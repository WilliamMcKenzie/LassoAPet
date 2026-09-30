"""Build the five player pens as a saved model, plus a preview picture.

    python3 tools/pens.py [preview.png]

Writes src/world/Pens.rbxmx (synced by Rojo to Workspace.Pens). Once it is in
Studio, QM can edit it by hand and Save to File over that path; rerunning this
script would overwrite those edits.

Each PenN model holds a wooden post-and-rail fence and plank floor with a
gate facing the course (-Z), a name board on the arch over the gate (the server writes the owner's name on it) and
invisible markers the scripts read:
  Spawn  where the owner appears
  Mount  where the owner's horse waits, facing the course
  Slots  one invisible part per pet spot (all of the owner's pets live here)
"""

import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import partlib  # noqa: E402

OUT = Path(__file__).resolve().parent.parent / "src" / "world" / "Pens.rbxmx"

PENS = 5
SPACING = 28  # pen centres along X
WIDTH, DEPTH = 24, 32
FRONT_Z = 126  # the gate side; the back sits 2 studs off the base's back wall (z = 160)
GATE = 8
MOUNT_Z = 112
SPAWN_Z = 121
SLOTS = [(x, FRONT_Z + dz) for dz in (8, 16, 24) for x in (-6, 6)]

# Post-and-rail wooden pens like the horse pens and farm plots in Roblox horse
# and pet games: dark posts, lighter plank rails, a plank floor and a gate arch
# with a hanging name board.
POST_WOOD = (117, 72, 42)
RAIL_WOOD = (181, 121, 70)
FLOOR_WOOD = [(214, 152, 92), (198, 138, 82)]
SIGN_WOOD = (226, 176, 108)
POST, RAIL = 2, 0.6
FENCE_H = 5
FLOOR_H = 0.4
ARCH_H = 12


def pen_parts(cx):
    parts = []  # (name, size, centre, colour, visible)

    def box(name, lo, hi, color=RAIL_WOOD, visible=True):
        lo, hi = np.array(lo, float), np.array(hi, float)
        parts.append((name, hi - lo, (lo + hi) / 2, color, visible))

    x0, x1 = cx - WIDTH / 2, cx + WIDTH / 2
    z0, z1 = FRONT_Z, FRONT_Z + DEPTH
    g0, g1 = cx - GATE / 2, cx + GATE / 2
    p = POST / 2

    # Plank floor, boards running from the gate to the back, 4 studs wide.
    for i, x in enumerate(np.arange(x0, x1, 4)):
        box("Floor", (x, 0, z0), (x + 4, FLOOR_H, z1), FLOOR_WOOD[i % 2])

    # Posts: corners, every 6-8 studs along the sides and back, and either side of the gate.
    posts = set()
    for x in np.linspace(x0, x1, 4):
        posts.add((x, z1))
    for z in np.linspace(z0, z1, 5):
        posts.add((x0, z))
        posts.add((x1, z))
    for x, z in sorted(posts):
        box("Post", (x - p, 0, z - p), (x + p, FENCE_H, z + p), POST_WOOD)

    # Gate arch: two tall posts, a beam across the top and the name board under it.
    for x in (g0 - p, g1 + p):
        box("GatePost", (x - p, 0, z0 - p), (x + p, ARCH_H, z0 + p), POST_WOOD)
    box("Beam", (g0 - 4, ARCH_H, z0 - 1.5), (g1 + 4, ARCH_H + 1.5, z0 + 1.5), POST_WOOD)
    # Between the gate posts, not flush with their outer faces (that z-fought).
    box("Sign", (g0, ARCH_H - 3.5, z0 - 0.5), (g1, ARCH_H - 0.5, z0), SIGN_WOOD)

    # Two plank rails on every run of fence, on the outside of the posts.
    runs = [
        ((x0, z0), (x0, z1), (-1, 0)),
        ((x1, z0), (x1, z1), (1, 0)),
        ((x0, z1), (x1, z1), (0, 1)),
        ((x0, z0), (g0 - POST, z0), (0, -1)),
        ((g1 + POST, z0), (x1, z0), (0, -1)),
    ]
    for (ax, az), (bx, bz), (nx, nz) in runs:
        ox, oz = nx * (p + RAIL / 2), nz * (p + RAIL / 2)
        wx = RAIL / 2 if nx else 0
        wz = RAIL / 2 if nz else 0
        ex = p if nz else 0  # rails run past the end posts' faces
        ez = p if nx else 0
        for y in (1.5, 3.5):
            lo = (min(ax, bx) + ox - wx - ex, y - 0.6, min(az, bz) + oz - wz - ez)
            hi = (max(ax, bx) + ox + wx + ex, y + 0.6, max(az, bz) + oz + wz + ez)
            box("Rail", lo, hi)

    box("Spawn", (cx - 2, 0, SPAWN_Z - 2), (cx + 2, 1, SPAWN_Z + 2), visible=False)
    box("Mount", (cx - 2, 0, MOUNT_Z - 2), (cx + 2, 1, MOUNT_Z + 2), visible=False)
    for i, (sx, sz) in enumerate(SLOTS, 1):
        box(f"Slot{i}", (cx + sx - 2, FLOOR_H, sz - 2), (cx + sx + 2, FLOOR_H + 1, sz + 2), visible=False)
    return parts


