-- While you were away (QM, Oct 3): back after time away, your pets have earned gold
-- meanwhile (the "AwayGold" attribute, Hatchery.server). It goes straight into your
-- cash (QM, Oct 11: no more "While you were away" popup, just give the money):
-- ClaimAway banks it as soon as it's there.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local claimAway = ReplicatedStorage:WaitForChild("ClaimAway")

local function check()
	local total = player:GetAttribute("AwayGold")
	if total and total > 0 then
		claimAway:FireServer()
	end
end
player:GetAttributeChangedSignal("AwayGold"):Connect(check)
check()
