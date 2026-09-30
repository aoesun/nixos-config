set shell := ["bash", "-euo", "pipefail", "-c"]

# List software packages provided by this repository.
list:
    @printf '%s\n' 'Available software:' '  spotify  Custom Spotify with Spicetify extensions'

# Build and install the custom Spotify package in the user profile.
spotify:
    nix profile install .#spotify-spiced
