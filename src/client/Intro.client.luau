-- The intro (QM, Oct 11): a new player's first moments, before the tutorial. You're
-- asleep by your pen, a beautiful Phoenix egg glowing in it; the villain rides in on a
-- huge Loong, lassoes the egg away and rides off down the course with it. You wake up
-- furious (red in the face, an anger mark), and the goal's set: ride as far as you can
-- to catch him. (The story never has to finish: it's just the hook.)
--
-- Plays whenever the "Tutorial" attribute turns on (Hatchery.server: a new player, or
-- "/tutorial" to see it again). Everything in it is this client's own and goes when
-- it ends; the rest of the UI hides meanwhile and the controls are off.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Egg = require(ReplicatedStorage.Shared.Eggs.Egg)
local Sounds = require(script.Parent.Sounds)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local EGG = "Phoenix" -- the egg he steals
local MOUNT = "Loong" -- what he rides
local MOUNT_SCALE = 1.6 -- x its own size: huge
local EGG_SCALE = 1.5
local VEIN = "rbxassetid://85408798859805" -- assets/ui/boss/AngerMarkOutlined.png (the boss's anger mark)
local FONT = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.ExtraBold)
local VILLAIN_COLOR = Color3.fromRGB(34, 30, 44)
local ANGRY_RED = Color3.fromRGB(235, 60, 50)
local LINES = { "Your egg was stolen!", "Ride as far as you can to catch him!" }

local function ease(t)
	return t * t * (3 - 2 * t)
end

local function myPen()
	local index = player:GetAttribute("Pen")
	return index and workspace:FindFirstChild("Pens") and workspace.Pens:FindFirstChild("Pen" .. index)
end

-- Runs step(t, dt) every frame for `duration` seconds.
local function play(duration, step)
	local t = 0
	while t < duration do
		local dt = RunService.RenderStepped:Wait()
		t = math.min(t + dt, duration)
		step(t / duration, dt)
	end
end

-- The villain: you, in shadow (your own avatar, darkened, with glowing red eyes).
local function makeVillain(character)
	local was = character.Archivable
	character.Archivable = true
	local villain = character:Clone()
	character.Archivable = was
	villain.Name = "Villain"
	for _, d in villain:GetDescendants() do
		if d:IsA("LuaSourceContainer") or d:IsA("Accessory") or d:IsA("Clothing") or d:IsA("ShirtGraphic") or d:IsA("ForceField") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide, d.CanQuery, d.CanTouch = false, false, false
			d.Color = VILLAIN_COLOR
			if d:IsA("MeshPart") then
				d.TextureID = ""
			end
		elseif d:IsA("Decal") and d.Name == "face" then
			d.Transparency = 1
		end
	end
	local humanoid = villain:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		humanoid.PlatformStand = true
	end
	local head = villain:FindFirstChild("Head")
	if head then
		for side = -1, 1, 2 do
			local eye = Instance.new("Part")
			eye.Name = "Eye"
			eye.Anchored, eye.CanCollide, eye.CanQuery, eye.CanTouch = true, false, false, false
			eye.Material = Enum.Material.Neon
			eye.Color = Color3.fromRGB(255, 40, 40)
			eye.Size = Vector3.new(0.22, 0.12, 0.05)
			eye.CFrame = head.CFrame * CFrame.new(side * 0.2, 0.15, -head.Size.Z / 2 - 0.01)
			eye.Parent = villain
		end
	end
	return villain
end

-- Moves a model, keeping its parts where they are relative to its root.
local function placeAt(model, cf)
	model:PivotTo(cf)
end

local playing = false

local function intro()
	if playing then
		return
	end
	playing = true
	task.wait(1.2) -- ("/tutorial" respawns you just after turning the tutorial on)
	local character = player.Character or player.CharacterAdded:Wait()
	local hrp = character:WaitForChild("HumanoidRootPart", 10)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local start = os.clock()
	while not myPen() and os.clock() - start < 10 do
		task.wait(0.2)
	end
	local pen = myPen()
	if not hrp or not humanoid or not pen or not pen:FindFirstChild("Area") then
		playing = false
		return
	end
	task.wait(0.4) -- (let the pen and character settle in)

	local area = pen.Area
	local floorY = area.Position.Y + area.Size.Y / 2
	local middle = Vector3.new(area.Position.X, floorY, area.Position.Z)
	local spawnPart = pen:FindFirstChild("Spawn")
	local out = if spawnPart then ((spawnPart.Position - middle) * Vector3.new(1, 0, 1)).Unit else Vector3.new(0, 0, -1)
	local side = out:Cross(Vector3.yAxis)
	local made = {} -- everything to clear away at the end

	-- Everything else on screen goes, and the controls stop, till it's over.
	local hidden = {}
	for _, g in player.PlayerGui:GetChildren() do
		if g:IsA("ScreenGui") and g.Enabled and g.Name ~= "PreloadWarm" and g.Name ~= "AnimalDexWarm" then
			g.Enabled = false
			table.insert(hidden, g)
		end
	end
	player:SetAttribute("Cutscene", true) -- (BaseUi keeps itself on every frame otherwise)
	-- (held off every frame: some of the HUD turns itself back on)
	local holdHidden = RunService.RenderStepped:Connect(function()
		for _, g in player.PlayerGui:GetChildren() do
			if g:IsA("ScreenGui") and g.Enabled and g.Name ~= "Intro" and g.Name ~= "PreloadWarm" and g.Name ~= "AnimalDexWarm" then
				g.Enabled = false
				if not table.find(hidden, g) then
					table.insert(hidden, g)
				end
			end
		end
	end)
	local controls
	pcall(function()
		controls = require(player.PlayerScripts:WaitForChild("PlayerModule")):GetControls()
		controls:Disable()
	end)
	local cameraType = camera.CameraType
	camera.CameraType = Enum.CameraType.Scriptable
	local fov = camera.FieldOfView

	local gui = Instance.new("ScreenGui")
	gui.Name = "Intro"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 60
	local function bar(anchorY)
		local f = Instance.new("Frame")
		f.BorderSizePixel = 0
		f.BackgroundColor3 = Color3.new(0, 0, 0)
		f.AnchorPoint = Vector2.new(0, anchorY)
		f.Size = UDim2.fromScale(1, 0.12)
		f.Position = UDim2.fromScale(0, anchorY)
		f.Parent = gui
		return f
	end
	bar(0)
	bar(1)
	local caption = Instance.new("TextLabel")
	caption.BackgroundTransparency = 1
	caption.FontFace = FONT
	caption.TextColor3 = Color3.new(1, 1, 1)
	caption.TextScaled = true
	caption.AnchorPoint = Vector2.new(0.5, 0.5)
	caption.Position = UDim2.fromScale(0.5, 0.8)
	caption.Size = UDim2.fromScale(0.8, 0.08)
	caption.TextTransparency = 1
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 4
	stroke.Transparency = 1
	stroke.Parent = caption
	caption.Parent = gui
	local fade = Instance.new("Frame")
	fade.BorderSizePixel = 0
	fade.BackgroundColor3 = Color3.new(0, 0, 0)
	fade.Size = UDim2.fromScale(1, 1)
	fade.BackgroundTransparency = 0
	fade.ZIndex = 5
	fade.Parent = gui
	gui.Parent = player.PlayerGui
	table.insert(made, gui)
	local function say(text)
		caption.Text = text
		TweenService:Create(caption, TweenInfo.new(0.3), { TextTransparency = 0 }):Play()
		TweenService:Create(stroke, TweenInfo.new(0.3), { Transparency = 0 }):Play()
	end
	local function unsay()
		TweenService:Create(caption, TweenInfo.new(0.25), { TextTransparency = 1 }):Play()
		TweenService:Create(stroke, TweenInfo.new(0.25), { Transparency = 1 }):Play()
	end

	-- 1. The Phoenix egg, glowing in the pen.
	local egg = Egg.new(EGG)
	egg.model:ScaleTo(egg.model:GetScale() * EGG_SCALE)
	Egg.fitStuds(egg.model)
	local eggSpot = middle + Vector3.new(0, 1.6 * egg.model:GetScale(), 0)
	egg.model:PivotTo(CFrame.new(eggSpot) * CFrame.Angles(0, math.atan2(-out.X, -out.Z), 0))
	egg.model.Parent = workspace
	table.insert(made, egg.model)
	local glow = Instance.new("PointLight")
	glow.Color = Color3.fromRGB(255, 160, 60)
	glow.Range = 18
	glow.Brightness = 2
	glow.Parent = egg.model.PrimaryPart
	local sparkle = Instance.new("ParticleEmitter")
	sparkle.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparkle.Color = ColorSequence.new(Color3.fromRGB(255, 210, 120))
	sparkle.Rate = 14
	sparkle.Lifetime = NumberRange.new(0.8, 1.4)
	sparkle.Speed = NumberRange.new(2, 4)
	sparkle.SpreadAngle = Vector2.new(180, 180)
	sparkle.Size = NumberSequence.new(0.6, 0)
	sparkle.LightEmission = 1
	sparkle.Parent = egg.model.PrimaryPart

	-- You, asleep on the grass just outside the pen, Zzz over your head.
	local sleepAt = middle + out * (area.Size.Z / 2 + 14) + side * 10 -- (clear of the fence and the pets)
	local wasAnchored = hrp.Anchored
	hrp.Anchored = true
	humanoid.PlatformStand = true
	local lying = CFrame.new(sleepAt + Vector3.new(0, 1, 0)) * CFrame.fromMatrix(Vector3.zero, side, out, Vector3.yAxis)
	hrp.CFrame = lying
	local zzz = Instance.new("BillboardGui")
	zzz.Size = UDim2.fromOffset(120, 60)
	zzz.StudsOffsetWorldSpace = Vector3.new(0, 3, 0)
	zzz.AlwaysOnTop = true
	zzz.Adornee = hrp
	local z = Instance.new("TextLabel")
	z.BackgroundTransparency = 1
	z.Size = UDim2.fromScale(1, 1)
	z.FontFace = FONT
	z.TextScaled = true
	z.TextColor3 = Color3.new(1, 1, 1)
	z.Text = "z Z z"
	Instance.new("UIStroke", z).Thickness = 3
	z.Parent = zzz
	zzz.Parent = gui
	table.insert(made, zzz)

	-- The opening shot: the egg, glowing, then you asleep beside the pen.
	local wide = CFrame.lookAt(middle + out * 40 + side * 26 + Vector3.new(0, 18, 0), middle + Vector3.new(0, 3, 0))
	camera.FieldOfView = 55
	camera.CFrame = CFrame.lookAt(eggSpot + out * 14 + Vector3.new(0, 4, 0), eggSpot)
	TweenService:Create(fade, TweenInfo.new(0.8), { BackgroundTransparency = 1 }):Play()
	local close = camera.CFrame
	play(2.4, function(u)
		camera.CFrame = close:Lerp(wide, ease(u))
		z.Rotation = math.sin(u * 8) * 6
	end)

	-- 2. The villain rides in on a huge Loong.
	local Mount = require(ReplicatedStorage.Shared.Animals[MOUNT])
	local mount = Mount.new()
	mount:setScale(MOUNT_SCALE)
	mount.model.Name = "VillainMount"
	mount.model.PrimaryPart.CFrame = CFrame.new()
	local box, size = mount.model:GetBoundingBox()
	local lift = mount.model.PrimaryPart.Position.Y - (box.Position.Y - size.Y / 2)
	mount.model.Parent = workspace
	table.insert(made, mount.model)
	local villain = makeVillain(character)
	villain.Parent = workspace
	table.insert(made, villain)
	local vRoot = villain:FindFirstChild("HumanoidRootPart")
	local function ride(at, facing, dt, speed)
		mount.model.PrimaryPart.CFrame = CFrame.lookAt(at + Vector3.new(0, lift, 0), at + Vector3.new(0, lift, 0) + facing)
		pcall(mount.update, mount, dt, speed, 0)
		if vRoot then
			placeAt(villain, mount:getSeatCFrame() * CFrame.new(0, 3, 0))
		end
	end
	local stopAt = middle + out * (area.Size.Z / 2 + 30) - side * 22
	local enterFrom = stopAt + out * 160 - side * 40
	Sounds.play("boss_LavaWyrm", 0.5)
	play(3.2, function(u, dt)
		local at = enterFrom:Lerp(stopAt, ease(math.min(u * 1.15, 1)))
		ride(at, (stopAt - enterFrom).Unit, dt, if u < 0.85 then 90 else 0)
		camera.CFrame = camera.CFrame:Lerp(CFrame.lookAt(middle + out * 60 + side * 40 + Vector3.new(0, 24, 0), at:Lerp(middle, 0.4) + Vector3.new(0, 6, 0)), 1 - math.exp(-4 * dt))
	end)

	-- 3. He lassoes the egg away.
	local hand = villain:FindFirstChild("RightHand") or villain:FindFirstChild("Right Arm") or vRoot
	local from = Instance.new("Attachment")
	from.Parent = hand
	local to = Instance.new("Attachment")
	to.Parent = egg.model.PrimaryPart
	local rope = Instance.new("Beam")
	rope.Attachment0, rope.Attachment1 = from, to
	rope.Color = ColorSequence.new(Color3.fromRGB(196, 150, 90))
	rope.Width0, rope.Width1 = 0.35, 0.35
	rope.FaceCamera = true
	rope.Segments = 12
	rope.CurveSize0 = 6
	rope.Parent = hand
	table.insert(made, rope)
	table.insert(made, from)
	Sounds.play("lasso_throw")
	local facing = (middle - stopAt) * Vector3.new(1, 0, 1)
	play(0.6, function(u, dt)
		rope.CurveSize0 = 6 * (1 - u)
		ride(stopAt, facing.Unit, dt, 0)
		camera.CFrame = camera.CFrame:Lerp(CFrame.lookAt(stopAt:Lerp(middle, 0.5) + out * 30 + side * 30 + Vector3.new(0, 20, 0), stopAt:Lerp(middle, 0.5) + Vector3.new(0, 4, 0)), 1 - math.exp(-5 * dt))
	end)
	Sounds.play("lasso_land")
	Sounds.play("egg_grab", 0.8)
	sparkle.Rate = 40
	local eggFrom = egg.model:GetPivot()
	play(0.9, function(u, dt)
		ride(stopAt, facing.Unit, dt, 0)
		local target = mount:getSeatCFrame().Position + Vector3.new(0, 5, 0) + facing.Unit * -3
		local p = eggFrom.Position:Lerp(target, ease(u)) + Vector3.new(0, math.sin(u * math.pi) * 14, 0)
		egg.model:PivotTo(CFrame.new(p) * eggFrom.Rotation * CFrame.Angles(0, u * 6, 0))
	end)
	rope:Destroy()

	-- 4. And rides off down the course with it.
	local leaveTo = stopAt + Vector3.new(0, 0, -700)
	local carry = function()
		egg.model:PivotTo(CFrame.new(mount:getSeatCFrame().Position + Vector3.new(0, 5, 0)) * eggFrom.Rotation)
	end
	play(2.6, function(u, dt)
		local k = u * u
		local at = stopAt:Lerp(leaveTo, k)
		ride(at, (leaveTo - stopAt).Unit, dt, 120)
		carry()
		camera.CFrame = camera.CFrame:Lerp(CFrame.lookAt(stopAt + out * 20 + Vector3.new(0, 16, 0), at + Vector3.new(0, 6, 0)), 1 - math.exp(-6 * dt))
	end)

	-- 5. You wake up furious.
	zzz:Destroy()
	-- (standing, facing out the way he went, the camera in front of your face)
	local stand = sleepAt + Vector3.new(0, 3, 0)
	hrp.CFrame = CFrame.lookAt(stand, stand + out)
	humanoid.PlatformStand = false
	local head = character:FindFirstChild("Head")
	local headWas = head and head.Color
	local face = head and head.CFrame
	if head then
		camera.CFrame = CFrame.lookAt(head.Position + out * 6 + Vector3.new(0, 0.8, 0), head.Position)
		camera.FieldOfView = 45
		TweenService:Create(head, TweenInfo.new(0.7), { Color = ANGRY_RED }):Play()
		-- Steam puffing out either side of your head.
		for sideSign = -1, 1, 2 do
			local a = Instance.new("Attachment")
			a.Position = Vector3.new(sideSign * head.Size.X * 0.6, head.Size.Y * 0.3, 0)
			a.Parent = head
			local steam = Instance.new("ParticleEmitter")
			steam.Texture = "rbxasset://textures/particles/smoke_main.dds"
			steam.Color = ColorSequence.new(Color3.new(1, 1, 1))
			steam.Transparency = NumberSequence.new(0.2, 1)
			steam.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 2.2) })
			steam.Lifetime = NumberRange.new(0.5, 0.8)
			steam.Speed = NumberRange.new(5, 8)
			steam.EmissionDirection = Enum.NormalId.Top
			steam.SpreadAngle = Vector2.new(25, 25)
			steam.Rate = 30
			steam.Parent = a
			table.insert(made, a)
		end
	end
	local vein = Instance.new("ImageLabel")
	vein.BackgroundTransparency = 1
	vein.Image = VEIN
	vein.AnchorPoint = Vector2.new(0.5, 0.5)
	vein.Position = UDim2.fromScale(0.6, 0.36)
	vein.Size = UDim2.fromScale(0.16, 0.16)
	vein.SizeConstraint = Enum.SizeConstraint.RelativeYY
	local veinScale = Instance.new("UIScale")
	veinScale.Scale = 0
	veinScale.Parent = vein
	vein.Parent = gui
	Sounds.play("boss_ElderBoar", 0.35)
	play(0.5, function(u)
		veinScale.Scale = 1 - math.exp(-12.6 * u * 0.5) * math.cos(26 * u * 0.5)
	end)
	say(LINES[1])
	play(1.6, function(u)
		veinScale.Scale = 1 + 0.15 * math.sin(u * math.pi * 4)
		vein.Rotation = u * 20
		if face then
			camera.CFrame = CFrame.lookAt(face.Position + out * (6 - u * 1.5) + Vector3.new(0, 0.8, 0), face.Position)
		end
	end)
	unsay()
	task.wait(0.3)
	say(LINES[2])
	task.wait(2.2)

	-- Back to the game.
	TweenService:Create(fade, TweenInfo.new(0.4), { BackgroundTransparency = 0 }):Play()
	task.wait(0.45)
	for _, thing in made do
		if thing and thing.Parent then
			thing:Destroy()
		end
	end
	if head and headWas then
		head.Color = headWas
	end
	hrp.Anchored = wasAnchored
	humanoid.PlatformStand = false
	camera.FieldOfView = fov
	camera.CameraType = cameraType
	if controls then
		controls:Enable()
	end
	holdHidden:Disconnect()
	player:SetAttribute("Cutscene", nil)
	for _, g in hidden do
		if g.Parent then
			g.Enabled = true
		end
	end
	playing = false
end

local function check()
	if Config.Intro ~= false and player:GetAttribute("Tutorial") == true then
		task.spawn(intro)
	end
end
player:GetAttributeChangedSignal("Tutorial"):Connect(check)
check()
