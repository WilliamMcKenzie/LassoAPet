"""Stick nest for the egg: a woven bowl of rotated sticks, like the nest in
Steal An Egg. Rewrites the Nest model inside src/world/World.rbxmx (keeping
its EggSpot) and renders a preview with the horse egg sitting in it.

Run: python3 tools/nest_design.py [preview.png] [--write]
The nest is seeded, so re-running gives the same sticks. Nest-local
coordinates: centre on the ground at the origin; the egg's base sits at y 0.4.
"""

import json
import math
import os
import random
import re
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
from partlib import Part, T, Rx, Ry, Rz, render  # noqa: E402

WORLD = os.path.join(os.path.dirname(__file__), "..", "src", "world", "World.rbxmx")
EGG = os.path.join(os.path.dirname(__file__), "..", "designs", "eggs", "Egg6_PonyOcto.bbmodel")

BROWNS = [(143, 74, 44), (122, 62, 38), (160, 88, 54), (104, 53, 33), (134, 70, 41), (150, 80, 48)]


def ring_frame(a, r, y):
    """Stick on a ring: local X along the ring, Y up, Z pointing inward."""
    X = np.array([-math.sin(a), 0, math.cos(a)])
    Y = np.array([0, 1.0, 0])
    Z = np.cross(X, Y)
    m = np.eye(4)
    m[:3, :3] = np.stack([X, Y, Z], axis=1)
    m[:3, 3] = (r * math.cos(a), y, r * math.sin(a))
    return m


def nest(seed=7):
    rnd = random.Random(seed)
    parts = []

    def stick(name, length, w, h, cf):
        parts.append(Part(name, (length, h, w), cf, rnd.choice(BROWNS), plain=True))

    # floor: a criss-cross mat the egg sits on
    for i in range(30):
        a, d = rnd.uniform(0, 2 * math.pi), math.sqrt(rnd.random()) * 2.0
        stick(f"Floor{i}", rnd.uniform(3.2, 4.6), rnd.uniform(0.3, 0.42), 0.24,
              T(d * math.cos(a), rnd.uniform(0.12, 0.3), d * math.sin(a))
              @ Ry(rnd.uniform(0, 180)) @ Rz(rnd.uniform(-5, 5)) @ Rx(rnd.uniform(-8, 8)))

    # rim: rings of sticks woven round, each layer wider and leaning further out
    for layer in range(5):
        r = 2.2 + 0.34 * layer
        y = 0.22 + 0.24 * layer
        n = 13 + 2 * layer
        lean = 18 + 7 * layer
        for j in range(n):
            a = 2 * math.pi * (j + rnd.uniform(-0.25, 0.25)) / n
            length = 2 * math.pi * r / n * rnd.uniform(1.35, 1.8)
            cf = (ring_frame(a, r + rnd.uniform(-0.12, 0.12), y + rnd.uniform(-0.06, 0.06))
                  @ Ry(rnd.uniform(-12, 12)) @ Rz(rnd.uniform(-9, 9)) @ Rx(-lean + rnd.uniform(-6, 6)))
            stick(f"Rim{layer}_{j}", length, rnd.uniform(0.38, 0.5), rnd.uniform(0.26, 0.34), cf)

    # strays: loose sticks poking out of the rim at odd angles
    for i in range(14):
        a = 2 * math.pi * (i + rnd.uniform(-0.4, 0.4)) / 14
        r = rnd.uniform(3.1, 3.7)
        cf = (ring_frame(a, r, rnd.uniform(0.7, 1.3))
              @ Ry(rnd.choice([-1, 1]) * rnd.uniform(25, 50)) @ Rz(rnd.uniform(-18, 18)) @ Rx(-rnd.uniform(20, 45)))
        stick(f"Stray{i}", rnd.uniform(2.2, 3.4), rnd.uniform(0.24, 0.32), rnd.uniform(0.2, 0.26), cf)
    return parts


# ---------------------------------------------------------------- World.rbxmx

def color_uint(c):
    return (255 << 24) | (c[0] << 16) | (c[1] << 8) | c[2]


