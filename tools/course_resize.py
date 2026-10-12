"""Re-lengths the course's biomes, one pass at a time (SEGMENTS below is the latest).

Pass 2 (QM, Oct 11): the Desert 1.5x as long, 1208 -> 1816, by repeating its middle
608 studs; everything past it moves 608 further out. Course 21136 -> 21744.
(Pass 1, the pacing ladder, balance/pacing_ladder_v1.md, is in git history: Meadow
760 -> 2168, Desert 2280 -> 1208, Snow 5472 -> 1920, Ocean 7680 -> 3120, Volcano
7680 -> 5040, Jurassic 7680 kept.)

Run once per pass, on the straight course, from the repo root:
    python3 tools/course_resize.py

It works on the pieces no builder redraws: World.Walls, World.Obstacles, World.Nests (and
World.Decor), plus the rock list in tools/biome_rocks.luau (ITEMS). SEGMENTS maps old z
to new: a shrunk biome keeps its first stretch (what lies past is dropped), a grown one
repeats its middle. Parts crossing a cut are trimmed to it; models go by their middle.
The floors are redrawn by their builders at the new spots instead (desert_ground,
snow_ground, ocean_ground, volcano, jurassic: their constants already say the new
lengths), and volcano.py / jurassic.py also redraw their walls, nests and the ribcage,
so those are left to them here.

Shifts are whole multiples of 16 studs, so the 8-stud cells and the 4-stud checker keep
their parity. Don't run a pass twice: it reads the world as it is.
"""
import math
import os
import re
import sys
import xml.etree.ElementTree as ET

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WORLD = os.path.join(ROOT, "src", "world", "World.rbxmx")
ROCKS = os.path.join(ROOT, "tools", "biome_rocks.luau")
INF = math.inf

# (hi, lo, shift): what lies in lo < z <= hi (old, straight course) moves by shift
SEGMENTS = [
    (INF, -3080, 0),           # home, the Meadow and the Desert's first 912
    (-2472, -3080, -608),      # the Desert's middle 608, again: -3080 to -3688
    (-3080, -INF, -608),       # the Desert's last 296 (it ends at -3984) and all past it
]
REDRAWN = re.compile(r"^(VWAL|JWAL|VNST|JNST|JRIB)")  # volcano.py / jurassic.py write these
MIN_PIECE = 0.5


def prop(item, name):
    props = item.find("Properties")
    for c in props:
        if c.get("name") == name:
            return c
    return None


def cframe(item):
    return prop(item, "CFrame")


def z_extent(item):
    """A part's z span (lo, hi) on the straight course, and which local axis lies along z."""
    c = cframe(item)
    s = prop(item, "size") if prop(item, "size") is not None else prop(item, "Size")
    z = float(c.find("Z").text)
    size = [float(s.find(k).text) for k in "XYZ"]
    r2 = [float(c.find(k).text) for k in ("R20", "R21", "R22")]
    half = sum(abs(r) * sz for r, sz in zip(r2, size)) / 2
    axis = max(range(3), key=lambda k: abs(r2[k]))
    return z - half, z + half, axis, size, abs(r2[axis]) > 0.999


def model_z(item):
    zs = [float(c.find("Z").text) for c in item.iter("CoordinateFrame") if c.get("name") == "CFrame"]
    return (min(zs) + max(zs)) / 2 if zs else None


def shift_all(item, dz):
    for c in item.iter():
        if c.tag in ("CoordinateFrame", "OptionalCoordinateFrame") and c.get("name") in ("CFrame", "WorldPivotData"):
            zc = c.find("Z") if c.tag == "CoordinateFrame" else c.find("CFrame/Z")
            if zc is not None:
                zc.text = "%g" % round(float(zc.text) + dz, 4)


def rename(item, tag):
    """New referents through a copy (and any Ref inside it that points within it)."""
    refs = {}
    for c in item.iter("Item"):
        old = c.get("referent")
        refs[old] = old + tag
        c.set("referent", refs[old])
    for c in item.iter("Ref"):
        if c.text in refs:
            c.text = refs[c.text]


