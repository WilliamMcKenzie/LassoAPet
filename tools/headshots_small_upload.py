"""Uploads every pet headshot (assets/ui/Pet<Kind>.png, 512 px) again at 128 x 128 for the Index
(QM, Nov 8: memory; a 512 px headshot is ~1.3 MB of texture, a 128 px one ~85 KB) through the open
Studio (tools/studio/imgup.py), and writes { Kind = "rbxassetid://..." } to OUT (default
tools/studio/headshot_small_ids.json). Skips kinds already in OUT, so it can be rerun.

Run on the Mac with World 1's place open in Studio: python3 tools/headshots_small_upload.py
Only uploads; it doesn't change the place or any source file.
"""

import json
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
FACES = os.path.join(HERE, "..", "src", "client", "PetFaces.luau")
UI = os.path.join(HERE, "..", "assets", "ui")
OUT = os.environ.get("OUT", os.path.join(HERE, "studio", "headshot_small_ids.json"))
RAW = os.path.join(HERE, "studio", "_headshot_small_raw.json")


def main():
    src = open(FACES).read()
    block = src[src.index("local HEADSHOTS = {"):src.index("\n}\n", src.index("local HEADSHOTS = {"))]
    kinds = re.findall(r'^\t(\w+) = "rbxassetid://\d+"', block, re.M)
    done = json.load(open(OUT)) if os.path.exists(OUT) else {}
    todo = [k for k in kinds if k not in done and os.path.exists(os.path.join(UI, "Pet" + k + ".png"))]
    print(len(kinds), "headshots,", len(todo), "to upload")
    for i in range(0, len(todo), 10):  # (in batches, saved as it goes)
        batch = todo[i:i + 10]
        files = [os.path.join(UI, "Pet" + k + ".png") + ":128x128" for k in batch]
        subprocess.run(["python3", os.path.join(HERE, "studio", "imgup.py")] + files, env=dict(os.environ, OUT=RAW), check=True)
        raw = json.load(open(RAW)) if os.path.exists(RAW) else {}
        for k in batch:
            v = raw.get("Pet" + k)
            if v:
                done[k] = v if str(v).startswith("rbxassetid://") else "rbxassetid://" + str(v)
        json.dump(done, open(OUT, "w"), indent=1, sort_keys=True)
        print(len(done), "uploaded so far")


if __name__ == "__main__":
    main()