def part_xml(p, ref, origin):
    R = p.cf[:3, :3]
    x, y, z = p.cf[:3, 3] + origin
    cf = "".join(f"<{k}>{round(v, 4):g}</{k}>" for k, v in (("X", x), ("Y", y), ("Z", z)))
    cf += "".join(f"<R{i}{j}>{round(R[i, j], 6):g}</R{i}{j}>" for i in range(3) for j in range(3))
    sx, sy, sz = (round(v, 3) for v in p.size)
    return "\n".join([
        f'<Item class="Part" referent="{ref}"><Properties>',
        f'<string name="Name">{p.name}</string>',
        '<bool name="Anchored">true</bool>',
        '<bool name="CanCollide">false</bool>',
        '<bool name="CanQuery">false</bool>',
        '<token name="Material">272</token>',
        f'<Vector3 name="size"><X>{sx:g}</X><Y>{sy:g}</Y><Z>{sz:g}</Z></Vector3>',
        f'<Color3uint8 name="Color3uint8">{color_uint(p.color)}</Color3uint8>',
        *(f'<token name="{f}Surface">0</token>' for f in ("Top", "Bottom", "Front", "Back", "Left", "Right")),
        f'<CoordinateFrame name="CFrame">{cf}</CoordinateFrame>',
        "</Properties>",
        "</Item>",
    ])


def rewrite_world(parts):
    s = open(WORLD).read()
    head = re.search(r'<Item class="Model" referent="[^"]+"><Properties>\s*<string name="Name">Nest</string>\s*</Properties>\n', s)
    start = head.end()
    spot = re.search(r'<Item class="Part" referent="([^"]+)"><Properties>\s*<string name="Name">(Egg|EggSpot)</string>', s[start:])
    spot_start = start + spot.start()
    # EggSpot keeps its CFrame and PointLight; it's an invisible marker now
    spot_xml = s[spot_start:]
    end = spot_xml.find("</Item>\n</Item>\n</Item>\n</roblox>")
    body = spot_xml[:end]
    body = body.replace('<string name="Name">Egg</string>', '<string name="Name">EggSpot</string>')
    body = re.sub(r'<Item class="SpecialMesh".*?</Item>\n', "", body, flags=re.S)
    if '<float name="Transparency">' not in body.split("</Properties>")[0]:
        body = body.replace("<bool name=\"CanCollide\">false</bool>",
                            "<bool name=\"CanCollide\">false</bool>\n<float name=\"Transparency\">1</float>", 1)
    m = re.search(r'<CoordinateFrame name="CFrame"><X>([-\d.]+)</X><Y>[-\d.]+</Y><Z>([-\d.]+)</Z>', body)
    origin = np.array([float(m.group(1)), 0, float(m.group(2))])
    sticks = "\n".join(part_xml(p, f"NEST{i:04X}", origin) for i, p in enumerate(parts))
    s = s[:start] + sticks + "\n" + body + spot_xml[end:]
    open(WORLD, "w").write(s)
    return origin


def preview(parts, path):
    from horse_rig import pose
    model = json.load(open(EGG))
    egg = pose(model, None, 0)
    for p in egg:
        p.polys = [q + np.array([0, 0.4, 0]) for q in p.polys]
    from PIL import Image
    views = [dict(eye=(-9, 7.5, -10), target=(0, 1.2, 0)), dict(eye=(-3, 11, -6), target=(0, 0.5, 0)),
             dict(eye=(-13, 2.2, -1), target=(0, 1.3, 0))]
    tiles = [render(parts + egg, W=480, H=480, fov=40, **v) for v in views]
    im = Image.new("RGB", (480 * len(tiles), 480))
    for i, t in enumerate(tiles):
        im.paste(t, (480 * i, 0))
    im.save(path)


if __name__ == "__main__":
    ps = nest()
    print(len(ps), "sticks")
    paths = [a for a in sys.argv[1:] if not a.startswith("--")]
    if paths:
        preview(ps, paths[0])
    if "--write" in sys.argv:
        print("nest at", rewrite_world(ps))
