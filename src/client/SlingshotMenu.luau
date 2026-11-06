-- The Slingshot's menu (QM, Nov 6: in place of the top bar): hold E at your slingshot and
-- pick where it flings you. The Weapon Shop's popup (HudKit.popup, its orange Header), one
-- card per biome in its own colours: one you've unlocked has GO!; one you haven't has its
-- price under its name and UNLOCK (only the next one in order can be bought: the server's
-- UnlockBiome, Server/Slingshot, takes the cash and puts your pen level up to it).
--
--   SlingshotMenu.open(onPick)   -- onPick(biome index) when you pick an unlocked one
--   SlingshotMenu.close()
--   SlingshotMenu.isOpen()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local HudKit = require(script.Parent.HudKit)
local NativeHud = require(script.Parent.NativeHud)
local UiFx = require(script.Parent.UiFx)
local Ui = require(script.Parent.Ui)

local SlingshotMenu = {}

local player = Players.LocalPlayer
local fig, label, button = HudKit.fig, HudKit.label, HudKit.button

-- QM's Figma px, as the Shop's
local WIDTH = 2177
local GAP = 22
local CARD_W, CARD_H = 520, 980 -- (a card's own size; more than fit across scroll sideways, as the Weapon Shop's)
local BUTTON_W, BUTTON_H = CARD_W - 70, 170

local gui, cards, onPick
local busy = false

local function unlocked(i)
	return i <= (player:GetAttribute("PenLevel") or 1)
end

local function setLook(b, look)
	if b:GetAttribute("Look") == look then
		return
	end
	local old = b:FindFirstChild("Back")
	if old then
		old:Destroy()
	end
	HudKit.back(b, look, {})
	b:SetAttribute("Look", look)
end

local function refresh()
	if not cards then
		return
	end
	local level = player:GetAttribute("PenLevel") or 1
	local gold = player:GetAttribute("Gold") or 0
	for i, c in cards do
		local biome = Config.Biomes[i]
		local cost = biome.UnlockCost or 0
		if unlocked(i) then
			c.price.Visible = false
			c.text.Text = "GO!"
			setLook(c.button, "Green")
		else
			c.price.Visible = true
			c.price.Text = "$" .. Config.short(cost)
			c.text.Text = "UNLOCK"
			setLook(c.button, if i == level + 1 and gold >= cost then "Green" else "GreyPlain")
		end
	end
end

local function pick(i)
	if busy then
		return
	end
	local c = cards[i]
	if unlocked(i) then
		SlingshotMenu.close()
		if onPick then
			onPick(i)
		end
		return
	end
	local level = player:GetAttribute("PenLevel") or 1
	local cost = Config.Biomes[i].UnlockCost or 0
	if i ~= level + 1 or (player:GetAttribute("Gold") or 0) < cost then
		UiFx.shake(c.button) -- (not the next one yet, or not enough cash)
		return
	end
	busy = true
	local remote = ReplicatedStorage:FindFirstChild("UnlockBiome")
	local ok, bought = false, false
	if remote then
		ok, bought = pcall(remote.InvokeServer, remote, i)
	end
	busy = false
	if ok and bought then
		UiFx.play("Buy")
	else
		UiFx.shake(c.button)
	end
	refresh()
end

local function build()
	if gui then
		return
	end
	local root = NativeHud.popupRoot()
	local close
	gui, close = HudKit.popup(root, "SlingshotMenu", "Slingshot", "Header")
	UiFx.menu(gui, SlingshotMenu.close)
	UiFx.button(close)
	close.Activated:Connect(SlingshotMenu.close)

	local list = Ui.make(gui, "List", "ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(fig(45), fig(300)),
		Size = UDim2.fromOffset(fig(WIDTH) + 4, fig(CARD_H + 50)),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		ScrollingDirection = Enum.ScrollingDirection.X,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = Color3.fromRGB(150, 150, 150),
		ZIndex = 2,
	})
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, fig(GAP))
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft, pad.PaddingRight, pad.PaddingTop = UDim.new(0, fig(10)), UDim.new(0, fig(10)), UDim.new(0, fig(10))
	pad.Parent = list

	local w = CARD_W
	cards = {}
	for i, biome in Config.Biomes do
		local ground = biome.GroundColors or { Color3.fromRGB(120, 200, 90), Color3.fromRGB(100, 170, 70) }
		local wall = biome.WallColors or ground
		local card = Ui.make(list, "Biome" .. i, "Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(fig(w), fig(CARD_H)),
			LayoutOrder = i,
			ZIndex = 2,
		})
		-- its back in the biome's own colours: its ground over its wall, studded
		HudKit.back(card, {
			top = ground[2] or ground[1],
			bottom = wall[1],
			from = 0.3,
			bevel = { 0.75, 0.75 },
			border = { Color3.new(0, 0, 0), 5 },
			tile = { 223.5, 0.8 },
			outline = 6,
			corner = 10,
		}, { Name = "Back", Size = UDim2.fromScale(1, 1), ZIndex = 2 })
		if biome.Picture then
			-- its picture (a render of the biome, Config.Biomes[i].Picture) over the colours
			local pic = Ui.make(card, "Picture", "ImageLabel", {
				BackgroundTransparency = 1,
				Image = biome.Picture,
				ScaleType = Enum.ScaleType.Crop,
				Position = UDim2.fromOffset(fig(8), fig(8)),
				Size = UDim2.new(1, -fig(16), 1, -fig(16)),
				ZIndex = 3,
			})
			local round = Instance.new("UICorner")
			round.CornerRadius = UDim.new(0, fig(8))
			round.Parent = pic
		end
		label(card, "BiomeName", {
			Text = biome.Name,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextSize = fig(100),
			Position = UDim2.fromOffset(fig(20), fig(60)),
			Size = UDim2.new(1, -fig(40), 0, fig(130)),
			ZIndex = 4,
		})
		local price = label(card, "Price", {
			Text = "",
			TextColor3 = Color3.fromHex("ffe700"),
			TextXAlignment = Enum.TextXAlignment.Center,
			TextSize = fig(110),
			Position = UDim2.fromOffset(fig(20), fig(230)),
			Size = UDim2.new(1, -fig(40), 0, fig(130)),
			ZIndex = 4,
		})
		local b = button(card, "Go", BUTTON_W, BUTTON_H, {
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -fig(60)),
			ZIndex = 4,
		}, "Green")
		b:SetAttribute("Look", "Green")
		UiFx.button(b)
		local text = label(b, "Text", {
			Text = "GO!",
			TextXAlignment = Enum.TextXAlignment.Center,
			TextSize = fig(90),
			Size = UDim2.fromScale(1, 1),
			ZIndex = 6,
		})
		b.Activated:Connect(function()
			pick(i)
		end)
		cards[i] = { button = b, price = price, text = text }
	end
	player:GetAttributeChangedSignal("Gold"):Connect(refresh)
	player:GetAttributeChangedSignal("PenLevel"):Connect(refresh)
end

function SlingshotMenu.open(callback)
	build()
	onPick = callback
	refresh()
	NativeHud.haze("SlingshotMenu", true)
	UiFx.popIn(gui)
end

function SlingshotMenu.close()
	if gui and UiFx.isOpen(gui) then
		UiFx.popOut(gui)
	end
	NativeHud.haze("SlingshotMenu", false)
end

function SlingshotMenu.isOpen()
	return gui ~= nil and UiFx.isOpen(gui)
end

return SlingshotMenu
