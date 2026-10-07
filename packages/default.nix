{
  pkgs,
  spicetify-nix,
}:

{
  goldendict-ng = pkgs.goldendict-ng;

  spotify-spiced = import ./spotify-spiced.nix {
    inherit pkgs spicetify-nix;
  };
}
