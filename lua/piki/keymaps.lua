-- keymaps.lua
local M = {}

function M.setup(piki, config)
    local actions = {
        wiki = {
            picker = piki.picker,
            backlinks = piki.backlinks,
            graph = piki.show_graph,
            follow = piki.follow
        },
        daily = {
            open = piki.open_daily,
            prev = piki.daily_prev,
            next = piki.daily_next,
            close = piki.close_daily,
            calendar = piki.calendar,
        },
        markdown = {
            wordlink = piki.word_link,
            togglecheck = piki.toggle_check,
        },
    }

    local descriptions = {
        wiki = {
            picker = "Open piki menu",
            backlinks = "Show this note's backlinks",
            graph = "Show piki graph",
            follow = "Follow markdown link",
        },
        daily = {
            open = "Open daily note",
            prev = "Open previous daily note",
            next = "Open next daily note",
            close = "Close daily note",
            calendar = "Open calendar view",
        },
        markdown = {
            wordlink = "Convert hovered word to a link",
            togglecheck = "Toggle Markdown checkbox"
        },
    }

    local gates = {
        wiki = function() return config.path ~= nil end,
        daily = function() return config.daily.path ~= nil end,
        markdown = function() return config.markdown_help ~= false end,
    }

    for namespace, namespace_keymaps in pairs(config.keymaps) do
        if not gates[namespace] or gates[namespace]() then
            for action, key in pairs(namespace_keymaps) do
                local func = actions[namespace][action]
                local desc = descriptions[namespace][action]
                if key ~= false and func ~= nil then
                    vim.keymap.set("n", key, func, { desc = desc })
                end
            end
        end
    end

end

return M




vim.keymap.set("n", "<leader>ml", word_to_link, {
	buffer = true,
	desc = "Convert word to link / cycle link format",
	silent = true,
})

vim.keymap.set({ "n", "v" }, "<leader>mc", toggle_markdown_checkbox, {
	buffer = true,
	desc = "Toggle markdown checkbox",
	silent = true,
})

vim.keymap.set({ "n", "v" }, "<Space><Space>", toggle_markdown_checkbox, {
	buffer = true,
	desc = "Toggle markdown checkbox",
	silent = true,
})

vim.keymap.set("n", "gf", follow_markdown_link, {
	buffer = true,
	desc = "Follow markdown link",
	silent = true,
})

vim.keymap.set("n", "<CR>", follow_markdown_link, {
	buffer = true,
	desc = "Follow markdown link",
	silent = true,
})


