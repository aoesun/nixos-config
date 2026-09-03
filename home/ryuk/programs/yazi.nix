{ pkgs, ... }:
{
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    shellWrapperName = "y";

    # Yazi's Nix package already includes its recommended preview and search
    # tools. Add the native clipboard helper needed by the Wayland session.
    extraPackages = with pkgs; [
      wl-clipboard
    ];

    settings.mgr = {
      show_hidden = true;
      sort_by = "natural";
      sort_dir_first = true;
      linemode = "size";
    };
  };
}
