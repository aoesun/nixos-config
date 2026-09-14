{ ... }:
{
  imports = [
    ./config/navi.nix
    ./programs/fastfetch.nix
    ./programs/ssh.nix
    ./programs/zsh.nix
  ];

  home = {
    username = "ryuk";
    homeDirectory = "/home/ryuk";
    stateVersion = "26.05";
  };

  xdg.enable = true;
  programs.home-manager.enable = true;
}
