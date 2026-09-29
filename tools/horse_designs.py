"""Five static horse design studies, built from blocks and wedges.

Run: python3 tools/horse_designs.py <out_dir>
Writes <out_dir>/HorseN_<Name>.rbxmx (drag into Studio or File > Insert From File)
and preview PNGs. Horses face -Z with hooves on Y = 0.
"""

import os
import sys

from partlib import Builder, T, Rx, Ry, Rz, render, write_rbxmx

COAT = (226, 130, 50)
MANE = (92, 54, 34)
MUZZLE = (247, 214, 170)
HOOF = (74, 78, 102)
EYE = (255, 255, 255)
PUPIL = (30, 30, 45)
EAR_IN = (242, 150, 192)
NOSE = (70, 44, 36)


def ear(b, name, frame, h, w, thick, color, inner=None):
    """A pointed ear: two wedges back to back, triangle facing forward."""
    b.wedge(name + "A", (thick, h, w / 2), frame @ T(-w / 4, h / 2, 0) @ Ry(90), color)
    b.wedge(name + "B", (thick, h, w / 2), frame @ T(w / 4, h / 2, 0) @ Ry(-90), color)
    if inner:
        ih, iw = h * 0.62, w * 0.55
        f = frame @ T(0, 0.08, -thick / 2 - 0.03)
        b.wedge(name + "InA", (0.06, ih, iw / 2), f @ T(-iw / 4, ih / 2, 0) @ Ry(90), inner, plain=True)
        b.wedge(name + "InB", (0.06, ih, iw / 2), f @ T(iw / 4, ih / 2, 0) @ Ry(-90), inner, plain=True)


def side_eye(b, frame, x, y, z, eh=0.85, ew=0.75, ph=0.5, pw=0.38):
    """Eye on the left side of the head (mirrored to the right), pupil toward the front."""
    b.box("Eye", (0.06, eh, ew), frame @ T(x - 0.03, y, z), EYE, plain=True, mirror=True)
    b.box("Pupil", (0.06, ph, pw), frame @ T(x - 0.07, y - 0.08, z - (ew - pw) / 2 + 0.04), PUPIL, plain=True, mirror=True)


def legs(b, xs, zf, zh, parts):
    """parts = list of (size, y_center) from the top down, shared by all four legs."""
    for tag, z in (("F", zf), ("H", zh)):
        for i, (size, y, color) in enumerate(parts):
            b.box(f"Leg{tag}{i}", size, T(-xs, y, z), color, mirror=True)


# ---------------------------------------------------------------- 1. Sculpted

def sculpted():
    b = Builder()
    # body: a box with wedge chamfers front and back so the barrel reads rounded
    b.box("Body", (3.4, 2.8, 4.4), T(0, 5, 0), COAT)
    b.box("Chest", (3.4, 1.4, 1.0), T(0, 5.7, -2.7), COAT)
    b.wedge("ChestLow", (3.4, 1.4, 1.0), T(0, 4.3, -2.7) @ Rz(180), COAT)
    b.wedge("RumpTop", (3.4, 1.4, 1.0), T(0, 5.7, 2.7) @ Ry(180), COAT)
    b.wedge("RumpLow", (3.4, 1.4, 1.0), T(0, 4.3, 2.7) @ Rx(180), COAT)

    N = T(0, 5.8, -2.5) @ Rx(-28)
    b.box("Neck", (1.9, 3.6, 1.9), N @ T(0, 1.6, 0), COAT)
    b.box("Mane", (0.7, 3.8, 0.6), N @ T(0, 1.8, 1.1), MANE)
    b.wedge("Throat", (1.9, 1.8, 0.8), N @ T(0, 0.9, -1.35), COAT)

    H = N @ T(0, 3.3, -0.1) @ Rx(28)
    b.box("Skull", (2.3, 2.1, 2.2), H @ T(0, 0, -0.3), COAT)
    b.box("Muzzle", (2.0, 1.4, 1.8), H @ T(0, -0.35, -2.2), MUZZLE)
    b.wedge("Bridge", (2.0, 0.7, 1.8), H @ T(0, 0.7, -2.2), COAT)
    b.box("Nostril", (0.32, 0.22, 0.06), H @ T(-0.5, -0.25, -3.12), NOSE, plain=True, mirror=True)
    b.wedge("Forelock", (1.0, 0.6, 0.9), H @ T(0, 1.35, -0.6), MANE)
    side_eye(b, H, -1.15, 0.25, -0.55)
    ear(b, "EarL", H @ T(-0.65, 1.05, 0.35) @ Rz(12), 1.1, 0.7, 0.35, COAT, EAR_IN)
    ear(b, "EarR", H @ T(0.65, 1.05, 0.35) @ Rz(-12), 1.1, 0.7, 0.35, COAT, EAR_IN)

    TF = T(0, 6.1, 3.0) @ Rx(-30)
    b.box("Tail", (1.0, 2.2, 1.0), TF @ T(0, -1.0, 0.1), MANE)
    b.wedge("TailTip", (1.0, 1.0, 1.0), TF @ T(0, -2.6, 0.1) @ Rz(180), MANE)

    legs(b, 1.0, -1.6, 1.7, [
        ((1.3, 2.0, 1.4), 3.0, COAT),
        ((1.05, 1.4, 1.05), 1.4, COAT),
        ((1.3, 0.7, 1.3), 0.35, HOOF),
    ])
    return b.parts


