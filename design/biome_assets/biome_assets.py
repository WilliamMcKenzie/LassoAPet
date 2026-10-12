"""QM (Oct 10): every obstacle/decor asset in the biomes now, one labelled row per biome,
so QM can pick the few to keep (the rest go for the new rock meshes).
Meadow..Ocean come from src/world/World.rbxmx (first instance of each, Config.ObstacleScale
applied); the Godlands mountains from tools/godlands_concept.py (GodlandsTracks kits)."""
import os
import sys
import xml.etree.ElementTree as ET

import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..", "..")
sys.path.insert(0, os.path.join(ROOT, "tools"))
import partlib  # noqa: E402
from partlib import Part  # noqa: E402
import course_layout as CL  # noqa: E402

ROWS = [
    ("Meadow", ["Stone", "Bush", "Boulder", "BoulderSplit"], ((113, 173, 31), (122, 190, 25))),
    ("Desert", ["Sandstone", "Cactus", "SandBoulder", "SandBoulderCarved", "SandMound"], ((232, 188, 102), (250, 214, 130))),
    ("Tundra", ["Icicle", "IcicleLarge", "Pine", "IceBoulder"], ((228, 234, 242), (244, 247, 251))),
    ("Ocean", ["TubeCoral", "BrainCoral", "BranchCoral", "FanCoral", "BasaltRock", "ReefRock", "Vent"], ((236, 214, 164), (246, 228, 184))),
]
COUNT = {}


def load():
    r = ET.parse(os.path.join(ROOT, "src/world/World.rbxmx")).getroot()
    obs = [i for i in r.iter("Item") if i.get("class") == "Folder" and i.find('Properties/string[@name="Name"]').text == "Obstacles"][0]
    first = {}
    for m in obs.findall("Item"):
        n = m.find('Properties/string[@name="Name"]').text
        COUNT[n] = COUNT.get(n, 0) + 1
        if n in first:
            continue
        parts, base = [], None
        for p in m.iter("Item"):
            if p.get("class") != "Part":
                continue
            pr = p.find("Properties")
            g = lambda tag, nm: pr.find(f'{tag}[@name="{nm}"]')
            cf = g("CoordinateFrame", "CFrame")
            v = [float(cf.find(k).text) for k in ("X", "Y", "Z", "R00", "R01", "R02", "R10", "R11", "R12", "R20", "R21", "R22")]
            M = np.eye(4)
            M[:3, 3] = v[:3]
            M[:3, :3] = np.array(v[3:]).reshape(3, 3)
            sz = g("Vector3", "size")
            size = tuple(float(sz.find(k).text) for k in "XYZ")
            tr = g("float", "Transparency")
            if pr.find('string[@name="Name"]').text == "Base" and tr is not None and float(tr.text) >= 1:
                base = M[:3, 3].copy()
                continue
            c = int(g("Color3uint8", "Color3uint8").text)
            col = ((c >> 16) & 255, (c >> 8) & 255, c & 255)
            shp = g("token", "shape")
            shape = {"0": "Ball", "2": "Cylinder"}.get(shp.text if shp is not None else "1", "Block")
            studs = any(t.get("class") == "Texture" for t in p.findall("Item"))
            parts.append(Part("P", size, M, col, plain=not studs, shape=shape))
        if base is None:
            base = np.array([np.mean([q.cf[0, 3] for q in parts]), 0, np.mean([q.cf[2, 3] for q in parts])])
        base[1] += 0.5  # the Base part's top is the floor
        s = CL.SCALE.get(n, 1.0)
        out = []
        for q in parts:
            cf = q.cf.copy()
            cf[:3, 3] = (cf[:3, 3] - base) * s
            out.append(Part(q.name, tuple(x * s for x in q.size), cf, q.color, plain=q.plain, shape=q.shape))
        first[n] = out
    return first


def mountains():
    import godlands_concept as GC
    return {n: GC.mountain_kit(n)[0] for n in ("MountainLeft", "MountainCenter", "MountainRight")}


def width(parts):
    xs = [q.cf[0, 3] for q in parts]
    ext = [max(q.size) / 2 for q in parts]
    return max(x + e for x, e in zip(xs, ext)) - min(x - e for x, e in zip(xs, ext))


