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
    popupLyrics
  ];

  enabledSnippets = [
    ''
      /* Hide Spotify home-page ads without relying on generated class names. */
      [data-testid="home-ads-container"],
      [data-testid="home-ad-card"] {
        display: none !important;
      }
    ''
  ];

  enabledCustomApps = with spicePkgs.apps; [
    marketplace
  ];

  # Optional theme example. Uncomment both lines to enable it.
  # theme = spicePkgs.themes.catppuccin;
  # colorScheme = "mocha";
}
