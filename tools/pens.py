"""Build the five player pens as a saved model, plus a preview picture.

    python3 tools/pens.py [preview.png]

Writes src/world/Pens.rbxmx (synced by Rojo to Workspace.Pens). Once it is in
Studio, QM can edit it by hand and Save to File over that path; rerunning this
script would overwrite those edits.

The pens copy the open farm pens of Roblox pet games (QM's references): low
fences on the grass, dark posts, orange wooden rails top and bottom with an X
brace in every span, and a gap in one side.

The arc base (QM, Oct 9; design/base_arc/SPEC.md): the five pens stand on one arc
round the dirt yard in the middle of the base, centre ARC, each turned to face
it (CFrame.lookAt(pen centre, ARC)) with its gap in the side facing the yard.

Pens grow as you unlock zones (QM, Oct 3): SIZES[level - 1] tiles a side, from
14 at the start to 20 once the Jurassic is open. A pen grows outward, away from
the yard: its gap stays put. At 20 tiles (80 studs) the pens fill the base (QM,
Oct 11: "take up all the space we can"): 8 studs between pens, clear of the walls,
the big rocks, Carl, the podium, the start line and every pen's ride lane. Each PenN holds
a Sizes folder with one SizeK model per level: its fence, plus copies of the
markers below laid out for that size. PenLevel.server shows the owner's size
and moves the live markers onto that size's copies.

Each PenN model also holds invisible markers the scripts read (laid out for
size 1 here):
  Spawn  where the owner appears, outside the gap
  Sign   above the gap; the server hangs the owner's picture and name on it
  Area   the ground the pets wander over
  Tiles  the pen's N x N floor (its own floor, turned with the pen, PenLevel.server)
The markers are turned with the pen too (the scripts read them in its frame).
  Slots  one invisible part per pet spot (all of the owner's pets live here);
         Slot1 is just inside the gap, where the pet you ride sets off from
"""

import math
import os
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import partlib  # noqa: E402

OUT = Path(__file__).resolve().parent.parent / "src" / "world" / "Pens.rbxmx"

TILE = 4  # the floor's checker squares
# Tiles a side at pen level 1..13: one level per quest claimed (QM, Oct 11: every claim but
# Reach Meadow), each with its own fence (STYLES). 22 (88 studs) is the most the base holds:
# 4 studs between pens, 2 from the walls, with the two middle boulders moved (BaseDecor).
SIZES = [14, 15, 16, 17, 17, 18, 19, 19, 20, 21, 21, 22, 22]
GATE = 10
HALF_W, DEPTH = 176, 264  # the home base: x -176..176, z 0..264 inside its walls
ARC = (0, 96)  # the yard's middle: every pen faces it
GATES = (78, 100, 100, 78, 78)  # each pen's gap from ARC, in claim order
ANGLES = (90, 140, 40, 190, -10)  # degrees from +x toward +z, in claim order


def _pen(angle, r):
    """(gate middle x, z, unit x, z the gap faces): the gap's r from ARC."""
    a = math.radians(angle)
    out_x, out_z = math.cos(a), math.sin(a)
    return (ARC[0] + out_x * r, ARC[1] + out_z * r, -out_x, -out_z)


# World 3's island base (QM, Oct 14: tools/world3_base.luau, 1.2x the base): WORLD=3 writes
# src/world/Pens_W3.rbxmx, pens up to 104 studs (26 tiles), fully grown centred at (0, 262),
# (-+132.4, 226.3) and (-+144.1, 89.8): the same angles round the yard's middle, 1.2x out.
if os.environ.get("WORLD") == "3":
    OUT = OUT.with_name("Pens_W3.rbxmx")
    SIZES = [round(n * 26 / 22) for n in SIZES]
    ARC = (0, 96 * 1.2)
    _full = ((0, 262), (-132.4, 226.3), (132.4, 226.3), (-144.1, 89.8), (144.1, 89.8))
    GATES = tuple(math.hypot(x - ARC[0], z - ARC[1]) - SIZES[-1] * TILE / 2 for x, z in _full)
    LIFT = 1  # (QM, Oct 14: on the light sand, a stud up: tools/world3_sandstep.luau)
LIFT = globals().get("LIFT", 0)
PENS = [_pen(a, r) for a, r in zip(ANGLES, GATES)]
# Local pen frame: centred on the pen, open side at z = -SIZE / 2 facing -z.


def frame(fx, fz):
    """The pen's rotation: local -z (its gap) faces (fx, fz), like CFrame.lookAt."""
    look = np.array([fx, 0.0, fz])
    up = np.array([0.0, 1.0, 0.0])
    right = np.cross(look, up)
    return np.column_stack([right, up, -look])
SLOTS = [(0, 6)] + [(x, dz) for dz, xs in ((20, (-12, 12)), (34, (-14, 0, 14))) for x in xs]  # from the gap

