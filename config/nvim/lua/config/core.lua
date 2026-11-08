vim.opt.exrc = true
vim.opt.relativenumber = true
vim.opt.number = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.undofile = true
vim.opt.updatetime = 250
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.signcolumn = "yes:1"
vim.opt.scrolloff = 10
vim.opt.expandtab = true
vim.opt.clipboard = "unnamedplus"
vim.opt.cursorline = true
vim.opt.winborder = "rounded"
vim.opt.foldenable = false
vim.opt.cmdheight = 0

-- local progress = vim.ui.progress_status()
require('vim._core.ui2').enable()

vim.cmd('packadd nvim.undotree')

vim.keymap.set("n", "<space><space>x", "<cmd>source %<CR>")
vim.keymap.set("n", "<space>x", ":.lua<CR>")
vim.keymap.set("v", "<space>x", ":lua<CR>")

-- vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Window navigation left", noremap = true, silent = true })
-- vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Window navigation down", noremap = true, silent = true })
-- vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Window navigation up", noremap = true, silent = true })
-- vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Window navigation right", noremap = true, silent = true })

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down", noremap = true, silent = true })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up", noremap = true, silent = true })

vim.keymap.set("n", "J", "mzJ`z", { desc = "Keep cursor in place when joining lines", noremap = true, silent = true })
vim.keymap.set("v", ">", ">gv", { desc = "Stay in visual when indenting right", noremap = true, silent = true })
vim.keymap.set("v", "<", "<gv", { desc = "Stay in visual when indenting left", noremap = true, silent = true })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Stay centered when moving up", noremap = true, silent = true })
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Stay centered when moving down", noremap = true, silent = true })

vim.keymap.set("v", "p", '"_dP', { desc = "Do not yank on paste", noremap = true, silent = true })
vim.keymap.set("n", "x", '"_x', { desc = "Do not yank on delete", silent = true })

vim.keymap.set("n", "<esc>", "<cmd>nohlsearch<cr>", { desc = "Remove search highlight", noremap = false, silent = true })

-- vim.keymap.set("i", "jj", "<Esc>");
-- vim.keymap.set("i", "jk", "<Esc>");
-- vim.bo.formatexpr = "v:vim.lsp.formatexpr()"

vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlights-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end
})

local esc = vim.api.nvim_replace_termcodes("<Esc>", true, true, true)
vim.api.nvim_create_autocmd('FileType', {
  desc = 'Add Macro to console.log highlighted var',
  pattern = { 'javascript', 'typescript' },
  group = vim.api.nvim_create_augroup('js-log-macro', { clear = true }),
  callback = function()
    vim.fn.setreg('l', "yoconsole.log('" .. esc .. "pa:'" .. esc .. "a, " .. esc .. "pa);" .. esc)
    -- console.log('setreg:', setreg)
    vim.fn.setreg('e', "yoyield* Effect.logInfo('" .. esc .. "pa:'" .. esc .. "a, " .. esc .. "pa);" .. esc)
    -- yield* Effect.logInfo('setreg:', setreg)
  end
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "json",
  callback = function()
    vim.bo.formatprg = "jq ."
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "*" },
  callback = function(args)
    local ft = vim.bo[args.buf].filetype
    local lang = vim.treesitter.language.get_lang(ft)

    if not vim.treesitter.language.add(lang) then
      -- this stupid tracking is here only because
      -- they have added warnings on absent parsers
      local available = vim.g.ts_available
          or require("nvim-treesitter").get_available()
      if not vim.g.ts_available then
        vim.g.ts_available = available
      end
      if vim.tbl_contains(available, lang) then
        require("nvim-treesitter").install(lang)
      end
    end

    if vim.treesitter.language.add(lang) then
      vim.treesitter.start(args.buf, lang)
      -- this is an experimental feature
      -- vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      -- vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
      -- vim.wo[0][0].foldmethod = "expr"
    end
  end,
})

local signs = { Error = ' ', Warn = ' ', Hint = '󰠠 ', Info = ' ' }
vim.diagnostic.config({
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = signs.Error,
      [vim.diagnostic.severity.WARN] = signs.Warn,
      [vim.diagnostic.severity.HINT] = signs.Hint,
      [vim.diagnostic.severity.INFO] = signs.Info,
    }
  }
})
