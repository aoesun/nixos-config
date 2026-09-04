{ dotfiles, ... }:
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-backup";
    extraSpecialArgs = { inherit dotfiles; };
    users.ryuk = import ../../home/ryuk;
  };
}
