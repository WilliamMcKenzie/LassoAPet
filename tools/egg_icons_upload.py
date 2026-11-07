"""Uploads the egg pictures tools/egg_icons.py rendered (assets/ui/<Kind>EggRender.png, its MISSING
list) through the open Studio (tools/studio/imgup.py) and writes their ids into Config.EggIcons
(src/shared/Config.luau). Skips any kind already in Config.EggIcons, so it can be rerun.

Run on the Mac with World 1's place open in Studio: python3 tools/egg_icons_upload.py
Only uploads; it doesn't change the place.
"""

import json
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
CONFIG = os.path.join(HERE, "..", "src", "shared", "Config.luau")
UI = os.path.join(HERE, "..", "assets", "ui")
IDS = os.path.join(HERE, "studio", "egg_icon_ids.json")


def missing():
    src = open(os.path.join(HERE, "egg_icons.py")).read()
    block = src[src.index("MISSING = ["):src.index("] + list(ALPHAS)")]
    kinds = re.findall(r'"(\w+)"', block)
    alphas = src[src.index("ALPHAS = {"):src.index("\n}\n", src.index("ALPHAS = {"))]
    kinds += re.findall(r'^    "(\w+)": \(', alphas, re.M)
    return kinds


def main():
    cfg = open(CONFIG).read()
    start = cfg.index("\tEggIcons = {")
    end = cfg.index("\n\t},", start)
    have = set(re.findall(r'^\t\t(\w+) = "rbxassetid', cfg[start:end], re.M))
    todo = [k for k in missing() if k not in have]
    files = [os.path.join(UI, k + "EggRender.png") for k in todo]
    if files:
        env = dict(os.environ, OUT=IDS)
        subprocess.run(["python3", os.path.join(HERE, "studio", "imgup.py")] + files, env=env, check=True)
    ids = json.load(open(IDS)) if os.path.exists(IDS) else {}
    lines = []
    for k in todo:
        i = ids.get(k + "EggRender")
        if i:
            lines.append(f'\t\t{k} = "{i}", -- assets/ui/{k}EggRender.png (tools/egg_icons.py)')
        else:
            print("not uploaded:", k)
    if lines:
        cfg = cfg[:end] + "\n" + "\n".join(lines) + cfg[end:]
        open(CONFIG, "w").write(cfg)
    print(len(lines), "egg pictures added to Config.EggIcons")


if __name__ == "__main__":
    main()
