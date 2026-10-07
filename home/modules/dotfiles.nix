{ config, lib, ... }:
let
  cfg = config.dotfiles;
in
{
  options.dotfiles.path = lib.mkOption {
    type = lib.types.str;
    default = "${config.home.homeDirectory}/dotfiles";
    description = "Editable dotfiles working tree linked outside the Nix store.";
  };

  # Link into the working tree instead of the store so edits apply without
  # creating a new Home Manager generation.
  config.lib.dotfiles.link =
    relativePath: config.lib.file.mkOutOfStoreSymlink "${cfg.path}/${relativePath}";
}
