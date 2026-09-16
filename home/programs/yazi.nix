{ ... }:
{
  programs = {
    yazi = {
      enable = true;
      enableZshIntegration = true;
      shellWrapperName = "y";
      settings.mgr = {
        show_hidden = true;
        sort_by = "natural";
        sort_dir_first = true;
        linemode = "size";
      };

      keymap.mgr.prepend_keymap = [
        {
          on = "!";
          run = ''shell "$SHELL" --block'';
          desc = "Open shell here";
        }
        {
          on = [
            "g"
            "l"
          ];
          run = ''shell "lazygit" --block'';
          desc = "Open LazyGit here";
        }
      ];
    };

    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
