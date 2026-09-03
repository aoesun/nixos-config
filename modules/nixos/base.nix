{ pkgs, ... }:
{
  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
  };

  time.timeZone = "Asia/Tokyo";
  i18n.defaultLocale = "en_US.UTF-8";

  users.users.ryuk = {
    isNormalUser = true;
    description = "Ryuk";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    shell = pkgs.zsh;
  };

  programs = {
    zsh.enable = true;
    tmux.enable = true;
  };

  # Expose completion definitions for shells managed by Home Manager.
  environment.pathsToLink = [ "/share/zsh" ];

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
  };
}
