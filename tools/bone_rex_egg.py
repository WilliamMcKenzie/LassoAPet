"""The Bone Rex's egg (QM Oct 11: "an EPIC super complex egg"), in take C's style: an obsidian
shell split by glowing green cracks, a ribcage of grey bones wrapped round its front with a
glowing soul gem showing between them, tiny bone arms with glowing claws, a spiked spine down
its back to a little bone tail, bone feet with glowing talons gripping the ground, and the
Bone Rex's skull crowning it: dark sockets with burning eyes, fangs over the shell, horns, a
spiked frill and soul fire streaming back off it. Glow* parts are Neon in game.

Run from the repo root: python3 tools/bone_rex_egg.py
Writes designs/eggs/c_style/BoneRexEgg.bbmodel, assets/ui/BoneRexEggRender.png and previews
in /mnt/project-files/animals/bonerex/.
"""

import json
import math
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
import horse_egg_takes as C  # noqa: E402
from egg_designs import SPLIT  # noqa: E402
from horse_egg_takes import H, LH, WIDTHS, shell  # noqa: E402
from partlib import render  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
OUT = "/mnt/project-files/animals/bonerex"
SHELL, BASE = (52, 48, 62), (36, 32, 44)
BONE, KNOB = (150, 140, 166), (118, 108, 134)  # grey bone, so it shows on the black shell
DARK = (20, 16, 26)
GLOW, CORE = (60, 255, 110), (220, 255, 200)


def chamfer(w):
    return round(w / (2 + math.sqrt(2)) / 0.1) * 0.1


def pyr(egg, name, base, d, hw, length, color, bone=None):
    """Square pyramid: base centred on `base`, pointing along d."""
    d = np.asarray(d, float) / np.linalg.norm(d)
    u = np.cross(d, [0, 1, 0]) if abs(d[1]) < 0.9 else np.array([1.0, 0, 0])
    u /= np.linalg.norm(u)
    v = np.cross(d, u)
    base = np.asarray(base, float)
    q = [base - u * hw - v * hw, base + u * hw - v * hw, base + u * hw + v * hw, base - u * hw + v * hw]
    tip = base + d * length
    return egg.poly(name, [q[::-1]] + [[q[j], q[(j + 1) % 4], tip] for j in range(4)], color, bone=bone)


