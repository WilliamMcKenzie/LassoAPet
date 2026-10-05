"""Furnace drafts (QM Oct 5: a robot-ish creature for a fire biome, with a grill over
its face that shows a fiery inside; reference: a riveted iron boiler-knight with a
pointed iron hat, a slotted visor glowing orange, blue mitts and bare feet).

Run: python3 tools/furnace_design.py [out_dir]   (renders the three takes)

Every take shares the head: an iron box whose front is a grate of iron bars over a
glowing orange inside, under a pointed iron hat with a brim. The takes differ in body:
  A Walker   stands on two stubby legs like the reference, arms with blue mitts
  B Stove    a potbelly stove on four stubby legs, a glowing belly door and a chimney
  C Brute    a knuckle-walker like the Ice Golem: big mitt arms in front, short back legs

Rest pose: facing -z. Bones: root (body) -> neck (head and hat), plus legs / arms.
Parts named Glow* turn Neon in game, Metal* get Roblox's metal texture.
"""

import json
import os
import sys

from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, os.path.dirname(__file__))
import horse_rig  # noqa: E402
import snake_design as S  # noqa: E402
from partlib import render  # noqa: E402

horse_rig.EULER = "ZYX"
S.SIZE = 1.0
ROOT = os.path.join(os.path.dirname(__file__), "..")
BB = S.BB

COLORS = {"iron": (128, 134, 150), "dark": (80, 84, 100), "rivet": (56, 58, 70), "mitt": (58, 112, 226),
          "skin": (240, 178, 136), "glow": (255, 128, 24), "core": (255, 214, 64)}
TEX = {n: i for i, n in enumerate(COLORS)}

TAKES = {"A": "A  Walker: two legs, mitts, like your picture",
         "B": "B  Stove: potbelly stove on four legs, chimney",
         "C": "C  Brute: knuckle-walker like the Ice Golem"}


def pyr(name, base, hw, hd, h, col):
    """A square pyramid standing on `base` (studs, centre of its footprint), point up."""
    x, y, z = (b * BB for b in base)
    w, d, H = hw * BB, hd * BB, h * BB
    v = {"a": [-w, 0, -d], "b": [w, 0, -d], "c": [w, 0, d], "d": [-w, 0, d], "e": [0, H, 0]}
    faces = {"bottom": ["a", "b", "c", "d"], "n": ["a", "e", "b"], "east": ["b", "e", "c"],
             "s": ["c", "e", "d"], "w": ["d", "e", "a"]}
    return {"name": name, "type": "mesh", "uuid": S.uid(), "color": 0, "origin": [x, y, z], "rotation": [0, 0, 0],
            "vertices": v, "faces": {k: {"texture": TEX[col], "vertices": vs, "uv": {q: [0, 0] for q in vs}}
                                     for k, vs in faces.items()}}


