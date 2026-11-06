# Regenerates Client/Preload's image list: every image id in the client's scripts (the HUD,
# menus, popups, buttons) that can actually show, kept loaded for good. Left out (QM, Nov 6:
# no dead preloads): Sounds' ids (Sounds preloads those), UiArt's own tables, any id UiArt blanks
# to a placeholder (in its NAMES but not its KEEP), and the headshots, the dictionary's sheets
# and Config's egg art, which load when their screen opens.
#   python3 tools/preload_ids.py
import glob, os, re

ID = re.compile(r"rbxassetid://\d+")
here = os.path.dirname(os.path.abspath(__file__))
src = os.path.join(here, "..", "src")
path = os.path.join(src, "client", "Preload.client.luau")

def ids(files):
    out = []
    for f in files:
        for line in open(f):
            if "Sound" in line:
                continue
            for m in ID.findall(line):
                if m not in out:
                    out.append(m)
    return out

client = sorted(glob.glob(os.path.join(src, "client", "*.luau")))
sounds = set(ID.findall(open(os.path.join(src, "client", "Sounds.luau")).read()))
skip = {"PetFaces.luau", "AnimalDex.luau", "Sounds.luau", "Preload.client.luau", "UiArt.client.luau"}
uiart = open(os.path.join(src, "client", "UiArt.client.luau")).read()
names = uiart[uiart.index("local NAMES = {"):]
names = set(re.findall(r'\["(\d+)"\]', names[: names.index("\n}")]))
keeps = uiart[uiart.index("local KEEP = {"):]
keeps = set(re.findall(r'\["(\d+)"\]', keeps[: keeps.index("\n}")]))
blanked = {"rbxassetid://" + i for i in names - keeps}
config_off = os.path.join(src, "shared", "Config.luau")
uiart_on = re.search(r"\n\tUiArt = true", open(config_off).read()) is not None
keep_files = [f for f in client if os.path.basename(f) not in skip]
keep = [i for i in ids(keep_files) if i not in sounds and (uiart_on or i not in blanked)]

def block(name, items):
    rows = []
    for k in range(0, len(items), 3):
        rows.append("\t" + ", ".join('"%s"' % i for i in items[k:k + 3]) + ",")
    return "local %s = {\n%s\n}" % (name, "\n".join(rows))

s = open(path).read()
s = re.sub(r"local PANELS = \{.*?\n\}", lambda _: block("PANELS", keep), s, flags=re.S)
open(path, "w").write(s)
print(len(keep), "kept")