# ---------------------------------------------------------------- 2. Minimal

def minimal():
    b = Builder()
    b.box("Body", (3.4, 3.0, 5.6), T(0, 5.1, 0.2), COAT)

    N = T(0, 5.6, -2.2) @ Rx(-24)
    b.box("Neck", (2.1, 3.2, 2.2), N @ T(0, 1.4, 0), COAT)
    b.box("Mane", (0.6, 3.8, 0.6), N @ T(0, 1.8, 1.3), MANE)

    H = N @ T(0, 3.2, 0) @ Rx(24)
    b.box("Head", (2.4, 2.4, 2.4), H @ T(0, 0, -0.3), COAT)
    b.box("Muzzle", (2.1, 1.5, 1.5), H @ T(0, -0.45, -2.25), MUZZLE)
    side_eye(b, H, -1.2, 0.35, -0.6, eh=0.9, ew=0.9, ph=0.55, pw=0.45)
    b.box("Ear", (0.55, 0.9, 0.4), H @ T(-0.7, 1.65, 0.4), COAT, mirror=True)

    b.box("Tail", (0.9, 2.8, 0.9), T(0, 5.2, 3.3) @ Rx(-25), MANE)

    legs(b, 1.05, -1.8, 2.0, [
        ((1.2, 3.1, 1.2), 2.25, COAT),
        ((1.3, 0.7, 1.3), 0.35, HOOF),
    ])
    return b.parts


# ---------------------------------------------------------------- 3. Chibi

def chibi():
    b = Builder()
    b.box("Body", (3.2, 2.5, 3.8), T(0, 3.6, 0.4), COAT)
    b.wedge("RumpTop", (3.2, 1.0, 0.8), T(0, 4.35, 2.7) @ Ry(180), COAT)
    b.box("RumpLow", (3.2, 1.5, 0.8), T(0, 3.1, 2.7), COAT)

    b.box("Neck", (1.8, 1.6, 1.6), T(0, 5.2, -0.9), COAT)
    H = T(0, 7.2, -1.3)
    b.box("Head", (3.4, 3.0, 3.0), H, COAT)
    b.box("Muzzle", (2.8, 1.4, 1.2), H @ T(0, -0.8, -2.0), MUZZLE)
    b.wedge("MuzzleTop", (2.8, 0.5, 1.2), H @ T(0, 0.15, -2.0), COAT)
    b.box("Nostril", (0.35, 0.25, 0.06), H @ T(-0.6, -0.7, -2.63), NOSE, plain=True, mirror=True)
    # big forward-facing eyes on the face, above the muzzle
    b.box("Eye", (0.95, 1.15, 0.06), H @ T(-0.85, 0.55, -1.53), EYE, plain=True, mirror=True)
    b.box("Pupil", (0.5, 0.65, 0.06), H @ T(-0.8, 0.45, -1.57), PUPIL, plain=True, mirror=True)
    # forelock tuft: two wedges falling forward over the brow
    b.wedge("Tuft", (1.6, 0.9, 1.4), H @ T(0, 1.95, -0.5), MANE)
    b.box("Mane", (0.8, 2.4, 1.3), T(0, 6.0, -0.2), MANE)
    ear(b, "EarL", H @ T(-1.1, 1.5, 0.4) @ Rz(18), 1.3, 0.8, 0.4, COAT, EAR_IN)
    ear(b, "EarR", H @ T(1.1, 1.5, 0.4) @ Rz(-18), 1.3, 0.8, 0.4, COAT, EAR_IN)

    TF = T(0, 4.5, 3.1) @ Rx(-45)
    b.box("Tail", (1.2, 1.6, 1.2), TF @ T(0, -0.6, 0.2), MANE)
    b.wedge("TailTip", (1.2, 0.9, 1.2), TF @ T(0, -1.85, 0.2) @ Rz(180), MANE)

    legs(b, 0.95, -0.9, 1.9, [
        ((1.2, 1.8, 1.2), 1.9, COAT),
        ((1.35, 0.8, 1.35), 0.4, HOOF),
    ])
    return b.parts


