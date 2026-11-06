"""Dresses biomes QM hadn't yet (Nov 6) in the style of QM's Meadow, Desert and Lava, straight
into maps/world.map (the map editor's format; edit it there afterwards like anything else):

  - clusters of props hugging the corridor's edges, a big one (scale 5-10) and two or three
    small ones, every 250-400 studs, alternating sides, from that biome's Fight to Steal an
    Egg props (ServerStorage.WorldAssets)
  - a gate: two joint pillars and an arch over the course, at its narrowest, as the Meadow's
  - a couple of monoliths or ruins near the biome's end
  - in SPLIT biomes, a split route: the corridor bulges out round a stepped wall island in
    its middle, two lanes each at least LANE wide, both ends tapered in two steps

Run: python3 tools/map_dressing.py [area ...]   (default: AREAS) then save in the editor or
     python3 tools/map_bake.py. Areas that already have props are left alone.
"""
import json
import os
import random
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
WORLD = os.path.join(HERE, "..", "maps", "world.map")
sys.path.insert(0, os.path.join(HERE, "mapeditor"))
from serve import dump  # noqa: E402

AREAS = ["Ice", "Dungeon", "Forest", "Castle", "Ocean"]
SPLIT = {"Dungeon": 0.45, "Forest": 0.55}  # where along the biome its split route is (0 near, 1 far)
LANE = 160  # studs: the narrowest the course gets anywhere
SPLIT_LEN = 320  # the island's length
ISLAND_HALF = 48  # the island's half width at its widest
RAMP = 64  # studs each taper step runs

PROPS = {  # big ones (scale 5-10), small ones (2-4), accents near the end
    "Ice": (["SnowPine", "SnowPine", "Boulders"], ["Boulders", "SnowPine"], ["Monolith"]),
    "Dungeon": (["RuinPillar", "StoneBlock", "Candelabra"], ["StoneRubble", "Skull", "Ribcage", "Torch", "StoneBlockLow"], ["RuinPillarBroken", "Monolith"]),
    "Forest": (["DeadTree", "PineTall", "Boulders"], ["ForestCandle", "Boulders", "PineShort"], ["Monolith"]),
    "Castle": (["RuinPillar", "StoneBlock", "CandlePodium"], ["Candles", "Shackles", "StoneRubble"], ["RuinPillarBroken"]),
    "Ocean": (["PalmTree", "Coral", "Coral"], ["Kelp", "Sponges", "Starfish", "PalmTreeSmall"], ["Monolith"]),
}


