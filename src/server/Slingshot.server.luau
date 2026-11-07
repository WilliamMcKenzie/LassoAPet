-- The Slingshot (Config.Slingshot, QM Nov 6): everyone's (the top bar that sold it is gone,
-- QM Nov 6), it stands in front of its owner's pen: Ahead studs out from the pen's
-- Spawn, facing away from the pen, so its band rests pulled back toward the pen's opening.
-- Built here from the uploaded meshes (design/slingshot): the frame's pieces, and three
-- band pieces (BandL, BandMid, BandR) that Client/Slingshot stretches. It follows the pen
-- as it grows (its Spawn moves). Hold E at it: Client/SlingshotLaunch.
-- workspace.Slingshots.<UserId>, with an "Owner" attribute. The band's colour goes up with
-- your pen level (Config.Slingshot.BandColors: each Upgrade Pen recolours it).

local AssetService = game:GetService("AssetService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Studs = require(ReplicatedStorage.Shared.Studs)
local SlingshotPose = require(ReplicatedStorage.Shared.SlingshotPose)
local Funnel = require(script.Parent.Funnel)

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
		prompt.MaxActivationDistance = 16 -- (from the base's middle: the band hangs right over it now)
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

local function bandColor(player)
	local colors = CFG.BandColors
	if not colors or #colors == 0 then
		return CFG.BandColor
	end
	return colors[math.clamp(player:GetAttribute("PenLevel") or 1, 1, #colors)]
end

local function paint(player)
	local p = placed[player]
	if p then
		for _, name in { "BandL", "BandMid", "BandR" } do
			local band = p.model:FindFirstChild(name)
			if band then
				band.Color = bandColor(player)
			end
		end
	end
end

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
	if player:GetAttribute("Tutorial") then
		return -- (none till the tutorial's over: QM, Nov 6; Hatchery's "Tutorial")
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
	paint(player)
end

local function watch(player)
	player:GetAttributeChangedSignal("Tutorial"):Connect(function()
		place(player)
	end)
	player:GetAttributeChangedSignal("Pen"):Connect(function()
		place(player)
	end)
	player:GetAttributeChangedSignal("PenLevel"):Connect(function()
		paint(player)
	end)
	place(player)
end
Players.PlayerAdded:Connect(watch)
for _, player in Players:GetPlayers() do
	task.spawn(watch, player)
end
Players.PlayerRemoving:Connect(remove)

-- Unlocking a biome from the Slingshot's menu (Client/SlingshotMenu, in place of the top
-- bar): the next one in order, for its UnlockCost cash, takes your pen level up to it (its
-- gate opens: PenLevel.server saves it). Returns true if it went through.
local unlock = Instance.new("RemoteFunction")
unlock.Name = "UnlockBiome"
unlock.Parent = ReplicatedStorage
unlock.OnServerInvoke = function(player, i)
	local level = player:GetAttribute("PenLevel") or 1
	local biome = typeof(i) == "number" and Config.Biomes[i]
	if not biome or i ~= level + 1 then
		return false
	end
	local cost = Config.unlockCost(player, i) -- (x2 a rebirth: Config.Luck)
	local gold = player:GetAttribute("Gold") or 0
	if gold < cost then
		return false
	end
	player:SetAttribute("Gold", gold - cost)
	Funnel.cash(player, true, cost, Enum.AnalyticsEconomyTransactionType.Shop.Name, "Unlock " .. biome.Name)
	local zone = ReplicatedStorage:FindFirstChild("ZoneUnlocked")
	if zone then
		zone:FireClient(player, i) -- (its gate breaks open on camera: Gate.client)
	end
	player:SetAttribute("PenLevel", i)
	Funnel.unlocked(player, i, "cash")
	return true
end

-- A biome bought with Robux (Config.Biomes[i].RobuxProduct; Shop.server's ProcessReceipt
-- invokes this): your pen level up to it. True once given.
local grant = Instance.new("BindableFunction")
grant.Name = "GrantBiome"
grant.OnInvoke = function(player, i)
	if not (player and player.Parent and Config.Biomes[i]) then
		return false
	end
	local level = player:GetAttribute("PenLevel") or 1
	if i > level then
		local zone = ReplicatedStorage:FindFirstChild("ZoneUnlocked")
		if zone then
			zone:FireClient(player, i)
		end
		player:SetAttribute("PenLevel", i)
		Funnel.unlocked(player, i, "robux")
	end
	return true
end
grant.Parent = game:GetService("ServerStorage")
