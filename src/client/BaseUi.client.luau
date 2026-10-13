-- The base's UI (QM, Oct 9: the new look, from QM's Figma), in place of the old home
-- HUD (Config.HomeHud off). Montserrat ExtraBold everywhere, white with a black stroke.
--   Left, centred top to bottom: Merge, Shop and Index, stacked (QM's art, label drawn in).
--   Bottom left: your cash (no more stamina over it: QM, Oct 10).
--   Top right, all the time at your base: Quests (QM, Oct 11, in place of Upgrade; QM's
--     art, Config.Quests): the two quests up, each its name, N/M and a bar, and CLAIM
--     once it's done. The header folds it up and out again. It steps aside while a menu
--     (Shop, Index, Roll, the merge view) is up, and so do PassPopups' cards.
-- All of it hides on a ride. Laid out on a Config.BaseUi.RefWidth-wide screen.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Hud = require(script.Parent.Hud)
local Shop = require(script.Parent.Shop)
local AnimalDex = require(script.Parent.AnimalDex)
local RollMenu = require(script.Parent.RollMenu)
local CameraHint = require(script.Parent.CameraHint)
local TapHand = require(script.Parent.TapHand)
local Inventory = require(script.Parent.Inventory)
local WorldColors = require(ReplicatedStorage.Shared.WorldColors)

local player = Players.LocalPlayer
local cfg = Config.BaseUi

local ART = { -- assets/ui/base_hud/*.png (QM, Oct 9)
	shop = { id = "rbxassetid://119060039201858", size = Vector2.new(267, 113) }, -- Shop.png
	index = { id = "rbxassetid://135845846149671", size = Vector2.new(267, 113) }, -- Index.png
	merge = { id = "rbxassetid://126251339270486", size = Vector2.new(267, 113) }, -- Merge.png
	invite = { id = "rbxassetid://72356826090260", size = Vector2.new(267, 113) }, -- Invite.png (QM, Oct 12)
	cash = { id = "rbxassetid://76663783463176", size = Vector2.new(256, 256) }, -- Cash.png
}
-- assets/ui/quests/*.png (QM, Oct 11). "" till Studio uploads them: plain boxes meanwhile.
local QUEST_ART = {
	top = "rbxassetid://120142364189594", -- QuestsTop.png, 453 x 90: Quests.png's header, "Quests" and its fold chevron
	middle = "rbxassetid://133997765094952", -- QuestsMiddle.png, 453 x 20: a strip of its body, stretched to fit the quests
	bottom = "rbxassetid://72901094417133", -- QuestsBottom.png, 453 x 40: its bottom edge
	-- (cut from Quests.png: a 9-slice drew its header at the art's own pixel size, not the
	-- panel's, so "Quests" came out huge and the chevron got cut: QM, Oct 11)
	panel = "rbxassetid://72181051059940", -- Quests.png, 453 x 265: open, "Quests" and its fold chevron drawn in
	closed = "rbxassetid://115847818752186", -- QuestsClosed.png, 453 x 85 (QM's QuestsHidden, Oct 11): folded up
	one = "rbxassetid://136367932806454", -- QuestsOne.png, 453 x 184: room for one quest, when one questline's done (QM, Oct 11; till it's uploaded, the pieces)
	bar = "rbxassetid://88826165672196", -- QuestBG.png, 407 x 22
	fill = "rbxassetid://76511917573203", -- QuestFill.png, 406 x 22 (QM's second, Oct 11)
	claim = "rbxassetid://113926447181781", -- ClaimQuest.png, 399 x 62
}
local FONT = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.ExtraBold)
local CASH_GREEN = Color3.fromHex("00FF09")
-- (in RefWidth pixels: QM's mockups at 1300 wide, x 1920 / 1300)
local MARGIN = 18
local MENU_WIDTH = 260 -- each of Merge, Index, Shop, Invite (QM's mockup, Oct 12: about 0.65 of the Quests panel's width; Oct 9 had 213)
local MENU_GAP = 12 -- (small even gaps: QM's mockup, Oct 12; was 20)
local ICON = 74 -- the counters' icons
local TEXT = 55 -- the counters' text (QM's Figma: 55, stroke 5)
local STROKE = 5
local QUESTS_WIDTH = 402 -- (QM's mockup's 365, 10% bigger: QM, Oct 11; the art's 453)

local gui = Instance.new("ScreenGui")
gui.Name = "BaseUi"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")
local root = Instance.new("Frame")
root.Name = "Root"
root.BackgroundTransparency = 1
root.Size = UDim2.fromScale(1, 1)
root.Parent = gui
local scale = Instance.new("UIScale")
scale.Parent = root
local function resize()
	local view = gui.AbsoluteSize
	scale.Scale = view.X / cfg.RefWidth * (Config.HudScale or 1)
	root.Size = UDim2.fromOffset(view.X / scale.Scale, view.Y / scale.Scale)
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
resize()

local function text(parent, size, color, strokeWidth)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.FontFace = FONT
	label.TextSize = size
	label.TextColor3 = color or Color3.new(1, 1, 1)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.AutomaticSize = Enum.AutomaticSize.X
	label.Size = UDim2.fromOffset(0, size)
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.new(0, 0, 0)
	stroke.Thickness = strokeWidth or STROKE
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = label
	label.Parent = parent
	return label
end

local function picture(class, parent, art, width)
	local p = Instance.new(class)
	p.BackgroundTransparency = 1
	p.Image = art.id
	p.Size = UDim2.fromOffset(width, width * art.size.Y / art.size.X)
	p.Parent = parent
	return p
end

-- A press squashes it a little.
local function pressable(button)
	local s = Instance.new("UIScale")
	s.Parent = button
	button.MouseButton1Down:Connect(function()
		s.Scale = 0.94
	end)
	for _, event in { button.MouseButton1Up, button.MouseLeave } do
		event:Connect(function()
			s.Scale = 1
		end)
	end
end

-- Roblox's invite, carrying your id so the friend's join counts toward "Invite a friend"
-- (Hatchery). From the Invite button and the quest.
local function promptInvite()
	task.spawn(function()
		local SocialService = game:GetService("SocialService")
		local okCan, can = pcall(SocialService.CanSendGameInviteAsync, SocialService, player)
		if okCan and can then
			local options = Instance.new("ExperienceInviteOptions")
			options.LaunchData = tostring(player.UserId)
			options.PromptMessage = "Ride with me!"
			pcall(SocialService.PromptGameInvite, SocialService, player, options)
		end
	end)
end

-- On the right, under Quests (QM, Oct 12; they were down the left): Merge, Index, Shop, Invite.
local menu = Instance.new("Frame")
menu.Name = "Menu"
menu.BackgroundTransparency = 1
menu.AutomaticSize = Enum.AutomaticSize.XY
menu.AnchorPoint = Vector2.new(1, 0) -- (under the Quests panel: placed every frame, below)
menu.Position = UDim2.new(1, -MARGIN, 0, MARGIN)
local list = Instance.new("UIListLayout")
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Padding = UDim.new(0, MENU_GAP)
list.HorizontalAlignment = Enum.HorizontalAlignment.Right
list.Parent = menu
menu.Parent = root
local mergeBadge -- QM's red "1" on Merge while the "Merge animals" quest is up and you've not merged yet (QM, Oct 11)
local mergeHinted = false -- (and the quest's tap hands, as tapping it, once as it comes up: QM)
for i, spec in { { "shop", function()
	if Shop.hasOffers() then
		Shop.toggle()
	end
end }, { "index", function()
	AnimalDex.toggle()
end }, { "merge", function()
	if Hud.onFuse then
		Hud.onFuse()
	end
end }, { "invite", promptInvite } } do
	local b = picture("ImageButton", menu, ART[spec[1]], MENU_WIDTH)
	b.Name = spec[1]
	b.LayoutOrder = ({ merge = 1, index = 2, shop = 3, invite = 4 })[spec[1]] -- (top to bottom: Merge, Index, Shop, Invite: QM's mockup, Oct 12)
	if ART[spec[1]].id == "" then -- (no art yet: a plain button with its name)
		b.BackgroundTransparency = 0
		b.BackgroundColor3 = Color3.fromRGB(76, 200, 92)
		Instance.new("UICorner", b).CornerRadius = UDim.new(0.2, 0)
		local label = text(b, 44)
		label.Text = "Invite"
		label.AutomaticSize = Enum.AutomaticSize.None
		label.TextXAlignment = Enum.TextXAlignment.Center
		label.Size = UDim2.fromScale(1, 1)
	end
	b:SetAttribute("Hover", 1.04) -- (ButtonHover: half its usual 1.08 grow, QM)
	b.Activated:Connect(spec[2])
	pressable(b)
	if spec[1] == "merge" then -- the "Merge animals" quest's hint: a tap hand on it (below)
		local hand = TapHand.new(80)
		hand.Name = "MergeHint"
		hand.Position = UDim2.fromScale(0.55, 0.7)
		hand.Visible = false
		hand.Parent = b
		local function show()
			hand.Visible = player:GetAttribute("MergeHint") == true and player:GetAttribute("MergeView") ~= true
		end
		player:GetAttributeChangedSignal("MergeHint"):Connect(show)
		player:GetAttributeChangedSignal("MergeView"):Connect(show)
		mergeBadge = Instance.new("ImageLabel")
		mergeBadge.Name = "QuestBadge"
		mergeBadge.Image = "rbxassetid://136773861994278" -- assets/ui/quests/QuestNotification.png (QM)
		mergeBadge.BackgroundTransparency = 1
		mergeBadge.AnchorPoint = Vector2.new(0.5, 0.5)
		mergeBadge.Position = UDim2.new(1, -8, 0, 8) -- (its top right corner, as QM's mockup)
		mergeBadge.Size = UDim2.fromOffset(36, 36)
		mergeBadge.ZIndex = 10
		mergeBadge.Visible = false
		mergeBadge.Parent = b
	end
end

-- Bottom left: cash, its icon with the number beside it.
local counters = Instance.new("Frame")
counters.Name = "Counters"
counters.BackgroundTransparency = 1
counters.AutomaticSize = Enum.AutomaticSize.XY
counters.AnchorPoint = Vector2.new(0, 1)
counters.Position = UDim2.new(0, MARGIN, 1, -MARGIN)
local stack = Instance.new("UIListLayout")
stack.SortOrder = Enum.SortOrder.LayoutOrder
stack.Padding = UDim.new(0, 6)
stack.Parent = counters
counters.Parent = root
local function counter(order, art, color)
	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.AutomaticSize = Enum.AutomaticSize.XY
	row.LayoutOrder = order
	local across = Instance.new("UIListLayout")
	across.FillDirection = Enum.FillDirection.Horizontal
	across.VerticalAlignment = Enum.VerticalAlignment.Center
	across.Padding = UDim.new(0, 10)
	across.Parent = row
	picture("ImageLabel", row, art, ICON)
	local label = text(row, TEXT, color)
	label.LayoutOrder = 1
	row.Parent = counters
	return label
end
local cashText = counter(1, ART.cash, CASH_GREEN)
local function showCounters()
	cashText.Text = Hud.money(player:GetAttribute("Gold") or 0) -- (no "+$N" pop: QM, Oct 12, tried and dropped)
end
player:GetAttributeChangedSignal("Gold"):Connect(showCounters)
showCounters()

-- Top right: Quests. Laid out in the art's own pixels, scaled down to QUESTS_WIDTH.
local claimQuest = ReplicatedStorage:WaitForChild("ClaimQuest")
local Q = { -- (art pixels)
	width = 453, header = 86, -- the folded art's height: the header's
	top = 92, -- the first quest's name
	-- (the quests 10% bigger, words and bars, the title kept: QM, Oct 11; the bars and CLAIM
	-- are as wide as the panel lets them be, so only taller)
	x = 23, bar = Vector2.new(407, 24), inset = 3, -- (the fill inside the bar)
	name = 29, nameStroke = 3,
	barAt = 40, claimAt = 70, claim = Vector2.new(399, 62),
	gap = 22, bottom = 24,
}
local quests = Instance.new("Frame")
quests.Name = "Quests"
quests.BackgroundTransparency = 1
-- The panel in three pieces, so it grows down with its quests: header, body, bottom.
local function piece(name, image, height)
	local p = Instance.new("ImageLabel")
	p.Name = name
	p.BackgroundTransparency = 1
	p.Image = image
	p.ScaleType = Enum.ScaleType.Stretch
	p.Size = UDim2.new(1, 0, 0, height)
	p.Parent = quests
	return p
end
local panelTop = piece("Top", QUEST_ART.top, 90)
local panelMiddle = piece("Middle", QUEST_ART.middle, 0)
panelMiddle.Position = UDim2.fromOffset(0, 90)
local panelBottom = piece("Bottom", QUEST_ART.bottom, 40)
panelBottom.AnchorPoint = Vector2.new(0, 1)
panelBottom.Position = UDim2.fromScale(0, 1)
local panelClosed = piece("Closed", QUEST_ART.closed, Q.header)
local panelOne = piece("One", QUEST_ART.one, 184)
quests.AnchorPoint = Vector2.new(1, 0)
quests.Position = UDim2.new(1, -MARGIN, 0, MARGIN)
quests.Size = UDim2.fromOffset(Q.width, Q.header)
quests.Visible = false
quests.Parent = root
local questsScale = Instance.new("UIScale")
questsScale.Scale = QUESTS_WIDTH / Q.width
questsScale.Parent = quests
local fold = Instance.new("TextButton") -- the header: folds it up and out again
fold.Name = "Fold"
fold.BackgroundTransparency = 1
fold.Text = ""
fold.Size = UDim2.fromOffset(Q.width, Q.header)
fold.ZIndex = 3
fold.Parent = quests
-- (folded to start with everywhere, its claim badge still showing: QM, Oct 13; it was only
-- on a phone or tablet, Oct 12, so the column under it cleared Roblox's jump button)
local folded = true
quests:SetAttribute("Folded", folded)
fold.Activated:Connect(function()
	folded = not folded
	quests:SetAttribute("Folded", folded) -- (draws again: below)
	local telemetry = not folded and ReplicatedStorage:FindFirstChild("Telemetry")
	if telemetry then
		telemetry:FireServer("questsOpened") -- (Analytics V1)
	end
end)

-- A new quest pops in (QM, Oct 11): from nothing, overshooting, a wobble, and settles
-- (anticipation, overshoot, follow-through), once the panel's up and no egg reveal's over
-- it. And QM's red badge on the panel while a quest's ready to claim, till you claim it
-- (QM, Oct 11: not just till you hover it).
local POP_TIME = 0.6
local pops = {} -- [quest i] = os.clock() it started popping, or false while it waits to
local seenQuests -- [quest i] = true: what's been up (nil till the first list: those don't pop)
local dot = Instance.new("ImageLabel")
dot.Name = "ClaimBadge"
local BADGES = {
	"rbxassetid://136773861994278", -- assets/ui/quests/QuestNotification.png, 48 x 48 (QM): "1"
	"rbxassetid://128175495014059", -- assets/ui/quests/QuestNotification2.png (QM): "2", two to claim
}
dot.Image = BADGES[1]
dot.BackgroundTransparency = 1
dot.AnchorPoint = Vector2.new(0.5, 0.5)
dot.Position = UDim2.fromOffset(10, 6) -- (on the panel's top left corner, as QM's mockup)
dot.Size = UDim2.fromOffset(48, 48)
dot.ZIndex = 10
dot.Visible = false
local claimable = {} -- [quest i] = true: ready to claim, as last drawn
local dotScale = Instance.new("UIScale")
dotScale.Parent = dot
dot.Parent = quests
local dotSince -- os.clock() it popped up
local function seen()
	dot.Visible, dotSince = false, nil
end
-- 0 to 1 over POP_TIME, overshooting to ~1.2 and settling.
local function popScale(t)
	local a = math.clamp(t / POP_TIME, 0, 1)
	return 1 - math.exp(-6 * a) * math.cos(10 * a)
end

-- Tapping a quest shows how to do it, where there's a hint (QM, Oct 11): "Reach ..."
-- flies the camera to that biome's barrier (as the tutorial's to the Desert's), as does
-- "Lasso Snowmen" to the barrier of the biome they run in,
-- "Collect animals" to the count over your pen, and "Merge animals" puts tap hands on
-- Merge, then on two animals and the merge (FuseMenu, by "MergeHint").
local function hint(quest)
	if (quest.kind == "reach" or quest.kind == "lasso") and tonumber(quest.biome) then
		task.spawn(CameraHint.show, Vector3.new(0, 10, WorldColors.biomeStart(quest.biome)), Vector3.new(0, 26, 80))
	elseif quest.kind == "home" then
		local index = player:GetAttribute("Pen")
		local pen = index and workspace:FindFirstChild("Pens") and workspace.Pens:FindFirstChild("Pen" .. index)
		local area = pen and pen:FindFirstChild("Area")
		if area then
			local look = area.Position + Vector3.new(0, Config.PenProfile.Height, 0)
			local ahead = workspace.CurrentCamera.CFrame.LookVector * Vector3.new(1, 0, 1)
			ahead = if ahead.Magnitude > 0.01 then ahead.Unit else Vector3.new(0, 0, -1)
			task.spawn(CameraHint.show, look, -ahead * 70 + Vector3.new(0, 12, 0))
		end
	elseif quest.kind == "merge" then
		player:SetAttribute("MergeHint", true)
	elseif quest.kind == "invite" then
		promptInvite()
	end
end

local claimPulses = {} -- [UIScale] = true: the CLAIM buttons up, pulsing (below)
RunService.RenderStepped:Connect(function()
	local s = 1 + 0.05 * math.sin(os.clock() * 5)
	for pulse in claimPulses do
		pulse.Scale = s
	end
end)

local claimBusy = false -- a claim's egg reveal is up: no other claim till it's over (QM, Oct 11)
local function questRow(i, quest, y)
	local done = quest.have >= quest.need
	local row = Instance.new("Frame")
	row.Name = "Quest"
	row.BackgroundTransparency = 1
	row.ZIndex = 2 -- (over the panel's pieces)
	row.Size = UDim2.fromOffset(Q.width, if done then Q.claim.Y else Q.barAt + Q.bar.Y)
	row.AnchorPoint = Vector2.new(0.5, 0.5) -- (its middle: a new one pops about it)
	row.Position = UDim2.fromOffset(Q.width / 2, y + row.Size.Y.Offset / 2)
	row:SetAttribute("Quest", i)
	if pops[i] ~= nil then
		local pop = Instance.new("UIScale")
		pop.Name = "Pop"
		pop.Scale = if pops[i] then popScale(os.clock() - pops[i]) else 0
		pop.Parent = row
	end
	-- (finished: its CLAIM button takes the quest's place, QM)
	if not done then
		local tap = Instance.new("TextButton") -- (the whole quest: its hint)
		tap.Name = "Hint"
		tap.BackgroundTransparency = 1
		tap.Text = ""
		tap.Size = UDim2.fromScale(1, 1)
		tap.ZIndex = 4
		tap.Activated:Connect(function()
			hint(quest)
		end)
		tap.Parent = row
	end
	local name = text(row, Q.name, nil, Q.nameStroke)
	name.Visible = not done
	name.Text = quest.text
	name.Position = UDim2.fromOffset(Q.x, 0)
	local count = text(row, Q.name, nil, Q.nameStroke)
	count.Text = string.format("%d/%d", quest.have, quest.need)
	count.AutomaticSize = Enum.AutomaticSize.None
	count.TextXAlignment = Enum.TextXAlignment.Right
	count.Position = UDim2.fromOffset(Q.x, 0)
	count.Size = UDim2.fromOffset(Q.bar.X, Q.name)
	count.Visible = not done
	local bar = Instance.new("ImageLabel")
	bar.Name = "Bar"
	bar.Image = QUEST_ART.bar
	bar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	bar.BackgroundTransparency = if QUEST_ART.bar == "" then 0 else 1
	bar.Position = UDim2.fromOffset(Q.x, Q.barAt)
	bar.Size = UDim2.fromOffset(Q.bar.X, Q.bar.Y)
	bar.Visible = not done
	bar.Parent = row
	local share = math.clamp(quest.have / quest.need, 0, 1)
	if share > 0 then
		-- The fill laid over the bar, full size, cropped to the share done (QM, Oct 11: as
		-- the other progress bars, the bar showing through the rest).
		local crop = Instance.new("Frame")
		crop.Name = "Crop"
		crop.BackgroundTransparency = 1
		crop.ClipsDescendants = true
		crop.Size = UDim2.fromScale(share, 1)
		crop.Parent = bar
		local fill = Instance.new("ImageLabel")
		fill.Name = "Fill"
		fill.Image = QUEST_ART.fill
		fill.BackgroundColor3 = Color3.fromRGB(59, 255, 95)
		fill.BackgroundTransparency = if QUEST_ART.fill == "" then 0 else 1
		fill.Size = UDim2.fromOffset(Q.bar.X, Q.bar.Y)
		fill.Parent = crop
	end
	if done then
		local claim = Instance.new("ImageButton")
		claim.Name = "Claim"
		claim.Image = QUEST_ART.claim
		claim.BackgroundColor3 = Color3.fromRGB(59, 255, 95)
		claim.BackgroundTransparency = if QUEST_ART.claim == "" then 0 else 1
		claim.Size = UDim2.fromScale(1, 1)
		claim:SetAttribute("Hover", 1.04)
		pressable(claim)
		if QUEST_ART.claim == "" then
			local label = text(claim, 34)
			label.Text = "CLAIM"
			label.AutomaticSize = Enum.AutomaticSize.None
			label.TextXAlignment = Enum.TextXAlignment.Center
			label.Size = UDim2.fromScale(1, 1)
		end
		claim.Activated:Connect(function()
			if claimBusy or Hud.revealing() then
				return
			end
			claimBusy = true
			-- (its egg stays out of the inventory till its reveal's over: QM, Oct 11)
			local line = Config.Quests[i // 100]
			local egg = line and line[i % 100] and line[i % 100].Egg
			local eggs = if typeof(egg) == "table" then egg else { egg } -- (some give several: World 2's last, QM Oct 13)
			for _, kind in eggs do
				Inventory.holdBack(kind, 1)
			end
			local ok, kind = pcall(claimQuest.InvokeServer, claimQuest, i)
			task.spawn(function()
				for _, each in if ok and kind then eggs else {} do
					local animal = ReplicatedStorage.Shared.Animals:FindFirstChild(each)
					if animal then
						Hud.eggReveal(require(animal).Rarity, each, true) -- (the egg it gave you)
						task.wait(0.2)
						while Hud.revealing() do
							task.wait(0.1)
						end
					end
				end
				for _, each in eggs do
					Inventory.holdBack(each, -1)
				end
				claimBusy = false
			end)
		end)
		-- (in a holder that pulses about its middle: QM, Oct 11; the button's own UIScale is its press)
		local holder = Instance.new("Frame")
		holder.Name = "ClaimPulse"
		holder.BackgroundTransparency = 1
		holder.AnchorPoint = Vector2.new(0.5, 0.5)
		holder.Position = UDim2.fromOffset(Q.width / 2, Q.claim.Y / 2)
		holder.Size = UDim2.fromOffset(Q.claim.X, Q.claim.Y)
		local pulse = Instance.new("UIScale")
		pulse.Parent = holder
		claimPulses[pulse] = true
		pulse.Destroying:Connect(function()
			claimPulses[pulse] = nil
		end)
		claim.Parent = holder
		holder.Parent = row
	end
	row.Parent = quests
	return row.Size.Y.Offset
end

local questList = {} -- what's up: { { i, text, have, need } } (Hatchery's "Quests")
local function drawQuests()
	local ok, list = pcall(HttpService.JSONDecode, HttpService, player:GetAttribute("Quests") or "[]")
	questList = if ok and typeof(list) == "table" then list else {}
	-- (new ones pop; the first list's don't, unless it's a new player's, after the tutorial)
	if #questList > 0 then
		local first = seenQuests == nil
		seenQuests = seenQuests or {}
		for _, quest in questList do
			local i = typeof(quest) == "table" and tonumber(quest.i)
			if i and not seenQuests[i] then
				seenQuests[i] = true
				if not first or player:GetAttribute("Tutorial") then
					pops[i] = false
				end
			end
		end
	end
	-- The badge: on as a quest becomes ready to claim, off once none is (all claimed).
	local now = {}
	for _, quest in questList do
		if typeof(quest) == "table" and tonumber(quest.i) and tonumber(quest.have) and tonumber(quest.need) and quest.have >= quest.need then
			now[quest.i] = true
			if not claimable[quest.i] then
				dot.Visible, dotSince = true, os.clock()
			end
		end
	end
	claimable = now
	local merging, mergeUp = false, false
	for _, quest in questList do
		mergeUp = mergeUp or (typeof(quest) == "table" and quest.kind == "merge")
		merging = merging or (typeof(quest) == "table" and quest.kind == "merge" and (tonumber(quest.have) or 0) == 0)
	end
	mergeBadge.Visible = merging -- (gone once you've merged)
	if merging and not mergeHinted and not player:GetAttribute("Tutorial") then -- (not till the tutorial's over)
		mergeHinted = true
		player:SetAttribute("MergeHint", true)
	elseif not mergeUp and player:GetAttribute("MergeHint") then
		player:SetAttribute("MergeHint", nil) -- (no Merge animals quest up: e.g. "/tutorial" set the quests back)
	end
	local count = 0
	for _ in claimable do
		count += 1
	end
	dot.Image = BADGES[math.clamp(count, 1, #BADGES)]
	if count == 0 then
		seen()
	end
	for i in pops do -- (claimed before it ever showed)
		local up = false
		for _, quest in questList do
			up = up or (typeof(quest) == "table" and tonumber(quest.i) == i)
		end
		if not up then
			pops[i] = nil
		end
	end
	for _, child in quests:GetChildren() do
		if child.Name == "Quest" then
			child:Destroy()
		end
	end
	local one = not folded and #questList == 1 and QUEST_ART.one ~= ""
	panelClosed.Visible = folded
	panelOne.Visible = one
	local pieces = not folded and not one
	panelTop.Visible, panelMiddle.Visible, panelBottom.Visible = pieces, pieces, pieces
	if folded then
		quests.Size = UDim2.fromOffset(Q.width, Q.header)
		return
	end
	local y = Q.top
	for n, quest in questList do
		if typeof(quest) == "table" and tonumber(quest.i) and tonumber(quest.have) and tonumber(quest.need) then
			y += questRow(quest.i, quest, y) + (if n < #questList then Q.gap else 0)
		end
	end
	-- A pulsing tap hand on a quest ready to claim: the bottom one, if there are two (QM, Oct 11).
	local lastClaim
	for _, row in quests:GetChildren() do
		local claim = row.Name == "Quest" and row:FindFirstChild("Claim", true)
		if claim and (not lastClaim or row.Position.Y.Offset > lastClaim.Parent.Parent.Position.Y.Offset) then
			lastClaim = claim
		end
	end
	if lastClaim then
		local hand = TapHand.new(90)
		hand.Position = UDim2.fromScale(0.62, 0.6)
		hand.Parent = lastClaim
	end
	quests.Size = UDim2.fromOffset(Q.width, if one then 184 else y + Q.bottom)
	panelMiddle.Size = UDim2.fromOffset(Q.width, math.max(y + Q.bottom - 90 - 40, 0))
end
player:GetAttributeChangedSignal("Quests"):Connect(drawQuests)
player:GetAttributeChangedSignal("Tutorial"):Connect(drawQuests)
quests:GetAttributeChangedSignal("Folded"):Connect(drawQuests)
drawQuests()

-- A menu's up over the base: Quests (and PassPopups' cards, by the "Modal" attribute) step aside.
local function modal()
	return Shop.isOpen() or AnimalDex.isOpen() or RollMenu.isOpen() or player:GetAttribute("MergeView") == true
end

RunService.RenderStepped:Connect(function()
	local riding = Hud.isRiding()
	gui.Enabled = not riding and not player:GetAttribute("Cutscene") and not player:GetAttribute("Tutorial") -- (none in the intro or the tutorial: QM, minimal UI till it's done)
	local covered = modal()
	root:SetAttribute("Modal", covered)
	quests.Visible = not riding and not covered and #questList > 0
	-- (the buttons right under the Quests panel, or the top corner with none)
	local under = if quests.Visible then (quests.AbsolutePosition.Y + quests.AbsoluteSize.Y - root.AbsolutePosition.Y) / scale.Scale else 0
	menu.Position = UDim2.new(1, -MARGIN, 0, under + MENU_GAP)
	-- New quests pop once you can see them.
	local up = quests.Visible and gui.Enabled and not Hud.revealing()
	for i, started in pops do
		if started == false and up then
			pops[i] = os.clock()
		elseif started and os.clock() - started > POP_TIME then
			pops[i] = nil
		end
	end
	for _, row in quests:GetChildren() do
		local pop = row.Name == "Quest" and row:FindFirstChild("Pop")
		if pop then
			local started = pops[row:GetAttribute("Quest")]
			pop.Scale = if started then popScale(os.clock() - started) elseif started == false then 0 else 1
			row.Rotation = if started then 6 * math.sin((os.clock() - started) * 18) * math.exp(-6 * (os.clock() - started)) else 0
		end
	end
	if dotSince and not up then
		dotSince = os.clock() -- (its pop waits till you can see it)
	end
	if dotSince then -- (the badge pops in too, then breathes)
		local t = os.clock() - dotSince
		dotScale.Scale = if t < POP_TIME then popScale(t) else 1 + 0.08 * math.sin(t * 5)
	end
end)
