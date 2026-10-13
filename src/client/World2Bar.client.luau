-- World 1's World 2 bar (QM, Oct 13): top centre of the base HUD till you own World 2,
-- QM's grey track (World2BarEmpty.png) filling left to right with his green one
-- (World2Bar.png: the cash, "WORLD 2") as your gold comes up to World 2's price, the gold
-- over it ("$12m/10m"). Full: the tap hand pulses on it, and clicking it buys World 2 and
-- plays the unlock cutscene (WorldUnlock). After that, till you go (GuideTravel): QM's big
-- white arrow bobbing over the portal gate and the arrow trail on the ground to it.
-- In World 2 it's the Rebirth bar (QM, Oct 13), in the same place: QM's RebirthBar art
-- filling to your next rebirth's price (Config.Rebirth). Full, the tap hand; a tap opens
-- QM's Rebirth panel (RebirthMenu): Confirm rebirths you (Gold.server's Rebirth). Gone
-- after the last.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Config = require(ReplicatedStorage.Shared.Config)
local REBIRTH = Config.World ~= 1
local player = Players.LocalPlayer
local Hud = require(script.Parent.Hud)
local TapHand = require(script.Parent.TapHand)
local ArrowTrail = require(script.Parent.ArrowTrail)
local Focus = require(script.Parent.Focus)
local WorldUnlock = require(script.Parent.WorldUnlock)

