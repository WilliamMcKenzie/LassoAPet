"""Check the saved map for wall faces that show plain studs.

Every side face of a Wall part in src/world/World.rbxmx that is not fully
covered by another wall must carry a Checker texture, and its edges must
sit on the 8-stud grid so the checker lines up with its neighbours.

    python3 tools/check_walls.py
"""

import re
import sys
from pathlib import Path

MAP = Path(__file__).resolve().parent.parent / "src" / "world" / "World.rbxmx"
FACES = {0: "Right", 2: "Back", 3: "Left", 5: "Front"}  # NormalId values of the four sides


def parse(text):
    walls = []
    for item in re.finditer(r'<Item class="Part"[^>]*>\s*<Properties>(.*?)</Properties>(.*?)(?=<Item class="Part"|</roblox>)', text, re.S):
        props, children = item.groups()
        if '<string name="Name">Wall</string>' not in props:
            continue
        size = [float(v) for v in re.search(r'<Vector3 name="size"><X>(.*?)</X><Y>(.*?)</Y><Z>(.*?)</Z>', props).groups()]
        pos = [float(v) for v in re.search(r'<CoordinateFrame name="CFrame"><X>(.*?)</X><Y>(.*?)</Y><Z>(.*?)</Z>', props).groups()]
        lo = [p - s / 2 for p, s in zip(pos, size)]
        hi = [p + s / 2 for p, s in zip(pos, size)]
        checkered = {int(f) for f in re.findall(r'<string name="Name">Checker</string>.*?<token name="Face">(\d)</token>', children, re.S)}
        walls.append((lo, hi, checkered))
    return walls


def covered(point, walls, skip):
    return any(all(lo[i] <= point[i] <= hi[i] for i in range(3)) for j, (lo, hi, _) in enumerate(walls) if j != skip)


def face_samples(lo, hi, face):
    # Points just outside the face, on a 2-stud grid across it.
    axis, sign = {0: (0, 1), 3: (0, -1), 2: (2, 1), 5: (2, -1)}[face]
    u = 2 if axis == 0 else 0
    at = (hi if sign > 0 else lo)[axis] + 0.01 * sign
    for a in range(int(lo[u]) + 1, int(hi[u]), 2):
        for y in range(int(lo[1]) + 1, int(hi[1]), 2):
            p = [0.0, float(y), 0.0]
            p[axis], p[u] = at, float(a)
            yield p


def main():
    walls = parse(MAP.read_text())
    problems = []
    for i, (lo, hi, checkered) in enumerate(walls):
        name = f"Wall x {lo[0]:g}..{hi[0]:g} z {lo[2]:g}..{hi[2]:g}"
        if any(v % 8 for v in (lo[0], hi[0], lo[2], hi[2])):
            problems.append(f"{name}: edge off the 8-stud grid")
        for face, label in FACES.items():
            exposed = any(not covered(p, walls, i) for p in face_samples(lo, hi, face))
            if exposed and face not in checkered:
                problems.append(f"{name}: {label} face is visible but has no Checker")
    print(f"{len(walls)} walls checked")
    for p in problems:
        print("FAIL", p)
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
