"""The biomes redecorated with the rock meshes (QM, Oct 10): every old obstacle goes
except Cactus, Pine, TubeCoral, BranchCoral and FanCoral; the rest is five rock meshes
(tools/rock_meshes.py: Pebble, Stone, Slab, Boulder, Crag) in each biome's rock colour.
The Godlands are left alone (QM: going anyway).

Run: python3 tools/biome_rocks.py
Writes tools/biome_rocks.luau (Studio's builder), design/biome_rocks/layout.json and
previews (a top-down plan per biome and a ride view of each).

How a biome is laid out: the first 48 studs clear, then one cluster every 80-stud beat,
alternating walls, hugging the wall (the middle of the path stays open), clear of the
nests. A cluster is one anchor (a boulder, crag or the biome's tree/coral) with a few
small rocks round it; now and then a beat is left empty, so it never reads as a pattern.
"""

import json
import math
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import course_layout as CL  # noqa: E402
import ocean_ground as OG  # noqa: E402
import rock_meshes as RM  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "design", "biome_rocks")
KEEP = ["Cactus", "Pine", "TubeCoral", "BranchCoral", "FanCoral"]

# The rock meshes as uploaded (tools/arc_base.py MESHES), the scale each is used at on
# the course (tier sizes: small ~5.4, medium ~8.6, large ~13.8 studs, Config.TierGrowth),
# and their tier.
MESHES = {"Pebble": 97909332868672, "Stone": 116242154122535, "Slab": 118417030739444,
          "Boulder": 109133145406087, "Crag": 105444261900626}
ROCK_SCALE = {"Pebble": 2.8, "Stone": 2.4, "Slab": 1.9, "Boulder": 2.2, "Crag": 1.7}  # (QM: 2x the tier sizes)
ROCK_TIER = {"Pebble": 1, "Stone": 1, "Slab": 2, "Boulder": 2, "Crag": 3}
ROCK_COLOR = {  # QM, Oct 10 (design/rocks_biomes): the meadow's is the base's Fossil grey
    "Meadow": (159, 161, 172), "Desert": (234, 190, 122), "Snow": (158, 200, 240), "Ocean": (242, 120, 98)}
_built = {n: RM.build(f, s) for n, f, s, _ in RM.ROCKS}


def rock_radius(name):
    pts = np.concatenate([np.concatenate(t) for t in _built["Rock" + name]])
    return float(np.hypot(pts[:, 0], pts[:, 2]).max()) * ROCK_SCALE[name]


for _n in MESHES:  # the rocks join the layout's assets: (footprint radius, tier, kit)
    CL.ASSETS["Rock" + _n] = (rock_radius(_n) * 0.85, {1: "small", 2: "medium", 3: "large"}[ROCK_TIER[_n]], None)
for _b in ("Meadow", "Desert", "Snow", "Ocean"):  # the band by each wall they stay in (big rocks need room)
    CL.REACH[_b] = 32

# per biome: anchors (one per cluster, weighted) and the small rocks round them
PLAN = {
    "Meadow": dict(anchor=[("RockBoulder", 5), ("RockCrag", 2), ("RockSlab", 2)], small=["RockPebble", "RockStone"]),
    "Desert": dict(anchor=[("Cactus", 3), ("RockBoulder", 4), ("RockCrag", 2), ("RockSlab", 2)], small=["RockPebble", "RockStone"],
                   extra="Cactus"),
    "Snow": dict(anchor=[("Pine", 5), ("RockBoulder", 3), ("RockCrag", 2)], small=["RockPebble", "RockStone"], extra="Pine"),
    "Ocean": dict(anchor=[("BranchCoral", 3), ("FanCoral", 3), ("RockBoulder", 2), ("RockCrag", 2)],
                  small=["TubeCoral", "RockPebble", "RockStone"], extra="FanCoral"),
}


class Layout(CL.Course):
    def fits(self, asset, x, z, biome):
        if self.patch(x, z) in (9, 10):  # never in an ocean trench or on lava
            return False
        return super().fits(asset, x, z, biome)


def pick(rng, weighted):
    names, w = zip(*weighted)
    w = np.array(w, float)
    return names[rng.choice(len(names), p=w / w.sum())]


