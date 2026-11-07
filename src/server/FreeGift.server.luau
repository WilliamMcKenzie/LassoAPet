-- (Ported from Fight to Steal an Egg, QM Nov 7.) The free gift's Claim (Client/FreeReward is its
-- popup, Shared/GiftModel the present): Config.FreeGift.Luck luck (LuckBonus) and .Cash cash
-- (Gold), once per player. Saved as the player attribute FreeGift (Gold.server keeps it as
-- `gift`, and saves the moment it's set). Also builds the present at Config.FreeGift's spot.
--
-- Of the popup's three steps only the group can be checked (Roblox doesn't tell a game who
-- liked or favorited it): the server checks you're in the group (Config.FreeGift.GroupId, or
-- the one that owns the game) and by the gift.
--
--   FreeGiftClaim (RemoteFunction) -> ok, why   -- (why: "claimed", "far", "group", "busy")

local GroupService = game:GetService("GroupService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local GiftModel = require(Shared.GiftModel)
local MapData = require(Shared.MapData)
local MapFile = require(Shared.MapFile)

local busy = {} -- [player] = true while a Claim is being checked

local function groupId()
	local s = Config.FreeGift
	if s.GroupId then
		return s.GroupId
	end
	return if game.CreatorType == Enum.CreatorType.Group then game.CreatorId else nil
end

-- in the group? (GroupService asks Roblox fresh: Player:IsInGroup remembers the answer from
-- when they joined the server, so it'd miss a group joined from the popup)
local function inGroup(player, id)
	local ok, groups = pcall(GroupService.GetGroupsAsync, GroupService, player.UserId)
	if ok and type(groups) == "table" then
		for _, g in groups do
			if g.Id == id then
				return true
			end
		end
		return false
	end
	local ok2, member = pcall(player.IsInGroup, player, id)
	return ok2 and member == true
end

local function near(player)
	local s = Config.FreeGift
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end
	local away = (root.Position - Vector3.new(s.X, root.Position.Y, s.Z)).Magnitude
	return away <= s.Reach
end

local function claim(player)
	local s = Config.FreeGift
	if player:GetAttribute("FreeGift") then
		return false, "claimed"
	end
	if not player:GetAttribute("GoldLoaded") then
		return false, "busy" -- (their save isn't in yet: it may say they already have)
	end
	if busy[player] then
		return false, "busy"
	end
	if not near(player) then
		return false, "far"
	end
	busy[player] = true
	local id = groupId()
	local member = not id or inGroup(player, id)
	busy[player] = nil
	if not member then
		return false, "group"
	end
	if player.Parent == nil or player:GetAttribute("FreeGift") then
		return false, "claimed"
	end
	player:SetAttribute("LuckBonus", (player:GetAttribute("LuckBonus") or 0) + s.Luck)
	player:SetAttribute("Gold", (player:GetAttribute("Gold") or 0) + s.Cash)
	player:SetAttribute("FreeGift", true) -- (last: setting it saves, Gold.server)
	return true
end

-- the present, at Config.FreeGift's spot, on the ground there (built fresh on every start)
local function build()
	local s = Config.FreeGift
	local old = workspace:FindFirstChild("FreeGift")
	if old then
		old:Destroy()
	end
	local model = GiftModel.build()
	if s.Scale and s.Scale ~= 1 then
		model:ScaleTo(s.Scale)
	end
	local y = MapFile.groundAt(MapData, s.X, s.Z)
	model:PivotTo(CFrame.new(s.X, y, s.Z) * CFrame.Angles(0, math.rad(s.Yaw or 0), 0))
	model.Parent = workspace
end

local remote = Instance.new("RemoteFunction")
remote.Name = "FreeGiftClaim"
remote.OnServerInvoke = claim
remote.Parent = ReplicatedStorage
build()
Players.PlayerRemoving:Connect(function(player)
	busy[player] = nil
end)
