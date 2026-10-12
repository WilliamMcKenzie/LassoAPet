-- Quests (QM, Oct 11; Config.Quests): two questlines, each showing its next quest.
-- Hatchery keeps each player's in their profile, saved with the pen:
--   { lines = { [line] = { at = its quest up (past the end: done) } }, counts = { lasso = n, merge = n, ["lasso:Snowman"] = n }, v = 2 }
-- and puts what's up on the player as the "Quests" attribute for BaseUi: JSON of
-- { { i, text, have, need, kind, biome } }, i = line * 100 + the quest's place in it (ClaimQuest's).
-- Progress is the player's own, live (QM, Oct 11), not counted from when the quest came
-- up: barriers broken, lassos landed (all, or on one kind: a quest's Animal) and merges
-- ever (from Oct 11), and "home" the pen's count right now (it goes down with a merge).

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local COUNTS = { lasso = true, merge = true }

local Quests = {}

-- A player's quests from their save (nil, or saved before the questlines: from the start).
function Quests.load(saved)
	local state = { lines = {}, counts = {} }
	local lines = typeof(saved) == "table" and typeof(saved.lines) == "table" and saved.lines or {}
	local counts = typeof(saved) == "table" and typeof(saved.counts) == "table" and saved.counts or {}
	for kind, n in counts do
		if COUNTS[kind] or (type(kind) == "string" and kind:match("^lasso:")) then
			state.counts[kind] = math.max(0, math.floor(tonumber(n) or 0))
		end
	end
	for kind in COUNTS do
		state.counts[kind] = state.counts[kind] or 0
	end
	-- (saved before "Reach Meadow" went first in line 1, QM Oct 11: past its first quest, one
	-- on, so a Desert already claimed isn't up again)
	local old = typeof(saved) == "table" and (tonumber(saved.v) or 1) < 2
	for line, quests in Config.Quests do
		local was = typeof(lines[line]) == "table" and lines[line] or {}
		local at = math.floor(tonumber(was.at) or 1)
		if old and line == 1 and at > 1 then
			at += 1
		end
		state.lines[line] = { at = math.clamp(at, 1, #quests + 1) }
	end
	state.v = 2
	return state
end

local function progress(player, state, quest)
	if quest.Kind == "reach" then
		return if (player:GetAttribute("GatesBroken") or 1) >= quest.Biome then 1 else 0, 1
	end
	local count = if quest.Animal then quest.Kind .. ":" .. quest.Animal else quest.Kind
	return math.min(state.counts[count] or 0, quest.Need), quest.Need
end

-- The biome an animal runs in (its hint flies to that barrier), or nil.
local function biomeOf(animal)
	for i, biome in Config.Biomes do
		if biome.Herd and (biome.Herd[animal] or 0) > 0 then
			return i
		end
	end
	return nil
end

function Quests.publish(player, state)
	local list = {}
	for line, quests in Config.Quests do
		local slot = state.lines[line]
		local quest = quests[slot.at]
		if quest then
			local have, need = progress(player, state, quest)
			table.insert(list, { i = line * 100 + slot.at, text = quest.Text, have = have, need = need, kind = quest.Kind, biome = quest.Biome or (quest.Animal and biomeOf(quest.Animal)) })
		end
	end
	player:SetAttribute("Quests", HttpService:JSONEncode(list))
end

-- One more lasso landed ("lasso", on animal) or merge ("merge").
function Quests.count(player, state, kind, animal)
	state.counts[kind] = (state.counts[kind] or 0) + 1
	if type(animal) == "string" then
		local count = kind .. ":" .. animal
		state.counts[count] = (state.counts[count] or 0) + 1
	end
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
