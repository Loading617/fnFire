using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Windows;
using System.Windows.Interop;
using System.Diagnostics;
using System.Windows.Controls;

namespace fnFire
{
    public partial class MainWindow : Window
    {
        private KeybindManager keybindManager;

        public MainWindow()
        {
            InitializeComponent();
            keybindManager = new KeybindManager(this);
            keybindManager.RegisterAll();
        }

        private void BindKey_Click(object sender, RoutedEventArgs e)
        {
            if (FunctionKeyCombo.SelectedItem is ComboBoxItem selectedItem)
            {
                string keyName = selectedItem.Content.ToString();
                string action = ActionTextBox.Text.Trim();
                if (!string.IsNullOrEmpty(action))
                {
                    keybindManager.BindKey(keyName, action);
                    StatusTextBlock.Text = $"Bound {keyName} to \"{action}\"";
                }
            }
        }
    }
}
