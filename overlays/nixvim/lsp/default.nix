{
  plugins = {
    lsp = {
      enable = true;
      servers = {
        bashls.enable = true;
        clangd.enable = false;
        pyright.enable = true;
        ts_ls.enable = true;
        tailwindcss.enable = true;
        nushell.enable = true;
        html.enable = true;
        elixirls.enable = true;
        nixd.enable = true;
        helm_ls.enable = true;
        hls = {
          enable = true;
          installGhc = true;
        };
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