# ---------------------------------------------------------------- 4. Arched

def arched():
    b = Builder()
    b.box("Body", (3.2, 2.7, 4.6), T(0, 5.6, 0), COAT)
    b.box("Chest", (3.2, 1.3, 1.0), T(0, 6.3, -2.8), COAT)
    b.wedge("ChestLow", (3.2, 1.4, 1.0), T(0, 4.95, -2.8) @ Rz(180), COAT)
    b.wedge("RumpTop", (3.2, 1.2, 1.1), T(0, 6.35, 2.85) @ Ry(180), COAT)
    b.box("RumpMid", (3.2, 0.6, 1.1), T(0, 5.45, 2.85), COAT)
    b.wedge("RumpLow", (3.2, 0.9, 1.1), T(0, 4.7, 2.85) @ Rx(180), COAT)

    N1 = T(0, 6.4, -2.7) @ Rx(-40)
    b.box("NeckLow", (1.9, 2.2, 2.0), N1 @ T(0, 1.0, 0), COAT)
    N2 = N1 @ T(0, 2.0, 0) @ Rx(28)
    b.box("NeckHigh", (1.7, 2.2, 1.8), N2 @ T(0, 1.0, 0), COAT)
    # mane as a row of wedge spikes flowing back along the neck
    for i, (f, y) in enumerate(((N1, 0.5), (N1, 1.6), (N2, 0.5), (N2, 1.6))):
        b.wedge(f"Mane{i}", (0.7, 1.1, 0.9), f @ T(0, y, 1.1) @ Rx(90) @ Ry(180), MANE)

    H = N2 @ T(0, 2.4, -0.1) @ Rx(-10)
    b.box("Skull", (2.1, 2.0, 2.0), H @ T(0, 0, -0.2), COAT)
    b.box("Jaw", (1.8, 1.2, 1.9), H @ T(0, -0.4, -2.1), MUZZLE)
    b.wedge("Bridge", (1.8, 0.8, 1.9), H @ T(0, 0.6, -2.1), COAT)
    b.box("Nostril", (0.3, 0.22, 0.06), H @ T(-0.45, -0.3, -3.07), NOSE, plain=True, mirror=True)
    side_eye(b, H, -1.05, 0.25, -0.45, eh=0.75, ew=0.7, ph=0.45, pw=0.34)
    ear(b, "EarL", H @ T(-0.6, 1.0, 0.3) @ Rz(10), 1.1, 0.65, 0.3, COAT, EAR_IN)
    ear(b, "EarR", H @ T(0.6, 1.0, 0.3) @ Rz(-10), 1.1, 0.65, 0.3, COAT, EAR_IN)

    # tail lifts out of the rump, then falls in a wedge sweep
    TF = T(0, 6.7, 3.2) @ Rx(-70)
    b.box("TailBase", (0.9, 1.4, 0.9), TF @ T(0, -0.6, 0), MANE)
    TF2 = TF @ T(0, -1.2, 0) @ Rx(55)
    b.box("Tail", (1.1, 2.0, 1.1), TF2 @ T(0, -1.0, 0), MANE)
    b.wedge("TailTip", (1.1, 1.2, 1.1), TF2 @ T(0, -2.6, 0) @ Rz(180), MANE)

    legs(b, 0.95, -1.75, 1.85, [
        ((1.2, 2.4, 1.3), 3.4, COAT),
        ((0.9, 2.0, 0.9), 1.6, COAT),
        ((1.15, 0.6, 1.15), 0.3, HOOF),
    ])
    return b.parts


