-- keymaps.lua
local M = {}

function M.setup(piki, config)
    local actions = {
        wiki = {
            picker = piki.picker,
            backlinks = piki.backlinks,
            graph = piki.show_graph,
        },
        daily = {
            open = piki.open_daily,
            prev = piki.daily_prev,
            next = piki.daily_next,
            close = piki.close_daily,
            calendar = piki.calendar,
        },
    }

    local descriptions = {
        wiki = {
            picker = "open piki menu",
            backlinks = "show this note's backlinks",
            graph = "show piki graph",
        },
        daily = {
            open = "open daily note",
            prev = "open previous daily note",
            next = "open next daily note",
            close = "close daily note",
            calendar = "open calendar view",
        },
    }

    local gates = {
        wiki = function() return config.path ~= nil end,
        daily = function() return config.daily.path ~= nil end,
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
