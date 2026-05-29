-- piki/daily.lua
-- Daily notes functionality: open, close, cleanup, templates

local config = require("piki.config")
local utils = require("piki.utils")
local patterns = config.patterns

local M = {}

-- Built-in default template for daily notes
M.DEFAULT_TEMPLATE = [=[
# {{ date }}

## To-Do

## Log
]=]

--- Get daily template path with fallback logic
--- Priority: 1. Wiki template, 2. Config template, 3. Built-in default
--- @return string|nil path Path to template file or nil for built-in
--- @return string source Template source: "config", or "builtin"
function M.get_template_path()
    local file
    if config.config.daily.template_path then
        local expanded = vim.fn.expand(config.config.daily.template_path)
        vim.notify("piki debug: trying template path: " .. expanded, vim.log.levels.DEBUG)
        file = io.open(expanded, "r")
        if file then
            file:close()
            vim.notify("piki debug: template found, using config", vim.log.levels.DEBUG)
            return config.config.daily.template_path, "config"
        else
            vim.notify("piki debug: template NOT found at: " .. expanded, vim.log.levels.WARN)
        end
    else
        vim.notify("piki debug: no template_path in config", vim.log.levels.WARN)
    end
    return nil, "builtin"
end

--- Get daily template content, falling back to built-in default
--- @return string Template content with {{ date }} placeholder
function M.get_template_content()
	local template_path, source = M.get_template_path()

	if source == "builtin" then
		return M.DEFAULT_TEMPLATE
	end

	local content = utils.read_file(vim.fn.expand(template_path --[[@as string]]))
	if not content then
		vim.notify("Failed to read template: " .. template_path, vim.log.levels.ERROR)
		return M.DEFAULT_TEMPLATE
	end
	return content
end

--- List all files in the daily directory
--- @return string[] Sorted daily filenames (e.g. "2024-01-15.md")
function M.list_files()
	local files = {}
	local handle = vim.uv.fs_scandir(config.dailydir)
	if handle then
		while true do
			local name, type = vim.uv.fs_scandir_next(handle)
			if not name then
				break
			end
			if type == "file" then
				table.insert(files, name)
			end
		end
	end
	return files
end

-- Get the date from current buffer's filename (assumes YYYY-MM-DD.md format)
local function get_current_daily_date()
	local filename = vim.fn.expand("%:t")
	local year, month, day = filename:match("(%d%d%d%d)-(%d%d)-(%d%d)%.md$")
	if year and month and day then
		return string.format("%04d-%02d-%02d", tonumber(year), tonumber(month), tonumber(day))
	end
	return nil
end

--- Get adjacent daily note date (prev or next existing one)
--- @param direction integer -1 for previous, 1 for next
--- @return string|nil Date string (YYYY-MM-DD) or nil if none found
function M.get_adjacent_daily(direction)
	local current_date = get_current_daily_date()
	if not current_date then
		vim.notify("Not in a daily note", vim.log.levels.WARN)
		return nil
	end

	-- Get all daily files and sort them
	local files = M.list_files()
	local dates = {}
	for _, f in ipairs(files) do
		local date = f:match(patterns.DATE_FILENAME)
		if date then
			table.insert(dates, date)
		end
	end
	table.sort(dates)

	-- Find current date's position
	local current_idx = nil
	for i, d in ipairs(dates) do
		if d == current_date then
			current_idx = i
			break
		end
	end

	if not current_idx then
		return nil
	end

	-- Get adjacent
	local target_idx = current_idx + direction
	if target_idx < 1 or target_idx > #dates then
		return nil
	end

	return dates[target_idx]
end

--- Navigate to the previous daily note
function M.prev()
	if not config.is_valid() then
		vim.notify("piki: Wiki directory not configured or not found", vim.log.levels.ERROR)
		return
	end

	local target_date = M.get_adjacent_daily(-1)
	if target_date then
        local filepath = config.dailydir .. "/" .. target_date .. ".md"
        vim.cmd("edit " .. vim.fn.fnameescape(filepath))
		M.setup_daily_buffer()
	else
		vim.notify("No previous daily note", vim.log.levels.INFO)
	end
end

--- Navigate to the next daily note
function M.next()
	if not config.is_valid() then
		vim.notify("piki: Wiki directory not configured or not found", vim.log.levels.ERROR)
		return
	end

	local target_date = M.get_adjacent_daily(1)
	if target_date then
		local filepath = config.dailydir .. "/" .. target_date .. ".md"
		vim.cmd("edit " .. vim.fn.fnameescape(filepath))
		M.setup_daily_buffer()
	else
		vim.notify("No next daily note", vim.log.levels.INFO)
	end
