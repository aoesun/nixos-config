{ username, ... }:
{
  # Noctalia Greeter on greetd. Its appearance (wallpaper, palette, font) is
  # synced from the Noctalia shell: Settings -> Security -> Noctalia Greeter.
  # Keep appearance keys out of `settings`, because greeter.toml overrides
  # whatever the sync delivers.
  services.displayManager.noctalia-greeter = {
    enable = true;

    # Let Noctalia's Auto-Sync apply appearance changes without a Polkit
    # password prompt. The helper only accepts appearance data.
    passwordlessSyncUsers = [ username ];
  };

  environment.persistence."/persist".directories = [
    # Synced wallpapers and sync.toml (last session, picked scheme).
    {
      directory = "/var/lib/noctalia-greeter";
      user = "greeter";
      group = "greeter";
      mode = "0750";
    }

    # User avatars shown by the greeter come from AccountsService.
    "/var/lib/AccountsService"
  ];
}
