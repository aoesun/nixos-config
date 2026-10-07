set shell := ["bash", "-euo", "pipefail", "-c"]

# List software packages provided by this repository.
list:
    @printf '%s\n' 'Available software:' '  goldendict-ng  Dictionary lookup application' '  spotify       Custom Spotify with Spicetify extensions'

# Build and install GoldenDict-ng in the user profile.
goldendict-ng:
    nix profile install .#goldendict-ng

# Build and install the custom Spotify package in the user profile.
spotify:
    nix profile install .#spotify-spiced
