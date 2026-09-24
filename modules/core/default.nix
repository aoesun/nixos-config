{ pkgs, ... }:
{
  imports = [
    ./impermanence.nix
    ./nix.nix
    ./ssh.nix
  ];

  time.timeZone = "Asia/Tokyo";
  i18n.defaultLocale = "en_US.UTF-8";

  networking.networkmanager.enable = true;

  programs.zsh.enable = true;

  # Expose completion definitions for shells managed by Home Manager.
  environment.pathsToLink = [ "/share/zsh" ];

  users.users.ryuk = {
    isNormalUser = true;
    description = "Ryuk";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    shell = pkgs.zsh;
  };
}
