{ config, ... }:
let
  rimeDirectory = "${config.home.homeDirectory}/dotfiles/rime";
  link = name: {
    source = config.lib.file.mkOutOfStoreSymlink "${rimeDirectory}/${name}";
  };
in
{
  xdg.dataFile = {
    "fcitx5/rime/default.custom.yaml" = link "default.custom.yaml";
    "fcitx5/rime/double_pinyin.custom.yaml" = link "double_pinyin.custom.yaml";
    "fcitx5/rime/melt_eng.custom.yaml" = link "melt_eng.custom.yaml";
    "fcitx5/rime/radical_pinyin.custom.yaml" = link "radical_pinyin.custom.yaml";
  };
}