end

--- Find the most recent existing daily note before a given date
--- @param reference_date string Date in YYYY-MM-DD format
--- @return string|nil Date string (YYYY-MM-DD) or nil if none found
function M.get_most_recent_previous_daily(reference_date)
	local files = M.list_files()
	local dates = {}
	for _, f in ipairs(files) do
		local date = f:match(patterns.DATE_FILENAME)
		if date then
			table.insert(dates, date)
		end
	end
	table.sort(dates)

	-- Find the most recent date before reference_date
	local target_date = nil
	for _, date in ipairs(dates) do
		if date < reference_date then
			target_date = date -- Keep updating to get the most recent one before reference_date
		else
			break -- Since sorted, we won't find any more before reference_date
		end
	end

	return target_date
end

--- Extract incomplete todos from a daily note file
--- @param filepath string Absolute path to the daily note
--- @return string[] Lines containing unchecked or blocked todos
function M.extract_incomplete_todos(filepath)
	local todos = {}
	local lines = utils.read_lines(filepath)
	if not lines then
		return todos
	end

	for _, line in ipairs(lines) do
		-- Match lines with [ ] (unchecked) or [-] (blocked/in progress)
		if line:match("^%s*%-(%s+)%[%s%]") or line:match("^%s*%-(%s+)%[%-]") then
			table.insert(todos, line)
		end
	end

	return todos
end

--- Mark forwarded todos in a file (change [ ] or [-] to [>])
--- @param filepath string Absolute path to the daily note
--- @param todo_lines_to_mark string[] Todo lines to mark as forwarded
--- @return boolean Whether the file was successfully updated
function M.mark_todos_forwarded(filepath, todo_lines_to_mark)
	local lines = utils.read_lines(filepath)
	if not lines then
		return false
	end

	-- Create a set of todos to mark (strip leading/trailing whitespace for comparison)
	local todos_to_mark = {}
	for _, todo in ipairs(todo_lines_to_mark) do
		-- Normalize: strip leading/trailing whitespace, keep only the content
		local normalized = todo:gsub("^%s+", ""):gsub("%s+$", "")
		todos_to_mark[normalized] = true
	end

	-- Update lines
	for i, line in ipairs(lines) do
		local normalized = line:gsub("^%s+", ""):gsub("%s+$", "")
		if todos_to_mark[normalized] then
			-- Replace the checkbox with [>], preserving original spacing
			lines[i] = line:gsub("%[%s%]", "[>]"):gsub("%[%-]", "[>]")
		end
	end

	-- Write back
	if not utils.write_file(filepath, table.concat(lines, "\n") .. "\n") then
		return false
	end

	return true
end

--- Setup buffer-local keymaps for daily notes
function M.setup_daily_buffer()
	vim.b.piki = true
	vim.cmd("lcd " .. vim.fn.fnameescape(config.wikidir))
end

--- Open or create a daily file with a specified offset in days
--- @param days_offset integer|nil Number of days from today (default 0)
function M.open(days_offset)
	if not config.is_valid() then
		vim.notify("piki: Wiki directory not configured or not found", vim.log.levels.ERROR)
		return
	end

    if not config.dailydir then
        vim.notify("piki: daily directory not configured", vim.log.levels.WARN)
        return
    end

	days_offset = days_offset or 0
	local date = os.date("%Y-%m-%d", os.time() + days_offset * 86400) --[[@as string]]
	local filename = config.dailydir .. "/" .. date .. ".md"

	-- Expand ~ and other path components for io.open() compatibility
	local expanded_filename = vim.fn.expand(filename)

	-- Check if the file exists
	local file = io.open(expanded_filename, "r")
	if file then
		file:close()
	else
		-- File doesn't exist, create it with the template content
		local template_content = M.get_template_content()
		local content = template_content:gsub("{{ date }}", date)

		if not utils.write_file(expanded_filename, content) then
			vim.notify("Failed to create daily file: " .. expanded_filename, vim.log.levels.ERROR)
			return
		end

		-- If this is a new file, check for incomplete todos from most recent previous daily
		local prev_date = M.get_most_recent_previous_daily(date)
		if prev_date then
			local prev_filepath = config.dailydir .. "/" .. prev_date .. ".md"
			local todos = M.extract_incomplete_todos(prev_filepath)

			if #todos > 0 then
				-- Append rollover section to new file
				-- Append rollover section to new file
				local rollover_content = "\n## Rolled over from [[" .. prev_date .. "]]\n\n"
				for _, todo in ipairs(todos) do
					rollover_content = rollover_content .. todo .. "\n"
				end
				if utils.append_file(expanded_filename, rollover_content) then
					-- Mark todos as forwarded in previous file
					M.mark_todos_forwarded(prev_filepath, todos)
				end
			end
		end
	end

	-- Open the file in the editor
	-- If actively editing a file, use split; otherwise use full screen
	local should_split = vim.fn.bufname() ~= "" and vim.bo[0].buftype == "" and vim.fn.line("$") > 1

	if should_split then
		-- Split view: 20% height or minimum 10 lines
		vim.cmd("aboveleft " .. math.max(10, math.floor(vim.o.lines * 0.2)) .. "split " .. expanded_filename)
	else
		-- Full screen: we're on splash/empty buffer, open in current window
		vim.cmd("edit " .. expanded_filename)
	end
	M.setup_daily_buffer()
