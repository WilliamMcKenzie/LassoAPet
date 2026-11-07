-- The leaderboards' faces (Config.Leaderboards, QM Nov 7; Server/Leaderboards builds the boards):
-- each board's title with its icon either side ("Title"), and its list ("Screen"), from
-- ReplicatedStorage.Leaderboards: a row a player, best first, their avatar with "#rank" over
-- its corner, the value top right with the icon, "@username" under it (#1 gold, #3 orange).
-- In PlayerGui (adorned to the parts) so the lists scroll.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local HudImages = require(script.Parent.HudImages)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local values = ReplicatedStorage:WaitForChild("Leaderboards")
local boards = workspace:WaitForChild("Leaderboards")

local FONT = Font.new("rbxasset://fonts/families/FredokaOne.json", Enum.FontWeight.Bold)
local PX = 40 -- canvas pixels a stud
local ROW = 80 -- a row's height (canvas pixels)
local GOLD = Color3.fromRGB(255, 206, 40)
local ORANGE = Color3.fromRGB(255, 150, 40)
local WHITE = Color3.new(1, 1, 1)
local INK = Color3.fromRGB(24, 22, 34)

-- ---- numbers -----------------------------------------------------------------

local SUFFIXES = { "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }
local function short(n)
	local i = 0
	while n >= 1000 and i < #SUFFIXES do
		n /= 1000
		i += 1
	end
	if i == 0 then
		return tostring(math.floor(n))
	end
	return (string.format("%.1f", math.floor(n * 10) / 10):gsub("%.0$", "")) .. SUFFIXES[i]
end

local function duration(seconds)
	local m = math.floor(seconds / 60)
	local h, d = math.floor(m / 60), math.floor(m / 1440)
	if d > 0 then
		return d .. "d " .. (h % 24) .. "h"
	elseif h > 0 then
		return h .. "h " .. (m % 60) .. "m"
	end
	return m .. "m"
end

local TEXT = {
	Money = function(v)
		return "$" .. short(v) .. "/s"
	end,
	Luck = function(v)
		return Config.luckText(v / 100)
	end,
	Playtime = duration,
}

-- ---- pieces --------------------------------------------------------------------

local function stroke(parent, colour, thickness)
	local s = Instance.new("UIStroke")
	s.Color = colour
	s.Thickness = thickness
	s.LineJoinMode = Enum.LineJoinMode.Round
	s.Parent = parent
	return s
end

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = radius
	c.Parent = parent
end

local function label(parent, text, colour, x, y, w, h, align)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Position = UDim2.fromOffset(x, y)
	l.Size = UDim2.fromOffset(w, h)
	l.FontFace = FONT
	l.TextColor3 = colour
	l.TextScaled = true
	l.TextXAlignment = align or Enum.TextXAlignment.Center
	l.TextTruncate = Enum.TextTruncate.AtEnd
	l.Text = text
	l.Parent = parent
	return l
end

-- The Playtime board's clock (no clock image: drawn): a pink ring, a white face, two hands.
local function clock(parent, x, y, size)
	local ring = Instance.new("Frame")
	ring.Position = UDim2.fromOffset(x, y)
	ring.Size = UDim2.fromOffset(size, size)
	ring.BackgroundColor3 = Color3.fromRGB(238, 60, 130)
	ring.BorderSizePixel = 0
	corner(ring, UDim.new(0.5, 0))
	stroke(ring, Color3.fromRGB(110, 10, 50), math.max(1, size / 18))
	local face = Instance.new("Frame")
	face.AnchorPoint = Vector2.new(0.5, 0.5)
	face.Position = UDim2.fromScale(0.5, 0.5)
	face.Size = UDim2.fromScale(0.72, 0.72)
	face.BackgroundColor3 = WHITE
	face.BorderSizePixel = 0
	corner(face, UDim.new(0.5, 0))
	face.Parent = ring
	for _, hand in { { Vector2.new(0.5, 1), UDim2.fromScale(0.07, 0.34) }, { Vector2.new(0, 0.5), UDim2.fromScale(0.26, 0.07) } } do
		local f = Instance.new("Frame") -- (one hand up to 12, the other out to 3)
		f.AnchorPoint = hand[1]
		f.Position = UDim2.fromScale(0.5, 0.5)
		f.Size = hand[2]
		f.BackgroundColor3 = Color3.fromRGB(200, 30, 60)
		f.BorderSizePixel = 0
		f.Parent = face
	end
	ring.Parent = parent
	return ring
end

local function icon(key, parent, x, y, size, flip)
	if key == "Playtime" then
		return clock(parent, x, y, size)
	end
	local i = Instance.new("ImageLabel")
	i.BackgroundTransparency = 1
	i.Position = UDim2.fromOffset(x, y)
	i.Size = UDim2.fromOffset(size, size)
	i.ScaleType = Enum.ScaleType.Fit
	i.Image = if key == "Luck" then HudImages.LuckIcon elseif flip then HudImages.CashStackFlip else HudImages.CashStack
	i.Parent = parent
	return i
end

local function surface(part, name, w, h)
	local gui = Instance.new("SurfaceGui")
	gui.Name = name
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	gui.CanvasSize = Vector2.new(w, h)
	gui.LightInfluence = 0
	gui.MaxDistance = 300
	gui.ResetOnSpawn = false
	gui.Adornee = part
	return gui
end

-- ---- a board ---------------------------------------------------------------------

local function build(board)
	local model = boards:WaitForChild(board.Key)
	local value = values:WaitForChild(board.Key)
	local key = board.Key

	-- the title: "Top Money" between two icons, in the board's colour with a dark edge
	local titlePart = model:WaitForChild("Title")
	local tw, th = math.floor(titlePart.Size.X * PX), math.floor(titlePart.Size.Y * PX)
	local title = surface(titlePart, "Leaderboard" .. key .. "Title", tw, th)
	local iconSize = math.floor(th * 0.72)
	local textW = math.floor(tw * 0.56)
	local text = label(title, board.Title, board.Text, (tw - textW) / 2, th * 0.14, textW, th * 0.72)
	stroke(text, board.Dark:Lerp(Color3.new(0, 0, 0), 0.35), 5)
	icon(key, title, (tw - textW) / 2 - iconSize - 6, (th - iconSize) / 2, iconSize, false)
	icon(key, title, (tw + textW) / 2 + 6, (th - iconSize) / 2, iconSize, true)
	title.Parent = playerGui

	-- the list
	local screen = model:WaitForChild("Screen")
	local w, h = math.floor(screen.Size.X * PX), math.floor(screen.Size.Y * PX)
	local gui = surface(screen, "Leaderboard" .. key, w, h)
	local list = Instance.new("ScrollingFrame")
	list.Position = UDim2.fromOffset(8, 8)
	list.Size = UDim2.fromOffset(w - 16, h - 16)
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.ScrollBarThickness = 6
	list.ScrollBarImageColor3 = board.Dark
	list.CanvasSize = UDim2.new()
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.Parent = gui
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list
	gui.Parent = playerGui

	local rw = w - 16 - 10 -- a row's width (the scroll bar beside it)
	local function row(rank, entry)
		local id, name, v = entry[1], entry[2], entry[3]
		local f = Instance.new("Frame")
		f.LayoutOrder = rank
		f.Size = UDim2.fromOffset(rw, ROW)
		f.BackgroundColor3 = Color3.fromRGB(112, 118, 146)
		f.BorderSizePixel = 0
		stroke(f, Color3.fromRGB(40, 42, 60), 4)
		local face = Instance.new("ImageLabel")
		face.Position = UDim2.fromOffset(6, 4)
		face.Size = UDim2.fromOffset(ROW - 8, ROW - 8)
		face.BackgroundTransparency = 1
		face.Image = "rbxthumb://type=AvatarHeadShot&id=" .. id .. "&w=150&h=150"
		face.Parent = f
		local nameColour = if rank == 1 then GOLD elseif rank == 3 then ORANGE else WHITE
		local r = label(f, "#" .. rank, nameColour, 4, ROW - 36, 52, 32, Enum.TextXAlignment.Left)
		stroke(r, INK, 3)
		-- top right: the icon, then the value (a row, right-aligned, sized to the text: nothing overlaps)
		local top = Instance.new("Frame")
		top.BackgroundTransparency = 1
		top.Position = UDim2.fromOffset(ROW + 8, 4)
		top.Size = UDim2.fromOffset(rw - ROW - 18, 36)
		top.Parent = f
		local across = Instance.new("UIListLayout")
		across.FillDirection = Enum.FillDirection.Horizontal
		across.HorizontalAlignment = Enum.HorizontalAlignment.Right
		across.VerticalAlignment = Enum.VerticalAlignment.Center
		across.SortOrder = Enum.SortOrder.LayoutOrder
		across.Padding = UDim.new(0, 8)
		across.Parent = top
		local ic = icon(key, top, 0, 0, 32, false)
		ic.LayoutOrder = 1
		local vt = label(top, TEXT[key](v), board.Value, 0, 0, 0, 36, Enum.TextXAlignment.Right)
		vt.LayoutOrder = 2
		vt.TextScaled = false
		vt.TextSize = 32
		vt.TextTruncate = Enum.TextTruncate.None
		vt.AutomaticSize = Enum.AutomaticSize.X
		stroke(vt, INK, 3)
		local n = label(f, "@" .. name, nameColour, ROW + 4, 42, rw - ROW - 12, 34, Enum.TextXAlignment.Right)
		n.TextScaled = false
		n.TextSize = 28
		stroke(n, INK, 3)
		f.Parent = list
	end

	local function fill()
		for _, child in list:GetChildren() do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
		local ok, rows = pcall(HttpService.JSONDecode, HttpService, value.Value)
		if not ok or typeof(rows) ~= "table" then
			return
		end
		for rank, entry in rows do
			row(rank, entry)
		end
	end
	value.Changed:Connect(fill)
	fill()
end

for _, board in Config.Leaderboards.Boards do
	task.spawn(build, board)
end
