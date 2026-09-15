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
    tree
    wget
  ];

  programs = {
    codex.enable = true;
    fastfetch.enable = true;
    git.enable = true;
    lazygit.enable = true;
    tmux.enable = true;
  };
}
