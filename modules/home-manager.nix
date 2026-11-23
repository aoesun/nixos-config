{
  noctalia,
  username,
  ...
}:
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-backup";
    sharedModules = [ noctalia.homeModules.default ];
    users.${username}.imports = [
      ../home/users/${username}.nix
      ../home/profiles/default.nix
      ../home/profiles/niri.nix
    ];
  };
}
