-- todo.lua - todo logic, will be imported into daily.lua

local M = {}

local config = require("piki.config")
local utils = require("piki.utils")
local patterns = config.patterns

--- Extract incomplete todos from a daily note file
--- @param filepath string Absolute path to the daily note
--- @return string[] Lines containing unchecked or blocked todos
function M.extract_incomplete_todos(filepath)
	local todos = {}
	local lines = utils.read_lines(filepath)
    local filename = vim.fn.fnamemodify(filepath, ":t:r")
	if not lines then
		return todos
	end

	for _, line in ipairs(lines) do
		-- Match lines with [ ] (unchecked) or [>] (forwarded/in progress)
		if line:match("^%s*%-%[%s%]") or line:match("^%s*%-%[%>%]") then
            -- Add date injection/wikilink
            local tagged_line
            if filename:match(patterns.DATE_FILENAME) then
                if not line:match("#%d+%-%d+%-%d+") then
                    -- filename is date, then tag = #date
                    tagged_line = line .. " #" .. filename
                else
                    tagged_line = line
                end
            else
                -- append = wikilink
                tagged_line = line .. " [[" .. filename .. "]]"
            end
            table.insert(todos, tagged_line) -- append tag to todos
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

return M
