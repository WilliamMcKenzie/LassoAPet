"""Convert a rigged Blockbench model into a Luau data module for Rig.luau.

Run: python3 tools/bbmodel_to_luau.py designs/horses/Horse9_Leap.bbmodel src/shared/Animals/HorseModel.luau

1 Blockbench unit = 0.1 stud. Blockbench and Roblox share axes (Y up, front
= -Z) and both rotate right-handed, so rotation keyframes carry over as-is.
Cubes become Parts; six-vertex wedge meshes become WedgeParts. Other meshes
are approximated with blocks and wedges:
  one-face quads (eye plates)   thin plain Parts, stacked in the order they sit
  pyramids (a quad and a tip)   four CornerWedgeParts (see spike())
  ringed spikes (4n + 1 verts)  a block per ring-to-ring segment, then a pyramid tip
Each face picks its colour from its own texture. Group rotations become the
bone's rest rotation. Parts named in NEON glow (Enum.Material.Neon), and parts named in
METAL get the classic Weld texture instead of studs. A group whose name repeats an earlier one (QM's
wyvern has a "Head" inside its "Head") becomes its own bone, <name>_2, so bones and their
animation tracks stay one to one.

Euler order: our own tools write rotations meaning R = Rx * Ry * Rz (Roblox's
CFrame.Angles), the default here. Blockbench itself means R = Rz * Ry * Rx, which only
differs when a rotation turns about two or more axes. For a model built by hand in
Blockbench (QM's King Crab), pass --zyx so those parts come out as Blockbench shows them:
  python3 tools/bbmodel_to_luau.py --zyx designs/ocean/KingCrab.bbmodel src/shared/Animals/KingCrabModel.luau
"""

import base64
import io
import json
import math
import sys

import numpy as np
from PIL import Image

SCALE = 0.1
PLAIN = ("Eye", "Pupil", "Nostril", "Plain")  # name prefixes that skip the stud texture
NEON = ("Slit_pupil", "Glow")  # name prefixes that glow
METAL = ("Metal",)  # name prefixes drawn with the classic Weld texture instead of studs
PLATE = 0.04  # studs: thickness of a converted one-face plane


def v3(v):
    return "Vector3.new({:g}, {:g}, {:g})".format(*(round(float(x), 4) + 0.0 for x in v))


def cf(pos, R):
    vals = [*pos, *R.flatten()]
    return "CFrame.new({})".format(", ".join("{:g}".format(round(float(x), 6) + 0.0) for x in vals))


ORDER = "XYZ"  # see the module docstring; main() sets "ZYX" for --zyx


def euler(deg):
    x, y, z = (math.radians(a) for a in deg)
    cx, sx, cy, sy, cz, sz = math.cos(x), math.sin(x), math.cos(y), math.sin(y), math.cos(z), math.sin(z)
    Rx = np.array([[1, 0, 0], [0, cx, -sx], [0, sx, cx]])
    Ry = np.array([[cy, 0, sy], [0, 1, 0], [-sy, 0, cy]])
    Rz = np.array([[cz, -sz, 0], [sz, cz, 0], [0, 0, 1]])
    return Rz @ Ry @ Rx if ORDER == "ZYX" else Rx @ Ry @ Rz


def element_rotation(e):
    return euler(e.get("rotation") or (0, 0, 0))


def num(v):
    """Keyframe value: Blockbench stores numbers, or strings like "-\\n19.6"."""
    v = "".join(str(v).split())
    return float(v) if v else 0.0


def wedge_frame(e):
    """Center, rotation and size of a WedgePart matching a 6-vertex wedge mesh.
    Mesh vertices are relative to the element's origin (and rotation)."""
    R0, o = element_rotation(e), np.array(e.get("origin") or (0, 0, 0), float)
    verts = {k: (R0 @ np.array(v, float) + o) * SCALE for k, v in e["vertices"].items()}
    tris = [f["vertices"] for f in e["faces"].values() if len(f["vertices"]) == 3]
    assert len(tris) == 2 and len(verts) == 6, e["name"] + " is not a wedge"
    t0 = [verts[k] for k in tris[0]]
    t1 = [verts[k] for k in tris[1]]
    # right-angle corner of the first triangle
    for i in range(3):
        a, b, c = t0[i], t0[(i + 1) % 3], t0[(i + 2) % 3]
        if abs(np.dot(b - a, c - a)) < 1e-6:
            break
    else:
        raise ValueError(e["name"] + ": no right angle")
    u, w = b - a, c - a
    # Roblox wedge: corner at bottom-back, legs run up (+Y) and forward (-Z)
    Y = u / np.linalg.norm(u)
    Z = -w / np.linalg.norm(w)
    X = np.cross(Y, Z)
    other = np.mean(t1, axis=0) - np.mean(t0, axis=0)
    width = abs(np.dot(other, X))
    center = a + u / 2 + w / 2 + X * np.dot(other, X) / 2
    R = np.stack([X, Y, Z], axis=1)  # columns = right, up, back
    return center, R, (width, np.linalg.norm(u), np.linalg.norm(w))


