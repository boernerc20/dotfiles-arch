-- Bootstrap lazy.nvim (unchanged)  
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"  
if not vim.loop.fs_stat(lazypath) then  
  vim.fn.system({  
    "git", "clone", "--filter=blob:none",  
    "https://github.com/folke/lazy.nvim.git", lazypath,  
  })  
end  
vim.opt.rtp:prepend(lazypath)  

require("lazy").setup({  
  {  
    "AlphaTechnolog/pywal.nvim",    -- the Lua reimplementation  
    name = "pywal",                 -- alias so we can call it easily  
    lazy = false,                   -- load immediately  
    config = function()  
      -- ensure true‑color  
      vim.opt.termguicolors = true  
      -- initialize from your existing ~/.cache/wal/colors-wal.vim  
      require("pywal").setup()  

      -- optional: auto‑reload on BufEnter/WinEnter  
      vim.cmd [[  
        augroup PywalReload  
          autocmd!  
          autocmd BufEnter,WinEnter * silent! lua require("pywal").reload()  
        augroup END  
      ]]  

      -- optional: manual reload mapping  
      vim.keymap.set("n", "<leader>wr", function()  
        require("pywal").reload()  
      end, { desc = "Reload Pywal theme" })  
    end,  
  }  
})


--require("lazy").setup({
--Tokyo Night Theme
--  {
--    "folke/tokyonight.nvim",
--    lazy = false,
--    priority = 1000,
--    config = function()
--      vim.cmd("colorscheme tokyonight-moon") -- You can use "night", "storm", "moon", or "day"
--    end,
--  }
--})

-- Basic Settings
vim.opt.number = true           -- Show line numbers
vim.opt.relativenumber = true   -- Relative line numbers
vim.opt.mouse = 'a'             -- Enable mouse support
vim.opt.clipboard = 'unnamedplus' -- Use system clipboard
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.termguicolors = true

-- Keymaps
vim.keymap.set('n', '<Space>', '<Nop>', { silent = true, remap = false })
-- Leader key (Space)
vim.g.mapleader = ' '

-- Copy (yank) to system clipboard with <leader>c
vim.keymap.set({ 'n', 'v' }, '<leader>c', '"+y', { desc = 'Copy to system clipboard' })

-- Paste from system clipboard with <leader>v
vim.keymap.set('n', '<leader>v', '"+p', { desc = 'Paste from system clipboard' })
vim.keymap.set('v', '<leader>v', '"+p', { desc = 'Paste from clipboard over selection' })

vim.g.clipboard = {
  name = "wl-clipboard",
  copy = {
    ["+"] = "wl-copy",
    ["*"] = "wl-copy",
  },
  paste = {
    ["+"] = "wl-paste --no-newline",
    ["*"] = "wl-paste --no-newline",
  },
  cache_enabled = true,
}
-- Basic Plugin Setup (optional)
-- To use plugins, install a plugin manager like lazy.nvim or packer.nvim
-- Let me know if you want to set one up

