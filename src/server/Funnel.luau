-- Analytics funnels for Creator Hub > Analytics > Funnels.
--
-- Onboarding: a new player's first session, step by step through the tutorial
-- and on to unlocking the Desert. Hatchery calls track() for a player with no
-- save yet; only they're logged, each step once (Roblox also keeps only a
-- player's first of each step). Steps are logged when they happen, so one done
-- out of order still counts. Steps the server can't see (the tutorial's own
-- hints) come from the client over the FunnelStep remote; riding out, the
-- lasso and gold are watched here; the rest are step() calls where they happen
-- (Hatchery, Nests, PenLevel).
--
-- Zones: every player's zone unlocks, one pass per player (the session id is
-- their UserId), so it runs across sessions.
--
-- Shop: each time the shop opens is a pass: opened, picked an offer (the
-- Robux prompt), bought it.
--
-- Rolls and merges are custom events (Analytics > Custom Events), every time.
local AnalyticsService = game:GetService("AnalyticsService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local Funnel = {}

local desert = Config.Biomes[2]
local STEPS = {
	"Joined",
	"Tutorial Started", -- (client)
	"Placed Starter Egg",
	"Starter Pet Ready", -- (client) the starter egg hatched: "Ride your Horse!"
	"Started Ride", -- (client)
	"Rode Out", -- past the start line on an animal
	"Threw Lasso",
	"Landed Lasso", -- (client) on the lassoed animal: "Follow the arrows to the egg!"
	"Egg In Reach", -- (client) "Press E to take the egg!"
	"Grabbed Egg",
	"Turned Home", -- (client)
	"Brought Egg Home",
	"Placed Egg",
	"Egg Hatched",
	"Saw Gate", -- (client) the camera flies to the Desert gate
	"Tutorial Done",
	"Rode Out Again",
	"Brought Egg Home Again",
	"Saved Half For " .. desert.Name,
	"Can Afford " .. desert.Name,
	"Unlocked Zone 2",
}
local stepIndex = {}
for i, name in STEPS do
	stepIndex[name] = i
end
-- The tutorial's steps (Tutorial.luau's setStep names) the client reports.
local CLIENT_STEPS = {
	place = "Tutorial Started",
	ride = "Starter Pet Ready",
	lasso = "Started Ride",
	egg = "Landed Lasso",
	take = "Egg In Reach",
	home = "Turned Home",
	gate = "Saw Gate",
}
-- Done again once the tutorial's over.
local AGAIN = {
	["Rode Out"] = "Rode Out Again",
	["Brought Egg Home"] = "Brought Egg Home Again",
}
local TUTORIAL_DONE = stepIndex["Tutorial Done"]

local logged = {} -- [player] = { [step] = true }, only for players being tracked

function Funnel.step(player, name)
	local done = logged[player]
	local i = stepIndex[name]
	if done and i and done[i] and AGAIN[name] and done[TUTORIAL_DONE] then
		name = AGAIN[name]
		i = stepIndex[name]
	end
	if not done or not i or done[i] then
		return
	end
	done[i] = true
	pcall(AnalyticsService.LogOnboardingFunnelStepEvent, AnalyticsService, player, i, name)
end

local function watchGold(player)
	local function check()
		local gold = player:GetAttribute("Gold") or 0
		if gold >= desert.UnlockCost / 2 then
			Funnel.step(player, "Saved Half For " .. desert.Name)
		end
		if gold >= desert.UnlockCost then
			Funnel.step(player, "Can Afford " .. desert.Name)
		end
	end
	player:GetAttributeChangedSignal("Gold"):Connect(check)
	check()
end

function Funnel.track(player)
	if not logged[player] then
		logged[player] = {}
		Funnel.step(player, "Joined")
		watchGold(player)
	end
end

-- PenLevel: the player's pen went up to `level` (2 is the Desert).
function Funnel.zone(player, level)
	local biome = Config.Biomes[level]
	if biome and level >= 2 then
		pcall(AnalyticsService.LogFunnelStepEvent, AnalyticsService, player, "Zones", tostring(player.UserId), level - 1, "Unlocked " .. biome.Name)
	end
end

function Funnel.event(player, name)
	pcall(AnalyticsService.LogCustomEvent, AnalyticsService, player, name)
end

-- The shop: [player] = { id = its pass's session id, done = { [step] = true } }
-- for the latest time they opened it.
local shopPass = {}
local SHOP_STEPS = { "Opened Shop", "Picked Offer", "Bought" }
local function shopStep(player, i)
	local pass = shopPass[player]
	if pass and not pass.done[i] then
		pass.done[i] = true
		pcall(AnalyticsService.LogFunnelStepEvent, AnalyticsService, player, "Shop", pass.id, i, SHOP_STEPS[i])
	end
end
-- Shop.server: the player asked to buy an offer (2), or paid for one (3).
-- Only counted in a pass that started with the shop open.
function Funnel.shopPicked(player)
	shopStep(player, 2)
end
function Funnel.shopBought(player)
	if shopPass[player] and shopPass[player].done[2] then
		shopStep(player, 3)
	end
end

local funnelStep = Instance.new("RemoteEvent")
funnelStep.Name = "FunnelStep"
funnelStep.OnServerEvent:Connect(function(player, kind, name)
	if kind == "tutorial" and type(name) == "string" and CLIENT_STEPS[name] then
		Funnel.step(player, CLIENT_STEPS[name])
	elseif kind == "shop" then
		local pass = shopPass[player]
		if pass and os.clock() - pass.at < 1 then
			return
		end
		shopPass[player] = { id = HttpService:GenerateGUID(false), done = {}, at = os.clock() }
		shopStep(player, 1)
	end
end)
funnelStep.Parent = ReplicatedStorage

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
	logged[player], shopPass[player] = nil, nil
end)

return Funnel
