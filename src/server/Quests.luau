-- Quests (QM, Oct 11; Config.Quests): two questlines, each showing its next quest.
-- Hatchery keeps each player's in their profile, saved with the pen:
--   { lines = { [line] = { at = its quest up (past the end: done) } }, counts = { lasso = n, merge = n } }
-- and puts what's up on the player as the "Quests" attribute for BaseUi: JSON of
-- { { i, text, have, need, kind, biome } }, i = line * 100 + the quest's place in it (ClaimQuest's).
-- Progress is the player's own, live (QM, Oct 11), not counted from when the quest came
-- up: barriers broken, lassos landed and merges ever (from Oct 11), and "home" the pen's
-- count right now (Hatchery's PetCount: it goes down again with a merge).

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local COUNTS = { lasso = true, merge = true }

local Quests = {}

-- A player's quests from their save (nil, or saved before the questlines: from the start).
function Quests.load(saved)
	local state = { lines = {}, counts = {} }
	local lines = typeof(saved) == "table" and typeof(saved.lines) == "table" and saved.lines or {}
	for kind in COUNTS do
		state.counts[kind] = math.max(0, math.floor(tonumber(typeof(saved) == "table" and saved.counts and saved.counts[kind]) or 0))
	end
	for line, quests in Config.Quests do
		local was = typeof(lines[line]) == "table" and lines[line] or {}
		state.lines[line] = { at = math.clamp(math.floor(tonumber(was.at) or 1), 1, #quests + 1) }
	end
	return state
end

local function progress(player, state, quest)
	if quest.Kind == "reach" then
		return if (player:GetAttribute("GatesBroken") or 1) >= quest.Biome then 1 else 0, 1
	end
	return math.min(state.counts[quest.Kind] or 0, quest.Need), quest.Need
end

function Quests.publish(player, state)
	local list = {}
	for line, quests in Config.Quests do
		local slot = state.lines[line]
		local quest = quests[slot.at]
		if quest then
			local have, need = progress(player, state, quest)
			table.insert(list, { i = line * 100 + slot.at, text = quest.Text, have = have, need = need, kind = quest.Kind, biome = quest.Biome })
		end
	end
	player:SetAttribute("Quests", HttpService:JSONEncode(list))
end

-- One more lasso landed ("lasso") or merge ("merge").
function Quests.count(player, state, kind)
	state.counts[kind] = (state.counts[kind] or 0) + 1
	Quests.publish(player, state)
end

-- The pen's count now ("home": Hatchery, whenever the pen changes).
function Quests.penCount(player, state, n)
	state.counts.home = n
	Quests.publish(player, state)
end

-- Claims quest i (as published) if it's up and finished: returns it (Config.Quests'), or nil.
function Quests.claim(player, state, i)
	local line, at = i // 100, i % 100
	local slot = state.lines[line]
	local quest = slot and slot.at == at and Config.Quests[line][at]
	if not quest then
		return nil
	end
	local have, need = progress(player, state, quest)
	if have < need then
		return nil
	end
	state.lines[line] = { at = at + 1 }
	Quests.publish(player, state)
	return quest
end

return Quests
