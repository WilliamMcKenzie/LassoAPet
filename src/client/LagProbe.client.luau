-- Studio only: logs each hitch to the Output as "[Lag]", with what happened in the
-- quarter second before it (models, effects and GUIs added, your attributes changing,
-- server events) and the Lua heap either side (a big drop is a garbage collection).
-- Only while the game window runs at full speed: Studio in the background runs at
-- 15 fps, which isn't a hitch. (QM, Oct 11: hitches every few seconds at the base.)

local RunService = game:GetService("RunService")
if not RunService:IsStudio() then
	return
end
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Stats = game:GetService("Stats")

local HITCH = 0.08 -- seconds: a frame this long is logged
local WINDOW = 0.25 -- seconds of events shown before it
local player = Players.LocalPlayer

local recent = {}
local function note(text)
	table.insert(recent, { os.clock(), text })
	if #recent > 200 then
		table.remove(recent, 1)
	end
end

workspace.DescendantAdded:Connect(function(d)
	if d:IsA("Model") or d:IsA("ParticleEmitter") or d:IsA("BillboardGui") or d:IsA("Sound") or d:IsA("Beam") then
		note(d.ClassName .. " " .. d.Name .. " in " .. (if d.Parent then d.Parent.Name else "?"))
	end
end)
player:WaitForChild("PlayerGui").DescendantAdded:Connect(function(d)
	if d:IsA("GuiObject") and d.Parent and not d.Parent:IsA("GuiObject") then
		note("GUI " .. d.Name)
	end
end)
player.AttributeChanged:Connect(function(name)
	note("attribute " .. name)
end)
for _, r in ReplicatedStorage:GetDescendants() do
	if r:IsA("RemoteEvent") then
		r.OnClientEvent:Connect(function()
			note("event " .. r.Name)
		end)
	end
end

local function heap()
	return Stats:GetMemoryUsageMbForTag(Enum.DeveloperMemoryTag.LuaHeap)
end

local start, last, lastHeap = os.clock(), os.clock(), heap()
local ring = {}
RunService.RenderStepped:Connect(function()
	local now = os.clock()
	local dt = now - last
	last = now
	local h = heap()
	table.insert(ring, dt)
	if #ring > 30 then
		table.remove(ring, 1)
	end
	local sorted = table.clone(ring)
	table.sort(sorted)
	local typical = sorted[math.ceil(#sorted / 2)]
	if typical < 0.025 and dt > HITCH and dt < 2 then
		local before = {}
		for _, e in recent do
			if now - e[1] < WINDOW + dt then
				table.insert(before, string.format("%s (%d ms before)", e[2], (now - e[1]) * 1000))
			end
		end
		print(string.format("[Lag] %.1fs in: a %d ms frame; Lua heap %.0f -> %.0f MB; before it: %s",
			now - start, dt * 1000, lastHeap, h, if #before > 0 then table.concat(before, "; ") else "nothing seen"))
	end
	lastHeap = h
end)
