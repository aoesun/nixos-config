{ pkgs, ... }:
{
  environment = {
    systemPackages = with pkgs; [
      bitwarden-desktop
      goldendict-ng
      fastfetch
    ];
  };
}
