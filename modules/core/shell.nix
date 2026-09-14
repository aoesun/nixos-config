{ ... }:
{
  programs = {
    zsh.enable = true;
  };

  # Expose completion definitions for shells managed by Home Manager.
  environment.pathsToLink = [ "/share/zsh" ];
}
