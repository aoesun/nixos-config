{ config, pkgs, ... }:
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

  # Recreate the account database declaratively on every activation. The
  # password hash is decrypted by sops-nix before users are configured.
  users.mutableUsers = false;

  users.users.ryuk = {
    isNormalUser = true;
    description = "Ryuk";
    hashedPasswordFile = config.sops.secrets."users/ryuk-password".path;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    shell = pkgs.zsh;
  };

  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;
    age.keyFile = "/persist/var/lib/sops-nix/key.txt";

    secrets."users/ryuk-password" = {
      neededForUsers = true;
    };
  };
}
