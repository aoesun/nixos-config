{ pkgs, ... }:
{
  imports = [
    ./input-method.nix
    ./plasma.nix
  ];

  fonts.packages = [ pkgs.nerd-fonts.fira-code ];
}
