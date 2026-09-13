{ pkgs, ... }:
{
  programs = {
    yazi = {
      enable = true;

      settings.yazi.mgr = {
        show_hidden = true;
        sort_by = "natural";
        sort_dir_first = true;
        linemode = "size";
      };
    };

    zoxide = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = false;
      enableFishIntegration = false;
      enableXonshIntegration = false;
    };

    zsh.interactiveShellInit = ''
      # Open Yazi and change the shell directory to its final location on exit.
      function y() {
        local tmp="$(mktemp -t "yazi-cwd.XXXXX")"
        command yazi "$@" --cwd-file="$tmp"

        if cwd="$(<"$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
          builtin cd -- "$cwd"
        fi

        rm -f -- "$tmp"
      }
    '';
  };

  environment.systemPackages = [
    pkgs.wl-clipboard
  ];
}
