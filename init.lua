local has_telescope, _ = pcall(require, "telescope")
if not has_telescope then
  error(
    "This plugin requires telescope.nvim (https://github.com/nvim-telescope/telescope.nvim)"
  )
end

local M = {}

local paths = vim.split(vim.fn.glob('templates/*'), '\n')

local function filter_for_ending(input_list, ending)
  local output = {}
  local idx = 0
  for _, value in ipairs(input_list) do
    -- if the value ends with '.stack', add it to stacks
    if string.sub(value, -#ending) == ending then
      idx = idx + 1
      output[idx] = value
    end
  end
  return output
end

local stacks = filter_for_ending(paths, '.stack')
local ignores = filter_for_ending(paths, '.gitignore')
local patches = filter_for_ending(paths, '.patch')


local themes = require("telescope.themes")
local actions = require("telescope.actions")
local state = require("telescope.actions.state")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values

local function readAll(file)
    local f = assert(io.open(file, "r"))
    local content = f:read("*all")
    f:close()
    return content
end

local only_files = {}
-- for evey entry in paths, remote the 'templates/' prefix
for i, v in ipairs(paths) do
  only_files[i] = string.sub(v, 11)
end

local prefix_map = {}

for _, v in ipairs(only_files) do
  local dot_idx = string.find(v, '%.')
  if dot_idx ~= nil then
    prefix_map[string.sub(v, 1, dot_idx - 1)] = true
  else
    prefix_map[v] = true
  end
end

local idx = 0 local prefix_list = {}
for key, _ in pairs(prefix_map) do
  idx = idx+1
  prefix_list[idx] = key
end

local function get_matching_paths(prefix)
  local matches = {}
  for _, path in ipairs(stacks) do
    local filename = string.sub(path, 11)
    if string.sub(filename, 1, #prefix) == prefix then
      local dot_idx = string.find(filename, '%.')
      local stack_identifier = string.sub(filename, dot_idx+1, #filename - 6)
      matches[#matches+1] = 'templates/' .. stack_identifier .. '.gitignore'
    end
  end
  for _, path in ipairs(ignores) do
    local filename = string.sub(path, 11)
    if string.sub(filename, 1, #prefix) == prefix then
      matches[#matches+1] = path
    end
  end
  for _, path in ipairs(patches) do
    local filename = string.sub(path, 11)
    if string.sub(filename, 1, #prefix) == prefix then
      matches[#matches+1] = path
    end
  end

  -- remove the duplicates from matches
  local unique_matches = {}
  for _, v in ipairs(matches) do
    unique_matches[v] = true
  end
  matches = {}
  idx = 0
  for key, _ in pairs(unique_matches) do
    idx = idx + 1
    matches[idx] = key
  end
  return matches
end

function M.select(on_choice, opts)
  opts = opts or {}
  local defaults = {
    prompt_title = 'Creating .gitignore: Make your choice(s)',
    previewer = false,
    finder = finders.new_table({
      results = prefix_list,
    }),
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local selection = state.get_selected_entry()
        -- Replace on_choice with a no-op so closing doesn't trigger it
        on_choice = function(_, _) end
        if not selection then
          -- User did not select anything.
          vim.schedule(function () print('none') end)
          return
        end
        local picker = state.get_current_picker(prompt_bufnr)
        local sel = picker:get_multi_selection()
        local full_string = ''
        for _, v in pairs(sel) do
          local selection_value = v[1]
          local stack_files = get_matching_paths(selection_value)
          -- read file from path to string
          for _, file_path in ipairs(stack_files) do
            local contents = readAll(file_path)
            full_string = full_string .. contents
          end
        end
        local new_buf = vim.api.nvim_create_buf(true, false)
        vim.api.nvim_buf_set_lines(new_buf, 0, -1, true, vim.split(full_string, '\n'))
        vim.api.nvim_buf_set_option(new_buf, 'filetype', 'gitignore')
        vim.api.nvim_buf_set_name(new_buf, '.gitignore')
        actions.close(prompt_bufnr)
        vim.api.nvim_win_set_buf(0, new_buf)
      end)

      actions.close:enhance({
        post = function()
          vim.schedule(function () print('Creation of .gitignore cancelled!') end)
          on_choice(nil)
        end,
      })

      return true
    end,
  }
  return pickers.new(themes.get_dropdown(), defaults):find()
end

M.select(print)

return M
