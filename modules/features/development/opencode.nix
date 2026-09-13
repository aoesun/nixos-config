{ config, lib, pkgs, ... }:
let
  cfg = config.my.programs.opencode;
in
{
  options.my.programs.opencode.enable =
    lib.mkEnableOption "OpenCode CLI";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.opencode
    ];
  };
}
