-- FUSE (QM, Oct 6): two of your pets of different kinds become one hybrid. The rarer
-- one is the base: its model, animations and ability. The other one, the donor,
-- sets its size (a Pig donor makes a tiny Loong, a Loong donor a giant Pig) and
-- paints it in its own colours, slot for slot (Shared/Palettes). It earns what both
-- earned. Two of the same hybrid merge like any other pets (Shared/Merge).
--
-- A pen item or the ridden pet keeps its base in `pet` (or `ride`) as before, and
-- the donor in `fuse`; what it earns a second is in `income`.
--
--   Fusion.key(kind, fuse)        "Loong:Pig", or just the kind for a plain pet
--   Fusion.split(key)             kind, fuse
--   Fusion.order(a, b)            base, donor: the rarer one is the base
--   Fusion.scale(kind, fuse)      how much bigger (or smaller) the donor makes it
--   Fusion.name(kind, fuse)       "Loong x Pig"
--   Fusion.paint(model, kind, fuse)  repaints a built model in the donor's palette

local Config = require(script.Parent.Config)
local Palettes = require(script.Parent.Palettes)

local Fusion = {}

local RARITIES = { "Common", "Uncommon", "Rare", "Epic", "Legendary" }

local function rgbKey(r, g, b)
	return r * 65536 + g * 256 + b
end

-- [kind] = { slots = { [rgb key] = slot }, base = { [slot] = Color3 }, parts = { [name] = slot } }
local sorted = {}
for kind, list in Palettes do
	local s = { slots = {}, base = {}, parts = list.parts or {} }
	for _, entry in ipairs(list) do
		local slot, r, g, b = entry[1], entry[2], entry[3], entry[4]
		s.slots[rgbKey(r, g, b)] = slot
		s.base[slot] = s.base[slot] or Color3.fromRGB(r, g, b)
	end
	sorted[kind] = s
end

function Fusion.key(kind, fuse)
	return if fuse then kind .. ":" .. fuse else kind
end

function Fusion.split(key)
	local kind, fuse = string.match(key, "^([^:]+):(.+)$")
	if kind then
		return kind, fuse
	end
	return key, nil
end

local function rarityRank(kind)
	local Animals = script.Parent.Animals
	local module = Animals:FindFirstChild(kind)
	local ok, class = pcall(require, module)
	return ok and class and table.find(RARITIES, class.Rarity) or 0
end

-- The rarer one is the base (QM); between equals, the one that earns more.
function Fusion.order(a, b)
	local ra, rb = rarityRank(a), rarityRank(b)
	if rb > ra or (rb == ra and (Config.PetIncome[b] or 0) > (Config.PetIncome[a] or 0)) then
		return b, a
	end
	return a, b
end

-- The donor's size tier stands in for the base's: each tier is Config.TierGrowth
-- bigger than the one below, so a Loong (tier 4) with a Pig donor (tier 1) is
-- 1.6^3 = 4x smaller.
function Fusion.scale(kind, fuse)
	if not fuse then
		return 1
	end
	local from, to = Config.PetTiers[kind] or 1, Config.PetTiers[fuse] or 1
	return Config.TierGrowth ^ (to - from)
end

local function spaced(kind)
	return (string.gsub(kind, "(%l)(%u)", "%1 %2"))
end

function Fusion.name(kind, fuse)
	return if fuse then spaced(kind) .. " x " .. spaced(fuse) else spaced(kind)
end

-- The donor's colour for a slot it doesn't have, made from the ones it does.
local function lighter(c, f)
	return c:Lerp(Color3.new(1, 1, 1), f)
end
local function darker(c, f)
	return c:Lerp(Color3.new(0, 0, 0), f)
end
local function donorColor(base, slot)
	if base[slot] then
		return base[slot]
	end
	local body = base.Body or Color3.fromRGB(200, 200, 200)
	if slot == "Belly" then
		return lighter(body, 0.55)
	elseif slot == "Marking" then
		return darker(body, 0.35)
	elseif slot == "Accent" then
		return if base.Marking then lighter(base.Marking, 0.3) else lighter(body, 0.3)
	elseif slot == "Horn" then
		return base.Hoof or lighter(body, 0.6)
	elseif slot == "Hoof" then
		return base.Horn or darker(body, 0.5)
	end
	return body
end

-- A shade of the base's slot colour `from` (`c`) moved onto the donor's `to`: as
-- much darker or lighter, as much more or less saturated, and a hue nudge if it
-- was only a nudge (a bigger jump in hue is a different colour, and takes the
-- donor's).
local function shade(c, from, to)
	if c == from then
		return to
	end
	local h, s, v = c:ToHSV()
	local h0, s0, v0 = from:ToHSV()
	local h1, s1, v1 = to:ToHSV()
	local dh = (h - h0 + 0.5) % 1 - 0.5
	local hue = (h1 + (if math.abs(dh) < 0.08 then dh else 0)) % 1
	local sat = if s0 > 0.05 then s1 * s / s0 else s1 + (s - s0)
	local val
	if v <= v0 then
		val = v1 * (if v0 > 0 then v / v0 else 1)
	else
		val = v1 + (1 - v1) * (v - v0) / math.max(1 - v0, 0.01)
	end
	return Color3.fromHSV(hue, math.clamp(sat, 0, 1), math.clamp(val, 0, 1))
end

local function round(c)
	return math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5)
end

-- What `color` (one of `kind`'s, on a part called `name`) becomes in `fuse`'s palette.
function Fusion.recolor(kind, fuse, name, color)
	local own, donor = sorted[kind], sorted[fuse]
	if not own or not donor then
		return color
	end
	local slot = own.parts[name] or own.slots[rgbKey(round(color))]
	if not slot or slot == "Fixed" then
		return color
	end
	local from = own.base[slot] or color
	return shade(color, from, donorColor(donor.base, slot))
end

-- Repaints a model built from `kind` (Rig.fromData's parts, and the stud textures
-- tinted to match) in `fuse`'s palette. Every part keeps its original colour in
-- the "BaseColor" attribute, so painting again (another donor) starts from it; no
-- donor puts its own colours back.
function Fusion.paint(model, kind, fuse)
	if not model then
		return
	end
	for _, part in model:GetDescendants() do
		local original = part:IsA("BasePart") and (part:GetAttribute("BaseColor") or (fuse and part.Color))
		if original then
			part:SetAttribute("BaseColor", original)
			local color = if fuse then Fusion.recolor(kind, fuse, part.Name, original) else original
			for _, texture in part:GetChildren() do
				if texture:IsA("Texture") and texture.Color3 == part.Color then -- (only the metal weld's is tinted to match)
					texture.Color3 = color
				end
			end
			part.Color = color
		end
	end
end

return Fusion
