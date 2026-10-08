-- The recommended lasso level (Config.LassoLevels) over the animal you'd lasso as you
-- ride (QM, Oct 8): the lasso icon with the level beside it, like the HUD's lasso
-- counter, the number coloured by how it compares with your lasso strength (QM, Oct 8):
-- white at or under yours (safe), orange up to 9x yours (risky), red past that. Ride.client
-- moves it with the target ring (Outline.set).
--
--   LassoLevel.set(model, kind) -- show it over this animal; nil hides it
--   LassoLevel.setSelf(character) -- yours over your head while you ride (QM, Oct 8:
--                                 -- the same tag, your real level, in green); nil hides it

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Hud = require(script.Parent.Hud)
local Outline = require(script.Parent.Outline)

local ICON = 40 -- px
local ABOVE = 1.5 -- studs over the animal's top
local RISKY = 9 -- up to this many times your strength: risky (QM: a rough sense of scale)
local SAFE_COLOR = Color3.new(1, 1, 1)
local RISKY_COLOR = Color3.fromRGB(255, 150, 30)
local HARD_COLOR = Color3.fromRGB(255, 50, 50)

local LassoLevel = {}

local tag, number
local function newTag()
	local tag = Instance.new("BillboardGui")
	tag.Name = "LassoLevel"
	tag.Size = UDim2.fromOffset(200, ICON)
	tag.AlwaysOnTop = true
	tag.LightInfluence = 0
	tag.ResetOnSpawn = false
	tag.Enabled = false
	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.Size = UDim2.fromScale(1, 1)
	row.Parent = tag
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, -ICON * 0.2) -- the number overlaps the icon's edge, like the HUD's
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = row
	local icon = Instance.new("ImageLabel")
	icon.BackgroundTransparency = 1
	icon.Size = UDim2.fromOffset(ICON, ICON)
	icon.Image = Hud.lassoIcon
	icon.Parent = row
	local number = Instance.new("TextLabel")
	number.BackgroundTransparency = 1
	number.AutomaticSize = Enum.AutomaticSize.X
	number.Size = UDim2.fromOffset(0, ICON)
	number.Font = Enum.Font.FredokaOne
	number.TextSize = 28
	number.LayoutOrder = 1
	number.ZIndex = 2
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = number
	number.Parent = row
	tag.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	return tag, number
end

local function build()
	tag, number = newTag()
end

local shown, shownLevel
local function recolor()
	if not shownLevel then
		return
	end
	local mine = math.max(Players.LocalPlayer:GetAttribute("Lasso") or 0, Config.HoldOn.MinStrength) -- (at least MinStrength in a match-up)
	number.TextColor3 = if shownLevel <= mine then SAFE_COLOR elseif shownLevel <= mine * RISKY then RISKY_COLOR else HARD_COLOR
end
Players.LocalPlayer:GetAttributeChangedSignal("Lasso"):Connect(recolor)

function LassoLevel.set(model, kind)
	local level = kind and Config.LassoLevels[kind]
	if not (model and level and model.PrimaryPart) then
		model = nil
	end
	if model == shown then
		return
	end
	shown = model
	if not tag then
		build()
	end
	if not model then
		tag.Enabled = false
		tag.Adornee = nil
		return
	end
	local box, size = Outline.box(model)
	tag.Adornee = model.PrimaryPart
	tag.StudsOffset = Vector3.new(0, box.Y + size.Y / 2 + ABOVE, 0)
	shownLevel = level
	recolor()
	number.Text = (Hud.money(level):gsub("%$", ""))
	tag.Enabled = true
end

-- Your own lasso level over your head while you ride: the same tag, in green (QM).
local SELF_COLOR = Color3.fromHex("8EFFA1")
local selfTag, selfNumber, selfOn
function LassoLevel.setSelf(character)
	local head = character and character:FindFirstChild("Head")
	if not head then
		if selfTag and selfOn then
			selfTag.Enabled, selfOn = false, false
		end
		return
	end
	if not selfTag then
		selfTag, selfNumber = newTag()
		selfTag.Name = "MyLassoLevel"
		selfNumber.TextColor3 = SELF_COLOR
		selfTag.StudsOffset = Vector3.new(0, 2.5, 0)
	end
	selfTag.Adornee = head
	selfNumber.Text = (Hud.money(Players.LocalPlayer:GetAttribute("Lasso") or 0):gsub("%$", ""))
	if not selfOn then
		selfTag.Enabled, selfOn = true, true
	end
end

-- Other riders' lasso levels over their heads, the same green tag, while they ride out
-- (Ride's vfx.updateRiders: only while their lasso swings, so not hanging on or with an
-- egg). Their "Lasso" attribute comes from the server, so nothing more is sent.
local otherTags = {} -- [player] = { tag, number }
function LassoLevel.setOther(p, character)
	local head = character and character:FindFirstChild("Head")
	local o = otherTags[p]
	if not head then
		if o then
			o.tag:Destroy()
			otherTags[p] = nil
		end
		return
	end
	if not o then
		local tag, number = newTag()
		tag.Name = "LassoLevel" .. p.UserId
		number.TextColor3 = SELF_COLOR
		tag.StudsOffset = Vector3.new(0, 2.5, 0)
		tag.Enabled = true
		o = { tag = tag, number = number }
		otherTags[p] = o
	end
	o.tag.Adornee = head
	o.number.Text = (Hud.money(p:GetAttribute("Lasso") or 0):gsub("%$", ""))
end

return LassoLevel
