-- The 100x Luck Event's sign (Config.LuckEvent, QM Nov 7): a long beam across the course's
-- mouth, wall to wall, and a board in its middle with the title and countdown on both faces.
-- LuckEventSign.build() puts it in workspace as "LuckEventSign" (replacing one already there):
-- Server/LuckEvent at runtime, and Studio's command bar in Edit mode so it shows there too
-- (QM: `require(game.ReplicatedStorage.Shared.LuckEventSign).build()`). Client/LuckEvent
-- animates its Title and Timer labels.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local MapData = require(Shared.MapData)
local MapFile = require(Shared.MapFile)
local Studs = require(Shared.Studs)

local LuckEventSign = {}

local W, H = 1040, 300 -- the board's canvas (20 pixels a stud: Sign 52 x 15)
LuckEventSign.RAINBOW = {
	Color3.fromRGB(255, 70, 70),
	Color3.fromRGB(255, 160, 50),
	Color3.fromRGB(255, 235, 70),
	Color3.fromRGB(80, 220, 90),
	Color3.fromRGB(70, 150, 255),
	Color3.fromRGB(170, 90, 240),
}

-- the title in rich text, letter k coloured RAINBOW[k + shift], spaces skipped
function LuckEventSign.rainbow(text, shift)
	local out, k = {}, 0
	local colors = LuckEventSign.RAINBOW
	for _, code in utf8.codes(text) do
		local ch = utf8.char(code)
		if ch == " " then
			table.insert(out, ch)
		else
			local c = colors[(k + shift) % #colors + 1]
			table.insert(out, string.format('<font color="rgb(%d,%d,%d)">%s</font>', math.round(c.R * 255), math.round(c.G * 255), math.round(c.B * 255), ch))
			k += 1
		end
	end
	return table.concat(out)
end

function LuckEventSign.clock(seconds)
	seconds = math.max(0, math.ceil(seconds))
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

local function face(board, normal)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Face" .. normal.Name
	gui.Face = normal
	gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	gui.CanvasSize = Vector2.new(W, H)
	gui.LightInfluence = 0
	gui.MaxDistance = 600
	local function label(name, text, y, h)
		local l = Instance.new("TextLabel")
		l.Name = name
		l.BackgroundTransparency = 1
		l.Position = UDim2.fromOffset(20, y)
		l.Size = UDim2.fromOffset(W - 40, h)
		l.FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json")
		l.TextScaled = true
		l.RichText = true
		l.TextColor3 = Color3.new(1, 1, 1)
		l.Text = text
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(30, 22, 40)
		stroke.Thickness = 5
		stroke.LineJoinMode = Enum.LineJoinMode.Round
		stroke.Parent = l
		l.Parent = gui
	end
	label("Title", LuckEventSign.rainbow(Config.LuckEvent.Title, 0), 34, 140)
	label("Timer", "Starts in: " .. LuckEventSign.clock(Config.LuckEvent.Every), 190, 76)
	gui.Parent = board
end

function LuckEventSign.build()
	local old = workspace:FindFirstChild("LuckEventSign")
	if old then
		old:Destroy()
	end
	local S = Config.LuckEvent.Sign
	local ground = MapFile.groundAt(MapData, 0, S.Z + 12) -- (the base's floor, just in front of it)
	local mid = CFrame.new(0, ground + S.Height, S.Z)
	local span = 2 * Config.CourseHalfWidth + 8 -- (its ends into the walls)

	local model = Instance.new("Model")
	model.Name = "LuckEventSign"
	local function block(name, size, cf, color)
		local p = Instance.new("Part")
		p.Name = name
		p.Anchored = true
		p.CanCollide, p.CanQuery, p.CanTouch = false, false, false -- (rides and the Slingshot pass through)
		p.Material = Enum.Material.SmoothPlastic
		p.Color = color
		p.Size = size
		p.CFrame = cf
		Studs.apply(p, 0.5)
		p.Locked = true
		p.Parent = model
		return p
	end
	block("BeamTrim", Vector3.new(span, 4.4, 1.6), mid * CFrame.new(0, 1, 0), S.Trim)
	block("Beam", Vector3.new(span - 2, 3.2, 2), mid * CFrame.new(0, 1, 0), S.Color)
	block("Frame", Vector3.new(S.Width + 2, S.BoardHeight + 2, 2.4), mid, S.Trim)
	local board = block("Board", Vector3.new(S.Width, S.BoardHeight, 3), mid, S.Color)
	face(board, Enum.NormalId.Back) -- (Back faces the base, +z)
	face(board, Enum.NormalId.Front)
	model.PrimaryPart = board
	model.Parent = workspace
	return model
end

return LuckEventSign
