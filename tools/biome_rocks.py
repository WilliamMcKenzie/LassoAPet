"""The biomes redecorated with the rock meshes (QM, Oct 10): every old obstacle goes
except Cactus, Pine, TubeCoral, BranchCoral and FanCoral; the rest is five rock meshes
(tools/rock_meshes.py: Pebble, Stone, Slab, Boulder, Crag) in each biome's rock colour.
The Godlands are left alone (QM: going anyway).

Run: python3 tools/biome_rocks.py
(Laid out for the course before Oct 11: tools/course_resize.py has since moved biome_rocks.luau's
rocks to the pacing ladder's lengths. Re-fit the biome spans here before re-running, or it puts them back.)
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
import volcano as VO  # noqa: E402
import jurassic as JU  # noqa: E402
import funnel_grid as FG  # noqa: E402
import rock_meshes as RM  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "design", "biome_rocks")
KEEP = ["Cactus", "Pine", "TubeCoral", "BranchCoral", "FanCoral"]
PLANTS = ["Fern", "Cycad", "JungleTree", "Horsetail"]  # the Jurassic's (design/jurassic_biome/jungle_plants.py)

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

# Multi-piece rocks (QM, Oct 10, design/rocks_biomes/rocks_multishade.png): each piece
# its own MeshPart (design/rocks/pieces/Rock<Name>_<i>.obj, uploaded by Studio, same
# origin as the whole rock) in its own shade of the biome colour. 0 = not uploaded yet.
PIECE_MESHES = {"Pebble": [97909332868672], "Stone": [112802048248632, 82884921728711], "Slab": [77459657567159, 75443554074464],
                "Boulder": [89116112106227, 121000971017571], "Crag": [116203642190808, 137285736622590, 79842203430013, 116412510279796, 111736026009275]}
_SHADE_STEPS = {  # each piece's shade (QM's pick: the steps below x 2.2 from the base)
    "Meadow": [(159, 161, 172), (148, 151, 163), (168, 170, 179), (153, 157, 164), (164, 164, 176)],
    "Desert": [(234, 190, 122), (224, 176, 110), (240, 200, 136), (228, 184, 112), (238, 194, 130)],
    "Snow": [(158, 200, 240), (146, 190, 234), (170, 210, 244), (152, 196, 232), (164, 202, 246)],
    "Ocean": [(242, 120, 98), (232, 108, 90), (246, 134, 110), (236, 116, 92), (244, 126, 106)],
    "Volcano": [(126, 88, 74), (120, 83, 69), (133, 93, 79), (122, 85, 72), (130, 90, 75)],  # warm brown (design/lava_biome)
    "Jurassic": [(132, 94, 62), (126, 88, 58), (139, 99, 66), (128, 91, 60), (136, 97, 64)],  # dirt brown (design/jurassic_biome)
}
SHADE_SPREAD = 2.2
SHADES = {b: [tuple(int(max(0, min(255, c0 + (c - c0) * SHADE_SPREAD))) for c0, c in zip(v[0], sh)) for sh in v]
          for b, v in _SHADE_STEPS.items()}


def rock_radius(name):
    pts = np.concatenate([np.concatenate(t) for t in _built["Rock" + name]])
    return float(np.hypot(pts[:, 0], pts[:, 2]).max()) * ROCK_SCALE[name]


for _n in MESHES:  # the rocks join the layout's assets: (footprint radius, tier, kit)
    CL.ASSETS["Rock" + _n] = (rock_radius(_n) * 0.85, {1: "small", 2: "medium", 3: "large"}[ROCK_TIER[_n]], None)
for _b in ("Meadow", "Desert", "Snow", "Ocean", "Volcano", "Jurassic"):  # the band by each wall they stay in (big rocks need room)
    CL.REACH[_b] = 32

# per biome: anchors (one per cluster, weighted) and the small rocks round them
PLAN = {
    "Meadow": dict(anchor=[("RockBoulder", 5), ("RockCrag", 2), ("RockSlab", 2)], small=["RockPebble", "RockStone"]),
    "Desert": dict(anchor=[("Cactus", 3), ("RockBoulder", 4), ("RockCrag", 2), ("RockSlab", 2)], small=["RockPebble", "RockStone"],
                   extra="Cactus"),
    "Snow": dict(anchor=[("Pine", 5), ("RockBoulder", 3), ("RockCrag", 2)], small=["RockPebble", "RockStone"], extra="Pine"),
    "Ocean": dict(anchor=[("BranchCoral", 3), ("FanCoral", 3), ("RockBoulder", 2), ("RockCrag", 2)],
                  small=["TubeCoral", "RockPebble", "RockStone"], extra="FanCoral"),
    "Volcano": dict(small=["RockPebble", "RockStone"]),  # (its big rocks: PEAK_ROCKS)
    "Jurassic": dict(anchor=[("JungleTree", 4), ("Cycad", 3), ("RockBoulder", 2), ("RockCrag", 1)],
                     small=["Fern", "Horsetail", "Fern", "RockPebble", "RockStone"], extra="Fern"),
}
# The Volcano (QM, Oct 11; tools/volcano.py): after the ocean, rocks only. Laid out after
# the other four, so their layouts stay as they were. Its rocks go where its floor's
# quasicrystal peaks (QM, Oct 11: placed by the pattern): each peak in the band by a
# wall is a crust plate, and a rock stands on it, bigger the higher the peak (a peak
# below SMALL_PEAK gets nothing, below BIG_PEAK a pebble or stone); each lava pool by a
# wall gets a pebble or stone on its crust rim (the deepest ones only).
VOLCANO = dict(name="Volcano", z0=VO.Z_START, z1=VO.END, small=[], medium=[], large=[],
               nests=[(FG.unmap_x(x, z), z) for x, z in VO.nest_spots()])  # (where the funnel puts them)
SMALL_PEAK, BIG_PEAK = 0.8, 0.82
# The Jurassic (QM, Oct 11; tools/jurassic.py): after the volcano, jungle plants and brown
# rocks in wall clusters like the first four biomes, none under the ribcage.
JURASSIC = dict(name="Jurassic", z0=JU.Z_START, z1=JU.END, small=[], medium=[], large=[],
                nests=[(FG.unmap_x(x, z), z) for x, z in JU.nest_spots()])
RIB_SPAN = (JU.RIB_Z0 + 40, JU.RIB_Z0 - (JU.RIB_N - 1) * JU.RIB_GAP - 60)


def _plants():
    """The jungle plants as kits, at their mockup sizes over the funnel's growth (it grows
    them about 2.15x out here), with footprints about their trunks."""
    import importlib.util
    path = os.path.join(HERE, "..", "design", "jurassic_biome", "jungle_plants.py")
    spec = importlib.util.spec_from_file_location("jungle_plants", path)
    JP = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(JP)
    grow = 2.6 ** 0.8
    for name, fn, size, foot, tier in (("Fern", JP.fern, 2.0, 4.0, "small"), ("Cycad", JP.cycad, 1.6, 2.6, "medium"),
                                       ("JungleTree", JP.jungle_tree, 1.5, 4.6, "large"),
                                       ("Horsetail", JP.horsetail, 1.6, 3.0, "small")):
        sc = size / grow

        def kit(k, fn=fn, sc=sc):
            k.parts += fn(0, 0, 0, sc)
        CL.ASSETS[name] = (foot * sc, tier, kit)


_plants()
PEAK_ROCKS = [(0.9, "RockCrag"), (0.86, "RockBoulder"), (BIG_PEAK, "RockSlab")]


class Layout(CL.Course):
    def __init__(self, seed=7):
        super().__init__(seed)
        self.volcano = VO.layout()
        self.jurassic = JU.layout()

    def patch(self, x, z):
        """As the Course's, the Volcano: 11 floor, 12 ash, 13 crust, 14 lava, and the Jurassic: 15 grass, 16 trail."""
        if z <= JU.Z_START:
            return 15 + self.jurassic.at(x, z)
        if z <= VO.Z_START:
            return 11 + self.volcano.at(x, z)
        return super().patch(x, z)

    def floor(self, x, z):
        k = self.patch(x, z)
        if k >= 15:
            return float(JU.TOP[k - 15])
        if k >= 11:
            return float(VO.TOP[k - 11])
        return super().floor(x, z)

    def fits(self, asset, x, z, biome):
        if self.patch(x, z) in (9, 10, 14):  # never in an ocean trench or on lava
            return False
        if biome["name"] == "Volcano" and z - CL.ASSETS[asset][0] < VO.END + VO.END_CLEAR:
            return False  # the finish line and the big crack (Config.VolcanoCrack)
        if biome["name"] == "Jurassic" and z - CL.ASSETS[asset][0] < JU.END + CL.FINISH_CLEAR:
            return False  # the finish line and the leap over it
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
        wall_clusters(c, rng, b)
    volcano_rocks(c, rng)
    wall_clusters(c, rng, JURASSIC, skip=RIB_SPAN)
    return c


