{
  description = "Declarative NixOS hosts and a portable Home Manager environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Follow Noctalia's cache branch so the desktop shell does not need to be
    # compiled locally on this VM.
    noctalia.url = "github:noctalia-dev/noctalia/cachix";

    silentSDDM = {
      url = "github:uiriansan/SilentSDDM";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rime-ice = {
      url = "github:iDvel/rime-ice";
      flake = false;
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      noctalia,
      silentSDDM,
      disko,
      spicetify-nix,
      rime-ice,
      ...
    }:
    let
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfreePredicate = pkg: nixpkgs.lib.getName pkg == "spotify";
      };

      mkSystem =
        hostModule:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            nixpkgsInput = nixpkgs;
            inherit noctalia silentSDDM;
            rimeIce = rime-ice;
          };
          modules = [
            home-manager.nixosModules.home-manager
            disko.nixosModules.disko
            hostModule
          ];
        };

      mkHome =
        profile:
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            ./home/users/ryuk.nix
            profile
          ];
        };
    in
    {
      # The output name matches the current hostname, so `--flake .` selects it.
      nixosConfigurations.nixos = mkSystem ./hosts/nixos;

      # This uses the same module as the NixOS integration and can be activated
      # on any x86_64 Linux distribution with Home Manager installed.
      homeConfigurations = {
        ryuk = mkHome ./home/profiles/default.nix;
        "ryuk-tools" = mkHome ./home/profiles/tools.nix;
      };

      # Reusable profiles for consumers that provide their own user identity.
      homeModules = {
        default = import ./home/profiles/default.nix;
        gui = import ./home/profiles/gui.nix;
        niri = import ./home/profiles/niri.nix;
        tools = import ./home/profiles/tools.nix;
      };

      # Custom packages are exported for explicit installation with `nix profile`.
      packages.${system} = import ./packages {
        inherit pkgs spicetify-nix;
      };
    };
}
