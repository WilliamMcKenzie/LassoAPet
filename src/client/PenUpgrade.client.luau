-- A board on the front of your own pen's fence that buys its next level
-- (UpgradePen): Config.Biomes[n].UpgradeImage, with the price drawn on it. It
-- hangs on the outside of the fence beside the gate, spanning two bays, and
-- presses in when clicked or tapped. Only you see it, and it's gone once
-- there's no next level. Flashes red if you can't afford it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)

local player = Players.LocalPlayer
local upgrade = ReplicatedStorage:WaitForChild("UpgradePen")
local RED = Color3.fromRGB(255, 110, 100)
local ASPECT = 1162 / 606 -- UpgradePenDesert.png
local THICK = 0.4
local PRESS = 0.25 -- studs the board pushes in when pressed
local PIXELS_PER_STUD = 60

local board = Instance.new("Part")
board.Name = "UpgradeBoard"
board.Anchored = true
board.CanCollide = false
board.CanTouch = false
board.CastShadow = false
board.Material = Enum.Material.SmoothPlastic
board.Color = Color3.fromRGB(40, 30, 20)

local gui = Instance.new("SurfaceGui")
gui.Name = "PenUpgrade"
gui.Face = Enum.NormalId.Front
gui.LightInfluence = 0
gui.MaxDistance = 90
gui.ResetOnSpawn = false
gui.Adornee = board

local button = Instance.new("ImageButton")
button.Size = UDim2.fromScale(1, 1)
button.BackgroundTransparency = 1
button.AutoButtonColor = false
button.Parent = gui

-- Text on the board until a level has its own picture.
local label = Instance.new("TextLabel")
label.Size = UDim2.fromScale(1, 1)
label.BackgroundColor3 = Color3.fromRGB(255, 196, 30)
label.Font = Enum.Font.FredokaOne
label.TextScaled = true
label.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UIStroke", label).Thickness = 4
label.Parent = button

gui.Parent = player:WaitForChild("PlayerGui")

local function myPen()
	local index = player:GetAttribute("Pen")
	return index and workspace:WaitForChild("Pens"):FindFirstChild("Pen" .. index)
end

-- Where the board hangs: on the outside of the pen's front fence (the side its
-- Spawn is on), centred on the second post left of the gate, as wide as the two
-- bays either side of that post. Returns the board's CFrame (Front facing out) and size.
local function mount(pen)
	local spawn, area = pen:FindFirstChild("Spawn"), pen:FindFirstChild("Area")
	if not (spawn and area) then
		return nil
	end
	local out = (spawn.Position - area.Position) * Vector3.new(1, 0, 1)
	out = out.Unit
	local side = out:Cross(Vector3.yAxis) -- along the fence
	local posts = {}
	local front = -math.huge
	for _, part in pen:GetChildren() do
		if part.Name == "Post" and part:IsA("BasePart") then
			front = math.max(front, (part.Position - spawn.Position):Dot(out))
			table.insert(posts, part)
		end
	end
	-- The front fence's posts: those nearest the spawn along `out`.
	local row = {}
	for _, post in posts do
		if math.abs((post.Position - spawn.Position):Dot(out) - front) < 0.5 then
			local along = (post.Position - spawn.Position):Dot(side)
			if along < 0 then
				table.insert(row, { post = post, along = along })
			end
		end
	end
	table.sort(row, function(a, b)
		return a.along > b.along -- nearest the gate first
	end)
	if #row < 3 then
		return nil
	end
	local centre, post = row[2].post.Position, row[2].post
	local width = (row[1].along - row[3].along) - post.Size.X
	local height = math.min(width / ASPECT, post.Size.Y * 1.4)
	width = height * ASPECT
	local depth = post.Size.Z / 2 + THICK / 2
	local at = Vector3.new(centre.X, post.Position.Y - post.Size.Y / 2 + height / 2 + 0.2, centre.Z) + out * depth
	return CFrame.lookAt(at, at + out), Vector3.new(width, height, THICK)
end

local rest -- the board's CFrame when not pressed

local function refresh()
	local pen = myPen()
	local nextBiome = Config.Biomes[(player:GetAttribute("PenLevel") or 1) + 1]
	local cframe, size
	if pen and nextBiome and nextBiome.UnlockCost then
		cframe, size = mount(pen)
	end
	if not (Config.ShowHud and cframe) then
		rest = nil
		board.Parent = nil
		gui.Enabled = false
		return
	end
	rest = cframe
	board.Size = size
	board.CFrame = cframe
	gui.CanvasSize = Vector2.new(size.X, size.Y) * PIXELS_PER_STUD
	button.Image = nextBiome.UpgradeImage or ""
	label.Visible = button.Image == ""
	label.Text = "UPGRADE PEN " .. nextBiome.UnlockCost .. "$"
	board.Parent = workspace
	gui.Enabled = true
end

local busy = false
button.Activated:Connect(function()
	if busy or not rest then
		return
	end
	busy = true
	local press = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local pressed = rest * CFrame.new(0, 0, PRESS) -- Front is -Z: +Z pushes it into the fence
	TweenService:Create(board, press, { CFrame = pressed }):Play()
	local ok, bought = pcall(upgrade.InvokeServer, upgrade)
	if not (ok and bought) then
		button.ImageColor3 = RED
		label.BackgroundColor3 = RED
		task.wait(0.4)
		button.ImageColor3 = Color3.new(1, 1, 1)
		label.BackgroundColor3 = Color3.fromRGB(255, 196, 30)
	end
	if rest then
		TweenService:Create(board, TweenInfo.new(0.15, Enum.EasingStyle.Back), { CFrame = rest }):Play()
	end
	busy = false
end)

player:GetAttributeChangedSignal("Pen"):Connect(refresh)
player:GetAttributeChangedSignal("PenLevel"):Connect(refresh)
refresh()