def build(take):
    elements, groups = [], []

    def add_group(name, pivot, parent):
        g = S.group(name, pivot)
        groups.append(g)
        node = {"uuid": g["uuid"], "isOpen": True, "children": []}
        if parent is not None:
            parent["children"].append(node)
        return node

    def put(node, *parts):
        for e in parts:
            elements.append(e)
            node["children"].append(e["uuid"])

    def c(name, center, size, col):
        return S.cube(name, center, size, TEX[col])

    def head(parent, cx, cy, cz, s=3.8):
        """Head box centred at (cx, cy, cz) with the grate on its -z face, hat on top."""
        node = add_group("neck", (cx, cy - s / 2, cz + s / 2), parent)
        f = cz - s / 2  # front face
        put(node, c("MetalHead", (cx, cy, cz + 0.3), (s, s, s - 0.6), "iron"),
            # the fire inside, set back behind the bars
            c("GlowInside", (cx, cy - 0.1, f + 0.5), (s - 1.0, s - 1.4, 0.6), "glow"),
            c("GlowCore", (cx, cy - 0.3, f + 0.35), (s - 2.0, s - 2.2, 0.4), "core"),
            # frame round the grate
            c("MetalFrameTop", (cx, cy + s / 2 - 0.35, f + 0.2), (s, 0.7, 0.4), "dark"),
            c("MetalFrameBot", (cx, cy - s / 2 + 0.35, f + 0.2), (s, 0.7, 0.4), "dark"))
        for sx in (-1, 1):
            put(node, c(f"MetalFrame{'LR'[sx > 0]}", (cx + sx * (s / 2 - 0.25), cy, f + 0.2), (0.5, s, 0.4), "dark"))
        # the grill: vertical iron bars across the glow
        for k, dx in enumerate((-0.9, 0, 0.9)):
            put(node, c(f"MetalBar{k}", (cx + dx, cy - 0.1, f + 0.15), (0.32, s - 1.3, 0.3), "dark"))
        # hat: a wide brim and a pointed iron cone, rivets round the brim
        top = cy + s / 2
        put(node, c("MetalBrim", (cx, top + 0.2, cz), (s + 2.2, 0.4, s + 2.2), "dark"),
            c("MetalHatBand", (cx, top + 0.7, cz), (s - 0.2, 0.6, s - 0.2), "iron"),
            pyr("HatCone", (cx, top + 1.0, cz), s / 2 - 0.1, s / 2 - 0.1, 4.2, "iron"))
        for k, (dx, dz) in enumerate(((-1, -1), (1, -1), (1, 1), (-1, 1))):
            r = (s + 2.2) / 2 - 0.4
            put(node, c(f"Rivet{k}", (cx + dx * r, top + 0.5, cz + dz * r), (0.4, 0.3, 0.4), "rivet"))
        return node

    def mitt_arm(parent, name, x, y_shoulder, z, length, up_w=1.2, mitt=2.0):
        node = add_group(name, (x, y_shoulder, z), parent)
        put(node, c("Metal" + name, (x, y_shoulder - length / 2, z), (up_w, length, up_w), "iron"),
            c(name + "Mitt", (x, y_shoulder - length - mitt / 2 + 0.3, z), (mitt, mitt, mitt), "mitt"))
        return node

    def stub_leg(parent, name, x, y_hip, z, length, foot="skin", w=1.4):
        node = add_group(name, (x, y_hip, z), parent)
        put(node, c("Metal" + name, (x, y_hip - length / 2 + 0.3, z), (w, length, w), "dark"))
        if foot == "skin":  # bare feet like the reference, toes forward
            put(node, c(name + "Foot", (x, 0.4, z - 0.35), (w + 0.4, 0.8, w + 1.0), "skin"))
        else:
            put(node, c(name + "Foot", (x, 0.35, z), (w + 0.4, 0.7, w + 0.4), "rivet"))
        return node

    def rivets(node, prefix, xs, y, z):
        for k, x in enumerate(xs):
            put(node, c(f"{prefix}{k}", (x, y, z), (0.36, 0.36, 0.3), "rivet"))

    if take == "A":
        # upright boiler on two stubby legs
        y0, h, w, d = 2.4, 6.2, 6.0, 5.0
        root = add_group("root", (0, y0 + h / 2, 0), None)
        put(root, c("MetalBody", (0, y0 + h / 2, 0), (w, h, d), "iron"),
            c("MetalBelt", (0, y0 + 0.5, 0), (w + 0.3, 1.0, d + 0.3), "dark"),
            c("MetalCollar", (0, y0 + h + 0.2, 0), (w - 1.6, 0.4, d - 1.0), "dark"))
        rivets(root, "BeltRivet", (-2.2, -0.75, 0.75, 2.2), y0 + 0.5, -d / 2 - 0.25)
        for sx in (-1, 1):
            s = "LR"[sx > 0]
            put(root, c("MetalPauldron" + s, (sx * (w / 2 + 0.3), y0 + h - 0.6, 0), (1.8, 1.4, 3.0), "dark"))
            stub_leg(root, "Leg" + s, sx * 1.5, y0 + 0.5, 0.2, 2.9)
            mitt_arm(root, "Arm" + s, sx * (w / 2 + 0.9), y0 + h - 1.2, 0, 3.0)
        head(root, 0, y0 + h + 0.4 + 1.9, -0.2)
        seat = (0, y0 + h + 0.4, 1.6)
    elif take == "B":
        # potbelly stove lying long-ways on four short legs
        y0, h, w, d = 1.8, 5.0, 5.4, 8.0
        root = add_group("root", (0, y0 + h / 2, 0), None)
        put(root, c("MetalBody", (0, y0 + h / 2, 0), (w, h, d), "iron"),
            c("MetalBelly", (0, y0 + h / 2 - 0.2, 0), (w + 0.6, h - 1.6, d - 1.6), "iron"),
            c("MetalTopPlate", (0, y0 + h + 0.2, 0.8), (w - 1.0, 0.4, d - 2.6), "dark"),
            c("MetalBase", (0, y0 + 0.3, 0), (w + 0.2, 0.6, d + 0.2), "dark"))
        # the belly door on each side: a frame with glowing slots
        for sx in (-1, 1):
            s = "LR"[sx > 0]
            xf = sx * (w / 2 + 0.4)
            put(root, c("MetalDoor" + s, (xf, y0 + h / 2 - 0.2, 0.6), (0.3, 2.4, 3.4), "dark"))
            for k, dz in enumerate((-0.8, 0, 0.8)):
                put(root, c(f"GlowSlot{s}{k}", (xf + sx * 0.12, y0 + h / 2 - 0.2, 0.6 + dz), (0.2, 1.6, 0.4), "glow"))
        # chimney on the back with a glowing ember top
        put(root, c("MetalChimney", (0, y0 + h + 1.6, d / 2 - 1.0), (1.4, 3.2, 1.4), "dark"),
            c("MetalChimneyCap", (0, y0 + h + 3.4, d / 2 - 1.0), (2.0, 0.5, 2.0), "rivet"),
            c("GlowEmber", (0, y0 + h + 3.7, d / 2 - 1.0), (1.0, 0.2, 1.0), "core"))
        for i, (lz, nm) in enumerate(((-2.6, "F"), (2.6, "B"))):
            for sx in (-1, 1):
                stub_leg(root, f"Leg{nm}{'LR'[sx > 0]}", sx * 1.8, y0 + 0.4, lz, 2.0, foot="iron", w=1.3)
        head(root, 0, y0 + h - 0.6, -d / 2 - 1.6, s=3.6)
        seat = (0, y0 + h + 0.4, 0.2)
    else:
        # knuckle-walker: big shoulders in front on mitt arms, short back legs
        root = add_group("root", (0, 5.0, 0), None)
        put(root, c("MetalChest", (0, 5.8, -1.4), (6.4, 4.8, 4.0), "iron"),
            c("MetalHips", (0, 4.6, 2.2), (5.0, 3.4, 3.4), "iron"),
            c("MetalBelt", (0, 3.4, 0.4), (5.4, 0.9, 6.8), "dark"),
            c("MetalBackPlate", (0, 8.35, -1.2), (5.2, 0.4, 3.4), "dark"))
        rivets(root, "ChestRivet", (-2.4, 2.4), 7.4, -3.55)
        # a glowing vent down the chest between the arms
        put(root, c("MetalVent", (0, 5.4, -3.5), (2.0, 2.4, 0.3), "dark"))
        for k, dx in enumerate((-0.5, 0.5)):
            put(root, c(f"GlowVent{k}", (dx, 5.4, -3.7), (0.35, 1.8, 0.2), "glow"))
        for sx in (-1, 1):
            s = "LR"[sx > 0]
            put(root, c("MetalPauldron" + s, (sx * 3.7, 7.6, -1.4), (2.0, 1.6, 3.4), "dark"))
            mitt_arm(root, "Arm" + s, sx * 4.0, 7.0, -1.6, 4.6, up_w=1.6, mitt=2.4)
            stub_leg(root, "Leg" + s, sx * 1.6, 3.4, 2.6, 2.4)
        head(root, 0, 6.2, -5.2, s=3.6)
        seat = (0, 8.5, 1.2)

    model = json.load(open(os.path.join(ROOT, "designs", "desert", "Snake.bbmodel")))
    model.update(name="Furnace", elements=elements, groups=groups, outliner=[root], animations=[],
                 textures=[S.solid_texture(n, col) for n, col in COLORS.items()])
    model.setdefault("meta", {})["format_version"] = "5.0"
    model["furnace_seat"] = seat
    return model


