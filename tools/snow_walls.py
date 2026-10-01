"""Side walls (and their caps) for the snow biome, and the far wall moved to its end.

Run once: python3 tools/snow_walls.py
Copies the desert's wall and cap parts (World.Walls) for each snow segment.
Segments are under Roblox's 2048-stud part limit (4 per side, about 1710 each),
with their ends on the 8-stud grid so the checker lines up (tools/check_walls.py).
The far wall goes to the new course end. Run again, it moves the snow segments
already in the map onto the current bounds.
"""

import os
import re
import sys

sys.path.insert(0, os.path.dirname(__file__))
from desert_ground import WORLD, item_span  # noqa: E402

Z0, LENGTH, SEGMENTS = -3040, 6840, 4
END = Z0 - LENGTH
WALL = {-1: "RBXD86D2024CE624C54A839341A912CBAF4", 1: "RBX4834AEC1E5A1412D9DEF9C9BF7AAC73C"}
CAP = {-1: "RBX055398A22F8846D291BC67B3CDF3F12F", 1: "RBX070AB57E0A1F47C99DEE17B9BF361584"}
FAR_WALL, FAR_CAP = "RBX0000000A", "RBX00000013"


def item(s, ref):
    st = s.index(f'<Item class="Part" referent="{ref}"')
    return st, item_span(s, st)


def resize(xml, size, pos):
    xml = re.sub(r'<Vector3 name="size">.*?</Vector3>',
                 '<Vector3 name="size"><X>%g</X><Y>%g</Y><Z>%g</Z></Vector3>' % size, xml, count=1)
    return re.sub(r'(<CoordinateFrame name="CFrame">)<X>[^<]*</X><Y>[^<]*</Y><Z>[^<]*</Z>',
                  r'\g<1><X>%g</X><Y>%g</Y><Z>%g</Z>' % pos, xml, count=1)


def bounds():
    """Segment ends, on the 8-stud grid."""
    return [Z0 - round(LENGTH * k / SEGMENTS / 8) * 8 for k in range(SEGMENTS + 1)]


def layout():
    """(size, centre) of every snow part, in the order they're written: per side,
    per segment, the wall then its cap."""
    zs = bounds()
    out = []
    for sx in (-1, 1):
        for k in range(SEGMENTS):
            seg, zc = zs[k] - zs[k + 1], (zs[k] + zs[k + 1]) / 2
            out += [((8, 48, seg), (sx * 60, 24, zc)), ((10, 2, seg - 1), (sx * 59, 49, zc + 0.5))]
    return out


def fix(s):
    """Move the snow parts already in the map onto layout()."""
    refs = re.findall(r'<Item class="Part" referent="(SWAL\d+)"', s)
    assert len(refs) == 4 * SEGMENTS, refs
    for ref, (size, pos) in zip(refs, layout()):
        a, b = item(s, ref)
        s = s[:a] + resize(s[a:b], size, pos) + s[b:]
    return s


def main():
    s = open(WORLD).read()
    if "SWAL" in s:
        open(WORLD, "w").write(fix(s))
        print("moved the snow walls onto", bounds())
        return
    new = []
    n = 0
    shapes = iter(layout())
    for sx in (-1, 1):
        wall = s[slice(*item(s, WALL[sx]))]
        cap = s[slice(*item(s, CAP[sx]))]
        for k in range(SEGMENTS):
            for tmpl in (wall, cap):
                size, pos = next(shapes)

                def ref(m):
                    nonlocal n
                    n += 1
                    return f'referent="SWAL{n:05d}"'
                new.append(resize(re.sub(r'referent="[A-Za-z0-9]+"', ref, tmpl), size, pos))
    # the far wall and its cap at the new end
    for ref, y, dz in ((FAR_WALL, 24, -4), (FAR_CAP, 49, -3)):
        a, b = item(s, ref)
        xml = s[a:b]
        size = re.search(r'<Vector3 name="size"><X>([^<]*)</X><Y>([^<]*)</Y><Z>([^<]*)</Z>', xml).groups()
        s = s[:a] + resize(xml, tuple(float(v) for v in size), (0, y, END + dz)) + s[b:]
    a, b = item(s, WALL[1])
    s = s[:b] + "\n" + "\n".join(new) + s[b:]
    open(WORLD, "w").write(s)
    print("wrote", len(new), "snow wall parts; far wall at", END - 4)


if __name__ == "__main__":
    main()
