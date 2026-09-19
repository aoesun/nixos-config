{ config, pkgs, ... }:
let
  dotfiles = "${config.home.homeDirectory}/dotfiles";
in
{
  imports = [
    ../programs/chromium.nix
    ../programs/rime.nix
  ];

  home.packages = with pkgs; [
    bitwarden-desktop
    goldendict-ng
    wl-clipboard
  ];

  programs.ghostty.enable = true;

  # Keep Ghostty's frequently edited settings outside the Nix store so they
  # can be reloaded without creating a new Home Manager or system generation.
  xdg.configFile."ghostty/config.ghostty" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/ghostty/config.ghostty";
  };
}
