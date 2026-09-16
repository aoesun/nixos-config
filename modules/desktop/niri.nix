{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf (builtins.elem config.desktop.session [ "niri" "both" ]) {
    programs.niri.enable = true;

    # Niri enables GNOME Keyring for its Secret portal. Keep the existing
    # OpenSSH agent instead of also starting GCR's competing SSH agent.
    services.gnome.gcr-ssh-agent.enable = false;

    # Niri starts this on demand for applications that still require X11.
    environment.systemPackages = [ pkgs.xwayland-satellite ];
  };
}
