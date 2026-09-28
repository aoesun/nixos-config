{ config, ... }:
{
  sops = {
    defaultSopsFile = ../../secrets/nixos.yaml;
    age.keyFile = "/persist/var/lib/sops-nix/key.txt";

    secrets."users/ryuk/password-hash".neededForUsers = true;
  };

  users.users.ryuk.hashedPasswordFile =
    config.sops.secrets."users/ryuk/password-hash".path;
}
