-- Your own pets in your pen, other than the one waiting on its spot (that one is
-- Ride.client's starter). Pen.client keeps the list; Ride.client binds RIDE to
-- the nearest pet, or the one you clicked.
--
-- Merging (QM, Oct 4): Ride.client pulls every pet going into a merge up into one
-- spot MERGE_UP studs over the pen, shrinking them away, and notes it in `merges`.
-- The new, bigger pet (Pen.client's for a pen pet, Ride.client's starter for the one
-- you ride) then pops out up there and drops down: PenPets.drop says how.

local PenPets = {
	pets = {}, -- [model] = { id = pen item id, kind = animal name, merged, fuse = donor of a hybrid, income, stats }
	merges = {}, -- [Fusion.key] = { at = Vector3 up in the air, landAt = os.clock() the new pet pops out }
	starter = nil, -- Ride.client's pet waiting on its spot (its entity: kind, merged, fuse, animal)
	plated = {}, -- [model] = true: pets showing their nameplate (PetPlates.client), which don't pop "+N$"
	others = {}, -- [model] = { kind, merged, fuse, income, stats }: other players' pets in their pens (Pen.client), for their nameplates
}

PenPets.MERGE_UP = 8 -- studs over the pen (2 m)
PenPets.MERGE_PULL = 0.7 -- seconds the pets take to be pulled up and shrink away
local POP = 0.3 -- seconds the new pet takes to pop out to full size, up in the air
local FALL = 0.45 -- seconds it takes to drop to the ground

-- The merge of `kind` that's just happened (the new pet's still to land), if any.
function PenPets.mergeFor(kind)
	local m = PenPets.merges[kind]
	return if m and os.clock() < m.landAt + POP + FALL then m else nil
end

-- `t` seconds after the new pet pops out, dropping from `height` studs: its scale (x
-- its full size), how high it is, and whether it's landed.
function PenPets.drop(t, height)
	if t < POP then
		local a = t / POP
		return 0.2 + 0.8 * (1 - math.exp(-6 * a) * math.cos(9 * a)), height, false -- popping, with an overshoot
	end
	local f = math.min((t - POP) / FALL, 1)
	return 1, height * (1 - f * f), f >= 1 -- falling, faster and faster
end

return PenPets
