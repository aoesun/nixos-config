{
  description = "Declarative NixOS configuration for the nixos host";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Reserved as a reproducible source for configurations that should live in
    # the Nix Store. Frequently edited Navi cheats use the local checkout.
    dotfiles = {
      url = "github:aoesun/dotfiles";
      flake = false;
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      spicetify-nix,
      ...
    }:
    let
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfreePredicate = pkg: nixpkgs.lib.getName pkg == "spotify";
      };

      mkSystem = hostModule:
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            home-manager.nixosModules.home-manager
            hostModule
          ];
        };
    in
    {
      # The output name matches the current hostname, so `--flake .` selects it.
      nixosConfigurations.nixos = mkSystem ./hosts/nixos;

      # Custom packages are exported for explicit installation with `nix profile`.
      packages.${system} = import ./packages {
        inherit pkgs spicetify-nix;
      };
    };
}
