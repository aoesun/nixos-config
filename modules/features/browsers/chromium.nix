{ pkgs, ... }:
{
  programs.chromium = {
    enable = true;
    extensions = [
      "dbepggeogbaibhgnhhndojpepiihcmeb" # Vimium
      "ddkjiahejlhfcafbddmgiahcphecmpfh" # uBlock Origin Lite
    ];
  };

  environment.systemPackages = [
    pkgs.chromium
  ];
}
