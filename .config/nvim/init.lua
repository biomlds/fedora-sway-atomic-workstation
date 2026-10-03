vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.mouse = "a"
vim.opt.clipboard = "unnamedplus"
vim.opt.breakindent = true
vim.opt.undofile = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.updatetime = 250
vim.opt.timeoutlen = 400
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.opt.completeopt = { "menu", "menuone", "noselect" }
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

local map = vim.keymap.set
map("n", "<leader>w", "<cmd>write<cr>", { desc = "Write buffer" })
map("n", "<leader>q", "<cmd>quit<cr>", { desc = "Quit window" })
map("n", "<leader>e", "<cmd>Ex<cr>", { desc = "File explorer" })
map("n", "<leader>h", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })
map("n", "<C-h>", "<C-w>h", { desc = "Focus left" })
map("n", "<C-j>", "<C-w>j", { desc = "Focus down" })
map("n", "<C-k>", "<C-w>k", { desc = "Focus up" })
map("n", "<C-l>", "<C-w>l", { desc = "Focus right" })
map("v", "<", "<gv", { desc = "Indent left" })
map("v", ">", ">gv", { desc = "Indent right" })
map("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })
map("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
map("n", "<leader>d", vim.diagnostic.open_float, { desc = "Diagnostic details" })

vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight yanked text",
  callback = function() vim.highlight.on_yank({ timeout = 180 }) end,
})

vim.api.nvim_create_autocmd("BufWritePre", {
  desc = "Remove trailing whitespace",
  pattern = "*",
  callback = function()
    local view = vim.fn.winsaveview()
    vim.cmd([[keeppatterns %s/\s\+$//e]])
    vim.fn.winrestview(view)
  end,
})

-- Catppuccin Mocha with Sapphire accent.
--
-- The colorscheme itself is the official Catppuccin Neovim port, vendored
-- under lua/catppuccin/ at the commit pinned in versions.env. See
-- lua/catppuccin/VENDORED.md for the pin and the upgrade procedure.
--
-- auto_integrations = false: we vendor the core only and install none of the
-- plugins that the integration files theme, so there is nothing to detect.
require("catppuccin").setup({
  flavour = "mocha",
  background = { light = "latte", dark = "mocha" },
  auto_integrations = false,
  -- Keep :terminal inside Neovim on the same palette as Foot and VS Code.
  term_colors = true,
})

vim.cmd.colorscheme("catppuccin-mocha")
