{ pkgs, ... }:
{
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    shellWrapperName = "y";

    # These utilities enable previews, filtering, archives, and jump plugins.
    extraPackages = with pkgs; [
      fd
      file
      fzf
      jq
      ripgrep
      unar
      zoxide
    ];

    settings.mgr = {
      show_hidden = true;
      sort_by = "natural";
      sort_dir_first = true;
      linemode = "size";
    };
  };
}
