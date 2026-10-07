{ config, lib, ... }:
let
  patches = [
    "default.custom.yaml"
    "double_pinyin.custom.yaml"
    "melt_eng.custom.yaml"
    "radical_pinyin.custom.yaml"
  ];
in
{
  imports = [ ../modules/dotfiles.nix ];

  xdg.dataFile = lib.genAttrs (map (name: "fcitx5/rime/${name}") patches) (target: {
    source = config.lib.dotfiles.link "rime/${baseNameOf target}";
  });
}
