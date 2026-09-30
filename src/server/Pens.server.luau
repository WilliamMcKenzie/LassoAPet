-- Five pens (src/world/Pens.rbxmx, Workspace.Pens), one per player: a player
-- gets the lowest free pen on joining and it's freed when they leave. The pen
-- is theirs only while they're online. Its number goes on the player as the
-- "Pen" attribute (the ride reads it), its owner's UserId on the pen as "Owner".
-- Players past the fifth get no pen and spawn at the base's SpawnLocation.

local Players = game:GetService("Players")

local folder = workspace:WaitForChild("Pens")
local pens = {}
for i = 1, 5 do
	pens[i] = folder:WaitForChild("Pen" .. i)
end

-- The owner's name on both faces of the pen's name board.
local function setSign(pen, text)
	local sign = pen:FindFirstChild("Sign")
	if not sign then
		return
	end
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local name = "OwnerName" .. face.Name
		local gui = sign:FindFirstChild(name)
		if not gui then
			gui = Instance.new("SurfaceGui")
			gui.Name = name
			gui.Face = face
			gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
			gui.PixelsPerStud = 50
			local label = Instance.new("TextLabel")
			label.Size = UDim2.fromScale(1, 1)
			label.BackgroundTransparency = 1
			label.Font = Enum.Font.FredokaOne
			label.TextScaled = true
			label.TextColor3 = Color3.new(1, 1, 1)
			local stroke = Instance.new("UIStroke")
			stroke.Thickness = 6
			stroke.Parent = label
			local pad = Instance.new("UIPadding") -- room for the outline, so long names aren't clipped
			pad.PaddingTop = UDim.new(0.18, 0)
			pad.PaddingBottom = UDim.new(0.18, 0)
			pad.PaddingLeft = UDim.new(0.08, 0)
			pad.PaddingRight = UDim.new(0.08, 0)
			pad.Parent = label
			label.Parent = gui
			gui.Parent = sign
		end
		gui.TextLabel.Text = text
	end
end

local function penOf(player)
	local index = player:GetAttribute("Pen")
	return index and pens[index]
end

local function toPen(player, character)
	local pen = penOf(player)
	local spawn = pen and pen:FindFirstChild("Spawn")
	if spawn then
		character:WaitForChild("HumanoidRootPart")
		task.wait() -- let the default spawn finish placing the character first
		character:PivotTo(CFrame.new(spawn.Position + Vector3.new(0, 3, 0)))
	end
end

local function claim(player)
	for i, pen in pens do
		if pen:GetAttribute("Owner") == nil then
			pen:SetAttribute("Owner", player.UserId)
			player:SetAttribute("Pen", i)
			setSign(pen, player.DisplayName)
			return
		end
	end
end

local function release(player)
	local pen = penOf(player)
	if pen and pen:GetAttribute("Owner") == player.UserId then
		pen:SetAttribute("Owner", nil)
		setSign(pen, "")
	end
end

local function onJoin(player)
	claim(player)
	player.CharacterAdded:Connect(function(character)
		toPen(player, character)
	end)
	if player.Character then
		task.spawn(toPen, player, player.Character)
	end
end

for _, pen in pens do
	setSign(pen, "")
end
Players.PlayerAdded:Connect(onJoin)
Players.PlayerRemoving:Connect(release)
for _, player in Players:GetPlayers() do
	task.spawn(onJoin, player)
end
