{
  plugins.none-ls = {
    enable = true;
    sources = {
      diagnostics = {
        golangci_lint.enable = false;
        ktlint.enable = false;
        statix.enable = true;
      };
      formatting = {
        fantomas.enable = true;
        gofmt.enable = false;
        goimports.enable = false;
        ktlint.enable = false;
        nixfmt.enable = true;
        markdownlint.enable = true;
        shellharden.enable = true;
        shfmt.enable = true;
      };
    };
  };
}
