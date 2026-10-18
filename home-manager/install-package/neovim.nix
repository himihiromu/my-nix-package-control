{ pkgs, ... }:
let
  skkeleton = pkgs.vimUtils.buildVimPlugin {
    pname = "skkeleton";
    version = "unstable-2026-08-27";
    src = pkgs.fetchFromGitHub {
      owner = "vim-skk";
      repo = "skkeleton";
      rev = "cb6e529dada798929deefd879e32e418dab1c6ac";
      hash = "sha256-ydZdzknNz9baKPZ5FDHY264evzZ3+50ZVi1VuhwXv4M=";
    };
  };
in
{
  programs.nixvim = {
    enable = true;
    nixpkgs.source = pkgs.path;

    extraPackages = [ pkgs.deno ];
    extraPlugins = [
      pkgs.vimPlugins.denops-vim
      skkeleton
    ];

    extraConfigLua = ''
      vim.fn['skkeleton#config']({
        globalDictionaries = { '${pkgs.skkDictionaries.l}/share/skk/SKK-JISYO.L' },
        eggLikeNewline = true,
      })
      vim.fn['skkeleton#register_keymap']('input', 'l', 'disable')
    '';

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
      nvim-tree.enable = true;
      fff.enable = true;

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

    keymaps = [
      {
        mode = "n";
        key = "<leader>f";
        action = "<cmd>lua require('fff').find_files()<CR>";
        options = {
          desc = "FFF: find files";
        };
      }
      {
        mode = [
          "i"
          "c"
        ];
        key = "<C-j>";
        action = "<Plug>(skkeleton-enable)";
        options = {
          desc = "SKK: skkeletonを起動";
        };
      }
    ];
  };
}
