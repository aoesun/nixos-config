{
  description = "Declarative NixOS configuration for the nixos host";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dotfiles = {
      url = "github:aoesun/dotfiles";
      flake = false;
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      dotfiles,
      ...
    }:
    let
      mkSystem = hostModule:
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit dotfiles; };
          modules = [
            home-manager.nixosModules.home-manager
            hostModule
          ];
        };
    in
    {
      # The output name matches the current hostname, so `--flake .` selects it.
      nixosConfigurations.nixos = mkSystem ./hosts/nixos;
    };
}
