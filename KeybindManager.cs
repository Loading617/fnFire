using System;
using System.Collections.Generic;
using System.IO;
using System.Runtime.InteropServices;
using System.Text.Json;
using System.Windows;
using System.Windows.Interop;
using System.Diagnostics;

namespace FnKeybindApp
{
    public class KeybindManager
    {
        private const int WM_HOTKEY = 0x0312;
        private Dictionary<int, string> keybinds = new();
        private Dictionary<string, int> functionKeyCodes = new()
        {
            { "F1", 0x70 }, { "F2", 0x71 }, { "F3", 0x72 }, { "F4", 0x73 },
            { "F5", 0x74 }, { "F6", 0x75 }, { "F7", 0x76 }, { "F8", 0x77 },
            { "F9", 0x78 }, { "F10", 0x79 }, { "F11", 0x7A }, { "F12", 0x7B }
        };
        private HwndSource hwndSource;
        private Window window;
        private string savePath = "Keybinds.json";

        [DllImport("user32.dll")]
        private static extern bool RegisterHotKey(IntPtr hWnd, int id, int fsModifiers, int vk);

        [DllImport("user32.dll")]
        private static extern bool UnregisterHotKey(IntPtr hWnd, int id);

        public KeybindManager(Window win)
        {
            window = win;
            hwndSource = HwndSource.FromHwnd(new WindowInteropHelper(window).Handle);
            hwndSource.AddHook(WndProc);
            LoadKeybinds();
        }

        public void RegisterAll()
        {
            foreach (var pair in functionKeyCodes)
            {
                if (keybinds.TryGetValue(pair.Value, out _))
                {
                    RegisterHotKey(hwndSource.Handle, pair.Value, 0, pair.Value);
                }
            }
        }

        public void BindKey(string key, string action)
        {
            if (!functionKeyCodes.TryGetValue(key, out int vk)) return;

            UnregisterHotKey(hwndSource.Handle, vk);
            keybinds[vk] = action;
            RegisterHotKey(hwndSource.Handle, vk, 0, vk);
            SaveKeybinds();
        }

        private void SaveKeybinds()
        {
            var json = JsonSerializer.Serialize(keybinds);
            File.WriteAllText(savePath, json);
        }

        private void LoadKeybinds()
        {
            if (File.Exists(savePath))
            {
                var json = File.ReadAllText(savePath);
                keybinds = JsonSerializer.Deserialize<Dictionary<int, string>>(json);
            }
        }

        private IntPtr WndProc(IntPtr hwnd, int msg, IntPtr wParam, IntPtr lParam, ref bool handled)
        {
            if (msg == WM_HOTKEY)
            {
                int vk = wParam.ToInt32();
                if (keybinds.TryGetValue(vk, out string action))
                {
                    try
                    {
                        Process.Start("cmd.exe", $"/C {action}");
                    }
                    catch (Exception ex)
                    {
                        MessageBox.Show($"Error executing action: {ex.Message}");
                    }
                    handled = true;
                }
            }
            return IntPtr.Zero;
        }
    }
}

