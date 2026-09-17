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
      /* Hide Spotify ad surfaces without relying on generated class names. */
      [data-testid="home-ads-container"],
      [data-testid="home-ad-card"],
      [data-testid="standalone-video-ad-player"],
      .NowPlayingView section[aria-label="广告"],
      [data-testid="playlist-page"] .main-entityHeader-headerText > div:has(a[target="_blank"][rel~="noopener"]),
      .main-nowPlayingView-headerTextWrapper > .main-trackInfo-overlay {
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