def pen_centres():
    return [(i - (PENS - 1) / 2) * SPACING for i in range(PENS)]


def xml_part(ref, name, size, centre, color, visible):
    r, g, b = color
    rgb = (255 << 24) | (r << 16) | (g << 8) | b
    extra = "" if visible else (
        '<float name="Transparency">1</float>\n<bool name="CanCollide">false</bool>\n'
        '<bool name="CanQuery">false</bool>\n<bool name="CanTouch">false</bool>\n'
        '<bool name="CastShadow">false</bool>\n')
    top = 3 if visible else 0
    return (
        f'<Item class="Part" referent="{ref()}"><Properties>\n'
        f'<string name="Name">{name}</string>\n'
        '<bool name="Anchored">true</bool>\n'
        f'<Vector3 name="size"><X>{size[0]:g}</X><Y>{size[1]:g}</Y><Z>{size[2]:g}</Z></Vector3>\n'
        f'<Color3uint8 name="Color3uint8">{rgb}</Color3uint8>\n'
        f'<token name="TopSurface">{top}</token>\n'
        '<token name="BottomSurface">0</token>\n'
        f'{extra}'
        f'<CoordinateFrame name="CFrame"><X>{centre[0]:g}</X><Y>{centre[1]:g}</Y><Z>{centre[2]:g}</Z>'
        '<R00>1</R00><R01>0</R01><R02>0</R02><R10>0</R10><R11>1</R11><R12>0</R12><R20>0</R20><R21>0</R21><R22>1</R22>'
        '</CoordinateFrame>\n'
        '</Properties></Item>\n'
    )


def write():
    n = [0]

    def ref():
        n[0] += 1
        return f"RBX{n[0]:08X}"

    out = ['<roblox version="4">\n', f'<Item class="Folder" referent="{ref()}"><Properties>\n<string name="Name">Pens</string>\n</Properties>\n']
    for i, cx in enumerate(pen_centres(), 1):
        out.append(f'<Item class="Model" referent="{ref()}"><Properties>\n<string name="Name">Pen{i}</string>\n</Properties>\n')
        slots = []
        for part in pen_parts(cx):
            if part[0].startswith("Slot"):
                slots.append(part)
            else:
                out.append(xml_part(ref, *part))
        out.append(f'<Item class="Folder" referent="{ref()}"><Properties>\n<string name="Name">Slots</string>\n</Properties>\n')
        out += [xml_part(ref, *s) for s in slots]
        out.append("</Item>\n</Item>\n")
    out.append("</Item>\n</roblox>\n")
    OUT.write_text("".join(out))


def preview(path):
    parts = []
    for cx in pen_centres():
        for name, size, centre, color, visible in pen_parts(cx):
            if visible:
                parts.append(partlib.Part(name, size, partlib.T(*centre), color))
        # stand-in for the owner's horse at the Mount spot
        parts.append(partlib.Part("Horse", (3, 5, 8), partlib.T(cx, 2.5, MOUNT_Z), (160, 100, 60), plain=True))
    wall = (240, 160, 108)
    for lo, hi in [((-84, 0, -4), (-80, 20, 164)), ((80, 0, -4), (84, 20, 164)), ((-84, 0, 160), (84, 20, 164))]:
        lo, hi = np.array(lo, float), np.array(hi, float)
        parts.append(partlib.Part("Wall", hi - lo, partlib.T(*((lo + hi) / 2)), wall, plain=True))
    img = partlib.render(parts, eye=(0, 60, 30), target=(0, 0, 120), W=1100, H=800, fov=50)
    img.save(path)


if __name__ == "__main__":
    write()
    if len(sys.argv) > 1:
        preview(sys.argv[1])
