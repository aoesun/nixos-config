{
  pkgs,
  rimeIce,
  ...
}:
let
  rimeCustomData = pkgs.symlinkJoin {
    name = "rime-custom-data";
    paths = [
      (pkgs.writeTextDir "share/rime-data/default.custom.yaml" ''
        patch:
          schema_list:
            - schema: double_pinyin
          "ascii_composer/switch_key/Shift_R": commit_code
      '')
      (pkgs.writeTextDir "share/rime-data/double_pinyin.custom.yaml" ''
        patch:
          # The third switch selects simplified or traditional Chinese.
          "switches/@2/reset": 0
          "menu/page_size": 7
          # Show the raw double-pinyin code instead of expanding it to full pinyin.
          "translator/preedit_format": []
      '')
      (pkgs.writeTextDir "share/rime-data/melt_eng.custom.yaml" ''
        patch:
          # Adapt English candidates to natural-code double pinyin.
          "speller/algebra":
            __include: algebra_double_pinyin
      '')
      (pkgs.writeTextDir "share/rime-data/radical_pinyin.custom.yaml" ''
        patch:
          # Adapt component lookup to natural-code double pinyin.
          "speller/algebra":
            __include: algebra_double_pinyin
      '')
    ];
  };

  rimeData = pkgs.runCommand "rime-data" { } ''
    mkdir -p $out/share/rime-data
    cp -r ${rimeIce}/. $out/share/rime-data/
    cp -r ${rimeCustomData}/share/rime-data/. $out/share/rime-data/
  '';
in
{
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      waylandFrontend = true;
      addons = with pkgs; [
        fcitx5-gtk
        (fcitx5-rime.override {
          rimeDataPkgs = [
            rimeData
          ];
        })
        fcitx5-mozc
      ];

      settings.inputMethod = {
        "Groups/0" = {
          Name = "Default";
          "Default Layout" = "us";
          DefaultIM = "rime";
        };
        "Groups/0/Items/0".Name = "keyboard-us";
        "Groups/0/Items/1".Name = "rime";
        "Groups/0/Items/2".Name = "mozc";
        GroupOrder."0" = "Default";
      };
    };
  };
}