def bone_rex_egg():
    egg = shell([BASE] + [SHELL] * 6)

    # ---- glowing cracks: zigzags running up the back and both sides, a layer a step
    def crack(name, face, offsets, layers):
        prev = None
        for k, i in enumerate(layers):
            a = WIDTHS[i] / 2
            o = offsets[k]
            y0, y1 = i * LH, (i + 1) * LH
            if face == "back":
                egg.block(f"Glow{name}{k}", (o - 0.04, y0, a - 0.02), (o + 0.04, y1, a + 0.04), GLOW)
            else:
                sx = -1 if face == "L" else 1
                x0, x1 = sorted((sx * (a - 0.02), sx * (a + 0.04)))
                egg.block(f"Glow{name}{k}", (x0, y0, o - 0.04), (x1, y1, o + 0.04), GLOW)
            if prev is not None:  # a short run across to join the last step
                lo, hi = sorted((prev, o))
                if face == "back":
                    egg.block(f"Glow{name}J{k}", (lo - 0.04, y0 - 0.04, a - 0.02), (hi + 0.04, y0 + 0.04, a + 0.04), GLOW)
                else:
                    egg.block(f"Glow{name}J{k}", (x0, y0 - 0.04, lo - 0.04), (x1, y0 + 0.04, hi + 0.04), GLOW)
            prev = o
    crack("CrackBackL", "back", (-0.5, -0.3, -0.55, -0.35, -0.2), (1, 2, 3, 4, 5))
    crack("CrackBackR", "back", (0.45, 0.6, 0.4, 0.55), (1, 2, 3, 4))
    crack("CrackL", "L", (0.3, 0.05, 0.35, 0.15), (2, 3, 4, 5))
    crack("CrackR", "R", (-0.1, 0.25, 0.0, 0.3, 0.1), (1, 2, 3, 4, 5))

    # ---- the ribcage: grey ribs wrapping round the front and sides on layers 1-3, a gap
    # down the middle where the soul gem glows
    for i in (1, 2, 3):
        a = WIDTHS[i] / 2
        c = chamfer(WIDTHS[i])
        for r, y in enumerate((i * LH + 0.1, i * LH + 0.29)):
            yy = (y, y + 0.13)
            for sx, side in ((-1, "L"), (1, "R")):
                x0, x1 = sorted((sx * 0.3, sx * (a - c + 0.02)))
                egg.block(f"Rib{i}{r}{side}F", (x0, yy[0], -a - 0.09), (x1, yy[1], -a + 0.02), BONE)
                cx, cz = sx * (a - c / 2), -(a - c / 2)
                h = c * 0.42
                egg.block(f"Rib{i}{r}{side}C", (cx - h, yy[0], cz - h), (cx + h, yy[1], cz + h), BONE)
                x0, x1 = sorted((sx * (a - 0.02), sx * (a + 0.09)))
                egg.block(f"Rib{i}{r}{side}S", (x0, yy[0], -(a - c) - 0.02), (x1, yy[1], 0.35), BONE)
    # sternum knobs either side of the gap
    for sx, side in ((-1, "L"), (1, "R")):
        x0, x1 = sorted((sx * 0.24, sx * 0.36))
        egg.block("Sternum" + side, (x0, LH + 0.05, -WIDTHS[2] / 2 - 0.12), (x1, 4 * LH - 0.05, -WIDTHS[2] / 2 + 0.02), KNOB)
    # the soul gem between the ribs: a glowing cross with a white-hot heart
    z = -WIDTHS[2] / 2
    egg.block("GlowGem", (-0.2, 1.5 * LH, z - 0.1), (0.2, 3.5 * LH, z + 0.02), GLOW)
    egg.block("GlowGemX", (-0.26, 2.2 * LH, z - 0.12), (0.26, 2.8 * LH, z + 0.02), GLOW)
    egg.block("GlowGemHot", (-0.1, 2.15 * LH, z - 0.16), (0.1, 2.85 * LH, z - 0.08), CORE)

    # ---- tiny bone arms on the front, two glowing claws each
    for sx, side in ((-1, "L"), (1, "R")):
        a = WIDTHS[4] / 2
        xa = sx * (a - chamfer(WIDTHS[4]) * 0.5)
        x0, x1 = sorted((xa - sx * 0.08, xa + sx * 0.1))
        y = 4 * LH + 0.1
        egg.block("Shoulder" + side, (x0 - 0.04, y, -a + 0.1), (x1 + 0.04, y + 0.2, -a + 0.3), KNOB)
        egg.block("Humerus" + side, (x0, y - 0.25, -a - 0.05), (x1, y + 0.1, -a + 0.15), BONE)
        egg.block("Forearm" + side, (x0, y - 0.32, -a - 0.32), (x1, y - 0.17, -a - 0.05), BONE)
        for k, dx in enumerate((-0.045, 0.045)):
            pyr(egg, f"GlowArmClaw{side}{k}", (xa + dx, y - 0.25, -a - 0.32), (0, -0.4, -1), 0.035, 0.16, GLOW)

    # ---- spine down the back: vertebrae with a glowing disc each and a spike leaning up
    # and back, then a little bone tail off the base
    for i in range(1, 6):
        a = WIDTHS[i] / 2
        y0, y1 = i * LH + 0.04, (i + 1) * LH - 0.04
        egg.block(f"Vert{i}", (-0.14, y0, a - 0.04), (0.14, y1, a + 0.14), BONE)
        egg.block(f"GlowVert{i}Disc", (-0.1, y1, a - 0.02), (0.1, y1 + 0.08, a + 0.1), GLOW)
        pyr(egg, f"SpikeVert{i}", ((0, (y0 + y1) / 2, a + 0.14)), (0, 0.55, 1), 0.09, 0.32 + 0.04 * (3 - abs(i - 3)), BONE)
        pyr(egg, f"GlowSpikeVert{i}", (0, (y0 + y1) / 2 + 0.13, a + 0.39 + 0.03 * (3 - abs(i - 3))), (0, 0.55, 1), 0.05, 0.16, GLOW)
    zb = WIDTHS[0] / 2
    for k, (z0, z1, h) in enumerate(((zb - 0.05, zb + 0.35, 0.3), (zb + 0.38, zb + 0.68, 0.24), (zb + 0.71, zb + 0.93, 0.18))):
        egg.block(f"Tail{k}", (-h / 2, 0.02, z0), (h / 2, 0.02 + h, z1), BONE)
        egg.block(f"GlowTail{k}Disc", (-h / 2 + 0.03, 0.05, z1), (h / 2 - 0.03, h - 0.01, z1 + 0.03), GLOW)
        pyr(egg, f"GlowSpikeTail{k}", (0, 0.02 + h, (z0 + z1) / 2), (0, 1, 0.4), 0.05, 0.16 - 0.03 * k, GLOW)
    pyr(egg, "GlowTailTip", (0, 0.11, zb + 0.96), (0, 0, 1), 0.06, 0.2, GLOW)

    # ---- feet: bone toes splayed out of the base at the four corners, glowing talons
    a0 = WIDTHS[0] / 2
    for sx, sz, nm in ((-1, -1, "FL"), (1, -1, "FR"), (-1, 1, "BL"), (1, 1, "BR")):
        d = np.array([sx, 0, sz]) / math.sqrt(2)
        for k, off in enumerate((-0.12, 0.0, 0.12)):
            side = np.array([-d[2], 0, d[0]]) * off
            base = d * (a0 - 0.05) + side
            tip = base + d * 0.28
            lo, hi = np.minimum(base, tip) - [0.05, 0, 0.05], np.maximum(base, tip) + [0.05, 0, 0.05]
            egg.block(f"Toe{nm}{k}", (lo[0], 0.0, lo[2]), (hi[0], 0.12, hi[2]), BONE)
            pyr(egg, f"GlowTalon{nm}{k}", tuple(tip + d * 0.04 + [0, 0.06, 0]), tuple(d + [0, -0.3, 0]), 0.045, 0.16, GLOW)

    # ---- the skull crowning it, facing front: a heavy grey skull, dark sockets with burning
    # eyes and slit pupils, nostrils, fangs hanging over the shell, horns, a spiked frill
    top = H - 0.05
    egg.block("Skull", (-0.5, top, -0.62), (0.5, top + 0.5, 0.28), BONE)
    egg.block("SkullBack", (-0.56, top + 0.04, 0.0), (0.56, top + 0.46, 0.34), KNOB)
    egg.block("Snout", (-0.38, top + 0.02, -1.05), (0.38, top + 0.4, -0.6), BONE)
    egg.block("SnoutTip", (-0.3, top + 0.04, -1.16), (0.3, top + 0.34, -1.04), BONE)
    for sx, side in ((-1, "L"), (1, "R")):
        x0, x1 = sorted((sx * 0.44, sx * 0.52))
        egg.block("DarkSocket" + side, (x0, top + 0.14, -0.5), (x1, top + 0.42, -0.2), DARK)
        x0, x1 = sorted((sx * 0.48, sx * 0.53))
        egg.block("GlowEye" + side, (x0, top + 0.18, -0.46), (x1, top + 0.38, -0.24), GLOW)
        x0, x1 = sorted((sx * 0.53, sx * 0.55))
        egg.block("GlowPupil" + side, (x0, top + 0.21, -0.4), (x1, top + 0.35, -0.33), CORE)
        x0, x1 = sorted((sx * 0.3, sx * 0.56))
        egg.block("Brow" + side, (x0, top + 0.42, -0.58), (x1, top + 0.56, -0.18), KNOB)
        x0, x1 = sorted((sx * 0.34, sx * 0.39))
        egg.block("DarkNostril" + side, (x0, top + 0.26, -1.12), (x1, top + 0.34, -1.02), DARK)
        pyr(egg, "Horn" + side, (sx * 0.43, top + 0.56, -0.38), (sx * 0.35, 1, 0.25), 0.07, 0.3, BONE)
        # soul fire streaming up and back out of each socket
        for j, (dy, dz, s) in enumerate(((0.52, -0.3, 0.12), (0.62, -0.08, 0.11), (0.72, 0.14, 0.095), (0.8, 0.36, 0.08), (0.86, 0.56, 0.06))):
            col = CORE if j == 0 else GLOW
            egg.block(f"GlowFlame{side}{j}", (sx * 0.48 - s, top + dy, dz - s), (sx * 0.48 + s, top + dy + 2 * s, dz + s), col)
        # fangs down the side of the snout, over the shell's front
        for k, zf in enumerate((-1.0, -0.86, -0.72, -0.58)):
            pyr(egg, f"Fang{side}{k}", (sx * 0.33, top + 0.02, zf), (0, -1, 0), 0.04, 0.2 if k == 1 else 0.14, BONE)
    for k, x in enumerate((-0.15, 0.0, 0.15)):
        pyr(egg, f"FangFront{k}", (x, top + 0.04, -1.12), (0, -1, 0), 0.035, 0.13, BONE)
    # crest spikes down the middle of the skull and the frill fanned behind it
    for k, z in enumerate((-0.9, -0.6, -0.3)):
        pyr(egg, f"SpikeSkull{k}", (0, top + 0.5 if z > -0.62 else top + 0.4, z), (0, 1, 0), 0.05, 0.1 + 0.03 * k, BONE)
    for k, ang in enumerate((-50, -25, 0, 25, 50)):
        r = math.radians(ang)
        d = (math.sin(r) * 0.8, 0.45, 1)
        base = (0.5 * math.sin(r), top + 0.3, 0.34)
        pyr(egg, f"SpikeFrill{k}", base, d, 0.08, 0.34, BONE)
        tip = np.array(base) + np.array(d) / np.linalg.norm(d) * 0.3
        pyr(egg, f"GlowFrill{k}", tuple(tip), d, 0.04, 0.14, GLOW)
    # the skull a size up, so it rules the egg
    S, pivot = 1.25, np.array([0.0, top, -0.3])
    for p in egg.parts:
        if p.name.startswith(("Skull", "Snout", "DarkSocket", "DarkNostril", "GlowEye", "GlowPupil", "Brow", "Horn", "GlowFlame", "Fang", "SpikeSkull", "SpikeFrill", "GlowFrill")):
            p.bone = "top"
            if p.shape == "Poly":
                p.polys = [pivot + (q - pivot) * S for q in p.polys]
            else:
                p.size = np.array(p.size) * S
                p.cf[:3, 3] = pivot + (p.cf[:3, 3] - pivot) * S
    return egg


