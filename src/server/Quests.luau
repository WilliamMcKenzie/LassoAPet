-- Quests (QM, Oct 11; Config.Quests): two questlines, each showing its next quest.
-- Hatchery keeps each player's in their profile, saved with the pen:
--   { lines = { [line] = { at = its quest up (past the end: done) } }, counts = { lasso = n, merge = n, ["lasso:Snowman"] = n }, v = 3 }  (skip: a quest already claimed, passed over)
-- and puts what's up on the player as the "Quests" attribute for BaseUi: JSON of
-- { { i, text, have, need, kind, biome } }, i = line * 100 + the quest's place in it (ClaimQuest's).
-- Progress is the player's own, live (QM, Oct 11), not counted from when the quest came
-- up: barriers broken, lassos landed (all, or on one kind: a quest's Animal) and merges
-- ever (from Oct 11), and "home" the pen's count right now (it goes down with a merge).

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Funnel = require(script.Parent.Funnel)

local COUNTS = { lasso = true, merge = true, invite = true }

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
	local v = typeof(saved) == "table" and tonumber(saved.v) or 1
	for line, quests in Config.Quests do
		local was = typeof(lines[line]) == "table" and lines[line] or {}
		local at = math.floor(tonumber(was.at) or 1)
		if v < 2 and line == 1 and at > 1 then
			at += 1
		end
		local skip = typeof(was.skip) == "number" and was.skip or nil -- (already claimed, passed over when it comes up)
		-- (saved before Merge went before Collect in line 2, QM Oct 12: Collect claimed but
		-- not Merge, back to Merge, and Collect passed over after it)
		if v < 3 and line == 2 and at == 3 then
			at, skip = 2, 3
		end
		-- (the Rebirth goal, last, is never passed: QM Nov 7; a save past the end before it came
		-- in waits at it)
		local last = if quests[#quests] and quests[#quests].Kind == "rebirth" then #quests else #quests + 1
		state.lines[line] = { at = math.clamp(at, 1, last), skip = skip }
	end
	-- (World 1's goals became one line, QM Nov 6: saves from before it start that line over)
	if v < 4 and Config.World == 1 then
		state.lines = { { at = 1 } }
	end
	state.v = 4
	-- (QM, Nov 7: a goal's egg only the first time; `given` = { ["line.k"] = true }, the goals
	-- already claimed once. Saved before it: everything before where each line is up)
	state.given = {}
	if typeof(saved) == "table" and typeof(saved.given) == "table" then
		for key, on in saved.given do
			if type(key) == "string" and on == true then
				state.given[key] = true
			end
		end
	else
		for line, slot in state.lines do
			for k = 1, slot.at - 1 do
				state.given[line .. "." .. k] = true
			end
		end
	end
	return state
end

local function progress(player, state, quest)
	if quest.Kind == "reach" then
		return if (player:GetAttribute("GatesBroken") or 1) >= quest.Biome then 1 else 0, 1
	end
	if quest.Kind == "rebirth" then -- (QM, Nov 7: done once you've reached the last biome; claimed by Quests.rebirth)
		return if (player:GetAttribute("GatesBroken") or 1) >= quest.Biome then 1 else 0, 1
	end
	if quest.Kind == "slingshot" then -- (the Slingshot's menu has unlocked Biome: your pen level's up to it)
		return if (player:GetAttribute("PenLevel") or 1) >= quest.Biome then 1 else 0, 1
	end
	if quest.Kind == "lasso" and quest.Biome and not quest.Animal then -- (lassos on any of that biome's herd)
		local n = 0
		for animal, weight in (Config.Biomes[quest.Biome] or {}).Herd or {} do
			if weight > 0 then
				n += state.counts["lasso:" .. animal] or 0
			end
		end
		return math.min(n, quest.Need), quest.Need
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
		-- (a quest that's Off, Config.NativeUi's Merge: passed over, as if claimed)
		while quests[slot.at] and quests[slot.at].Off do
			slot.at += 1
			if slot.skip == slot.at then
				slot.at += 1
			end
		end
		local quest = quests[slot.at]
		if quest then
			local have, need = progress(player, state, quest)
			table.insert(list, { i = line * 100 + slot.at, text = quest.Text, have = have, need = need, kind = quest.Kind, biome = quest.Biome or (quest.Animal and biomeOf(quest.Animal)) })
		end
	end
	player:SetAttribute("Quests", HttpService:JSONEncode(list))
	Funnel.quests(player, list) -- (Analytics V1: Quest Claims, Quest Progress)
	player:SetAttribute("MergeFree", if (state.counts.merge or 0) == 0 then true else nil) -- (your first merge is free: QM, Oct 11)
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

-- Claims quest i (as published) if it's up and finished: returns it (Config.Quests') and
-- whether it's the first time it's been claimed, or nil.
function Quests.claim(player, state, i)
	local line, at = i // 100, i % 100
	local slot = state.lines[line]
	local quest = slot and slot.at == at and Config.Quests[line][at]
	if not quest then
		return nil
	end
	local have, need = progress(player, state, quest)
	if have < need or quest.Kind == "rebirth" then -- (Rebirth: only its popup's confirm, Quests.rebirth)
		return nil
	end
	local slot = state.lines[line]
	local nextAt = at + 1
	if slot.skip == nextAt then -- (claimed before the line's order changed: Quests.load)
		nextAt += 1
	end
	state.lines[line] = { at = nextAt }
	state.given = state.given or {}
	local first = not state.given[line .. "." .. at] -- (its egg only the first time: QM, Nov 7)
	state.given[line .. "." .. at] = true
	Quests.publish(player, state)
	return quest, first
end

-- "/skipgoal N" (QM, Nov 7; Hatchery's): each line's next n goals passed over, no rewards, never
-- past the Rebirth goal. Returns the goal now up in the first line (its Text), or nil.
function Quests.skip(player, state, n)
	for line, quests in Config.Quests do
		local slot = state.lines[line]
		for _ = 1, n do
			local quest = quests[slot.at]
			if not quest or quest.Kind == "rebirth" then
				break
			end
			slot.at += 1
		end
		slot.skip = nil
	end
	Quests.publish(player, state)
	local first = Config.Quests[1] and Config.Quests[1][state.lines[1].at]
	return first and first.Text
end

-- The Rebirth goal (Config.Quests' "rebirth"), if it's up and done: every line back to its
-- Loop goal (else its first). True if it was (Hatchery's Rebirth then does the rest).
function Quests.rebirth(player, state)
	for line, quests in Config.Quests do
		local slot = state.lines[line]
		local quest = slot and quests[slot.at]
		if quest and quest.Kind == "rebirth" then
			local have, need = progress(player, state, quest)
			if have < need then
				return false
			end
			-- (QM, Nov 7: a jump back to the line's label, its goal marked Loop, "Reach Desert":
			-- the first goals aren't done again; a line without one starts over)
			for l, goals in Config.Quests do
				local at = 1
				for k, goal in goals do
					if goal.Loop then
						at = k
						break
					end
				end
				state.lines[l] = { at = at }
			end
			return true
		end
	end
	return false
end

return Quests
