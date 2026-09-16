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
    extra-substituters = [ "https://noctalia.cachix.org" ];
    extra-trusted-public-keys = [
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];
  };

  # Remove old, unreachable store paths on a predictable schedule.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
}
