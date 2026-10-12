{ pkgs, username, ... }:
{
  services.mihomo = {
    enable = true;
    # Keep this a string: a Nix path literal would be copied into /nix/store.
    configFile = "/home/${username}/.config/mihomo/config.yaml";
    webui = pkgs.metacubexd;
  };
}
