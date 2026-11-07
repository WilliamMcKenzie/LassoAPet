-- The Rebirth popup (QM, Nov 7; Config.Luck): the last goal's Claim! and the luck counter open
-- it (NativeHud). The orange-headed popup (HudKit.popup, as the Slingshot's menu), what a
-- rebirth does in three dark bars, each now -> after:
-- (QM, Nov 7: icons, not words)
--   [cash]   $1.2m -> $0
--   every biome you've unlocked (its picture, Config.Biomes[i].Picture) -> just the Meadow's,
--   then [cash] x1 -> x2 (unlock prices)
--   [clover] +0.25 -> +0.5 (luck per goal: goal rewards x2; your luck itself stays)
-- and under them Rebirth! (Hatchery's Rebirth), or, till the Rebirth goal is done, a grey
-- "Reach <Config.rebirthBiome>" (Desert, then Tundra...) that does nothing. X (or not confirming) leaves the goal to claim later.
--
--   RebirthPopup.open()
--   RebirthPopup.close()

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local HudKit = require(script.Parent.HudKit)
local NativeHud = require(script.Parent.NativeHud)
local UiFx = require(script.Parent.UiFx)
local Ui = require(script.Parent.Ui)

local RebirthPopup = {}

local player = Players.LocalPlayer
local fig, label, button = HudKit.fig, HudKit.label, HudKit.button
local GOOD = "#7CFF4D" -- (the Slingshot menu's Unlocked green)
local BAD = "#ff5a5a" -- (and its Locked red)
local ROW_W, ROW_H, ROW_GAP = 1800, 170, 40
local ROWS_Y = 360
local CONFIRM_W, CONFIRM_H, CONFIRM_Y = 900, 200, 1060

local PIC_MAX_H, PIC_ASPECT, PIC_GAP = 130, 1.4, 16 -- the Slingshot row's biome pictures
local ARROW_W, PRICES_W = 170, 520 -- (the arrow's and the prices' room, icon and all)
local ICON = 140 -- the rows' icons (HudImages: the HUD's cash and clover)

local gui, rows, confirm, confirmText, waiting

-- The Rebirth goal is up and done (the "Quests" attribute: Server/Quests).
local function ready()
	local ok, list = pcall(HttpService.JSONDecode, HttpService, player:GetAttribute("Quests") or "[]")
	for _, q in if ok and type(list) == "table" then list else {} do
		if q.kind == "rebirth" and q.have >= q.need then
			return true
		end
	end
	return false
end

local function colored(text, hex)
	return '<font color="' .. hex .. '">' .. text .. "</font>"
end

local function refresh()
	if not gui then
		return
	end
	local reborn = player:GetAttribute("Reborn") or 0
	local per = Config.Luck.CostPerRebirth
	-- each row an icon strip (QM, Nov 7: icons, not words), rebuilt each time
	local strip, order
	local function start(row)
		strip, order = rows[row].Strip, 0
		for _, child in strip:GetChildren() do
			if not child:IsA("UIListLayout") then
				child:Destroy()
			end
		end
	end
	local function icon(name)
		order += 1
		HudKit.art(strip, name, { Size = UDim2.fromOffset(fig(ICON), fig(ICON)), LayoutOrder = order, ZIndex = 4 })
	end
	local function text(str)
		order += 1
		label(strip, "Text" .. order, {
			RichText = true,
			Text = str,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextSize = fig(80),
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromOffset(0, fig(ROW_H)),
			LayoutOrder = order,
			ZIndex = 4,
		})
	end
	local function picture(i, h)
		order += 1
		local pic = Instance.new("ImageLabel")
		pic.Name = "Biome" .. order
		pic.BackgroundColor3 = Color3.new(0, 0, 0)
		pic.Image = Config.Biomes[i].Picture or ""
		pic.ScaleType = Enum.ScaleType.Crop
		pic.Size = UDim2.fromOffset(fig(h * PIC_ASPECT), fig(h))
		pic.LayoutOrder = order
		pic.ZIndex = 4
		local round = Instance.new("UICorner")
		round.CornerRadius = UDim.new(0, fig(10))
		round.Parent = pic
		local edge = Instance.new("UIStroke")
		edge.Thickness = fig(4)
		edge.Color = Color3.new(0, 0, 0)
		edge.Parent = pic
		pic.Parent = strip
	end
	local ARROW = "  →  "

	-- cash: [cash] $9.8b -> $0
	start("Cash")
	icon("CashIcon")
	text("$" .. Config.short(player:GetAttribute("Gold") or 0) .. ARROW .. colored("$0", BAD))

	-- slingshot: your unlocked biomes' pictures -> the Meadow's, [cash] x1 -> x2 (its prices)
	start("Slingshot")
	local have = math.clamp(player:GetAttribute("PenLevel") or 1, 1, #Config.Biomes)
	local room = ROW_W - 60 - ARROW_W - PRICES_W - (have + 4) * PIC_GAP
	local h = math.min(PIC_MAX_H, room / (have + 1) / PIC_ASPECT)
	for i = 1, have do
		picture(i, h)
	end
	text(ARROW)
	picture(1, h)
	icon("CashIcon")
	text("x" .. Config.short(per ^ reborn) .. ARROW .. colored("x" .. Config.short(per ^ (reborn + 1)), BAD))

	-- luck per goal: [clover] +0.25 -> +0.5
	local now, after = Config.Luck.Reach * Config.Luck.RewardPerRebirth ^ reborn, Config.Luck.Reach * Config.Luck.RewardPerRebirth ^ (reborn + 1)
	local function plus(n)
		return "+" .. (string.format("%.2f", n):gsub("%.?0+$", ""))
	end
	start("Luck")
	icon("LuckIcon")
	text(plus(now) .. ARROW .. colored(plus(after), GOOD))
	local can = ready()
	confirm.Active = can
	confirm.AutoButtonColor = false
	local back = confirm:FindFirstChild("Back")
	if back then
		back.Visible = can
	end
	confirm:FindFirstChild("Grey").Visible = not can
	local target = Config.rebirthBiome(player)
	confirmText.Text = if can then "Rebirth!" else "Reach " .. (Config.BiomeNames[1][target] or Config.Biomes[target].Name)
end

local function build()
	if gui then
		return
	end
	local root = NativeHud.popupRoot()
	local close
	gui, close = HudKit.popup(root, "RebirthPopup", "Rebirth", "Header")
	UiFx.menu(gui, RebirthPopup.close) -- (one menu at a time: client/UiFx)
	close.Activated:Connect(RebirthPopup.close)

	rows = {}
	for k, name in { "Cash", "Slingshot", "Luck" } do
		local bar = HudKit.back(gui, "Dark", {
			Name = name,
			Position = UDim2.fromOffset(fig((2268 - ROW_W) / 2), fig(ROWS_Y + (k - 1) * (ROW_H + ROW_GAP))),
			Size = UDim2.fromOffset(fig(ROW_W), fig(ROW_H)),
			ZIndex = 3,
		})
		-- (filled in by refresh: icons, text and pictures in a centred row)
		local strip = Instance.new("Frame")
		strip.Name = "Strip"
		strip.BackgroundTransparency = 1
		strip.Size = UDim2.fromScale(1, 1)
		strip.ZIndex = 4
		local list = Instance.new("UIListLayout")
		list.FillDirection = Enum.FillDirection.Horizontal
		list.HorizontalAlignment = Enum.HorizontalAlignment.Center
		list.VerticalAlignment = Enum.VerticalAlignment.Center
		list.SortOrder = Enum.SortOrder.LayoutOrder
		list.Padding = UDim.new(0, fig(PIC_GAP))
		list.Parent = strip
		strip.Parent = bar
		rows[name] = bar
	end

	confirm = button(gui, "RebirthConfirm", CONFIRM_W, CONFIRM_H, {
		Position = UDim2.fromOffset(fig((2268 - CONFIRM_W) / 2), fig(CONFIRM_Y)),
		ZIndex = 4,
	}, "GreenEdged")
	-- (a grey back in its place till you can: the green one hidden)
	HudKit.back(confirm, "GreyPlain", { Name = "Grey", Visible = false })
	confirmText = label(confirm, "Text", {
		Text = "Rebirth!",
		TextXAlignment = Enum.TextXAlignment.Center,
		TextScaled = true,
		Position = UDim2.fromScale(0.05, 0.1),
		Size = UDim2.fromScale(0.9, 0.8),
		ZIndex = 6,
	})
	local cap = Instance.new("UITextSizeConstraint")
	cap.MaxTextSize = fig(90)
	cap.Parent = confirmText

	local remote = ReplicatedStorage:WaitForChild("Rebirth", 10)
	confirm.Activated:Connect(function()
		if waiting then
			return
		end
		if not ready() then
			UiFx.shake(confirm)
			return
		end
		waiting = true
		local ok, done = false, false
		if remote then
			ok, done = pcall(remote.InvokeServer, remote)
		end
		waiting = false
		if ok and done then
			UiFx.play("Claim")
			RebirthPopup.close()
		else
			UiFx.shake(confirm)
		end
	end)
	for _, name in { "Gold", "Reborn", "Quests", "LuckBonus", "PenLevel" } do
		player:GetAttributeChangedSignal(name):Connect(refresh)
	end
end

function RebirthPopup.open()
	build()
	refresh()
	NativeHud.haze("RebirthPopup", true)
	UiFx.popIn(gui)
end

function RebirthPopup.close()
	if gui and UiFx.isOpen(gui) then
		UiFx.popOut(gui)
	end
	NativeHud.haze("RebirthPopup", false)
end

return RebirthPopup
