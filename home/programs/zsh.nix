{ pkgs, ... }:
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autocd = true;
    defaultKeymap = "emacs";

    autosuggestion = {
      enable = true;
      highlight = "fg=8";
      strategy = [ "history" ];
    };

    syntaxHighlighting = {
      enable = true;
      highlighters = [
        "main"
        "brackets"
      ];
      styles = {
        alias = "fg=green";
        builtin = "fg=green";
        command = "fg=green";
        function = "fg=green";
        reserved-word = "fg=yellow";
        path = "fg=cyan";
        path_prefix = "fg=cyan";
        single-hyphen-option = "fg=cyan";
        double-hyphen-option = "fg=cyan";
        single-quoted-argument = "fg=yellow";
        double-quoted-argument = "fg=yellow";
        comment = "fg=8";
        unknown-token = "fg=red";
        bracket-level-1 = "fg=cyan,bold";
        bracket-level-2 = "fg=green,bold";
        bracket-level-3 = "fg=yellow,bold";
      };
    };

    localVariables = {
      SPACESHIP_PROMPT_ADD_NEWLINE = false;
      SPACESHIP_PROMPT_SEPARATE_LINE = true;
      SPACESHIP_DIR_COLOR = "blue";
      SPACESHIP_GIT_BRANCH_COLOR = "yellow";
      SPACESHIP_GIT_STATUS_COLOR = "red";
      SPACESHIP_CHAR_COLOR_SUCCESS = "green";
      SPACESHIP_CHAR_COLOR_FAILURE = "red";
    };

    history = {
      size = 1000;
      save = 1000;
      ignoreSpace = true;
      share = true;
      saveNoDups = true;
    };

    historySubstringSearch.enable = true;

    shellAliases = {
      l = "ls -CF --color=auto";
      la = "ls -A --color=auto";
      ll = "ls -lah --color=auto";
      tree = "tree -a -C";
    };

    initContent = ''
      source ${pkgs.spaceship-prompt}/share/zsh/themes/spaceship.zsh-theme

      bindkey '^[[C' forward-word
      bindkey '^[OC' forward-word
    '';
  };
}
