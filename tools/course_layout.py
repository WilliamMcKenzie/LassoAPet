"""Where the terrain assets go along the course (a draft for QM to vet).

Run: python3 tools/course_layout.py [out_dir]         pictures only
     python3 tools/course_layout.py --map               also write World.Obstacles

Writes layout.json (every placement: asset, x, z, yaw, y), a top-down map of
every biome (plan.png) and a ride-view render of each. With --map, every placement
becomes a Model named after its asset in World.Obstacles (src/world/World.rbxmx);
Config.ObstacleTiers gives each name its size tier.

How a biome is laid out, from its line toward its far end:
  - Entry: the first 48 studs are clear, so a new biome reads before it bites.
  - Beats: the rest is cut into beats ~80 studs long, each one pattern:
      scatter  small rocks and bushes in little clumps
      gate     two mediums with one gap to steer through
      slalom   three mediums, alternating sides
      island   (desert) a big sand mound mid-course, lanes either side
    Beats get busier with distance: more smalls, narrower gates.
  - Edges: smalls hug the walls every so often, so the edges feel lived in and
    the middle stays readable from the top-down camera.
  - Nests: a clear ring around each nest, with a pair of smalls framing it.
  - Every placement keeps its footprint clear of the others, so there's always
    a way through on the ride back.
Snow is laid out like the desert, with pines on the cold grass and ice boulder
islands. Desert extras: cacti prefer dry grass, sandstone chunks prefer the raised
sandstone edges, and anything on sandstone sits a stud up.
"""

import json
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
import partlib  # noqa: E402
from partlib import Part, T, Ry, render  # noqa: E402
import terrain_assets as TA  # noqa: E402
import desert_ground as DG  # noqa: E402
import meadow_ground as MG  # noqa: E402
import snow_ground as SG  # noqa: E402
import ocean_ground as OG  # noqa: E402
from animal_designs import font  # noqa: E402

HALF_W = 56
BIOMES = [
    dict(name="Meadow", z0=0, z1=-760, nests=[(-20, -470), (22, -600), (0, -736)],
         small=["Stone", "Bush"], medium=["Boulder", "BoulderSplit"], large=[]),
    dict(name="Desert", z0=-760, z1=-3040, nests=DG.NESTS,
         small=["Sandstone"], medium=["Cactus", "SandBoulder", "SandBoulderCarved"], large=["SandMound"]),
    dict(name="Snow", z0=-3040, z1=-9880, nests=SG.NESTS,
         small=["Icicle"], medium=["Pine", "IcicleLarge"], large=["IceBoulder"]),
    dict(name="Ocean", z0=OG.Z_START, z1=OG.Z_START - OG.OCEAN_LENGTH, nests=OG.NESTS,
         small=["TubeCoral", "BrainCoral"], medium=["BranchCoral", "FanCoral"], large=["ReefRock"]),
]
# footprint radius (studs), size class and builder for each asset
ASSETS = {
    "Stone": (3.0, "small", TA.stone),
    "Bush": (3.4, "small", TA.bush),
    "Boulder": (5.6, "medium", TA.boulder),
    "BoulderSplit": (5.0, "medium", TA.boulder_b),
    "Sandstone": (3.0, "small", TA.sandstone),
    "Cactus": (3.4, "medium", TA.cactus),
    "SandBoulder": (5.0, "medium", TA.sand_boulder),
    "SandBoulderCarved": (5.4, "medium", TA.sand_boulder_b),
    "SandMound": (12.5, "large", TA.sand_mound),
    "Icicle": (2.6, "small", TA.icicle),
    "Pine": (4.6, "medium", TA.pine_tree),
    "IcicleLarge": (4.3, "medium", TA.large_icicle),
    "IceBoulder": (9.0, "large", TA.ice_boulder),
    "TubeCoral": (2.6, "small", TA.tube_coral),
    "BrainCoral": (3.0, "small", TA.brain_coral),
    "BranchCoral": (4.0, "medium", TA.branch_coral),
    "FanCoral": (3.8, "medium", TA.fan_coral),
    "ReefRock": (9.0, "large", TA.reef_rock),
}
# the medium a cluster mixes in now and then, so it isn't all rubble
ACCENT = {"Desert": "Cactus", "Snow": "Pine", "Ocean": "FanCoral"}
TIERS = {"small": 1, "medium": 2, "large": 3}
ENTRY = 48
BEAT = 80
NEST_CLEAR = 18
GAP = 3  # studs between any two footprints
FINISH_CLEAR = 80  # studs kept clear before the far wall: the finish line is 50 in


