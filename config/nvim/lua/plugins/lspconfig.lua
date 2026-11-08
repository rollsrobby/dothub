return {
  "neovim/nvim-lspconfig",
  config = function()
    local capabilities = {
      general = {
        positionEncodings = { 'utf-16' }
      }
    }
    capabilities = require('blink.cmp').get_lsp_capabilities(capabilities);

    local on_attach = function(_, bufnr)
      local opts = { noremap = true, silent = true, buffer = bufnr }
      vim.keymap.set('n', 'grd', function() Snacks.picker.lsp_definitions() end, opts)
      vim.keymap.set('n', 'grr', function() Snacks.picker.lsp_references() end, opts)
      vim.keymap.set('n', 'gri', function() Snacks.picker.lsp_implementations() end, opts)
      vim.keymap.set('n', '<leader>D', function() Snacks.picker.diagnostics_buffer() end, opts)
      vim.keymap.set('n', 'gra', vim.lsp.buf.code_action, opts)
    end

    vim.lsp.config('*', {
      root_markers = { '.git', '.bare' },
      on_attach = on_attach,
      capabilities = capabilities
    })

    -- Project-specific settings (e.g. experimental.configFile for a monorepo's
    -- CSS entry point) belong in that project's .nvim.lua, which exrc loads.
    -- Neovim merges them over this global config.
    vim.lsp.config('tailwindcss', {
      root_dir = function(bufnr, on_dir)
        -- Prefer the nearest directory holding a Tailwind config, so per-package
        -- configs in monorepos work. Otherwise fall back to the workspace or repo root.
        local root = vim.fs.root(bufnr, {
          'tailwind.config.js', 'tailwind.config.cjs', 'tailwind.config.mjs', 'tailwind.config.ts',
        }) or vim.fs.root(bufnr, { 'pnpm-workspace.yaml', '.git', '.bare' })
        if root then
          on_dir(root)
        end
      end,
      settings = {
        tailwindCSS = {
          classAttributes = {
            'class',
            'className',
            'class:list',
            'classList',
            'ngClass',
            'containerClassName',
            '.*ClassName',
          },
        },
      },
    })

    local log_dir = vim.fs.joinpath(vim.fn.stdpath("state"), "roslyn_ls", "logs")
    vim.fn.mkdir(log_dir, "p")
    vim.lsp.config('roslyn_ls', {
      cmd = {
        'Microsoft.CodeAnalysis.LanguageServer',
        '--logLevel',
        'Information',
        '--extensionLogDirectory',
        log_dir,
        '--stdio'
      },
      on_attach = on_attach,
      capabilities = capabilities
    })

    vim.lsp.config('bicep', {
      cmd = { 'Bicep.LangServer' }
    })

    vim.lsp.enable({
      'bicep',
      'biome',
      'tsc',
      'jsonls',
      'tailwindcss',
      'docker-language-server',
      'yamlls',
      'lua_ls',
      'nixd',
      'roslyn_ls',
      'tombi'
    })
  end
}
