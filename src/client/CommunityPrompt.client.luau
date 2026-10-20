-- After ten online minutes this session, offer the experience's owning community
-- on the next quiet moment at base. Native Roblox UI; never interrupts a ride.
local Players = game:GetService("Players")
local GroupService = game:GetService("GroupService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local Hud = require(script.Parent.Hud)
local player = Players.LocalPlayer
if game.CreatorType ~= Enum.CreatorType.Group or not Config.ShowHud then
	return
end
local telemetry = ReplicatedStorage:WaitForChild("Telemetry")
local function atBase()
	local base = player.PlayerGui:FindFirstChild("BaseUi")
	local root = base and base:FindFirstChild("Root")
	local characterRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	return base
		and base.Enabled
		and root
		and not root:GetAttribute("Modal")
		and characterRoot
		and characterRoot.Position.Z >= 0
		and not Hud.isRiding()
		and not Hud.revealing()
		and not player:GetAttribute("Cutscene")
		and not player:GetAttribute("Tutorial")
		and not player:GetAttribute("MergeHint")
end
local shown, retryAt = false, 0
while not shown do
	task.wait(1)
	if player:GetAttribute("CommunityPromptDue") and os.clock() >= retryAt and atBase() then
		local checked, member = pcall(player.IsInGroupAsync, player, game.CreatorId)
		-- Membership lookup yields: recheck the base before opening a modal.
		if checked and atBase() then
			local ok = true
			if not member then
				local before = player:GetAttribute("Cutscene")
				player:SetAttribute("Cutscene", true)
				ok = pcall(GroupService.PromptJoinAsync, GroupService, game.CreatorId)
				player:SetAttribute("Cutscene", before)
			end
			if ok then
				shown = true
				telemetry:FireServer("communityPromptShown")
			end
		end
		retryAt = os.clock() + 30
	end
end
