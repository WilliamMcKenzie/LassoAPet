"""Top Earners board frame (QM, Nov 6): the old stone portal gate (tools/portal_gate.py,
removed with World 2) made square to fit the list: a two-step base, two pillars of
stacked rough blocks (plinth, shaft, stepped capital) and a flat lintel and cornice
instead of the arch, a blocky skull on top (QM's reference). The opening is left empty:
Server/TopEarners puts the screen (a Part with the list's SurfaceGui) in it.

Studs, y up, base at y = 0, the board faces -z (Roblox front), the opening centred on
x = 0: SCREEN_W wide, from SCREEN_Y0 up SCREEN_H (Config.TopEarners.Screen).

Run: python3 tools/earners_board_meshes.py
Writes design/earners_board/pieces/EarnersBoard_<i>.obj (one per colour, colours and each
piece's bounding-box centre in pieces/colours.txt) and design/earners_board/board.png.
Upload: python3 tools/earners_board_upload.py (with the place open in Studio).
"""

import os

import numpy as np
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "design", "earners_board")
RNG = np.random.default_rng(12)
STUD = 0.5

SCREEN_W = 26.0   # the opening between the pillars
SCREEN_H = 32.0
SCREEN_Y0 = 4.2   # the opening's bottom (on the sill)
PILLAR = 5.5      # pillar shaft width
DEPTH = 6.0       # pillar depth (front to back)

COLOURS = {  # the meadow gate stone (MapData MeadowPillar / MeadowPillarDark), bone, sockets
    "Stone": (177, 185, 178),
    "StoneDark": (148, 156, 150),
    "Bone": (232, 226, 206),
    "Socket": (38, 38, 44),
}


def box(x0, y0, z0, x1, y1, z1, jitter=0.12):
    """A rough block: the 8 corners of the box, each nudged a little."""
    c = np.array([(x0, y0, z0), (x1, y0, z0), (x1, y1, z0), (x0, y1, z0),
                  (x0, y0, z1), (x1, y0, z1), (x1, y1, z1), (x0, y1, z1)], float)
    return c + RNG.uniform(-jitter, jitter, (8, 3))


# a box's six faces (corner indices, outward winding for Roblox: counter-clockwise from outside)
FACES = [(0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4), (3, 7, 6, 2), (0, 4, 7, 3), (1, 2, 6, 5)]


def tris_of(c):
    out = []
    centre = c.mean(0)
    for a, b, cc, d in FACES:
        for t in ((c[a], c[b], c[cc]), (c[a], c[cc], c[d])):
            t = np.array(t)
            n = np.cross(t[1] - t[0], t[2] - t[0])
            if np.dot(n, t.mean(0) - centre) < 0:
                t = t[::-1]
            out.append(t)
    return out


def row(group, x0, x1, y0, y1, z0, z1, n, jitter=0.12):
    """A course of n slabs side by side with uneven joints."""
    cuts = np.linspace(x0, x1, n + 1)
    cuts[1:-1] += RNG.uniform(-0.15, 0.15, n - 1) * (x1 - x0) / n
    for i in range(n):
        group[i % 2].append(box(cuts[i] + 0.06, y0, z0 + RNG.uniform(-0.15, 0.15), cuts[i + 1] - 0.06,
                                y1 + RNG.uniform(-0.1, 0.1), z1 + RNG.uniform(-0.15, 0.15), jitter))


def board():
    stone = [[], []]  # light, dark
    bone, socket = [], []
    hw = SCREEN_W / 2
    hx = hw + PILLAR  # each shaft's outer face
    d2 = DEPTH / 2
    # the two-step base, and a sill under the opening
    row(stone, -hx - 4.2, hx + 4.2, -0.6, 1.4, -d2 - 3.0, d2 + 1.5, 5)
    row(stone[::-1], -hx - 2.2, hx + 2.2, 1.3, 2.8, -d2 - 1.4, d2 + 0.8, 4)
    stone[1].append(box(-hw - 0.2, 2.7, -d2 + 0.4, hw + 0.2, SCREEN_Y0, d2 - 0.4, 0.05))
    top = SCREEN_Y0 + SCREEN_H  # the opening's top
    for s in (-1, 1):
        lo, hi = sorted((s * hw, s * hx))
        # plinth, a chunky block wider than the shaft
        stone[1].append(box(lo - 0.8, 2.7, -d2 - 0.8, hi + 0.8, 6.2, d2 + 0.8))
        # the shaft: courses of rough blocks, light and dark by turns
        y = 6.2
        courses = 6
        h = (top - 0.6 - y) / courses
        for k in range(courses):
            inset = RNG.uniform(0, 0.35)
            stone[k % 2].append(box(lo + inset, y + 0.05, -d2 + inset, hi - inset, y + h - 0.05, d2 - inset, 0.18))
            y += h
        # stepped capital
        stone[0].append(box(lo - 0.4, y, -d2 - 0.4, hi + 0.4, y + 1.2, d2 + 0.4))
    # a dark header strip over the opening, then the lintel across both capitals and a cornice
    stone[1].append(box(-hw - 0.2, top, -d2 + 0.4, hw + 0.2, top + 1.0, d2 - 0.4, 0.05))
    y = top + 0.6
    row(stone, -hx - 1.2, hx + 1.2, y, y + 4.0, -d2 - 0.6, d2 + 0.6, 3)
    y += 4.0
    row(stone[::-1], -hx - 2.4, hx + 2.4, y - 0.1, y + 1.4, -d2 - 1.2, d2 + 1.2, 4)
    y += 1.4
    # the skull: a jaw, the cranium on it, two eye sockets and a nose on its front
    bone.append(box(-4.4, y - 0.1, -4.6, 4.4, y + 2.2, 2.4, 0.05))
    bone.append(box(-5.6, y + 2.0, -4.0, 5.6, y + 9.2, 4.2, 0.05))
    for s in (-1, 1):
        x0, x1 = sorted((s * 1.0, s * 4.0))
        socket.append(box(x0, y + 4.8, -4.25, x1, y + 7.6, -3.6, 0.0))
    socket.append(box(-0.7, y + 2.9, -4.25, 0.7, y + 4.3, -3.6, 0.0))
    for i in range(-3, 4):  # teeth: dark gaps across the jaw's front
        socket.append(box(i * 1.15 - 0.12, y + 0.6, -4.75, i * 1.15 + 0.12, y + 2.0, -4.3, 0.0))
    return [("Stone", stone[0]), ("StoneDark", stone[1]), ("Bone", bone), ("Socket", socket)]


