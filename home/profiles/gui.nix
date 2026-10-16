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
    loupe
    fragments
  ];

  programs.ghostty.enable = true;

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