local REFERENCE_WIDTH = 1320 -- Hud's: sizes below are pixels on a screen this wide
local FULL = if REBIRTH then "rbxassetid://73306793972865" else "rbxassetid://108726643390976" -- assets/ui/RebirthBar.png, World2Bar.png (964x103; QM's thinner one, Oct 13)
local EMPTY = if REBIRTH then "rbxassetid://88891851849945" else "rbxassetid://108345016053649" -- assets/ui/RebirthBarEmpty.png, World2BarEmpty.png
local BAR = Vector2.new(660, 660 * 103 / 964) -- (half the screen across: QM's mockup)
local TOP = 14 -- px from the screen's top (QM, Oct 13: was at the bottom, over the egg inventory)
local ARROW = "rbxassetid://127821178410489" -- assets/ui/TutorialArrow.png
local NEAR = 30 -- studs from the gate: the Worlds menu's (no trail closer in)
local function price()
	return if REBIRTH then Config.Rebirth.Prices[(player:GetAttribute("Rebirths") or 0) + 1] else Config.WorldPrices[2]
end
local MONTSERRAT = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.ExtraBold)

local camera = workspace.CurrentCamera

local gui = Instance.new("ScreenGui")
gui.Name = "World2Bar"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = -1
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

local bar = Instance.new("ImageButton")
bar.Name = "Bar"
bar.AutoButtonColor = false
bar.BackgroundTransparency = 1
bar.Image = EMPTY
bar.AnchorPoint = Vector2.new(0.5, 0)
bar.Position = UDim2.new(0.5, 0, 0, TOP)
bar.Size = UDim2.fromOffset(BAR.X, BAR.Y)
bar.Parent = root
local fill = Instance.new("Frame") -- (clips the green art to the gold so far)
fill.Name = "Fill"
fill.BackgroundTransparency = 1
fill.ClipsDescendants = true
fill.Size = UDim2.fromScale(0, 1)
fill.Parent = bar
local green = Instance.new("ImageLabel")
green.BackgroundTransparency = 1
green.Image = FULL
green.Size = UDim2.fromOffset(BAR.X, BAR.Y)
green.Parent = fill
-- The gold, between the cash and "WORLD 2".
local text = Instance.new("TextLabel")
text.Name = "Gold"
text.BackgroundTransparency = 1
text.FontFace = MONTSERRAT
text.TextScaled = true
text.TextColor3 = Color3.fromHex("00FF09") -- (the cash green, as the HUD's gold: QM, Oct 13)
text.TextXAlignment = Enum.TextXAlignment.Left
text.AnchorPoint = Vector2.new(0, 0.5)
text.Position = UDim2.fromScale(0.145, 0.5)
text.Size = UDim2.fromScale(0.3, 0.42) -- (QM's Oct 13 art: its label sits right, the gold has the middle)
text.ZIndex = 3
local stroke = Instance.new("UIStroke")
stroke.Thickness = 2.5
stroke.LineJoinMode = Enum.LineJoinMode.Round
stroke.Parent = text
text.Parent = bar
local hand = TapHand.new(70)
hand:SetAttribute("Spotlight", not REBIRTH) -- (buying World 2 here: in the spotlight, QM Oct 13)
hand:SetAttribute("Focus", Focus.P.BuyWorld2) -- (one goal at a time: Client/Focus)
hand:SetAttribute("FocusGoal", "buyWorld2")
hand.Position = UDim2.fromScale(0.84, 0.6)
hand.Visible = false
hand.Parent = bar
gui.Parent = player:WaitForChild("PlayerGui")

local function full()
	return price() ~= nil and (player:GetAttribute("Gold") or 0) >= price()
end
local function showGold()
	local gold = player:GetAttribute("Gold") or 0
	local p = price() or math.huge
	fill.Size = UDim2.fromScale(math.clamp(gold / p, 0, 1), 1)
	text.Text = "$" .. Config.short(gold) .. "/" .. Config.short(p)
	hand.Visible = full()
end
player:GetAttributeChangedSignal("Gold"):Connect(showGold)
player:GetAttributeChangedSignal("Rebirths"):Connect(showGold)
showGold()

bar.Activated:Connect(function()
	if not full() then
		return
	end
	if not REBIRTH then
		WorldUnlock.buy(2)
	else
		require(script.Parent.RebirthMenu).open() -- (QM's panel: what you gain and lose, Confirm)
	end
end)

-- The arrow over the gate.
local arrow = Instance.new("BillboardGui")
arrow.Name = "World2GateArrow"
arrow.Size = UDim2.fromScale(9, 9)
arrow.AlwaysOnTop = true
arrow.LightInfluence = 0
arrow.ResetOnSpawn = false
arrow.Enabled = false
local arrowImage = Instance.new("ImageLabel")
arrowImage.BackgroundTransparency = 1
arrowImage.Image = ARROW
arrowImage.Size = UDim2.fromScale(1, 1)
arrowImage.Parent = arrow
arrow.Parent = player.PlayerGui
local trail = ArrowTrail.new()

local gate = if REBIRTH then nil else workspace:WaitForChild("World"):WaitForChild("BaseDecor"):WaitForChild("PortalGate", 30)
-- In line with the Quests panel, as tall as it is folded (QM, Oct 13): its top and its
-- header's height (BaseUi's 86, at BaseUi's scale).
local QUESTS_HEADER = 86
local GROW = 1.2 -- (the art's panel is smaller than its picture, round the cash: 20% up to look as tall, QM)
local function align()
	local base = player.PlayerGui:FindFirstChild("BaseUi")
	local baseRoot = base and base:FindFirstChild("Root")
	local quests = baseRoot and baseRoot:FindFirstChild("Quests")
	local baseScale = baseRoot and baseRoot:FindFirstChildOfClass("UIScale")
	if not quests or not baseScale then
		return
	end
	local questsScale = quests:FindFirstChildOfClass("UIScale")
	local header = QUESTS_HEADER * (questsScale and questsScale.Scale or 1) * baseScale.Scale / rootScale.Scale
	local tall = header * GROW
	local size = Vector2.new(tall * BAR.X / BAR.Y, tall)
	bar.Size = UDim2.fromOffset(size.X, size.Y)
	green.Size = bar.Size
	bar.Position = UDim2.new(0.5, 0, 0, (quests.AbsolutePosition.Y - root.AbsolutePosition.Y) / rootScale.Scale - (tall - header) / 2) -- (centred on it)
end

RunService.RenderStepped:Connect(function()
	align()
	local owned = player:GetAttribute("OwnsWorld2") == true
	local busy = Hud.isRiding() or player:GetAttribute("Cutscene") or player:GetAttribute("Tutorial")
	local menu = player.PlayerGui:FindFirstChild("WorldsMenu")
	gui.Enabled = (REBIRTH or not owned) and price() ~= nil and not busy and not (menu and menu.Enabled) -- (not under the Worlds menu)
	if REBIRTH then
		return
	end
	local guide = owned and player:GetAttribute("GuideTravel") and not busy and gate ~= nil
	Focus.want("travelGuide", guide == true, Focus.P.Travel, "travel")
	guide = guide and Focus.has("travelGuide") -- (one goal at a time)
	arrow.Enabled = guide == true
	if not guide then
		trail.draw()
		return
	end
	local base = gate.PrimaryPart or gate:FindFirstChildWhichIsA("BasePart", true)
	local top = gate:GetPivot().Position + Vector3.new(0, 30 * gate:GetScale() / 1.6 + 6, 0) -- (over the arch: 17 + 7.2 up at scale 1)
	arrow.Adornee = base
	arrow.StudsOffsetWorldSpace = top - (if base then base.Position else top) + Vector3.new(0, math.abs(math.sin(os.clock() * 3)) * 2, 0)
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local to = gate:GetPivot().Position
	if hrp and Vector2.new(hrp.Position.X - to.X, hrp.Position.Z - to.Z).Magnitude > NEAR then
		local from = Vector3.new(hrp.Position.X, 0, hrp.Position.Z)
		local along = (Vector3.new(to.X, 0, to.Z) - from).Unit
		from += along * 3
		trail.draw(Vector3.new(from.X, 1.4, from.Z), Vector3.new(to.X, 1.4, to.Z) - along * 12)
	else
		trail.draw()
	end
end)
