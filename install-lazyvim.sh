#!/usr/bin/env bash
set -e

echo "==> LazyVim Installation Script"
echo ""

# Detect OS
OS="$(uname -s)"
case "$OS" in
  Darwin*) PLATFORM="macos" ;;
  Linux*)  PLATFORM="linux" ;;
  *)       echo "Unsupported OS: $OS"; exit 1 ;;
esac

echo "Platform: $PLATFORM"
echo ""

# 1. Install Neovim
echo "==> Checking Neovim..."
if command -v nvim &> /dev/null; then
  NVIM_VERSION=$(nvim --version | head -1 | awk '{print $2}')
  echo "✓ Neovim already installed: $NVIM_VERSION"
else
  echo "Installing Neovim..."
  if [ "$PLATFORM" = "macos" ]; then
    brew install neovim
  elif [ "$PLATFORM" = "linux" ]; then
    if command -v apt-get &> /dev/null; then
      sudo apt-get update && sudo apt-get install -y neovim
    elif command -v yum &> /dev/null; then
      sudo yum install -y neovim
    else
      echo "Please install Neovim manually"
      exit 1
    fi
  fi
  echo "✓ Neovim installed"
fi

# 2. Backup existing config
echo ""
echo "==> Checking existing config..."
if [ -d "$HOME/.config/nvim" ]; then
  BACKUP_DIR="$HOME/.config/nvim.backup.$(date +%Y%m%d_%H%M%S)"
  echo "Backing up to: $BACKUP_DIR"
  mv "$HOME/.config/nvim" "$BACKUP_DIR"
  echo "✓ Backup created"
else
  echo "✓ No existing config"
fi

# 3. Install LazyVim
echo ""
echo "==> Installing LazyVim..."
git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"
rm -rf "$HOME/.config/nvim/.git"
echo "✓ LazyVim starter installed"

# 4. Configure LazyVim
echo ""
echo "==> Configuring LazyVim..."

# 4.1 Configure options
cat > "$HOME/.config/nvim/lua/config/options.lua" << 'EOF'
-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

local opt = vim.opt

-- 相对行号（LazyVim 已默认启用，这里显式声明）
opt.relativenumber = true

-- 文本宽度
opt.textwidth = 180

-- 关闭自动格式化
vim.g.autoformat = false

-- 空格可视化
opt.list = true
opt.listchars = {
  space = "·",
  tab = "→ ",
  trail = "·",
  extends = "⟩",
  precedes = "⟨",
}

-- 缩进指示
opt.breakindent = true
EOF

# 4.2 Configure keymaps
cat > "$HOME/.config/nvim/lua/config/keymaps.lua" << 'EOF'
-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

-- Normal mode
map("n", ";", ":", { desc = "Command mode" })
map("n", "H", "^", { desc = "Go to line start" })
map("n", "L", "$", { desc = "Go to line end" })

-- Insert mode (Emacs-style)
map("i", "<C-b>", "<Left>", { desc = "Move left" })
map("i", "<C-f>", "<Right>", { desc = "Move right" })
map("i", "<C-p>", "<Up>", { desc = "Move up" })
map("i", "<C-n>", "<Down>", { desc = "Move down" })
map("i", "<C-h>", "<BS>", { desc = "Delete backward" })
map("i", "<C-d>", "<Del>", { desc = "Delete forward" })
map("i", "<C-k>", "<C-o>D", { desc = "Kill to line end" })
map("i", "<C-u>", "<C-o>d^", { desc = "Kill to line start" })
EOF

# 4.3 Configure autocmds
cat > "$HOME/.config/nvim/lua/config/autocmds.lua" << 'EOF'
-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

local autocmd = vim.api.nvim_create_autocmd

-- 自动保存：失焦时保存
autocmd("FocusLost", {
  pattern = "*",
  command = "silent! wa",
  desc = "Auto save on focus lost",
})

-- 自动保存：1秒延迟保存
local save_timer = nil
autocmd({ "TextChanged", "TextChangedI" }, {
  pattern = "*",
  callback = function()
    if save_timer then
      vim.fn.timer_stop(save_timer)
    end
    save_timer = vim.fn.timer_start(1000, function()
      if vim.bo.modified and vim.bo.buftype == "" then
        vim.cmd("silent! write")
      end
    end)
  end,
  desc = "Auto save after 1s delay",
})
EOF

# 4.4 Configure lazy.lua (SSH for git)
sed -i.bak '/^require("lazy").setup({$/a\
  git = {\
    url_format = "git@github.com:%s.git",\
  },' "$HOME/.config/nvim/lua/config/lazy.lua"

# 4.5 Configure plugins
mkdir -p "$HOME/.config/nvim/lua/plugins"

# LSP configuration
cat > "$HOME/.config/nvim/lua/plugins/lsp.lua" << 'EOF'
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- JavaScript/TypeScript
        ts_ls = {},
        biome = {},
        -- Rust
        rust_analyzer = {},
        -- Python
        pyright = {},
        ruff = {},
      },
    },
  },
}
EOF

# Formatting configuration
cat > "$HOME/.config/nvim/lua/plugins/formatting.lua" << 'EOF'
return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        javascript = { "biome" },
        typescript = { "biome" },
        javascriptreact = { "biome" },
        typescriptreact = { "biome" },
        json = { "biome" },
        jsonc = { "biome" },
      },
    },
  },
}
EOF

# Theme configuration
cat > "$HOME/.config/nvim/lua/plugins/theme.lua" << 'EOF'
return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "monokai-pro",
    },
  },
  {
    "loctvl842/monokai-pro.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("monokai-pro").setup()
    end,
  },
}
EOF

# Completion configuration (Tab to accept)
cat > "$HOME/.config/nvim/lua/plugins/completion.lua" << 'EOF'
return {
  {
    "saghen/blink.cmp",
    opts = {
      keymap = {
        preset = "none",
        -- Tab: 确认补全
        ["<Tab>"] = { "select_and_accept", "fallback" },
        -- Shift-Tab: 向上选择
        ["<S-Tab>"] = { "select_prev", "fallback" },
        -- Ctrl-n/p: 上下选择（Emacs 风格）
        ["<C-n>"] = { "select_next", "fallback" },
        ["<C-p>"] = { "select_prev", "fallback" },
        -- Enter: 仅在明确选择时确认，否则换行
        ["<CR>"] = { "accept", "fallback" },
        -- Ctrl-Space: 显示补全菜单
        ["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
        -- Ctrl-e: 隐藏补全
        ["<C-e>"] = { "hide" },
        -- Ctrl-u/d: 文档滚动
        ["<C-u>"] = { "scroll_documentation_up", "fallback" },
        ["<C-d>"] = { "scroll_documentation_down", "fallback" },
      },
    },
  },
}
EOF

echo "✓ Configuration files created"

echo ""
echo "==> Installation complete!"
echo ""
echo "Next steps:"
echo "  1. Run: nvim"
echo "  2. Wait for plugins to install (LSP servers will auto-install via Mason)"
echo "  3. Check installation: :Mason"
echo "  4. Restart nvim after all plugins are installed"
echo ""
echo "Configured features:"
echo "  - Relative line numbers"
echo "  - Auto-save (focus lost + 1s delay)"
echo "  - Emacs-style insert mode keybindings"
echo "  - ; for command mode"
echo "  - H/L for line start/end"
echo "  - Tab to accept completion (Ctrl-n/p to navigate)"
echo "  - Monokai Pro theme"
echo "  - LSP: TypeScript, Biome, Rust, Python"
echo "  - Formatter: Biome (replaces ESLint + Prettier)"