def font(sz):
    return ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", sz)


def row(items, ground, W=1800, H=420, gap=6, eye_k=1.0):
    partlib.GROUND = np.array(ground[0], float)
    partlib.GROUND2 = np.array(ground[1], float)
    ws = [width(p) for _, p in items]
    total = sum(ws) + gap * (len(ws) - 1)
    x = -total / 2
    scene, xs = [], []
    for (n, ps), w in zip(items, ws):
        cx = -(x + w / 2)
        T = partlib.T(cx, 0, 0) @ partlib.Ry(20)
        scene += [Part(q.name, q.size, T @ q.cf, q.color, plain=q.plain, shape=q.shape) for q in ps]
        xs.append(cx)
        x += w + gap
    dist = total * 1.05 * eye_k
    eye, target = (0, dist * 0.32, -dist), (0, dist * 0.04, 0)
    fov = 36
    img = partlib.render(scene, eye=eye, target=target, W=W, H=H, fov=fov, fog=False, outline=False).convert("RGB")
    d = ImageDraw.Draw(img)
    e, r, u, f = partlib.look_at(eye, target)
    focal = (H / 2) / np.tan(np.radians(fov) / 2)
    for (n, _), cx in zip(items, xs):
        dv = np.array([cx, 0, -6]) - e
        px = W / 2 + focal * (dv @ r) / (dv @ f)
        lab = f"{n} x{COUNT.get(n, '?')}" if n in COUNT else n
        tw = d.textlength(lab, font=font(22))
        d.text((px - tw / 2, H - 40), lab, font=font(22), fill="white", stroke_width=4, stroke_fill="black")
    return img


def tile(name, ps, ground, TW=300, TH=300):
    partlib.GROUND = np.array(ground[0], float)
    partlib.GROUND2 = np.array(ground[1], float)
    R = partlib.Ry(25)
    scene = [Part(q.name, q.size, R @ q.cf, q.color, plain=q.plain, shape=q.shape) for q in ps]
    pts = np.array([q.cf[:3, 3] for q in scene])
    ext = max(max(q.size) for q in scene) / 2
    lo, hi = pts.min(0) - ext, pts.max(0) + ext
    hi[1] = max(hi[1], 0.5)
    size = max(hi[0] - lo[0], hi[2] - lo[2], hi[1] * 1.3)
    c = (lo + hi) / 2
    dist = size * 1.7
    eye = (c[0], hi[1] * 0.5 + dist * 0.55, c[2] - dist)
    target = (c[0], hi[1] * 0.4, c[2])
    img = partlib.render(scene, eye=eye, target=target, W=TW, H=TH, fov=40, fog=False, outline=False).convert("RGB")
    d = ImageDraw.Draw(img)
    lab = f"{name}" + (f" x{COUNT[name]}" if name in COUNT else "")
    tw = d.textlength(lab, font=font(20))
    d.text(((TW - tw) / 2, TH - 34), lab, font=font(20), fill="white", stroke_width=4, stroke_fill="black")
    tall = hi[1]
    d.text((8, 6), f"{tall:.0f} studs tall", font=font(15), fill="white", stroke_width=3, stroke_fill="black")
    return img


if __name__ == "__main__":
    kits = load()
    kits.update(mountains())
    rows = ROWS + [("Godlands", ["MountainLeft", "MountainCenter", "MountainRight"], ((208, 212, 224), (224, 228, 238)))]
    TW, TH, BAND, PAD = 300, 300, 46, 6
    ncol = max(len(n) for _, n, _ in rows)
    W = ncol * (TW + PAD) + PAD
    sheet = Image.new("RGB", (W, len(rows) * (TH + BAND)), "white")
    d = ImageDraw.Draw(sheet)
    for i, (title, names, ground) in enumerate(rows):
        y = i * (TH + BAND)
        d.text((PAD + 4, y + 10), title, font=font(26), fill=(20, 20, 20))
        for j, n in enumerate(names):
            sheet.paste(tile(n, kits[n], ground, TW, TH), (PAD + j * (TW + PAD), y + BAND))
        print("row", title)
    sheet.save(os.path.join(HERE, "biome_assets.png"))
