{
  pkgs,
  spicetify-nix,
}:

let
  spicePkgs = spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
spicetify-nix.lib.mkSpicetify pkgs {
  enabledExtensions = with spicePkgs.extensions; [
    adblockify
    shuffle
  ];

  enabledCustomApps = with spicePkgs.apps; [
    marketplace
  ];

  # Optional theme example. Uncomment both lines to enable it.
  # theme = spicePkgs.themes.catppuccin;
  # colorScheme = "mocha";
}
