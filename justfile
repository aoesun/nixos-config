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

# Make the local host configuration the next boot target without activating it now.
boot:
    sudo nixos-rebuild boot --flake .

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

# Delete user and system generations older than seven days, then collect the store.
clean:
    nix profile wipe-history --older-than 7d
    sudo nix profile wipe-history --profile /nix/var/nix/profiles/system --older-than 7d
    nix store gc

# Delete every non-current user and system generation, then collect the store.
clean-all:
    nix profile wipe-history
    sudo nix profile wipe-history --profile /nix/var/nix/profiles/system
    nix store gc

# Build the custom Spotify package.
spotify:
    nix build .#spotify-spiced -o result-spotify
