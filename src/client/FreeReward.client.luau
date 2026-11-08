-- (Ported from Fight to Steal an Egg 1:1, QM Nov 7: its free gift, but +3 luck and +5k cash,
-- not Power.) The present right of the course's mouth (Shared/GiftModel, Server/FreeGift)
-- bobs gently; walking into its ring opens the Free Reward! popup: a lime header with the red
-- X, the luck clover on a turning sunburst, "LIMITED TIME!" over "+3x Luck" and "+$5K Cash",
-- the three steps (Like the game, Favorite the game, Join the group) and Claim!. Claimed
-- (Server/FreeGift, once per player, saved), the luck and cash go in and the whole present
-- goes, for you.
--
-- The steps are only shown, not ticked off: Claim asks the server, which checks you're in the
-- group (Roblox doesn't tell a game who liked or favorited it, so those can't be checked). Not
-- in it: a red "Steps not complete!" pops up where you clicked, floats up and fades.
--
-- Built like the other native popups (Client/HudKit, Figma px through HudKit.fig), on
-- NativeHud's popup root, as the Rebirth popup.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local HudKit = require(script.Parent.HudKit)
local NativeHud = require(script.Parent.NativeHud)
local Ui = require(script.Parent.Ui)
local UiFx = require(script.Parent.UiFx)

