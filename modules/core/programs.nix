{ ... }:
{
  programs = {
    zsh.enable = true;
    tmux.enable = true;
  };

  # Expose completion definitions for shells managed by Home Manager.
  environment.pathsToLink = [ "/share/zsh" ];
}
