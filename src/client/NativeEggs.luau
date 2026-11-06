-- The Growing Eggs popup in the native UI (Config.NativeUi, QM Nov 6): Fight to Steal an Egg's
-- (its client/EggsPanel, 1:1 in look), opened by the red egg button under Pets and sliding in
-- on the right (client/SidePanel). A tan header with "Growing Eggs" and the yellow HATCH ALL
-- (Lasso's Hatch All product, Config.HatchAll: while any egg is still growing), and a row per
-- egg in your pen (its Contents): the egg (Config.EggIcons) and a green bar filling as it
-- grows, the time left over it; once it's ready the bar pops into a green HATCH that hatches
-- it from wherever you are (HatchEgg: Server/Hatchery lets the native UI's hatch from anywhere).
--
--   NativeEggs.toggle() / NativeEggs.close() / NativeEggs.isOpen()

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local HudKit = require(script.Parent.HudKit)
local NativeHud = require(script.Parent.NativeHud)
local SidePanel = require(script.Parent.SidePanel)
local Ui = require(script.Parent.Ui)
local UiFx = require(script.Parent.UiFx)

local NativeEggs = {}

local player = Players.LocalPlayer
local fig, label, button = HudKit.fig, HudKit.label, HudKit.button
local TITLE_OUTLINE = Color3.fromHex("8a3a00")
local TICK = 0.2 -- seconds between the bars' updates while it's open
local POP = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out) -- (HATCH growing in)

local panel, template, hatchAll

-- a row (QM's Figma Card: 876 x 207): the egg, then the bar (639 x 72 with its 6px border)
local function rowTemplate()
	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.Size = UDim2.fromOffset(fig(876), fig(207))
	HudKit.back(row, "EggCard", {})
	local picture = Instance.new("ImageLabel")
	picture.Name = "Picture"
	picture.BackgroundTransparency = 1
	picture.ScaleType = Enum.ScaleType.Fit
	picture.Position = UDim2.fromOffset(fig(13), fig(15))
	picture.Size = UDim2.fromOffset(fig(177), fig(177))
	picture.ZIndex = 2
	picture.Parent = row
	local track = HudKit.back(row, "EggTrack", {
		Name = "Track",
		Position = UDim2.fromOffset(fig(202 + 6), fig(67 + 6)),
		Size = UDim2.fromOffset(fig(639 - 12), fig(72 - 12)),
		ZIndex = 2,
	})
	local clip = Instance.new("Frame")
	clip.Name = "Clip"
	clip.BackgroundTransparency = 1
	clip.ClipsDescendants = true
	clip.Size = UDim2.fromScale(1, 1)
	clip.ZIndex = 3
	clip.Parent = track
	-- (the green keeps the whole track's size, so it's cut, not squashed)
	HudKit.back(clip, "EggGrow", { Name = "Grow", Size = UDim2.fromOffset(fig(639 - 12), fig(72 - 12)), ZIndex = 3 })
	label(track, "Left", {
		Text = "12s",
		TextXAlignment = Enum.TextXAlignment.Center,
		TextSize = fig(40),
		Size = UDim2.fromScale(1, 1),
		ZIndex = 5,
	})
	-- HATCH over the bar, in a holder whose Pop grows it in from its middle
	local pop = Instance.new("Frame")
	pop.Name = "HatchPop"
	pop.BackgroundTransparency = 1
	pop.AnchorPoint = Vector2.new(0.5, 0.5)
	pop.Position = UDim2.fromOffset(fig(202 + 639 / 2), fig(67 + 72 / 2))
	pop.Size = UDim2.fromOffset(fig(639), fig(90))
	pop.ZIndex = 6
	pop.Visible = false
	pop.Parent = row
	Ui.make(pop, "Pop", "UIScale")
	local b = button(pop, "Hatch", 639, 90, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		ZIndex = 6,
	}, "GreenYellow")
	label(b, "Text", {
		Text = "HATCH",
		TextXAlignment = Enum.TextXAlignment.Center,
		TextSize = fig(40),
		Size = UDim2.fromScale(1, 1),
		ZIndex = 7,
	})
	return row
end

-- time left: "12s" under a minute, "4:05" under an hour, then whole hours ("2h")
local function left(seconds)
	seconds = math.max(0, math.ceil(seconds))
	if seconds >= 3600 then
		return string.format("%dh", seconds // 3600)
	elseif seconds >= 60 then
		return string.format("%d:%02d", seconds // 60, seconds % 60)
	end
	return string.format("%ds", seconds)
end

local function myPen()
	local pens = workspace:FindFirstChild("Pens")
	return pens and pens:FindFirstChild("Pen" .. tostring(player:GetAttribute("Pen")))
end

-- the eggs in your pen: { id, kind, at (os.time it's ready), total (seconds it takes) }
local firstSeen = {} -- [id] = seconds left when first seen (eggs placed before hatchFor)
local function placed()
	local pen = myPen()
	local ok, items = pcall(HttpService.JSONDecode, HttpService, pen and pen:GetAttribute("Contents") or "{}")
	local out = {}
	for id, item in if ok and typeof(items) == "table" then items else {} do
		if typeof(item) == "table" and item.egg and tonumber(item.hatchAt) then
			local at = tonumber(item.hatchAt)
			firstSeen[id] = firstSeen[id] or math.max(at - workspace:GetServerTimeNow(), 1)
			table.insert(out, { id = id, kind = item.egg, at = at, total = tonumber(item.hatchFor) or firstSeen[id] })
		end
	end
	table.sort(out, function(a, b) -- (the soonest ready first)
		if a.at ~= b.at then
			return a.at < b.at
		end
		return a.id < b.id
	end)
	return out
end

local made = {} -- { { row, egg, ready } }
local function update()
	local now = workspace:GetServerTimeNow()
	local growing = false
	for _, m in made do
		local row, egg = m[1], m[2]
		local rest = egg.at - now
		growing = growing or rest > 0
		row.Track.Clip.Size = UDim2.fromScale(math.clamp(1 - rest / math.max(egg.total, 1), 0, 1), 1)
		row.Track.Left.Text = if rest <= 0 then "Ready" else left(rest)
		local ready = rest <= 0
		local was = m[3]
		if ready ~= was then
			m[3] = ready
			local pop = row.HatchPop
			row.Track.Visible = not ready
			pop.Visible = ready
			if ready and panel:isOpen() and was ~= nil then
				pop.Pop.Scale = 0
				TweenService:Create(pop.Pop, POP, { Scale = 1 }):Play()
			else
				pop.Pop.Scale = 1
			end
		end
	end
	hatchAll.Visible = growing and Config.HatchAll ~= nil
end

local function refresh()
	if not panel then
		return
	end
	for _, m in made do
		m[1]:Destroy()
	end
	table.clear(made)
	for i, egg in placed() do
		local row = Ui.copy(template, "Row" .. i, panel.rows)
		row.LayoutOrder = i
		row.Picture.Image = Config.EggIcons[egg.kind] or ""
		local hatch = row.HatchPop.Hatch
		HudKit.hover(hatch) -- (a copy doesn't keep the template's)
		local sent = false
		hatch.Activated:Connect(function()
			if not sent and egg.at <= workspace:GetServerTimeNow() then
				sent = true -- (once: the row goes when the pen's Contents drops it)
				UiFx.play("Claim")
				ReplicatedStorage:WaitForChild("HatchEgg"):FireServer(egg.id)
			end
		end)
		table.insert(made, { row, egg })
	end
	update()
end

local function ensure()
	if panel then
		return
	end
	panel = SidePanel.new(NativeHud.popupRoot(), "EggsPanel", "TanHeader", "Growing Eggs", TITLE_OUTLINE)
	hatchAll = button(panel.gui, "EggsHatchAll", 302, 90, { Position = UDim2.fromOffset(fig(850), fig(19)), ZIndex = 4 }, "Yellow")
	label(hatchAll, "Text", {
		Text = "HATCH ALL",
		TextXAlignment = Enum.TextXAlignment.Center,
		TextSize = fig(35),
		Size = UDim2.fromScale(1, 1),
		ZIndex = 5,
	})
	hatchAll.Activated:Connect(function()
		ReplicatedStorage:WaitForChild("BuyShop"):FireServer("HatchAll", "eggs") -- (Roblox's prompt; hatched once it's paid)
	end)
	template = Ui.template(panel.rows, "RowTemplate", rowTemplate)
	-- kept up to date while it's open
	local watched
	local function watchPen()
		if watched then
			watched:Disconnect()
			watched = nil
		end
		local pen = myPen()
		if pen then
			watched = pen:GetAttributeChangedSignal("Contents"):Connect(function()
				if panel:isOpen() then
					refresh()
				end
			end)
		end
	end
	player:GetAttributeChangedSignal("Pen"):Connect(watchPen)
	watchPen()
	local since = 0
	RunService.Heartbeat:Connect(function(dt)
		since += dt
		if since >= TICK and panel:isOpen() then
			since = 0
			update()
		end
	end)
	-- (its haze follows it, however it closes: its tab, another menu opening)
	panel.gui:GetPropertyChangedSignal("Visible"):Connect(function()
		NativeHud.haze("Eggs", panel.gui.Visible)
	end)
end

function NativeEggs.isOpen()
	return panel ~= nil and panel:isOpen()
end

function NativeEggs.toggle()
	ensure()
	if not panel:isOpen() then
		refresh()
		panel.rows.CanvasPosition = Vector2.zero
	end
	panel:toggle()
end

function NativeEggs.close()
	if panel then
		panel:close()
	end
end

return NativeEggs
