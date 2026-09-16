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
    jq
    just
    tree
    wget
  ];

  programs = {
    codex.enable = true;
    fastfetch.enable = true;
    fzf = {
      enable = true;
      enableZshIntegration = true;
    };
    git.enable = true;
    lazygit.enable = true;
    tmux.enable = true;
  };
}
