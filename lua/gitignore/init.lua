local M = {}

-- GENERIC HELPER FUNCTIONS
local function map(tbl, f) local t = {} for i,v in ipairs(tbl) do t[i] = f(v) end return t end
local function isIn(tbl, val) for _, value in ipairs(tbl) do if val == value then return true end end return false end
local function removeDuplicates(tbl, ignored) ignored = ignored or {} local hash = {} local t = {} for _,v in ipairs(tbl) do if (not hash[v]) then t[#t+1] = v if not isIn(ignored, v) then hash[v] = true end end end return t end
local function filter(tbl, f) local t = {} local i = 1 for _, v in ipairs(tbl) do if f(v) then t[i] = v i = i + 1 end end return t end
local function endsWith(str, ending) return string.sub(str, -#ending) == ending end
local function collapseEmptyLines(tbl) local t = {} local lastValWasEmptyString = false for _, value in ipairs(tbl) do if (not lastValWasEmptyString) or value ~= '' then table.insert(t, value) end if value == '' then lastValWasEmptyString = true else lastValWasEmptyString = false end end return t end
local function getKeysInTable(tbl) local keys = {} for k, _ in pairs(tbl) do keys[#keys+1] = k end return keys end
local function removeBufIfHasTelescope(prompt_bufnr) if prompt_bufnr and pcall(require, "telescope") then require("telescope.actions").close(prompt_bufnr) end end

-- DEFINITIONS
local DEFAULT_TITLE = 'Creating .gitignore: Make your choice(s)'

-- PLUGIN DATA
local templates_data = require("gitignore.templates")
local order_data = require("gitignore.order")

-- THE REST OF THE PLUGIN
local templateKeys = getKeysInTable(templates_data)
M.templateNames = removeDuplicates(map(
    templateKeys,
    function (path) return path:sub(1, path:find('%.')-1) end
))

local function getTmplKeysForPrefix(prefix)
    prefix = prefix .. "."
    local matches = {}
    local stacks = filter(templateKeys, function (templateKey) return endsWith(templateKey, '.stack') end)
    local ignores = filter(templateKeys, function (templateKey) return endsWith(templateKey, '.gitignore') end)
    local patches = filter(templateKeys, function (templateKey) return endsWith(templateKey, '.patch') end)
    for _, templateKey in ipairs(stacks) do
        if string.sub(templateKey, 1, #prefix) == prefix then
            matches[#matches+1] = templateKey
        end
    end
    for _, templateKey in ipairs(ignores) do
        if string.sub(templateKey, 1, #prefix) == prefix then
            matches[#matches+1] = templateKey
        end
    end
    for _, templateKey in ipairs(patches) do
        if string.sub(templateKey, 1, #prefix) == prefix then
            matches[#matches+1] = templateKey
        end
    end
    return matches
end

local function createGitignore(selectionList, order)
    local s = removeDuplicates(selectionList)
    table.sort(s)
    table.sort(s, function (left, right)
        return (order[left] or 0) < (order[right] or 0)
    end)
    local ignoreLines = {}
    local infoString = "# Gitignore for the following technologies: "
    for i, v in ipairs(s) do
        infoString = infoString .. v
        if i < #s then
            infoString = infoString .. ', '
        end
    end
    table.insert(ignoreLines, infoString)
    table.insert(ignoreLines, '')
    for _, prefix in ipairs(s) do
        local p = getTmplKeysForPrefix(prefix)
        if #p == 0 then
            vim.schedule(function () print('Error while creating .gitignore, unknown selection: ' .. prefix) end)
            return nil
        end
        for _, templateKey in ipairs(p) do
            local fileLines = vim.split(templates_data[templateKey], '\n')
            for _, line in ipairs(fileLines) do
                table.insert(ignoreLines, line)
            end
            table.insert(ignoreLines, '')
        end
    end
    ignoreLines = removeDuplicates(ignoreLines, {''})
    ignoreLines = collapseEmptyLines(ignoreLines)
    local x = ignoreLines
    return x
end

--- Creates the gitignore to new buffer or new file if path is provided.
---@param chosen_path? string path to .gitignore
---@param selectionList table list of selected templateNames
---@param prompt_bufnr? number bufnr for closing telescope plugin if exists
function M.createGitignoreBuffer(chosen_path, selectionList, prompt_bufnr)
    if #selectionList < 1 then
        removeBufIfHasTelescope(prompt_bufnr)
        vim.schedule(function () print('Nothing selected, creation of .gitignore cancelled!') end)
        return
    end
    local ignoreLines = createGitignore(selectionList, order_data)
    if ignoreLines == nil then
        return
    end
    local gitignoreFile = chosen_path
    -- Check if chosen_path is empty, if so set gitignoreFile as ".gitignore".
    if not gitignoreFile or gitignoreFile == "" then
        gitignoreFile = ".gitignore"
    elseif not gitignoreFile:match(".gitignore$") then
        -- If chosen_path ends with "/", append ".gitignore" instead of "/.gitignore".
        if gitignoreFile:sub(-1) == "/" then
            gitignoreFile = gitignoreFile .. ".gitignore"
        else
            gitignoreFile = gitignoreFile .. "/.gitignore"
        end
    end
    local existingLines = {}
    if vim.g.gitignore_nvim_overwrite ~= true then
        if vim.fn.filereadable(gitignoreFile) == 1 then
            existingLines = vim.fn.readfile(gitignoreFile)
        end
    end
    local separator = {
        "#--------------------------------------------------#",
        "# The following was generated with gitignore.nvim: #",
        "#--------------------------------------------------#",
    }
    local allLines = vim.tbl_flatten({existingLines, separator, ignoreLines})
    local new_buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_buf_set_lines(new_buf, 0, -1, true, allLines)
    vim.api.nvim_buf_set_option(new_buf, 'filetype', 'gitignore')
    local ok, _ = pcall(function ()
        vim.api.nvim_buf_set_name(new_buf, gitignoreFile)
    end)
    if not ok then
        vim.schedule(function () print('Buffer with name \'.gitignore\' already exists, didn\'t name buffer!') end)
    end
    removeBufIfHasTelescope(prompt_bufnr)
    vim.api.nvim_win_set_buf(0, new_buf)
end

local function call_telescope_win(opts, sorter_opts)
    -- TELESCOPE STUFF
    local themes = require("telescope.themes")
    local actions = require("telescope.actions")
    local state = require("telescope.actions.state")
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values

    sorter_opts = sorter_opts or {}
    local defaults = {
        prompt_title = DEFAULT_TITLE,
        previewer = false,
        finder = finders.new_table({
            results = M.templateNames,
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
                M.createGitignoreBuffer(opts.args, multiSelection, prompt_bufnr)
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

--- Create a window to pick gitignores
---@param opts table options that passed in cmd
---@param sorter_opts? table opts for telescope sorters if exists
function M.generate(opts, sorter_opts)
	local has_telescope, _ = pcall(require, "telescope")
	if has_telescope then
		return call_telescope_win(opts, sorter_opts)
	end

	local winopts = {
		prompt = DEFAULT_TITLE,
	}
	vim.ui.select(M.templateNames, winopts, function(selected)
		M.createGitignoreBuffer(opts.args, { selected })
	end)
end

vim.api.nvim_create_user_command('Gitignore', M.generate, { nargs = '?', complete = 'file' })

return M
