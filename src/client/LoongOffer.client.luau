-- Limited pet display: each pet on its own grass-and-dirt pedestal with gold trim (blocks in the
-- map's look, Shared/VoxelBlock), its Fredoka nameplate right above it. No sign (QM, Nov 7); the
-- row is turned Config.LimitedsTurn degrees in toward the base, as the Top Earners board.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Config = require(ReplicatedStorage.Shared.Config)
if Config.LimitedsStand == false or not (Config.Podium and Config.Podium.Hidden and Config.PetOffers and #Config.PetOffers > 0) then
	return
end
local Rig = require(ReplicatedStorage.Shared.Animals.Rig)
local VoxelBlock = require(ReplicatedStorage.Shared.VoxelBlock)
local player = Players.LocalPlayer
local FONT = Font.new("rbxasset://fonts/families/FredokaOne.json")
local GOLD = Color3.fromRGB(255, 209, 35)
local C = Config.WorldColors
local DIRT, DIRT_C = C.WallDirt, C.WallDirtChecker
local GRASS, GRASS_C = C.Grass, C.GrassChecker
local TRIM = Color3.fromRGB(255, 196, 40)
local STUD_TEXTURE = { image = "rbxassetid://7447638591", tile = 0.5 }
local display = Instance.new("Model")
display.Name = "LimitedsDisplay"
local stands = {}

local function part(name, size, at, color, material, transparency)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide, p.CanQuery, p.CanTouch = false, false, false
	p.CastShadow = false
	p.Size, p.CFrame = size, if typeof(at) == "CFrame" then at else CFrame.new(at)
	p.Color, p.Material = color, material or Enum.Material.SmoothPlastic
	p.Transparency = transparency or 0
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = display
	return p
end

-- a block in the map's look; you walk through it, as the old stand
local function block(name, size, at, color, checker)
	local p = VoxelBlock.new(name, display, if typeof(at) == "CFrame" then at else CFrame.new(at), size, color, checker)
	p.CanCollide, p.CanQuery, p.CanTouch = false, false, false
	return p
end

local function text(parent, name, value, color, y, height)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Position, label.Size = UDim2.fromScale(0, y), UDim2.fromScale(1, height)
	label.FontFace = FONT
	label.Text, label.TextColor3, label.TextScaled = value, color, true
	local stroke = Instance.new("UIStroke")
	stroke.Color, stroke.Thickness = Color3.fromRGB(20, 17, 28), 2.5
	stroke.Parent = label
	label.Parent = parent
	return label
end

-- the row turns about the first stand (the one nearest the course), the others swinging forward
local row = CFrame.new(Config.Podium.Position + (Config.PetOffers[1].Offset or Vector3.zero))
	* CFrame.Angles(0, -math.rad(Config.LimitedsTurn or 0), 0)
for i, offer in Config.PetOffers do
	local cf = row * CFrame.new((i - 1) * 28, 0, 0) -- this stand, turned with the row
	local at = cf.Position
	local width = offer.Ring or 22
	-- dirt, a gold step, grass on top: the pet stands at 1.5
	block(offer.Kind .. "Base", Vector3.new(width + 3, 0.8, width + 3), cf * CFrame.new(0, 0.4, 0), DIRT, DIRT_C)
	block(offer.Kind .. "Step", Vector3.new(width + 1.5, 0.35, width + 1.5), cf * CFrame.new(0, 0.975, 0), TRIM)
	block(offer.Kind .. "Platform", Vector3.new(width, 0.35, width), cf * CFrame.new(0, 1.325, 0), GRASS, GRASS_C)
	-- Four flat side panels, fading from gold at the floor to transparent at the top.
	for side = 0, 3 do
		local panel = part(offer.Kind .. "GradientSide", Vector3.new(width, 4, 0.05), at, GOLD, nil, 1)
		panel.CFrame = cf
			* CFrame.new(0, 3.4, 0)
			* CFrame.Angles(0, side * math.pi / 2, 0)
			* CFrame.new(0, 0, width / 2)
		for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
			local surface = Instance.new("SurfaceGui")
			surface.Name, surface.Face = "GoldGradient", face
			surface.LightInfluence, surface.PixelsPerStud = 0, 16
			local fill = Instance.new("Frame")
			fill.Size, fill.BorderSizePixel = UDim2.fromScale(1, 1), 0
			fill.BackgroundColor3 = GOLD
			local gradient = Instance.new("UIGradient")
			gradient.Rotation = 90
			gradient.Transparency =
				NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0.2) })
			gradient.Parent, fill.Parent, surface.Parent = fill, surface, panel
		end
	end

	local data = require(ReplicatedStorage.Shared.Animals[offer.Kind .. "Model"])
	local model, _, bones = Rig.fromData(data, offer.Kind, STUD_TEXTURE, offer.Scale)
	model.Name = offer.Kind
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			p.CanCollide, p.CanQuery, p.CanTouch = false, false, false
		end
	end
	model:PivotTo(cf * CFrame.Angles(0, math.rad(offer.Yaw), 0))
	local boxAt, box = model:GetBoundingBox()
	model:PivotTo(model:GetPivot() + Vector3.new(0, at.Y + 1.5 - (boxAt.Y - box.Y / 2), 0))
	model.Parent = display
	local hub = part(offer.Kind .. "Hub", Vector3.one, at, GOLD, nil, 1)
	local tag = Instance.new("BillboardGui")
	tag.Name = "OfferLabels"
	tag.Size = UDim2.fromScale(26, 10)
	-- right above its own pet: the label (10 studs) sits 2 studs over the pet's top
	local petTop = 1.5 + box.Y
	tag.StudsOffsetWorldSpace = Vector3.new(boxAt.X - at.X, petTop + 7, boxAt.Z - at.Z)
	tag.Adornee, tag.LightInfluence, tag.MaxDistance = hub, 0, 180
	tag.Parent = hub
	local stock = text(tag, "Stock", "LOADING STOCK", Color3.fromRGB(255, 65, 55), 0, 0.19)
	local name = (offer.Kind:gsub("(%l)(%u)", "%1 %2"))
	text(tag, "Title", string.upper(name), Color3.new(1, 1, 1), 0.19, 0.26)
	local rarity = require(ReplicatedStorage.Shared.Animals[offer.Kind]).Rarity
	text(tag, "Rarity", string.upper(rarity), Config.RarityColors[rarity], 0.45, 0.18)
	text(
		tag,
		"Income",
		"$" .. Config.short(Config.incomeIn(Config.World, offer.Kind) or 0) .. "/SEC",
		Color3.fromRGB(115, 255, 40),
		0.63,
		0.17
	)
	text(tag, "Robux", utf8.char(0xE002) .. " " .. offer.Price, Color3.fromRGB(255, 235, 118), 0.8, 0.2)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText, prompt.ObjectText = "Buy " .. name, "R$" .. offer.Price
	prompt.HoldDuration, prompt.MaxActivationDistance, prompt.RequiresLineOfSight = 0, width, false
	prompt.Parent = hub
	local function refresh()
		local left = workspace:GetAttribute(offer.Kind .. "Left")
		stock.Visible = Config.PetOffersLimited
		stock.Text = if left == nil
			then "LOADING STOCK"
			elseif left <= 0 then "SOLD OUT"
			else string.format("%d/%d STOCK", left, offer.Stock)
		prompt.Enabled = not Config.PetOffersLimited or (left ~= nil and left > 0)
	end
	workspace:GetAttributeChangedSignal(offer.Kind .. "Left"):Connect(refresh)
	refresh()
	prompt.PromptShown:Connect(function()
		local telemetry = ReplicatedStorage:FindFirstChild("Telemetry")
		if telemetry then telemetry:FireServer("monoView", "limited_" .. offer.Kind) end
	end)
	prompt.Triggered:Connect(function()
		if prompt.Enabled then
			ReplicatedStorage:WaitForChild("BuyShop"):FireServer(offer.Kind)
		end
	end)
	table.insert(stands, { model = model, data = data, bones = bones, scale = offer.Scale, at = at, t = 0 })
end

display.Parent = workspace
RunService.Heartbeat:Connect(function(dt)
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	for _, stand in stands do
		local idle = stand.data.animations.idle or select(2, next(stand.data.animations))
		if not idle or (hrp and (hrp.Position - stand.at).Magnitude > 300) then
			continue
		end
		stand.t = (stand.t + dt) % idle.length
		for bone, track in idle.tracks do
			local motor = stand.bones[bone]
			if motor then
				local x, y, z, rx, ry, rz = 0, 0, 0, 0, 0, 0
				if track.position then
					x, y, z = Rig.sample(track.position, stand.t)
				end
				if track.rotation then
					rx, ry, rz = Rig.sample(track.rotation, stand.t)
				end
				motor.Transform = CFrame.new(x * stand.scale, y * stand.scale, z * stand.scale)
					* CFrame.Angles(rx, ry, rz)
			end
		end
	end
end)
