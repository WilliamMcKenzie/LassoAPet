-- Game passes (Config.Passes; QM, Oct 7): which ones each player owns. On join each
-- pass is checked once (UserOwnsGamePassAsync) and an owned one sets the player's
-- "Pass<Key>" attribute, which everything else reads (Gold.server, Hatchery, PenLevel,
-- Pens, Vip). Buying one in game sets it on the spot. The client asks to buy with
-- BuyPass (Shop): a pass with no Id yet is free in Studio, for the session, and not
-- offered live.
-- QM's popups for each pass (PassPopups.client) show at the moments that suit them.
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

-- The game's owner (Config.OwnerPasses false): Roblox has a game's creator own all its
-- passes, so they're skipped for them, to play the game as everyone else does (QM, Oct 9).
local function isOwner(player)
	if game.CreatorType == Enum.CreatorType.User then
		return player.UserId == game.CreatorId
	end
	local ok, group = pcall(function()
		return game:GetService("GroupService"):GetGroupInfoAsync(game.CreatorId)
	end)
	return ok and group.Owner ~= nil and player.UserId == group.Owner.Id
end

local function check(player)
	if not Config.OwnerPasses and isOwner(player) then
		checked[player] = true
		return
	end
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
	if not pass then
		return
	end
	if pass.Id ~= 0 then
		-- (owned too: Roblox's prompt then says you own it, so a tap never does nothing)
		MarketplaceService:PromptGamePassPurchase(player, pass.Id)
	elseif RunService:IsStudio() and not player:GetAttribute("Pass" .. pass.Key) then
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

-- Testing (QM only): "/popup vip|auto|speed|gold" shows that pass's popup now
-- (PassPopups.client), whatever its usual moment.
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

local passPopup = Instance.new("RemoteEvent")
passPopup.Name = "PassPopup"
passPopup.Parent = ReplicatedStorage
local POPUPS = { vip = "VIP", auto = "AutoHatch", speed = "FastHatch", gold = "DoubleGold" }
local popupCommand = Instance.new("TextChatCommand")
popupCommand.Name = "Popup"
popupCommand.PrimaryAlias = "/popup"
popupCommand.Triggered:Connect(function(source, text)
	local player = Players:GetPlayerByUserId(source.UserId)
	local key = POPUPS[string.lower(string.match(text, "^%S+%s+(%S+)") or "")]
	if player and key and allowed(player) then
		passPopup:FireClient(player, key)
	end
end)
popupCommand.Parent = game:GetService("TextChatService")

return Passes
