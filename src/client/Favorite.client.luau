-- Roblox's own "add to favourites" prompt (QM, Oct 13): once, when you're back home from the
-- ride where you first broke World 1's Tundra barrier (GatesBroken reaching 3 mid-ride:
-- Gold.server saves the furthest, so that only happens once), after the new animal's
-- cutscene and with no menu up. Not if the game's already in your favourites (when Roblox
-- lets us check: GetFavorite needs inventory access, so without it the prompt shows anyway).
-- "/favourite" shows it any time (Favorite.server). It's the first world's place either way (the experience's start).
local AvatarEditorService = game:GetService("AvatarEditorService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local Hud = require(script.Parent.Hud)
local player = Players.LocalPlayer

local TUNDRA = 3 -- (Config.Biomes: Meadow, Desert, Snow)
local PLACE = Config.Places[1]

local function prompt()
	pcall(AvatarEditorService.PromptSetFavorite, AvatarEditorService, PLACE, Enum.AvatarItemType.Asset, true)
end

local function busy()
	local base = player.PlayerGui:FindFirstChild("BaseUi")
	local root = base and base:FindFirstChild("Root")
	return Hud.isRiding() or player:GetAttribute("Cutscene") or player:GetAttribute("Tutorial") or Hud.revealing()
		or (root and root:GetAttribute("Modal")) or not (base and base.Enabled)
end

local due = false
if Config.World == 1 then
	local last = player:GetAttribute("GatesBroken") or 1
	player:GetAttributeChangedSignal("GatesBroken"):Connect(function()
		local now = player:GetAttribute("GatesBroken") or 1
		if Hud.isRiding() and last < TUNDRA and now >= TUNDRA then -- (not the save loading in)
			due = true
		end
		last = now
	end)
end

task.spawn(function()
	while true do
		task.wait(0.5)
		if due and not busy() then
			task.wait(1) -- (a beat after you're back)
			if not busy() then
				due = false
				local ok, favourited = pcall(AvatarEditorService.GetFavorite, AvatarEditorService, PLACE, Enum.AvatarItemType.Asset)
				if not (ok and favourited) then
					prompt()
				end
			end
		end
	end
end)

ReplicatedStorage:WaitForChild("PromptFavorite").OnClientEvent:Connect(prompt) -- ("/favourite": Favorite.server)