def mesh_verts(e):
    """Mesh vertices in model space (studs), in file order."""
    R0, o = element_rotation(e), np.array(e.get("origin") or (0, 0, 0), float)
    return {k: (R0 @ np.array(v, float) + o) * SCALE for k, v in e["vertices"].items()}


def frame(X, Y):
    """Rotation with columns right, up, back from a right (X) and up (Y) guess."""
    Y = Y / np.linalg.norm(Y)
    X = X - Y * np.dot(X, Y)
    X = X / np.linalg.norm(X)
    return np.stack([X, Y, np.cross(X, Y)], axis=1)


def extents(pts, R):
    """Size of pts along R's columns, and the center of that box."""
    local = (np.array(pts) @ R)
    lo, hi = local.min(0), local.max(0)
    return hi - lo, R @ ((lo + hi) / 2)


def plate(e, model_center):
    """A one-face quad as a thin block: its back face on the quad's plane,
    standing out on the side away from the model (so stacked plates keep order)."""
    V = np.array(list(mesh_verts(e).values()))
    c = V.mean(0)
    _, _, vt = np.linalg.svd(V - c)
    long, _, n = vt
    if np.dot(n, c - model_center) < 0:
        n = -n
    R = frame(long, np.cross(n, long))  # right = long axis, up = across, back = normal
    size, center = extents(V, R)
    # a diamond or slanted quad: keep its area, not its bounding box
    area = 0.5 * np.linalg.norm(np.cross(V[2] - V[0], V[3] - V[1]))
    size = np.array([size[0], min(size[1], area / max(size[0], 1e-6)), PLATE])
    return [("Part", center + n * PLATE / 2, R, size)]


def spike(base, apex):
    """A pyramid from four CornerWedgeParts, one per quarter of its base, each
    with its peak over the point under the apex. A CornerWedgePart's peak is at
    (+X/2, +Y/2, -Z/2). When the apex leans out past its base, the spike is
    stood straight up on a base square to the apex's axis instead (sunk a
    little so the tilt never opens a gap)."""
    b = np.mean(base, axis=0)
    _, _, vt = np.linalg.svd(np.array(base) - b)
    up = vt[2] if np.dot(vt[2], apex - b) > 0 else -vt[2]
    R = frame(base[1] - base[0], up)
    size, center = extents(base, R)
    local = R.T @ (apex - center)
    half = size / 2
    if abs(local[0]) > half[0] * 0.95 or abs(local[2]) > half[2] * 0.95:
        d = apex - b
        up = d / np.linalg.norm(d)
        R = frame(base[1] - base[0], up)
        size, _ = extents(base, R)
        sink = min(0.1, 0.2 * np.linalg.norm(d))
        center = b - up * sink
        local = np.array([0.0, np.linalg.norm(d) + sink, 0.0])
        half = size / 2
    bx, bz = R[:, 0], R[:, 2]
    px, pz, h = local[0], local[2], local[1]
    out = []
    for sx, (x0, x1) in ((1, (-half[0], px)), (-1, (px, half[0]))):
        for sz, (z0, z1) in ((1, (-half[2], pz)), (-1, (pz, half[2]))):
            wx, wz = x1 - x0, z1 - z0
            if wx < 1e-4 or wz < 1e-4:
                continue
            c = center + bx * (x0 + x1) / 2 + bz * (z0 + z1) / 2 + up * h / 2
            # peak on the side toward the apex: +x for the quarter left of it (sx = 1)
            if sx == -sz:
                Rw, sz3 = np.stack([sx * bx, up, -sz * bz], axis=1), (wx, h, wz)
            else:
                Rw, sz3 = np.stack([sz * bz, up, -sx * bx], axis=1), (wz, h, wx)
            out.append(("CornerWedgePart", c, Rw, np.array(sz3)))
    return out


def pyramid(e):
    V = mesh_verts(e)
    quad = next(f["vertices"] for f in e["faces"].values() if len(f["vertices"]) == 4)
    apex = next(v for k, v in V.items() if k not in quad)
    return spike(order_quad([V[k] for k in quad]), apex)


