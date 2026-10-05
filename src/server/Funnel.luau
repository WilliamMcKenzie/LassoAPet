-- New players' first session as an onboarding funnel (Creator Hub > Analytics >
-- Funnels). Hatchery calls track() for a player with no save yet; only they're
-- logged, each step once (Roblox also keeps only a player's first of each step).
-- Steps are logged when they happen, so one done out of order still counts.
-- Riding out and the first lasso are watched here; the rest are step() calls
-- where they happen (Hatchery, Nests, PenLevel).
local AnalyticsService = game:GetService("AnalyticsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Funnel = {}

local STEPS = {
	"Joined",
	"Rode Out", -- past the start line on an animal
	"Threw Lasso",
	"Grabbed Egg",
	"Brought Egg Home",
	"Placed Egg",
	"Egg Hatched",
	"Tutorial Done",
	"Unlocked Zone 2",
}
local stepIndex = {}
for i, name in STEPS do
	stepIndex[name] = i
end

local logged = {} -- [player] = { [step] = true }, only for players being tracked

function Funnel.step(player, name)
	local done = logged[player]
	local i = stepIndex[name]
	if not done or not i or done[i] then
		return
	end
	done[i] = true
	pcall(AnalyticsService.LogOnboardingFunnelStepEvent, AnalyticsService, player, i, name)
end

function Funnel.track(player)
	if not logged[player] then
		logged[player] = {}
		Funnel.step(player, "Joined")
	end
end

task.spawn(function() -- (Riders makes these: don't hold up whoever requires this)
	ReplicatedStorage:WaitForChild("RideSync").OnServerEvent:Connect(function(player, kind, _, riderCFrame)
		if logged[player] and type(kind) == "string" and kind ~= "" and typeof(riderCFrame) == "CFrame" and riderCFrame.Position.Z < 0 then
			Funnel.step(player, "Rode Out")
		end
	end)
	ReplicatedStorage:WaitForChild("RideCue").OnServerEvent:Connect(function(player, what)
		if what == "lasso" then
			Funnel.step(player, "Threw Lasso")
		end
	end)
end)
Players.PlayerRemoving:Connect(function(player)
	logged[player] = nil
end)

return Funnel
