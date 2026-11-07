-- (QM, Oct 31 in Fight to Steal an Egg; Lasso, Nov 6) Builds the pet lineup, every biome's
-- animals mid-run in their biome (Shared/PetLineup), and keeps it following
-- workspace.PetScale until Studio closes. Run in Studio's command bar in Edit mode, or
-- `python3 tools/studio/lu.py tools/studio/pet_lineup.luau Edit`, after syncing src/.
-- Re-runnable. (The Map Baker plugin's "Pet Lineup" button does the same, and keeps it
-- following after Studio restarts.) Save the place after.
local ServerStorage = game:GetService("ServerStorage")

if _G.PetLineupWatch then
	_G.PetLineupWatch:Disconnect()
	_G.PetLineupWatch = nil
end
-- (a fresh copy of Shared: a module required here stays cached, so the original could be stale)
local tmp = Instance.new("Folder")
tmp.Name = "PetLineupTemp"
game:GetService("ReplicatedStorage").Shared:Clone().Parent = tmp
tmp.Parent = ServerStorage
local counts = {}
local ok, err = pcall(function()
	local PetLineup = require(tmp.Shared.PetLineup)
	local root = PetLineup.build()
	for _, group in root:GetChildren() do
		table.insert(counts, group.Name .. " " .. #group:GetChildren())
	end
	_G.PetLineupWatch = PetLineup.watch()
end)
tmp.Parent = nil -- (kept alive for the watcher, not saved with the place)
if not ok then
	warn("[Pet lineup] " .. tostring(err))
	return "error: " .. tostring(err)
end
print("[Pet lineup] built: change workspace.PetScale to resize, tick CopyValues to print them")
return "built: " .. table.concat(counts, ", ")