def order_quad(pts):
    """Quad corners in order round the edge (Blockbench faces can list them crossed)."""
    c = np.mean(pts, axis=0)
    _, _, vt = np.linalg.svd(np.array(pts) - c)
    a = [np.arctan2(np.dot(p - c, vt[1]), np.dot(p - c, vt[0])) for p in pts]
    return [pts[i] for i in np.argsort(a)]


def ringed(e):
    """Rings of four vertices (in file order) and a tip: a block per segment
    between rings, a pyramid from the last ring to the tip."""
    V = list(mesh_verts(e).values())
    rings = [order_quad(V[i:i + 4]) for i in range(0, len(V) - 1, 4)]
    out = []
    for r0, r1 in zip(rings, rings[1:]):
        c0, c1 = np.mean(r0, axis=0), np.mean(r1, axis=0)
        R = frame(r0[1] - r0[0], c1 - c0)
        s0, _ = extents(r0, R)
        s1, _ = extents(r1, R)
        L = np.linalg.norm(c1 - c0)
        grow = 0.35 * (s0[0] + s0[2]) / 2  # overlap at the bends
        size = np.array([(s0[0] + s1[0]) / 2, L + grow, (s0[2] + s1[2]) / 2])
        out.append(("Part", (c0 + c1) / 2, R, size))
    out += spike(rings[-1], V[-1])
    return out


def mesh_parts(e, model_center):
    faces = [len(f["vertices"]) for f in e["faces"].values()]
    n = len(e["vertices"])
    if n == 4 and faces == [4]:
        return plate(e, model_center)
    if n == 6 and sorted(faces) == [3, 3, 4, 4, 4]:
        center, R, size = wedge_frame(e)
        return [("WedgePart", center, R, size)]
    if n == 5 and sorted(faces) == [3, 3, 3, 3, 4]:
        return pyramid(e)
    if n % 4 == 1 and faces.count(3) == 4:
        return ringed(e)
    raise ValueError(f"{e['name']}: mesh with {n} vertices and faces {faces} isn't supported")


def bone_names(model):
    """Group uuid -> bone name, in outliner order; a repeated name gets _2, _3, ..."""
    groups = {g["uuid"]: g for g in model["groups"]}
    names, seen = {}, {}

    def walk(node):
        if isinstance(node, str):
            return
        name = groups[node["uuid"]]["name"]
        seen[name] = seen.get(name, 0) + 1
        names[node["uuid"]] = name if seen[name] == 1 else f"{name}_{seen[name]}"
        for c in node["children"]:
            walk(c)

    for node in model["outliner"]:
        walk(node)
    return names


def convert(model):
    """(bones, parts) of a loaded .bbmodel: bones are (name, parent, pivot, rest
    rotation in degrees), parts (name, bone, class, size, center, rotation, rgb,
    plain, neon, metal) in model space at rest (before bone rest rotations)."""
    names = bone_names(model)
    res = model.get("resolution") or {"width": 16, "height": 16}
    texs = []
    for t in model["textures"]:
        im = Image.open(io.BytesIO(base64.b64decode(t["source"].split(",", 1)[1]))).convert("RGB")
        texs.append((im, im.width / (t.get("uv_width") or res["width"]), im.height / (t.get("uv_height") or res["height"])))
    groups = {g["uuid"]: g for g in model["groups"]}
    elements = {e["uuid"]: e for e in model["elements"]}
    cubes = [e for e in model["elements"] if e["type"] == "cube"]
    model_center = np.mean([(np.array(e["from"]) + e["to"]) / 2 for e in cubes], axis=0) * SCALE if cubes else np.zeros(3)

    def color(e):
        """The element's colour: its front face (or first textured face) at that face's UV."""
        faces = e["faces"]
        face = faces.get("north") if faces.get("north", {}).get("texture") is not None else None
        face = face or next((f for f in faces.values() if f.get("texture") is not None), None)
        if face is None:
            return 255, 255, 255  # untextured: Blockbench shows it white
        im, sx, sy = texs[face["texture"]]
        uv = face["uv"]
        u, v = uv[:2] if isinstance(uv, list) else next(iter(uv.values()))
        return im.getpixel((min(int(u * sx), im.width - 1), min(int(v * sy), im.height - 1)))

    bones, parts = [], []

    def walk(node, parent):
        if isinstance(node, str):
            e = elements[node]
            if e.get("visibility") is False:
                return
            if e["type"] == "cube":
                lo, hi = np.array(e["from"]) * SCALE, np.array(e["to"]) * SCALE
                R = element_rotation(e)
                o = np.array(e.get("origin") or (0, 0, 0), float) * SCALE
                pieces = [("Part", R @ ((lo + hi) / 2 - o) + o, R, hi - lo)]
            else:
                pieces = mesh_parts(e, model_center)
            rgb = color(e)
            neon = e["name"].startswith(NEON)
            metal = e["name"].startswith(METAL)
            # plates, and the sloped faces of spikes, skip the studs
            flat = e["type"] == "mesh" and len(e["vertices"]) in (4, 5)
            plain = e["name"].startswith(PLAIN) or "In" in e["name"] or neon or flat
            for i, (cls, center, R, size) in enumerate(pieces):
                name = e["name"] if i == 0 else f"{e['name']}_{i + 1}"
                parts.append((name, parent, cls, size, center, R, rgb, plain, neon, metal))
            return
        g = groups[node["uuid"]]
        name = names[g["uuid"]]
        bones.append((name, parent, np.array(g["origin"]) * SCALE, g.get("rotation") or [0, 0, 0]))
        for c in node["children"]:
            walk(c, name)

    for node in model["outliner"]:
        walk(node, None)
    return bones, parts


