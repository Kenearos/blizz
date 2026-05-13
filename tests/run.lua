-- tests/run.lua
-- Discovers tests/test_*.lua, runs each in a fresh _G.Blizz scope, prints summary.
-- Each test file uses plain `assert(cond, msg)` and prints "✓ name" on pass.

package.path = "./?.lua;./?/init.lua;" .. package.path

local lfs_ok, lfs = pcall(require, "lfs")
local function list_test_files()
	local files = {}
	if lfs_ok then
		for f in lfs.dir("tests") do
			if f:match("^test_.+%.lua$") then
				table.insert(files, "tests." .. f:gsub("%.lua$", ""))
			end
		end
	else
		-- fallback: shell glob via io.popen
		local p = io.popen("ls tests/test_*.lua 2>/dev/null")
		if p then
			for line in p:lines() do
				local name = line:gsub("^tests/", ""):gsub("%.lua$", "")
				table.insert(files, "tests." .. name)
			end
			p:close()
		end
	end
	table.sort(files)
	return files
end

local files = list_test_files()
if #files == 0 then
	print("No tests found in tests/test_*.lua")
	os.exit(0)
end

local passed, failed = 0, 0
local failures = {}

for _, modname in ipairs(files) do
	-- fresh state per test file
	_G.Blizz = nil
	for k in pairs(package.loaded) do
		if
			k:match("^core%.")
			or k:match("^ui%.")
			or k:match("^config%.")
			or k == modname
			or k == "tests.mocks.wow_api"
		then
			package.loaded[k] = nil
		end
	end

	io.write(string.format("\n=== %s ===\n", modname))
	local ok, err = pcall(require, modname)
	if ok then
		passed = passed + 1
	else
		failed = failed + 1
		table.insert(failures, { mod = modname, err = err })
		print("✗ FAIL:", err)
	end
end

print(string.format("\n--- %d passed, %d failed ---", passed, failed))
if failed > 0 then
	for _, f in ipairs(failures) do
		print("FAIL:", f.mod)
	end
	os.exit(1)
end