def stud_axes(n):
    ref = np.array([0.0, 1.0, 0.0]) if abs(n[1]) < 0.9 else np.array([1.0, 0.0, 0.0])
    e1 = np.cross(ref, n)
    e1 /= np.linalg.norm(e1)
    return e1, np.cross(n, e1)


def write_obj(name, tris, path):
    """Flat shaded (a normal per face), UVs planar per face in studs (Studs.apply)."""
    lines = [f"# {name}: Top Earners board piece, studs, y up, base at y=0", f"o {name}"]
    vt, vn, faces, nv = [], [], [], 0
    for t in tris:
        n = np.cross(t[1] - t[0], t[2] - t[0])
        n /= np.linalg.norm(n)
        e1, e2 = stud_axes(n)
        for v in t:
            lines.append("v %.4f %.4f %.4f" % tuple(v))
            vt.append("vt %.4f %.4f" % (v @ e1 / STUD, v @ e2 / STUD))
        vn.append("vn %.4f %.4f %.4f" % tuple(n))
        faces.append((nv + 1, nv + 2, nv + 3, len(vn)))
        nv += 3
    lines += vt + vn
    lines += ["f %d/%d/%d %d/%d/%d %d/%d/%d" % (a, a, k, b, b, k, c, c, k) for a, b, c, k in faces]
    with open(path, "w") as f:
        f.write("\n".join(lines) + "\n")


def preview(pieces, path):
    """Front view, flat shaded by normal (painter's order), the opening outlined."""
    S, W, H = 14, 800, 800
    img = Image.new("RGB", (W, H), (150, 200, 240))
    d = ImageDraw.Draw(img)
    light = np.array([-0.4, 0.7, -0.6])  # toward the light: front left, above
    light /= np.linalg.norm(light)
    view = np.array([0.35, 0.0, 0.94])  # a little from the left
    view /= np.linalg.norm(view)
    right = np.cross(view, (0, 1, 0))
    right /= np.linalg.norm(right)
    allt = []
    for label, blocks in pieces:
        col = np.array(COLOURS[label], float)
        for b in blocks:
            for t in tris_of(b):
                n = np.cross(t[1] - t[0], t[2] - t[0])
                n /= np.linalg.norm(n)
                if np.dot(n, view) > 0:  # facing away (the camera looks along +view)
                    continue
                shade = 0.55 + 0.45 * max(0.0, float(np.dot(n, light)))
                allt.append((float(np.mean(t @ view)), t, tuple(int(min(255, c * shade)) for c in col)))
    allt.sort(key=lambda a: -a[0])
    for _, t, c in allt:
        pts = [(W / 2 + float(v @ right) * S, H - 40 - float(v[1]) * S) for v in t]
        d.polygon(pts, fill=c)
    hw = SCREEN_W / 2
    corners = [np.array((x, y, -DEPTH / 2 + 0.5)) for x, y in ((-hw, SCREEN_Y0), (hw, SCREEN_Y0), (hw, SCREEN_Y0 + SCREEN_H), (-hw, SCREEN_Y0 + SCREEN_H))]
    d.polygon([(W / 2 + float(v @ right) * S, H - 40 - float(v[1]) * S) for v in corners], fill=(12, 16, 14))
    img.save(path)


def main():
    os.makedirs(os.path.join(OUT, "pieces"), exist_ok=True)
    pieces = board()
    with open(os.path.join(OUT, "pieces", "colours.txt"), "w") as f:
        f.write("# piece: label, R, G, B, centre x, y, z (its bounding box's, where its MeshPart goes)\n")
        for i, (label, blocks) in enumerate(pieces):
            tris = [t for b in blocks for t in tris_of(b)]
            name = f"EarnersBoard_{i + 1}"
            write_obj(name, tris, os.path.join(OUT, "pieces", name + ".obj"))
            pts = np.concatenate(tris)
            lo, hi = pts.min(0), pts.max(0)
            c = (lo + hi) / 2
            f.write("%s: %s, %d, %d, %d, %.3f, %.3f, %.3f\n" % ((name, label) + COLOURS[label] + tuple(c)))
            print(f"{name} ({label}): {len(tris)} tris, {hi[0] - lo[0]:.1f} x {hi[1] - lo[1]:.1f} x {hi[2] - lo[2]:.1f}")
    preview(pieces, os.path.join(OUT, "board.png"))


if __name__ == "__main__":
    main()
