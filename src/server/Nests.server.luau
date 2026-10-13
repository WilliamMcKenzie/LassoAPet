-- The egg you bring home (QM, Oct 8: no more nests). Ride out for Config.RideSeconds
-- (Oct 10: no more stamina), lassoing animals; when it runs out you turn round
-- on whatever you're riding, and its egg is yours once you're over the line. Your
-- Ride.client says which animal (TakeEgg) as it turns; here that's checked against
-- this ride's cues: you must have got on a wild animal (a "lasso" or "take" cue: not
-- the pet you rode out on, which brings no egg). The egg's set as "CarriedEgg", and
-- Hatchery's DeliverEgg takes it in when you're home.
--
-- The course's nest models (World.Nests) are taken out as the server starts: they
-- stay in the place, so turning the nests back on is putting this back.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")


local world = workspace:WaitForChild("World")
local nests = world:FindFirstChild("Nests")
if nests then
	nests.Parent = nil -- (kept here, not destroyed)
end

-- Whether each rider's got on a stampede animal this ride (a "lasso" or "take" cue:
-- they're on a wild animal, not the pet they rode out on), till the ride's "end".
local wild = {} -- [player] = true
ReplicatedStorage:WaitForChild("RideCue").OnServerEvent:Connect(function(player, what)
	if what == "lasso" or what == "take" then
		wild[player] = true
	elseif what == "end" then
		wild[player] = nil
		-- The ride's over: an egg still carried was lost on the way (a crash, Home from
		-- the fail screen). One brought home was handed in first (Hatchery's DeliverEgg,
		-- sent before this), so this only clears a lost one, which otherwise stayed set:
		-- Hatchery would take it as brought home next ride.
		player:SetAttribute("CarriedEgg", nil)
	end
end)
Players.PlayerRemoving:Connect(function(player)
	wild[player] = nil
end)

local takeEgg = Instance.new("RemoteEvent")
takeEgg.Name = "TakeEgg"
takeEgg.Parent = ReplicatedStorage

-- A rider's turned for home on `mount` (the animal their Ride.client says they're on:
-- the stampede is theirs alone, so there's nothing here to check it against), as long
-- as they've got on a wild animal this ride and it's a real animal.
takeEgg.OnServerEvent:Connect(function(player, mount)
	if not wild[player] or player:GetAttribute("Lassoing") or typeof(mount) ~= "string" or mount == ""
		or not ReplicatedStorage.Shared.Animals:FindFirstChild(mount) then
		return
	end
	player:SetAttribute("CarriedEgg", mount) -- theirs once they ride it home (Hatchery)
	player:SetAttribute("CarriedEggScale", nil)
end)