def wall_clusters(c, rng, b, skip=None):
    """One cluster every beat down the biome, alternating walls, now and then a quiet beat
    (and none between skip's two z's)."""
    p = PLAN[b["name"]]
    reach = CL.REACH[b["name"]]
    side = 1 if rng.random() < 0.5 else -1
    z = b["z0"] - CL.ENTRY - CL.BEAT / 2
    while z > b["z1"] + 40:
        if rng.random() < 0.4 or (skip and skip[0] > z > skip[1]):  # a quiet beat (QM: accents, not litter)
            z -= CL.BEAT
            side = -side
            continue
        sides = [side]
        for k0, sd in enumerate(sides):
            cluster(c, rng, b, p, reach, sd, z + rng.uniform(-18, 18) + k0 * CL.BEAT / 2)
        z -= CL.BEAT
        side = -side


def volcano_rocks(c, rng):
    """A rock on each of the volcano floor's pattern peaks by the walls (VOLCANO above)."""
    from scipy.ndimage import maximum_filter, minimum_filter
    X, Z = np.meshgrid(np.arange(-136, 137, 2.0), np.arange(VO.Z_START, VO.END, -2.0), indexing="ij")
    q = VO.quasi(X, Z)

    def place(asset, gx, z):
        x = FG.unmap_x(gx, z)
        for step in (0, 2, -2, 4, -4, 6, -6, 8, -8, 10, -10, 12, -12):  # (nudged in or out until it fits)
            px = x + np.sign(x) * step
            if c.fits(asset, px, z, VOLCANO):
                return c.put(asset, px, z, VOLCANO, tries=1)

    peaks = (q == maximum_filter(q, size=9)) & (q >= SMALL_PEAK) & (abs(X) < 134)  # (not just cut off by the wall)
    for i, j in sorted(zip(*np.nonzero(peaks)), key=lambda ij: (-q[ij], ij[1], ij[0])):
        v = q[i, j]
        if v >= BIG_PEAK:
            place(next(a for at, a in PEAK_ROCKS if v >= at), X[i, j], Z[i, j])
        else:
            place(str(rng.choice(PLAN["Volcano"]["small"])), X[i, j], Z[i, j])
    # and a pebble or stone on each deep lava pool's crust rim, on its wall side
    pools = (q == minimum_filter(q, size=9)) & (q < 0.12)  # (the deepest pools only)
    for i, j in zip(*np.nonzero(pools)):
        k = i
        while 0 <= k < q.shape[0] and q[k, j] < 0.25:  # out of the lava toward the wall
            k += 1 if X[i, j] > 0 else -1
        if 0 <= k < q.shape[0]:
            place(str(rng.choice(PLAN["Volcano"]["small"])), X[k, j] + np.sign(X[i, j]) * 4, Z[i, j])


