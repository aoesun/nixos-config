{ pkgs, ... }:
{
  imports = [
    ../programs/chromium.nix
  ];

  home.packages = with pkgs; [
    bitwarden-desktop
    goldendict-ng
    wl-clipboard
  ];
}
