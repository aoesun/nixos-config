{
  config,
  lib,
  pkgs,
  ...
}:
let
  enabled = builtins.elem config.desktop.session [
    "plasma"
    "both"
  ];
in
{
  config = lib.mkIf enabled {
    services.desktopManager.plasma6.enable = true;

    environment.plasma6.excludePackages = with pkgs.kdePackages; [
      ark
      discover
      elisa
      khelpcenter
      kwin-x11
      okular
      qrca
    ];
  };
}
