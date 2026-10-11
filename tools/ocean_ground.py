"""Ocean biome ground concept: sea-floor sand with seagrass beds and deep blue
trenches, coral clusters, under a blue haze with bubbles.

Run: python3 tools/ocean_ground.py --map           write it into src/world/World.rbxmx
(preview: design/volcano/quasicrystal_preview.py)

Patches on the 8-stud cells the funnel leaves in game (tools/funnel_grid.py), so the
4-stud checker lines up. Sand is the base at 0, seagrass beds stand a stud
higher, and trenches are sunk a stud. The columns along the walls, the start
and the nests stay sand.
"""

import os
import re
import sys

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
from desert_ground import rects, write_patches, CELL  # noqa: E402
import funnel_grid as FG  # noqa: E402
import quasicrystal as QC  # noqa: E402

SAND = [(236, 214, 164), (246, 228, 184)]
GRASS = [(64, 178, 122), (80, 196, 138)]  # seagrass
TRENCH = [(70, 150, 214), (86, 166, 228)]
WALL = [(236, 140, 124), (250, 160, 142)]  # salmon coral (QM)
LAVA = [(255, 110, 20), (255, 160, 40)]
HAZE = np.array([60, 150, 235.0])  # the blue the distance fades into
TRENCH_DOWN = 1
GRASS_UP = 1
LAVA_DOWN = 1
LENGTH = 200  # studs shown in the preview
OCEAN_LENGTH = 7680  # 1.4x the snow (QM, Oct 2), on the 240-stud bands
Z_START = -8512  # the ocean's near edge (the snow's far one)
# a nest about every 1100 studs
NESTS = [(16, -8932), (-14, -10032), (18, -11132), (-16, -12232), (14, -13332), (-18, -14432),
         (16, -15532)]
NEST_CLEAR = 14
START_CLEAR = 16
KINDS = ("Ground", "Grass", "Trench", "Lava")

# The ocean gets darker the further you ride (QM, Oct 2): coral reef, sand flats,
# dark rock with the first lava, volcanic abyss. At = fraction of the way along;
# everything blends between stops. Grass is seagrass at the reef and turns into
# raised dark rock (how much of each: STOPS below).
# Config.Biomes Ocean.Depths carries the same colours for WorldColors and Ocean.client.
DEPTHS = [
    dict(At=0.00, Ground=SAND, Grass=GRASS, Trench=TRENCH, Wall=WALL),
    dict(At=0.33, Ground=[(222, 196, 150), (234, 210, 166)], Grass=[(76, 150, 112), (90, 164, 124)],
         Trench=[(60, 120, 190), (74, 134, 204)], Wall=[(196, 150, 140), (212, 166, 154)]),
    dict(At=0.55, Ground=[(150, 146, 150), (164, 160, 164)], Grass=[(84, 86, 102), (96, 98, 114)],
         Trench=[(50, 80, 140), (60, 92, 152)], Wall=[(120, 116, 132), (136, 132, 148)]),
    dict(At=0.75, Ground=[(104, 104, 120), (118, 118, 134)], Grass=[(66, 68, 86), (78, 80, 98)],
         Trench=[(40, 50, 90), (50, 60, 100)], Wall=[(78, 82, 106), (92, 96, 120)]),
    dict(At=1.00, Ground=[(54, 50, 62), (66, 62, 74)], Grass=[(36, 34, 44), (46, 44, 54)],
         Trench=[(30, 30, 50), (40, 40, 60)], Wall=[(40, 38, 50), (52, 50, 62)]),
]
BAND = 240  # studs: the floor and walls are cut into bands this long, each painted its depth's colour


def depth(t):
    """The DEPTHS stops blended at fraction t."""
    t = min(max(t, 0.0), 1.0)
    for s0, s1 in zip(DEPTHS, DEPTHS[1:]):
        if t <= s1["At"]:
            f = (t - s0["At"]) / (s1["At"] - s0["At"])
            out = {}
            for key, v in s0.items():
                w = s1[key]
                if isinstance(v, list):
                    out[key] = [tuple(round(a + (b - a) * f) for a, b in zip(ca, cb)) for ca, cb in zip(v, w)]
                else:
                    out[key] = v + (w - v) * f
            return out
    return dict(DEPTHS[-1])


def colors_at(k, z):
    """The checker pair kind k is painted at z in game (its band's depth)."""
    band = (Z_START - z) // BAND
    d = depth((band + 0.5) * BAND / OCEAN_LENGTH)
    return (d["Ground"], d["Grass"], d["Trench"], LAVA, d["Wall"])[k]