class Course:
    def __init__(self, seed=7):
        self.rng = np.random.default_rng(seed)
        self.items = []
        self.kind = DG.layout()  # desert patches, per 8-stud cell
        self.dirt = MG.layout(MG.MEADOW_LENGTH // MG.CELL)  # meadow dirt, per 8-stud cell
        self.snow = SG.full_layout()  # snow patches, per 8-stud cell
        self.ocean = OG.full_layout()  # ocean patches, per 8-stud cell

    def patch(self, x, z):
        """Desert: 0 sand, 1 dry grass, 2 sandstone. Meadow: 0 grass, 3 dirt.
        Snow: 4 snow, 5 cold grass, 6 ice. Ocean: 7 sand, 8 seagrass, 9 trench."""
        i = int((x + DG.HALF_W) // DG.CELL)
        if z <= OG.Z_START:
            j = int((OG.Z_START - z) // OG.CELL)
            if 0 <= i < self.ocean.shape[0] and 0 <= j < self.ocean.shape[1]:
                return 7 + int(self.ocean[i, j])
            return 7
        if z <= SG.Z_START:
            j = int((SG.Z_START - z) // SG.CELL)
            if 0 <= i < self.snow.shape[0] and 0 <= j < self.snow.shape[1]:
                return 4 + int(self.snow[i, j])
            return 4
        if z > DG.Z_START:
            j = int(-z // MG.CELL)
            if 0 <= i < self.dirt.shape[0] and 0 <= j < self.dirt.shape[1] and self.dirt[i, j]:
                return 3
            return 0
        j = int((DG.Z_START - z) // DG.CELL)
        if 0 <= i < self.kind.shape[0] and 0 <= j < self.kind.shape[1]:
            return int(self.kind[i, j])
        return 0

    def floor(self, x, z):
        """Floor height, as Shared/Ground reports it: sandstone and cold grass +1, dirt and ice -1."""
        return {2: 1.0, 3: -1.0, 5: 1.0, 6: -1.0, 8: 1.0, 9: -1.0}.get(self.patch(x, z), 0.0)

    def fits(self, asset, x, z, biome):
        r = ASSETS[asset][0]
        if abs(x) + r > HALF_W - 1:
            return False
        if z + r > biome["z0"] - ENTRY:
            return False
        if z - r < biome["z1"] + 4:
            return False
        if biome["name"] in ("Desert", BIOMES[-1]["name"]) and z - r < biome["z1"] + FINISH_CLEAR:
            return False  # the finish line and the leap over it (Config.FinishFromEnd)
        for nx, nz in biome["nests"]:
            if math.hypot(x - nx, z - nz) < NEST_CLEAR + r:
                return False
        for it in self.items:
            if math.hypot(x - it["x"], z - it["z"]) < r + ASSETS[it["asset"]][0] + GAP:
                return False
        return True

    def put(self, asset, x, z, biome, tries=12, jitter=3.0):
        for t in range(tries):
            px = x + (self.rng.normal(0, jitter) if t else 0)
            pz = z + (self.rng.normal(0, jitter) if t else 0)
            if self.fits(asset, px, pz, biome):
                y = self.floor(px, pz)
                self.items.append(dict(asset=asset, x=round(px, 2), z=round(pz, 2),
                                       yaw=round(float(self.rng.uniform(0, 360)), 1), y=y,
                                       tier=TIERS[ASSETS[asset][1]], biome=biome["name"]))
                return True
        return False

    def pick_small(self, biome, x, z):
        return self.rng.choice(biome["small"])

    def pick_medium(self, biome, x, z):
        if biome["name"] == "Desert":
            # cacti grow on the dry grass, boulders sit on sand or stone
            if self.patch(x, z) == 1:
                return "Cactus"
            return self.rng.choice(["Cactus", "SandBoulder", "SandBoulderCarved"], p=[0.3, 0.35, 0.35])
        if biome["name"] == "Snow":
            # pines grow on the cold grass, big icicles stand on snow and ice
            if self.patch(x, z) == 5:
                return "Pine"
            return self.rng.choice(["Pine", "IcicleLarge"], p=[0.4, 0.6])
        return self.rng.choice(biome["medium"])

    def clump(self, biome, x, z, n):
        for _ in range(n):
            px, pz = x + self.rng.normal(0, 5), z + self.rng.normal(0, 5)
            # desert clumps mix in a cactus now and then, so it isn't all rubble
            if biome["name"] == "Desert" and self.rng.random() < 0.3:
                self.put("Cactus", px, pz, biome)
            else:
                self.put(self.pick_small(biome, px, pz), px, pz, biome)

    def beat(self, biome, pattern, z0, z1, busy):
        mid = (z0 + z1) / 2
        rng = self.rng
        if pattern == "scatter":
            for _ in range(2 + int(busy * 2)):
                self.clump(biome, rng.uniform(-44, 44), rng.uniform(z1, z0), rng.integers(1, 4))
        elif pattern == "gate":
            gap = 34 - busy * 12  # the opening narrows deeper in
            cx = rng.uniform(-HALF_W + gap / 2 + 8, HALF_W - gap / 2 - 8)
            for side in (-1, 1):
                edge = cx + side * gap / 2
                x = edge + side * 6
                m = self.pick_medium(biome, x, mid)
                self.put(m, x, mid, biome, jitter=1.5)
                # fill toward the wall so the gap is the way through
                x2 = x + side * 13
                if abs(x2) < HALF_W - 6:
                    self.put(self.pick_medium(biome, x2, mid), x2, mid + rng.normal(0, 3), biome)
            self.clump(biome, cx + rng.choice([-1, 1]) * 20, mid - 26, 1 + int(busy * 2))
        elif pattern == "slalom":
            side = int(rng.choice([-1, 1]))
            for k in range(3):
                z = z0 - 14 - k * (z0 - z1 - 28) / 2
                x = side * rng.uniform(14, 26)
                self.put(self.pick_medium(biome, x, z), x, z, biome)
                self.put(self.pick_small(biome, x, z), x + side * 10, z + rng.normal(0, 4), biome)
                side = -side
        elif pattern == "island":
            x = rng.uniform(-10, 10)
            self.put("SandMound", x, mid, biome, jitter=4)
            for side in (-1, 1):
                self.clump(biome, side * rng.uniform(40, 48), mid + rng.normal(0, 10), 2)

    def edges(self, biome):
        z = biome["z0"] - ENTRY
        while z > biome["z1"] + 16:
            for side in (-1, 1):
                if self.rng.random() < 0.3:
                    asset = self.pick_small(biome, side * 50, z)
                    if biome["name"] == "Desert" and self.rng.random() < 0.4:
                        asset = self.rng.choice(["Cactus", "SandBoulder"])
                    x = side * (HALF_W - ASSETS[asset][0] - 1.5)
                    self.put(asset, x, z + self.rng.normal(0, 4), biome)
            z -= 24

    def nests(self, biome):
        for nx, nz in biome["nests"]:
            for side in (-1, 1):
                self.put(self.pick_small(biome, nx, nz), nx + side * (NEST_CLEAR + 4), nz + self.rng.normal(0, 3),
                         biome, jitter=1.5)

    def biome(self, biome):
        self.nests(biome)
        length = biome["z0"] - biome["z1"]
        n = int((length - ENTRY) // BEAT)
        desert = biome["name"] == "Desert"
        patterns = ["gate", "scatter", "slalom", "gate", "scatter"] if not desert else \
            ["gate", "scatter", "island", "slalom", "gate", "scatter", "island", "slalom"]
        for b in range(n):
            z0 = biome["z0"] - ENTRY - b * BEAT
            busy = b / max(1, n - 1)
            self.beat(biome, patterns[b % len(patterns)], z0, z0 - BEAT, busy)
        self.edges(biome)

    def meadow_clusters(self, biome, rng):
        """The meadow, the easy first biome (QM, Oct 1): obstacles only in clusters
        against the walls, so the middle of the course is open and they never
        really get in the way. One cluster per beat, alternating walls: a boulder
        with smalls strung along the wall either side of it."""
        main = self.rng
        self.rng = rng
        n = int((biome["z0"] - biome["z1"] - ENTRY) // BEAT)
        side = int(rng.choice([-1, 1]))
        for b in range(n):
            mid = biome["z0"] - ENTRY - b * BEAT - BEAT / 2 + rng.uniform(-12, 12)
            m = self.pick_medium(biome, side * 48, mid)
            self.put(m, side * (HALF_W - 1.5 - ASSETS[m][0]), mid, biome, jitter=2)
            for dz in (-11.5, 11.5, 22) if b >= n // 2 else (-11.5, 11.5):
                s_ = self.pick_small(biome, side * 50, mid + dz)
                self.put(s_, side * (HALF_W - 1.5 - ASSETS[s_][0]), mid + dz, biome, jitter=1.5)
            side = -side
        self.rng = main

    def cluster(self, biome, rng, cx, cz, smalls, mediums=1):
        """A tight knot of obstacles: the mediums side by side, smalls packed round."""
        centres = []
        for m in range(mediums):
            x = cx + (m - (mediums - 1) / 2) * 12.5
            if self.put(self.pick_medium(biome, x, cz), x, cz, biome, jitter=3):
                centres.append((self.items[-1]["x"], self.items[-1]["z"]))
        if not centres:
            centres = [(cx, cz)]
        start = rng.uniform(0, 2 * math.pi)
        for k in range(smalls):
            ox, oz = centres[k % len(centres)]
            a = start + k * 2 * math.pi / smalls
            x, z = ox + math.cos(a) * 11.5, oz + math.sin(a) * 11.5
            asset = ACCENT[biome["name"]] if rng.random() < 0.3 else self.pick_small(biome, x, z)
            self.put(asset, x, z, biome, jitter=1.5)

    def desert_clusters(self, biome, rng):
        """The desert, gathered up (QM, Sep 30): the same kinds of obstacles, about
        two thirds as many, packed into clusters with clear lanes between them.
        Each beat is one cluster swinging from side to side; deeper in, some
        beats get a second cluster on the other side (a lane down the middle),
        and every fourth beat is a sand mound island with a few things tucked
        against it. A few smalls still hug the walls, and each nest keeps one."""
        main = self.rng
        self.rng = rng
        for nx, nz in biome["nests"]:
            side = int(rng.choice([-1, 1]))
            self.put(self.pick_small(biome, nx, nz), nx + side * (NEST_CLEAR + 4), nz + rng.normal(0, 3), biome, jitter=1.5)
        n = int((biome["z0"] - biome["z1"] - ENTRY) // BEAT)
        side = int(rng.choice([-1, 1]))
        for b in range(n):
            mid = biome["z0"] - ENTRY - b * BEAT - BEAT / 2
            busy = b / max(1, n - 1)
            if b % 4 == 3:
                x = rng.uniform(-8, 8)
                if self.put(biome["large"][0], x, mid, biome, jitter=4):
                    mx, mz = self.items[-1]["x"], self.items[-1]["z"]
                    for k in range(2):
                        a = rng.uniform(0, 2 * math.pi)
                        self.put(self.pick_small(biome, mx, mz), mx + math.cos(a) * 18, mz + math.sin(a) * 18, biome, jitter=2)
                continue
            self.cluster(biome, rng, side * rng.uniform(10, 30), mid, 3 + (1 if busy > 0.5 else 0),
                         mediums=2 if rng.random() < 0.35 else 1)
            if busy > 0.4 and rng.random() < 0.5:
                self.cluster(biome, rng, -side * rng.uniform(30, 40), mid + rng.normal(0, 8), 2)
            side = -side
        z = biome["z0"] - ENTRY
        while z > biome["z1"] + 16:
            for s in (-1, 1):
                if rng.random() < 0.08:
                    small = biome["small"][0]
                    x = s * (HALF_W - ASSETS[small][0] - 1.5)
                    self.put(small, x, z + rng.normal(0, 4), biome)
            z -= 24
        self.rng = main


    def build(self):
        for b in BIOMES:
            if b["name"] == "Meadow":
                # Lay the old meadow out and throw it away, so the random draws the
                # desert gets (and so its layout) stay exactly as QM approved them.
                before = len(self.items)
                self.biome(b)
                del self.items[before:]
                self.meadow_clusters(b, np.random.default_rng(11))
            elif b["name"] == "Desert":
                self.desert_clusters(b, np.random.default_rng(23))
            else:
                # the snow and ocean are laid out like the desert: clusters with lanes between
                self.desert_clusters(b, np.random.default_rng(31 if b["name"] == "Snow" else 41))
        return self.items


# ---------------------------------------------------------------- pictures

MEADOW = [(77, 196, 63), (105, 255, 74)]
ICON = {
    "Stone": ((150, 156, 170), "square"), "Bush": ((70, 168, 58), "circle"),
    "Boulder": ((118, 124, 140), "square"), "BoulderSplit": ((118, 124, 140), "diamond"),
    "Sandstone": ((176, 116, 64), "square"), "Cactus": ((60, 150, 40), "plus"),
    "SandBoulder": ((200, 150, 90), "circle"), "SandBoulderCarved": ((200, 150, 90), "diamond"),
    "SandMound": ((226, 176, 92), "circle"),
    "Icicle": ((150, 206, 244), "square"), "Pine": ((40, 110, 70), "plus"),
    "IcicleLarge": ((120, 180, 236), "diamond"), "IceBoulder": ((170, 220, 250), "circle"),
    "TubeCoral": ((156, 86, 230), "square"), "BrainCoral": ((255, 140, 48), "circle"),
    "BranchCoral": ((255, 92, 150), "plus"), "FanCoral": ((255, 214, 60), "diamond"),
    "ReefRock": ((236, 140, 124), "circle"),
}


def plan(course, items, path, s=2.0, only=None):
    """Top-down map: distance runs left to right, 760 studs per strip (the
    meadow is one strip, the desert three)."""
    pad, band = 20, 34
    SEG = 760
    W = int(SEG * s) + 2 * pad
    strip = int(2 * HALF_W * s)
    segs = []
    for b in BIOMES:
        if only and b["name"] not in only:
            continue
        for z0 in range(b["z0"], b["z1"], -SEG):
            segs.append((b, z0, max(z0 - SEG, b["z1"])))
    im = Image.new("RGB", (W, (strip + band) * len(segs) + 80), (255, 255, 255))
    d = ImageDraw.Draw(im)
    for si, (b, z0, z1) in enumerate(segs):
        oy = si * (strip + band) + band

        def to_px(x, z):
            return pad + (z0 - z) * s, oy + (x + HALF_W) * s

        d.text((pad, oy - band + 8), f"{b['name']}: studs {b['z0'] - z0} to {b['z0'] - z1} into the biome",
               fill=(30, 30, 30), font=font(18))
        for zi in range(int((z0 - z1) // 4)):
            for xi in range(28):
                z = z0 - zi * 4 - 2
                x = -HALF_W + xi * 4 + 2
                chk = (xi + zi) % 2
                k = course.patch(x, z)
                if b["name"] == "Desert":
                    c = (DG.SAND, DG.GRASS, DG.STONE)[k][chk]
                elif b["name"] == "Snow":
                    c = (SG.SNOW, SG.GRASS, SG.ICE)[k - 4][chk]
                elif b["name"] == "Ocean":
                    c = (OG.SAND, OG.GRASS, OG.TRENCH)[k - 7][chk]
                else:
                    c = MG.DIRT[chk] if k == 3 else MEADOW[chk]
                x0, y0 = to_px(x - 2, z + 2)
                d.rectangle([x0, y0, x0 + 4 * s - 1, y0 + 4 * s - 1], fill=c)
        # beat lines
        for k in range(40 if b["name"] != "Ocean" else 0):  # the ocean's 13680 studs would need more
            z = b["z0"] - ENTRY - k * BEAT
            if z1 < z <= z0:
                x0, y0 = to_px(-HALF_W, z)
                d.line([x0, y0, x0, y0 + strip], fill=(255, 255, 255), width=1)
        for nx, nz in b["nests"]:
            if not (z1 < nz <= z0):
                continue
            cx, cy = to_px(nx, nz)
            r = NEST_CLEAR * s
            d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=(255, 255, 255), width=2)
            d.ellipse([cx - 6, cy - 6, cx + 6, cy + 6], fill=(140, 90, 50), outline=(40, 30, 20))
            d.ellipse([cx - 3, cy - 4, cx + 3, cy + 3], fill=(255, 250, 235))
        for it in items:
            if it["biome"] != b["name"] or not (z1 < it["z"] <= z0):
                continue
            color, shape = ICON[it["asset"]]
            cx, cy = to_px(it["x"], it["z"])
            r = ASSETS[it["asset"]][0] * s
            box = [cx - r, cy - r, cx + r, cy + r]
            o = (30, 30, 30)
            if shape == "circle":
                d.ellipse(box, fill=color, outline=o, width=2)
            elif shape == "square":
                d.rectangle(box, fill=color, outline=o, width=2)
            elif shape == "diamond":
                d.polygon([(cx, cy - r), (cx + r, cy), (cx, cy + r), (cx - r, cy)], fill=color, outline=o)
            else:
                w = r * 0.4
                d.rectangle([cx - w, cy - r, cx + w, cy + r], fill=color, outline=o)
                d.rectangle([cx - r, cy - w, cx + r, cy + w], fill=color, outline=o)
    # legend
    y = len(segs) * (strip + band) + 14
    x = pad
    names = {"Stone": "stone", "Bush": "bush", "Boulder": "boulder A", "BoulderSplit": "boulder B",
             "Sandstone": "sandstone", "Cactus": "cactus", "SandBoulder": "sand boulder A",
             "SandBoulderCarved": "sand boulder B", "SandMound": "sand mound",
             "Icicle": "icicle", "Pine": "pine", "IcicleLarge": "large icicle", "IceBoulder": "ice boulder",
             "TubeCoral": "tube coral (1)", "BrainCoral": "brain coral (1)", "BranchCoral": "staghorn (2)",
             "FanCoral": "sea fan (2)", "ReefRock": "reef rock (3)"}
    if only:
        keep = {a for b in BIOMES if b["name"] in only for a in b["small"] + b["medium"] + b["large"]}
        names = {a: l for a, l in names.items() if a in keep}
    for a, label in names.items():
        color, shape = ICON[a]
        r = 8
        if shape == "circle":
            d.ellipse([x, y, x + 2 * r, y + 2 * r], fill=color, outline=(30, 30, 30), width=2)
        elif shape == "diamond":
            d.polygon([(x + r, y), (x + 2 * r, y + r), (x + r, y + 2 * r), (x, y + r)], fill=color, outline=(30, 30, 30))
        elif shape == "plus":
            d.rectangle([x + 5, y, x + 11, y + 16], fill=color, outline=(30, 30, 30))
            d.rectangle([x, y + 5, x + 16, y + 11], fill=color, outline=(30, 30, 30))
        else:
            d.rectangle([x, y, x + 2 * r, y + 2 * r], fill=color, outline=(30, 30, 30), width=2)
        d.text((x + 22, y), label, fill=(30, 30, 30), font=font(15))
        x += 32 + d.textlength(label, font=font(15)) + 14
    d.text((x, y), "white ring = nest (kept clear)" + ("" if only else "   white lines = beats"),
           fill=(90, 90, 90), font=font(15))
    im.save(path)


def placed_parts(items, z_lo, z_hi):
    parts = []
    for it in items:
        if not (z_lo - 16 <= it["z"] <= z_hi + 16):
            continue
        k = TA.Kit()
        ASSETS[it["asset"]][2](k)
        M = T(it["x"], it["y"], it["z"]) @ Ry(it["yaw"])
        for p in k.parts:
            q = Part(p.name, p.size, M @ p.cf, p.color, p.shape, p.plain)
            if hasattr(p, "polys"):
                q.polys = [(M @ np.c_[poly, np.ones(len(poly))].T).T[:, :3] for poly in p.polys]
            parts.append(q)
    return parts


def ride_view(course, items, z_hi, desert, path):
    z_lo = z_hi - 170
    parts = placed_parts(items, z_lo, z_hi)
    for zi in range(int((z_hi - z_lo) // 4)):
        for xi in range(28):
            x, z = -HALF_W + xi * 4 + 2, z_hi - zi * 4 - 2
            k = course.patch(x, z)
            top = course.floor(x, z)
            c = (DG.SAND, DG.GRASS, DG.STONE, MG.DIRT, SG.SNOW, SG.GRASS, SG.ICE,
                 OG.SAND, OG.GRASS, OG.TRENCH)[k] if desert or k else MEADOW
            parts.append(Part("Floor", (4, top + 2, 4), T(x, (top - 2) / 2, z), c[(xi + zi) % 2]))
    for side in (-1, 1):
        wall = OG.WALL if z_hi <= OG.Z_START else SG.WALL if z_hi <= SG.Z_START else DG.WALL if desert else [(225, 150, 104), (248, 170, 114)]
        for zi in range(int((z_hi - z_lo) // 4)):
            for yi in range(4):
                parts.append(Part("Wall", (4, 4, 4), T(side * (HALF_W + 2), yi * 4 + 2, z_hi - zi * 4 - 2),
                                  wall[(zi + yi) % 2], plain=True))
    img = render(parts, eye=(0, 72, z_hi + 26), target=(0, 0, z_hi - 70), W=1000, H=640, fov=52, fog=False,
                 ground=False)
    if z_hi <= OG.Z_START:
        img = OG.underwater(img)
    img.save(path)


# ---------------------------------------------------------------- map

WORLD = DG.WORLD
STUD_FACES = (0, 1, 2, 3, 5)  # every face but the bottom gets the stud decal
FACE_AXES = {0: (1, 2), 1: (0, 2), 2: (0, 1), 3: (1, 2), 5: (0, 1)}  # the size axes each face spans
MIN_STUD_FACE = 0.75  # thinner faces show no studs anyway, so they get no decal (keeps the map light)


def part_xml(ref, p):
    R, (x, y, z) = p.cf[:3, :3], p.cf[:3, 3]
    cf = f"<X>{x:.4f}</X><Y>{y:.4f}</Y><Z>{z:.4f}</Z>" + "".join(
        f"<R{i}{j}>{R[i, j]:.6f}</R{i}{j}>" for i in range(3) for j in range(3))
    out = [f'<Item class="Part" referent="{ref()}"><Properties>',
           f'<string name="Name">{p.name}</string>',
           '<bool name="Anchored">true</bool>',
           '<bool name="CanCollide">false</bool>',
           '<bool name="CanTouch">false</bool>',
           '<token name="Material">272</token>',
           f'<Vector3 name="size"><X>{p.size[0]:.4f}</X><Y>{p.size[1]:.4f}</Y><Z>{p.size[2]:.4f}</Z></Vector3>',
           f'<Color3uint8 name="Color3uint8">{partlib._xml_color(p.color)}</Color3uint8>']
    out += [f'<token name="{f}Surface">0</token>' for f in ("Top", "Bottom", "Front", "Back", "Left", "Right")]
    out += [f'<CoordinateFrame name="CFrame">{cf}</CoordinateFrame>', "</Properties>"]
    if not p.plain:
        for face in STUD_FACES:
            if min(p.size[i] for i in FACE_AXES[face]) < MIN_STUD_FACE:
                continue
            out += [f'<Item class="Texture" referent="{ref()}"><Properties>',
                    '<string name="Name">Studs</string>',
                    f'<Content name="Texture"><url>{partlib.STUD_IMAGE}</url></Content>',
                    f'<float name="StudsPerTileU">{partlib.STUD_TILE}</float>',
                    f'<float name="StudsPerTileV">{partlib.STUD_TILE}</float>',
                    f'<token name="Face">{face}</token>',
                    "</Properties></Item>"]
    out.append("</Item>")
    return "\n".join(out)


def write_obstacles(items):
    """Replace everything in World.Obstacles with one Model per placement."""
    n = [0]

    def ref():
        n[0] += 1
        return f"OBS{n[0]:06d}"

    models = []
    parts_total = 0
    for it in items:
        k = TA.Kit()
        ASSETS[it["asset"]][2](k)
        M = T(it["x"], it["y"], it["z"]) @ Ry(it["yaw"])
        body = [part_xml(ref, Part(p.name, p.size, M @ p.cf, p.color, p.shape, p.plain)) for p in k.parts]
        # Ride takes an obstacle's footprint from its lowest part, so each model gets
        # an invisible Base just under the floor, the size of what you'd hit.
        side = ASSETS[it["asset"]][0] * 1.6
        body.insert(0, "\n".join([
            f'<Item class="Part" referent="{ref()}"><Properties>',
            '<string name="Name">Base</string>',
            '<bool name="Anchored">true</bool>',
            '<bool name="CanCollide">false</bool>',
            '<bool name="CanTouch">false</bool>',
            '<bool name="CanQuery">false</bool>',
            '<bool name="CastShadow">false</bool>',
            '<float name="Transparency">1</float>',
            f'<Vector3 name="size"><X>{side:.3f}</X><Y>1</Y><Z>{side:.3f}</Z></Vector3>',
            f'<CoordinateFrame name="CFrame"><X>{it["x"]:.3f}</X><Y>{it["y"] - 0.5:.3f}</Y><Z>{it["z"]:.3f}</Z>'
            "<R00>1</R00><R01>0</R01><R02>0</R02><R10>0</R10><R11>1</R11><R12>0</R12><R20>0</R20><R21>0</R21><R22>1</R22>"
            "</CoordinateFrame>",
            "</Properties>", "</Item>"]))
        parts_total += len(body)
        models.append(f'<Item class="Model" referent="{ref()}"><Properties>\n'
                      f'<string name="Name">{it["asset"]}</string>\n</Properties>\n' + "\n".join(body) + "\n</Item>")
    s = open(WORLD).read()
    i = s.index('<string name="Name">Obstacles</string>')
    st = s.rindex("<Item", 0, i)
    en = DG.item_span(s, st)
    head = s[st:s.index("</Properties>", st) + len("</Properties>")]
    s = s[:st] + head + "\n" + "\n".join(models) + "\n</Item>" + s[en:]
    open(WORLD, "w").write(s)
    return len(models), parts_total


def ocean_main(out):
    """The ocean's plan and a few ride views only, into its own folder."""
    os.makedirs(out, exist_ok=True)
    course = Course()
    items = course.build()
    plan(course, items, os.path.join(out, "ocean_plan.png"), only=("Ocean",))
    for k, z in enumerate((-10400, -16000, -22000)):
        ride_view(course, items, z, True, os.path.join(out, f"ocean_ride{k + 1}.png"))
    print(sum(it["biome"] == "Ocean" for it in items), "ocean placements")


def main(out):
    os.makedirs(out, exist_ok=True)
    course = Course()
    items = course.build()
    with open(os.path.join(out, "layout.json"), "w") as f:
        json.dump(items, f, indent=1)
    plan(course, items, os.path.join(out, "plan.png"))
    ride_view(course, items, -330, False, os.path.join(out, "ride_meadow.png"))
    ride_view(course, items, -1100, True, os.path.join(out, "ride_desert.png"))
    ride_view(course, items, -4000, True, os.path.join(out, "ride_snow.png"))
    ride_view(course, items, -10400, True, os.path.join(out, "ride_ocean.png"))
    counts = {}
    for it in items:
        counts[it["asset"]] = counts.get(it["asset"], 0) + 1
    print(len(items), "placements", counts)
    if "--map" in sys.argv:
        print("wrote %d obstacles (%d parts) into World.Obstacles" % write_obstacles(items))


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    if "--ocean" in sys.argv:
        ocean_main(args[0] if args else "/mnt/project-files/biomes/ocean")
    else:
        main(args[0] if args else "/mnt/project-files/biomes/layout")
