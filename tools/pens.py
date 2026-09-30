"""Build the five player pens as a saved model, plus a preview picture.

    python3 tools/pens.py [preview.png]

Writes src/world/Pens.rbxmx (synced by Rojo to Workspace.Pens). Once it is in
Studio, QM can edit it by hand and Save to File over that path; rerunning this
script would overwrite those edits.

The pens copy the open farm pens of Roblox pet games (QM's references): low
fences on the grass, dark posts, orange wooden rails top and bottom with an X
brace in every span, and a gap in one side. Three stand along the back wall
with their gaps facing the start line, and one sits in each front corner of the
base with its gap facing in. Each covers exactly N x N floor tiles.

Each PenN model also holds invisible markers the scripts read:
  Spawn  where the owner appears, outside the gap
  Sign   above the gap; the server hangs the owner's picture and name on it
  Area   the ground the pets wander over
  Tiles  the pen's N x N floor tiles, for recolouring them
  Slots  one invisible part per pet spot (all of the owner's pets live here);
         Slot1 is just inside the gap, where the pet you ride sets off from
"""

import math
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import partlib  # noqa: E402

OUT = Path(__file__).resolve().parent.parent / "src" / "world" / "Pens.rbxmx"

TILE = 4  # the floor's checker squares
N = 12  # each pen covers exactly N x N floor tiles (so the pen's tiles can be recoloured)
SIZE = N * TILE
GATE = 10
# Pens in claim order: (centre x, centre z, the way the open side faces).
# Three along the back wall facing the start line, and one in each front corner
# of the base facing in. Edges sit on tile lines; the base is x -112..112, z 0..104.
PENS = [
    (0, 80, "front"),
    (-56, 80, "front"),
    (56, 80, "front"),
    (-88, 24, "right"),
    (88, 24, "left"),
]
# Local pen frame: centred on the pen, open side at z = -SIZE / 2 facing -z.
# These map it onto the world for each facing.
FACING = {
    "front": ((1, 0, 0), (0, 1, 0), (0, 0, 1)),
    "right": ((0, 0, -1), (0, 1, 0), (1, 0, 0)),  # open side faces +x
    "left": ((0, 0, 1), (0, 1, 0), (-1, 0, 0)),  # open side faces -x
}
FRONT = -SIZE / 2
SPAWN_Z = FRONT - 6
SLOTS = [(0, FRONT + 6)] + [(x, FRONT + dz) for dz, xs in ((20, (-12, 12)), (34, (-14, 0, 14))) for x in xs]

POST_COLOR = (62, 62, 72)
RAIL_COLOR = (204, 108, 52)
POST, POST_H = 1.2, 4
SPAN = 6  # longest gap between posts
RAIL_H, RAIL_T = 0.5, 0.5  # rail height and thickness
RAILS_Y = (0.9, 3.3)  # rail centres
BRACE_W = 0.4


def rot_y(deg):
    return partlib.Ry(deg)[:3, :3]


def pen_parts(cx, cz, facing):
    parts = []  # (name, size, centre, rotation 3x3, colour, visible), local frame first

    def box(name, lo, hi, color=RAIL_COLOR, visible=True):
        lo, hi = np.array(lo, float), np.array(hi, float)
        parts.append((name, hi - lo, (lo + hi) / 2, np.eye(3), color, visible))

    x0, x1 = -SIZE / 2, SIZE / 2
    z0, z1 = FRONT, SIZE / 2
    g0, g1 = -GATE / 2, GATE / 2

    runs = [  # fence runs, start -> end on the ground
        ((x0, z0), (g0, z0)),
        ((g1, z0), (x1, z0)),
        ((x0, z0), (x0, z1)),
        ((x1, z0), (x1, z1)),
        ((x0, z1), (x1, z1)),
    ]
    posts = set()
    p = POST / 2
    lo_y, hi_y = RAILS_Y[0] + RAIL_H / 2, RAILS_Y[1] - RAIL_H / 2
    for (ax, az), (bx, bz) in runs:
        a, b = np.array([ax, az]), np.array([bx, bz])
        length = float(np.linalg.norm(b - a))
        along = (b - a) / length
        n = max(1, math.ceil(length / SPAN - 1e-9))
        stops = [a + along * length * k / n for k in range(n + 1)]
        for s in stops:
            posts.add((round(s[0], 4), round(s[1], 4)))
        yaw = 0 if abs(along[0]) > 0.5 else 90  # rails run along local X
        R = rot_y(yaw)
        mid = (a + b) / 2
        for y in RAILS_Y:
            parts.append(("Rail", np.array([length, RAIL_H, RAIL_T]), np.array([mid[0], y, mid[1]]), R, RAIL_COLOR, True))
        # an X in every span, between the posts and the rails
        for k in range(n):
            s0 = stops[k] + along * p
            s1 = stops[k + 1] - along * p
            w = float(np.linalg.norm(s1 - s0))
            h = hi_y - lo_y
            angle = math.degrees(math.atan2(h, w))
            c = (s0 + s1) / 2
            for sign, depth in ((1, 0.34), (-1, 0.3)):  # different depths so the crossing faces never z-fight
                Rb = R @ partlib.Rz(sign * angle)[:3, :3]
                size = np.array([math.hypot(w, h) - BRACE_W * 0.5, BRACE_W, depth])
                parts.append(("Brace", size, np.array([c[0], (lo_y + hi_y) / 2, c[1]]), Rb, RAIL_COLOR, True))
    for x, z in sorted(posts):
        box("Post", (x - p, 0, z - p), (x + p, POST_H, z + p), POST_COLOR)

    box("Spawn", (-2, 0, SPAWN_Z - 2), (2, 1, SPAWN_Z + 2), visible=False)
    box("Sign", (-1, 8, z0 - 1), (1, 10, z0 + 1), visible=False)
    box("Area", (x0 + 4, 0, z0 + 4), (x1 - 4, 1, z1 - 4), visible=False)
    box("Tiles", (x0, 0, z0), (x1, 0.2, z1), visible=False)  # the N x N floor tiles under the pen
    for i, (sx, sz) in enumerate(SLOTS, 1):
        box(f"Slot{i}", (sx - 2, 0, sz - 2), (sx + 2, 1, sz + 2), visible=False)

    M = np.array(FACING[facing], float)
    out = []
    for name, size, centre, R, color, visible in parts:
        world = M @ centre + np.array([cx, 0, cz])
        if visible:
            out.append((name, size, world, M @ R, color, visible))
        else:  # markers stay axis-aligned (the scripts read their boxes)
            out.append((name, np.abs(M @ size), world, np.eye(3), color, visible))
    return out