def main(out=OUT):
    import egg_designs as E
    from horse_rig import write_animations
    from partlib import write_bbmodel
    from PIL import Image
    os.makedirs(out, exist_ok=True)
    egg = bone_rex_egg()
    bones = [("egg", None, (0, 0, 0)), ("bottom", "egg", (0, 0, 0)), ("top", "egg", (0, SPLIT, 0))]
    model, groups = write_bbmodel(egg.parts, "BoneRexEgg", None, bones=bones)
    write_animations(model, groups, E.animations())
    path = os.path.join(ROOT, "designs", "eggs", "c_style", "BoneRexEgg.bbmodel")
    for dst in (path, os.path.join(out, "BoneRexEgg.bbmodel")):
        with open(dst, "w") as f:
            json.dump(model, f, separators=(",", ":"))
    for p in egg.parts:
        if p.name.startswith("Glow"):
            p.neon = True
    tile = 560
    sheet = Image.new("RGB", (tile * 3, tile))
    views = list(C.VIEWS) + [dict(eye=(-11, 3.4, 0), target=(0, 2.4, 0))]
    for r, view in enumerate(views):
        v = {k: tuple(np.array(x, float) + [0, 0.5, 0]) for k, x in view.items()}
        sheet.paste(render(egg.parts, W=tile, H=tile, fov=36, **v), (r * tile, 0))
    sheet.save(os.path.join(out, "BoneRexEgg.png"))
    im = render(egg.parts, W=1100, H=1300, fov=34, transparent=True, **C.VIEWS[0])
    im = im.crop(im.getbbox())
    im.save(os.path.join(ROOT, "assets", "ui", "BoneRexEggRender.png"))
    print(len(egg.parts), "parts, render", im.size)


if __name__ == "__main__":
    main(*sys.argv[1:])
