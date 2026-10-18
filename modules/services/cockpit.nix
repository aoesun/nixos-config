{ lib, ... }:
{
  services.cockpit = {
    enable = true;
    port = 9091;
    openFirewall = false;

    # The module's default only allows https://localhost:9091.
    settings.WebService.Origins = lib.mkForce "https://localhost:9091 http://localhost:9091 http://127.0.0.1:9091";
  };

  # Bind the socket to loopback only instead of all interfaces.
  systemd.sockets.cockpit.listenStreams = lib.mkForce [
    ""
    "127.0.0.1:9091"
  ];
}
