{ pkgs, ... }:
{
  users.users.ryuk = {
    isNormalUser = true;
    description = "Ryuk";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    shell = pkgs.zsh;
  };
}
