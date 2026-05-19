-- Smoke test: verify plugin loads without errors
local ok, piki = pcall(require, "piki")

if not ok then
	print("ERROR: Failed to load piki module")
	print(piki)
	vim.cmd("cquit 1")
end

-- Test setup function exists
if type(piki.setup) ~= "function" then
	print("ERROR: piki.setup is not a function")
	vim.cmd("cquit 1")
end

-- Try to call setup with minimal config
local setup_ok, err = pcall(function()
	piki.setup({ path = "/tmp/test-wiki" })
end)

if not setup_ok then
	print("ERROR: Failed to run piki.setup()")
	print(err)
	vim.cmd("cquit 1")
end

print("SUCCESS: piki plugin loaded and initialized")
