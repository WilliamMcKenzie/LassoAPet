-- Map Baker (QM, Oct 24; Fight to Steal an Egg's, ported to Lasso A Pet Nov 6): a Studio plugin that bakes the map into the place in Edit mode,
-- so it's there to see and save without pressing Play.
--
-- Install: copy this file into Studio's plugins folder (Plugins tab > Plugins Folder;
-- on a Mac ~/Documents/Roblox/Plugins) as LassoMapBaker.lua, so it sits beside Fight to
-- Steal an Egg's MapBaker.lua, and restart Studio. A "Lasso Map Baker" toolbar appears:
--   Rebuild     bakes Shared/MapData (maps/world.map, as synced from the repo)
--   Import .map bakes a .map straight from disk (a download from the map editor), to
--               look at before it goes in the repo (tools/map_bake.py)
-- Either replaces workspace.World (one undo step). Save the place afterwards. The game
-- plays on the baked map (Server/Map.ensure).
--   Pet Lineup  stands every biome's animals mid-run in their biome (workspace.PetLineup),
--               sized by workspace.PetScale, which resizes them as you change it
--               (Shared/PetLineup, Shared/PetScale)
--   (and in Edit mode the fog follows the camera: each biome's own, workspace.Fog)

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local StudioService = game:GetService("StudioService")

local toolbar = plugin:CreateToolbar("Lasso Map Baker") -- (not "Map": Fight to Steal an Egg's Map Baker has that)
local rebuild = toolbar:CreateButton("MapBakerRebuild", "Bake Shared/MapData into workspace.World", "", "Rebuild")
local import = toolbar:CreateButton("MapBakerImport", "Bake a .map file from disk into workspace.World", "", "Import .map")
local petLineup = toolbar:CreateButton("MapBakerPetLineup", "Stand every biome's animals mid-run in their biome, sized by workspace.PetScale", "", "Pet Lineup")
rebuild.ClickableWhenViewportHidden = true
import.ClickableWhenViewportHidden = true
petLineup.ClickableWhenViewportHidden = true

-- Fresh copies of Server.Map and Shared, side by side (Map finds Shared beside it): a
-- module required from a plugin stays cached, so the originals would bake stale code.
local function fresh()
	local shared = ReplicatedStorage:FindFirstChild("Shared")
	local server = ServerScriptService:FindFirstChild("Server")
	local mapModule = server and server:FindFirstChild("Map")
	assert(shared and mapModule, "needs ReplicatedStorage.Shared and ServerScriptService.Server.Map (sync src/ first)")
	local tmp = Instance.new("Folder")
	tmp.Name = "MapBakerTemp"
	shared:Clone().Parent = tmp
	mapModule:Clone().Parent = tmp
	tmp.Parent = ServerStorage
	return tmp
end

local function bake(label, text)
	if RunService:IsRunning() then
		warn("[Map Baker] stop Play first: the map is baked in Edit mode")
		return
	end
	local recording = ChangeHistoryService:TryBeginRecording(label)
	local tmp
	local ok, err = pcall(function()
		tmp = fresh()
		local Map = require(tmp.Map)
		local data = nil
		if text then
			data = require(tmp.Shared.MapFile).decode(text)
		end
		local started = os.clock()
		local map = Map.build(data)
		local parts = 0
		for _, d in map:GetDescendants() do
			if d:IsA("BasePart") then
				parts += 1
			end
		end
		print(string.format("[Map Baker] baked workspace.World: %d parts in %.1fs. Save the place to keep it.", parts, os.clock() - started))
	end)
	if tmp then
		tmp:Destroy()
	end
	if recording then
		ChangeHistoryService:FinishRecording(
			recording,
			if ok then Enum.FinishRecordingOperation.Commit else Enum.FinishRecordingOperation.Cancel
		)
	end
	if not ok then
		warn("[Map Baker] " .. tostring(err))
	end
end

rebuild.Click:Connect(function()
	rebuild:SetActive(false)
	bake("Bake map")
end)

import.Click:Connect(function()
	import:SetActive(false)
	local ok, file = pcall(StudioService.PromptImportFileAsync, StudioService, { "map", "json", "txt" })
	if not ok then
		-- (a type filter Studio doesn't take: pick any file)
		ok, file = pcall(StudioService.PromptImportFileAsync, StudioService)
	end
	if not ok then
		warn("[Map Baker] couldn't open the file picker: " .. tostring(file))
		return
	end
	if not file then
		return
	end
	print("[Map Baker] importing " .. file.Name)
	bake("Import " .. file.Name, file:GetBinaryContents())
	print("[Map Baker] to keep it in the game, send " .. file.Name .. " over to go in the repo (maps/world.map)")
end)

-- ---- the studs, in Edit mode ---------------------------------------------------------------
-- (QM, Oct 30) workspace.StudStyle's knobs (ground and everything else: Transparency and
-- TileScale) hold for every stud Texture in Edit mode too: this makes them when the place
-- has none and repaints the place (Shared/StudStyle, a fresh copy each time, so an update
-- shows without restarting Studio) whenever one changes or the map is baked. During Play,
-- Shared/StudStyle does the same itself.
local studStyle, studConn = nil, nil

local function studCode()
	local shared = ReplicatedStorage:FindFirstChild("Shared")
	local module = shared and shared:FindFirstChild("StudStyle")
	if not (module and module:IsA("ModuleScript")) then
		return nil, nil
	end
	local tmp = Instance.new("Folder")
	tmp.Name = "StudStyleTemp"
	local copy = module:Clone()
	copy.Parent = tmp
	local config = shared:FindFirstChild("Config")
	if config then
		config:Clone().Parent = tmp
	end
	local ok, code = pcall(require, copy)
	return if ok then code else nil, tmp
end

local function studPaint()
	if RunService:IsRunning() then
		return
	end
	local code, tmp = studCode()
	if code then
		local ok, err = pcall(function()
			code.ensure()
			code.applyAll()
		end)
		if not ok then
			warn("[Map Baker] StudStyle: " .. tostring(err))
		end
	end
	if tmp then
		tmp:Destroy()
	end
end

local function studHook()
	if RunService:IsRunning() then
		return
	end
	studPaint() -- (makes workspace.StudStyle if it's missing)
	local style = workspace:FindFirstChild("StudStyle")
	if style and style ~= studStyle then
		if studConn then
			studConn:Disconnect()
		end
		studStyle = style
		studConn = style.AttributeChanged:Connect(studPaint)
	end
end

task.defer(studHook)
workspace.ChildAdded:Connect(function(child)
	if child.Name == "StudStyle" or child.Name == "World" then
		task.defer(studHook)
	end
end)
workspace.ChildRemoved:Connect(function(child)
	if child == studStyle then
		studStyle = nil
		if studConn then
			studConn:Disconnect()
			studConn = nil
		end
	end
end)

-- ---- the pet lineup, in Edit mode ----------------------------------------------------------
-- (QM, Oct 31 in Fight to Steal an Egg; Lasso, Nov 6) Pet Lineup (re)builds every biome's
-- animals mid-run in their biome (Shared/PetLineup, from a fresh copy of Shared); while
-- workspace.PetLineup is there, changing an animal's workspace.PetScale resizes it in the
-- lineup, and ticking CopyValues prints the values as a Config.AnimalScale line.
local lineupConn, lineupTmp = nil, nil

local function lineupCode()
	if lineupConn then
		lineupConn:Disconnect()
		lineupConn = nil
	end
	if lineupTmp then
		lineupTmp:Destroy()
		lineupTmp = nil
	end
	local shared = ReplicatedStorage:FindFirstChild("Shared")
	if not (shared and shared:FindFirstChild("PetLineup")) then
		return nil
	end
	lineupTmp = Instance.new("Folder")
	lineupTmp.Name = "PetLineupTemp"
	shared:Clone().Parent = lineupTmp
	lineupTmp.Parent = ServerStorage
	local ok, code = pcall(require, lineupTmp.Shared.PetLineup)
	lineupTmp.Parent = nil -- (kept for the watcher, not saved with the place)
	if not ok then
		warn("[Map Baker] PetLineup: " .. tostring(code))
		return nil
	end
	return code
end

local function lineupHook(rebuildIt)
	if RunService:IsRunning() then
		return
	end
	local code = lineupCode()
	if not code then
		return
	end
	local ok, err = pcall(function()
		if rebuildIt then
			code.build()
		end
		lineupConn = code.watch()
	end)
	if not ok then
		warn("[Map Baker] PetLineup: " .. tostring(err))
	end
end

petLineup.Click:Connect(function()
	local recording = ChangeHistoryService:TryBeginRecording("Pet Lineup")
	lineupHook(true)
	if recording then
		ChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Commit)
	end
end)
task.defer(function()
	if workspace:FindFirstChild("PetLineup") then
		lineupHook(false)
	end
end)

-- ---- each biome's fog, in Edit mode ----------------------------------------------------------
-- (QM, Nov 6) While workspace.Fog is there, the fog follows the Studio camera: fly into a
-- biome and you see its fog (Shared/BiomeFog), so changing its Color, Start or End shows at once.
local fogCode = nil
RunService.Heartbeat:Connect(function(dt)
	if RunService:IsRunning() or not workspace:FindFirstChild("Fog") then
		return
	end
	if not fogCode then
		local module = ReplicatedStorage:FindFirstChild("Shared") and ReplicatedStorage.Shared:FindFirstChild("BiomeFog")
		if not module then
			return
		end
		local copy = module:Clone() -- (a fresh copy: a module required from a plugin stays cached)
		local ok, code = pcall(require, copy)
		fogCode = if ok then code else false
		if not ok then
			warn("[Map Baker] BiomeFog: " .. tostring(code))
		end
	end
	if fogCode then
		fogCode.step(workspace.CurrentCamera.CFrame.Position.Z, dt)
	end
end)