def main(src, dst):
    model = json.load(open(src))
    bones, parts = convert(model)
    names = bone_names(model)

    out = ["-- GENERATED by tools/bbmodel_to_luau.py from " + src + ". Don't edit by hand:",
           "-- change the .bbmodel in Blockbench and regenerate.",
           "-- Units are studs, rest pose, hooves on Y = 0, facing -Z.",
           "",
           "return {",
           "\tbones = {"]
    for name, parent, pivot, rot in bones:
        p = f'"{parent}"' if parent else "nil"
        rest = ""
        if any(rot) and ORDER == "ZYX" and sum(1 for a in rot if a) > 1:
            rest = ", rest = " + cf((0, 0, 0), euler(rot))
        elif any(rot):
            rest = ", rest = CFrame.Angles({:g}, {:g}, {:g})".format(*(round(math.radians(a), 6) + 0.0 for a in rot))
        out.append(f'\t\t{{ name = "{name}", parent = {p}, pivot = {v3(pivot)}{rest} }},')
    out.append("\t},")
    out.append("\tparts = {")
    for name, bone, cls, size, center, R, (r, g, b), plain, neon, metal in parts:
        extra = (", plain = true" if plain else "") + (", neon = true" if neon else "") + (", metal = true" if metal else "")
        out.append(f'\t\t{{ name = "{name}", bone = "{bone}", class = "{cls}", size = {v3(size)}, '
                   f"cframe = {cf(center, R)}, color = Color3.fromRGB({r}, {g}, {b}){extra} }},")
    out.append("\t},")
    out.append("\t-- keys: { time, x, y, z }; rotation in radians, position in studs, scale as a factor")
    out.append("\tanimations = {")
    for anim in model.get("animations", []):
        out.append(f'\t\t{anim["name"]} = {{')
        out.append(f'\t\t\tlength = {anim["length"]:g},')
        out.append("\t\t\ttracks = {")
        for uid, a in anim["animators"].items():
            if not a.get("keyframes"):
                continue
            chans = {}
            for k in sorted(a["keyframes"], key=lambda k: k["time"]):
                chans.setdefault(k["channel"], []).append(k)
            out.append(f'\t\t\t\t{names.get(uid, a["name"])} = {{')
            for ch, kfs in chans.items():
                f = {"rotation": lambda x: math.radians(float(x)),
                     "position": lambda x: float(x) * SCALE}.get(ch, float)  # scale stays a factor
                interp = kfs[0]["interpolation"]
                keys = ", ".join("{{ {:g}, {:g}, {:g}, {:g} }}".format(
                    k["time"], *(round(f(num(k["data_points"][0][c])), 5) + 0.0 for c in "xyz")) for k in kfs)
                out.append(f'\t\t\t\t\t{ch} = {{ smooth = {"true" if interp == "catmullrom" else "false"}, keys = {{ {keys} }} }},')
            out.append("\t\t\t\t},")
        out.append("\t\t\t},")
        out.append("\t\t},")
    out.append("\t},")
    out.append("}")
    open(dst, "w").write("\n".join(out) + "\n")
    print(len(bones), "bones,", len(parts), "parts,", len(model.get("animations", [])), "animations")


if __name__ == "__main__":
    args = sys.argv[1:]
    if "--zyx" in args:
        args.remove("--zyx")
        ORDER = "ZYX"
    main(*args)
