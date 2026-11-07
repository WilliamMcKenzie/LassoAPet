-- The Rebirth popup (QM, Nov 7; Config.Luck): the last goal's Claim! and the luck counter open
-- it (NativeHud). The orange-headed popup (HudKit.popup, as the Slingshot's menu), what a
-- rebirth does in three dark bars, each now -> after:
--   Cash             $1.2m -> $0
--   Slingshot        unlocks wiped, prices x1 -> x2
--   Luck             x1 -> x2
-- and under them Rebirth! (Hatchery's Rebirth), or, till the Rebirth goal is done, a grey
-- "Reach Ocean Trench" that does nothing. X (or not confirming) leaves the goal to claim later.
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

local gui, rows, confirm, confirmText, waiting
local lastBiome = #Config.Biomes
local lastName = Config.BiomeNames[1][lastBiome] or Config.Biomes[lastBiome].Name

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
	local luck = Config.luck(player)
	local per = Config.Luck.CostPerRebirth
	rows.Cash.Text.Text = "Cash   $" .. Config.short(player:GetAttribute("Gold") or 0) .. "  →  " .. colored("$0", BAD)
	rows.Slingshot.Text.Text = "Slingshot unlocks wiped, prices x"
		.. Config.short(per ^ reborn)
		.. "  →  "
		.. colored("x" .. Config.short(per ^ (reborn + 1)), BAD)
	rows.Luck.Text.Text = "Luck   x" .. Config.short(luck) .. "  →  " .. colored("x" .. Config.short(luck * Config.Luck.PerRebirth), GOOD)
	local can = ready()
	confirm.Active = can
	confirm.AutoButtonColor = false
	local back = confirm:FindFirstChild("Back")
	if back then
		back.Visible = can
	end
	confirm:FindFirstChild("Grey").Visible = not can
	confirmText.Text = if can then "Rebirth!" else "Reach " .. lastName
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
		label(bar, "Text", {
			RichText = true,
			Text = "",
			TextXAlignment = Enum.TextXAlignment.Center,
			TextSize = fig(80),
			Size = UDim2.fromScale(1, 1),
			ZIndex = 4,
		})
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
	for _, name in { "Gold", "Reborn", "Quests" } do
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
