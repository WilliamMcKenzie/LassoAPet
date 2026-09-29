-- Minimal riding HUD: Hold bar, distance, one action button, a center message.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Hud = {}

local FONT = Enum.Font.FredokaOne
local gui, holdFrame, holdFill, distance, action, message, rideAgain

local function label(parent, size, position, textSize)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.AnchorPoint = Vector2.new(0.5, 0.5)
	l.Size = size
	l.Position = position
	l.Font = FONT
	l.TextSize = textSize
	l.TextColor3 = Color3.new(1, 1, 1)
	l.Text = ""
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Transparency = 0.4
	stroke.Parent = l
	l.Parent = parent
	return l
end

local function round(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = radius or UDim.new(1, 0)
	c.Parent = parent
end

function Hud.init(onAction, onRideAgain)
	gui = Instance.new("ScreenGui")
	gui.Name = "RideHud"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Enabled = false
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	holdFrame = Instance.new("Frame")
	holdFrame.AnchorPoint = Vector2.new(0.5, 0)
	holdFrame.Position = UDim2.new(0.5, 0, 0, 56)
	holdFrame.Size = UDim2.fromOffset(240, 12)
	holdFrame.BackgroundColor3 = Color3.new(0, 0, 0)
	holdFrame.BackgroundTransparency = 0.6
	round(holdFrame)
	holdFrame.Parent = gui
	holdFill = Instance.new("Frame")
	holdFill.Size = UDim2.fromScale(1, 1)
	holdFill.BackgroundColor3 = Color3.new(1, 1, 1)
	round(holdFill)
	holdFill.Parent = holdFrame

	distance = label(gui, UDim2.fromOffset(240, 30), UDim2.new(0.5, 0, 0, 90), 22)
	message = label(gui, UDim2.fromOffset(600, 80), UDim2.fromScale(0.5, 0.3), 56)

	action = Instance.new("TextButton")
	action.Name = "Action"
	action.AnchorPoint = Vector2.new(1, 1)
	action.Position = UDim2.new(1, -40, 1, -40)
	action.Size = UDim2.fromOffset(130, 130)
	action.BackgroundColor3 = Color3.fromRGB(255, 196, 64)
	action.Font = FONT
	action.TextSize = 24
	action.TextColor3 = Color3.new(1, 1, 1)
	action.TextWrapped = true
	action.AutoButtonColor = false
	round(action)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 4
	stroke.Color = Color3.new(1, 1, 1)
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = action
	action.Parent = gui
	action.Activated:Connect(onAction)

	rideAgain = Instance.new("TextButton")
	rideAgain.Name = "RideAgain"
	rideAgain.AnchorPoint = Vector2.new(0.5, 0.5)
	rideAgain.Position = UDim2.fromScale(0.5, 0.48)
	rideAgain.Size = UDim2.fromOffset(240, 64)
	rideAgain.BackgroundColor3 = Color3.fromRGB(96, 200, 90)
	rideAgain.Font = FONT
	rideAgain.TextSize = 30
	rideAgain.TextColor3 = Color3.new(1, 1, 1)
	rideAgain.Text = "RIDE AGAIN"
	rideAgain.Visible = false
	round(rideAgain, UDim.new(0, 16))
	rideAgain.Parent = gui
	rideAgain.Activated:Connect(onRideAgain)
end

function Hud.show(visible)
	gui.Enabled = visible
	if not visible then
		message.Text = ""
		rideAgain.Visible = false
	end
end

function Hud.setHold(fraction)
	holdFrame.Visible = fraction ~= nil
	if fraction then
		holdFill.Size = UDim2.fromScale(math.clamp(fraction, 0, 1), 1)
		holdFill.BackgroundColor3 = fraction < 0.3 and Color3.fromRGB(255, 90, 80) or Color3.new(1, 1, 1)
	end
end

function Hud.setDistance(text)
	distance.Text = text
end

-- text = nil hides the button; ready = false dims it.
function Hud.setAction(text, ready)
	action.Visible = text ~= nil
	action.Text = text or ""
	action.BackgroundTransparency = ready and 0 or 0.6
	action.TextTransparency = ready and 0 or 0.4
end

function Hud.flash(text, seconds)
	message.Text = text
	message.TextTransparency = 0
	message.Size = UDim2.fromOffset(500, 70)
	TweenService:Create(message, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Size = UDim2.fromOffset(600, 80) }):Play()
	if seconds then
		task.delay(seconds, function()
			if message.Text == text then
				TweenService:Create(message, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
			end
		end)
	end
end

function Hud.showRideAgain(visible)
	rideAgain.Visible = visible
end

return Hud
