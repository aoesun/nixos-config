{
  description = "Declarative NixOS configuration for the nixos host";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, home-manager, ... }:
    let
      commonModules = [
        home-manager.nixosModules.home-manager
        ./hosts/nixos
      ];

      mkSystem = additionalModules:
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = commonModules ++ additionalModules;
        };
    in
    {
      # The output name matches the current hostname, so `--flake .` selects it.
      nixosConfigurations.nixos = mkSystem [
        ./modules/nixos/optional/vmware-guest.nix
      ];
    };
}
