"""Pets-panel headshots for the snow pets (assets/ui/Pet<Kind>.png): a close
3/4 front view of each head on a clear background, like the earlier ones.
Run from the repo root: python3 tools/snow_headshots.py assets/ui"""

import sys, os, json
sys.path.insert(0, "tools")
import numpy as np
import snow_designs as SD
from partlib import render
HEAD_KEYS = ("head", "eye", "snout", "muzzle", "face", "nose", "beak", "jaw", "forehead", "hat")
out = sys.argv[1]
for fn in (SD.snowman, SD.penguin, SD.polar_bear, SD.ice_wyvern):
    a, model, parts = SD.build(fn)
    if a.name in SD.QM_FILES:
        model = json.load(open(os.path.join(SD.MODELS, a.name + ".bbmodel")))
        parts = SD.posed(model)
    for p in parts:
        if p.name.startswith(SD.PLAIN):
            p.plain = True
    head = [p for p in parts if any(k in p.name.lower() for k in HEAD_KEYS)]
    lo, hi = SD.bounds(head)
    c = (lo + hi) / 2
    size = np.linalg.norm(hi - lo)
    target = c - np.array([0, size * 0.18, 0])
    eye = target + SD.Q34_DIR * size * 3.1
    im = render(parts, eye=eye, target=target, W=512, H=512, fov=30, transparent=True)
    path = os.path.join(out, f"Pet{a.name}.png")
    im.save(path)
    print("wrote", path)
