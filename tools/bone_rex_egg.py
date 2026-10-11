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
    """Blocks only (QM: under 150 parts; a pyramid costs 4 in game), the octo shell is 63."""
    egg = shell([BASE] + [SHELL] * 6)

    def blk(name, lo, hi, color, bone=None):
        p = egg.block(name, lo, hi, color)
        if bone:
            p.bone = bone
        return p

    # ---- glowing cracks: one zigzag up the back, one down the right side
    for k, (i, o0, o1) in enumerate(((1, -0.5, -0.5), (2, -0.5, -0.2), (3, -0.2, -0.2), (4, -0.2, -0.45), (5, -0.45, -0.45))):
        a = WIDTHS[i] / 2
        lo, hi = sorted((o0, o1))
        if o0 == o1:
            blk(f"GlowCrackBack{k}", (o0 - 0.04, i * LH, a - 0.02), (o0 + 0.04, (i + 1) * LH, a + 0.04), GLOW)
        else:  # a step across
            blk(f"GlowCrackBack{k}", (lo - 0.04, i * LH, a - 0.02), (hi + 0.04, i * LH + 0.08, a + 0.04), GLOW)
    for k, (i, o) in enumerate(((2, 0.25), (3, -0.05), (4, 0.2))):
        a = WIDTHS[i] / 2
        blk(f"GlowCrackR{k}", (a - 0.02, i * LH, o - 0.04), (a + 0.04, (i + 1) * LH + 0.04, o + 0.04), GLOW)

    # ---- the ribcage: a rib per layer on each side, wrapping from beside the gem round the
    # front corner and down the side; the soul gem glowing in the gap
    for i in (1, 2, 3):
        a = WIDTHS[i] / 2
        c = chamfer(WIDTHS[i])
        y = (i * LH + 0.15, i * LH + 0.3)
        for sx, side in ((-1, "L"), (1, "R")):
            x0, x1 = sorted((sx * 0.3, sx * (a - c * 0.35)))
            blk(f"Rib{i}{side}F", (x0, y[0], -a - 0.09), (x1, y[1], -a + c * 0.65), BONE)
            x0, x1 = sorted((sx * (a - c * 0.35), sx * (a + 0.09)))
            blk(f"Rib{i}{side}S", (x0, y[0], -(a - c * 0.35)), (x1, y[1], 0.35), BONE)
        x0 = 0.24
    for sx, side in ((-1, "L"), (1, "R")):
        x0, x1 = sorted((sx * 0.24, sx * 0.36))
        blk("Sternum" + side, (x0, LH + 0.05, -WIDTHS[2] / 2 - 0.12), (x1, 4 * LH - 0.05, -WIDTHS[2] / 2 + 0.02), KNOB)
    z = -WIDTHS[2] / 2
    blk("GlowGem", (-0.2, 1.5 * LH, z - 0.1), (0.2, 3.5 * LH, z + 0.02), GLOW)
    blk("GlowGemX", (-0.26, 2.2 * LH, z - 0.12), (0.26, 2.8 * LH, z + 0.02), GLOW)
    blk("GlowGemHot", (-0.1, 2.15 * LH, z - 0.16), (0.1, 2.85 * LH, z - 0.08), CORE)

    # ---- tiny bone arms on the front, a glowing claw each
    for sx, side in ((-1, "L"), (1, "R")):
        a = WIDTHS[4] / 2
        xa = sx * (a - chamfer(WIDTHS[4]) * 0.5)
        x0, x1 = sorted((xa - sx * 0.08, xa + sx * 0.1))
        y = 4 * LH + 0.1
        blk("Humerus" + side, (x0, y - 0.25, -a - 0.05), (x1, y + 0.15, -a + 0.15), BONE)
        blk("Forearm" + side, (x0, y - 0.32, -a - 0.32), (x1, y - 0.17, -a - 0.05), BONE)
        blk("GlowArmClaw" + side, (x0 + 0.02, y - 0.4, -a - 0.42), (x1 - 0.02, y - 0.28, -a - 0.3), GLOW)

    # ---- spine down the back: a vertebra and a glowing-tipped spike per layer, then a
    # little bone tail off the base with a glowing tip
    for i in range(1, 6):
        a = WIDTHS[i] / 2
        y0, y1 = i * LH + 0.04, (i + 1) * LH - 0.04
        h = 0.18 + 0.04 * (3 - abs(i - 3))
        blk(f"Vert{i}", (-0.14, y0, a - 0.04), (0.14, y1, a + 0.14 + h), BONE)
        blk(f"GlowSpikeVert{i}", (-0.07, y0 + 0.1, a + 0.14 + h), (0.07, y1, a + 0.26 + h), GLOW)
    zb = WIDTHS[0] / 2
    blk("Tail0", (-0.15, 0.02, zb - 0.05), (0.15, 0.3, zb + 0.4), BONE)
    blk("Tail1", (-0.11, 0.02, zb + 0.4), (0.11, 0.22, zb + 0.75), BONE)
    blk("GlowTailTip", (-0.06, 0.06, zb + 0.75), (0.06, 0.18, zb + 0.95), GLOW)

    # ---- feet: a bone toe at each corner of the base, a glowing talon on its end
    a0 = WIDTHS[0] / 2
    for sx, sz, nm in ((-1, -1, "FL"), (1, -1, "FR"), (-1, 1, "BL"), (1, 1, "BR")):
        cx, cz = sx * (a0 - 0.05), sz * (a0 - 0.05)
        x0, x1 = sorted((cx, cx + sx * 0.3))
        z0, z1 = sorted((cz, cz + sz * 0.3))
        blk(f"Toe{nm}", (x0, 0, z0), (x1, 0.14, z1), BONE)
        x0, x1 = sorted((cx + sx * 0.3, cx + sx * 0.42))
        z0, z1 = sorted((cz + sz * 0.3, cz + sz * 0.42))
        blk(f"GlowTalon{nm}", (x0, 0, z0), (x1, 0.1, z1), GLOW)

    # ---- the skull crowning it, facing front: dark sockets with burning eyes and slit
    # pupils, a heavy brow and horns, fangs over the shell, a frill, soul fire streaming back
    top = H - 0.05
    S = 1.25

    def sk(name, lo, hi, color):
        """A skull block, a size up about the crown so the skull rules the egg."""
        pv = np.array([0.0, top, -0.3])
        lo = pv + (np.array(lo, float) - pv) * S
        hi = pv + (np.array(hi, float) - pv) * S
        return blk(name, tuple(lo), tuple(hi), color, "top")

    sk("Skull", (-0.5, top, -0.62), (0.5, top + 0.5, 0.28), BONE)
    sk("SkullBack", (-0.56, top + 0.04, 0.0), (0.56, top + 0.46, 0.34), KNOB)
    sk("Snout", (-0.38, top + 0.02, -1.12), (0.38, top + 0.4, -0.6), BONE)
    for sx, side in ((-1, "L"), (1, "R")):
        x0, x1 = sorted((sx * 0.44, sx * 0.52))
        sk("DarkSocket" + side, (x0, top + 0.14, -0.5), (x1, top + 0.42, -0.2), DARK)
        x0, x1 = sorted((sx * 0.48, sx * 0.53))
        sk("GlowEye" + side, (x0, top + 0.18, -0.46), (x1, top + 0.38, -0.24), GLOW)
        x0, x1 = sorted((sx * 0.53, sx * 0.55))
        sk("GlowPupil" + side, (x0, top + 0.21, -0.4), (x1, top + 0.35, -0.33), CORE)
        x0, x1 = sorted((sx * 0.3, sx * 0.56))
        sk("Brow" + side, (x0, top + 0.42, -0.58), (x1, top + 0.56, -0.18), KNOB)
        x0, x1 = sorted((sx * 0.38, sx * 0.5))
        sk("Horn" + side, (x0, top + 0.56, -0.44), (x1, top + 0.82, -0.32), BONE)
        # two long fangs down the side of the snout, over the shell's front
        for k, (zf, ln) in enumerate(((-0.98, 0.14), (-0.78, 0.2))):
            x0, x1 = sorted((sx * 0.28, sx * 0.36))
            sk(f"Fang{side}{k}", (x0, top + 0.02 - ln, zf - 0.04), (x1, top + 0.02, zf + 0.04), BONE)
        # soul fire streaming up and back out of each socket
        for j, (dy, dz, s) in enumerate(((0.56, -0.26, 0.12), (0.7, 0.0, 0.1), (0.82, 0.26, 0.075))):
            sk(f"GlowFlame{side}{j}", (sx * 0.48 - s, top + dy, dz - s), (sx * 0.48 + s, top + dy + 2 * s, dz + s), CORE if j == 0 else GLOW)
    # a frill of three spiked plates fanned behind the skull, glowing on their tips
    for k, (x, h) in enumerate(((-0.34, 0.36), (0.0, 0.48), (0.34, 0.36))):
        sk(f"Frill{k}", (x - 0.1, top + 0.2, 0.34), (x + 0.1, top + 0.2 + h, 0.5), BONE)
        sk(f"GlowFrill{k}", (x - 0.06, top + 0.2 + h, 0.36), (x + 0.06, top + 0.32 + h, 0.48), GLOW)
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
