-- World 1's World 2 bar (QM, Oct 13): top centre of the base HUD till you own World 2,
-- QM's grey track (World2BarEmpty.png) filling left to right with his green one
-- (World2Bar.png: the cash, "WORLD 2") as your gold comes up to World 2's price, the gold
-- over it ("$12m/10m"). Full: the tap hand pulses on it, the Worlds menu pops up (its X closes
-- it), and clicking the bar buys World 2 and plays the unlock cutscene (WorldUnlock). After that, till you go (GuideTravel): QM's big
-- white arrow bobbing over the portal gate and the arrow trail on the ground to it.
-- In World 2 it's the Rebirth bar (QM, Oct 13), in the same place: QM's RebirthBar art
-- filling to your next rebirth's price (Config.Rebirth). Full, the tap hand; a tap opens
-- QM's Rebirth panel (RebirthMenu): Confirm rebirths you (Gold.server's Rebirth). Gone
-- after the last.
-- One bar for every world (QM, Oct 15): it fills to the next world you don't have, in whichever
-- world you're in (World 2, then World 3: Config.WorldPrices), and once they're all yours to the
-- next trail (Config.TrailBars: Grey ... Rainbow; Gold.server's BuyTrail). The label's on QM's
-- art with its "WORLD 2" painted out (BarFill.png, BarEmpty.png).
-- In your pen with eggs still hatching it's QM's Hatch All button instead (Nov 2; Config.HatchAll,
-- Shop.server's "HatchAll"): every egg there hatched for R$99.
-- In the Halloween world (Config.Gems, QM Oct 15) it's the "+5s TIME" bar instead: QM's art
-- (gems/BossTimeBar.png on BossTimeBarDisabled.png) filling as your gems come up to the next
-- 5 seconds' price, the gems over it in their yellow; tapped when full, it buys them
-- (Gold.server's BuyBossTime): BossStep more seconds on every ride's boss timer.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Config = require(ReplicatedStorage.Shared.Config)
local REBIRTH = Config.World ~= 1 and Config.RebirthOn -- (off: no bar outside World 1, QM Oct 15)
local GEMS = Config.Gems ~= nil -- (the Halloween world's "+5s TIME" bar)
local player = Players.LocalPlayer
local Hud = require(script.Parent.Hud)
local TapHand = require(script.Parent.TapHand)
local ArrowTrail = require(script.Parent.ArrowTrail)
local Focus = require(script.Parent.Focus)
local WorldUnlock = require(script.Parent.WorldUnlock)

local REFERENCE_WIDTH = 1320 -- Hud's: sizes below are pixels on a screen this wide
local FULL = if GEMS then "rbxassetid://111546355637207" elseif REBIRTH then "rbxassetid://73306793972865" else "rbxassetid://100062651101544" -- assets/ui/RebirthBar.png, BarFill.png (964x103; QM's World2Bar.png, its label painted out)
local EMPTY = if GEMS then "rbxassetid://106586945972314" elseif REBIRTH then "rbxassetid://88891851849945" else "rbxassetid://105502035787337" -- assets/ui/RebirthBarEmpty.png, BarEmpty.png
-- QM's own art for a world's bar, its name on it (no label over it): [world] = { full, empty }
local WORLD_ART = {
	[2] = { "rbxassetid://108726643390976", "rbxassetid://108345016053649" }, -- World2Bar.png, World2BarEmpty.png
	[3] = { "rbxassetid://114072165271854", "rbxassetid://134941502651415" }, -- World3Bar.png, World3BarEmpty.png (QM, Oct 15)
}
local TRAIL_ART = { "rbxassetid://96598497238200", "rbxassetid://130130177164969" } -- TrailBar.png, TrailBarEmpty.png (QM's, "TRAIL" on them; the colour's name goes before it)
local BAR = Vector2.new(660, 660 * 103 / 964) -- (half the screen across: QM's mockup)
local TOP = 14 -- px from the screen's top (QM, Oct 13: was at the bottom, over the egg inventory)
local HATCH_ALL = "rbxassetid://95664942496836" -- assets/ui/HatchAll.png (QM's, same size as the bar)
local ARROW = "rbxassetid://127821178410489" -- assets/ui/TutorialArrow.png
local NEAR = 30 -- studs from the gate: the Worlds menu's (no trail closer in)
-- What the bar's for now: { price, label, world or trail }, or nil when there's nothing left.
local function goal()
	if GEMS then
		return { price = Config.bossTimePrice(player:GetAttribute("BossTime") or 0), label = "", gems = true }
	end
	if REBIRTH then
		local p = Config.Rebirth.Prices[(player:GetAttribute("Rebirths") or 0) + 1]
		return p and { price = p, label = "" }
	end
	for world = 2, #Config.Places do
		if not player:GetAttribute("OwnsWorld" .. world) and Config.WorldPrices[world] and not Config.WorldProducts[world] then -- (Robux worlds: the Worlds menu's)
			return { price = Config.WorldPrices[world], label = "WORLD " .. world, world = world }
		end
	end
	local i = Config.nextTrail(player)
	return i and { price = Config.TrailBars[i].Price, label = string.upper(Config.TrailBars[i].Name), trail = i }
end
local function price()
	local g = goal()
	return g and g.price
end
local MONTSERRAT = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.ExtraBold)

local camera = workspace.CurrentCamera

local gui = Instance.new("ScreenGui")
if Config.NativeUi.On then
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling -- (the native UI's layers sit over their parents, as in Fight to Steal an Egg)
end
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
text.TextColor3 = if GEMS then Config.GemYellow else Color3.fromHex("00FF09") -- (the cash green, as the HUD's gold: QM, Oct 13; gems' yellow)
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
-- What it's for, right of the gold, as QM's art had "WORLD 2".
local label = Instance.new("TextLabel")
label.Name = "Label"
label.BackgroundTransparency = 1
label.FontFace = MONTSERRAT
label.TextScaled = true
label.TextColor3 = Color3.new(1, 1, 1)
label.TextXAlignment = Enum.TextXAlignment.Right
label.AnchorPoint = Vector2.new(1, 0.5)
label.Position = UDim2.fromScale(0.815, 0.53) -- (just left of the art's "TRAIL", its height: QM, Oct 15, it was too small)
label.Size = UDim2.fromScale(0.35, 0.56)
label.ZIndex = 3
local labelStroke = Instance.new("UIStroke")
labelStroke.Thickness = 3
labelStroke.LineJoinMode = Enum.LineJoinMode.Round
labelStroke.Parent = label
label.Parent = bar
local hand = TapHand.new(70)
-- (No spotlight or Force box any more: QM, Oct 14, it made players quit. And no Worlds menu
-- popping up on a full bar either, nor its reminder: QM, Oct 15, bad UX; the tap hand guides.)
hand:SetAttribute("Focus", Focus.P.BuyWorld2) -- (one goal at a time: Client/Focus)
hand:SetAttribute("FocusGoal", "buyWorld2")
hand.Position = UDim2.fromScale(0.84, 0.6)
hand.Visible = false
hand.Parent = bar
local hatchAll = Instance.new("ImageButton")
hatchAll.Name = "HatchAll"
hatchAll.AutoButtonColor = false
hatchAll.BackgroundTransparency = 1
hatchAll.Image = HATCH_ALL
hatchAll.AnchorPoint = bar.AnchorPoint
hatchAll.Visible = false
hatchAll.Parent = root
hatchAll.Activated:Connect(function()
	ReplicatedStorage.BuyShop:FireServer("HatchAll", "pen") -- (Roblox's prompt; hatched once it's paid)
end)
-- The native UI's look (Config.NativeUi, QM Nov 6): the bar is the Goal panel's (a dark slate
-- track, the lime fill over it, studs and bevel) with what it's for written on it, and Hatch All
-- a yellow button with its Robux price, in place of the art.
local HudKit = if Config.NativeUi.On then require(script.Parent.HudKit) else nil
if HudKit then
	bar.Image, green.Image = "", ""
	HudKit.back(bar, "GoalTrack", { Name = "NativeTrack", ZIndex = 1 })
	green.Size = UDim2.fromOffset(BAR.X, BAR.Y)
	HudKit.back(green, "TopFill", { Name = "NativeFill", ZIndex = 2 })
	fill.ZIndex = 2
	for _, l in { text, label } do
		l.FontFace = HudKit.FONT
		l.ZIndex = 4
	end
	text.Position, text.Size = UDim2.fromScale(0.04, 0.5), UDim2.fromScale(0.48, 0.55)
	label.Position, label.Size = UDim2.fromScale(0.96, 0.5), UDim2.fromScale(0.45, 0.55)
	hatchAll.Image = ""
	HudKit.back(hatchAll, "Yellow", { Name = "NativeBack", ZIndex = 1 })
	local hatchText = HudKit.label(hatchAll, "Text", {
		Text = "Hatch All  R$" .. Config.HatchAll.Price,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextScaled = true,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.9, 0.6),
		ZIndex = 3,
	})
	task.spawn(function()
		local MarketplaceService = game:GetService("MarketplaceService")
		local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, Config.HatchAll.ProductId, Enum.InfoType.Product)
		if ok and info and info.PriceInRobux then
			hatchText.Text = "Hatch All  R$" .. info.PriceInRobux
		end
	end)
end
gui.Parent = player:WaitForChild("PlayerGui")

local CURRENCY = if GEMS then "Gems" else "Gold"
local function full()
	return price() ~= nil and (player:GetAttribute(CURRENCY) or 0) >= price()
end
local function showGold()
	local gold = player:GetAttribute(CURRENCY) or 0
	local p = price() or math.huge
	fill.Size = UDim2.fromScale(math.clamp(gold / p, 0, 1), 1)
	text.Text = (if GEMS then "" else "$") .. Config.short(gold) .. "/" .. Config.short(p)
	local g = goal()
	local art = g and (if g.world then WORLD_ART[g.world] elseif g.trail then TRAIL_ART else nil)
	label.Text = if g and g.trail then g.label else ""
	green.Image = if art then art[1] else FULL
	bar.Image = if art then art[2] else EMPTY
	if HudKit then -- (no art: what it's for written on)
		green.Image, bar.Image = "", ""
		label.Text = if g then (if g.trail then g.label .. " TRAIL" else g.label) else ""
	end
	hand.Visible = full()
end
for _, name in { "Gold", "Gems", "BossTime", "Rebirths", "OwnsWorld2", "OwnsWorld3", "TrailsOwned", "FinishTrail", "RainbowTrail" } do
	player:GetAttributeChangedSignal(name):Connect(showGold)
end
showGold()

bar.Activated:Connect(function()
	local g = goal()
	if not g then
		return
	elseif not full() then
		if g.world or g.trail then
			require(script.Parent.Shop).buyGoldFor(g.price - (player:GetAttribute("Gold") or 0))
		end
		return
	elseif g.gems then
		pcall(ReplicatedStorage.BuyBossTime.InvokeServer, ReplicatedStorage.BuyBossTime)
	elseif g.world then
		WorldUnlock.buy(g.world)
	elseif g.trail then
		pcall(ReplicatedStorage.BuyTrail.InvokeServer, ReplicatedStorage.BuyTrail)
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

local gate = nil -- (looked for without holding the bar up: not every world's base has one)
task.spawn(function()
	gate = workspace:WaitForChild("World"):WaitForChild("BaseDecor"):WaitForChild("PortalGate", 30)
end)
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
	hatchAll.Size, hatchAll.Position = bar.Size, bar.Position
end

-- Standing in your own pen (its Area, a few studs' grace).
local function inPen()
	local index = player:GetAttribute("Pen")
	local pens = workspace:FindFirstChild("Pens")
	local pen = index and pens and pens:FindFirstChild("Pen" .. index)
	local area = pen and pen:FindFirstChild("Area")
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not area or not area:IsA("BasePart") or not hrp then
		return false
	end
	local at = area.CFrame:PointToObjectSpace(hrp.Position)
	return math.abs(at.X) <= area.Size.X / 2 + 4 and math.abs(at.Z) <= area.Size.Z / 2 + 4
end

RunService.RenderStepped:Connect(function()
	align()
	local owned = player:GetAttribute("OwnsWorld2") == true
	local busy = Hud.isRiding() or player:GetAttribute("Cutscene") or player:GetAttribute("Tutorial")
	local menu = player.PlayerGui:FindFirstChild("WorldsMenu")
	local hatching = not busy and (player:GetAttribute("PenHatchLast") or 0) > workspace:GetServerTimeNow() and inPen()
	hatchAll.Visible = hatching
	bar.Visible = not hatching
	gui.Enabled = (price() ~= nil or hatching) and not busy and not (menu and menu.Enabled) -- (not under the Worlds menu; in every world: QM, Oct 15)
	if REBIRTH or GEMS then
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