local fig = HudKit.fig
local label = HudKit.label
local W, H = 2268, 1370 -- the popup (HudKit.popup's size, Figma px)
local HEADER = 283
local ART_X, ART_Y = 560, 590 -- the clover's and sunburst's middle
local BURST = 900
local CLOVER = 470
local TEXT_X = 1500 -- the middle of "LIMITED TIME!" and the amounts
local CARD_W, CARD_H, CARD_Y, CARD_GAP = 640, 290, 860, 60
local CLAIM_W, CLAIM_H, CLAIM_Y = 760, 165, 1172
local SPIN = 12 -- degrees a second the sunburst turns
local TOAST_SIZE = 0.045 -- "Steps not complete!": its text, of the screen's height
local TOAST_RISE = 0.08 -- how far it floats up, of the screen's height
local TOAST_LIFE = 0.9 -- seconds it takes to float up and fade
local RED_TOP, RED_BOTTOM = Color3.fromHex("ff6a6a"), Color3.fromHex("e00000")
local GREEN_TOP, GREEN_BOTTOM = Color3.fromHex("caff00"), Color3.fromHex("0aff00") -- (the luck: the clover's green)
local GOLD_TOP, GOLD_BOTTOM = Color3.fromHex("fff36a"), Color3.fromHex("ffb300") -- (the cash)
local STEPS = {
	{ name = "Like", icon = "👍", text = "Like the game" },
	{ name = "Favorite", icon = "⭐", text = "Favorite the game" },
	{ name = "Group", icon = "👥", text = "Join the group" },
}
local AWAY = 12 -- studs past the ring that closes the popup again

local player = Players.LocalPlayer

local function gradient(parent, top, bottom)
	local g, fresh = Ui.make(parent, "Shade", "UIGradient")
	if fresh then
		g.Rotation = 90
		g.Color = ColorSequence.new(top, bottom)
	end
	return g
end

local function cardX(i)
	local total = 3 * CARD_W + 2 * CARD_GAP
	return (W - total) / 2 + (i - 1) * (CARD_W + CARD_GAP)
end

local function build(root)
	local gui, close = HudKit.popup(root, "FreeReward", "Free Reward!", "LimeHeader")

	-- the reward: the luck clover on a sunburst (clipped to the panel)
	local clip, fresh = Ui.make(gui, "Burst", "Frame")
	if fresh then
		clip.BackgroundTransparency = 1
		clip.ClipsDescendants = true
		clip.Position = UDim2.fromOffset(fig(8), fig(HEADER))
		clip.Size = UDim2.fromOffset(fig(W - 16), fig(H - HEADER - 8))
		clip.ZIndex = 2
	end
	HudKit.art(clip, "Sunburst", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(fig(ART_X - 8), fig(ART_Y - HEADER)),
		Size = UDim2.fromOffset(fig(BURST), fig(BURST)),
		ImageColor3 = Color3.fromHex("7fd8ff"),
		ImageTransparency = 0.55,
		ZIndex = 2,
	})
	HudKit.art(gui, "LuckIcon", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(fig(ART_X), fig(ART_Y)),
		Size = UDim2.fromOffset(fig(CLOVER), fig(CLOVER)),
		ZIndex = 4,
	})

	-- "LIMITED TIME!" and the amounts (luck, then cash)
	local limited = label(gui, "Limited", {
		Text = "LIMITED TIME!",
		TextSize = fig(150),
		TextXAlignment = Enum.TextXAlignment.Center,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(fig(TEXT_X), fig(400)),
		Size = UDim2.fromOffset(fig(1300), fig(200)),
		ZIndex = 5,
	})
	gradient(limited, RED_TOP, RED_BOTTOM)
	for _, a in {
		{ "Amount", "+" .. Config.short(Config.FreeGift.Luck) .. "x Luck", 180, 580, GREEN_TOP, GREEN_BOTTOM },
		{ "Cash", "+$" .. Config.short(Config.FreeGift.Cash) .. " Cash", 130, 760, GOLD_TOP, GOLD_BOTTOM },
	} do
		local amount = label(gui, a[1], {
			Text = a[2],
			TextSize = fig(a[3]),
			TextXAlignment = Enum.TextXAlignment.Center,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(fig(TEXT_X), fig(a[4])),
			Size = UDim2.fromOffset(fig(1400), fig(a[3] * 1.2)),
			ZIndex = 5,
		})
		if not amount:GetAttribute("Thick") then -- (once: an outline QM changed in Studio stays)
			amount:SetAttribute("Thick", true)
			amount.Outline.Thickness = fig(a[3] * 0.07)
		end
		gradient(amount, a[5], a[6])
	end

	-- the three steps: just shown (QM, Oct 31: not ticked off one by one; Claim checks)
	for _, old in { "LikeCard", "FavoriteCard", "GroupCard", "Arrow" } do
		local was = gui:FindFirstChild(old) -- (the first try's clickable cards and arrow)
		if was then
			was:Destroy()
		end
	end
	for i, step in STEPS do
		local card = HudKit.back(gui, "Dark", {
			Name = step.name .. "Step",
			Position = UDim2.fromOffset(fig(cardX(i)), fig(CARD_Y)),
			Size = UDim2.fromOffset(fig(CARD_W), fig(CARD_H)),
			ZIndex = 5,
		})
		local icon
		icon, fresh = Ui.make(card, "Icon", "TextLabel")
		if fresh then
			icon.BackgroundTransparency = 1
			icon.AnchorPoint = Vector2.new(0.5, 0.5)
			icon.Position = UDim2.fromScale(0.5, 0.36)
			icon.Size = UDim2.fromOffset(fig(CARD_W), fig(150))
			icon.TextSize = fig(130)
			icon.Text = step.icon
			icon.ZIndex = 7
		end
		label(card, "Text", {
			Text = step.text,
			TextSize = fig(66),
			TextXAlignment = Enum.TextXAlignment.Center,
			Position = UDim2.fromOffset(0, fig(CARD_H - 110)),
			Size = UDim2.fromOffset(fig(CARD_W), fig(90)),
			ZIndex = 7,
		})
	end

	-- Claim!
	local claim = HudKit.button(gui, "Claim", CLAIM_W, CLAIM_H, {
		Position = UDim2.fromOffset(fig((W - CLAIM_W) / 2), fig(CLAIM_Y)),
		ZIndex = 6,
	}, "GreenEdged")
	label(claim, "Text", {
		Text = "Claim!",
		TextSize = fig(120),
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 8,
	})
	return gui, close, claim, clip.Sunburst
end

-- ---- the gift in the world ----------------------------------------------------------------

local gift -- workspace.FreeGift
local base -- its Present's pivot as built

local home -- the folder it was in, to put it back (a /reset)

-- claimed: the whole present goes, for you only (QM, Oct 31): taken out of your copy of the map
local function hideGift()
	if gift and gift.Parent then
		home = gift.Parent
		gift.Parent = nil
	end
end

local function showGift()
	if gift and not gift.Parent and home and home.Parent then
		gift.Parent = home
	end
end

local function findGift()
	local found = workspace:WaitForChild("FreeGift", 60)
	if not found then
		return
	end
	gift = found
	local present = gift:WaitForChild("Present", 10)
	base = present and present:GetPivot()
	if player:GetAttribute("FreeGift") then
		hideGift()
	end
end

-- ---- the popup ------------------------------------------------------------------------------

-- "Steps not complete!" in red where you clicked, floating up and fading (QM, Oct 31)
local toastGui
local function toast(text, at)
	if not toastGui then
		toastGui = Instance.new("ScreenGui")
		toastGui.Name = "FreeRewardToast"
		toastGui.IgnoreGuiInset = true
		toastGui.ResetOnSpawn = false
		toastGui.DisplayOrder = 50
		toastGui.Parent = player:WaitForChild("PlayerGui")
	end
	local height = workspace.CurrentCamera.ViewportSize.Y
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.FontFace = HudKit.FONT
	l.Text = text
	l.TextSize = math.round(height * TOAST_SIZE)
	l.TextColor3 = Color3.new(1, 1, 1)
	l.AnchorPoint = Vector2.new(0.5, 1)
	l.Size = UDim2.fromOffset(height, l.TextSize * 1.3)
	l.Position = UDim2.fromOffset(at.X, at.Y - 6)
	local g = Instance.new("UIGradient")
	g.Rotation = 90
	g.Color = ColorSequence.new(RED_TOP, RED_BOTTOM)
	g.Parent = l
	local stroke = Instance.new("UIStroke")
	stroke.Color = HudKit.BLACK
	stroke.Thickness = math.max(2, math.round(l.TextSize / 12))
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = l
	local grow = Instance.new("UIScale")
	grow.Scale = 0.6
	grow.Parent = l
	l.Parent = toastGui
	TweenService:Create(grow, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	local float = TweenInfo.new(TOAST_LIFE, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(l, float, { Position = UDim2.fromOffset(at.X, at.Y - 6 - height * TOAST_RISE) }):Play()
	local fade = TweenInfo.new(TOAST_LIFE, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	TweenService:Create(l, fade, { TextTransparency = 1 }):Play()
	TweenService:Create(stroke, fade, { Transparency = 1 }):Play()
	task.delay(TOAST_LIFE, function()
		l:Destroy()
	end)
end

local function wire(gui, close, claim, burst)
	local remote = ReplicatedStorage:WaitForChild("FreeGiftClaim", 10)
	local s = Config.FreeGift
	local spinning

	local function shut()
		if spinning then
			spinning:Disconnect()
			spinning = nil
		end
		if UiFx.isOpen(gui) then
			UiFx.popOut(gui)
		end
		NativeHud.haze("FreeReward", false)
	end

	local function open()
		if player:GetAttribute("FreeGift") or UiFx.isOpen(gui) then
			return
		end
		NativeHud.haze("FreeReward", true)
		UiFx.popIn(gui)
		if not spinning then
			spinning = RunService.RenderStepped:Connect(function(dt)
				burst.Rotation = (burst.Rotation + SPIN * dt) % 360
			end)
		end
	end

	UiFx.menu(gui, shut)
	close.Activated:Connect(shut)

	-- Claim: the server checks the group (likes and favorites can't be checked)
	local claiming = false
	claim.Activated:Connect(function()
		if claiming or not remote then
			return
		end
		local at = UserInputService:GetMouseLocation()
		claiming = true
		local ok, got, why = pcall(remote.InvokeServer, remote)
		claiming = false
		if ok and got then
			UiFx.play("Claim")
			shut()
			hideGift()
		elseif why == "claimed" then
			shut()
			hideGift()
		elseif why == "group" then
			UiFx.play("Error")
			toast("Steps not complete!", at)
		else
			UiFx.shake(claim)
		end
	end)
	player:GetAttributeChangedSignal("FreeGift"):Connect(function()
		if player:GetAttribute("FreeGift") then
			hideGift()
		else
			showGift() -- (/reset: it's back to claim again)
		end
	end)

	-- walking into the ring opens it (once each time you step in); walking off closes it
	local inside = false
	local t = 0
	RunService.Heartbeat:Connect(function(dt)
		t += dt
		if not (gift and gift.Parent) then
			return
		end
		local pivot = gift:GetPivot()
		local character = player.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		local away = if hrp then ((hrp.Position - pivot.Position) * Vector3.new(1, 0, 1)).Magnitude else math.huge
		-- (the present bobs and sways while you're near enough to see it)
		local present = gift:FindFirstChild("Present")
		if present and base and away < 250 then
			present:PivotTo(base * CFrame.new(0, s.Bob * (math.sin(t * 2) + 1) / 2, 0) * CFrame.Angles(0, math.sin(t * 0.9) * 0.12, 0))
		end
		if player:GetAttribute("FreeGift") or not player:GetAttribute("GoldLoaded") then
			return
		end
		if away <= s.OpenRadius then
			if not inside then
				inside = true
				open()
			end
		elseif away > s.OpenRadius + 2 then
			inside = false
			if away > s.OpenRadius + AWAY and UiFx.isOpen(gui) then
				shut()
			end
		end
	end)
end

local gui, close, claim, burst = build(NativeHud.popupRoot())
gui.Visible = false
task.spawn(findGift)
wire(gui, close, claim, burst)
