-- Keymaps for piki

local has_piki, piki = pcall(require, "piki")
if not has_piki then
	return
end

-- Default keymaps
-- You can disable these by setting vim.g.piki_disable_mappings = true
if not vim.g.piki_disable_mappings then
	vim.keymap.set({ "n", "v" }, "<leader>w", piki.picker, { desc = "piki!" })
	vim.keymap.set("n", "<leader>wb", piki.backlinks, { desc = "piki backlinks" })
	vim.keymap.set("n", "<leader>wg", piki.show_graph, { desc = "piki graph view" })
	vim.keymap.set("n", "<leader>wq", piki.capture_with_location, { desc = "piki quick capture" })
	vim.keymap.set("v", "<leader>wq", piki.capture_visual, { desc = "piki capture selection" })
	vim.keymap.set("n", "<leader>wi", piki.inbox, { desc = "piki inbox" })
end
