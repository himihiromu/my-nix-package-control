{ config, pkgs, inputs, ... }:
let
  userOptions = import ../user-options/options.nix;
in
{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = userOptions.username;
  home.homeDirectory = "/home/${userOptions.username}";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  home.stateVersion = "24.05";

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    # Core tools
    git
    curl
    wget
    htop
    tree
    ripgrep
    fd
    jq
    bat
    eza

    # Python environment
    python3
    python3Packages.pip
    python3Packages.virtualenv
    python3Packages.ipython
    python3Packages.black
    python3Packages.pylint
    python3Packages.pytest
    python3Packages.numpy
    python3Packages.pandas
    python3Packages.requests

    # Development tools
    nodejs
    yarn
    docker-compose
    
    # Neovim (from nightly overlay)
    neovim
  ];

  # Git configuration
  programs.git = {
    enable = true;
    userName = userOptions.username;
    userEmail = userOptions.gitEmail;
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = false;
      core.editor = "nvim";
    };
  };

  # Neovim configuration
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    defaultEditor = true;
    plugins = with pkgs.vimPlugins; [
      # File navigation
      nvim-tree-lua
      telescope-nvim
      telescope-fzf-native-nvim
      
      # Git integration
      vim-fugitive
      gitsigns-nvim
      
      # Language support & LSP
      nvim-lspconfig
      nvim-cmp
      cmp-nvim-lsp
      cmp-buffer
      cmp-path
      cmp-cmdline
      nvim-treesitter.withAllGrammars
      
      # Snippets
      luasnip
      cmp_luasnip
      
      # Language specific
      vim-nix
      
      # Editor enhancements
      lualine-nvim
      nvim-web-devicons
      vim-commentary
      vim-surround
      nvim-autopairs
      indent-blankline-nvim
      
      # Color schemes
      gruvbox-nvim
      onedark-nvim
    ];
    extraConfig = ''
      " Basic settings
      set number relativenumber
      set expandtab tabstop=2 shiftwidth=2
      set ignorecase smartcase
      set hidden
      set mouse=a
      set cursorline
      set termguicolors
      
      " Set leader key
      let mapleader = " "
      
      " Quick save and quit
      nnoremap <leader>w :w<CR>
      nnoremap <leader>q :q<CR>
      
      " Split navigation
      nnoremap <C-h> <C-w>h
      nnoremap <C-j> <C-w>j
      nnoremap <C-k> <C-w>k
      nnoremap <C-l> <C-w>l
      
      " Search highlighting
      set hlsearch incsearch
      nnoremap <leader>/ :nohlsearch<CR>
      
      " Python specific settings
      autocmd FileType python setlocal expandtab shiftwidth=4 tabstop=4
      
      " Colorscheme
      colorscheme gruvbox
    '';
    extraLuaConfig = ''
      -- Telescope setup
      local telescope = require('telescope')
      telescope.setup{
        defaults = {
          file_ignore_patterns = {".git/", "node_modules/", "%.pyc"},
        }
      }
      telescope.load_extension('fzf')
      
      -- Telescope keymaps
      vim.keymap.set('n', '<C-p>', ':Telescope find_files<CR>')
      vim.keymap.set('n', '<leader>fg', ':Telescope live_grep<CR>')
      vim.keymap.set('n', '<leader>fb', ':Telescope buffers<CR>')
      vim.keymap.set('n', '<leader>fh', ':Telescope help_tags<CR>')
      
      -- Nvim-tree setup
      require('nvim-tree').setup{
        view = {
          width = 30,
        },
        filters = {
          dotfiles = false,
        },
      }
      
      -- Nvim-tree keymaps
      vim.keymap.set('n', '<leader>n', ':NvimTreeToggle<CR>')
      vim.keymap.set('n', '<leader>f', ':NvimTreeFindFile<CR>')
      
      -- Lualine setup
      require('lualine').setup{
        options = {
          theme = 'gruvbox',
          icons_enabled = true,
        }
      }
      
      -- Gitsigns setup
      require('gitsigns').setup()
      
      -- Treesitter setup
      require('nvim-treesitter.configs').setup{
        highlight = {
          enable = true,
        },
        indent = {
          enable = true,
        },
      }
      
      -- Autopairs setup
      require('nvim-autopairs').setup{}
      
      -- Indent-blankline setup
      require('ibl').setup{
        indent = {
          char = "▏",
        },
      }
      
      -- LSP Configuration
      local lspconfig = require('lspconfig')
      local capabilities = require('cmp_nvim_lsp').default_capabilities()
      
      -- Python LSP
      lspconfig.pyright.setup{
        capabilities = capabilities,
      }
      
      -- Nix LSP
      lspconfig.nil_ls.setup{
        capabilities = capabilities,
      }
      
      -- TypeScript/JavaScript LSP
      lspconfig.tsserver.setup{
        capabilities = capabilities,
      }
      
      -- Completion setup
      local cmp = require('cmp')
      local luasnip = require('luasnip')
      
      cmp.setup{
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-b>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<C-e>'] = cmp.mapping.abort(),
          ['<CR>'] = cmp.mapping.confirm({ select = true }),
          ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { 'i', 's' }),
          ['<S-Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { 'i', 's' }),
        }),
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
        }, {
          { name = 'buffer' },
          { name = 'path' },
        })
      }
      
      -- Use buffer source for `/` and `?`
      cmp.setup.cmdline({ '/', '?' }, {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = 'buffer' }
        }
      })
      
      -- Use cmdline & path source for ':'
      cmp.setup.cmdline(':', {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = 'path' }
        }, {
          { name = 'cmdline' }
        })
      })
    '';
  };


  # Bash configuration
  programs.bash = {
    enable = true;
    enableCompletion = true;
    bashrcExtra = ''
      # Custom aliases
      alias ll='eza -la'
      alias la='eza -a'
      alias l='eza -l'
      alias gs='git status'
      alias gd='git diff'
      alias gc='git commit'
      alias gp='git push'
      alias gl='git log --oneline --graph'
      
      # Python aliases
      alias py='python3'
      alias pip='python3 -m pip'
      alias venv='python3 -m venv'
      alias activate='source venv/bin/activate'
      
      # Navigation aliases
      alias ..='cd ..'
      alias ...='cd ../..'
      alias ....='cd ../../..'
      
      # Safety aliases
      alias rm='rm -i'
      alias cp='cp -i'
      alias mv='mv -i'
      
      # Colorize output
      alias grep='grep --color=auto'
      alias fgrep='fgrep --color=auto'
      alias egrep='egrep --color=auto'
    '';
  };

  # Direnv for automatic environment loading
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # FZF configuration
  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
    defaultCommand = "fd --type f --hidden --follow --exclude .git";
    defaultOptions = [
      "--height 40%"
      "--layout=reverse"
      "--border"
      "--preview 'bat --color=always --style=numbers --line-range=:500 {}'"
    ];
  };

  # Bat configuration (better cat)
  programs.bat = {
    enable = true;
    config = {
      theme = "gruvbox-dark";
      style = "numbers,changes,header";
    };
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}