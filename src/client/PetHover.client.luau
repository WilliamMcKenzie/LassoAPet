-- Your pets at home under the mouse (QM, Oct 5): the one you point at gets a thin
-- white outline and its speed over its body, a blue bolt over the number. On a
-- phone (no pointer) it's the pet you last tapped, until you tap off it.
--
-- The outline is one shared Highlight, moved onto the pet you point at and
-- parented nowhere otherwise (moving it redraws the pet, fine at mouse speed). A
-- phone gets the dashed ring (Outline.ring) instead: Highlights hitch on phones.
-- The pets are your pen's (PenPets.pets) and the one waiting to be ridden
-- (Ride.client's starter, PenPets.starter()).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)
local Merge = require(ReplicatedStorage.Shared.Merge)
local PenPets = require(script.Parent.PenPets)
local Outline = require(script.Parent.Outline)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local ICON = "rbxassetid://108037539336444" -- assets/ui/SpeedIcon.png
local STUDS_PER_METRE = 4 -- the HUD's
local REACH = 400 -- studs from the camera

local highlight = Instance.new("Highlight")
highlight.Name = "PetHover"
highlight.FillTransparency = 1
highlight.OutlineColor = Color3.new(1, 1, 1)
highlight.OutlineTransparency = 0

local tag = Instance.new("BillboardGui")
tag.Name = "PetSpeed"
tag.Size = UDim2.fromOffset(180, 96)
tag.AlwaysOnTop = true
tag.LightInfluence = 0
tag.ResetOnSpawn = false
local icon = Instance.new("ImageLabel")
icon.Image = ICON
icon.BackgroundTransparency = 1
icon.AnchorPoint = Vector2.new(0.5, 0)
icon.Position = UDim2.fromScale(0.5, 0)
icon.Size = UDim2.fromOffset(40, 40)
icon.Parent = tag
local text = Instance.new("TextLabel")
text.BackgroundTransparency = 1
text.Position = UDim2.fromOffset(0, 40)
text.Size = UDim2.new(1, 0, 0, 52)
text.Font = Enum.Font.FredokaOne
text.TextScaled = true
text.TextColor3 = Color3.new(1, 1, 1)
local stroke = Instance.new("UIStroke")
stroke.Thickness = 3
stroke.Parent = text
text.Parent = tag

local function touchOnly()
	return UserInputService.TouchEnabled and not UserInputService.MouseEnabled
end

-- Your pets at home: [model] = { kind, merged }.
local function homePets()
	local list = {}
	for model, info in PenPets.pets do
		if model.Parent then
			list[model] = { kind = info.kind, merged = info.merged or 1 }
		end
	end
	local starter = PenPets.starter and PenPets.starter()
	if starter and starter.Parent then
		list[starter] = { kind = player:GetAttribute("RidePet") or Config.DefaultPet, merged = player:GetAttribute("RideMerged") or 1 }
	end
	return list
end

-- The home pet at screen point (x, y) (viewport pixels), if any.
local function petAt(x, y)
	local pets = homePets()
	local models = {}
	for model in pets do
		table.insert(models, model)
	end
	if #models == 0 then
		return nil
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = models
	local ray = camera:ViewportPointToRay(x, y)
	local hit = workspace:Raycast(ray.Origin, ray.Direction * REACH, params)
	local part = hit and hit.Instance
	while part and not pets[part] do
		part = part.Parent
	end
	return part, part and pets[part]
end

local function speedText(kind, merged)
	local studs = Config.MountSpeed * ((Config.AnimalStats[kind] or {}).Speed or 1) * Merge.speed(kind, merged)
	local metres = studs / STUDS_PER_METRE
	return (if metres < 10 then string.format("%.1f", metres) else tostring(math.floor(metres + 0.5))) .. " m/s"
end

local target, ring
local function show(model, info)
	if model == target then
		return
	end
	target = model
	if ring then
		ring:Destroy()
		ring = nil
	end
	if not model or not model.PrimaryPart then
		target = nil
		highlight.Parent = nil
		tag.Parent = nil
		return
	end
	if touchOnly() then
		ring = Outline.ring(model)
	else
		highlight.Parent = model
	end
	local box, size = Outline.box(model)
	tag.StudsOffsetWorldSpace = Vector3.new(0, box.Y + size.Y * 0.1, 0)
	text.Text = speedText(info.kind, info.merged)
	tag.Adornee = model.PrimaryPart
	tag.Parent = model.PrimaryPart
end

-- A phone: the pet you tap (and off it again with a tap anywhere else).
UserInputService.TouchTap:Connect(function(positions, processed)
	if processed or not positions[1] then
		return
	end
	local inset = game:GetService("GuiService"):GetGuiInset()
	local p = positions[1] + inset
	show(petAt(p.X, p.Y))
end)

RunService.RenderStepped:Connect(function()
	if target and not target.Parent then
		show(nil)
	end
	if touchOnly() then
		return
	end
	local m = UserInputService:GetMouseLocation()
	show(petAt(m.X, m.Y))
end)
