﻿// See https://aka.ms/new-console-template for more information
using Microsoft.Toolkit.Uwp.Notifications;
using System.Drawing;
using System.Reflection.Metadata;
using System.Runtime.InteropServices;
using System.Text.Json;
using System.Windows.Controls;
using System.Windows.Media;
using System.Threading;
using TwitchDesktopNotifications;
using TwitchDesktopNotifications.Core;
using TwitchDesktopNotifications.JsonStructure;
using Windows.UI.Core.Preview;

internal class Program
{

    static bool isConnecting = false;
    static WebServer ws = WebServer.GetInstance();

    private static NotifyIcon notifyIcon;
    private static ContextMenuStrip cms;
    private static ManageIgnores? manageIgnores;

    public static void Ws_CodeRecived(object? sender, EventArgs e)
    {
        ws.CodeRecived -= Ws_CodeRecived;

        string response = TwitchFetcher.GetInstance().endConnection(((WebServer)sender).TwitchCode);

        if (!DataStore.GetInstance().isLoaded)
        {
            DataStore.GetInstance().Load();
        }

        DataStore.GetInstance().Store.Authentication = JsonSerializer.Deserialize<Authentication>(response);

        DateTime unixStart = DateTime.SpecifyKind(new DateTime(1970, 1, 1), DateTimeKind.Utc);
        DataStore.GetInstance().Store.Authentication.ExpiresAt = (long)Math.Floor((DateTime.Now.AddSeconds(DataStore.GetInstance().Store.Authentication.ExpiresSeconds) - unixStart).TotalMilliseconds);
        DataStore.GetInstance().Save();

        isConnecting = false;
        ws.Stop();
    }

    protected static void Reconnect_Click(object? sender, System.EventArgs e)
    {
        TriggerAuthentication();
    }

    protected static void ManageIgnores_Click(object? sender, System.EventArgs e)
    {
        if (manageIgnores == null) {
            manageIgnores = new ManageIgnores();
            manageIgnores.Closed += ManageIgnores_Closed;
        }
        manageIgnores.Show();
        manageIgnores.Focus();
    }

    private static void ManageIgnores_Closed(object? sender, EventArgs e)
    {
        manageIgnores = null;
    }

    protected static void Quit_Click(object? sender, System.EventArgs e)
    {
        notifyIcon.Visible = false;
        notifyIcon.Dispose();
        Environment.Exit(0);
    }

    private async static void TriggerAuthentication()
    {
        ws.CodeRecived += Ws_CodeRecived;
        ws.Start();
        isConnecting = true;
        TwitchFetcher.GetInstance().BeginConnection();
        if (DataStore.GetInstance().Store.Authentication == null)
        {
            if (isConnecting)
            {
                TwitchFetcher.GetInstance().OpenFailedNotification();
            }
        }
    }
    [STAThread]
    private static void Main(string[] args)
    {
        try
        {
            notifyIcon = new NotifyIcon();
            notifyIcon.Icon = new Icon("Assets/icon.ico");
            notifyIcon.Text = "Twitch Notify";

            cms = new ContextMenuStrip();
            cms.BackColor = System.Drawing.Color.FromArgb(51, 51, 51);
            cms.ForeColor = System.Drawing.Color.FromArgb(145, 70, 255);
            cms.ShowImageMargin= false;
            cms.Items.Add(new ToolStripMenuItem("Manage Ignores", null, new EventHandler(ManageIgnores_Click)));
            cms.Items.Add(new ToolStripSeparator());
            cms.Items.Add(new ToolStripMenuItem("Reconnect", null, new EventHandler(Reconnect_Click)));
            //cms.Items.Add(new ToolStripMenuItem("About", null, new EventHandler(About_Click), "Quit"));
            cms.Items.Add(new ToolStripSeparator());
            cms.Items.Add(new ToolStripMenuItem("Quit", null, new EventHandler(Quit_Click), "Quit"));

            notifyIcon.ContextMenuStrip = cms;
            notifyIcon.Visible = true;

            if (DataStore.GetInstance().Store.Authentication == null)
            {
                TriggerAuthentication();
            }

            var autoEvent = new AutoResetEvent(false);
            var timer = new System.Threading.Timer((Object? stateInfo) => {
                if (DataStore.GetInstance().Store != null)
                {
                    TwitchFetcher.GetInstance().GetLiveFollowingUsers();
                }
            }, autoEvent, 1000, 500);
            

            Application.Run();

            Application.ApplicationExit += (object? sender, EventArgs e) => {
                ToastNotificationManagerCompat.Uninstall();
            };
        }
        catch (Exception e) {
            Logger.GetInstance().Writer.WriteLineAsync(e.ToString());
        }

    }
}