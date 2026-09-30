-- The gates at the biome lines you haven't unlocked: a sheet across the
-- corridor, yellow at the floor fading to clear GateHeight studs up, with QM's
-- "LV. N REQUIRED" card on it. Only you see your gates; each one fades away
-- when your pen reaches its level (PenLevel). The ride stops you at them.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local WorldColors = require(ReplicatedStorage.Shared.WorldColors)

local player = Players.LocalPlayer
local PIXELS_PER_STUD = 20
local CARD_HEIGHT = 0.55 -- of the gate's height
local CARD_ASPECT = 1068 / 662 -- GateLv2.png

local gates = {} -- [biome index] = { part, fades }

local function build(i)
	local width, height = Config.CourseHalfWidth * 2, Config.GateHeight
	local part = Instance.new("Part")
	part.Name = "Gate" .. i
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Transparency = 1
	part.Size = Vector3.new(width, height, 0.2)
	part.CFrame = CFrame.new(0, height / 2, WorldColors.biomeStart(i))

	local fades = {}
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Back -- faces home (+z), the way you ride up to it
	gui.CanvasSize = Vector2.new(width, height) * PIXELS_PER_STUD
	gui.LightInfluence = 0
	gui.Adornee = part

	local sheet = Instance.new("Frame")
	sheet.Size = UDim2.fromScale(1, 1)
	sheet.BorderSizePixel = 0
	sheet.BackgroundColor3 = Config.GateColor
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90 -- top (0) to bottom (1)
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.6, 0.75),
		NumberSequenceKeypoint.new(1, 0.1),
	})
	gradient.Parent = sheet
	sheet.Parent = gui
	table.insert(fades, { sheet, "BackgroundTransparency" })

	local image = Config.Biomes[i].GateImage
	local card
	if image and image ~= "" then
		card = Instance.new("ImageLabel")
		card.Image = image
		card.BackgroundTransparency = 1
		table.insert(fades, { card, "ImageTransparency" })
	else
		card = Instance.new("TextLabel") -- until the card image is uploaded
		card.Text = "LV. " .. i .. " REQUIRED"
		card.Font = Enum.Font.FredokaOne
		card.TextScaled = true
		card.TextColor3 = Color3.new(1, 1, 1)
		card.BackgroundColor3 = Config.GateColor
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 6
		stroke.Parent = card
		Instance.new("UICorner", card).CornerRadius = UDim.new(0.15, 0)
		table.insert(fades, { card, "TextTransparency" })
		table.insert(fades, { card, "BackgroundTransparency" })
		table.insert(fades, { stroke, "Transparency" })
	end
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromScale(0.5, 0.5)
	card.Size = UDim2.fromScale(CARD_HEIGHT * height * CARD_ASPECT / width, CARD_HEIGHT)
	card.Parent = sheet

	gui.Parent = player:WaitForChild("PlayerGui")
	part.Parent = workspace
	gates[i] = { part = part, gui = gui, fades = fades }
end

local function unlock(i)
	local gate = gates[i]
	gates[i] = nil
	local info = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	for _, fade in gate.fades do
		TweenService:Create(fade[1], info, { [fade[2]] = 1 }):Play()
	end
	task.delay(0.7, function()
		gate.gui:Destroy()
		gate.part:Destroy()
	end)
end

local function refresh()
	local level = player:GetAttribute("PenLevel") or 1
	for i = 2, #Config.Biomes do
		if i > level and not gates[i] then
			build(i)
		elseif i <= level and gates[i] then
			unlock(i)
		end
	end
end

player:GetAttributeChangedSignal("PenLevel"):Connect(refresh)
refresh()
