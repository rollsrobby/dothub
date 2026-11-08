return {
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local harpoon = require("harpoon")
      harpoon:setup()

      vim.keymap.set("n", "<leader>a", function() harpoon:list():add() end, { desc = "Add file to harpoon list" })
      vim.keymap.set("n", "<C-e>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end,
        { desc = "Show list of harpooned files" })

      -- Toggle previous & next buffers stored within Harpoon list
      vim.keymap.set("n", "<C-p>", function() harpoon:list():prev() end, { desc = "Go to previous harpooned file" })
      vim.keymap.set("n", "<C-n>", function() harpoon:list():next() end, { desc = "Go to next harpooned file" })
      -- vim.keymap.set("n", "<C-1>", function() harpoon:list():select(1) end, { desc = "Go to harpooned file 1" })
      -- vim.keymap.set("n", "<C-2>", function() harpoon:list():select(2) end, { desc = "Go to harpooned file 2" })
      -- vim.keymap.set("n", "<C-3>", function() harpoon:list():select(3) end, { desc = "Go to harpooned file 3" })
      -- vim.keymap.set("n", "<C-4>", function() harpoon:list():select(4) end, { desc = "Go to harpooned file 4" })
    end
  }
}
