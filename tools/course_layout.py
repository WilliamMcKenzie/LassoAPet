"""Where the terrain assets go along the course (a draft for QM to vet).

Run: python3 tools/course_layout.py [out_dir]

Writes layout.json (every placement: asset, x, z, yaw, y), a top-down map of
both biomes (plan.png) and two ride-view renders.

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
Desert extras: cacti prefer dry grass, sandstone chunks prefer the raised
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
from animal_designs import font  # noqa: E402

HALF_W = 56
BIOMES = [
    dict(name="Meadow", z0=0, z1=-760, nests=[(-20, -470), (22, -600), (0, -736)],
         small=["Stone", "Bush"], medium=["Boulder", "BoulderSplit"], large=[]),
    dict(name="Desert", z0=-760, z1=-1520, nests=[(16, -980), (-14, -1180), (18, -1400)],
         small=["Sandstone"], medium=["Cactus", "SandBoulder", "SandBoulderCarved"], large=["SandMound"]),
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
}
TIERS = {"small": 1, "medium": 2, "large": 3}
ENTRY = 48
BEAT = 80
NEST_CLEAR = 18
GAP = 3  # studs between any two footprints


class Course:
    def __init__(self, seed=7):
        self.rng = np.random.default_rng(seed)
        self.items = []
        self.kind = DG.layout()  # desert patches, per 8-stud cell

    def patch(self, x, z):
        """0 sand, 1 dry grass, 2 sandstone (desert only)."""
        if z > DG.Z_START:
            return 0
        i = int((x + DG.HALF_W) // DG.CELL)
        j = int((DG.Z_START - z) // DG.CELL)
        if 0 <= i < self.kind.shape[0] and 0 <= j < self.kind.shape[1]:
            return int(self.kind[i, j])
        return 0

    def fits(self, asset, x, z, biome):
        r = ASSETS[asset][0]
        if abs(x) + r > HALF_W - 1:
            return False
        if z + r > biome["z0"] - ENTRY + (ENTRY if biome["z0"] == 0 else 0) and z > biome["z0"] - ENTRY:
            return False
        if z - r < biome["z1"] + 4:
            return False
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
                y = 1.0 if self.patch(px, pz) == 2 else 0.0
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
        return self.rng.choice(biome["medium"])

    def clump(self, biome, x, z, n):
        for _ in range(n):
            self.put(self.pick_small(biome, x, z), x + self.rng.normal(0, 5), z + self.rng.normal(0, 5), biome)

    def beat(self, biome, pattern, z0, z1, busy):
        mid = (z0 + z1) / 2
        rng = self.rng
        if pattern == "scatter":
            for _ in range(2 + int(busy * 3)):
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
            side = rng.choice([-1, 1])
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
                if self.rng.random() < 0.45:
                    self.put(self.pick_small(biome, side * 50, z), side * 51, z + self.rng.normal(0, 4), biome)
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
        patterns = ["scatter", "gate", "scatter", "slalom"] if not desert else \
            ["scatter", "gate", "island", "slalom", "scatter", "island"]
        for b in range(n):
            z0 = biome["z0"] - ENTRY - b * BEAT
            busy = b / max(1, n - 1)
            self.beat(biome, patterns[b % len(patterns)], z0, z0 - BEAT, busy)
        self.edges(biome)

    def build(self):
        for b in BIOMES:
            self.biome(b)
        return self.items


# ---------------------------------------------------------------- pictures

MEADOW = [(77, 196, 63), (105, 255, 74)]
ICON = {
    "Stone": ((150, 156, 170), "square"), "Bush": ((70, 168, 58), "circle"),
    "Boulder": ((118, 124, 140), "square"), "BoulderSplit": ((118, 124, 140), "diamond"),
    "Sandstone": ((176, 116, 64), "square"), "Cactus": ((60, 150, 40), "plus"),
    "SandBoulder": ((200, 150, 90), "circle"), "SandBoulderCarved": ((200, 150, 90), "diamond"),
    "SandMound": ((226, 176, 92), "circle"),
}


def plan(course, items, path, s=2.0):
    """Top-down map: distance runs left to right, one strip per biome."""
    pad, band = 20, 34
    W = int(760 * s) + 2 * pad
    strip = int(2 * HALF_W * s)
    im = Image.new("RGB", (W, (strip + band) * 2 + 80), (255, 255, 255))
    d = ImageDraw.Draw(im)
    for bi, b in enumerate(BIOMES):
        oy = bi * (strip + band) + band

        def to_px(x, z):
            return pad + (b["z0"] - z) * s, oy + (x + HALF_W) * s

        d.text((pad, oy - band + 8), f"{b['name']}  (start line on the left, 760 studs)", fill=(30, 30, 30),
               font=font(18))
        for zi in range(190):
            for xi in range(28):
                z = b["z0"] - zi * 4 - 2
                x = -HALF_W + xi * 4 + 2
                chk = (xi + zi) % 2
                if b["name"] == "Desert":
                    k = course.patch(x, z)
                    c = (DG.SAND, DG.GRASS, DG.STONE)[k][chk]
                else:
                    c = MEADOW[chk]
                x0, y0 = to_px(x - 2, z + 2)
                d.rectangle([x0, y0, x0 + 4 * s - 1, y0 + 4 * s - 1], fill=c)
        # beat lines
        for k in range(10):
            z = b["z0"] - ENTRY - k * BEAT
            if z > b["z1"]:
                x0, y0 = to_px(-HALF_W, z)
                d.line([x0, y0, x0, y0 + strip], fill=(255, 255, 255), width=1)
        for nx, nz in b["nests"]:
            cx, cy = to_px(nx, nz)
            r = NEST_CLEAR * s
            d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=(255, 255, 255), width=2)
            d.ellipse([cx - 6, cy - 6, cx + 6, cy + 6], fill=(140, 90, 50), outline=(40, 30, 20))
            d.ellipse([cx - 3, cy - 4, cx + 3, cy + 3], fill=(255, 250, 235))
        for it in items:
            if it["biome"] != b["name"]:
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
    y = 2 * (strip + band) + 14
    x = pad
    names = {"Stone": "stone", "Bush": "bush", "Boulder": "boulder A", "BoulderSplit": "boulder B",
             "Sandstone": "sandstone", "Cactus": "cactus", "SandBoulder": "sand boulder A",
             "SandBoulderCarved": "sand boulder B", "SandMound": "sand mound"}
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
    d.text((x, y), "white ring = nest (kept clear)   white lines = beats", fill=(90, 90, 90), font=font(15))
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
    if desert:
        for zi in range(int((z_hi - z_lo) // 4)):
            for xi in range(28):
                x, z = -HALF_W + xi * 4 + 2, z_hi - zi * 4 - 2
                k = course.patch(x, z)
                top = 1 if k == 2 else 0
                c = (DG.SAND, DG.GRASS, DG.STONE)[k][(xi + zi) % 2]
                parts.append(Part("Floor", (4, top + 1, 4), T(x, (top - 1) / 2, z), c))
        partlib.GROUND = np.array(DG.SAND[1], float)
        partlib.GROUND2 = np.array(DG.SAND[0], float)
    else:
        partlib.GROUND = np.array(MEADOW[1], float)
        partlib.GROUND2 = np.array(MEADOW[0], float)
    for side in (-1, 1):
        wall = DG.WALL if desert else [(225, 150, 104), (248, 170, 114)]
        for zi in range(int((z_hi - z_lo) // 4)):
            for yi in range(4):
                parts.append(Part("Wall", (4, 4, 4), T(side * (HALF_W + 2), yi * 4 + 2, z_hi - zi * 4 - 2),
                                  wall[(zi + yi) % 2], plain=True))
    img = render(parts, eye=(0, 72, z_hi + 26), target=(0, 0, z_hi - 70), W=1000, H=640, fov=52, fog=False)
    img.save(path)


def main(out):
    os.makedirs(out, exist_ok=True)
    course = Course()
    items = course.build()
    with open(os.path.join(out, "layout.json"), "w") as f:
        json.dump(items, f, indent=1)
    plan(course, items, os.path.join(out, "plan.png"))
    ride_view(course, items, -330, False, os.path.join(out, "ride_meadow.png"))
    ride_view(course, items, -1100, True, os.path.join(out, "ride_desert.png"))
    counts = {}
    for it in items:
        counts[it["asset"]] = counts.get(it["asset"], 0) + 1
    print(len(items), "placements", counts)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "/mnt/project-files/biomes/layout")
