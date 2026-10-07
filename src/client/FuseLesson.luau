-- The fuse lesson (QM, Oct 7): fusing opens with the Desert, so the Fuse button's
-- hidden till then, and till this lesson shows it to you (Hud.fuseUnlocked). Unlocking the Desert makes the lesson due
-- (the "FuseLesson" attribute: PenLevel.server sets it, Hatchery saves it till
-- you've fused). The next time you're home with two pets that can fuse, the rest
-- of the HUD goes, the Fuse button pops up big in the middle of the screen with a
-- bounce, shrinks as it flies to its spot, and Tutorial's cursor leads you through
-- it: Fuse, both pets, FUSE (FuseMenu's Hud.fuseGuide). Once the hybrid's landed
-- it's done, for good. Players who'd unlocked the Desert before never see it.
--
-- Tutorial.update drives it every frame (FuseLesson.update) and shows the HUD
-- stage and cursor target it returns.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Fusion = require(ReplicatedStorage.Shared.Fusion)
local SpeedGates = require(ReplicatedStorage.Shared.SpeedGates)
local Hud = require(script.Parent.Hud)
local PenPets = require(script.Parent.PenPets)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local REVEAL = { Big = 3, Pop = 0.5, Hold = 0.35, Fly = 0.6 } -- the Fuse button's reveal: times its size in the middle, then seconds
local GIVE_UP = 5 -- seconds after FUSE with no hybrid showing up before it counts as done anyway

local FuseLesson = {}
FuseLesson.done = nil -- called once it's over (Tutorial: the camera flies to the next gate)

local running = nil -- nil, "reveal" (the button's flying in) or "guide" (the cursor's leading)
local from = math.huge -- when it began
local before = 0 -- your hybrids then
local finished = false -- FuseLessonDone sent (till the attribute's set again)

local gui = Instance.new("ScreenGui")
gui.Name = "FuseLesson"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 6
gui.Parent = player:WaitForChild("PlayerGui")

-- Your pets: the one you ride and the pen's, as { kind, fuse } (eggs don't count).
local function yourPets()
	local list = {}
	local ride = player:GetAttribute("RidePet")
	if ride and ride ~= "" then
		local fuse = player:GetAttribute("RideFuse")
		table.insert(list, { ride, if fuse ~= "" then fuse else nil })
	end
	local index = player:GetAttribute("Pen")
	local pens = workspace:FindFirstChild("Pens")
	local pen = index and pens and pens:FindFirstChild("Pen" .. index)
	local ok, items = pcall(HttpService.JSONDecode, HttpService, pen and pen:GetAttribute("Contents") or "{}")
	for _, item in if ok and typeof(items) == "table" then items else {} do
		if item.pet then
			table.insert(list, { item.pet, item.fuse })
		end
	end
	return list
end

-- Two of your pets fuse, either way round (the lesson's fuse is free).
local function canFuse()
	local list = yourPets()
	for i = 1, #list do
		for j = 1, #list do
			local a, b = list[i], list[j]
			if i ~= j and Fusion.combine(a[1], a[2], b[1], b[2]) then
				return true
			end
		end
	end
	return false
end

local function hybrids()
	local n = 0
	for _, pet in yourPets() do
		if pet[2] then
			n += 1
		end
	end
	return n
end

-- A fusion's pets are being pulled up, or its hybrid dropping down (PenPets).
local function fusing()
	for key in PenPets.merges do
		if PenPets.mergeFor(key) then
			return true
		end
	end
	return false
end

-- The Fuse button pops up big in the middle of the screen with a bounce, then
-- shrinks as it flies to its spot in the HUD, where the real one then shows.
local function reveal()
	local icon = Hud.fuseButton()
	local size = icon.AbsoluteSize -- (laid out while hidden)
	if size.X >= 1 then
		local fly = Instance.new("ImageLabel")
		fly.Name = "FuseReveal"
		fly.BackgroundTransparency = 1
		fly.Image = icon.Image
		fly.AnchorPoint = Vector2.new(0.5, 0.5)
		fly.Position = UDim2.fromScale(0.5, 0.5)
		fly.Size = UDim2.fromOffset(size.X * REVEAL.Big, size.Y * REVEAL.Big)
		local grow = Instance.new("UIScale")
		grow.Scale = 0
		grow.Parent = fly
		fly.Parent = gui
		local pop = TweenService:Create(grow, TweenInfo.new(REVEAL.Pop, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
		pop:Play()
		pop.Completed:Wait()
		task.wait(REVEAL.Hold)
		local at = icon.AbsolutePosition + size / 2 - gui.AbsolutePosition
		local go = TweenService:Create(fly, TweenInfo.new(REVEAL.Fly, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
			Position = UDim2.fromOffset(at.X, at.Y),
			Size = UDim2.fromOffset(size.X, size.Y),
		})
		go:Play()
		go.Completed:Wait()
		running = "guide" -- the real one shows (update's stage)
		task.wait(0.05)
		fly:Destroy()
	end
	running = "guide"
end

local function finish()
	running, finished = nil, true
	player:SetAttribute("FuseLesson", nil) -- (here at once, so Fuse stays on show: Hud.fuseUnlocked)
	ReplicatedStorage:WaitForChild("FuseLessonDone"):FireServer()
	if FuseLesson.done then
		task.spawn(FuseLesson.done)
	end
end

player:GetAttributeChangedSignal("FuseLesson"):Connect(function()
	if player:GetAttribute("FuseLesson") then
		finished = false -- (again: /fuselesson)
	end
end)

-- Every frame, from Tutorial.update while the first-time tutorial's off: the HUD
-- stage to show ("bare" while the button flies in, "fuse" while it leads, nil when
-- it's not on) and the cursor's target, if any. `phase` is Ride's; `cutscene`, a
-- close-up's on.
local function step(phase, cutscene)
	local fused = running and Hud.fusedAt and Hud.fusedAt >= from -- (the server's ended it then: its fuse is the free one)
	-- (speed gates: it's due from the tutorial's end, before the Desert)
	if finished or not (player:GetAttribute("FuseLesson") or fused) or ((player:GetAttribute("PenLevel") or 1) < 2 and not SpeedGates.on()) then
		running = nil
		return nil, nil
	elseif phase ~= "idle" or cutscene or camera.CameraType ~= Enum.CameraType.Custom then
		return nil, nil -- out on a ride, or the gate's breaking open on camera: when you're back
	elseif not running then
		if not canFuse() then
			return nil, nil -- till you have two pets that can fuse
		end
		running, from, before = "reveal", os.clock(), hybrids()
		task.spawn(reveal)
		return "bare", nil
	elseif running == "reveal" then
		return "bare", nil
	end
	local at = Hud.fusedAt
	if at and at >= from then
		if not fusing() and (hybrids() > before or os.clock() > at + GIVE_UP) then
			finish() -- the hybrid's landed
			return nil, nil
		end
		return "fuse", nil -- (watching it fuse)
	end
	local target = Hud.fuseGuide and Hud.fuseGuide()
	if target == false and not canFuse() then
		finish() -- nothing left that can fuse after all
		return nil, nil
	end
	return "fuse", if target == nil then Hud.fuseButton() else (target or nil)
end

function FuseLesson.update(phase, cutscene)
	local stage, cursor = step(phase, cutscene)
	Hud.setLesson(stage ~= nil) -- nothing but Fuse while it's on (QM, Oct 7)
	return stage, cursor
end

return FuseLesson
