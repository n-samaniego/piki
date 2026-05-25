-- piki/config.lua
-- Shared configuration and state management

--- @class (exact) piki.CompletionConfig
--- @field enabled boolean Enable link/tag completion
--- @field include_headings boolean Include headings in completion results
--- @field max_results integer Maximum number of completion results
--- @field cache_ttl integer Seconds before file/tag caches expire (fallback; autocmd handles normal edits)

--- @class (exact) piki.WikilinksConfig
--- @field enabled boolean Support [[wikilink]] syntax
--- @field spaces_to string? Convert spaces in link names: "-", "_", or nil to keep spaces
--- @field confirm_create boolean Confirm before creating new files from links

--- @class (exact) piki.TagsConfig
--- @field enabled boolean Support #tags and frontmatter tags
--- @field inline_pattern string Lua pattern for inline tags
--- @field use_frontmatter boolean Parse YAML frontmatter for tags

--- @class (exact) piki.DailyConfig
--- @field path string? Path to daily notes directory, nil disables daily notes
--- @field template_path string? Path to user's daily note template

--- @class (exact) piki.WikiKeymapsConfig
--- @field picker string|false
--- @field backlinks string|false
--- @field graph string|false
--- @field follow string|false

--- @class (exact) piki.DailyKeymapsConfig
--- @field open string|false
--- @field prev string|false
--- @field next string|false
--- @field close string|false
--- @field calendar string|false

--- @class (exact) piki.MarkdownKeymapsConfig
--- @field wordlink string|false
--- @field togglecheck string|false

--- @class (exact) piki.KeymapsConfig
--- @field wiki piki.WikiKeymapsConfig
--- @field daily piki.DailyKeymapsConfig
--- @field markdown piki.MarkdownKeymapsConfig

--- @class (exact) piki.Config
--- @field path string? Path to wiki root directory, set by user
--- @field picker string? Picker backend: "telescope", "mini", "fzf", "snacks", or nil to auto-detect
--- @field completion piki.CompletionConfig
--- @field markdown_help boolean
--- @field wikilinks piki.WikilinksConfig
--- @field tags piki.TagsConfig
--- @field default_link_style "markdown"|"wikilink"
--- @field daily piki.DailyConfig
--- @field keymaps piki.KeymapsConfig

local M = {}

-- Shared regex patterns used across modules (not user-configurable)
M.patterns = {
	TAG_INLINE = "#([%w_-]+)",
	TAG_START = "^#([%w_-]+)",
	WIKILINK = "%[%[([^%]]+)%]%]",
	URL_HTTP = "^https?://",
	DATE_FILENAME = "^(%d%d%d%d%-%d%d%-%d%d)%.md$",
	HEADING_H1 = "^#%s+(.+)$",
}

--- @type piki.Config
M.config = {
	path = nil,
	picker = nil,
	completion = {
		enabled = true,
		include_headings = true,
		max_results = 50,
		cache_ttl = 300,
	},
    markdown_help = false,
	wikilinks = {
		enabled = true,
		spaces_to = "-",
		confirm_create = true,
	},
	tags = {
		enabled = true,
		inline_pattern = "#([%w_-]+)",
		use_frontmatter = true,
	},
	default_link_style = "wikilink",
    daily = {
        path = nil,
        template_path = nil,
    },
    keymaps = {
        wiki = {
            picker = "<leader>w",
            backlinks = "<leader>wb",
            graph = "<leader>wg",
            follow = "gf"
        },
        daily = {
            open = "<leader>dn",
            prev = "<leader>dh",
            next = "<leader>dl",
            close = "<leader>dq",
            calendar = "<leader>dc",
        },
        markdown = {
            wordlink = "<leader>wl",
            togglecheck = "<CR>"
        },
    }
}

--- Resolved wiki root path (set by update_paths)
--- @type string?
M.wikidir = nil

--- Resolved daily notes path (set by update_paths)
--- @type string?
M.dailydir = nil

function M.update_paths()
    if not M.config.path then
        M.wikidir = nil
        M.dailydir = nil
        vim.notify("piki: no wiki path configured", vim.log.levels.ERROR)
        return
    end

    local symlink_path = vim.fn.expand(M.config.path)
    local resolved = vim.uv.fs_realpath(symlink_path)

    if resolved then
        M.wikidir = resolved
    elseif vim.uv.fs_stat(symlink_path) then
        M.wikidir = symlink_path
    else
        M.wikidir = nil
        M.dailydir = nil
        vim.notify("piki: wiki directory does not exist: " .. symlink_path, vim.log.levels.ERROR)
        return
    end

    if M.config.daily and M.config.daily.path then
        local daily_expanded = vim.fn.expand(M.config.daily.path)
        if vim.uv.fs_stat(daily_expanded) then
            M.dailydir = daily_expanded
        else
            M.dailydir = nil
            vim.notify("piki: daily directory does not exist: " .. daily_expanded, vim.log.levels.WARN)
        end
    else
        M.dailydir = nil
    end
end

--- Returns true when wikidir is set and points to an existing directory.
--- @return boolean
function M.is_valid()
	if not M.wikidir then
		return false
	end
	local stat = vim.uv.fs_stat(M.wikidir)
	return stat ~= nil and stat.type == "directory"
end

--- @param opts piki.Config?
function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})
	M.update_paths()
end

-- Initialize with defaults
-- M.update_paths() -- patched: defer until setup()

return M