def posed(m, anim=None, t=0.0):
    ps = S.posed(m, anim, t)
    for p in ps:
        p.neon = p.name.startswith("Glow")
        p.plain = p.plain or p.neon
    return ps


def sheet(out):
    W, H = 520, 460
    cams = [dict(eye=(-24, 16, -26), target=(0, 5.5, 0)), dict(eye=(0, 8, -32), target=(0, 6, 0)),
            dict(eye=(-34, 9, 4), target=(0, 6, 0)), dict(eye=(22, 18, 26), target=(0, 5.5, 0))]
    im = Image.new("RGB", (W * len(cams), (H + 40) * len(TAKES)), (255, 255, 255))
    dr = ImageDraw.Draw(im)
    try:
        font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 26)
    except OSError:
        font = None
    for r, take in enumerate(TAKES):
        m = build(take)
        with open(os.path.join(out, f"Furnace_{take}.bbmodel"), "w") as f:
            json.dump(m, f, separators=(",", ":"))
        ps = posed(m)
        dr.text((16, r * (H + 40) + 6), f"{TAKES[take]}   ({len(m['elements'])} blocks)", fill=(20, 20, 20), font=font)
        for i, cam in enumerate(cams):
            im.paste(render(ps, W=W, H=H, fov=40, **cam), (i * W, r * (H + 40) + 40))
    im.save(os.path.join(out, "Furnace_takes.png"))


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "/mnt/project-files/animals/furnace"
    os.makedirs(out, exist_ok=True)
    sheet(out)