def cluster(c, rng, b, p, reach, side, bz):
    """One anchor by the wall with two to four small pieces round it."""
    anchor = pick(rng, p["anchor"])
    r = CL.eff(anchor)
    ax = side * (CL.HALF_W - r - rng.uniform(1, max(1.5, reach - 2 * r)))
    if c.put(anchor, ax, bz, b, jitter=4):
        ax, bz = c.items[-1]["x"], c.items[-1]["z"]
    for k in range(int(rng.integers(0, 3))):  # a small piece or two round it, in its band by the wall
        s = str(rng.choice(p["small"]))
        e = CL.eff(s)
        sx = side * rng.uniform(CL.HALF_W - reach + e, CL.HALF_W - 1 - e)
        dz = (r + e + CL.GAP + rng.uniform(0, 5)) * (1 if k % 2 == 0 else -1) * (1 + k // 2)
        c.put(s, sx, bz + dz, b, jitter=2)
    if p.get("extra") and rng.random() < 0.15:  # now and then a second tree/coral
        e = p["extra"]
        c.put(e, ax, bz + rng.choice([-1, 1]) * (r + CL.eff(e) + 6), b, jitter=3)


def layout(seed=11):
    c = Layout(seed)
    rng = c.rng
    for b in CL.BIOMES:
        p = PLAN[b["name"]]
        reach = CL.REACH[b["name"]]
        side = 1 if rng.random() < 0.5 else -1
        z = b["z0"] - CL.ENTRY - CL.BEAT / 2
        while z > b["z1"] + 40:
            if rng.random() < 0.4:  # a quiet beat (QM: accents, not litter)
                z -= CL.BEAT
                side = -side
                continue
            sides = [side]
            for k0, sd in enumerate(sides):
                cluster(c, rng, b, p, reach, sd, z + rng.uniform(-18, 18) + k0 * CL.BEAT / 2)
            z -= CL.BEAT
            side = -side
    return c


def fade(z):
    """The ocean's depth fade toward basalt (course_layout.tint), 0..1."""
    return min(max(((OG.Z_START - z) / OG.OCEAN_LENGTH - 0.3) / 0.5, 0.0), 1.0)


def rock_color(it):
    c = ROCK_COLOR[it["biome"]]
    if it["biome"] == "Ocean":
        f = fade(it["z"])
        c = tuple(round(a + (b - a) * f) for a, b in zip(c, (76, 74, 90)))
    return c


LUAU = """-- The biomes redecorated with the rock meshes (QM, Oct 10). Made by tools/biome_rocks.py:
-- edit that and re-make it, not this. Run in Studio's command bar (Edit, not Play) on the
-- STRAIGHT course: run tools/funnel.luau with MODE = "undo" first, then this, then
-- funnel.luau with MODE = "apply" again (it moves and grows the new obstacles too).
--
-- Everything in World.Obstacles goes except one of each kept asset (Cactus, Pine,
-- TubeCoral, BranchCoral, FanCoral), cloned for its new spots. The rocks are Models named
-- Rock<Mesh> holding an invisible Base (Ride's footprint) and the MeshPart, with a "Tier"
-- attribute. Ocean pieces fade toward basalt with depth, like the corals did.

local world = workspace.World
local obstacles = world.Obstacles
local AssetService = game:GetService("AssetService")
local studs = game:GetService("MaterialService"):FindFirstChild("Studs", true)

-- { asset, x, z, yaw, y, r, g, b }: r, g, b only for rocks (their colour), or the ocean fade for kept ones
local ITEMS = {
@ITEMS@
}
local MESHES = { @MESHES@ }
local SCALE = { @SCALE@ }
local TIER = { @TIER@ }
local RADIUS = { @RADIUS@ }
local BASALT = Color3.fromRGB(76, 74, 90)

for _, inst in obstacles:GetChildren() do
	if inst:GetAttribute("FunnelPivot") then
		error("World.Obstacles is still funnelled: run tools/funnel.luau with MODE = \\"undo\\" first")
	end
end

-- One template of each kept asset, out of the folder before it's cleared: the one
-- nearest the start (for the corals that's the shallowest, so not faded).
local KEPT = { "Cactus", "Pine", "TubeCoral", "BranchCoral", "FanCoral" }
local templates = {}
for _, inst in obstacles:GetChildren() do
	local base = inst:FindFirstChild("Base")
	if base and table.find(KEPT, inst.Name) then
		local cur = templates[inst.Name]
		if not cur or base.Position.Z > cur.Base.Position.Z then
			templates[inst.Name] = inst
		end
	end
end
for name, t in templates do
	templates[name] = t:Clone()
end
for _, name in KEPT do
	assert(templates[name], "no " .. name .. " left in World.Obstacles to copy")
end
local removed = #obstacles:GetChildren()
obstacles:ClearAllChildren()

local meshes = {}
local placed = 0
for _, it in ITEMS do
	local name, x, z, yaw, y = it[1], it[2], it[3], it[4], it[5]
	local at = CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(yaw), 0)
	if MESHES[name] then
		local from = meshes[name]
		if not from then
			from = AssetService:CreateMeshPartAsync(Content.fromUri("rbxassetid://" .. MESHES[name]))
			meshes[name] = from
		end
		local m = Instance.new("Model")
		m.Name = "Rock" .. name
		m:SetAttribute("Tier", TIER[name])
		local base = Instance.new("Part")
		base.Name = "Base"
		base.Anchored, base.CanCollide, base.CanTouch, base.CanQuery, base.CastShadow = true, false, false, false, false
		base.Transparency = 1
		local side = RADIUS[name] * 1.6
		base.Size = Vector3.new(side, 1, side)
		base.CFrame = CFrame.new(x, y - 0.5, z)
		base.Parent = m
		local p = from:Clone()
		p.Name = "Rock"
		p.Size *= SCALE[name]
		p.Anchored, p.CanCollide, p.CanTouch = true, false, false
		p.Color = Color3.fromRGB(it[6], it[7], it[8])
		if studs then
			p.Material = studs.BaseMaterial
			p.MaterialVariant = studs.Name
			p.CustomPhysicalProperties = PhysicalProperties.new(Enum.Material.SmoothPlastic)
		else
			p.Material = Enum.Material.SmoothPlastic
		end
		-- (an uploaded mesh keeps its own origin at the part's position: its y 0 is the rock's base)
		p.CFrame = at
		p.Parent = m
		m.PrimaryPart = base
		m.Parent = obstacles
	else
		local m = templates[name]:Clone()
		local base = m:FindFirstChild("Base")
		local fadeBy = it[6] or 0
		if fadeBy > 0 then
			for _, part in m:GetDescendants() do
				if part:IsA("BasePart") and part ~= base and part.Name ~= "Lava" then
					part.Color = part.Color:Lerp(BASALT, fadeBy)
				end
			end
		end
		m.PrimaryPart = base
		m:PivotTo(CFrame.new(x, y - 0.5, z) * CFrame.Angles(0, math.rad(yaw), 0))
		m.Parent = obstacles
	end
	placed += 1
end
return string.format("biome rocks: %d old obstacles out, %d placed", removed, placed)
"""


def write_luau(items):
    rows = []
    for it in items:
        a = it["asset"]
        if a.startswith("Rock"):
            r, g, b = rock_color(it)
            rows.append('\t{ "%s", %.2f, %.2f, %.1f, %g, %d, %d, %d },' % (a[4:], it["x"], it["z"], it["yaw"], it["y"], r, g, b))
        else:
            f = fade(it["z"]) if it["biome"] == "Ocean" else 0
            rows.append('\t{ "%s", %.2f, %.2f, %.1f, %g, %.3f },' % (a, it["x"], it["z"], it["yaw"], it["y"], f))
    s = LUAU.replace("@ITEMS@", "\n".join(rows))
    s = s.replace("@MESHES@", ", ".join(f"{n} = {v}" for n, v in MESHES.items()))
    s = s.replace("@SCALE@", ", ".join(f"{n} = {v}" for n, v in ROCK_SCALE.items()))
    s = s.replace("@TIER@", ", ".join(f"{n} = {v}" for n, v in ROCK_TIER.items()))
    s = s.replace("@RADIUS@", ", ".join(f"{n} = {CL.eff('Rock' + n):.2f}" for n in MESHES))
    open(os.path.join(HERE, "biome_rocks.luau"), "w").write(s)


def placed_parts(items, z_lo, z_hi):
    """Preview parts: the rock meshes as polys, the kept assets from their kits."""
    from partlib import Part, T, Ry
    import terrain_assets as TA
    parts = []
    for it in items:
        if not (z_lo - 16 <= it["z"] <= z_hi + 16):
            continue
        a = it["asset"]
        if a.startswith("Rock"):
            s = ROCK_SCALE[a[4:]]
            chunks = [[t * s for t in tris] for tris in _built[a]]
            ps = RM.as_parts(chunks, 0, 0, yaw=0, color=rock_color(it))
            M = T(it["x"], it["y"], it["z"]) @ Ry(it["yaw"])
            for p in ps:
                p.cf = M @ p.cf
            parts += ps
        else:
            k = TA.Kit()
            CL.ASSETS[a][2](k)
            s = CL.SCALE.get(a, 1.0)
            M = T(it["x"], it["y"], it["z"]) @ Ry(it["yaw"])
            for p in k.parts:
                cf = p.cf.copy()
                cf[:3, 3] *= s
                parts.append(Part(p.name, tuple(v * s for v in p.size), M @ cf, CL.tint(it, p), p.shape, p.plain))
    return parts


def previews(c, items):
    CL.placed_parts = placed_parts
    CL.MEADOW = [(113, 173, 31), (122, 190, 25)]
    for n, col, shape in (("RockPebble", (150, 150, 160), "square"), ("RockStone", (130, 130, 145), "square"),
                          ("RockSlab", (110, 110, 125), "diamond"), ("RockBoulder", (90, 90, 105), "circle"),
                          ("RockCrag", (60, 60, 75), "circle")):
        CL.ICON[n] = (col, shape)
    CL.plan(c, items, os.path.join(OUT, "plan_meadow_desert.png"), only=["Meadow", "Desert"])
    for name, z, desert in (("meadow", -330, False), ("desert", -1100, True), ("desert2", -2000, True),
                            ("snow", -4000, True), ("snow2", -6000, True), ("ocean", -9400, True), ("ocean_deep", -14000, True)):
        CL.ride_view(c, items, z, desert, os.path.join(OUT, f"ride_{name}.png"))
        print("ride", name)


if __name__ == "__main__":
    c = layout()
    items = c.items
    os.makedirs(OUT, exist_ok=True)
    json.dump(items, open(os.path.join(OUT, "layout.json"), "w"), indent=0)
    write_luau(items)
    from collections import Counter
    for b in CL.BIOMES:
        print(b["name"], dict(Counter(it["asset"] for it in items if it["biome"] == b["name"])))
    print(len(items), "placements")
    if "--preview" in sys.argv:
        previews(c, items)