# ---------------------------------------------------------------- 5. Toy (Jump for Animals style)

def toy():
    b = Builder()
    b.box("Body", (3.2, 3.0, 6.0), T(0, 5.0, 0.3), COAT)

    N = T(0, 5.4, -2.4) @ Rx(-42)
    b.box("Neck", (1.8, 3.4, 2.0), N @ T(0, 1.5, 0), COAT)

    H = N @ T(0, 3.2, 0) @ Rx(22)
    b.box("Head", (2.2, 2.2, 3.4), H @ T(0, 0, -0.9), COAT)
    b.box("Cap", (1.6, 0.6, 1.3), H @ T(0, 1.25, 0.1), MANE)  # mane block between the ears
    b.box("Nostril", (0.4, 0.3, 0.06), H @ T(-0.5, -0.45, -2.63), NOSE, plain=True, mirror=True)
    side_eye(b, H, -1.1, 0.3, -0.9, eh=0.95, ew=0.95, ph=0.6, pw=0.48)
    ear(b, "EarL", H @ T(-0.85, 1.1, 0.5) @ Rz(20), 1.2, 0.8, 0.35, COAT, EAR_IN)
    ear(b, "EarR", H @ T(0.85, 1.1, 0.5) @ Rz(-20), 1.2, 0.8, 0.35, COAT, EAR_IN)

    b.box("Tail", (0.8, 2.4, 0.8), T(0, 5.4, 3.6) @ Rx(-30), MANE)

    legs(b, 1.0, -2.0, 2.4, [
        ((1.1, 3.1, 1.1), 2.35, COAT),
        ((1.15, 0.8, 1.15), 0.4, HOOF),
    ])
    return b.parts


DESIGNS = [
    ("Sculpted", sculpted),
    ("Minimal", minimal),
    ("Chibi", chibi),
    ("Arched", arched),
    ("Toy", toy),
]


def framed(parts, direction, fov=30, size=520):
    """Render with the camera looking along -direction, sized to fit the model."""
    import numpy as np
    from partlib import part_faces
    pts = np.concatenate([poly for p in parts for poly, _ in part_faces(p)])
    lo, hi = pts.min(0), pts.max(0)
    lo[1] = 0
    center = (lo + hi) / 2
    radius = np.linalg.norm(hi - lo) / 2
    d = np.array(direction, float)
    d /= np.linalg.norm(d)
    dist = radius / np.sin(np.radians(fov / 2)) * 0.72
    return render(parts, center + d * dist, center, W=size, H=size, fov=fov)


def main(out):
    os.makedirs(out, exist_ok=True)
    from PIL import Image, ImageDraw, ImageFont
    tiles = []
    for i, (name, fn) in enumerate(DESIGNS, 1):
        parts = fn()
        write_rbxmx(parts, f"Horse{i}_{name}", os.path.join(out, f"Horse{i}_{name}.rbxmx"))
        a = framed(parts, (-1, 0.45, -0.95))
        s = framed(parts, (-1, 0.12, 0.0))
        f = framed(parts, (-0.18, 0.25, -1))
        a.save(os.path.join(out, f"Horse{i}_{name}.png"))
        tiles.append((f"{i}. {name}  ({len(parts)} parts)", [a, s, f]))
        print(name, len(parts), "parts")
    # contact sheet: one row per design (3/4, side, front)
    tw, lh = 520, 44
    sheet = Image.new("RGB", (tw * 3, (tw + lh) * len(tiles)), (255, 255, 255))
    d = ImageDraw.Draw(sheet)
    try:
        font = ImageFont.truetype("DejaVuSans-Bold.ttf", 28)
    except OSError:
        font = ImageFont.load_default()
    for r, (label, ims) in enumerate(tiles):
        y = r * (tw + lh)
        d.text((14, y + 8), label, fill=(20, 20, 20), font=font)
        for c, im in enumerate(ims):
            sheet.paste(im, (c * tw, y + lh))
    sheet.save(os.path.join(out, "sheet.png"))


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "designs/horses")
