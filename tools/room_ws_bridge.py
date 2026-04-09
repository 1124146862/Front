from __future__ import annotations

import argparse
import asyncio
import json
import os
import time
from pathlib import Path

import websockets
from websockets.exceptions import ConnectionClosed

COMMAND_POLL_INTERVAL_SECONDS = 0.005
CONTROL_POLL_INTERVAL_SECONDS = 0.05
RECONNECT_BASE_DELAY_SECONDS = 0.25
RECONNECT_MAX_DELAY_SECONDS = 2.0


def append_event(path: Path, packet: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(packet, ensure_ascii=False, separators=(",", ":")) + "\n")


async def tail_commands(path: Path, websocket, state: dict) -> None:
    path.touch(exist_ok=True)
    offset = int(state.get("command_offset", 0))

    while True:
        current_size = path.stat().st_size
        if current_size < offset:
            offset = 0

        if current_size > offset:
            with path.open("r", encoding="utf-8") as handle:
                handle.seek(offset)
                while True:
                    raw_line = handle.readline()
                    if raw_line == "":
                        break
                    line = raw_line.strip()
                    offset = handle.tell()
                    state["command_offset"] = offset
                    if not line:
                        continue
                    await websocket.send(line)

        await asyncio.sleep(COMMAND_POLL_INTERVAL_SECONDS)


async def receive_messages(events_path: Path, websocket) -> None:
    async for message in websocket:
        append_event(events_path, {"type": "bridge_message", "payload": message})


def should_stop(stop_path: Path, heartbeat_path: Path, heartbeat_timeout_seconds: float = 5.0) -> bool:
    if stop_path.exists():
        try:
            if stop_path.read_text(encoding="utf-8").strip() == "stop":
                return True
        except OSError:
            return True

    if not heartbeat_path.exists():
        return False

    try:
        heartbeat_age = time.time() - heartbeat_path.stat().st_mtime
    except FileNotFoundError:
        return False

    return heartbeat_age > heartbeat_timeout_seconds


def is_fatal_close(code: int | None) -> bool:
    return code in {4403, 4404, 1008}


async def watch_control(stop_path: Path, heartbeat_path: Path, websocket) -> str:
    while True:
        if should_stop(stop_path, heartbeat_path):
            await websocket.close()
            return "stopped"
        await asyncio.sleep(CONTROL_POLL_INTERVAL_SECONDS)


async def main_async(ws_url: str, session_dir: Path) -> None:
    session_dir.mkdir(parents=True, exist_ok=True)
    commands_path = session_dir / "commands.ndjson"
    events_path = session_dir / "events.ndjson"
    pid_path = session_dir / "pid"
    stop_path = session_dir / "stop"
    heartbeat_path = session_dir / "heartbeat"

    pid_path.write_text(str(os.getpid()), encoding="utf-8")
    stop_path.write_text("", encoding="utf-8")
    commands_path.write_text("", encoding="utf-8")
    events_path.write_text("", encoding="utf-8")
    heartbeat_path.write_text(str(time.time()), encoding="utf-8")
    command_state = {
        "command_offset": 0,
    }
    reconnect_delay_seconds = RECONNECT_BASE_DELAY_SECONDS

    while not should_stop(stop_path, heartbeat_path):
        try:
            append_event(events_path, {"type": "bridge_status", "payload": {"status": "connecting"}})
            async with websockets.connect(
                ws_url,
                max_size=2**20,
                open_timeout=5.0,
                close_timeout=3.0,
                ping_interval=15.0,
                ping_timeout=15.0,
                max_queue=256,
            ) as websocket:
                append_event(events_path, {"type": "bridge_status", "payload": {"status": "connected"}})
                reconnect_delay_seconds = RECONNECT_BASE_DELAY_SECONDS
                tasks = [
                    asyncio.create_task(tail_commands(commands_path, websocket, command_state)),
                    asyncio.create_task(receive_messages(events_path, websocket)),
                    asyncio.create_task(watch_control(stop_path, heartbeat_path, websocket)),
                ]

                done, pending = await asyncio.wait(tasks, return_when=asyncio.FIRST_COMPLETED)

                for task in pending:
                    task.cancel()

                for task in pending:
                    try:
                        await task
                    except asyncio.CancelledError:
                        pass
                    except Exception:
                        pass

                should_exit = any(task.result() == "stopped" for task in done if not task.cancelled() and task.exception() is None)
                close_code = websocket.close_code
                if should_exit or is_fatal_close(close_code):
                    break
        except ConnectionClosed as exc:
            if is_fatal_close(getattr(exc, "code", None)) or should_stop(stop_path, heartbeat_path):
                break
            append_event(
                events_path,
                {
                    "type": "bridge_status",
                    "payload": {
                        "status": "error",
                        "message": str(exc),
                    },
                },
            )
            await asyncio.sleep(reconnect_delay_seconds)
            reconnect_delay_seconds = min(reconnect_delay_seconds * 2.0, RECONNECT_MAX_DELAY_SECONDS)
        except Exception as exc:  # noqa: BLE001
            append_event(
                events_path,
                {
                    "type": "bridge_status",
                    "payload": {
                        "status": "error",
                        "message": str(exc),
                    },
                },
            )
            if should_stop(stop_path, heartbeat_path):
                break
            await asyncio.sleep(reconnect_delay_seconds)
            reconnect_delay_seconds = min(reconnect_delay_seconds * 2.0, RECONNECT_MAX_DELAY_SECONDS)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--ws-url", required=True)
    parser.add_argument("--session-dir", required=True)
    args = parser.parse_args()

    asyncio.run(main_async(args.ws_url, Path(args.session_dir)))


if __name__ == "__main__":
    main()
