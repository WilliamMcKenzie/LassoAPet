-- The Top Earners board's list (Config.TopEarners, QM Nov 6): drawn on workspace.TopEarners'
-- Screen (Server/TopEarners builds it), from ReplicatedStorage.TopEarners. A header
-- (WORLDWIDE / HALL OF FAME, TOP EARNERS, MONEY / SEC), the players best first (rank, avatar,
-- display name and @username, gold a second), and under them your own pen's gold a second
-- and the countdown to the next refresh. In PlayerGui (adorned to the Screen) so the list
-- scrolls.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local player = Players.LocalPlayer
local value = ReplicatedStorage:WaitForChild("TopEarners")
local board = workspace:WaitForChild("TopEarners")
local screen = board:WaitForChild("Screen")

local BOLD = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.ExtraBold)
local SEMI = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.SemiBold)
local GOLD = Color3.fromRGB(240, 196, 70)
local GREEN = Color3.fromRGB(120, 230, 120)
local GREY = Color3.fromRGB(150, 160, 155)
local WHITE = Color3.fromRGB(245, 245, 240)
local W, H = 532, 640 -- the canvas (20 pixels a stud)
local ROW = 58

local function money(n)
	return "$" .. string.upper(Config.short(n))
end

local function label(parent, text, font, colour, x, y, w, h, align)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Position = UDim2.fromOffset(x, y)
	l.Size = UDim2.fromOffset(w, h)
	l.FontFace = font
	l.TextColor3 = colour
	l.TextScaled = true
	l.TextXAlignment = align or Enum.TextXAlignment.Center
	l.TextTruncate = Enum.TextTruncate.AtEnd
	l.Text = text
	l.Parent = parent
	return l
end

local gui = Instance.new("SurfaceGui")
gui.Name = "TopEarners"
gui.Face = Enum.NormalId.Front
gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
gui.CanvasSize = Vector2.new(W, H)
gui.LightInfluence = 0
gui.MaxDistance = 300
gui.ResetOnSpawn = false
gui.Adornee = screen

local bg = Instance.new("Frame")
bg.Size = UDim2.fromScale(1, 1)
bg.BackgroundColor3 = Color3.fromRGB(10, 14, 12)
bg.BorderSizePixel = 0
bg.Parent = gui

-- the header
label(bg, "WORLDWIDE  /  HALL OF FAME", BOLD, GOLD, 0, 16, W, 16)
label(bg, "TOP EARNERS", BOLD, WHITE, 0, 38, W, 50)
label(bg, "MONEY / SEC", BOLD, GREEN, 0, 94, W, 18)
local rule = Instance.new("Frame")
rule.Position = UDim2.fromOffset(24, 122)
rule.Size = UDim2.fromOffset(W - 48, 2)
rule.BackgroundColor3 = GOLD
rule.BackgroundTransparency = 0.4
rule.BorderSizePixel = 0
rule.Parent = bg

-- the list
local list = Instance.new("ScrollingFrame")
list.Position = UDim2.fromOffset(14, 130)
list.Size = UDim2.fromOffset(W - 28, 408)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 6
list.ScrollBarImageColor3 = GOLD
list.CanvasSize = UDim2.new()
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.Parent = bg
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = list

local function row(rank, entry)
	local id, name, display, gold = entry[1], entry[2], entry[3], entry[4]
	local f = Instance.new("Frame")
	f.LayoutOrder = rank
	f.Size = UDim2.new(1, -12, 0, ROW)
	f.BackgroundColor3 = Color3.fromRGB(20, 34, 26)
	f.BorderSizePixel = 0
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = f
	local rw = W - 40
	label(f, tostring(rank), BOLD, WHITE, 6, 18, 34, 22)
	local face = Instance.new("ImageLabel")
	face.Position = UDim2.fromOffset(44, 5)
	face.Size = UDim2.fromOffset(48, 48)
	face.BackgroundColor3 = Color3.fromRGB(40, 56, 46)
	face.BorderSizePixel = 0
	face.Image = "rbxthumb://type=AvatarHeadShot&id=" .. id .. "&w=150&h=150"
	face.Parent = f
	label(f, display, BOLD, WHITE, 102, 8, rw - 102 - 150, 24, Enum.TextXAlignment.Left)
	label(f, "@" .. name, SEMI, GREY, 102, 34, rw - 102 - 150, 15, Enum.TextXAlignment.Left)
	label(f, money(gold), BOLD, GREEN, rw - 150, 8, 140, 26, Enum.TextXAlignment.Right)
	label(f, "/ SECOND", BOLD, GREY, rw - 150, 36, 140, 12, Enum.TextXAlignment.Right)
	f.Parent = list
end

-- the footer: your pen, the refresh countdown
local foot = Instance.new("Frame")
foot.Position = UDim2.fromOffset(0, 544)
foot.Size = UDim2.fromOffset(W, H - 544)
foot.BackgroundColor3 = Color3.fromRGB(4, 6, 5)
foot.BorderSizePixel = 0
foot.Parent = bg
local mine = label(foot, "", BOLD, GOLD, 0, 14, W, 20)
local countdown = label(foot, "", SEMI, WHITE, 0, 44, W, 15)
label(foot, "PEN INCOME  •  LATEST RECORDED", SEMI, GREY, 0, 68, W, 13)

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

gui.Parent = player:WaitForChild("PlayerGui")

while true do
	mine.Text = "YOUR PEN  " .. money(tonumber(player:GetAttribute("PenIncome")) or 0) .. "/s"
	local left = math.max(0, math.ceil((value:GetAttribute("Next") or 0) - workspace:GetServerTimeNow()))
	countdown.Text = "GLOBAL  •  Refresh in " .. left .. "s"
	task.wait(1)
end
