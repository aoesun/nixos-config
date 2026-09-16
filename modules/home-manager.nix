{
  config,
  lib,
  noctalia,
  ...
}:
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-backup";
    sharedModules = [ noctalia.homeModules.default ];
    users.ryuk.imports = [
      ../home/users/ryuk.nix
      ../home/profiles/default.nix
    ]
    ++ lib.optional (builtins.elem config.desktop.session [
      "niri"
      "both"
    ]) ../home/profiles/niri.nix;
  };
}