end

--- Close daily note buffer
function M.close()
	if vim.b.piki then
        if vim.bo.modified then
            local choice = vim.fn.confirm("Save daily note?", "&Yes\n&No\n&Cancel", 1)
            if choice == 1 then
                vim.cmd("silent! write")
                vim.cmd("quit")
            end
            if choice == 2 then
                vim.cmd("quit!") -- Close the window and buffer
            end
            if choice == 3 then
                return
            end
        else
            vim.cmd("quit")
        end
	end
end

--- Delete unmodified daily notes that match the template exactly
function M.cleanup()
	if not config.is_valid() then
		vim.notify("piki: Wiki directory not configured or not found", vim.log.levels.ERROR)
		return
	end

	local template_content = M.get_template_content()

	local files = M.list_files()
	local unmodified_files = {}

	for _, filename in ipairs(files) do
		local filepath = config.dailydir .. "/" .. filename
		local year, month, day = filename:match("(%d+)-(%d+)-(%d+)%.md")

		if year and month and day then
			local date = string.format("%04d-%02d-%02d", tonumber(year), tonumber(month), tonumber(day))

			-- Generate expected content from template
			local expected_content = template_content:gsub("{{ date }}", date)

			-- Read actual file content
			local actual_content = utils.read_file(filepath)
			if actual_content then
				-- Compare content
				if actual_content == expected_content then
					table.insert(unmodified_files, {
						name = filename,
						path = filepath,
						date = date,
					})
				end
			end
		end
	end

	if #unmodified_files == 0 then
		vim.notify("No unmodified daily notes found!", vim.log.levels.INFO)
		return
	end

	-- Show preview of files to be deleted
	local preview_lines = { "Found " .. #unmodified_files .. " unmodified daily note(s):", "" }
	for _, file in ipairs(unmodified_files) do
		table.insert(preview_lines, "  " .. file.name)
	end
	table.insert(preview_lines, "")
	table.insert(preview_lines, "Press 'd' to delete all, 'q' to cancel")

	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, preview_lines)
	vim.bo[buf].modifiable = false
	vim.bo[buf].buftype = "nofile"

	local width = 50
	local height = math.min(#preview_lines, 20)
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		col = math.ceil((vim.o.columns - width) / 2),
		row = math.ceil((vim.o.lines - height) / 2),
		style = "minimal",
		border = "rounded",
	})

	local keymap_opts = { buffer = buf, nowait = true, silent = true }

	vim.keymap.set("n", "q", function()
		vim.api.nvim_win_close(win, true)
		vim.notify("Cleanup cancelled", vim.log.levels.INFO)
	end, keymap_opts)

	vim.keymap.set("n", "<Esc>", function()
		vim.api.nvim_win_close(win, true)
		vim.notify("Cleanup cancelled", vim.log.levels.INFO)
	end, keymap_opts)

	vim.keymap.set("n", "d", function()
		local deleted_count = 0
		for _, file in ipairs(unmodified_files) do
			local success = os.remove(file.path)
			if success then
				deleted_count = deleted_count + 1
			else
				vim.notify("Failed to delete: " .. file.name, vim.log.levels.WARN)
			end
		end

		vim.api.nvim_win_close(win, true)
		vim.notify("Deleted " .. deleted_count .. " unmodified daily note(s)", vim.log.levels.INFO)
	end, keymap_opts)
end

return M
