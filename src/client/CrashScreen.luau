-- Crash overlay: the world and death camera stay visible behind the supplied art.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Config = require(ReplicatedStorage.Shared.Config)
local Gamepad = require(script.Parent.Gamepad)
local player = Players.LocalPlayer
local CrashScreen = {}
local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn, gui.IgnoreGuiInset = "CrashScreen", false, true
gui.DisplayOrder, gui.Enabled = 40, false
gui.Parent = if Config.ShowHud then player:WaitForChild("PlayerGui") else nil
local root = Instance.new("Frame")
root.Name, root.BackgroundTransparency, root.Size = "Root", 1, UDim2.fromScale(1, 1)
root.Parent = gui
local scale = Instance.new("UIScale", root)
local function resize()
	local size = workspace.CurrentCamera.ViewportSize
	scale.Scale = math.min(size.X / 1320, size.Y / 800) * Config.HudScale
	root.Size = UDim2.fromOffset(size.X / scale.Scale, size.Y / scale.Scale)
end
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
resize()
local function art(parent, name, id, w, h, x, y, button)
	local image = Instance.new(if button then "ImageButton" else "ImageLabel")
	image.Name, image.Image, image.BackgroundTransparency = name, id, 1
	image.AnchorPoint = Vector2.new(0.5, 0.5)
	image.Size, image.Position = UDim2.fromOffset(w, h), UDim2.fromScale(x, y)
	if button then
		image.AutoButtonColor = false
	end
	image.Parent = parent
	return image
end
local title = art(root, "YouCrashed", "rbxassetid://107816753420921", 400, 78, 0.5, 0.35)
local controls = Instance.new("Frame")
controls.Name, controls.BackgroundTransparency = "Controls", 1
controls.AnchorPoint, controls.Position = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.77)
controls.Size = UDim2.fromOffset(470, 158)
controls.Parent = root
local controlsScale = Instance.new("UIScale", controls)
local revive = art(controls, "Revive", "rbxassetid://127715475489628", 214, 73, 0, 0, true)
revive.Position = UDim2.fromOffset(112, 38)
local invincible = art(controls, "Invincible", "rbxassetid://102985018399551", 236, 73, 0, 0, true)
invincible.Position = UDim2.fromOffset(349, 38)
local continue = art(controls, "Continue", "rbxassetid://122061064731565", 258, 72, 0, 0, true)
continue.Position = UDim2.fromOffset(235, 120)
local onRevive, onContinue
local waiting, canRevive = false, false
local tweens, hidden = {}, {}
local run, holdHidden, previousCutscene = 0, nil, nil
local function tween(object, seconds, style, direction, properties)
	local t = TweenService:Create(object, TweenInfo.new(seconds, style, direction), properties)
	table.insert(tweens, t)
	t:Play()
	return t
end
local function refresh()
	revive.Visible = canRevive
	revive.Active, revive.Selectable = canRevive and not waiting, canRevive and not waiting
	revive.ImageTransparency = if waiting then 0.5 else 0
	continue.Active, continue.Selectable = not waiting, not waiting
	continue.ImageTransparency = if waiting then 0.5 else 0
	local owned = player:GetAttribute("PassInvincible") == true
	invincible.Visible = not owned
	invincible.Active, invincible.Selectable = not owned and not waiting, not owned and not waiting
	invincible.ImageTransparency = if waiting then 0.5 else 0
	revive.Position = UDim2.fromOffset(if owned then 235 else 112, 38)
	invincible.Position = UDim2.fromOffset(if canRevive then 349 else 235, 38)
end
player:GetAttributeChangedSignal("PassInvincible"):Connect(refresh)
function CrashScreen.init(reviveAction, continueAction)
	onRevive, onContinue = reviveAction, continueAction
end
revive.Activated:Connect(function()
	if gui.Enabled and not waiting and onRevive then
		onRevive()
	end
end)
continue.Activated:Connect(function()
	if gui.Enabled and not waiting and onContinue then
		onContinue()
	end
end)
invincible.Activated:Connect(function()
	if gui.Enabled and not waiting then
		ReplicatedStorage:WaitForChild("BuyPass"):FireServer("Invincible", "crash")
	end
end)
for _, button in { revive, invincible, continue } do
	local press = Instance.new("UIScale", button)
	button.MouseButton1Down:Connect(function()
		tween(press, 0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Scale = 0.95 })
	end)
	for _, event in { button.MouseButton1Up, button.MouseLeave } do
		event:Connect(function()
			tween(press, 0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Scale = 1 })
		end)
	end
end
function CrashScreen.setWaiting(value)
	waiting = value
	refresh()
end
function CrashScreen.hide()
	run += 1
	for _, t in tweens do
		t:Cancel()
	end
	table.clear(tweens)
	if holdHidden then
		holdHidden:Disconnect()
		holdHidden = nil
	end
	if gui.Enabled then
		player:SetAttribute("Cutscene", previousCutscene)
		for g in hidden do
			if g.Parent then
				g.Enabled = true
			end
		end
		table.clear(hidden)
	end
	gui.Enabled = false
	Gamepad.closeMenu("CrashScreen")
end
function CrashScreen.show(allowRevive)
	CrashScreen.hide()
	canRevive, waiting = allowRevive, false
	refresh()
	previousCutscene = player:GetAttribute("Cutscene")
	player:SetAttribute("Cutscene", true)
	local function hideAll()
		for _, g in player.PlayerGui:GetChildren() do
			if g:IsA("ScreenGui") and g ~= gui and g.Enabled then
				hidden[g] = true
				g.Enabled = false
			end
		end
	end
	hideAll()
	holdHidden = RunService.RenderStepped:Connect(hideAll)
	gui.Enabled = true
	local token = run
	title.Size, title.Rotation, title.ImageTransparency = UDim2.fromOffset(220, 100), -6, 1
	controls.Visible = false
	controlsScale.Scale = 0.85
	-- Stretch into the entrance, squash at the overshoot, rebound, then settle.
	task.spawn(function()
		tween(
			title,
			0.13,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out,
			{ Size = UDim2.fromOffset(452, 62), Rotation = 2, ImageTransparency = 0 }
		).Completed:Wait()
		if token ~= run then
			return
		end
		controls.Visible = true
		local telemetry = ReplicatedStorage:FindFirstChild("Telemetry")
		if telemetry then
			if revive.Visible then telemetry:FireServer("monoView", "revive") end
			if invincible.Visible then telemetry:FireServer("monoView", "crashInvincible") end
		end
		Gamepad.openMenu("CrashScreen", {
			close = function()
				if not waiting and onContinue then
					onContinue()
				end
			end,
			group = controls,
			select = function()
				return if canRevive then revive else continue
			end,
		})
		tween(controlsScale, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out, { Scale = 1 })
		tween(
			title,
			0.13,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out,
			{ Size = UDim2.fromOffset(380, 86), Rotation = -1 }
		).Completed:Wait()
		if token ~= run then
			return
		end
		tween(
			title,
			0.22,
			Enum.EasingStyle.Back,
			Enum.EasingDirection.Out,
			{ Size = UDim2.fromOffset(400, 78), Rotation = 0 }
		)
	end)
end
return CrashScreen
