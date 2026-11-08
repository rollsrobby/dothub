return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    ---@module 'snacks'
    ---@type snacks.Config
    opts = {
      input = { enabled = true },
      statuscolumn = { enabled = true },
      words = { enabled = true },
      image = { enabled = true },
      -- scroll = { enabled = true },
      picker = {
        enabled = true,
        layout = { preset = "ivy" },
      }
    },
    keys = {
      { "<leader>.",  function() Snacks.scratch() end,                                        desc = "Toggle Scratch Buffer" },
      { "<leader>S",  function() Snacks.scratch.select() end,                                 desc = "Select Scratch Buffer" },
      { "<leader>n",  function() Snacks.notifier.show_history() end,                          desc = "Notification History" },
      { "<leader>bd", function() Snacks.bufdelete() end,                                      desc = "Delete Buffer" },
      { "<leader>ba", function() Snacks.bufdelete.all() end,                                  desc = "Delete all Buffers" },
      { "<leader>bo", function() Snacks.bufdelete.other() end,                                desc = "Delete other Buffers" },
      -- { "<leader>cR", function() Snacks.rename.rename_file() end,      desc = "Rename File" },
      { "<leader>gB", function() Snacks.gitbrowse() end,                                      desc = "Git Browse" },
      { "<leader>gb", function() Snacks.git.blame_line() end,                                 desc = "Git Blame Line" },
      { "<leader>gh", function() Snacks.lazygit.log_file() end,                               desc = "Lazygit Current File History" },
      { "<leader>gg", function() Snacks.lazygit() end,                                        desc = "Lazygit" },
      { "<leader>gl", function() Snacks.lazygit.log() end,                                    desc = "Lazygit Log (cwd)" },
      { "<leader>un", function() Snacks.notifier.hide() end,                                  desc = "Dismiss All Notifications" },
      { "]]",         function() Snacks.words.jump(vim.v.count1) end,                         desc = "Next Reference",              mode = { "n" } },
      { "[[",         function() Snacks.words.jump(-vim.v.count1) end,                        desc = "Prev Reference",              mode = { "n" } },
      { "<leader>fd", function() Snacks.picker.files() end,                                   desc = "Find in directory" },
      { "<leader>fn", function() Snacks.picker.files({ cwd = vim.fn.stdpath("config") }) end, desc = "Find in nvim config dir" },
      { "<leader>ff", function() Snacks.picker.git_files() end,                               desc = "Find git Files" },
      { "<leader>fb", function() Snacks.picker.buffers() end,                                 desc = "Find Buffers" },
      { "<leader>fh", function() Snacks.picker.help() end,                                    desc = "Find help tags" },
      { "<leader>fc", function() Snacks.picker.grep_word() end,                               desc = "Find String" },
      { "<leader>fg", function() require("plugins.snacks.multigrep").pick() end,              desc = "Grep in files" },
    },
  }
}
