{ config, pkgs, ... }:
{
  imports = [ ../modules/dotfiles.nix ];

  programs.mpv = {
    enable = true;
    scripts = with pkgs.mpvScripts; [
      uosc
      thumbfast
    ];
  };

  # Keep mpv.conf outside the Nix store so it can be tuned without a rebuild.
  xdg.configFile."mpv/mpv.conf".source = config.lib.dotfiles.link "mpv/mpv.conf";
  xdg.configFile."mpv/input.conf".source = config.lib.dotfiles.link "mpv/input.conf";
}
