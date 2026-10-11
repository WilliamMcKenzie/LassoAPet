"""Bone Rex (QM Oct 11): a skeletal T-Rex, the final Legendary and meant to be the most badass
model in the game. The T-Rex's skeleton on QM's T-Rex rig (designs/jurassic/TRex.bbmodel:
same bones, pivots and rest pose, so it runs on QM's T-Rex animations): an ivory skull with
dark windows and a jaw of big fangs, glowing green soul-fire eyes trailing flames, a green
glowing mouth, a row of spiked vertebrae down the neck, back and tail with glowing discs
between them, a ribcage with a glowing soul core inside, a pelvis, bone legs with black
talons and tiny bone arms.

Run: python3 tools/bone_rex.py [out_dir]
writes BoneRex.bbmodel (with the T-Rex's idle, walk and gallop), BoneRex.png (three views),
BoneRex_vs_trex.png and BoneRex_idle/walk/gallop.gif.

Built in Blockbench units (Conv k = 0.1). Glow* parts are Neon in game.
"""

import json
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import animal_designs as A  # noqa: E402
import convert_designs as C  # noqa: E402
from convert_designs import Conv, SIDES, X  # noqa: E402
from partlib import render  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
TREX = os.path.join(ROOT, "designs", "jurassic", "TRex.bbmodel")
OUT = "/mnt/project-files/animals/bonerex"

BONE = (240, 232, 208)
KNOB = (214, 202, 174)  # joint ends, a shade darker
DARK = (40, 34, 50)  # skull windows, inside the mouth
CLAW = (34, 30, 40)
GLOW = (60, 255, 110)  # soul fire
CORE = (220, 255, 200)  # the hottest part of it
PLAIN = ("Claw", "Talon", "Tooth", "Fang", "Spike", "Horn", "Dark")


