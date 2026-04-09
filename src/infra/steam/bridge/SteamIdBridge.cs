using System;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;

internal static class NativeWindows
{
    [DllImport("steam_api64.dll", CallingConvention = CallingConvention.Cdecl)]
    internal static extern int SteamAPI_InitFlat(StringBuilder errorMessage);

    [DllImport("steam_api64.dll", CallingConvention = CallingConvention.Cdecl)]
    internal static extern void SteamAPI_Shutdown();

    [DllImport("steam_api64.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint = "SteamAPI_SteamUser_v023")]
    internal static extern IntPtr SteamAPI_SteamUser_v023();

    [DllImport("steam_api64.dll", CallingConvention = CallingConvention.Cdecl)]
    internal static extern ulong SteamAPI_ISteamUser_GetSteamID(IntPtr self);
}

internal static class NativeMac
{
    [DllImport("libsteam_api.dylib", CallingConvention = CallingConvention.Cdecl)]
    internal static extern int SteamAPI_InitFlat(StringBuilder errorMessage);

    [DllImport("libsteam_api.dylib", CallingConvention = CallingConvention.Cdecl)]
    internal static extern void SteamAPI_Shutdown();

    [DllImport("libsteam_api.dylib", CallingConvention = CallingConvention.Cdecl, EntryPoint = "SteamAPI_SteamUser_v023")]
    internal static extern IntPtr SteamAPI_SteamUser_v023();

    [DllImport("libsteam_api.dylib", CallingConvention = CallingConvention.Cdecl)]
    internal static extern ulong SteamAPI_ISteamUser_GetSteamID(IntPtr self);
}

internal static class Native
{
    private static bool IsWindows()
    {
        return Path.DirectorySeparatorChar == '\\';
    }

    internal static int SteamAPI_InitFlat(StringBuilder errorMessage)
    {
        return IsWindows() ? NativeWindows.SteamAPI_InitFlat(errorMessage) : NativeMac.SteamAPI_InitFlat(errorMessage);
    }

    internal static void SteamAPI_Shutdown()
    {
        if (IsWindows())
        {
            NativeWindows.SteamAPI_Shutdown();
            return;
        }
        NativeMac.SteamAPI_Shutdown();
    }

    internal static IntPtr SteamAPI_SteamUser_v023()
    {
        return IsWindows() ? NativeWindows.SteamAPI_SteamUser_v023() : NativeMac.SteamAPI_SteamUser_v023();
    }

    internal static ulong SteamAPI_ISteamUser_GetSteamID(IntPtr self)
    {
        return IsWindows() ? NativeWindows.SteamAPI_ISteamUser_GetSteamID(self) : NativeMac.SteamAPI_ISteamUser_GetSteamID(self);
    }
}

internal static class Program
{
    private const int SteamApiInitOk = 0;

    private static int Main(string[] args)
    {
        try
        {
            Directory.SetCurrentDirectory(AppDomain.CurrentDomain.BaseDirectory);

            if (Array.Exists(args, arg => arg == "--ping"))
            {
                Console.WriteLine("steam-id-bridge-ready");
                return 0;
            }

            var errorMessage = new StringBuilder(1024);
            var initResult = Native.SteamAPI_InitFlat(errorMessage);
            if (initResult != SteamApiInitOk)
            {
                Console.Error.WriteLine("SteamAPI_InitFlat failed.");
                Console.Error.WriteLine("code=" + initResult);
                Console.Error.WriteLine("message=" + errorMessage.ToString());
                return initResult == 0 ? 1 : initResult;
            }

            try
            {
                var steamUser = Native.SteamAPI_SteamUser_v023();
                if (steamUser == IntPtr.Zero)
                {
                    Console.Error.WriteLine("SteamAPI_SteamUser_v023 returned null.");
                    return 10;
                }

                var steamId = Native.SteamAPI_ISteamUser_GetSteamID(steamUser);
                if (steamId == 0)
                {
                    Console.Error.WriteLine("SteamID is 0.");
                    return 11;
                }

                Console.WriteLine(steamId);
                return 0;
            }
            finally
            {
                Native.SteamAPI_Shutdown();
            }
        }
        catch (DllNotFoundException ex)
        {
            Console.Error.WriteLine("DLL load failed: " + ex.Message);
            return 20;
        }
        catch (BadImageFormatException ex)
        {
            Console.Error.WriteLine("Architecture mismatch: " + ex.Message);
            return 21;
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine(ex.GetType().Name + ": " + ex.Message);
            return 99;
        }
    }
}
