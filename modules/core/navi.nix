{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.navi
  ];

  programs.zsh.interactiveShellInit = ''
    if [[ $options[zle] = on ]]; then
      eval "$(${pkgs.navi}/bin/navi widget zsh)"
    fi
  '';
}
