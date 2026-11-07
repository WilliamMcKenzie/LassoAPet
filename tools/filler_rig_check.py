"""Preview QM's picked luck-padding animals as rigged: per kind, rest pose plus three gallop
frames from the converted .bbmodel (designs/filler/rigged), and a lineup at their in-game
sizes (size tier: Config.PetSmallSize x TierGrowth^(tier - 1) over each model's silhouette),
the Horse and the Abyss Whale for scale.

Run: python3 tools/filler_rig_check.py [Kind ...]
Writes /mnt/project-files/animals/filler/picked_rigs.png and picked_sizes.png.
"""

import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
import animal_designs as A  # noqa: E402
import filler_core as C  # noqa: E402
import filler_export as X  # noqa: E402
from horse_rig import pose  # noqa: E402
from partlib import Part, look_at, render  # noqa: E402
from bbmodel_to_luau import PLAIN  # noqa: E402

OUT = "/mnt/project-files/animals/filler"
ROOT = os.path.join(os.path.dirname(__file__), "..")


def load(kind):
    return json.load(open(os.path.join(X.RIGGED, kind + ".bbmodel")))


def frame(model, anim, u):
    a = next((x for x in model["animations"] if x["name"] == anim), None) if anim else None
    parts = pose(model, a, u * a["length"] if a else 0)
    for p in parts:
        if p.name.startswith(PLAIN):
            p.plain = True
    return parts


def rigs(kinds):
    T = 220
    rows = []
    fnt = A.font(15)
    for kind in kinds:
        m = load(kind)
        row = Image.new("RGB", (T * 4 + 170, T), (255, 255, 255))
        ImageDraw.Draw(row).text((8, T / 2 - 8), kind, fill=(20, 20, 20), font=fnt)
        for i, (anim, u) in enumerate((("", 0), ("gallop", 0.15), ("gallop", 0.4), ("gallop", 0.75))):
            row.paste(C.tile(frame(m, anim or None, u), T, T), (170 + i * T, 0))
        rows.append(row)
    sheet = Image.new("RGB", (rows[0].width, T * len(rows)), (255, 255, 255))
    for i, r in enumerate(rows):
        sheet.paste(r, (0, i * T))
    path = os.path.join(OUT, "picked_rigs.png")
    sheet.save(path)
    print("wrote", path)


def luau_parts(path):
    """Box parts (rest pose) from a generated <Kind>Model.luau, for animals with no .bbmodel."""
    import re
    parts = []
    for m in re.finditer(r'name = "(\w+)".*?size = Vector3.new\(([^)]*)\), cframe = CFrame.new\(([^)]*)\), color = Color3.fromRGB\(([^)]*)\)', open(path).read()):
        name, size, cf, col = m.groups()
        v = [float(x) for x in cf.split(",")]
        M = np.eye(4)
        M[:3, 3] = v[:3]
        if len(v) == 12:
            M[:3, :3] = np.array(v[3:]).reshape(3, 3)
        parts.append(Part(name, np.array([float(x) for x in size.split(",")]), M, tuple(int(x) for x in col.split(","))))
    return parts


def sized(kind, model):
    parts = luau_parts(model) if isinstance(model, str) else frame(model, None, 0)
    tier = X.PICKS[kind][4] if kind in X.PICKS else {"Horse": 1, "AbyssWhale": 4}[kind]
    k = 1.52 if kind == "AbyssWhale" else 10.4 * 1.6 ** (tier - 1) / X.silhouette(parts)  # (the whale's module sets size = 1.52)
    for p in parts:
        if p.shape == "Poly":
            p.polys = [q * k for q in p.polys]
        else:
            p.size = p.size * k
            p.cf[:3, 3] *= k
    return parts


def sizes(kinds):
    import importlib
    items = []
    horse = A.qm_horse("A")
    hp = pose(horse, None, 0)
    k = 10.4 / X.silhouette(hp)
    for p in hp:
        p.size = p.size * k
        p.cf[:3, 3] *= k
    items.append(("Horse", hp))
    items.append(("Abyss Whale", sized("AbyssWhale", os.path.join(ROOT, "src", "shared", "Animals", "AbyssWhaleModel.luau"))))
    for kind in sorted(kinds, key=lambda k: (X.PICKS[k][4], k)):
        items.append((kind, sized(kind, load(kind))))
    C.set_ground((96, 196, 70), (88, 184, 64))
    scene, labels = [], []
    z = 0
    for name, parts in items:
        lo, hi = C.bounds(parts)
        dz, dx = z - lo[2], -(lo[0] + hi[0]) / 2
        for p in parts:
            q = Part(p.name, p.size, p.cf.copy(), p.color, p.shape, p.plain)
            if p.shape == "Poly":
                q.polys = [w + np.array([dx, 0, dz]) for w in p.polys]
            else:
                q.cf[0, 3] += dx
                q.cf[2, 3] += dz
            scene.append(q)
        labels.append((name, z + (hi[2] - lo[2]) / 2, hi[1]))
        z += hi[2] - lo[2] + 4
    total = z - 4
    tallest = max(h for _, _, h in labels)
    SW = 3000
    SH = int(np.clip(SW * (tallest + 10) / (total + 8), 300, 1000))
    fov = 10
    c = np.array([0, tallest / 2, total / 2])
    view = np.array([-1.0, 0.1, 0])
    view /= np.linalg.norm(view)
    focal = (SH / 2) / np.tan(np.radians(fov) / 2)
    dist = focal * (total / 2 + 4) / (SW / 2 - 10)
    im = render(scene, eye=c + view * dist, target=c, W=SW, H=SH, fov=fov)
    d = ImageDraw.Draw(im)
    e, r, u, f = look_at(c + view * dist, c)
    for i, (name, cz, top) in enumerate(labels):
        p = np.array([0, top + 1, cz]) - e
        sx = SW / 2 + focal * (p @ r) / (p @ f)
        sy = SH / 2 - focal * (p @ u) / (p @ f)
        tw = d.textlength(name, font=A.font(16))
        d.text((sx - tw / 2, max(2, sy - 20 - (i % 2) * 18)), name, fill=(20, 20, 20), font=A.font(16))
    path = os.path.join(OUT, "picked_sizes.png")
    im.save(path)
    print("wrote", path, im.size)


if __name__ == "__main__":
    kinds = sys.argv[1:] or list(X.PICKS)
    rigs(kinds)
    sizes(kinds)
