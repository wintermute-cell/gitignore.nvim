local has_telescope, _ = pcall(require, "telescope")
if not has_telescope then
    error(
        "This plugin requires telescope.nvim (https://github.com/nvim-telescope/telescope.nvim)"
    )
end

local M = {}

-- GENERIC HELPER FUNCTIONS
local function map(tbl, f) local t = {} for i,v in ipairs(tbl) do t[i] = f(v) end return t end
local function isIn(tbl, val) for _, value in ipairs(tbl) do if val == value then return true end end return false end
local function removeDuplicates(tbl, ignored) ignored = ignored or {} local hash = {} local t = {} for _,v in ipairs(tbl) do if (not hash[v]) then t[#t+1] = v if not isIn(ignored, v) then hash[v] = true end end end return t end
local function filter(tbl, f) local t = {} local i = 1 for _, v in ipairs(tbl) do if f(v) then t[i] = v i = i + 1 end end return t end
local function invertTable(tbl) local t = {} for k, v in pairs(tbl) do t[v] = k end return t end
local function endsWith(str, ending) return string.sub(str, -#ending) == ending end
local function readAll(filePath) local f = assert(io.open(filePath, "r")) local content = f:read("*all") f:close() return content end
local function collapseEmptyStrings(tbl) local t = {} local lastValWasEmpty = false for _, value in ipairs(tbl) do if not lastValWasEmpty then table.insert(t, value) end if value == '' then lastValWasEmpty = true else lastValWasEmpty = false end end return t end


-- TELESCOPE STUFF
local themes = require("telescope.themes")
local actions = require("telescope.actions")
local state = require("telescope.actions.state")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values

-- DEFINITIONS
local DEFAULT_TITLE = 'Creating .gitignore: Make your choice(s)'
local ORDER_FILEPATH = 'order'
local TEMPLATE_PATH = 'plugin/templates'

-- THE REST OF THE PLUGIN
local paths = vim.split(vim.fn.glob(TEMPLATE_PATH .. '/*'), '\n')
vim.schedule(function ()
    print(vim.inspect(vim.fn.stdpath('data')))
end)
local prefixes = removeDuplicates(map(
    map(
        paths,
        function (path) return path:sub(11) end),
    function (path) return path:sub(1, path:find('%.')-1) end
))

local function getPathsForPrefix(prefix)
    local matches = {}
    local stacks = filter(paths, function (path) return endsWith(path, '.stack') end)
    local ignores = filter(paths, function (path) return endsWith(path, '.gitignore') end)
    local patches = filter(paths, function (path) return endsWith(path, '.patch') end)
    for _, path in ipairs(stacks) do
        local filename = string.lower(string.sub(path, 11))
        if string.sub(filename, 1, #prefix) == prefix then
            matches[#matches+1] = path
        end
    end
    for _, path in ipairs(ignores) do
        local filename = string.lower(string.sub(path, 11))
        if string.sub(filename, 1, #prefix) == prefix then
            matches[#matches+1] = path
        end
    end
    for _, path in ipairs(patches) do
        local filename = string.lower(string.sub(path, 11))
        if string.sub(filename, 1, #prefix) == prefix then
            matches[#matches+1] = path
        end
    end
    return matches
end


local function createGitignore(selectionList, order)
    local s = map(selectionList, string.lower)
    s = removeDuplicates(s)
    table.sort(s)
    table.sort(s, function (left, right)
        return (order[left] or 0) < (order[right] or 0)
    end)
    local ignoreLines = {}
    for _, prefix in ipairs(s) do
        local p = getPathsForPrefix(prefix)
        for _, path in ipairs(p) do
            local fileLines = vim.split(readAll(path):gsub('\r\n', '\n'), '\n')
            for _, line in ipairs(fileLines) do
                table.insert(ignoreLines, line)
            end
            table.insert(ignoreLines, '')
        end
    end
    ignoreLines = removeDuplicates(ignoreLines, {''})
    ignoreLines = collapseEmptyStrings(ignoreLines)
    return ignoreLines
end

function M.generate(on_choice, sorter_opts)
    sorter_opts = sorter_opts or {}
    local order_data = vim.split(readAll(ORDER_FILEPATH), '\n')
    order_data = invertTable(filter(order_data, function (line) return not line:sub(1, 1) == '#' end))
    local defaults = {
        prompt_title = DEFAULT_TITLE,
        previewer = false,
        finder = finders.new_table({
            results = prefixes,
        }),
        sorter = conf.generic_sorter(sorter_opts),
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
                local multiSelection = picker:get_multi_selection()
                multiSelection = map(multiSelection, function (item) return item[1] end)

                -- in case of no multi selection, accept a single selection with <CR>
                if #multiSelection <= 0 then
                    multiSelection = {state.get_selected_entry()[1]}
                end
                local ignoreLines = createGitignore(multiSelection, order_data)
                if #ignoreLines > 0 then
                    local new_buf = vim.api.nvim_create_buf(true, false)
                    vim.api.nvim_buf_set_lines(new_buf, 0, -1, true, ignoreLines)
                    vim.api.nvim_buf_set_option(new_buf, 'filetype', 'gitignore')
                    vim.api.nvim_buf_set_name(new_buf, '.gitignore')
                    actions.close(prompt_bufnr)
                    vim.api.nvim_win_set_buf(0, new_buf)
                else
                    actions.close(prompt_bufnr)
                    vim.schedule(function () print('Nothing selected, creation of .gitignore cancelled!') end)
                end
            end)

            actions.toggle_selection:enhance({
                post = function ()
                    -- clearing the input after user makes a multi selection
                    vim.cmd [[norm! 0v$d]]
                    local picker = state.get_current_picker(prompt_bufnr)
                    local multiSelection = picker:get_multi_selection()
                    multiSelection = map(multiSelection, function (item) return item[1] end)
                    if #multiSelection == 0 then
                        picker.prompt_border:change_title(DEFAULT_TITLE)
                        return
                    end
                    local selectionString = ''
                    for i, value in ipairs(multiSelection) do
                        selectionString = selectionString .. value
                        if i ~= #multiSelection then
                            selectionString = selectionString .. ', '
                        end
                    end
                    picker.prompt_border:change_title(selectionString)
                end,
            })

            actions.close:enhance({
                post = function ()
                    --vim.schedule(function () print('Creation of .gitignore cancelled!') end)
                    --on_choice(nil)
                end,
            })

            return true
        end,
    }
    return pickers.new(themes.get_dropdown(), defaults):find()
end

vim.api.nvim_create_user_command('Gitignore', M.generate, {})

return M