def bone_rex():
    a = Conv("BoneRex", "Legendary", 0.1)
    a.pivots["root"] = (0, 8.0, 0)

    def spine(name, z0, z1, y0, y1, hw, blade, bone, chevron=0.0):
        """A vertebra: the centrum, a glowing disc behind it, a blade with a spike on top and,
        under the tail, a chevron."""
        a.b(name, (-hw, y0, z0), (hw, y1, z1), BONE, bone)
        a.b("Glow" + name + "Disc", (-hw * 0.7, y0 + 1, z1), (hw * 0.7, y1 - 1, z1 + 2), GLOW, bone)
        if blade:
            zc = (z0 + z1) / 2
            a.b(name + "Blade", (-1.5, y1, zc - 2.5), (1.5, y1 + blade, zc + 2.5), BONE, bone)
            a.pyr("Spike" + name, (-1.5, y1 + blade, zc - 2.5), (1.5, y1 + blade, zc + 2.5), "+y", 5 + blade * 0.3, CLAW, bone)
        if chevron:
            zc = (z0 + z1) / 2
            a.b(name + "Chevron", (-1.2, y0 - chevron, zc - 2), (1.2, y0, zc + 2), BONE, bone)

    # ---- back: vertebrae from the shoulders to the hips, tall spiked blades (lower over the
    # seat), ribs hanging off them round a glowing soul core, a belly of gastralia
    for i, z in enumerate(range(-36, 40, 10)):
        over_seat = -10 <= z <= 6
        spine(f"Back{i}", z, z + 8, 92, 102, 6, 4 if over_seat else 16 - abs(i - 3) * 1.5, "root")
    for k, z in enumerate((-31, -22, -13, -4, 5, 14, 23)):
        depth = 58 + k * 3.5  # deep in the chest, shallower toward the hips
        for side, sx in SIDES:
            x0, x1 = X(sx, 6, 21)
            a.b(f"Rib{k}{side}0", (x0, 93, z), (x1, 98, z + 4), BONE, "root")
            x0, x1 = X(sx, 19, 24)
            a.b(f"Rib{k}{side}1", (x0, depth + 12, z), (x1, 96, z + 4), BONE, "root")
            if k < 6:
                x0, x1 = X(sx, 15, 21)
                a.b(f"Rib{k}{side}2", (x0, depth + 4, z), (x1, depth + 13, z + 4), BONE, "root")
                x0, x1 = X(sx, 5, 16)
                a.b(f"Rib{k}{side}3", (x0, depth, z), (x1, depth + 5, z + 4), BONE, "root")
    a.b("Sternum", (-5, 56, -32), (5, 61, -6), KNOB, "root")
    for k, z in enumerate((-2, 6, 14)):
        a.b(f"Gastralia{k}", (-12, 66 + k * 3, z), (12, 69 + k * 3, z + 3), BONE, "root")
    # the soul core: a glowing gem floating in the chest, hottest in the middle
    a.b("GlowCore", (-8, 68, -22), (8, 86, -6), GLOW, "root")
    a.b("GlowCoreX", (-12, 73, -17), (12, 81, -11), GLOW, "root")
    a.b("GlowCoreY", (-4, 63, -18), (4, 91, -10), GLOW, "root")
    a.b("GlowCoreZ", (-4, 73, -27), (4, 81, -1), GLOW, "root")
    a.b("GlowCoreHot", (-5, 72, -19), (5, 82, -9), CORE, "root")
    # shoulder blades and the pelvis: ilium plates, the pubis reaching down to its boot, the ischium back
    for side, sx in SIDES:
        x0, x1 = X(sx, 19, 23)
        a.b("Scapula" + side, (x0, 72, -36), (x1, 100, -28), BONE, "root")
        x0, x1 = X(sx, 8, 13)
        a.b("Ilium" + side, (x0, 84, -2), (x1, 104, 32), BONE, "root")
        a.b("IliumTop" + side, (x0, 104, 4), (x1, 107, 26), KNOB, "root")
        for j, (y0, y1, z0, z1) in enumerate(((70, 86, 4, 12), (58, 72, 1, 9), (48, 60, -2, 6))):
            x0, x1 = X(sx, 6, 11)
            a.b(f"Pubis{side}{j}", (x0, y0, z0), (x1, y1, z1), BONE, "root")
        x0, x1 = X(sx, 3, 12)
        a.b("PubisBoot" + side, (x0, 44, -10), (x1, 50, 10), KNOB, "root")
        x0, x1 = X(sx, 6, 10)
        a.b("Ischium" + side, (x0, 64, 24), (x1, 86, 30), BONE, "root")

    # ---- tail: vertebrae shrinking back, spiked blades on top, chevrons under, glowing discs
    for i, z in enumerate(range(40, 86, 10)):
        spine(f"Tail1_{i}", z, z + 8, 82 - i, 92 - i, 6.5 - 0.4 * i, 13 - i * 1.2, "Tail", chevron=10 - i)
    for i, z in enumerate(range(86, 146, 10)):
        hw = 4.4 - 0.45 * i
        spine(f"Tail2_{i}", z, z + 8, 77 - i * 0.6, 85 - i * 1.0, hw, max(3, 7 - i), "Tail2", chevron=max(2, 6 - i))
    a.pyr("SpikeTailTip", (-1.8, 72, 146), (1.8, 78, 146), "+z", 12, CLAW, "Tail2")

    # ---- legs: a femur with knob ends, the tibia and fibula, an ankle, three long bone toes
    # in two joints each and huge black talons, and a back spur
    for side, sx in SIDES:
        leg = "Leg" + side
        x0, x1 = X(sx, 14, 24)
        a.b("Femur" + side, (x0, 50, 6), (x1, 80, 16), BONE, leg)
        x0, x1 = X(sx, 12, 26)
        a.b("Hip" + side, (x0, 76, 2), (x1, 88, 18), KNOB, leg)
        a.b("Knee" + side, (x0, 42, 4), (x1, 52, 20), KNOB, leg)
        x0, x1 = X(sx, 14.5, 22.5)
        a.b("Tibia" + side, (x0, 12, 9), (x1, 43, 17), BONE, leg)
        x0, x1 = X(sx, 22, 25)
        a.b("Fibula" + side, (x0, 14, 14), (x1, 42, 18), BONE, leg)
        x0, x1 = X(sx, 13, 25)
        a.b("Ankle" + side, (x0, 7, 6), (x1, 14, 20), KNOB, leg)
        for i, (xa, xb) in enumerate(((11, 15.5), (16.5, 21.5), (22.5, 27))):
            x0, x1 = X(sx, xa, xb)
            a.b(f"Toe{side}{i}a", (x0, 0, -4), (x1, 6, 12), BONE, leg)
            a.b(f"Toe{side}{i}j", (x0 - 0.5, 0, -7), (x1 + 0.5, 6.5, -4), KNOB, leg)
            a.b(f"Toe{side}{i}b", (x0, 0, -17), (x1, 5, -7), BONE, leg)
            a.pyr(f"Talon{side}{i}", (x0, 0, -17), (x1, 5, -17), "-z", 9, CLAW, leg)
        x0, x1 = X(sx, 17, 21)
        a.pyr("TalonSpur" + side, (x0, 2, 20), (x1, 6, 20), "+z", 6, CLAW, leg)

    # ---- tiny bone arms, two black claws each
    for side, sx in SIDES:
        arm = "Arm" + side
        x0, x1 = X(sx, 17, 24)
        a.b("ShoulderKnob" + side, (x0, 70, -36), (x1, 78, -26), KNOB, arm)
        x0, x1 = X(sx, 18, 23)
        a.b("Humerus" + side, (x0, 58, -34), (x1, 72, -29), BONE, arm)
        a.b("Forearm" + side, (x0, 56, -44), (x1, 61, -33), BONE, arm)
        for i, d in enumerate((-1.3, 1.3)):
            xc = sx * 20.5 + d
            a.pyr(f"Claw{side}{i}", (xc - 1.1, 56.5, -44), (xc + 1.1, 59.5, -44), "-z", 5, CLAW, arm)

    # ---- neck: vertebrae rising to the skull, spiked, glowing discs
    for i, (z, y) in enumerate(((-44, 90), (-52, 94), (-60, 98))):
        a.b(f"Neck{i}", (-6, y, z), (6, y + 10, z + 7), BONE, "neck")
        a.b(f"GlowNeck{i}Disc", (-4, y + 1, z + 7), (4, y + 9, z + 9), GLOW, "neck")
        a.b(f"Neck{i}Blade", (-1.5, y + 10, z + 1), (1.5, y + 18, z + 6), BONE, "neck")
        a.pyr(f"SpikeNeck{i}", (-1.5, y + 18, z + 1), (1.5, y + 18, z + 6), "+y", 7, CLAW, "neck")

    # ---- skull: a bone frame round dark windows (the big hole before the eye, the eye
    # socket, the hole behind it), a dark inside, a solid muzzle, a heavy brow with horns
    h = "neck"
    a.b("SkullRoof", (-18, 112, -118), (18, 121, -56), BONE, h)
    a.b("SkullMuzzle", (-18, 86, -118), (18, 112, -106), BONE, h)
    for side, sx in SIDES:
        x0, x1 = X(sx, 13, 19)
        a.b("Maxilla" + side, (x0, 86, -106), (x1, 95, -56), BONE, h)
        a.b("Pillar" + side, (x0, 95, -86), (x1, 112, -81), BONE, h)
        a.b("Postorbital" + side, (x0, 95, -68), (x1, 112, -63), BONE, h)
        x0, x1 = X(sx, 12, 21)
        a.b("Cheek" + side, (x0, 86, -63), (x1, 114, -52), BONE, h)
        x0, x1 = X(sx, 17, 19.2)
        a.b("DarkNostril" + side, (x0, 102, -117), (x1, 110, -109), DARK, h)
        # the brow: a heavy ridge over the eye and a horn off it
        x0, x1 = X(sx, 10, 21.5)
        a.b("Brow" + side, (x0, 108, -86), (x1, 124, -77), KNOB, h)  # low over the snout end: angry
        a.b("BrowBack" + side, (x0, 112, -77), (x1, 124, -64), KNOB, h)
        x0, x1 = X(sx, 13, 18)
        a.pyr("Horn" + side, (x0, 124, -80), (x1, 124, -72), "+y", 9, BONE, h)
        # big fangs down the upper jaw, outside the lower one
        for i, z in enumerate(np.arange(-112, -60, 7.5)):
            x0, x1 = X(sx, 14.5, 19)
            ln = 11 if i in (1, 2) else 8
            a.pyr(f"Fang{side}{i}", (x0, 86, z - 2.2), (x1, 86, z + 2.2), "-y", ln, BONE, h)
        # soul fire in the eye socket: a glowing eye with a hot pupil, flames streaming back
        # off the top of the skull
        x0, x1 = X(sx, 12, 19.6)
        a.b("GlowEye" + side, (x0, 96, -81), (x1, 112, -68), GLOW, h)
        x0, x1 = X(sx, 19.6, 20.4)
        a.b("GlowPupil" + side, (x0, 99, -77), (x1, 109, -73), CORE, h)
        # flames licking up out of the socket behind the brow and streaming back
        for j, (xa, xb, y0, y1, z0, z1) in enumerate(((13, 20, 121, 128, -77, -66), (13.5, 19.5, 125, 133, -71, -60),
                                                       (14, 19, 129, 138, -64, -53), (14.5, 18.5, 133, 141, -56, -46),
                                                       (15, 18, 136, 143, -48, -40))):
            x0, x1 = X(sx, xa, xb)
            a.b(f"GlowFlame{side}{j}", (x0, y0, z0), (x1, y1, z1), CORE if j < 2 else GLOW, h)
        for j, (y0, y1, z0, z1) in enumerate(((124, 130, -66, -60), (128, 134, -60, -54))):
            x0, x1 = X(sx, 19, 21.5)
            a.b(f"GlowLick{side}{j}", (x0, y0, z0), (x1, y1, z1), GLOW, h)
    for i, x in enumerate((-9, -3, 3, 9)):
        a.pyr(f"FangFront{i}", (x - 2.2, 86, -118), (x + 2.2, 86, -114), "-y", 7, BONE, h)
    # the dark inside, seen through the windows, and the roof of the mouth
    a.b("DarkSkull", (-13, 88, -106), (13, 112, -56), DARK, h)
    # a crest of three spikes down the middle of the skull
    for i, z in enumerate((-112, -100, -88)):
        a.pyr(f"SpikeSkull{i}", (-2, 121, z - 3), (2, 121, z + 3), "+y", 5 + i, BONE, h)
    # back of the head: a bony frill of spikes over the neck
    for i, (x, ln) in enumerate(((-14, 9), (-7, 12), (0, 14), (7, 12), (14, 9))):
        a.pyr(f"SpikeFrill{i}", (x - 2.5, 106, -52), (x + 2.5, 116, -52), "+z", ln, CLAW, h)

    # ---- lower jaw (opens at rest, as QM's T-Rex): bone rails with fangs pointing up,
    # a solid chin, and the glowing mouth between them (on Jaw2, which opens with it)
    for side, sx in SIDES:
        x0, x1 = X(sx, 9, 15)
        a.b("JawRail" + side, (x0, 74, -114), (x1, 85, -58), BONE, "Jaw")
        x0, x1 = X(sx, 8, 16)
        a.b("JawHinge" + side, (x0, 72, -64), (x1, 88, -54), KNOB, "Jaw")
        for i, z in enumerate(np.arange(-108, -64, 7.5)):
            x0, x1 = X(sx, 10, 14)
            a.pyr(f"Tooth{side}{i}", (x0, 85, z - 2), (x1, 85, z + 2), "+y", 8 if i else 10, BONE, "Jaw")
    a.b("Chin", (-15, 73, -118), (15, 85, -108), BONE, "Jaw")
    a.b("GlowMouth", (-9, 76, -108), (9, 81, -60), GLOW, "Jaw2")
    a.b("GlowThroat", (-8, 76, -62), (8, 90, -56), GLOW, "Jaw2")
    a.meta = {"seat": (0, 10.38, 0.6), "neck_loop": {"center": (0, 10.0, -5.0), "radius": 2.2}}  # studs
    return a


