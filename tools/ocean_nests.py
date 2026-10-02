"""Copy a desert nest into World.Nests at each ocean nest (ocean_ground.NESTS).

Run: python3 tools/ocean_nests.py (again after a length change: it moves them). Nests read their biome from where they
stand (Config), so a copy moved into the ocean becomes an ocean egg spawn.
"""

import os
import re
import sys

sys.path.insert(0, os.path.dirname(__file__))
from ocean_ground import NESTS  # noqa: E402

PATH = os.path.join(os.path.dirname(__file__), "..", "src", "world", "World.rbxmx")
SRC, SRC_AT = "NS3_0417", (16, -980)


def strip(s, prefix):
    """Take out the nest models a previous run wrote (referents prefix<n>_0000)."""
    while True:
        m = re.search(r'\n?<Item class="Model" referent="%s\d+_0000">' % prefix, s)
        if not m:
            return s
        a = m.start() + (1 if s[m.start()] == "\n" else 0)
        depth = 0
        for t in re.finditer(r"<Item\b|</Item>", s[a:]):
            depth += 1 if t.group(0) != "</Item>" else -1
            if depth == 0:
                s = s[:m.start()] + s[a + t.end():]
                break


def main():
    s = open(PATH, encoding="utf-8").read()
    s = strip(s, "ONST")  # rerunning moves them: the old ones go first
    a = s.index(f'<Item class="Model" referent="{SRC}">')
    depth, i = 0, a
    for m in re.finditer(r"<Item\b|</Item>", s[a:]):
        depth += 1 if m.group(0) != "</Item>" else -1
        if depth == 0:
            i = a + m.end()
            break
    block = s[a:i]
    out = []
    for n, (x, z) in enumerate(NESTS):
        dx, dz = x - SRC_AT[0], z - SRC_AT[1]
        refs = {}
        b = re.sub(r'referent="(\w+)"', lambda m: 'referent="%s"' % refs.setdefault(
            m.group(1), "ONST%d_%04d" % (n, len(refs))), block)

        def move(m):
            return "<X>%g</X><Y>%s</Y><Z>%g</Z>" % (round(float(m.group(1)) + dx, 4), m.group(2),
                                                     round(float(m.group(3)) + dz, 4))
        b = re.sub(r'(?<=<CoordinateFrame name="CFrame">)<X>([^<]+)</X><Y>([^<]+)</Y><Z>([^<]+)</Z>', move, b)
        out.append(b)
    s = s[:i] + "\n" + "\n".join(out) + s[i:]
    open(PATH, "w", encoding="utf-8").write(s)
    print("wrote", len(out), "ocean nests")


if __name__ == "__main__":
    main()
