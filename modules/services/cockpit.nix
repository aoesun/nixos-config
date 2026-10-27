{ lib, ... }:
let
  # 9090 is used by mihomo's external-controller and 9091 by Fragments'
  # embedded transmission-daemon, so Cockpit gets its own port.
  port = 9092;
in
{
  services.cockpit = {
    enable = true;
    inherit port;
    openFirewall = false;

    # The module's default only allows https://localhost:<port>.
    settings.WebService.Origins = lib.mkForce "https://localhost:${toString port} http://localhost:${toString port} http://127.0.0.1:${toString port}";
  };

  # Bind the socket to loopback only instead of all interfaces.
  systemd.sockets.cockpit.listenStreams = lib.mkForce [
    ""
    "127.0.0.1:${toString port}"
  ];
}
