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

local mocha = {
  base = "#1e1e2e", mantle = "#181825", surface0 = "#313244",
  surface1 = "#45475a", text = "#cdd6f4", subtext0 = "#a6adc8",
  sapphire = "#74c7ec", blue = "#89b4fa", green = "#a6e3a1",
  yellow = "#f9e2af", peach = "#fab387", red = "#f38ba8", mauve = "#cba6f7",
}
vim.api.nvim_set_hl(0, "Normal", { fg = mocha.text, bg = mocha.base })
vim.api.nvim_set_hl(0, "NormalFloat", { fg = mocha.text, bg = mocha.mantle })
vim.api.nvim_set_hl(0, "FloatBorder", { fg = mocha.sapphire, bg = mocha.mantle })
vim.api.nvim_set_hl(0, "CursorLine", { bg = mocha.surface0 })
vim.api.nvim_set_hl(0, "LineNr", { fg = mocha.surface1 })
vim.api.nvim_set_hl(0, "CursorLineNr", { fg = mocha.sapphire, bold = true })
vim.api.nvim_set_hl(0, "Comment", { fg = mocha.subtext0, italic = true })
vim.api.nvim_set_hl(0, "String", { fg = mocha.green })
vim.api.nvim_set_hl(0, "Function", { fg = mocha.blue })
vim.api.nvim_set_hl(0, "Keyword", { fg = mocha.mauve })
vim.api.nvim_set_hl(0, "Type", { fg = mocha.yellow })
vim.api.nvim_set_hl(0, "DiagnosticError", { fg = mocha.red })
vim.api.nvim_set_hl(0, "DiagnosticWarn", { fg = mocha.peach })
vim.api.nvim_set_hl(0, "DiagnosticInfo", { fg = mocha.sapphire })
vim.api.nvim_set_hl(0, "DiagnosticHint", { fg = mocha.green })
