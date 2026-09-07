{ pkgs, ... }:
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
          # The third switch is the traditional-to-simplified filter.
          "switches/@2/reset": 1
          "menu/page_size": 7
          # Show the raw double-pinyin code instead of expanding it to full pinyin.
          "translator/preedit_format": []
      '')
    ];
  };
in
{
  fonts.packages = [ pkgs.nerd-fonts.fira-code ];

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      waylandFrontend = true;
      addons = with pkgs; [
        fcitx5-gtk
        (fcitx5-rime.override {
          rimeDataPkgs = [
            rime-data
            rimeCustomData
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

  programs.chromium = {
    enable = true;
    extensions = [
      "dbepggeogbaibhgnhhndojpepiihcmeb" # Vimium
      "ddkjiahejlhfcafbddmgiahcphecmpfh" # uBlock Origin Lite
    ];
  };

  services = {
    desktopManager.plasma6.enable = true;
    displayManager.plasma-login-manager.enable = true;
  };

  environment = {
    systemPackages = with pkgs; [
      bitwarden-desktop
      chromium
      fastfetch
    ];
    plasma6.excludePackages = with pkgs.kdePackages; [
      ark
      discover
      elisa
      khelpcenter
      kwin-x11
      okular
      qrca
    ];
  };
}
