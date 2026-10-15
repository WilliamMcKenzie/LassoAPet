-- The pets for Robux at World 1's base (Config.PetOffers, QM Oct 15: the Loong in the podium's
-- place, the Robo Shark beside it), each idling over a glowing cyan ring, light rising round it in a curtain that fades
-- as it goes up, so it reads as something you can buy. Its prompt opens the Loong's
-- developer product (Shop.server grants it). Built on each client, as the podium's snake
-- was, so its idle plays (Motor6D.Transform doesn't replicate).

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
if not (Config.Podium and Config.Podium.Hidden and Config.PetOffers) then
	return
end
local Rig = require(ReplicatedStorage.Shared.Animals.Rig)

local STUD_TEXTURE = { image = "rbxassetid://7447638591", tile = 0.5 } -- the animals'
local player = Players.LocalPlayer

local function build(offer)
local at = Config.Podium.Position + (offer.Offset or Vector3.zero)
local LoongModel = require(ReplicatedStorage.Shared.Animals:FindFirstChild(offer.Kind .. "Model"))
local name = (offer.Kind:gsub("(%l)(%u)", "%1 %2"))
local LEFT = offer.Kind .. "Left"

local folder = Instance.new("Model")
folder.Name = offer.Kind .. "Offer"

local function part(props)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	for k, v in props do
		p[k] = v
	end
	p.Parent = folder
	return p
end

-- The ring: a glowing disc, a brighter rim round it.
local R = offer.Ring
part({ Name = "Glow", Shape = Enum.PartType.Cylinder, Material = Enum.Material.Neon, Color = offer.Glow, Transparency = 0.45,
	Size = Vector3.new(0.3, R, R), CFrame = CFrame.new(at + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90)) })
part({ Name = "Rim", Shape = Enum.PartType.Cylinder, Material = Enum.Material.Neon, Color = offer.Glow, Transparency = 0.1,
	Size = Vector3.new(0.2, R + 1.2, R + 1.2), CFrame = CFrame.new(at + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.rad(90)) })

-- The light rising round it: beams from the rim straight up, bright at the foot, gone at the top.
local hub = part({ Name = "Hub", Transparency = 1, Size = Vector3.one, CFrame = CFrame.new(at) })
local N = 36
for i = 1, N do
	local a = i / N * math.pi * 2
	local foot = Instance.new("Attachment")
	foot.Position = Vector3.new(math.cos(a) * R / 2, 0.3, math.sin(a) * R / 2)
	foot.Parent = hub
	local top = Instance.new("Attachment")
	top.Position = foot.Position + Vector3.new(0, offer.Rise, 0)
	top.Parent = hub
	local beam = Instance.new("Beam")
	beam.Attachment0, beam.Attachment1 = foot, top
	beam.Color = ColorSequence.new(offer.Glow)
	beam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 1) })
	beam.LightEmission = 1
	beam.Width0, beam.Width1 = R * math.pi / N * 1.4, R * math.pi / N * 1.4
	beam.FaceCamera = true
	beam.Segments = 2
	beam.Parent = hub
end
-- Sparks drifting up through it.
local sparks = Instance.new("ParticleEmitter")
sparks.Color = ColorSequence.new(offer.Glow)
sparks.LightEmission = 1
sparks.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
sparks.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
sparks.Lifetime = NumberRange.new(1.5, 2.5)
sparks.Rate = 18
sparks.Speed = NumberRange.new(4, 7)
sparks.SpreadAngle = Vector2.new(8, 8)
sparks.EmissionDirection = Enum.NormalId.Top
local spark = part({ Name = "Sparks", Transparency = 1, Size = Vector3.new(R, 0.2, R), CFrame = CFrame.new(at + Vector3.new(0, 0.3, 0)) })
sparks.Parent = spark

-- The Loong, idling over the ring.
local size = offer.Scale
local model, _, bones = Rig.fromData(LoongModel, offer.Kind, STUD_TEXTURE, size)
for _, p in model:GetDescendants() do
	if p:IsA("BasePart") then
		p.CanCollide, p.CanQuery, p.CanTouch = false, false, false
	end
end
model:PivotTo(CFrame.new(at + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, math.rad(offer.Yaw), 0))
do -- (floating its own height over the ring: QM, Oct 15)
	local _, standing = model:GetBoundingBox()
	model:PivotTo(model:GetPivot() + Vector3.new(0, standing.Y, 0))
end
model.Parent = folder

-- Its price and the prompt.
local tag = Instance.new("BillboardGui")
tag.Size = UDim2.fromScale(40, 6) -- (2x: QM, Oct 15; wide enough for "Robo Shark 870/1000 left" on one line)
local boxAt, box = model:GetBoundingBox()
tag.StudsOffsetWorldSpace = Vector3.new(0, math.max(boxAt.Y + box.Y / 2 - at.Y, offer.Rise) + 8, 0) -- (well over the Loong's head: QM, Oct 15, higher)
tag.AlwaysOnTop = false
tag.LightInfluence = 0
tag.MaxDistance = 200
local label = Instance.new("TextLabel")
label.BackgroundTransparency = 1
label.Size = UDim2.fromScale(1, 1)
label.FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json")
label.TextScaled = true
label.TextWrapped = false
label.TextColor3 = Color3.new(1, 1, 1)
local function showLeft()
	local left = workspace:GetAttribute(LEFT)
	label.Text = if left == nil then name
		elseif left <= 0 then name .. " SOLD OUT"
		else string.format("%s %d/%d left", name, left, offer.Stock) -- (QM, Oct 15)
end
workspace:GetAttributeChangedSignal(LEFT):Connect(showLeft)
showLeft()
local stroke = Instance.new("UIStroke")
stroke.Thickness = 5
stroke.Parent = label
label.Parent = tag
tag.Adornee = hub
tag.Parent = hub
local prompt = Instance.new("ProximityPrompt")
prompt.ActionText = "Buy " .. name
prompt.ObjectText = if offer.Price > 0 then "R$" .. offer.Price else name
prompt.HoldDuration = 0
prompt.MaxActivationDistance = R
prompt.RequiresLineOfSight = false
prompt.Parent = hub
local function promptOn()
	prompt.Enabled = (workspace:GetAttribute(LEFT) or 1) > 0 -- (none at SOLD OUT)
end
workspace:GetAttributeChangedSignal(LEFT):Connect(promptOn)
promptOn()
prompt.Triggered:Connect(function()
	if (workspace:GetAttribute(LEFT) or 0) <= 0 then
		return -- (checked first: sold out)
	elseif offer.ProductId ~= 0 then
		MarketplaceService:PromptProductPurchase(player, offer.ProductId)
	else
		warn("LoongOffer: no ProductId yet for " .. offer.Kind .. " (Config.PetOffers)")
	end
end)

folder.Parent = workspace

local idle = LoongModel.animations.idle or select(2, next(LoongModel.animations))
local t = 0
RunService.Heartbeat:Connect(function(dt)
	t = (t + dt) % idle.length
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if hrp and (hrp.Position - at).Magnitude > 300 then
		return -- out riding: too far to see it move
	end
	for bone, track in idle.tracks do
		local motor = bones[bone]
		if motor then
			local x, y, z = 0, 0, 0
			if track.position then
				x, y, z = Rig.sample(track.position, t)
			end
			local rx, ry, rz = 0, 0, 0
			if track.rotation then
				rx, ry, rz = Rig.sample(track.rotation, t)
			end
			motor.Transform = CFrame.new(x * size, y * size, z * size) * CFrame.Angles(rx, ry, rz)
		end
	end
end)
end

for _, offer in Config.PetOffers do
	build(offer)
end
