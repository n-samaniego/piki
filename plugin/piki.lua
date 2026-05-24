-- Keymaps for piki

-- pcall() has 2 return values, which it assigns to has_piki and piki. it says, call the function require with argument "piki", but return any errors. has_piki is a bool, piki is the return of require("piki"). if it succeeds, has_piki is true, piki contains an M table from lua/piki/init.lua. if false, piki has the error msg.
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
    vim.keymap.set("n", "<leader>dn", piki.open_daily, { desc = "Open today's daily note" })
    vim.keymap.set("n", "<leader>dh", piki.daily_prev, { desc = "Previous daily note" })
    vim.keymap.set("n", "<leader>dl", piki.daily_next, { desc = "Next daily note" })
end