def main(only):
    d = json.load(open(WORLD))
    cell = d["cell"]
    ox, oz = d["origin"]
    cols, nrows = d["size"]
    rows = [list(r) for r in d["rows"]]
    T = {t["id"]: t for t in d["tiles"]}

    def row_of(z):
        return int((z - oz) // cell)

    def col_of(x):
        return int((x - ox) // cell)

    def is_floor(ch):
        t = T.get(ch)
        return t is not None and not t.get("wall")

    def band(r):  # the floor run through the middle of row r, in studs: (x0, x1), or None
        row, mid = rows[r], cols // 2
        if not is_floor(row[mid]):
            return None
        a = b = mid
        while a > 0 and is_floor(row[a - 1]):
            a -= 1
        while b < cols - 1 and is_floor(row[b + 1]):
            b += 1
        return ox + a * cell, ox + (b + 1) * cell

    def tile(area, wall, top=None):
        for t in d["tiles"]:
            if t["area"] == area and bool(t.get("wall")) == wall and not t.get("liquid") and (top is None or t["top"] == top):
                if wall or t["top"] == 0:
                    return t["id"]
        return None

    report = []
    for area in d["areas"]:
        name = area["name"]
        if name not in (only or AREAS) or not area.get("bounds"):
            continue
        near, far = area["bounds"][1], area["bounds"][3]
        if any(o["type"] == "Prop" and far <= o["z"] < near for o in d["objects"]):
            report.append(name + ": has props already, left alone")
            continue
        rng = random.Random("dress " + name)
        notes = []

        # -- the split route --------------------------------------------------------------
        island = None
        if name in SPLIT:
            ground, low, high = tile(name, False), tile(name, True, 60), tile(name, True, 90)
            zc = near - (near - far) * SPLIT[name]
            z0, z1 = zc + SPLIT_LEN / 2, zc - SPLIT_LEN / 2  # (z0 nearer home)
            full = ISLAND_HALF + LANE  # the corridor's half width round the island
            for r in range(row_of(z1 - 2 * RAMP), row_of(z0 + 2 * RAMP) + 1):
                z = oz + (r + 0.5) * cell
                past = max(z - z0, z1 - z)  # studs beyond the island's ends (<= 0 alongside it)
                b = band(r)
                if not b:
                    continue
                cur = max(-b[0], b[1])
                # the corridor: full width alongside the island and a ramp past its ends, half
                # widened a ramp further, as it was beyond that (two clean steps each end)
                f = 1 if past <= RAMP else (0.5 if past <= 2 * RAMP else 0)
                want = max(cur, cur + (full - cur) * f)
                # widen: walls within want of the middle become floor
                for c in range(col_of(-want), col_of(want - 0.01) + 1):
                    if 0 <= c < cols and T.get(rows[r][c], {}).get("wall"):
                        rows[r][c] = ground
                # the island: half its width a ramp in from each end, all of it alongside
                half = ISLAND_HALF if past <= -RAMP else (ISLAND_HALF / 2 if past <= 0 else 0)
                if half > 0:
                    for c in range(col_of(-half), col_of(half - 0.01) + 1):
                        x = ox + (c + 0.5) * cell
                        rows[r][c] = high if abs(x) < half - 16 else low
            island = (z0 + RAMP, z1 - RAMP)
            notes.append("split route z %d..%d" % (z1, z0))

        def edge(z):  # the floor's half width at z (the narrower side), after any split
            b = band(row_of(z))
            return min(-b[0], b[1]) if b else None

        # -- prop clusters along the edges --------------------------------------------------
        big, small, accents = PROPS[name]
        z = near - rng.uniform(120, 260)
        side = rng.choice((-1, 1))
        clusters = 0
        while z > far + 300:
            e = edge(z)
            if e:
                x = side * (e - rng.uniform(14, 36))
                d["objects"].append({"type": "Prop", "item": rng.choice(big), "x": round(x), "z": round(z),
                                     "yaw": rng.randrange(360), "scale": round(rng.uniform(5, 10), 2), "style": name})
                for _ in range(rng.randint(2, 3)):
                    zz = z + rng.uniform(-45, 45)
                    ee = edge(zz) or e
                    xx = side * (ee - rng.uniform(6, 40))
                    d["objects"].append({"type": "Prop", "item": rng.choice(small), "x": round(xx), "z": round(zz),
                                         "yaw": rng.randrange(360), "scale": round(rng.uniform(2, 4), 2), "style": name})
                clusters += 1
            z -= rng.uniform(250, 400)
            side = -side

        # -- a gate at the narrowest point of its middle -------------------------------------
        best = None
        for zz in range(int(near - (near - far) * 0.2), int(far + (near - far) * 0.2), -cell * 4):
            if island and island[1] - 60 <= zz <= island[0] + 60:
                continue
            e = edge(zz)
            if e and (best is None or e < best[1]):
                best = (zz, e)
        if best:
            gz, ge = best
            px = ge + 124  # (the Meadow's: pillars 124 studs past the floor's edge, its arch scale 7)
            k = px / 204
            d["objects"].append({"type": "Pillar", "style": name, "kind": "joint", "x": -round(px), "z": gz, "size": 14, "height": 36, "scale": 7})
            d["objects"].append({"type": "Pillar", "style": name, "kind": "joint", "x": round(px), "z": gz, "size": 14, "height": 36, "scale": 7})
            d["objects"].append({"type": "Arch", "style": name, "x": 0, "z": gz, "scale": round(7 * k, 2), "y": round(-48 * k)})
            notes.append("gate at z %d" % gz)

        # -- accents near the end -----------------------------------------------------------
        for s in (-1, 1):
            zz = far + rng.uniform(80, 160)
            e = edge(zz)
            if e:
                d["objects"].append({"type": "Prop", "item": rng.choice(accents), "x": round(s * (e - 24)), "z": round(zz),
                                     "yaw": rng.randrange(360), "scale": 6, "style": name})
        report.append("%s: %d clusters, %s" % (name, clusters, ", ".join(notes)))

    d["rows"] = ["".join(r) for r in rows]
    open(WORLD, "w").write(dump(d))
    print("\n".join(report))


OBSTACLES = {  # small props out in the ride lane (QM, Nov 6): "obstacle": 1, only the smallest
    # animals swerve round them, bigger ones knock them away (Ride), riders smash them
    "Desert": ["CactusBarrel", "CactusBarrel", "Cactus", "Boulders", "Skull", "Femur"],
    "Lava": ["Boulders", "Boulders", "StoneRubble", "StoneBlockLow"],
}


def obstacles(only):
    """Sparse little clusters of tier-1 obstacles across the ride lanes of OBSTACLES' biomes:
    one to three small props every 120-200 studs, never more than a third of the lane across."""
    d = json.load(open(WORLD))
    cell = d["cell"]
    ox, oz = d["origin"]
    cols = d["size"][0]
    T = {t["id"]: t for t in d["tiles"]}

    def edge(z):
        row = d["rows"][int((z - oz) // cell)]
        mid = cols // 2
        a = b = mid
        while a > 0 and row[a - 1] in T and not T[row[a - 1]].get("wall"):
            a -= 1
        while b < cols - 1 and row[b + 1] in T and not T[row[b + 1]].get("wall"):
            b += 1
        return min(mid - a, b + 1 - mid) * cell

    report = []
    for area in d["areas"]:
        name = area["name"]
        if name not in (only or OBSTACLES) or not area.get("bounds"):
            continue
        near, far = area["bounds"][1], area["bounds"][3]
        if any(o.get("obstacle") and far <= o["z"] < near for o in d["objects"]):
            report.append(name + ": has obstacles already, left alone")
            continue
        rng = random.Random("obstacles " + name)
        n = 0
        z = near - rng.uniform(150, 250)
        while z > far + 120:
            e = edge(z) - 20
            cx = rng.uniform(-e * 0.75, e * 0.75)
            for _ in range(rng.choice((1, 1, 2, 2, 3))):
                d["objects"].append({"type": "Prop", "item": rng.choice(OBSTACLES[name]),
                                     "x": round(max(-e, min(e, cx + rng.uniform(-14, 14)))), "z": round(z + rng.uniform(-14, 14)),
                                     "yaw": rng.randrange(360), "scale": round(rng.uniform(1.6, 3), 2), "style": name, "obstacle": 1})
                n += 1
            z -= rng.uniform(120, 200)
        report.append("%s: %d obstacles" % (name, n))
    open(WORLD, "w").write(dump(d))
    print("\n".join(report))


if __name__ == "__main__":
    if sys.argv[1:2] == ["--obstacles"]:
        obstacles(sys.argv[2:])
    else:
        main(sys.argv[1:])
