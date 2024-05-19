{
  plugins = {
    lsp = {
      enable = true;
      servers = {
        bashls.enable = true;
        clangd.enable = false;
        elixirls.enable = true;
        nixd.enable = true;
        helm-ls.enable = true;
        hls.enable = true;
        jsonls.enable = true;
     };
      keymaps.lspBuf = {
        "gd" = "definition";
        "gD" = "references";
        "gt" = "type_definition";
        "gi" = "implementation";
        "K" = "hover";
      };
    };
    lsp-lines = {
      enable = true;
      currentLine = true;
    };
  };
}
