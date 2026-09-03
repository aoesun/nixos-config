# NixOS Configuration

Declarative NixOS and Home Manager configuration for the `nixos` host.

## Overview

- Nix flakes
- Home Manager integrated as a NixOS module
- KDE Plasma 6 desktop
- Fcitx5 with Rime
- Host-specific hardware configuration

## Layout

```text
.
├── flake.nix
├── flake.lock
├── hosts/
│   └── nixos/
├── modules/
│   └── nixos/
└── home/
    └── ryuk/
```

## Check

```bash
nix flake check --no-build
```

## Apply

From this repository:

```bash
sudo nixos-rebuild switch --flake .
```

Or from another directory:

```bash
sudo nixos-rebuild switch --flake ~/nixos-config
```

## Update inputs

```bash
nix flake update
```

Review the resulting changes and run the check command before applying them.

## Secrets

Do not commit plaintext passwords, tokens, private keys, or credentials. Keep
authentication state outside this repository. If secrets need to become part of
the declarative configuration, encrypt them with a tool such as `sops-nix` or
`agenix` before committing them.
