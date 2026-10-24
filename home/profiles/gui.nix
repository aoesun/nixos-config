{ config, pkgs, ... }:
{
  imports = [
    ../modules/dotfiles.nix
    ../programs/chromium.nix
    ../programs/rime.nix
    ../programs/mpv.nix
  ];

  home.packages = with pkgs; [
    bitwarden-desktop
    wl-clipboard
    nautilus
    zed-editor
    loupe
    fragments
  ];

  programs.ghostty.enable = true;

  # Open files from lazygit in Zed directly. xdg-open falls back to the
  # browser when no default handler is registered for a MIME type.
  programs.lazygit.settings.os.open = "zeditor {{filename}}";

  gtk = {
    enable = true;
    iconTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };
  };

  # Keep Ghostty's frequently edited settings outside the Nix store so they
  # can be reloaded without creating a new Home Manager or system generation.
  xdg.configFile."ghostty/config.ghostty".source = config.lib.dotfiles.link "ghostty/config.ghostty";
}
