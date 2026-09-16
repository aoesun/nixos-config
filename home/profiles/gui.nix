{ pkgs, ... }:
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
}
