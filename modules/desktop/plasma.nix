{ pkgs, ... }:
{
  services = {
    desktopManager.plasma6.enable = true;
    displayManager.plasma-login-manager.enable = true;
  };

  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    ark
    discover
    elisa
    khelpcenter
    kwin-x11
    okular
    qrca
  ];
}
