{
  pkgs,
  spicetify-nix,
}:

{
  spotify-spiced = import ./spotify-spiced.nix {
    inherit pkgs spicetify-nix;
  };
}
