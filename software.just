set shell := ["bash", "-euo", "pipefail", "-c"]

# List software packages provided by this repository.
list:
    @printf '%s\n' 'Available software:' '  goldendict-ng  Dictionary lookup application' '  spotify       Custom Spotify with Spicetify extensions' 'Coding agents from nixpkgs:' '  codex  claude-code  opencode  pi'

# Install GoldenDict-ng from nixpkgs into the user profile.
goldendict-ng:
    nix profile install nixpkgs#goldendict-ng

# Build and install the custom Spotify package in the user profile.
spotify:
    nix profile install .#spotify-spiced

# Install a coding agent from nixpkgs into the user profile.
# unfree packages (e.g. claude-code) need the env var and --impure.
_agent pkg:
    NIXPKGS_ALLOW_UNFREE=1 nix profile install --impure "nixpkgs#{{pkg}}"

# Coding agents: one recipe per agent so that shell completion works.
codex: (_agent "codex")
claude-code: (_agent "claude-code")
opencode: (_agent "opencode")
pi: (_agent "pi-coding-agent")

# Remove a package previously installed into the user profile.
# Use the name shown by `nix profile list`.
remove name:
    nix profile remove "{{name}}"
