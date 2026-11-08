return {
  {
    "rcarriga/nvim-dap-ui",
    dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")
      dapui.setup()

      vim.keymap.set('n', '<leader>db', function() dap.toggle_breakpoint() end, { desc = 'Toggle breakpoint' })
      vim.keymap.set('n', '<leader>dc', function() dap.continue() end, { desc = 'Start debugging' })
      vim.keymap.set('n', '<leader>dn', function() dap.step_over() end, { desc = 'Step over' })
      vim.keymap.set('n', '<leader>dO', function() dap.step_out() end, { desc = 'Step out ' })
      vim.keymap.set('n', '<leader>di', function() dap.step_into() end, { desc = 'Step into' })
      vim.keymap.set('n', '<leader>ds', function() dap.stop() end, { desc = 'Stop debugging' })
      vim.keymap.set('n', '<leader>dq', function()
        dap.disconnect({ terminateDebugger = true })
        dapui.close()
      end, { desc = 'Quit debugging' })
      vim.keymap.set('n', '<leader>dt', function() dapui.toggle() end, { desc = 'Toggle dap-ui' })

      vim.api.nvim_set_hl(0, 'DapStoppedSign', { fg = '#e0af68' })
      vim.api.nvim_set_hl(0, 'DapStoppedLine', { bg = '#373640' })
      vim.api.nvim_set_hl(0, 'DapBreakpointSign', { fg = '#ffa07a' })
      vim.api.nvim_set_hl(0, 'DapBreakpointConditionSign', { fg = '#00bfff' })
      vim.api.nvim_set_hl(0, 'DapBreakpointRejectedSign', { fg = '#db4b4b' })

      vim.fn.sign_define('DapStopped', { text = '󰁕 ', texthl = "DapStoppedSign", linehl = "DapStoppedLine" })
      vim.fn.sign_define('DapBreakpoint', { text = ' ', texthl = "DapBreakpointSign" })
      vim.fn.sign_define('DapBreakpointCondition', { text = ' ', texthl = "DapBreakpointConditionSign" })
      vim.fn.sign_define('DapBreakpointRejected', { text = ' ', texthl = 'DapBreakpointRejectedSign' })
      vim.fn.sign_define('DapLogPoint', { text = '.>' })

      dap.adapters.coreclr = {
        type = "executable",
        command = "netcoredbg",
        args = { "--interpreter=vscode" }
      }

      -- The solution folder bounds the search; the file being debugged does not
      -- decide which project to attach to (the started startup project does).
      local function find_solution_root()
        local dir = vim.fn.expand('%:p:h')
        while dir ~= '' do
          if #vim.fn.glob(dir .. '/*.sln', false, true) > 0
            or #vim.fn.glob(dir .. '/*.slnx', false, true) > 0 then
            return dir
          end
          local parent = vim.fn.fnamemodify(dir, ':h')
          if parent == dir then
            break
          end
          dir = parent
        end
        return vim.fn.getcwd()
      end

      -- Resolve a dotnet process's dll to an absolute path (args may be relative)
      local function resolve_dll_path(pid, token)
        if token:sub(1, 1) == '/' then
          return token
        end
        local cwd = vim.loop.fs_readlink('/proc/' .. pid .. '/cwd')
        return cwd and (cwd .. '/' .. token) or token
      end

      -- All running dotnet processes whose dll lives inside the solution folder.
      local function list_solution_dlls(root)
        local handle = io.popen('ps -eo pid=,args=')
        if handle == nil then
          return {}
        end
        local output = handle:read('*a')
        handle:close()

        local found = {}
        for line in output:gmatch('[^\n]+') do
          local pid, args = line:match('^%s*(%d+)%s+(.*)$')
          if pid then
            local dll_token
            for token in args:gmatch('%S+') do
              if token:match('%.dll$') then
                dll_token = token
              end
            end
            if dll_token then
              local dll = resolve_dll_path(pid, dll_token)
              if vim.startswith(dll, root .. '/') then
                table.insert(found, {
                  pid = tonumber(pid),
                  dll = dll,
                  rel = dll:sub(#root + 2),
                })
              end
            end
          end
        end
        return found
      end

      -- Last process attached per solution, so it is offered first next time
      local last_attached = {}

      local function get_dotnet_pid(root)
        local candidates = list_solution_dlls(root)
        if #candidates == 0 then
          return nil
        end

        local remembered = last_attached[root]
        local ordered = {}
        for _, c in ipairs(candidates) do
          if c.dll == remembered then
            table.insert(ordered, 1, c)
          else
            table.insert(ordered, c)
          end
        end

        local choice = ordered[1]
        if #ordered > 1 then
          local lines = { 'Several dotnet projects running in this solution. Attach to:' }
          for i, c in ipairs(ordered) do
            table.insert(lines, string.format('%d. %s  (PID %d)%s', i, c.rel, c.pid,
              c.dll == remembered and '  [last]' or ''))
          end
          choice = ordered[vim.fn.inputlist(lines)]
        end

        if choice then
          last_attached[root] = choice.dll
          return choice.pid
        end
        return nil
      end

      local function list_projects(root)
        local files = vim.fn.globpath(root, '**/*.csproj', false, true)
        return vim.tbl_filter(function(f)
          return not f:find('/bin/', 1, true) and not f:find('/obj/', 1, true)
        end, files)
      end

      local function is_functions_project(csproj)
        if vim.loop.fs_stat(vim.fn.fnamemodify(csproj, ':h') .. '/host.json') then
          return true
        end
        local f = io.open(csproj, 'r')
        if f == nil then
          return false
        end
        local content = f:read('*a')
        f:close()
        return content:find('Microsoft.NET.Sdk.Functions', 1, true) ~= nil
          or content:find('Microsoft.Azure.Functions', 1, true) ~= nil
      end

      local last_started = {}

      local function run_project()
        local root = find_solution_root()
        local projects = list_projects(root)
        if #projects == 0 then
          vim.notify('No .csproj found under ' .. root, vim.log.levels.ERROR)
          return
        end

        local remembered = last_started[root]
        local ordered = {}
        for _, p in ipairs(projects) do
          if p == remembered then
            table.insert(ordered, 1, p)
          else
            table.insert(ordered, p)
          end
        end

        local choice = ordered[1]
        if #ordered > 1 then
          local lines = { 'Start which project?' }
          for i, p in ipairs(ordered) do
            table.insert(lines, string.format('%d. %s%s', i, p:sub(#root + 2),
              p == remembered and '  [last]' or ''))
          end
          choice = ordered[vim.fn.inputlist(lines)]
        end
        if choice == nil then
          return
        end
        last_started[root] = choice

        local dir = vim.fn.fnamemodify(choice, ':h')
        local cmd
        if is_functions_project(choice) then
          cmd = { 'func', 'start' }
        else
          cmd = { 'dotnet', 'run', '--project', choice }
        end

        vim.cmd('botright 15split')
        vim.fn.jobstart(cmd, { term = true, cwd = dir })
        vim.cmd('startinsert')
      end

      vim.api.nvim_create_user_command('DotnetRun', run_project, { desc = 'Run dotnet or func project' })
      vim.keymap.set('n', '<leader>dr', run_project, { desc = 'Run project (dotnet/func)' })

      dap.configurations.cs = {
        {
          type = "coreclr",
          name = "Attach to Azure Function (.NET)",
          request = "attach",
          -- processId = get_dotnet_pid_fzf,
          processId = function()
            local root = find_solution_root()
            local pid = get_dotnet_pid(root)
            if pid then
              return pid
            end
            local manual = vim.fn.input("Enter PID of the dotnet process to attach to: ")
            if manual == "" then return nil end
            return tonumber(manual)
          end,
          justMyCode = true,
        }
      }

      dap.listeners.after.event_initialized.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated.dapui_config = function()
        dapui.close()
      end
      dap.listeners.before.event_exited.dapui_config = function()
        dapui.close()
      end
    end
  }
}
