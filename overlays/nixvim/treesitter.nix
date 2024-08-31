{
  plugins = {
    treesitter = {
      enable = true;
      nixGrammars = true;
      settings = {
        ensure_installed = "all";
        indent.enable = true;
      };
    };
    treesitter-context = {
      enable = true;
      settings = {
        max_lines = 2;
      };
    };

    haskell-scope-highlighting.enable = true;

    rainbow-delimiters.enable = true;
  };
}
