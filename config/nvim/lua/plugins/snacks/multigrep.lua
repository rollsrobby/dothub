local M = {}

local function parse_input(input)
  input = input or ""
  local query, rest = input:match("^(.-)%s%s(.+)$")
  if not rest then
    return vim.trim(input), nil
  end
  query = vim.trim(query)
  rest = vim.trim(rest)
  if rest == "" then
    return query, nil
  end
  local globs = {}
  for glob in rest:gmatch("%S+") do
    globs[#globs + 1] = glob
  end
  return query, #globs > 0 and globs or nil
end

local function wrap_config(user_config)
  return function(conf)
    if user_config then
      conf = user_config(conf) or conf
    end
    local grep = require("snacks.picker.source.grep").grep
    conf.finder = function(opts, ctx)
      local original_search = ctx.filter.search or ""
      local original_pattern = ctx.filter.pattern

      local query, globs = parse_input(original_search)
      ctx.filter.search = query
      if original_pattern and original_pattern ~= "" then
        ctx.filter.pattern = query
      end

      local finder_opts = vim.deepcopy(opts)
      finder_opts.finder = nil
      finder_opts.config = nil
      finder_opts.glob = globs

      local result = grep(finder_opts, ctx)

      ctx.filter.search = original_search
      ctx.filter.pattern = original_pattern
      return result
    end
    return conf
  end
end

---@param opts? snacks.picker.grep.Config
function M.pick(opts)
  opts = opts or {}
  opts = vim.tbl_deep_extend("force", {
    prompt = "Multi Grep: ",
    live = true,
  }, opts)
  opts.config = wrap_config(opts.config)
  Snacks.picker.grep(opts)
end

return M
