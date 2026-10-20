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
		local ok, lines = pcall(Stats.report, text:lower():match("^/stats%s+(%S+)"))
		for _, l in if ok then lines else { "/stats failed: " .. tostring(lines) } do
			devChat:FireClient(player, l)
		end
	end
end)
command.Parent = game:GetService("TextChatService")
