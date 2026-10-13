-- The Rebirth confirmation (QM, Oct 13: his panel): the full Rebirth bar (World2Bar, World
-- 2) opens it. As the Starter Pack popup: the world behind hazy, every other bit of UI gone,
-- the X on its top right corner. QM's panel says what a rebirth gives (2x gold, bigger
-- pets, their skins) and takes (all your pets, all your gold, back to World 1); Confirm
-- rebirths you (Gold.server's Rebirth).
--
--   RebirthMenu.open()
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Config = require(ReplicatedStorage.Shared.Config)
local ModalPop = require(script.Parent.ModalPop)

local RebirthMenu = {}

local REFERENCE_WIDTH = 1320 -- Hud's: sizes below are pixels on a screen this wide
local CLOSE = "rbxassetid://84920756991403" -- dex/IndexClose.png (the Worlds menu's X)
local ART = { -- assets/ui/rebirth (QM's)
	panel = "rbxassetid://95624233682694", -- Panel.png (1230x778, shrunk to 1024x648 by the upload): its title over the top, what you gain and lose
	confirm = "rbxassetid://118605133730785", -- Confirm.png (399x116)
}
local PANEL = Vector2.new(800, 800 * 778 / 1230) -- the art, title and all
local TOP = 800 * 38 / 1230 -- the panel's top edge, under the title
local CONFIRM = Vector2.new(256, 256 * 116 / 399)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local open = false

local function pressable(button)
	local scale = Instance.new("UIScale")
	scale.Parent = button
	local press = TweenInfo.new(0.08)
	button.MouseButton1Down:Connect(function()
		TweenService:Create(scale, press, { Scale = 0.95 }):Play()
	end)
	for _, event in { button.MouseButton1Up, button.MouseLeave } do
		event:Connect(function()
			TweenService:Create(scale, press, { Scale = 1 }):Play()
		end)
	end
end

local gui = Instance.new("ScreenGui")
gui.Name = "RebirthMenu"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = -1 -- (as the other menus)
gui.Enabled = false
local root = Instance.new("Frame")
root.BackgroundTransparency = 1
root.AnchorPoint = Vector2.new(0.5, 0.5)
root.Position = UDim2.fromScale(0.5, 0.5)
local rootScale = Instance.new("UIScale")
rootScale.Parent = root
local function resize()
	local screen = camera.ViewportSize
	rootScale.Scale = screen.X / REFERENCE_WIDTH * Config.HudScale
	root.Size = UDim2.fromOffset(screen.X / rootScale.Scale, screen.Y / rootScale.Scale)
end
camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
resize()
root.Parent = gui

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(PANEL.X, PANEL.Y)
panel.BackgroundTransparency = 1
local art = Instance.new("ImageLabel")
art.Name = "Art"
art.BackgroundTransparency = 1
art.Image = ART.panel
art.Size = UDim2.fromScale(1, 1)
art.ZIndex = 0
art.Parent = panel
local panelScale = Instance.new("UIScale")
panelScale.Parent = panel
panel.Parent = root


local closeButton = Instance.new("ImageButton")
closeButton.Name = "Close"
closeButton.BackgroundTransparency = 1
closeButton.AutoButtonColor = false
closeButton.Image = CLOSE
closeButton.AnchorPoint = Vector2.new(0.5, 0.5)
closeButton.Position = UDim2.new(1, -5, 0, TOP + 6)
closeButton.Size = UDim2.fromOffset(71, 71)
closeButton.ZIndex = 4
pressable(closeButton)
closeButton.Parent = panel

-- QM's Confirm button, near the bottom.
local confirm = Instance.new("ImageButton")
confirm.Name = "Confirm"
confirm.BackgroundTransparency = 1
confirm.AutoButtonColor = false
confirm.Image = ART.confirm
confirm.AnchorPoint = Vector2.new(0.5, 0.5)
confirm.Position = UDim2.new(0.5, 0, 0.84, 0)
confirm.Size = UDim2.fromOffset(CONFIRM.X, CONFIRM.Y)
confirm.ZIndex = 3
pressable(confirm)
confirm.Parent = panel
gui.Parent = player:WaitForChild("PlayerGui")

-- The world behind hazy (as the Worlds menu's).
local HAZE = { blur = 14, brightness = 0.06, contrast = -0.15, saturation = -0.35 }
local blur = Instance.new("BlurEffect")
blur.Name = "RebirthHaze"
blur.Size = 0
blur.Enabled = false
blur.Parent = camera
local tint = Instance.new("ColorCorrectionEffect")
tint.Name = "RebirthHaze"
tint.Enabled = false
tint.Parent = camera
local hazeTween = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local function haze(on)
	local k = if on then 1 else 0
	blur.Enabled, tint.Enabled = true, true
	TweenService:Create(blur, hazeTween, { Size = HAZE.blur * k }):Play()
	local t = TweenService:Create(tint, hazeTween, { Brightness = HAZE.brightness * k, Contrast = HAZE.contrast * k, Saturation = HAZE.saturation * k })
	t.Completed:Connect(function()
		if not open then
			blur.Enabled, tint.Enabled = false, false
		end
	end)
	t:Play()
end

-- Every other bit of UI goes while it's up (as the Worlds menu).
local hidden, holdHidden = {}, nil
local function hideOthers(on)
	if holdHidden then
		holdHidden:Disconnect()
		holdHidden = nil
	end
	if on then
		player:SetAttribute("Cutscene", true) -- (BaseUi and the guides keep themselves off)
		local function hideAll()
			for _, g in player.PlayerGui:GetChildren() do
				if g:IsA("ScreenGui") and g.Enabled and g ~= gui then
					g.Enabled = false
					if not table.find(hidden, g) then
						table.insert(hidden, g)
					end
				end
			end
		end
		hideAll()
		holdHidden = RunService.RenderStepped:Connect(hideAll)
	else
		for _, g in hidden do
			g.Enabled = true
		end
		table.clear(hidden)
		player:SetAttribute("Cutscene", nil)
	end
end

local function setScale(scale)
	panelScale.Scale = scale
end

function RebirthMenu.open()
	if open then
		return
	end
	open = true
	hideOthers(true)
	gui.Enabled = true
	haze(true)
	ModalPop.open(setScale)
end

local function close()
	if not open then
		return
	end
	open = false
	hideOthers(false)
	haze(false)
	ModalPop.close(setScale, function()
		gui.Enabled = false
	end)
end
closeButton.Activated:Connect(close)
local asking = false
confirm.Activated:Connect(function()
	if asking then
		return
	end
	asking = true
	local ok, done = pcall(ReplicatedStorage.Rebirth.InvokeServer, ReplicatedStorage.Rebirth)
	asking = false
	if not (ok and done) then
		close() -- (not enough gold any more, or mid-trip: nothing happens)
	end
	-- (done: the trip to World 1 takes them off with the panel up)
end)

return RebirthMenu
