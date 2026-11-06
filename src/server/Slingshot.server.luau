-- The Slingshot (Config.Slingshot, QM Nov 6): once bought (Gold.server's BuySlingshot,
-- "OwnsSlingshot"), it stands in front of its owner's pen: Ahead studs out from the pen's
-- Spawn, facing away from the pen, so its band rests pulled back toward the pen's opening.
-- Built here from the uploaded meshes (design/slingshot): the frame's pieces, and three
-- band pieces (BandL, BandMid, BandR) that Client/Slingshot stretches. It follows the pen
-- as it grows (its Spawn moves). Hold E at it: Client/SlingshotLaunch.
-- workspace.Slingshots.<UserId>, with an "Owner" attribute.

local AssetService = game:GetService("AssetService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Studs = require(ReplicatedStorage.Shared.Studs)
local SlingshotPose = require(ReplicatedStorage.Shared.SlingshotPose)

local CFG = Config.Slingshot

local folder = Instance.new("Folder")
folder.Name = "Slingshots"
folder.Parent = workspace

local template -- the frame and bands, built once from the meshes
local function build()
	if template ~= nil then
		return template or nil
	end
	if #CFG.Meshes == 0 or not CFG.Band then
		warn("Slingshot: no meshes yet (Config.Slingshot.Meshes: tools/slingshot_upload.py)")
		template = false
		return nil
	end
	local model = Instance.new("Model")
	model.Name = "Slingshot"
	for i, piece in CFG.Meshes do
		local ok, part = pcall(AssetService.CreateMeshPartAsync, AssetService, Content.fromUri("rbxassetid://" .. piece[1]))
		if ok then
			part.Name = "Frame" .. i
			part.Anchored = true
			part.Color = Color3.fromRGB(piece[2], piece[3], piece[4])
			part.CFrame = CFrame.new()
			Studs.apply(part, 0.5)
			part.Parent = model
		else
			warn("Slingshot: mesh " .. piece[1] .. " didn't load: " .. tostring(part))
		end
	end
	for _, name in { "BandL", "BandMid", "BandR" } do
		local ok, part = pcall(AssetService.CreateMeshPartAsync, AssetService, Content.fromUri("rbxassetid://" .. CFG.Band))
		if ok then
			part.Name = name
			part.Anchored = true
			part.CanCollide = false
			part.Color = CFG.BandColor
			Studs.apply(part, 0.5)
			part.Parent = model
		end
	end
	-- the Launch prompt, Roblox's own, on the slingshot (Client/SlingshotLaunch: the owner's works)
	local frame = model:FindFirstChild("Frame1")
	if frame then
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "Launch"
		prompt.ActionText = "Launch"
		prompt.ObjectText = "Slingshot"
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
		prompt.HoldDuration = 0.6
		prompt.MaxActivationDistance = 26 -- (from the base's middle: reaches the band where it rests)
		prompt.RequiresLineOfSight = false
		prompt.UIOffset = Vector2.new(0, -40)
		prompt.Parent = frame
	end
	model.WorldPivot = CFrame.new()
	template = model
	return model
end

-- Where a pen's slingshot stands: Ahead studs out from its Spawn, its back to the pen.
local function spotOf(pen)
	local spawn, area = pen:FindFirstChild("Spawn"), pen:FindFirstChild("Area")
	if not (spawn and area) then
		return nil
	end
	local d = Vector3.new(spawn.Position.X - area.Position.X, 0, spawn.Position.Z - area.Position.Z)
	if d.Magnitude < 0.01 then
		return nil
	end
	d = d.Unit
	local ground = area.Position.Y - area.Size.Y / 2 -- (the Area marker sits on the ground)
	local at = Vector3.new(spawn.Position.X, ground, spawn.Position.Z) + d * CFG.Ahead
	return CFrame.lookAt(at, at + d) -- (its -Z, the way it flings, away from the pen)
end

local placed = {} -- [player] = { model, connections }

local function remove(player)
	local p = placed[player]
	if p then
		for _, c in p.connections do
			c:Disconnect()
		end
		p.model:Destroy()
		placed[player] = nil
	end
end

local function place(player)
	remove(player)
	if not player:GetAttribute("OwnsSlingshot") then
		return
	end
	local index = player:GetAttribute("Pen")
	local pens = workspace:FindFirstChild("Pens")
	local pen = index and pens and pens:FindFirstChild("Pen" .. index)
	local spawn = pen and pen:FindFirstChild("Spawn")
	local source = build()
	if not spawn or not source then
		return
	end
	local model = source:Clone()
	model.Name = tostring(player.UserId)
	model:SetAttribute("Owner", player.UserId)
	local function move()
		local cf = spotOf(pen)
		if cf then
			model:PivotTo(cf)
			SlingshotPose.place(model, cf, 0)
		end
	end
	move()
	model.Parent = folder
	placed[player] = { model = model, connections = { spawn:GetPropertyChangedSignal("CFrame"):Connect(move) } }
end

local function watch(player)
	player:GetAttributeChangedSignal("OwnsSlingshot"):Connect(function()
		place(player)
	end)
	player:GetAttributeChangedSignal("Pen"):Connect(function()
		place(player)
	end)
	place(player)
end
Players.PlayerAdded:Connect(watch)
for _, player in Players:GetPlayers() do
	task.spawn(watch, player)
end
Players.PlayerRemoving:Connect(remove)
