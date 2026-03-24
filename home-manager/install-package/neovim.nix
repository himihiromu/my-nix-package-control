{ pkgs, ... }:

{
  programs.nixvim = {
    enable = true;

    opts = {
      number = true;
      relativenumber = true;
      expandtab = true;
      shiftwidth = 2;
      tabstop = 2;
      termguicolors = true;
      clipboard = "unnamedplus";
    };

    plugins = {
      web-devicons.enable = true;
      which-key.enable = true;
      bufferline.enable = true;

      lsp = {
        enable = true;
        servers = {
          lua_ls.enable = true;
          rust_analyzer = {
            enable = true;
            installCargo = false;
            installRustc = false;
          };
          pyright.enable = true;
          ts_ls.enable = true;
          nil_ls.enable = true;
        };
      };

      cmp = {
        enable = true;
        settings = {
          sources = [
            { name = "nvim_lsp"; }
            { name = "buffer"; }
            { name = "path"; }
          ];
        };
      };

      treesitter = {
        enable = true;
      };

      telescope.enable = true;

      gitsigns.enable = true;

      auto-session = {
        enable = true;
        settings = {
          auto_session_enable_last_session = false;
          auto_session_root_dir = "~/.local/share/nvim/sessions/";
        };
      };
    };
  };
}
