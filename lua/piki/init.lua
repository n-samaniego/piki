-- piki/init.lua
-- Main entry point - re-exports all modules for backward compatibility
-- This thin module provides the public API surface

local M = {}

M.version = "0.0.0"

-- Load all submodules
local config = require("piki.config")
local utils = require("piki.utils")
local daily = require("piki.daily")
local calendar = require("piki.calendar")
local capture = require("piki.capture")
local files = require("piki.files")
local menu = require("piki.menu")
local graph = require("piki.graph")
local tags = require("piki.tags")
local keymaps = require("piki.keymaps")
local markdown = require("piki.markdown")


--------------------------------------------------------------------------------
-- Configuration (re-export from config module)
--------------------------------------------------------------------------------

M.config = config.config
M.wikidir = config.wikidir
M.dailydir = config.dailydir

--- @param opts piki.Config.Partial?
function M.setup(opts)
	config.setup(opts)
	-- Update our re-exported references
	M.config = config.config
	M.wikidir = config.wikidir
	M.dailydir = config.dailydir
	-- Setup highlights
	utils.setup_graph_highlights()

    -- Setup keymaps
    keymaps.setup(M, M.config, M.dailydir)

    -- Initialize menu
    menu.setup(M, M.dailydir)

	-- Invalidate file and tag caches when any .md file in the wiki is saved
	local augroup = vim.api.nvim_create_augroup("PikiCacheInvalidation", { clear = true })
	vim.api.nvim_create_autocmd("BufWritePost", {
		group = augroup,
		pattern = "*.md",
		callback = function(ev)
			local bufpath = vim.api.nvim_buf_get_name(ev.buf)
			if config.wikidir and vim.startswith(bufpath, config.wikidir) then
				files.invalidate_cache()
				tags.invalidate_cache()
				graph.invalidate_cache()
			end
		end,
	})
end

--------------------------------------------------------------------------------
-- Daily Notes (re-export from daily module)
--------------------------------------------------------------------------------

M.open_daily = daily.open
M.close_daily = daily.close
M.list_files = daily.list_files
M.cleanup = daily.cleanup
M.daily_prev = daily.prev
M.daily_next = daily.next

--------------------------------------------------------------------------------
-- Calendar (re-export from calendar module)
--------------------------------------------------------------------------------

M.calendar = calendar.show

--------------------------------------------------------------------------------
-- Capture (re-export from capture module)
--------------------------------------------------------------------------------

M.capture = capture.capture
M.capture_with_location = capture.capture_with_location
M.capture_visual = capture.capture_visual
M.inbox = capture.inbox

--------------------------------------------------------------------------------
-- Files (re-export from files module)
--------------------------------------------------------------------------------

M.wiki = files.wiki
M.dailies = files.dailies
M.recent = files.recent
M.search = files.search
M.create_file = files.create
M.rename_file = files.rename
M.get_wiki_folders = files.get_wiki_folders
M.get_wiki_files = files.get_wiki_files
M.get_file_headings = files.get_file_headings

--------------------------------------------------------------------------------
-- Graph (re-export from graph module)
--------------------------------------------------------------------------------

M.backlinks = graph.backlinks
M.show_graph = graph.show
M.validate_links = graph.validate_links

--------------------------------------------------------------------------------
-- Tags (re-export from tags module)
--------------------------------------------------------------------------------

M.list_tags = tags.list_tags
M.filter_by_tag = tags.filter_by_tag
M.add_tag = tags.add_tag
M.get_file_tags = tags.get_file_tags
M.get_all_tags = tags.get_all_tags

--------------------------------------------------------------------------------
-- Completion (link autocompletion)
--------------------------------------------------------------------------------

function M.link_complete(findstart, base)
	if findstart == 1 then
		local line = vim.fn.getline(".")
		local col = vim.fn.col(".") - 1
		local link_pos = line:sub(1, col):find("%]%([^)]*$")
		if link_pos then
			return link_pos + 1
		end
		return -3
	else
		local items = {}
		local wiki_files = files.get_wiki_files()
		local file_part, heading_part = base:match("^(.-)#(.*)$")

		if file_part and config.config.completion.include_headings then
			local target_file = nil
			for _, file in ipairs(wiki_files) do
				if file.path == file_part or file.path == file_part .. ".md" then
					target_file = file.full_path
					break
				end
			end

			if target_file then
				local headings = files.get_file_headings(target_file)
				for _, heading in ipairs(headings) do
					local word = file_part .. "#" .. heading.slug
					if
						word:lower():find(base:lower(), 1, true)
						or heading.text:lower():find((heading_part or ""):lower(), 1, true)
					then
						table.insert(items, {
							word = word,
							menu = heading.text,
							kind = "H" .. heading.level,
						})
					end
				end
			end
		else
			for _, file in ipairs(wiki_files) do
				if file.path:lower():find(base:lower(), 1, true) or file.title:lower():find(base:lower(), 1, true) then
					table.insert(items, {
						word = file.path,
						menu = file.title,
						kind = "F",
					})
					if #items >= config.config.completion.max_results then
						break
					end
				end
			end
		end

		return items
	end
end

function M.setup_completion()
	if not config.config.completion.enabled then
		return
	end
	vim.bo[0].omnifunc = "v:lua.require'piki'.link_complete"

	local has_cmp, cmp = pcall(require, "cmp")
	if has_cmp then
		local has_source, cmp_piki = pcall(require, "cmp_piki")
		if has_source then
			cmp.register_source("piki", cmp_piki.new())
		end
	end
end

--------------------------------------------------------------------------------
-- Menus
--------------------------------------------------------------------------------

M.show_menu = menu.show
-- Main picker entry point
function M.picker()
    M.show_menu(menu.get_main_choices(), "piki")
end



--------------------------------------------------------------------------------
-- Markdown (re-export from config module)
--------------------------------------------------------------------------------
M.follow = markdown.follow_markdown_link
M.word_link = markdown.word_to_link
M.toggle_check = markdown.toggle_markdown_checkbox

--------------------------------------------------------------------------------
-- Initialize
--------------------------------------------------------------------------------

-- Setup highlights on load
utils.setup_graph_highlights()

return M
