-- keymaps.lua
local M = {}

function M.setup(piki, config, dailydir)
    local actions = {
        global = {
            picker = piki.picker,
            backlinks = piki.backlinks,
            graph = piki.show_graph,
            calendar = piki.calendar,
            open = piki.open_daily,
        },
        markdown = {
            wordlink = piki.word_link,
            togglecheck = piki.toggle_check,
            follow = piki.follow
        },
        daily = {
            prev = piki.daily_prev,
            next = piki.daily_next,
            close = piki.close_daily,
        }
    }

    local descriptions = {
        global = {
            picker = "Open piki menu",
            backlinks = "Show this note's backlinks",
            graph = "Show piki graph",
            calendar = "Open calendar view",
            open = "Open daily note",
        },
        markdown = {
            wordlink = "Convert word to link / cycle link format",
            togglecheck = "Toggle markdown checkbox",
            follow = "Follow piki link",
        },
        daily = {
            prev = "Open previous daily note",
            next = "Open next daily note",
            close = "Close daily note",
        },
    }

    local gates = {
        global = function() return config.path ~= nil end,
        markdown = function() return config.markdown_help ~= false end,
        daily = function() return dailydir ~= nil end,
    }

    if gates.global() then
        -- loop
        for action, key in pairs(config.keymaps.global) do
            local func = actions.global[action]
            local desc = descriptions.global[action]
            if key ~= false and func ~= nil then
                vim.keymap.set("n", key, func, { desc = desc })
            end
        end
    end

    local group = vim.api.nvim_create_augroup("PikiMarkdown", { clear = true })
    vim.api.nvim_create_autocmd("FileType", {
        pattern = "markdown",
        group = group,
        callback = function()
            -- guard so setup doesn't run twice
            if vim.b.piki_markdown_init then return end
            vim.b.piki_markdown_init = true

            -- Setup link autocompletion
            if config.completion.enabled then
            	piki.setup_completion()
            end

            -- Setup tag highlighting
            if config.tags and config.tags.enabled then
            	-- Highlight inline #tags (but not in code blocks or URLs)
            	vim.fn.matchadd("PikiTag", "\\v(^|\\s)#[a-zA-Z0-9_-]+")
            end

            -- Setup Markdown-specific keymaps
            local opts = { buffer = true, silent = true }
            if gates.markdown() then
                for action, key in pairs(config.keymaps.markdown) do
                    local func = actions.markdown[action]
                    local desc = descriptions.markdown[action]
                    if key ~= false and func ~= nil then
                        vim.keymap.set("n", key, func, vim.tbl_extend("force", opts, { desc = desc }))
                    end
                end

            end

            -- set daily note specific keymaps
            if gates.daily() and vim.fn.expand("%:p"):find(dailydir, 1, true) then
                -- loop over actions.daily
                for action, key in pairs(config.keymaps.daily) do
                    local func = actions.daily[action]
                    local desc = descriptions.daily[action]
                    if key ~= false and func ~= nil then
                        vim.keymap.set("n", key, func, vim.tbl_extend("force", opts, { desc = desc }))
                    end
                end
            end
        end,
    })
end


return M
