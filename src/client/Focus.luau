-- One goal at a time (QM, Oct 13: "never more"): every guide that points the player at
-- something (the tap hands, the big white arrows, the arrow trails on the ground) asks
-- for the focus here, and only the one with the highest priority shows; the others wait
-- till it's done. Same priority: the one that asked first.
--
--   Focus.want(id, on, priority, goal) -- each time a guide wants (or stops wanting) to show;
--                                      -- goal: guides that are one goal together (the arrow
--                                      -- over a thing and the trail to it) show together
--   Focus.has(id)                      -- true while its goal is the one to show
-- (Tap hands are drawn one at a time even within a goal: TapHand.)
--
-- The priorities, highest first (Focus.P):
local Focus = {}

Focus.P = {
	Tutorial = 100, -- the tutorial's hand, arrows and trail
	BuyWorld2 = 80, -- the full World 2 bar's hand
	Travel = 75, -- after buying World 2: the arrow and trail to the portal, Travel's hand
	StarterQuest = 70, -- opening the Quests panel, claiming the starter quest
	Merge = 60, -- the Merge animals quest's hands
	Hand = 50, -- any other tap hand (a quest to claim)
	EggReady = 40, -- the arrow over an egg in your pen that's ready to hatch
	FastestPet = 30, -- after the tutorial, the arrow over your fastest pet till you ride
}

local wanted = {} -- [id] = { priority, order it asked in, goal }
local order = 0

function Focus.want(id, on, priority, goal)
	if not on then
		wanted[id] = nil
	elseif not wanted[id] then
		order += 1
		wanted[id] = { priority or Focus.P.Hand, order, goal or id }
	else
		wanted[id][1], wanted[id][3] = priority or Focus.P.Hand, goal or id
	end
end

function Focus.has(id)
	local mine = wanted[id]
	if not mine then
		return false
	end
	local best
	for _, w in wanted do
		if not best or w[1] > best[1] or (w[1] == best[1] and w[2] < best[2]) then
			best = w
		end
	end
	return best[3] == mine[3]
end

return Focus