POST_COLOR = (62, 62, 72)
RAIL_COLOR = (204, 108, 52)
POST, POST_H = 1.2, 4
SPAN = 6  # longest gap between posts
RAIL_H, RAIL_T = 0.5, 0.5  # rail height and thickness
RAILS_Y = (0.9, 3.3)  # rail centres
BRACE_W = 0.4


def rot_y(deg):
    return partlib.Ry(deg)[:3, :3]


# Fence styles for previews (QM, Oct 11). In game the fence is the biome's (src/server/PenFence, QM Oct 12). Studded
# blocks in bright colours, as the rest of the game. Uprights are named Post and the long
# pieces Rail or Brace, so the VIP pass's gold fence repaints them (PenLevel.server);
# everything else (Wall, Trim) keeps its colours.
WHITE, GOLD = (245, 245, 240), (255, 196, 54)
STYLES = [
    # 1. the old fence: dark posts, orange rails, an X in every span
    dict(post=(1.2, 4, POST_COLOR), rails=[(0.9, 0.5, 0.5, RAIL_COLOR), (3.3, 0.5, 0.5, RAIL_COLOR)], braces=RAIL_COLOR),
    # 2. white picket
    dict(post=(1.2, 4.2, (150, 190, 230)), rails=[(1.2, 0.4, 0.3, WHITE), (2.8, 0.4, 0.3, WHITE)],
         slats=dict(w=0.5, gap=0.6, h=(3.4, 3.0), color=WHITE, depth=0.3)),
    # 3. ranch: three plain rails
    dict(post=(1.4, 4.2, (112, 72, 44)), rails=[(1.0, 0.6, 0.6, (176, 118, 70)), (2.2, 0.6, 0.6, (176, 118, 70)), (3.4, 0.6, 0.6, (176, 118, 70))]),
    # 4. low stone wall with capped pillars
    dict(post=(1.8, 3.2, (128, 128, 136)), cap=(2.2, 0.4, (196, 196, 204)), wall=(2.2, 1.2, (162, 162, 170))),
    # 5. log fence
    dict(post=(1.5, 4.4, (92, 58, 36)), cap=(1.9, 0.4, (128, 84, 52)),
         rails=[(0.8, 0.9, 0.9, (150, 98, 58)), (1.9, 0.9, 0.9, (150, 98, 58)), (3.0, 0.9, 0.9, (150, 98, 58))]),
    # 6. hedge with topiary posts
    dict(post=(2.0, 3.8, (52, 140, 56)), cap=(2.4, 1.2, (72, 176, 70)), wall=(3.0, 1.6, (64, 160, 62))),
    # 7. red brick with white caps
    dict(post=(1.8, 3.8, (156, 60, 48)), cap=(2.2, 0.5, WHITE), wall=(2.8, 1.2, (186, 78, 60))),
    # 8. bamboo
    dict(post=(0.9, 4.4, (60, 130, 50)), rails=[(1.2, 0.35, 0.35, (40, 96, 40)), (2.6, 0.35, 0.35, (40, 96, 40))],
         slats=dict(w=0.7, gap=0.25, h=(3.4, 4.0, 3.7), color=(118, 196, 84), depth=0.7)),
    # 9. ice: see-through blocks, white posts with blue caps
    dict(post=(1.6, 3.6, (236, 246, 255)), cap=(2.0, 0.5, (120, 190, 255)),
         wall=(2.4, 1.2, (170, 220, 255)), wall_transparency=0.3),
    # 10. reef: teal posts with pink coral caps, rope rails
    dict(post=(1.4, 4.0, (40, 170, 170)), cap=(1.9, 0.9, (255, 120, 170)),
         rails=[(1.6, 0.35, 0.35, (222, 196, 140)), (3.0, 0.35, 0.35, (222, 196, 140))]),
    # 11. volcano: basalt posts with glowing tops, a glowing lava rail
    dict(post=(1.6, 4.4, (54, 44, 44)), cap=(1.0, 0.6, (255, 120, 30), "Neon"),
         rails=[(1.0, 0.6, 0.6, (70, 56, 54)), (2.2, 0.3, 0.3, (255, 110, 30), "Neon"), (3.4, 0.6, 0.6, (70, 56, 54))]),
    # 12. bone
    dict(post=(1.0, 4.0, (240, 232, 210)), cap=(1.7, 0.8, (250, 244, 228)), foot=(1.7, 0.8, (250, 244, 228)),
         rails=[(1.4, 0.5, 0.5, (226, 216, 190)), (2.8, 0.5, 0.5, (226, 216, 190))]),
    # 13. royal: gold posts with lanterns, purple rails, gold X braces
    dict(post=(1.4, 4.6, GOLD), cap=(1.0, 1.0, (255, 236, 140), "Neon"),
         rails=[(0.9, 0.6, 0.6, (126, 70, 200)), (3.3, 0.6, 0.6, (126, 70, 200))], braces=GOLD),
]


