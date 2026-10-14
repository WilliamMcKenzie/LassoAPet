-- Multiplayer rides: each ride runs on its rider's own client (Ride.client),
-- which tells the server where it is and what happens on it, and the server
-- passes that on to everyone else, who draw that rider on their own screen.
--
--   RideSync (unreliable, ~10 a second while riding):
--     client -> server  kind, mountCFrame, riderCFrame, speed, scale, lasso
--     server -> others  player, kind, mountCFrame, riderCFrame, speed, scale, lasso
--     (kind "" = not on an animal right now: lassoed across, thrown off;
--     lasso "swing" over the head, "twirl" a caught egg, or "")
--   RideCue (reliable, now and then):
--     client -> server  what, ...
--     server -> others  player, what, ...
--     what: "take" key (jumped on or reeled in stampede animal key), "lasso" key,
--     "knock" key dx, "smash" x z dir side, "ability" kind, "crash" from yaw dir side, "end",
--     "boss" kind x z (their ride's boss popped up in front of them: Client/RemoteBosses)
--   "out" (client -> server only): the ride set off on the rider's own pet, so it's
--     left their pen. It sets the player's "PetOut" attribute until "end", and
--     Pen.client stops drawing that pet in their pen for everyone else meanwhile.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local rideSync = Instance.new("UnreliableRemoteEvent")
rideSync.Name = "RideSync"
rideSync.Parent = ReplicatedStorage

local rideCue = Instance.new("RemoteEvent")
rideCue.Name = "RideCue"
rideCue.Parent = ReplicatedStorage

local CUES = { take = true, lasso = true, knock = true, smash = true, ability = true, crash = true, ["end"] = true, boss = true }
local MAX_SYNC_RATE = 20 -- a second: anything faster is dropped

local lastSync = {} -- [player] = os.clock() of their last passed-on sync

local function toOthers(remote, from, ...)
	for _, other in Players:GetPlayers() do
		if other ~= from then
			remote:FireClient(other, from, ...)
		end
	end
end

rideSync.OnServerEvent:Connect(function(player, kind, mountCFrame, riderCFrame, speed, scale, lasso)
	if type(kind) ~= "string" or #kind > 32 or typeof(mountCFrame) ~= "CFrame" or typeof(riderCFrame) ~= "CFrame" then
		return
	end
	local now = os.clock()
	if now - (lastSync[player] or 0) < 1 / MAX_SYNC_RATE then
		return
	end
	lastSync[player] = now
	toOthers(rideSync, player, kind, mountCFrame, riderCFrame, tonumber(speed) or 0, tonumber(scale) or 1,
		if lasso == "swing" or lasso == "twirl" then lasso else "")
end)

rideCue.OnServerEvent:Connect(function(player, what, ...)
	-- "Lassoing" from the throw till they're on it (or off the ride): no egg can be
	-- taken meanwhile (Nests.server; QM, Oct 8: taps in the HOLD ON! struggle took one).
	if what == "lasso" then
		player:SetAttribute("Lassoing", true)
	elseif what == "landed" or what == "crash" or what == "end" then
		player:SetAttribute("Lassoing", nil)
	end
	if what == "landed" then
		return -- (just for that)
	elseif what == "out" then
		player:SetAttribute("PetOut", true)
		return
	elseif what == "end" then
		player:SetAttribute("PetOut", nil)
	end
	if type(what) == "string" and CUES[what] then
		toOthers(rideCue, player, what, ...)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	lastSync[player] = nil
	toOthers(rideCue, player, "end")
end)
