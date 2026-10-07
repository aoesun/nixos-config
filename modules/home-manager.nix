{
  config,
  lib,
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
    ]
    ++ lib.optional (builtins.elem config.desktop.session [
      "niri"
      "both"
    ]) ../home/profiles/niri.nix;
  };
}
