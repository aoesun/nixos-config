{ ... }:
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-backup";
    users.ryuk.imports = [
      ../home/users/ryuk.nix
      ../home/profiles/default.nix
    ];
  };
}
