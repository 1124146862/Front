# luasteam local drop-in

Put the luasteam release files here so the test page can load them without a global install.

Expected files on Windows:

- `luasteam.dll`
- `steam_api64.dll`

If you are using a different platform, place the matching luasteam binary and Steamworks redistributable for that platform in this folder.

The test page will look here first:

- `src/features/gameplay/card_themes/libs/luasteam/`

If you prefer, you can also install luasteam globally on your Lua path instead.
