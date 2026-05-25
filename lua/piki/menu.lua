-- piki/menu.lua
-- Generic popup menu system

local M = {}


-- Generic menu display function
-- Choices format: { "Display [H]otkey", "h", function } or { "---" } for separator
function M.show(choices, title, back_func)
    title = title or "piki"
    local options = { title }
    local hotkey_map = {} -- maps hotkey letter to choice index
    local number_map = {} -- maps display number to choice index
    local display_num = 0

    for i, choice in ipairs(choices) do
        if choice[1] == "---" then
            -- Separator - no number, no hotkey
            table.insert(options, "   ───────────────")
        else
            display_num = display_num + 1
            number_map[display_num] = i
            table.insert(options, string.format("%d: %s", display_num, choice[1]))
            -- Register hotkey if present
            if choice[2] and type(choice[2]) == "string" then
                hotkey_map[choice[2]:lower()] = i
            end
        end
    end

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, options)

    local max_width = 0
    for _, line in ipairs(options) do
        if #line > max_width then
            max_width = #line
        end
    end

    local height = #options
    local win_width = math.min(max_width + 4, vim.o.columns)
    local win_height = math.min(height, vim.o.lines)
    local row = math.ceil((vim.o.lines - win_height) / 2)
    local col = math.ceil((vim.o.columns - win_width) / 2)

    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = win_width,
        height = win_height,
        col = col,
        row = row,
        style = "minimal",
        border = "rounded",
    })

    local function execute_choice(index)
        -- Choice format: { label, hotkey, func } - func is at index 3
        if index and choices[index] and choices[index][3] then
            vim.api.nvim_win_close(win, true)
            choices[index][3]()
        end
    end

    local function handle_enter()
        local line = vim.api.nvim_get_current_line()
        local num = tonumber(line:match("^(%d):"))
        if num and number_map[num] then
            execute_choice(number_map[num])
        end
    end

    local function handle_back()
        vim.api.nvim_win_close(win, true)
        if back_func then
            back_func()
        end
    end

    vim.api.nvim_buf_set_keymap(buf, "n", "<CR>", "", {
        noremap = true,
        silent = true,
        callback = handle_enter,
    })

    -- q and Esc behave differently based on whether we have a back function
    if back_func then
        -- In submenu: Esc and 0 go back, q closes completely
        vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", "", {
            noremap = true,
            silent = true,
            callback = handle_back,
        })
        vim.api.nvim_buf_set_keymap(buf, "n", "0", "", {
            noremap = true,
            silent = true,
            callback = handle_back,
        })
    else
        -- In main menu: q and Esc close
        vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", "", {
            noremap = true,
            silent = true,
            callback = function()
                vim.api.nvim_win_close(win, true)
            end,
        })
    end

    -- Always allow q to close
    vim.api.nvim_buf_set_keymap(buf, "n", "q", "", {
        noremap = true,
        silent = true,
        callback = function()
            vim.api.nvim_win_close(win, true)
        end,
    })

    -- Number hotkeys (1-9)
    for num = 1, math.min(display_num, 9) do
        vim.api.nvim_buf_set_keymap(buf, "n", tostring(num), "", {
            noremap = true,
            silent = true,
            callback = function()
                if number_map[num] then
                    execute_choice(number_map[num])
                end
            end,
        })
    end

    -- Letter hotkeys
    for hotkey, index in pairs(hotkey_map) do
        -- Bind both lowercase and uppercase
        vim.api.nvim_buf_set_keymap(buf, "n", hotkey, "", {
            noremap = true,
            silent = true,
            callback = function()
                execute_choice(index)
            end,
        })
        vim.api.nvim_buf_set_keymap(buf, "n", hotkey:upper(), "", {
            noremap = true,
            silent = true,
            callback = function()
                execute_choice(index)
            end,
        })
    end
end

function M.setup(piki, dailydir)
    local analyze_menu
    local tags_menu
    local tools_menu

    -- Analysis submenu
    analyze_menu = function()
        M.show_menu({
            { "[B]acklinks", "b", piki.backlinks },
            { "[G]raph View", "g", piki.show_graph },
            { "[V]alidate Links", "v", piki.validate_links },
            { "[T]ags", "t", tags_menu },
        }, "Analyze", piki.picker)
    end

    -- Tags submenu
    tags_menu = function()
        M.show_menu({
            { "[L]ist All Tags", "l", piki.list_tags },
            { "[F]ilter by Tag", "f", piki.filter_by_tag },
            { "[A]dd Tag to File", "a", piki.add_tag },
        }, "Tags", analyze_menu)
    end

    -- Tools submenu
    tools_menu = function()
        M.show_menu({
            { "[R]ename / Refactor", "r", piki.rename_file },
            { "[C]leanup Empty Dailies", "c", piki.cleanup },
        }, "Tools", piki.picker)
    end

    -- Main menu choices (dynamically generated)
    function M.get_main_choices()
        local choices = {}
        local daily = function() return dailydir ~= nil end

        if daily and vim.fn.expand("%:p"):find(dailydir, 1, true) then
            table.insert(choices, { "Close [D]aily", "d", piki.close_daily })
            table.insert(choices, { "[Y]esterday", "y", function() piki.open_daily(-1) end, })
            table.insert(choices, { "[T]omorrow", "t", function() piki.open_daily(1) end, })
        else
            table.insert(choices, { "[T]oday", "t",  function() piki.open_daily() end, })
        end

        table.insert(choices, { "[R]ecent", "r", piki.recent })
        table.insert(choices, { "[C]alendar", "c", piki.calendar })
        table.insert(choices, { "Cr[e]ate", "e", piki.create_file })
        table.insert(choices, { "---" })
        table.insert(choices, { "[A]nalyze >", "a", analyze_menu })
        table.insert(choices, { "Too[l]s >", "l", tools_menu })

        return choices
    end

end

return M