TAKES = {"ivory": None, "obsidian": {BONE: (66, 60, 76), KNOB: (46, 42, 56), CLAW: (60, 255, 110)}}


def rig(a):
    """The T-Rex's bones in its order, with its pivots and rest rotations."""
    t = json.load(open(TREX))
    G = {g["uuid"]: g for g in t["groups"]}

    def walk(nodes, parent):
        for n in nodes:
            if isinstance(n, dict):
                g = G[n["uuid"]]
                if g["name"] != "root":
                    a.bone(g["name"], parent, g["origin"], g.get("rotation", (0, 0, 0)))
                walk(n["children"], g["name"])

    walk(t["outliner"], "root")
    return t


def with_trex_animations(model, t):
    """Copy QM's T-Rex animations onto the new model's groups, matched by bone name."""
    ids = {g["name"]: g["uuid"] for g in model["groups"]}
    old = {g["uuid"]: g["name"] for g in t["groups"]}
    model["animations"] = []
    for an in t["animations"]:
        an = json.loads(json.dumps(an))
        an["animators"] = {ids[old[k]]: dict(v, name=old[k]) for k, v in an["animators"].items() if k in old and old[k] in ids}
        model["animations"].append(an)
    return model


def build():
    holder = {}

    def make():
        a = bone_rex()
        holder["t"] = rig(a)
        return a

    a, model, parts = C.build(make)
    model["meta"]["format_version"] = "5.0"
    return a, with_trex_animations(model, holder["t"]), parts


