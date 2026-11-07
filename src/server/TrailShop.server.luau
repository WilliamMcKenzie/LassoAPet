-- The Trails Shop's stand (Config.TrailShop, QM Nov 7): Fight to Steal an Egg's Weapon Shop
-- stall (its Server/Map vendor() and shopSign(), 1:1) with Carl the cactus guy: posts, beams, a counter and
-- a green and white striped roof (Shared/TrailStallModel), "Trails Shop" floating over it and a
-- glowing ring on the ground in front. Built at the origin, its counter facing -z, then scaled,
-- turned and placed. Carl's Talk prompt and its ring open the popup (Client/TrailShop); buying and
-- equipping are Gold.server's BuyTrail and EquipTrail.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local HiddenFaces = require(ReplicatedStorage.Shared.HiddenFaces)
local Studs = require(ReplicatedStorage.Shared.Studs)
local TrailStallModel = require(ReplicatedStorage.Shared.TrailStallModel)
local Cactus = require(ReplicatedStorage.Shared.Animals.Cactus)

local s = Config.TrailShop
local TITLE_FONT = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.ExtraBold)

-- the shop's sign over the roof and its ring on the ground: parts of the stall, so they turn
-- and scale with it
local function shopSign(model, title)
	local anchor = Instance.new("Part")
	anchor.Name = "Title"
	anchor.Anchored, anchor.CanCollide, anchor.CanQuery, anchor.CanTouch = true, false, false, false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(1, 1, 1)
	anchor.CFrame = CFrame.new(0, 19.5, 0)
	anchor.Parent = model
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromScale(s.TitleHeight * 6, s.TitleHeight)
	gui.LightInfluence = 0
	gui.MaxDistance = 200
	gui.Parent = anchor
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.FontFace = TITLE_FONT
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Text = title
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Color = ColorSequence.new(s.TitleTop, s.TitleBottom)
	gradient.Parent = label
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = s.TitleStroke
	stroke.Parent = label
	label.Parent = gui
	-- the ring: a see-through disc with a glowing rim of short neon blocks round it
	local ring = Instance.new("Model")
	ring.Name = "Ring"
	local r, at = s.RingRadius, CFrame.new(0, 0, -s.RingAhead)
	local disc = Instance.new("Part")
	disc.Name = "Disc"
	disc.Shape = Enum.PartType.Cylinder
	disc.Size = Vector3.new(0.12, r * 2, r * 2)
	disc.CFrame = at * CFrame.new(0, 0.07, 0) * CFrame.Angles(0, 0, math.pi / 2)
	disc.Color = s.RingColor
	disc.Material = Enum.Material.SmoothPlastic
	disc.Transparency = 0.6
	disc.CastShadow = false
	disc.Anchored, disc.CanCollide, disc.CanQuery, disc.CanTouch = true, false, false, false
	disc.Parent = ring
	local n = 48
	for i = 1, n do
		local a = (i - 0.5) / n * math.pi * 2
		local rim = Instance.new("Part")
		rim.Name = "Rim"
		rim.Size = Vector3.new(0.8, 0.3, 2 * math.pi * r / n + 0.12)
		rim.CFrame = at * CFrame.Angles(0, a, 0) * CFrame.new(r - 0.4, 0.15, 0)
		rim.Color = s.RingColor
		rim.Material = Enum.Material.Neon
		rim.Transparency = 0.15
		rim.CastShadow = false
		rim.Anchored, rim.CanCollide, rim.CanQuery, rim.CanTouch = true, false, false, false
		rim.Parent = ring
	end
	ring.Parent = model
end

local function stall()
	local model = Instance.new("Model")
	model.Name = "TrailShop"
	local counter
	for _, spec in TrailStallModel.parts do
		local part = Instance.new("Part")
		part.Name = spec.name
		part.Size = spec.size
		part.CFrame = spec.cframe
		part.Color = spec.color
		part.Material = Enum.Material.SmoothPlastic
		part.Anchored = true
		part.TopSurface, part.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		Studs.apply(part, 0.5)
		part.Parent = model
		if spec.name == "Counter" then
			counter = part
		end
	end
	-- where Carl's feet go (Client/TrailShop stands its own Carl here, who idles and watches you),
	-- and a still Carl so he shows in Studio's Edit mode
	local spot = Instance.new("Part")
	spot.Name = "CarlSpot"
	spot.Anchored, spot.CanCollide, spot.CanQuery, spot.CanTouch = true, false, false, false
	spot.Transparency = 1
	spot.Size = Vector3.new(1, 1, 1)
	spot.CFrame = CFrame.new(TrailStallModel.carl)
	spot.Parent = model
	local carl = Cactus.new().model
	carl.Name = "Carl"
	for _, part in carl:GetDescendants() do
		if part:IsA("BasePart") then
			part.CanCollide, part.CanQuery, part.CanTouch = false, false, false
		end
	end
	carl:ScaleTo((s.CarlScale or s.Scale) / s.Scale) -- (the stall's ScaleTo below brings him to CarlScale)
	carl:PivotTo(spot.CFrame)
	carl.Parent = model
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "OpenPrompt"
	prompt.ActionText = "Talk"
	prompt.ObjectText = "Carl"
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = s.Reach * s.Scale
	prompt.Parent = counter
	shopSign(model, s.Title)
	return model
end

local old = workspace:FindFirstChild("TrailShop")
if old then
	old:Destroy()
end
local model = stall()
model.WorldPivot = CFrame.identity
if s.Scale ~= 1 then
	model:ScaleTo(s.Scale)
	Studs.fit(model, 0.5 * s.Scale)
end
model:PivotTo(CFrame.new(s.Position) * CFrame.Angles(0, math.rad(s.Yaw), 0))
local gui = model.Title:FindFirstChildOfClass("BillboardGui")
gui.Size = UDim2.fromScale(s.TitleHeight * 6 * s.Scale, s.TitleHeight * s.Scale)
HiddenFaces.cull(model)
model:SetAttribute("Scale", s.Scale)
model.Parent = workspace