def copy(item):
    return ET.fromstring(ET.tostring(item))


def resize_part(item, lo, hi, axis, size, dz):
    c = cframe(item)
    s = prop(item, "size") if prop(item, "size") is not None else prop(item, "Size")
    size = list(size)
    size[axis] = hi - lo
    s.find("XYZ"[axis]).text = "%g" % round(size[axis], 4)
    c.find("Z").text = "%g" % round((lo + hi) / 2 + dz, 4)
    # its children (textures) have no CFrame; nested parts (none in these folders) would
    for child in item.findall("Item"):
        shift_all(child, dz)


def remap(folder):
    kept, dropped, made = 0, 0, 0
    old = folder.findall("Item")
    for item in old:
        folder.remove(item)
    out = []
    for item in old:
        ref = item.get("referent") or ""
        if REDRAWN.match(ref):
            out.append(item)
            continue
        is_part = cframe(item) is not None and (prop(item, "size") is not None or prop(item, "Size") is not None)
        pieces = []
        if is_part:
            lo, hi, axis, size, square = z_extent(item)
            for n, (shi, slo, dz) in enumerate(SEGMENTS):
                a, b = max(lo, slo), min(hi, shi)
                if b - a < MIN_PIECE:
                    continue
                if (a > lo + 1e-6 or b < hi - 1e-6) and not square:
                    a, b = lo, hi  # can't trim a turned part: keep it whole where its middle is
                    if not (slo < (lo + hi) / 2 <= shi):
                        continue
                pieces.append((n, a, b, dz))
        else:
            z = model_z(item)
            for n, (shi, slo, dz) in enumerate(SEGMENTS):
                if z is not None and slo < z <= shi:
                    pieces.append((n, None, None, dz))
            if z is None:
                pieces.append((0, None, None, 0))
        if not pieces:
            dropped += 1
            continue
        for k, (n, a, b, dz) in enumerate(pieces):
            it = item if k == 0 else copy(item)
            if k > 0:
                rename(it, "_%d" % n)
                made += 1
            if a is not None:
                resize_part(it, a, b, *z_extent(it)[2:4], dz)
            else:
                shift_all(it, dz)
            out.append(it)
        kept += 1
    for item in out:
        folder.append(item)
    return kept, dropped, made


def fix_tails(folder):
    """ElementTree hangs the text between items on their tails: one newline after each."""
    folder.text = folder.text or "\n"
    for item in folder.findall("Item"):
        item.tail = "\n"


def rocks():
    """tools/biome_rocks.luau ITEMS: { "Asset", x, z, ... } lines, by z like models."""
    s = open(ROCKS, encoding="utf-8").read()
    out, kept, dropped = [], 0, 0
    line_re = re.compile(r'^(\t\{ "[A-Za-z]+", )(-?[\d.]+), (-?[\d.]+)(,.*)$')
    for line in s.split("\n"):
        m = line_re.match(line)
        if not m:
            out.append(line)
            continue
        z = float(m.group(3))
        hit = False
        for shi, slo, dz in SEGMENTS:
            if slo < z <= shi:
                out.append("%s%s, %.2f%s" % (m.group(1), m.group(2), z + dz, m.group(4)))
                hit = True
        kept += hit
        dropped += not hit
    open(ROCKS, "w", encoding="utf-8").write("\n".join(out))
    return kept, dropped


def main():
    tree = ET.parse(WORLD)
    world = tree.getroot().find("Item")
    for folder in world.findall("Item"):
        name = prop(folder, "Name").text
        if name in ("Walls", "Obstacles", "Nests", "Decor"):
            print(name, "kept %d, dropped %d, copies %d" % remap(folder))
            fix_tails(folder)
    xml = ET.tostring(tree.getroot(), encoding="unicode", short_empty_elements=False)
    open(WORLD, "w", encoding="utf-8").write(xml + "\n")
    print("biome_rocks.luau ITEMS kept %d, dropped %d" % rocks())


if __name__ == "__main__":
    if "--dry" in sys.argv:
        print(SEGMENTS)
    else:
        main()
