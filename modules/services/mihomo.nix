{
  config,
  lib,
  pkgs,
  username,
  ...
}:
{
  services.mihomo = {
    enable = true;
    # Keep this a string: a Nix path literal would be copied into /nix/store.
    configFile = "${config.users.users.${username}.home}/.config/mihomo/config.yaml";
    webui = pkgs.metacubexd;
  };

  # Keep the unit installed but do not start it at boot. Start it on demand
  # with systemctl-tui.
  systemd.services.mihomo.wantedBy = lib.mkForce [ ];
}