def fence_parts(runs, st, parts):
    """The fence along each run (start -> end on the ground, in the pen's frame) in style st."""
    def add(name, size, centre, R=np.eye(3), color=RAIL_COLOR, material=None, transparency=0):
        parts.append((name, np.array(size, float), np.array(centre, float), R, color, True, material, transparency))

    pw, ph, pcolor = st["post"]
    posts = set()
    for (ax, az), (bx, bz) in runs:
        a, b = np.array([ax, az]), np.array([bx, bz])
        length = float(np.linalg.norm(b - a))
        along = (b - a) / length
        n = max(1, math.ceil(length / SPAN - 1e-9))
        stops = [a + along * length * k / n for k in range(n + 1)]
        for s_ in stops:
            posts.add((round(s_[0], 4), round(s_[1], 4)))
        yaw = 0 if abs(along[0]) > 0.5 else 90  # rails run along local X
        R = rot_y(yaw)
        mid = (a + b) / 2
        for rail in st.get("rails", []):
            y, h, t, color = rail[:4]
            add("Rail", (length, h, t), (mid[0], y, mid[1]), R, color, rail[4] if len(rail) > 4 else None)
        if "wall" in st:
            h, t, color = st["wall"]
            add("Wall", (length, h, t), (mid[0], h / 2, mid[1]), R, color, None, st.get("wall_transparency", 0))
        if "slats" in st:  # upright slats between the posts, heights in turn
            sl = st["slats"]
            for k in range(n):
                s0 = stops[k] + along * pw / 2
                s1 = stops[k + 1] - along * pw / 2
                w = float(np.linalg.norm(s1 - s0))
                count = max(1, int((w + sl["gap"]) // (sl["w"] + sl["gap"])))
                pitch = w / count
                for j in range(count):
                    c = s0 + along * pitch * (j + 0.5)
                    h = sl["h"][j % len(sl["h"])]
                    add("Trim", (sl["w"], h, sl["depth"]), (c[0], h / 2, c[1]), R, sl["color"])
        if "braces" in st:  # an X in every span, between the posts and the rails
            lo_y, hi_y = RAILS_Y[0] + RAIL_H / 2, RAILS_Y[1] - RAIL_H / 2
            for k in range(n):
                s0 = stops[k] + along * pw / 2
                s1 = stops[k + 1] - along * pw / 2
                w = float(np.linalg.norm(s1 - s0))
                h = hi_y - lo_y
                angle = math.degrees(math.atan2(h, w))
                c = (s0 + s1) / 2
                for sign, depth in ((1, 0.34), (-1, 0.3)):  # different depths so the crossing faces never z-fight
                    Rb = R @ partlib.Rz(sign * angle)[:3, :3]
                    add("Brace", (math.hypot(w, h) - BRACE_W * 0.5, BRACE_W, depth), (c[0], (lo_y + hi_y) / 2, c[1]), Rb, st["braces"])
    for x, z in sorted(posts):
        add("Post", (pw, ph, pw), (x, ph / 2, z), np.eye(3), pcolor)
        if "cap" in st:
            cap = st["cap"]
            add("Trim", (cap[0], cap[1], cap[0]), (x, ph + cap[1] / 2, z), np.eye(3), cap[2], cap[3] if len(cap) > 3 else None)
        if "foot" in st:
            ft = st["foot"]
            add("Trim", (ft[0], ft[1], ft[0]), (x, ft[1] / 2, z), np.eye(3), ft[2])


def pen_parts(gx, gz, fx, fz, n=SIZES[0], style=0):
    """The pen at n tiles a side in STYLES[style]; (gx, gz) is the middle of its gap, (fx, fz) the way it faces."""
    SIZE = n * TILE
    FRONT = -SIZE / 2
    SPAWN_Z = FRONT - 6
    M = frame(fx, fz)
    # centre: half a size back from the gap (it grows away from the yard)
    cx, _, cz = M @ np.array([0, 0, SIZE / 2]) + np.array([gx, 0, gz])
    parts = []  # (name, size, centre, rotation 3x3, colour, visible), local frame first

    def box(name, lo, hi, color=RAIL_COLOR, visible=True):
        lo, hi = np.array(lo, float), np.array(hi, float)
        parts.append((name, hi - lo, (lo + hi) / 2, np.eye(3), color, visible, None, 0))

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
    fence_parts(runs, STYLES[style], parts)
    box("Spawn", (-2, 0, SPAWN_Z - 2), (2, 1, SPAWN_Z + 2), visible=False)
    box("Sign", (-1, 8, z0 - 1), (1, 10, z0 + 1), visible=False)
    box("Area", (x0 + 4, 0, z0 + 4), (x1 - 4, 1, z1 - 4), visible=False)
    box("Tiles", (x0, 0, z0), (x1, 0.2, z1), visible=False)  # the N x N floor tiles under the pen
    for i, (sx, sz) in enumerate(SLOTS, 1):
        box(f"Slot{i}", (sx - 2, 0, FRONT + sz - 2), (sx + 2, 1, FRONT + sz + 2), visible=False)

    out = []
    for name, size, centre, R, color, visible, material, transparency in parts:
        world = M @ centre + np.array([cx, LIFT, cz])
        out.append((name, size, world, M @ R, color, visible, material, transparency))  # (markers too: read in the pen's frame)
    return out


MATERIALS = {"Neon": 288}


def xml_part(ref, name, size, centre, R, color, visible, material=None, transparency=0):
    r, g, b = color
    rgb = (255 << 24) | (r << 16) | (g << 8) | b
    extra = "" if visible else (
        '<float name="Transparency">1</float>\n<bool name="CanCollide">false</bool>\n'
        '<bool name="CanQuery">false</bool>\n<bool name="CanTouch">false</bool>\n'
        '<bool name="CastShadow">false</bool>\n')
    if visible and material:
        extra += f'<token name="Material">{MATERIALS[material]}</token>\n'
    if visible and transparency:
        extra += f'<float name="Transparency">{transparency}</float>\n'
    if visible and transparency and transparency > 0:
        extra += '<bool name="CastShadow">false</bool>\n'

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


MARKERS = ("Spawn", "Sign", "Area", "Tiles")


def write():
    n = [0]

    def ref():
        n[0] += 1
        return f"RBX{n[0]:08X}"

    def folder(name):
        return f'<Item class="Folder" referent="{ref()}"><Properties>\n<string name="Name">{name}</string>\n</Properties>\n'

    def model(name):
        return f'<Item class="Model" referent="{ref()}"><Properties>\n<string name="Name">{name}</string>\n</Properties>\n'

    def markers(parts):
        out = [xml_part(ref, *p) for p in parts if p[0] in MARKERS]
        out.append(folder("Slots"))
        out += [xml_part(ref, *p) for p in parts if p[0].startswith("Slot")]
        out.append("</Item>\n")
        return out

    out = ['<roblox version="4">\n', folder("Pens")]
    for i, pen in enumerate(PENS, 1):
        out.append(model(f"Pen{i}"))
        out += markers(pen_parts(*pen))  # the live markers, at size 1
        out.append(folder("Sizes"))
        for k, size in enumerate(SIZES, 1):
            parts = pen_parts(*pen, size, k - 1)
            out.append(model(f"Size{k}"))
            # (no fence: PenLevel.server builds it in game, the owner's furthest biome's: PenFence)
            out += markers(parts)
            out.append("</Item>\n")
        out.append("</Item>\n</Item>\n")
    out.append("</Item>\n</roblox>\n")
    OUT.write_text("".join(out))


def visible_parts(pen, n=SIZES[0], style=0):
    out = []
    for name, size, centre, R, color, visible, _, _ in pen_parts(*pen, n, style):
        if visible:
            cf = np.eye(4)
            cf[:3, :3] = R
            cf[:3, 3] = centre
            out.append(partlib.Part(name, size, cf, color))
    return out


def preview(path, n=SIZES[0], style=0):
    parts = []
    for pen in PENS:
        parts += visible_parts(pen, n, style)
    W, D = HALF_W, DEPTH
    wall = (240, 160, 108)
    for lo, hi in [((-W - 8, 0, -8), (-W, 20, D)), ((W, 0, -8), (W + 8, 20, D)), ((-W - 8, 0, D), (W + 8, 20, D + 8)),
                   ((-W, 0, -8), (-56, 20, 0)), ((56, 0, -8), (W, 20, 0))]:
        lo, hi = np.array(lo, float), np.array(hi, float)
        parts.append(partlib.Part("Wall", hi - lo, partlib.T(*((lo + hi) / 2)), wall, plain=True))
    parts.append(partlib.Part("StartLine", (112, 0.2, 4), partlib.T(0, 0.1, -2), (30, 30, 30), plain=True))
    parts.append(partlib.Part("EggMachine", (12, 14, 12), partlib.T(-28, 7, 30), (255, 120, 190), plain=True))
    img = partlib.render(parts, eye=(0, 170, -80), target=(0, 0, 66), W=1400, H=900, fov=62)
    img.save(path)


if __name__ == "__main__":
    write()
    if len(sys.argv) > 1:
        for k, n in enumerate(SIZES, 1):
            preview(sys.argv[1].replace(".png", f"{k}.png"), n, k - 1)
