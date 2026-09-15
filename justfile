set shell := ["bash", "-euo", "pipefail", "-c"]

# List available recipes.
default:
    @just --list

# Evaluate every flake output without building it.
check:
    nix flake check --no-build

# Build the current NixOS system without activating it.
build:
    nix build .#nixosConfigurations.nixos.config.system.build.toplevel -o result-system

# Build a standalone Home Manager profile.
home profile="ryuk":
    nix build ".#homeConfigurations.{{ profile }}.activationPackage" -o "result-{{ profile }}"

# Compare the last system build with the active system.
diff: build
    nix store diff-closures /run/current-system ./result-system

# Temporarily activate the local host configuration.
test:
    sudo nixos-rebuild test --flake .

# Activate the local host configuration and make it the boot default.
switch:
    sudo nixos-rebuild switch --flake .

# Update every locked flake input.
update:
    nix flake update

# Update one locked flake input.
update-input input:
    nix flake update "{{ input }}"

# Show NixOS system generations.
history:
    nix profile history --profile /nix/var/nix/profiles/system

# Build the custom Spotify package.
spotify:
    nix build .#spotify-spiced -o result-spotify