def mark(ps):
    for p in ps:
        if p.name.startswith(PLAIN):
            p.plain = True
        if p.name.startswith("Glow"):
            p.neon = True


def main(out=OUT):
    import horse_rig
    from snow_rig import posed
    horse_rig.EULER = "ZYX"  # QM's T-Rex animations
    os.makedirs(out, exist_ok=True)
    a, model, parts = build()
    path = os.path.join(out, "BoneRex.bbmodel")
    with open(path, "w") as f:
        json.dump(model, f, separators=(",", ":"))
    mark(parts)
    lo, hi = C.bounds(parts)
    c = (lo + hi) / 2
    r = np.linalg.norm(hi - lo) / 2
    T = 520
    sheet = Image.new("RGB", (T * 3, T))
    for i, v in enumerate(((-19, 8, -21), (-30, 3, 0), (19, 12, 21))):
        v = np.array(v, float)
        eye = c + v / np.linalg.norm(v) * r / np.tan(np.radians(17)) * 1.0
        sheet.paste(render(parts, eye=eye, target=c, W=T, H=T, fov=34), (i * T, 0))
    A.label(sheet, ["Bone Rex", "side", "back"], 22).save(os.path.join(out, "BoneRex.png"))
    # face close-up
    face = render(parts, eye=(-9, 12.5, -18), target=(0, 9.5, -8), W=T, H=T, fov=34)
    A.label(face, ["Bone Rex"], 22).save(os.path.join(out, "BoneRex_face.png"))
    # beside the T-Rex
    trex = json.load(open(TREX))
    rex = posed(trex, None, 0)
    for p in parts:
        p.polys = [q + np.array([-16.0, 0, 0]) for q in p.polys]
    cam = dict(eye=(-50, 18, -48), target=(-8, 6, 0), W=T * 2, H=T, fov=34)
    A.label(render(rex + parts, **cam), ["Bone Rex and T-Rex"], 22).save(os.path.join(out, "BoneRex_vs_trex.png"))
    # the other take: black bones, the spike tips burning too
    swap = TAKES["obsidian"]
    for p in parts:
        p.polys = [q - np.array([-16.0, 0, 0]) for q in p.polys]
    dark = []
    for p in parts:
        q = __import__("copy").copy(p)
        col = tuple(int(round(x * 255)) if max(p.color) <= 1 else int(x) for x in p.color)
        if col in swap:
            new = swap[col]
            q.color = tuple(x / 255 for x in new) if max(p.color) <= 1 else new
            if col == CLAW:
                q.neon = True
        dark.append(q)
    takes = Image.new("RGB", (T * 2, T))
    for i, ps in enumerate((parts, dark)):
        takes.paste(render(ps, eye=c + np.array([-19, 8, -21]) / np.linalg.norm([-19, 8, -21]) * r / np.tan(np.radians(17)), target=c, W=T, H=T, fov=34), (i * T, 0))
    A.label(takes, ["Ivory", "Obsidian"], 22).save(os.path.join(out, "BoneRex_takes.png"))
    print("wrote", path, len(parts), "parts")
    if os.environ.get("GIFS", "1") == "1":
        gifs(model, out)


