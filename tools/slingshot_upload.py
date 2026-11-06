"""Uploads the Slingshot's meshes (design/slingshot/pieces: the frame's Slingshot_<i> and
SlingshotBand_1) through the open Studio (as Fight to Steal an Egg's tools/studio/meshup.py:
an EditableMesh from each OBJ, AssetService:CreateAssetAsync), and writes their asset ids
and colours into Config.Slingshot (src/shared/Config.luau: Meshes, Band).

Run on the Mac with World 1's place open in Studio: python3 tools/slingshot_upload.py
Only uploads; it doesn't change the place.
"""

import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "mapeditor"))
from studio import run_luau  # noqa: E402

PIECES = os.path.join(HERE, "..", "design", "slingshot", "pieces")
CONFIG = os.path.join(HERE, "..", "src", "shared", "Config.luau")


def read_obj(path):
    v, vt, vn, f = [], [], [], []
    for line in open(path):
        p = line.split()
        if not p:
            continue
        if p[0] == "v":
            v.append([round(float(x), 4) for x in p[1:4]])
        elif p[0] == "vt":
            vt.append([round(float(x), 4) for x in p[1:3]])
        elif p[0] == "vn":
            vn.append([round(float(x), 4) for x in p[1:4]])
        elif p[0] == "f":
            f.append([[int(i) if i else 0 for i in c.split("/")] for c in p[1:]])
    return {"v": v, "vt": vt, "vn": vn, "f": f}


UPLOAD = '''
local AS = game:GetService("AssetService")
local d = game:GetService("HttpService"):JSONDecode(%s)
local m = AS:CreateEditableMesh()
local V, T, N = {}, {}, {}
for i, p in d.v do V[i] = m:AddVertex(Vector3.new(p[1], p[2], p[3])) end
for i, p in d.vt do T[i] = m:AddUV(Vector2.new(p[1], 1 - p[2])) end
for i, p in d.vn do N[i] = m:AddNormal(Vector3.new(p[1], p[2], p[3])) end
for _, face in d.f do
	for k = 2, #face - 1 do
		local a, b, c = face[1], face[k], face[k + 1]
		local t = m:AddTriangle(V[a[1]], V[b[1]], V[c[1]])
		if a[2] ~= 0 then m:SetFaceUVs(t, { T[a[2]], T[b[2]], T[c[2]] }) end
		if a[3] ~= 0 then m:SetFaceNormals(t, { N[a[3]], N[b[3]], N[c[3]] }) end
	end
end
local ok, res, id = pcall(function() return AS:CreateAssetAsync(m, Enum.AssetType.Mesh, { Name = "%s" }) end)
return tostring(ok) .. " " .. tostring(res) .. " " .. tostring(id)
'''


def upload(name):
    data = json.dumps(read_obj(os.path.join(PIECES, name + ".obj")))
    out = run_luau(UPLOAD % (json.dumps(data), name), "Edit").strip()
    m = re.search(r"true Success (\d+)", out)
    if not m:
        raise SystemExit("%s didn't upload: %s" % (name, out[:400]))
    print(name, m.group(1))
    return m.group(1)


def main():
    colours = {}
    for line in open(os.path.join(PIECES, "colours.txt")):
        if line.startswith("#") or ":" not in line:
            continue
        name, rest = line.split(":", 1)
        rgb = [int(x) for x in rest.split(",")[1:4]]
        colours[name.strip()] = rgb
    frame = sorted((n for n in colours if n.startswith("Slingshot_")), key=lambda n: int(n.split("_")[1]))
    meshes = []
    for name in frame:
        meshes.append("{ %s, %d, %d, %d }" % ((upload(name),) + tuple(colours[name])))
    band = upload("SlingshotBand_1")
    src = open(CONFIG).read()
    src, n1 = re.subn(r"\tMeshes = \{[^\n]*\}, -- \(filled by tools/slingshot_upload\.py\)",
                      "\tMeshes = { " + ", ".join(meshes) + " }, -- (filled by tools/slingshot_upload.py)", src)
    src, n2 = re.subn(r"\tBand = [^\n]*,\n", "\tBand = %s, -- (filled by tools/slingshot_upload.py)\n" % band, src, count=1)
    if n1 != 1 or n2 != 1:
        raise SystemExit("couldn't find Config.Slingshot's Meshes / Band lines")
    open(CONFIG, "w").write(src)
    print("Config.Slingshot updated")


if __name__ == "__main__":
    main()
