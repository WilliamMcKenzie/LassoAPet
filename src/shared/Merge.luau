-- Merged pets (QM, Oct 4): with two or more pets of one kind, MERGE turns them all
-- into one pet of that kind (Hatchery.server's MergePets). A pet merged from n pets
-- (its "merged" count; 1 = a plain pet) is Config.MergeGrowth^(n - 1) x bigger, x
-- more stamina and x faster: bigger only up to XL, faster only up to
-- Config.MergeMaxSpeed (its Speed stat after the boost, Config.AnimalStats), and
-- stamina without a cap. It earns its gold a second n times over, so merging never
-- loses income.

local Config = require(script.Parent.Config)

local Merge = {}

local function boost(n)
	return Config.MergeGrowth ^ math.max((n or 1) - 1, 0)
end

-- Scale for a pet of `kind` merged from n (1 = its own size).
function Merge.size(kind, n)
	local max = Config.TierGrowth ^ math.max(4 - (Config.PetTiers[kind] or 1), 0) -- XL
	return math.max(1, math.min(boost(n), max))
end

-- What its speed is multiplied by.
function Merge.speed(kind, n)
	local base = (Config.AnimalStats[kind] or {}).Speed or 1
	return math.max(1, math.min(base * boost(n), Config.MergeMaxSpeed) / base)
end

-- What its stamina is multiplied by (no cap).
function Merge.stamina(n)
	return boost(n)
end

return Merge
