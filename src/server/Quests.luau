-- Quests (QM, Oct 11; Config.Quests): two up at a time, in the list's order. Hatchery
-- keeps each player's in their profile, saved with the pen:
--   { next = the list's next quest to hand out, slots = { { i = list index, from = count when it came up } },
--     counts = { home = n, merge = n, hatch = n } }
-- and puts the two on the player as the "Quests" attribute for BaseUi: JSON of
-- { { i, text, have, need } }.

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local SLOTS = 2
local COUNTS = { home = true, merge = true, hatch = true }

local Quests = {}

-- Hands out the next quests into any free slots.
local function fill(state)
	while #state.slots < SLOTS and Config.Quests[state.next] do
		local quest = Config.Quests[state.next]
		table.insert(state.slots, { i = state.next, from = state.counts[quest.Kind] or 0 })
		state.next += 1
	end
end

-- A player's quests from their save (nil for a new player: the first two).
function Quests.load(saved)
	local state = { next = 1, slots = {}, counts = {} }
	if typeof(saved) == "table" then
		state.next = math.max(1, math.floor(tonumber(saved.next) or 1))
		for kind in COUNTS do
			state.counts[kind] = math.max(0, math.floor(tonumber(saved.counts and saved.counts[kind]) or 0))
		end
		for _, slot in typeof(saved.slots) == "table" and saved.slots or {} do
			local i = typeof(slot) == "table" and tonumber(slot.i)
			if i and Config.Quests[i] and i < state.next and #state.slots < SLOTS then
				table.insert(state.slots, { i = i, from = math.max(0, tonumber(slot.from) or 0) })
			end
		end
	end
	fill(state)
	return state
end

local function progress(player, state, slot)
	local quest = Config.Quests[slot.i]
	if quest.Kind == "reach" then
		return if (player:GetAttribute("GatesBroken") or 1) >= quest.Biome then 1 else 0, 1
	end
	return math.min((state.counts[quest.Kind] or 0) - slot.from, quest.Need), quest.Need
end

function Quests.publish(player, state)
	local list = {}
	for _, slot in state.slots do
		local have, need = progress(player, state, slot)
		table.insert(list, { i = slot.i, text = Config.Quests[slot.i].Text, have = have, need = need })
	end
	player:SetAttribute("Quests", HttpService:JSONEncode(list))
end

-- One more animal brought home ("home"), merge ("merge") or egg hatched ("hatch").
function Quests.count(player, state, kind)
	state.counts[kind] = (state.counts[kind] or 0) + 1
	Quests.publish(player, state)
end

-- Claims quest i if it's up and finished; true if it was.
function Quests.claim(player, state, i)
	for n, slot in state.slots do
		if slot.i == i then
			local have, need = progress(player, state, slot)
			if have < need then
				return false
			end
			table.remove(state.slots, n)
			fill(state)
			Quests.publish(player, state)
			return true
		end
	end
	return false
end

return Quests