def gifs(m, out=OUT):
    from snow_rig import posed
    T = 420
    cams = [dict(eye=(-30, 13, -32), target=(0, 7, 0), W=T, H=T, fov=40), dict(eye=(-38, 7, 2), target=(0, 7, 2), W=T, H=T, fov=40)]
    for anim in m["animations"]:
        L = anim["length"]
        nf = 32 if anim["name"] == "idle" else 16
        frames = []
        for i in range(nf):
            ps = posed(m, anim, L * i / nf)
            mark(ps)
            im = Image.new("RGB", (T * 2, T))
            for k, cam in enumerate(cams):
                im.paste(render(ps, **cam), (k * T, 0))
            frames.append(A.label(im, [anim["name"], ""], 22))
        A.gif(os.path.join(out, f"BoneRex_{anim['name']}.gif"), frames, fps=nf / L)


def obsidian(out=OUT):
    """BoneRex_obsidian.bbmodel: the other take, black bones with green spike tips and talons."""
    global BONE, KNOB, CLAW
    swap = TAKES["obsidian"]
    BONE, KNOB, CLAW = swap[BONE], swap[KNOB], swap[CLAW]
    a, model, parts = build()
    model["name"] = "BoneRex"
    with open(os.path.join(out, "BoneRex_obsidian.bbmodel"), "w") as f:
        json.dump(model, f, separators=(",", ":"))
    print("wrote BoneRex_obsidian.bbmodel", len(parts), "parts")


if __name__ == "__main__":
    if sys.argv[1:2] == ["obsidian"]:
        obsidian(*sys.argv[2:])
    else:
        main(*sys.argv[1:])
