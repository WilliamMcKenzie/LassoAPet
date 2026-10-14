# Regenerates Client/Preload's image lists (QM, Oct 13: "preload all the UI png assets").
# KEEP: every image id in the client's scripts (the HUD, menus, popups, buttons), kept
# loaded for good; REST: the headshots, the dictionary's sheets and Config's (egg art and
# the like), preloaded in the background. Sounds' ids are left out (Sounds preloads those).
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
later = {"PetFaces.luau", "AnimalDex.luau"}
keep_files = [f for f in client if os.path.basename(f) not in later | {"Sounds.luau", "Preload.client.luau"}]
rest_files = [f for f in client if os.path.basename(f) in later] + [os.path.join(src, "shared", "Config.luau")]
keep = [i for i in ids(keep_files) if i not in sounds]
rest = [i for i in ids(rest_files) if i not in sounds and i not in keep]

def block(name, items):
    rows = []
    for k in range(0, len(items), 3):
        rows.append("\t" + ", ".join('"%s"' % i for i in items[k:k + 3]) + ",")
    return "local %s = {\n%s\n}" % (name, "\n".join(rows))

s = open(path).read()
s = re.sub(r"local PANELS = \{.*?\n\}", lambda _: block("PANELS", keep), s, flags=re.S)
s = re.sub(r"local REST = \{.*?\n\}", lambda _: block("REST", rest), s, flags=re.S)
open(path, "w").write(s)
print(len(keep), "kept,", len(rest), "in the background")
