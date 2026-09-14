{ nixpkgsInput, ... }:
{
  # Keep tools that use <nixpkgs> on the same revision as this flake.
  nix.nixPath = [ "nixpkgs=${nixpkgsInput}" ];

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
  };
}
