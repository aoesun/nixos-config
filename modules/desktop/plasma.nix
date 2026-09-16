{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf (builtins.elem config.desktop.session [ "plasma" "both" ]) {
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
