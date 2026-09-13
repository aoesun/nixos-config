{ config, lib, ... }:
let
  cfg = config.my.programs.codex;
in
{
  options.my.programs.codex.enable =
    lib.mkEnableOption "Codex CLI";

  config = lib.mkIf cfg.enable {
    # Keep authentication state and provider credentials outside this repository.
    programs.codex.enable = true;
  };
}
