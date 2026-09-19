{ ... }:
{
  programs.chromium = {
    enable = true;
    extensions = [
      "dbepggeogbaibhgnhhndojpepiihcmeb" # Vimium
      "ddkjiahejlhfcafbddmgiahcphecmpfh" # uBlock Origin Lite
      "fflnomjgnenfknflkefbaflgdihnhnig" # Code theme
      "nngceckbapebfimnlniiiahkandclblb" # Bitwarden Password Manager
    ];
  };

  # Keep the launcher entry private by default without forcing every
  # invocation of the `chromium` command into incognito mode.
  xdg.desktopEntries.chromium-browser = {
    name = "Chromium";
    genericName = "Web Browser";
    comment = "Access the Internet";
    icon = "chromium";
    exec = "chromium %U --incognito";
    terminal = false;
    categories = [
      "Network"
      "WebBrowser"
    ];
    mimeType = [
      "application/pdf"
      "application/rdf+xml"
      "application/rss+xml"
      "application/xhtml+xml"
      "application/xhtml_xml"
      "application/xml"
      "image/gif"
      "image/jpeg"
      "image/png"
      "image/webp"
      "text/html"
      "text/xml"
      "x-scheme-handler/http"
      "x-scheme-handler/https"
      "x-scheme-handler/chromium"
    ];
    startupNotify = true;
    settings.StartupWMClass = "chromium-browser";
    actions = {
      "01-new-window" = {
        name = "New Window";
        exec = "chromium";
      };
      "02-new-private-window" = {
        name = "New Incognito Window";
        exec = "chromium --incognito";
      };
    };
  };
}
