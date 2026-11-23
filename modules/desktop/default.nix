{ pkgs, ... }:
{
  imports = [
    ./greeter.nix
    ./input-method.nix
    ./niri.nix
  ];

  fonts = {
    packages = with pkgs; [
      maple-mono.NF-CN
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
    ];

    # Han characters resolve to Simplified Chinese glyphs first, so the
    # en_US locale does not pick Japanese variants.
    fontconfig.defaultFonts = {
      monospace = [
        "Maple Mono NF CN"
        "Noto Sans Mono CJK SC"
      ];
      sansSerif = [ "Noto Sans CJK SC" ];
      emoji = [ "Noto Color Emoji" ];
    };

    # Text tagged as Japanese (e.g. lang="ja" pages) gets Japanese glyph
    # forms instead of the Simplified Chinese default. Monospace keeps
    # Maple Mono, whose Latin glyphs matter more there than Han variants.
    fontconfig.localConf = ''
      <?xml version="1.0"?>
      <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
      <fontconfig>
        <match target="pattern">
          <test name="lang" compare="contains"><string>ja</string></test>
          <test qual="any" name="family"><string>sans-serif</string></test>
          <edit name="family" mode="prepend" binding="strong">
            <string>Noto Sans CJK JP</string>
          </edit>
        </match>
      </fontconfig>
    '';
  };

  programs.localsend = {
    enable = true;
    openFirewall = false;
  };

}
