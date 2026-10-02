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

-- The owner's picture and name floating over the pen's open side, like the
-- base owners in Roblox pet games. Hidden while the pen is free.
local function setSign(pen, player)
	local sign = pen:FindFirstChild("Sign")
	if not sign then
		return
	end
	local gui = sign:FindFirstChild("Owner")
	if not gui then
		gui = Instance.new("BillboardGui")
		gui.Name = "Owner"
		gui.Size = UDim2.fromScale(12, 6)
		gui.MaxDistance = 250
		gui.LightInfluence = 0
		local picture = Instance.new("ImageLabel")
		picture.Name = "Picture"
		picture.AnchorPoint = Vector2.new(0.5, 0)
		picture.Position = UDim2.fromScale(0.5, 0)
		picture.Size = UDim2.fromScale(0.6, 0.6)
		picture.SizeConstraint = Enum.SizeConstraint.RelativeYY
		picture.BackgroundColor3 = Color3.new(1, 1, 1)
		Instance.new("UICorner", picture).CornerRadius = UDim.new(0.5, 0)
		local ring = Instance.new("UIStroke")
		ring.Thickness = 3
		ring.Parent = picture
		picture.Parent = gui
		local label = Instance.new("TextLabel")
		label.Name = "OwnerName"
		label.Position = UDim2.fromScale(0, 0.64)
		label.Size = UDim2.fromScale(1, 0.36)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.FredokaOne
		label.TextScaled = true
		label.TextColor3 = Color3.new(1, 1, 1)
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 3
		stroke.Parent = label
		label.Parent = gui
		gui.Parent = sign
	end
	gui.Enabled = player ~= nil
	if player then
		gui.OwnerName.Text = player.DisplayName
		gui.Picture.Image = ""
		task.spawn(function()
			local ok, image = pcall(Players.GetUserThumbnailAsync, Players, player.UserId,
				Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
			if ok and pen:GetAttribute("Owner") == player.UserId then
				gui.Picture.Image = image
			end
		end)
	end
end

local function penOf(player)
	local index = player:GetAttribute("Pen")
	return index and pens[index]
end

local SPAWN_BACK = 10 -- QM's spawn view

local function toPen(player, character)
	local pen = penOf(player)
	local spawn = pen and pen:FindFirstChild("Spawn")
	if spawn then
		character:WaitForChild("HumanoidRootPart")
		task.wait() -- let the default spawn finish placing the character first
		-- Facing into the pen (Pen.client puts the camera behind you).
		-- SPAWN_BACK studs further out than the Spawn part, so the pen's in view.
		local at = spawn.Position + Vector3.new(0, 3, 0)
		local area = pen:FindFirstChild("Area")
		local ahead = if area then Vector3.new(area.Position.X, at.Y, area.Position.Z) else at + Vector3.zAxis
		at -= (ahead - at).Unit * SPAWN_BACK
		character:PivotTo(CFrame.lookAt(at, ahead))
	end
end

local function claim(player)
	for i, pen in pens do
		if pen:GetAttribute("Owner") == nil then
			pen:SetAttribute("Owner", player.UserId)
			player:SetAttribute("Pen", i)
			setSign(pen, player)
			return
		end
	end
end

local function release(player)
	local pen = penOf(player)
	if pen and pen:GetAttribute("Owner") == player.UserId then
		pen:SetAttribute("Owner", nil)
		setSign(pen, nil)
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
	setSign(pen, nil)
end
Players.PlayerAdded:Connect(onJoin)
Players.PlayerRemoving:Connect(release)
for _, player in Players:GetPlayers() do
	task.spawn(onJoin, player)
end