# The patches are a quasicrystal (QM, Oct 11: like his map maker's atlas patterns, so
# they have a rhyme and reason): 7 waves round the circle, PATTERN studs a unit, drawn in
# game coordinates (tools/funnel_grid.py), its middle OFFSET from the ocean's start (QM:
# zoomed in and off centre, so it isn't mirrored). The highest values
# are the raised patches (seagrass, then rock), the lowest the sunk ones (trenches at
# the reef, lava deep down); Grass and Low say how much of the floor each covers at that
# depth, and the pattern decides where.
ANGLES, PATTERN = 7, 30
OFFSET = (-121.8, -427.3)  # studs (random): the pattern's middle, from the ocean's start
STOPS = [(0.00, 0.14, 0.08), (0.33, 0.06, 0.0), (0.55, 0.10, 0.0), (0.75, 0.12, 0.04), (1.00, 0.18, 0.10)]
NEST_IN = 12  # tools/funnel.luau moves each nest this far in from the wall on its side


def amounts(t):
    """(raised, sunk) share of the floor at fraction t of the way along."""
    t = min(max(t, 0.0), 1.0)
    for (t0, g0, l0), (t1, g1, l1) in zip(STOPS, STOPS[1:]):
        if t <= t1:
            f = (t - t0) / (t1 - t0)
            return g0 + (g1 - g0) * f, l0 + (l1 - l0) * f
    return STOPS[-1][1:]


def full_layout():
    """The whole ocean's floor as a funnel_grid.Grid of kinds: 0 sand, 1 seagrass / rock,
    2 trench, 3 lava. .at(x, z) reads it on the straight course."""
    grid = FG.Grid(Z_START, Z_START - OCEAN_LENGTH, BAND)
    sample = QC.value(*np.meshgrid(np.arange(-136, 136, 8) + 4.0 - OFFSET[0], np.arange(0, 8000, 8.0), indexing="ij"),
                      ANGLES, PATTERN)
    for b in grid.bands:
        X, Z = b.centres()
        q = QC.value(Z - Z_START - OFFSET[1], X - OFFSET[0], ANGLES, PATTERN)
        t = (Z_START - (b.z0 + b.z1) / 2) / OCEAN_LENGTH
        raised, sunk = amounts(t)
        kind = np.zeros(q.shape, int)
        kind[q >= np.quantile(sample, 1 - raised)] = 1
        if sunk > 0:
            kind[q <= np.quantile(sample, sunk)] = 2 if t < 0.5 else 3
        kind[[0, -1], :] = np.where(kind[[0, -1], :] >= 2, 0, kind[[0, -1], :])  # the wall columns stay flat
        kind[:, Z_START - Z[0] < START_CLEAR] = 0
        for nx, nz in NESTS:
            gx = np.sign(nx) * (FG.half_width(nz) - NEST_IN)
            kind[(abs(X - gx) < NEST_CLEAR * 1.6 + CELL / 2) & (abs(Z - nz) < NEST_CLEAR * 1.6 + CELL / 2)] = 0
        b.kind = kind
    return grid


def map_boxes(grid):
    return grid.boxes(KINDS, (0, GRASS_UP, -TRENCH_DOWN, -LAVA_DOWN), rects)


def underwater(img, seed=3, strength=0.5):
    """Blue haze, stronger toward the top (the distance), plus a bubble field."""
    a = np.asarray(img, float)
    H, W = a.shape[:2]
    ys = np.linspace(1, 0, H)[:, None, None]
    haze = 0.14 + strength * ys ** 1.6
    a = a * (1 - haze) + HAZE * haze
    out = Image.fromarray(a.clip(0, 255).astype(np.uint8)).convert("RGBA")
    layer = Image.new("RGBA", out.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    rng = np.random.default_rng(seed)
    for _ in range(70):
        x, y = rng.uniform(0, W), rng.uniform(0, H)
        r = rng.uniform(3, 12) * (0.5 + y / H)
        d.ellipse((x - r, y - r, x + r, y + r), fill=(220, 240, 255, 60), outline=(255, 255, 255, 200), width=2)
        d.ellipse((x - r * 0.5, y - r * 0.55, x - r * 0.1, y - r * 0.15), fill=(255, 255, 255, 220))
    return Image.alpha_composite(out, layer).convert("RGB")


def main():
    print("wrote", write_patches(r"OGND\d+", "OGND", map_boxes(full_layout()), template=r"DGND00000"),
          "ocean floor parts")
    glow_lava()


def glow_lava():
    """Lava patches are Neon, so they glow through the abyss haze."""
    from desert_ground import WORLD
    s = open(WORLD).read()
    s = re.sub(r'(<Item class="Part" referent="OGND\d+"><Properties>\n<string name="Name">Lava</string>\n'
               r'<bool name="Anchored">true</bool>\n)(?!<token name="Material">)',
               r'\g<1><token name="Material">288</token>\n', s)
    open(WORLD, "w").write(s)


if __name__ == "__main__" and "--map" in sys.argv:
    main()
