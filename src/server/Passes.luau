-- Game passes (Config.Passes; QM, Oct 7): which ones each player owns. On join each
-- pass is checked once (UserOwnsGamePassAsync) and an owned one sets the player's
-- "Pass<Key>" attribute, which everything else reads (Gold.server, Hatchery, PenLevel,
-- Pens, Vip). Buying one in game sets it on the spot. The client asks to buy with
-- BuyPass (Shop): a pass with no Id yet is free in Studio, for the session, and not
-- offered live.
--
--   Passes.owns(player, key)   -- true if owned (waits for the join check)
--   Passes.onBought(fn)        -- fn(player, key) when a pass is bought in game

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)

local Passes = {}

local byKey, byId = {}, {} -- [Key] = pass; [Id] = pass
for _, pass in Config.Passes do
	byKey[pass.Key] = pass
	if pass.Id ~= 0 then
		byId[pass.Id] = pass
	end
end

local checked = {} -- [player] = true once the join check is done
local bought = {} -- listeners

local function grant(player, pass, fresh)
	if player:GetAttribute("Pass" .. pass.Key) then
		return
	end
	player:SetAttribute("Pass" .. pass.Key, true)
	if fresh then
		for _, fn in bought do
			task.spawn(fn, player, pass.Key)
		end
	end
end

local function check(player)
	for _, pass in Config.Passes do
		if pass.Id ~= 0 then
			for attempt = 1, 3 do
				local ok, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, pass.Id)
				if ok then
					if owns and player.Parent then
						grant(player, pass, false)
					end
					break
				end
				task.wait(attempt)
			end
		end
	end
	checked[player] = true
end

function Passes.owns(player, key)
	for _ = 1, 40 do -- (at most 10 s for the join check)
		if checked[player] or not player.Parent then
			break
		end
		task.wait(0.25)
	end
	return player:GetAttribute("Pass" .. key) == true
end

function Passes.onBought(fn)
	table.insert(bought, fn)
end

Players.PlayerAdded:Connect(check)
for _, player in Players:GetPlayers() do
	task.spawn(check, player)
end
Players.PlayerRemoving:Connect(function(player)
	checked[player] = nil
end)

local buyPass = Instance.new("RemoteEvent")
buyPass.Name = "BuyPass"
buyPass.OnServerEvent:Connect(function(player, key)
	local pass = typeof(key) == "string" and byKey[key]
	if not pass or player:GetAttribute("Pass" .. pass.Key) then
		return
	end
	if pass.Id ~= 0 then
		MarketplaceService:PromptGamePassPurchase(player, pass.Id)
	elseif RunService:IsStudio() then
		grant(player, pass, true)
	end
end)
buyPass.Parent = ReplicatedStorage

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, id, purchased)
	local pass = byId[id]
	if purchased and pass and player.Parent then
		grant(player, pass, true)
	end
end)

return Passes
