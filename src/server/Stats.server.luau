-- /stats: fresh session time, first-session quit biomes, monetization exposure/conversion.
-- /stats [today | YYYY-MM-DD | build]; no argument shows all data since this reset.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Stats = require(script.Parent.SimpleStats)
-- Gold.server and Telemetry share this existing biome-unlock signal.
local biomeUnlocked = Instance.new("BindableEvent")
biomeUnlocked.Name = "BiomeUnlocked"
biomeUnlocked.Parent = game:GetService("ServerStorage")

local function allowed(player)
	if RunService:IsStudio() then
		return true
	end
	if game.CreatorType == Enum.CreatorType.User then
		return player.UserId == game.CreatorId
	end
	local success, group = pcall(function()
		return game:GetService("GroupService"):GetGroupInfoAsync(game.CreatorId)
	end)
	return success and group.Owner ~= nil and player.UserId == group.Owner.Id
end

-- /stats ab: the ride egg A/B (Config.RideEggAB; Hatchery records it), each arm's totals.
local function abReport()
	local Store = require(script.Parent.StatsStore)
	local today = os.date("!%Y-%m-%d")
	local lines = { "RIDE EGG A/B (egg: rides give the animal's egg; control: the animal)" }
	for _, arm in { "control", "egg" } do
		local d = Store.readShared("ab-rideegg-" .. arm)
		local sessions, new, back = d.sessions or 0, 0, 0
		for k, n in d do
			local day = string.match(k, "^new:(.+)")
			if day and day < today then -- (today's new players can't have come back yet)
				new += n
				back += d["d1:" .. day] or 0
			end
		end
		table.insert(lines, string.format("  %s: %d sessions, %.1f min each, %d R$ from %d buys (%.0f R$ per 1,000 sessions), day 1 return %s (%d of %d new players)",
			arm, sessions, (d.seconds or 0) / math.max(sessions, 1) / 60, d.robux or 0, d.buys or 0, (d.robux or 0) / math.max(sessions, 1) * 1000,
			if new > 0 then string.format("%.1f%%", back / new * 100) else "N/A", back, new))
	end
	return lines
end

local command = Instance.new("TextChatCommand")
command.Name = "Stats"
command.PrimaryAlias = "/stats"
command.Triggered:Connect(function(source, text)
	local player = Players:GetPlayerByUserId(source.UserId)
	if not player or not allowed(player) then
		return
	end
	local devChat = ReplicatedStorage:WaitForChild("DevChat", 10) -- (Hatchery's: shown only to you)
	if devChat then
		local arg = text:lower():match("^/stats%s+(%S+)")
		local ok, lines = pcall(if arg == "ab" then abReport else Stats.report, arg)
		for _, l in if ok then lines else { "/stats failed: " .. tostring(lines) } do
			devChat:FireClient(player, l)
		end
	end
end)
command.Parent = game:GetService("TextChatService")
