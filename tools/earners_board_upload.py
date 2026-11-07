"""Uploads the Top Earners board's meshes (design/earners_board/pieces) through the open
Studio (as tools/slingshot_upload.py: an EditableMesh from each OBJ,
AssetService:CreateAssetAsync, run through tools/studio/lu.py), and writes their asset ids,
colours and centres into Config.TopEarners.Meshes (src/shared/Config.luau).

Run on the Mac with World 1's place open in Studio: python3 tools/earners_board_upload.py
Only uploads; it doesn't change the place.
"""

import json
import os
import re
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
PIECES = os.path.join(HERE, "..", "design", "earners_board", "pieces")
CONFIG = os.path.join(HERE, "..", "src", "shared", "Config.luau")
LU = os.path.join(HERE, "studio", "lu.py")


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


def run_luau(code):
    with tempfile.NamedTemporaryFile("w", suffix=".luau", delete=False) as f:
        f.write(code)
    try:
        return subprocess.run([sys.executable, LU, f.name, "Edit"], capture_output=True, text=True).stdout
    finally:
        os.remove(f.name)


def upload(name):
    data = json.dumps(read_obj(os.path.join(PIECES, name + ".obj")))
    out = run_luau(UPLOAD % (json.dumps(data), name)).strip()
    m = re.search(r"true (?:Enum\.CreateAssetResult\.)?Success (\d+)", out)
    if not m:
        raise SystemExit("%s didn't upload: %s" % (name, out[:400]))
    print(name, m.group(1))
    return m.group(1)


def main():
    pieces = []
    for line in open(os.path.join(PIECES, "colours.txt")):
        if line.startswith("#") or ":" not in line:
            continue
        name, rest = line.split(":", 1)
        nums = [x.strip() for x in rest.split(",")[1:]]
        pieces.append((name.strip(), [int(x) for x in nums[:3]], [float(x) for x in nums[3:6]]))
    meshes = []
    for name, rgb, centre in pieces:
        meshes.append("{ %s, %d, %d, %d, %s, %s, %s }" % ((upload(name),) + tuple(rgb) + tuple("%.3f" % c for c in centre)))
    src = open(CONFIG).read()
    src, n = re.subn(r"\tMeshes = \{[^\n]*\}, -- \(filled by tools/earners_board_upload\.py\)",
                     lambda _: "\tMeshes = { " + ", ".join(meshes) + " }, -- (filled by tools/earners_board_upload.py)", src)
    if n != 1:
        raise SystemExit("couldn't find Config.TopEarners' Meshes line")
    open(CONFIG, "w").write(src)
    print("Config.TopEarners updated")


if __name__ == "__main__":
    main()
