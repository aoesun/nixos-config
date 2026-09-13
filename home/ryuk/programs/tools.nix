{ config, ... }:
{
  programs = {
    # Keep authentication state and provider credentials outside this repository.
    codex.enable = true;
    git.enable = true;
    lazygit.enable = true;
    opencode.enable = true;

    ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings."github.com" = {
        HostName = "github.com";
        User = "git";
        IdentityFile = "~/.ssh/id_ed25519";
        IdentitiesOnly = true;
        AddKeysToAgent = "yes";
      };
    };

    navi = {
      enable = true;
      enableZshIntegration = true;
    };
  };

  xdg.dataFile."navi/cheats/personal".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/navi";
}
