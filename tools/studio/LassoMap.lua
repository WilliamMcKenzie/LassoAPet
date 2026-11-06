-- Lasso Map (QM, Nov 6): a Studio plugin for editing Lasso a Pet's map in Edit mode, the way
-- Fight to Steal an Egg's Map Baker works. The map is the parts in workspace.World, saved in
-- the place (publish to keep them); nothing builds it when the game runs.
--
-- Biome borders: workspace.World.Borders has a part where each biome starts (named after
-- it) and one at the finish line ("End"). Drag them along the course to stretch or shrink
-- the biomes (Shared/Borders): only their Z counts. When one moves, this repaints the
-- ground and walls with each biome's colours (Shared/WorldColors, as the game does in Play)
-- and prints the biome lengths in the Output. They're hidden in Play.
--
-- Install: copy this file into Studio's plugins folder (on a Mac ~/Documents/Roblox/Plugins)
-- and restart Studio. A "Lasso Map" toolbar appears:
--   Make borders   adds any missing border where Config has that biome start (and the end)
--   Repaint        repaints the ground and walls from the borders as they are now
-- It only does anything in a place with ReplicatedStorage.Shared.Borders (Lasso a Pet's).

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local toolbar = plugin:CreateToolbar("Lasso Map")
local makeButton = toolbar:CreateButton("LassoMapMake", "Add any missing biome border to workspace.World.Borders", "", "Make borders")
local repaintButton = toolbar:CreateButton("LassoMapRepaint", "Repaint the ground and walls from the biome borders", "", "Repaint")
makeButton.ClickableWhenViewportHidden = true
repaintButton.ClickableWhenViewportHidden = true

local function lasso()
	local shared = ReplicatedStorage:FindFirstChild("Shared")
	return shared and shared:FindFirstChild("Borders") and shared:FindFirstChild("WorldColors") and shared
end

-- Fresh copies of Shared's modules (a module required from a plugin stays cached, so the
-- originals would run stale code and keep the borders as they were).
local function fresh(fn)
	local shared = lasso()
	if not shared then
		return
	end
	local tmp = Instance.new("Folder")
	tmp.Name = "LassoMapTemp"
	shared:Clone().Parent = tmp
	tmp.Parent = ServerStorage
	local ok, err = pcall(function()
		local Config = require(tmp.Shared.Config) -- (applies the borders as they are now)
		fn(Config, require(tmp.Shared.WorldColors), require(tmp.Shared.Borders))
	end)
	tmp:Destroy()
	if not ok then
		warn("[Lasso Map] " .. tostring(err))
	end
	return ok
end

local function lengths(Config)
	local out = {}
	for _, biome in Config.Biomes do
		table.insert(out, biome.Name .. " " .. biome.Length)
	end
	print("[Lasso Map] biome lengths: " .. table.concat(out, ", ") .. "; course " .. Config.CourseLength)
end

-- The ground and walls painted as WorldColors.watch does in Play, from Config's colours (or
-- World's colour attributes, where a test left some), without adding attributes to World.
local function repaint()
	local world = workspace:FindFirstChild("World")
	if RunService:IsRunning() or not world then
		return
	end
	local recording = ChangeHistoryService:TryBeginRecording("Repaint biomes")
	fresh(function(Config, WorldColors)
		local defaults = {}
		for i, biome in Config.Biomes do
			local p = WorldColors.prefix(i)
			defaults[p .. "GroundA"], defaults[p .. "GroundB"] = biome.GroundColors[1], biome.GroundColors[2]
			defaults[p .. "WallA"], defaults[p .. "WallB"] = biome.WallColors[1], biome.WallColors[2]
			for name, colors in biome.Patches or {} do
				defaults[p .. name .. "A"], defaults[p .. name .. "B"] = colors[1], colors[2]
			end
		end
		local proxy = {
			Ground = world:FindFirstChild("Ground"),
			Walls = world:FindFirstChild("Walls"),
		}
		function proxy:GetAttribute(key)
			local v = world:GetAttribute(key)
			if v == nil then
				return defaults[key]
			end
			return v
		end
		function proxy:FindFirstChild(name)
			return world:FindFirstChild(name)
		end
		if proxy.Ground and proxy.Walls then
			WorldColors.apply(proxy)
		end
		lengths(Config)
	end)
	if recording then
		ChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Commit)
	end
end

-- Repaints a moment after a border stops moving.
local watched, pending = {}, false
local function changed()
	if pending then
		return
	end
	pending = true
	task.delay(0.6, function()
		pending = false
		repaint()
	end)
end

local function watch()
	local world = workspace:FindFirstChild("World")
	local folder = world and world:FindFirstChild("Borders")
	if not (folder and lasso()) or watched[folder] then
		return
	end
	watched[folder] = true
	local function hook(part)
		if part:IsA("BasePart") then
			part:GetPropertyChangedSignal("CFrame"):Connect(function()
				if not RunService:IsRunning() then
					changed()
				end
			end)
		end
	end
	for _, part in folder:GetChildren() do
		hook(part)
	end
	folder.ChildAdded:Connect(function(part)
		hook(part)
		changed()
	end)
	folder.ChildRemoved:Connect(changed)
end

makeButton.Click:Connect(function()
	makeButton:SetActive(false)
	local world = workspace:FindFirstChild("World")
	if RunService:IsRunning() or not world or not lasso() then
		warn("[Lasso Map] needs Edit mode and Lasso a Pet's workspace.World")
		return
	end
	local recording = ChangeHistoryService:TryBeginRecording("Make borders")
	fresh(function(Config, _, Borders)
		Borders.make(Config, world)
	end)
	if recording then
		ChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Commit)
	end
	watch()
end)

repaintButton.Click:Connect(function()
	repaintButton:SetActive(false)
	repaint()
end)

if not RunService:IsRunning() then
	task.defer(watch)
	workspace.DescendantAdded:Connect(function(d)
		if d.Name == "Borders" and d:IsA("Folder") then
			task.defer(watch)
		end
	end)
end
