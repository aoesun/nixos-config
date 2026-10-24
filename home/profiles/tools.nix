{ pkgs, ... }:
{
  imports = [
    ../programs/navi.nix
    ../programs/neovim.nix
    ../programs/ssh.nix
    ../programs/yazi.nix
    ../programs/zsh.nix
  ];

  home.packages = with pkgs; [
    gh
    jq
    just
    luvus
    tree
    wget
    yq-go
    systemctl-tui
  ];

  programs = {
    fastfetch.enable = true;
    fzf = {
      enable = true;
      enableZshIntegration = true;
    };
    git = {
      enable = true;
      settings.user = {
        name = "aoesun";
        email = "37470931+aoesun@users.noreply.github.com";
      };
    };
    lazygit = {
      enable = true;
      settings.notARepository = "skip";
    };
    tmux.enable = true;
  };
}
