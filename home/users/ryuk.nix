{ ... }:
{
  home = {
    username = "ryuk";
    homeDirectory = "/home/ryuk";
    stateVersion = "26.05";
  };

  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;
    };
  };
  programs.home-manager.enable = true;
}
