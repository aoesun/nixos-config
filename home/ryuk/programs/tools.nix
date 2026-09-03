{ pkgs, ... }:
{
  home.packages = with pkgs; [
    tree
    wget
  ];

  programs = {
    # Keep authentication state and provider credentials outside this repository.
    codex.enable = true;
    git.enable = true;
    lazygit.enable = true;
    opencode.enable = true;

    navi = {
      enable = true;
      enableZshIntegration = true;
    };

    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
