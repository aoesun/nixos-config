{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    jq
    tree
    wget
  ];

  programs = {
    git.enable = true;
    lazygit.enable = true;
    tmux.enable = true;
  };
}
