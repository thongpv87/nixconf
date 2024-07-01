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
  };

  diagnostics.virtual_lines.only_current_line = true;
}
