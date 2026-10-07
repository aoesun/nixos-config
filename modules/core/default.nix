{
  config,
  pkgs,
  username,
  ...
}:
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

  users.users.${username} = {
    isNormalUser = true;
    description = "Ryuk";
    hashedPasswordFile = config.sops.secrets."users/${username}-password".path;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    shell = pkgs.zsh;
  };

  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;
    age.keyFile = "/persist/var/lib/sops-nix/key.txt";

    secrets."users/${username}-password" = {
      neededForUsers = true;
    };

    secrets."github/ssh-private-key" = {
      owner = username;
      group = "users";
      mode = "0600";
      path = "${config.users.users.${username}.home}/.ssh/id_ed25519";
    };
  };
}