def xml_part(ref, name, size, centre, R, color, visible):
    r, g, b = color
    rgb = (255 << 24) | (r << 16) | (g << 8) | b
    extra = "" if visible else (
        '<float name="Transparency">1</float>\n<bool name="CanCollide">false</bool>\n'
        '<bool name="CanQuery">false</bool>\n<bool name="CanTouch">false</bool>\n'
        '<bool name="CastShadow">false</bool>\n')
    top = 3 if visible else 0
    rot = "".join(f"<R{i}{j}>{R[i, j]:.6g}</R{i}{j}>" for i in range(3) for j in range(3))
    return (
        f'<Item class="Part" referent="{ref()}"><Properties>\n'
        f'<string name="Name">{name}</string>\n'
        '<bool name="Anchored">true</bool>\n'
        f'<Vector3 name="size"><X>{size[0]:.4g}</X><Y>{size[1]:.4g}</Y><Z>{size[2]:.4g}</Z></Vector3>\n'
        f'<Color3uint8 name="Color3uint8">{rgb}</Color3uint8>\n'
        f'<token name="TopSurface">{top}</token>\n'
        '<token name="BottomSurface">0</token>\n'
        f'{extra}'
        f'<CoordinateFrame name="CFrame"><X>{centre[0]:.6g}</X><Y>{centre[1]:.6g}</Y><Z>{centre[2]:.6g}</Z>{rot}'
        '</CoordinateFrame>\n'
        '</Properties></Item>\n'
    )


def write():
    n = [0]

    def ref():
        n[0] += 1
        return f"RBX{n[0]:08X}"

    out = ['<roblox version="4">\n', f'<Item class="Folder" referent="{ref()}"><Properties>\n<string name="Name">Pens</string>\n</Properties>\n']
    for i, pen in enumerate(PENS, 1):
        out.append(f'<Item class="Model" referent="{ref()}"><Properties>\n<string name="Name">Pen{i}</string>\n</Properties>\n')
        slots = []
        for part in pen_parts(*pen):
            if part[0].startswith("Slot"):
                slots.append(part)
            else:
                out.append(xml_part(ref, *part))
        out.append(f'<Item class="Folder" referent="{ref()}"><Properties>\n<string name="Name">Slots</string>\n</Properties>\n')
        out += [xml_part(ref, *s) for s in slots]
        out.append("</Item>\n</Item>\n")
    out.append("</Item>\n</roblox>\n")
    OUT.write_text("".join(out))


def visible_parts(pen):
    out = []
    for name, size, centre, R, color, visible in pen_parts(*pen):
        if visible:
            cf = np.eye(4)
            cf[:3, :3] = R
            cf[:3, 3] = centre
            out.append(partlib.Part(name, size, cf, color))
    return out


def preview(path):
    parts = []
    for pen in PENS:
        parts += visible_parts(pen)
        # stand-ins for pets wandering about
        M = np.array(FACING[pen[2]], float)
        for dx, dz, yaw in ((0, 8, 0), (-12, 22, 40), (10, 30, -70)):
            p = M @ np.array([dx, 0, FRONT + dz]) + np.array([pen[0], 0, pen[1]])
            cf = partlib.T(p[0], 2.5, p[2]) @ partlib.Ry(yaw)
            parts.append(partlib.Part("Pet", (3, 5, 8), cf, (226, 130, 50), plain=True))
    wall = (240, 160, 108)
    for lo, hi in [((-120, 0, -8), (-112, 20, 104)), ((112, 0, -8), (120, 20, 104)), ((-120, 0, 104), (120, 20, 112)),
                   ((-112, 0, -8), (-56, 20, 0)), ((56, 0, -8), (112, 20, 0))]:
        lo, hi = np.array(lo, float), np.array(hi, float)
        parts.append(partlib.Part("Wall", hi - lo, partlib.T(*((lo + hi) / 2)), wall, plain=True))
    parts.append(partlib.Part("StartLine", (112, 0.2, 4), partlib.T(0, 0.1, -2), (30, 30, 30), plain=True))
    img = partlib.render(parts, eye=(0, 130, -60), target=(0, 0, 50), W=1400, H=900, fov=62)
    img.save(path)


if __name__ == "__main__":
    write()
    if len(sys.argv) > 1:
        preview(sys.argv[1])