def fade(z):
    """The ocean's depth fade toward basalt (course_layout.tint), 0..1."""
    return min(max(((OG.Z_START - z) / OG.OCEAN_LENGTH - 0.3) / 0.5, 0.0), 1.0)


def rock_color(it, piece=0):
    c = SHADES[it["biome"]][piece % len(SHADES[it["biome"]])]
    if it["biome"] == "Ocean":
        f = fade(it["z"])
        c = tuple(round(a + (b - a) * f) for a, b in zip(c, (76, 74, 90)))
    return c


def write_pieces():
    """One OBJ per piece of each multi-piece rock, in the whole rock's frame."""
    out = os.path.join(HERE, "..", "design", "rocks", "pieces")
    os.makedirs(out, exist_ok=True)
    for name, ids in PIECE_MESHES.items():
        chunks = _built["Rock" + name]
        assert len(chunks) == len(ids), name
        if len(chunks) > 1:
            for i, ch in enumerate(chunks, 1):
                RM.write_obj(f"Rock{name}_{i}", [ch], os.path.join(out, f"Rock{name}_{i}.obj"))


LUAU = """-- The biomes redecorated with the rock meshes (QM, Oct 10). Made by tools/biome_rocks.py:
-- edit that and re-make it, not this. Run in Studio's command bar (Edit, not Play) on the
-- STRAIGHT course: run tools/funnel.luau with MODE = "undo" first, then this, then
-- funnel.luau with MODE = "apply" again (it moves and grows the new obstacles too).
--
-- Everything in World.Obstacles goes except one of each kept asset (Cactus, Pine,
-- TubeCoral, BranchCoral, FanCoral, and the Jurassic's Fern, Cycad, JungleTree and
-- Horsetail, whose one each tools/biome_rocks.py writes in), cloned for its new spots. The rocks are Models named
-- Rock<Mesh> holding an invisible Base (Ride's footprint) and one MeshPart per piece
-- (PIECES: the ids of design/rocks/pieces/Rock<Mesh>_<i>.obj in order), each piece its
-- own shade of the biome colour, with a "Tier" attribute. Ocean pieces fade toward basalt with depth, like the corals did.

local world = workspace.World
local obstacles = world.Obstacles
local AssetService = game:GetService("AssetService")
local studs = game:GetService("MaterialService"):FindFirstChild("Studs", true)

-- { asset, x, z, yaw, y, r, g, b, r, g, b, ... }: rocks get one r, g, b per piece; kept ones the ocean fade
local ITEMS = {
@ITEMS@
}
local PIECES = { @MESHES@ }
local SCALE = { @SCALE@ }
local TIER = { @TIER@ }
local RADIUS = { @RADIUS@ }
local BASALT = Color3.fromRGB(76, 74, 90)

for name, ids in PIECES do
	for _, id in ids do
		assert(id ~= 0, "PIECES." .. name .. " has a piece not uploaded yet (0): upload design/rocks/pieces and fill in its ids")
	end
end
for _, inst in obstacles:GetChildren() do
	if inst:GetAttribute("FunnelPivot") then
		error("World.Obstacles is still funnelled: run tools/funnel.luau with MODE = \\"undo\\" first")
	end
end

-- One template of each kept asset, out of the folder before it's cleared: the one
-- nearest the start (for the corals that's the shallowest, so not faded).
local KEPT = { "Cactus", "Pine", "TubeCoral", "BranchCoral", "FanCoral", "Fern", "Cycad", "JungleTree", "Horsetail" }
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
	if PIECES[name] then
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
		for i, id in PIECES[name] do
			local from = meshes[id]
			if not from then
				from = AssetService:CreateMeshPartAsync(Content.fromUri("rbxassetid://" .. id))
				meshes[id] = from
			end
			local p = from:Clone()
			p.Name = if #PIECES[name] > 1 then "Rock" .. i else "Rock"
			p.Size *= SCALE[name]
			p.Anchored, p.CanCollide, p.CanTouch = true, false, false
			local k = 3 + 3 * i
			p.Color = Color3.fromRGB(it[k], it[k + 1], it[k + 2])
			if studs then
				p.Material = studs.BaseMaterial
				p.MaterialVariant = studs.Name
				p.CustomPhysicalProperties = PhysicalProperties.new(Enum.Material.SmoothPlastic)
			else
				p.Material = Enum.Material.SmoothPlastic
			end
			-- (an uploaded mesh keeps its own origin at the part's position: its y 0 is the
			-- rock's base, and every piece shares the whole rock's origin, so they fit together)
			p.CFrame = at
			p.Parent = m
		end
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
            cols = ", ".join("%d, %d, %d" % rock_color(it, i) for i in range(len(PIECE_MESHES[a[4:]])))
            rows.append('\t{ "%s", %.2f, %.2f, %.1f, %g, %s },' % (a[4:], it["x"], it["z"], it["yaw"], it["y"], cols))
        else:
            f = fade(it["z"]) if it["biome"] == "Ocean" else 0
            rows.append('\t{ "%s", %.2f, %.2f, %.1f, %g, %.3f },' % (a, it["x"], it["z"], it["yaw"], it["y"], f))
    s = LUAU.replace("@ITEMS@", "\n".join(rows))
    s = s.replace("@MESHES@", ", ".join(f"{n} = {{ {', '.join(map(str, v))} }}" for n, v in PIECE_MESHES.items()))
    s = s.replace("@SCALE@", ", ".join(f"{n} = {v}" for n, v in ROCK_SCALE.items()))
    s = s.replace("@TIER@", ", ".join(f"{n} = {v}" for n, v in ROCK_TIER.items()))
    s = s.replace("@RADIUS@", ", ".join(f"{n} = {CL.eff('Rock' + n):.2f}" for n in MESHES))
    open(os.path.join(HERE, "biome_rocks.luau"), "w").write(s)


def write_plant_templates():
    """One of each jungle plant into World.Obstacles (JPLT), for biome_rocks.luau to copy."""
    import re
    import desert_ground as DG
    w = open(CL.WORLD).read()
    while True:  # (a previous run's)
        m = re.search(r'\n<Item class="Model" referent="JPLT\d+">', w)
        if not m:
            break
        w = w[:m.start()] + w[DG.item_span(w, m.start() + 1):]
    items = [dict(asset=n, x=-40.0, z=JU.Z_START - 100 - 20 * i, yaw=0, y=0, biome="Jurassic") for i, n in enumerate(PLANTS)]
    models, parts = CL.obstacle_models(items, prefix="JPLT")
    i = w.index('<string name="Name">Obstacles</string>')
    at = w.index("</Properties>", i) + len("</Properties>")
    w = w[:at] + "\n" + "\n".join(models) + w[at:]
    open(CL.WORLD, "w").write(w)
    return parts


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
            ps = [p for i, ch in enumerate(chunks) for p in RM.as_parts([ch], 0, 0, yaw=0, color=rock_color(it, i))]
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
    write_pieces()
    print("wrote the jungle plant templates into World.Obstacles,", write_plant_templates(), "parts")
    from collections import Counter
    for b in CL.BIOMES + [VOLCANO, JURASSIC]:
        print(b["name"], dict(Counter(it["asset"] for it in items if it["biome"] == b["name"])))
    print(len(items), "placements")
    if "--preview" in sys.argv:
        previews(c, items)
