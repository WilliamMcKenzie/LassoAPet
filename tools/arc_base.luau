-- The arc home base (QM, Oct 9; design/base_arc/SPEC.md). Made by tools/arc_base.py
-- from design/base_arc/arc_layout.json: edit those and re-make it, not this.
-- Run in Studio's command bar (Edit, not Play) on the place. Re-running is fine.

local W, D = 176, 264
local YARD = Vector3.new(0, 0, 90)
local world = workspace.World

-- The walls and caps: { name, which, centre, size }.
local WALLS = {
	{ "Wall", "back", Vector3.new(0, 24, 268), Vector3.new(368, 48, 8) },
	{ "Cap", "back", Vector3.new(0, 49, 267), Vector3.new(368, 2, 10) },
	{ "Wall", "left", Vector3.new(-180, 24, 128), Vector3.new(8, 48, 272) },
	{ "Cap", "left", Vector3.new(-179, 49, 132), Vector3.new(10, 2, 260) },
	{ "Wall", "right", Vector3.new(180, 24, 128), Vector3.new(8, 48, 272) },
	{ "Cap", "right", Vector3.new(179, 49, 132), Vector3.new(10, 2, 260) },
	{ "Wall", "frontleft", Vector3.new(-116, 24, -4), Vector3.new(120, 48, 8) },
	{ "Cap", "frontleft", Vector3.new(-119, 49, -3), Vector3.new(130, 2, 10) },
	{ "Wall", "frontright", Vector3.new(116, 24, -4), Vector3.new(120, 48, 8) },
	{ "Cap", "frontright", Vector3.new(119, 49, -3), Vector3.new(130, 2, 10) },
}
-- The floor: { dirt (1) or grass (0), low x, low z, size x, size z }, 4-stud tiles.
local FLOOR = {
	{ 0, -176, 0, 4, 272 },
	{ 1, -172, 0, 16, 4 },
	{ 0, -156, 0, 16, 108 },
	{ 1, -140, 0, 4, 4 },
	{ 0, -136, 0, 24, 12 },
	{ 1, -112, 0, 12, 4 },
	{ 0, -100, 0, 32, 12 },
	{ 1, -68, 0, 8, 4 },
	{ 0, -60, 0, 40, 4 },
	{ 1, -20, 0, 12, 92 },
	{ 0, -8, 0, 56, 4 },
	{ 1, 48, 0, 8, 4 },
	{ 0, 56, 0, 72, 8 },
	{ 1, 128, 0, 16, 4 },
	{ 0, 144, 0, 32, 24 },
	{ 0, -172, 4, 4, 52 },
	{ 1, -168, 4, 4, 4 },
	{ 0, -164, 4, 8, 20 },
	{ 0, -140, 4, 4, 20 },
	{ 0, -112, 4, 8, 8 },
	{ 1, -104, 4, 4, 28 },
	{ 0, -68, 4, 40, 4 },
	{ 1, -28, 4, 8, 152 },
	{ 1, -8, 4, 4, 88 },
	{ 0, -4, 4, 60, 4 },
	{ 0, 128, 4, 16, 16 },
	{ 0, -168, 8, 4, 52 },
	{ 0, -68, 8, 28, 8 },
	{ 1, -40, 8, 12, 148 },
	{ 1, -4, 8, 24, 20 },
	{ 0, 20, 8, 92, 4 },
	{ 1, 112, 8, 4, 24 },
	{ 0, 116, 8, 12, 4 },
	{ 0, -136, 12, 8, 4 },
	{ 1, -128, 12, 8, 12 },
	{ 0, -120, 12, 12, 8 },
	{ 1, -108, 12, 4, 16 },
	{ 1, -100, 12, 4, 16 },
	{ 0, -96, 12, 28, 4 },
	{ 0, 20, 12, 88, 12 },
	{ 1, 108, 12, 4, 20 },
	{ 1, 116, 12, 4, 20 },
	{ 0, 120, 12, 8, 4 },
	{ 0, -136, 16, 4, 8 },
	{ 1, -132, 16, 4, 12 },
	{ 1, -96, 16, 4, 8 },
	{ 0, -92, 16, 48, 4 },
	{ 1, -44, 16, 4, 148 },
	{ 1, 120, 16, 4, 16 },
	{ 0, 124, 16, 4, 4 },
	{ 1, -120, 20, 12, 8 },
	{ 0, -92, 20, 44, 8 },
	{ 1, -48, 20, 4, 76 },
	{ 1, 124, 20, 8, 8 },
	{ 0, 132, 20, 12, 196 },
	{ 1, -164, 24, 4, 4 },
	{ 0, -160, 24, 4, 192 },
	{ 1, -140, 24, 8, 4 },
	{ 0, -128, 24, 4, 4 },
	{ 1, -124, 24, 4, 8 },
	{ 0, -96, 24, 4, 40 },
	{ 1, 20, 24, 16, 8 },
	{ 0, 36, 24, 64, 4 },
	{ 1, 100, 24, 8, 8 },
	{ 0, 144, 24, 16, 76 },
	{ 1, 160, 24, 4, 8 },
	{ 0, 164, 24, 12, 44 },
	{ 0, -164, 28, 4, 80 },
	{ 0, -140, 28, 12, 76 },
	{ 1, -128, 28, 4, 4 },
	{ 1, -120, 28, 8, 4 },
	{ 0, -112, 28, 8, 80 },
	{ 0, -100, 28, 4, 80 },
	{ 0, -92, 28, 40, 8 },
	{ 1, -52, 28, 4, 60 },
	{ 1, -4, 28, 8, 64 },
	{ 0, 4, 28, 12, 4 },
	{ 1, 16, 28, 4, 4 },
	{ 1, 36, 28, 4, 136 },
	{ 0, 40, 28, 60, 4 },
	{ 1, 124, 28, 4, 4 },
	{ 0, 128, 28, 4, 192 },
	{ 0, -128, 32, 16, 84 },
	{ 0, -104, 32, 4, 76 },
	{ 1, 4, 32, 8, 60 },
	{ 0, 12, 32, 16, 4 },
	{ 1, 28, 32, 8, 132 },
	{ 0, 40, 32, 56, 4 },
	{ 1, 96, 32, 8, 4 },
	{ 0, 104, 32, 24, 84 },
	{ 0, 160, 32, 4, 76 },
	{ 0, -92, 36, 36, 4 },
	{ 1, -56, 36, 4, 48 },
	{ 1, 12, 36, 16, 132 },
	{ 1, 40, 36, 4, 132 },
	{ 0, 44, 36, 60, 8 },
	{ 0, -92, 40, 32, 4 },
	{ 1, -60, 40, 4, 48 },
	{ 0, -92, 44, 28, 4 },
	{ 1, -64, 44, 4, 108 },
	{ 1, 44, 44, 4, 124 },
	{ 0, 48, 44, 56, 4 },
	{ 0, -92, 48, 20, 4 },
	{ 1, -72, 48, 8, 84 },
	{ 1, 48, 48, 8, 116 },
	{ 0, 56, 48, 32, 4 },
	{ 1, 88, 48, 4, 4 },
	{ 0, 92, 48, 12, 16 },
	{ 0, -92, 52, 16, 4 },
	{ 1, -76, 52, 4, 72 },
	{ 1, 56, 52, 8, 104 },
	{ 0, 64, 52, 28, 4 },
	{ 1, -172, 56, 4, 8 },
	{ 0, -92, 56, 12, 4 },
	{ 1, -80, 56, 4, 60 },
	{ 1, 64, 56, 8, 100 },
	{ 0, 72, 56, 20, 8 },
	{ 1, -168, 60, 4, 4 },
	{ 0, -92, 60, 8, 4 },
	{ 1, -84, 60, 4, 48 },
	{ 0, -172, 64, 8, 40 },
	{ 1, -96, 64, 12, 36 },
	{ 1, 72, 64, 4, 88 },
	{ 0, 76, 64, 8, 4 },
	{ 1, 84, 64, 12, 20 },
	{ 0, 96, 64, 8, 164 },
	{ 0, 76, 68, 4, 4 },
	{ 1, 80, 68, 4, 60 },
	{ 0, 164, 68, 4, 40 },
	{ 1, 168, 68, 4, 8 },
	{ 0, 172, 68, 4, 204 },
	{ 1, 76, 72, 4, 64 },
	{ 0, 168, 76, 4, 196 },
	{ 0, -56, 84, 4, 20 },
	{ 0, 84, 84, 12, 140 },
	{ 0, -60, 88, 4, 16 },
	{ 0, -52, 88, 4, 16 },
	{ 1, -20, 92, 8, 4 },
	{ 0, -12, 92, 20, 12 },
	{ 1, 8, 92, 4, 4 },
	{ 0, -48, 96, 4, 4 },
	{ 1, -20, 96, 4, 68 },
	{ 0, -16, 96, 4, 4 },
	{ 0, 8, 96, 4, 4 },
	{ 0, -96, 100, 4, 124 },
	{ 1, -92, 100, 8, 4 },
	{ 1, -48, 100, 4, 64 },
	{ 1, -16, 100, 4, 64 },
	{ 1, 8, 100, 4, 72 },
	{ 0, 144, 100, 4, 4 },
	{ 1, 148, 100, 4, 16 },
	{ 0, 152, 100, 8, 4 },
	{ 0, -172, 104, 4, 168 },
	{ 1, -168, 104, 4, 8 },
	{ 1, -140, 104, 8, 8 },
	{ 0, -132, 104, 4, 168 },
	{ 0, -92, 104, 8, 24 },
	{ 1, -60, 104, 12, 48 },
	{ 1, -12, 104, 20, 64 },
	{ 1, 144, 104, 4, 8 },
	{ 1, 152, 104, 4, 8 },
	{ 0, 156, 104, 4, 4 },
	{ 1, -164, 108, 4, 4 },
	{ 0, -156, 108, 12, 32 },
	{ 1, -144, 108, 4, 4 },
	{ 0, -112, 108, 4, 164 },
	{ 1, -108, 108, 12, 4 },
	{ 0, -84, 108, 4, 124 },
	{ 1, 156, 108, 12, 4 },
	{ 0, -168, 112, 8, 100 },
	{ 0, -144, 112, 12, 68 },
	{ 0, -108, 112, 4, 160 },
	{ 1, -104, 112, 4, 4 },
	{ 0, -100, 112, 4, 160 },
	{ 0, 144, 112, 4, 20 },
	{ 0, 152, 112, 16, 20 },
	{ 1, -128, 116, 8, 8 },
	{ 0, -120, 116, 8, 156 },
	{ 0, -104, 116, 4, 124 },
	{ 0, -80, 116, 4, 28 },
	{ 0, 104, 116, 16, 4 },
	{ 1, 120, 116, 4, 8 },
	{ 0, 124, 116, 4, 4 },
	{ 0, 148, 116, 4, 16 },
	{ 1, 104, 120, 16, 4 },
	{ 1, 124, 120, 4, 8 },
	{ 0, -128, 124, 8, 148 },
	{ 0, -76, 124, 4, 16 },
	{ 0, 104, 124, 20, 96 },
	{ 1, -92, 128, 4, 4 },
	{ 0, -88, 128, 4, 104 },
	{ 0, 80, 128, 4, 144 },
	{ 0, 124, 128, 4, 84 },
	{ 0, -92, 132, 4, 88 },
	{ 0, -72, 132, 4, 4 },
	{ 1, -68, 132, 4, 24 },
	{ 1, 144, 132, 20, 4 },
	{ 0, 164, 132, 4, 8 },
	{ 1, -72, 136, 4, 20 },
	{ 0, 76, 136, 4, 8 },
	{ 0, 144, 136, 4, 8 },
	{ 1, 148, 136, 16, 12 },
	{ 0, -156, 140, 4, 4 },
	{ 1, -152, 140, 8, 16 },
	{ 1, -76, 140, 4, 12 },
	{ 1, 164, 140, 4, 4 },
	{ 1, -156, 144, 4, 8 },
	{ 1, -80, 144, 4, 4 },
	{ 1, 76, 144, 4, 4 },
	{ 1, 144, 144, 4, 8 },
	{ 0, 164, 144, 4, 48 },
	{ 0, -80, 148, 4, 80 },
	{ 0, 76, 148, 4, 124 },
	{ 1, 148, 148, 12, 4 },
	{ 0, 160, 148, 4, 44 },
	{ 0, -156, 152, 4, 120 },
	{ 0, -76, 152, 4, 76 },
	{ 0, -64, 152, 12, 120 },
	{ 1, -52, 152, 4, 8 },
	{ 0, 72, 152, 4, 120 },
	{ 0, 144, 152, 4, 76 },
	{ 1, 148, 152, 4, 8 },
	{ 0, 152, 152, 8, 48 },
	{ 0, -152, 156, 8, 28 },
	{ 0, -72, 156, 8, 72 },
	{ 1, -40, 156, 4, 4 },
	{ 0, -36, 156, 12, 100 },
	{ 1, -24, 156, 4, 4 },
	{ 1, 56, 156, 4, 4 },
	{ 0, 60, 156, 12, 48 },
	{ 0, -52, 160, 4, 112 },
	{ 0, -40, 160, 4, 64 },
	{ 0, -24, 160, 4, 96 },
	{ 0, 56, 160, 4, 8 },
	{ 0, 148, 160, 4, 44 },
	{ 0, -48, 164, 8, 60 },
	{ 0, -20, 164, 8, 108 },
	{ 1, 28, 164, 4, 4 },
	{ 0, 32, 164, 8, 28 },
	{ 1, 48, 164, 4, 4 },
	{ 0, 52, 164, 4, 8 },
	{ 0, -12, 168, 12, 4 },
	{ 1, 0, 168, 8, 20 },
	{ 0, 12, 168, 20, 104 },
	{ 0, 40, 168, 12, 8 },
	{ 1, 56, 168, 4, 4 },
	{ 0, -12, 172, 4, 100 },
	{ 1, -8, 172, 8, 16 },
	{ 0, 8, 172, 4, 100 },
	{ 1, 52, 172, 4, 4 },
	{ 0, 56, 172, 4, 20 },
	{ 0, 40, 176, 8, 16 },
	{ 1, 48, 176, 4, 4 },
	{ 0, 52, 176, 4, 8 },
	{ 1, -144, 180, 4, 4 },
	{ 0, -140, 180, 8, 4 },
	{ 0, 48, 180, 4, 4 },
	{ 1, -152, 184, 4, 4 },
	{ 0, -148, 184, 8, 88 },
	{ 1, -140, 184, 4, 4 },
	{ 0, -136, 184, 4, 60 },
	{ 1, 48, 184, 8, 16 },
	{ 0, -152, 188, 4, 84 },
	{ 0, -140, 188, 4, 52 },
	{ 0, -8, 188, 16, 84 },
	{ 0, 32, 192, 4, 80 },
	{ 1, 36, 192, 4, 4 },
	{ 0, 40, 192, 4, 80 },
	{ 1, 44, 192, 4, 4 },
	{ 1, 56, 192, 4, 4 },
	{ 1, 160, 192, 8, 4 },
	{ 0, 36, 196, 4, 76 },
	{ 0, 44, 196, 4, 76 },
	{ 0, 56, 196, 4, 76 },
	{ 1, 160, 196, 4, 12 },
	{ 0, 164, 196, 4, 4 },
	{ 0, 48, 200, 8, 72 },
	{ 0, 152, 200, 4, 4 },
	{ 1, 156, 200, 4, 8 },
	{ 1, 164, 200, 4, 8 },
	{ 0, 60, 204, 4, 68 },
	{ 1, 64, 204, 4, 8 },
	{ 0, 68, 204, 4, 20 },
	{ 1, 148, 204, 8, 4 },
	{ 0, 148, 208, 20, 20 },
	{ 1, -168, 212, 4, 12 },
	{ 0, -164, 212, 4, 4 },
	{ 0, 64, 212, 4, 12 },
	{ 1, 124, 212, 4, 24 },
	{ 1, -164, 216, 8, 4 },
	{ 0, 132, 216, 4, 4 },
	{ 1, 136, 216, 4, 4 },
	{ 0, 140, 216, 4, 56 },
	{ 1, -164, 220, 4, 4 },
	{ 0, -160, 220, 4, 52 },
	{ 1, -92, 220, 4, 40 },
	{ 0, 104, 220, 16, 8 },
	{ 1, 120, 220, 4, 16 },
	{ 1, 128, 220, 8, 8 },
	{ 0, 136, 220, 4, 36 },
	{ 0, -168, 224, 8, 16 },
	{ 1, -96, 224, 4, 12 },
	{ 0, -48, 224, 4, 48 },
	{ 1, -44, 224, 8, 8 },
	{ 1, 64, 224, 8, 12 },
	{ 0, 84, 224, 4, 28 },
	{ 1, 88, 224, 4, 4 },
	{ 0, 92, 224, 4, 28 },
	{ 1, -80, 228, 12, 4 },
	{ 0, -68, 228, 4, 24 },
	{ 0, 88, 228, 4, 24 },
	{ 0, 96, 228, 4, 44 },
	{ 1, 100, 228, 8, 4 },
	{ 0, 108, 228, 12, 44 },
	{ 1, 128, 228, 4, 4 },
	{ 0, 132, 228, 4, 44 },
	{ 1, 144, 228, 16, 4 },
	{ 0, 160, 228, 8, 4 },
	{ 1, -88, 232, 8, 12 },
	{ 0, -80, 232, 12, 40 },
	{ 0, -44, 232, 8, 40 },
	{ 0, 100, 232, 8, 40 },
	{ 0, 128, 232, 4, 40 },
	{ 0, 144, 232, 8, 40 },
	{ 1, 152, 232, 12, 4 },
	{ 0, 164, 232, 4, 40 },
	{ 0, -96, 236, 4, 8 },
	{ 1, 64, 236, 4, 24 },
	{ 0, 68, 236, 4, 36 },
	{ 0, 120, 236, 8, 36 },
	{ 0, 152, 236, 4, 36 },
	{ 1, 156, 236, 8, 4 },
	{ 0, -168, 240, 4, 32 },
	{ 1, -164, 240, 4, 4 },
	{ 1, -140, 240, 4, 16 },
	{ 1, -104, 240, 4, 4 },
	{ 0, 156, 240, 4, 32 },
	{ 1, 160, 240, 4, 8 },
	{ 0, -164, 244, 4, 28 },
	{ 1, -136, 244, 4, 4 },
	{ 0, -104, 244, 4, 28 },
	{ 1, -96, 244, 4, 16 },
	{ 1, -88, 244, 4, 8 },
	{ 0, -84, 244, 4, 28 },
	{ 0, -136, 248, 4, 24 },
	{ 0, 160, 248, 4, 24 },
	{ 0, -88, 252, 4, 20 },
	{ 1, -68, 252, 4, 4 },
	{ 1, 84, 252, 12, 4 },
	{ 0, -140, 256, 4, 16 },
	{ 0, -68, 256, 4, 16 },
	{ 0, -36, 256, 4, 16 },
	{ 1, -32, 256, 12, 4 },
	{ 0, 84, 256, 4, 16 },
	{ 1, 88, 256, 4, 4 },
	{ 0, 92, 256, 4, 16 },
	{ 1, 136, 256, 4, 4 },
	{ 0, -96, 260, 8, 12 },
	{ 0, -32, 260, 12, 12 },
	{ 0, 64, 260, 4, 12 },
	{ 0, 88, 260, 4, 12 },
	{ 0, 136, 260, 4, 12 },
}
-- Meadow props: { model, x, z, yaw (degrees) }.
local PROPS = {
	{ "BoulderSplit", -168, 256, 291 },
	{ "Bush", -158, 255.4, 147 },
	{ "Bush", -166.5, 246.5, 351 },
	{ "Boulder", 168, 256, 177 },
	{ "BoulderSplit", -168, 150, 7 },
	{ "Bush", -157.4, 148.5, 73 },
	{ "Bush", -168.6, 138.9, 288 },
	{ "Stone", -168.8, 159.5, 182 },
	{ "Boulder", 168, 150, 5 },
	{ "Bush", 167.7, 141.3, 267 },
	{ "Bush", 168.5, 160.6, 231 },
	{ "Boulder", -58, 256, 249 },
	{ "Bush", -47.6, 255.6, 141 },
	{ "Stone", -67.1, 255.6, 339 },
	{ "BoulderSplit", 58, 256, 144 },
	{ "Bush", 47.5, 255.7, 227 },
	{ "Stone", 59.3, 247.3, 68 },
	{ "Boulder", -168, 12, 26 },
	{ "Stone", -156.9, 13, 93 },
	{ "Bush", -168.7, 21.8, 70 },
	{ "Boulder", 168, 12, 334 },
	{ "Stone", 167.7, 22.3, 249 },
	{ "BoulderSplit", -120, 256, 2 },
	{ "Bush", -111.4, 254.9, 18 },
	{ "Stone", -120.5, 245.6, 283 },
	{ "BoulderSplit", 120, 256, 123 },
	{ "Bush", 110, 256.7, 178 },
	{ "Bush", 118.7, 244.6, 300 },
	{ "Boulder", -168, 210, 215 },
	{ "Bush", -157.3, 210.1, 221 },
	{ "Bush", -167.3, 221.4, 94 },
	{ "Boulder", 168, 210, 6 },
	{ "Bush", 157, 210.6, 69 },
	{ "Bush", 168.5, 200, 99 },
	{ "Stone", 168, 221.3, 90 },
	{ "Bush", -42.3, 180.6, 70 },
	{ "Stone", -43.8, 170.9, 117 },
	{ "Bush", 42.3, 180.6, 33 },
	{ "Stone", 33.8, 175.6, 337 },
	{ "Bush", -96.6, 115.9, 131 },
	{ "Stone", -90.1, 108.4, 63 },
	{ "Bush", 96.6, 115.9, 0 },
	{ "Stone", 87.3, 119.1, 22 },
}
-- Bull pads: { pen, x, z }.
local BULLS = {
	{ 1, -18, 173 },
	{ 2, -75.2, 129.6 },
	{ 3, 52, 157.1 },
	{ 4, -78.6, 57.9 },
	{ 5, 84.9, 93.3 },
}

-- Walls: the home base's are the ones round z 0..the old depth; which is which by where they are.
local function which(p)
	local c = p.Position
	if c.Z > 20 and math.abs(c.X) < 40 then
		return "back"
	elseif c.Z > 20 and c.X < 0 then
		return "left"
	elseif c.Z > 20 then
		return "right"
	elseif c.Z > -10 and c.Z < 0 and math.abs(c.X) > 56 then
		return if c.X < 0 then "frontleft" else "frontright"
	end
	return nil
end
local moved = 0
for _, p in world.Walls:GetChildren() do
	if p:IsA("BasePart") and (p.Name == "Wall" or p.Name == "Cap") and p.Position.Z + p.Size.Z / 2 > -10 then
		local w = which(p)
		for _, spec in WALLS do
			if spec[1] == p.Name and spec[2] == w then
				p.Size, p.CFrame = spec[4], CFrame.new(spec[3])
				moved += 1
			end
		end
	end
end

-- The floor: the old single home Ground part (or a previous run's rectangles) goes.
local template
for _, p in world.Ground:GetChildren() do
	if p:IsA("BasePart") and (p:GetAttribute("ArcBase") or (p.Name == "Ground" and p.Position.Z > 0 and p.Size.X > 200)) then
		template = template or p:Clone()
		p:Destroy()
	end
end
assert(template, "no home Ground part to copy the look of")
for _, t in template:GetChildren() do
	if not t:IsA("Texture") then
		t:Destroy()
	end
end
template:SetAttribute("ArcBase", true)
for _, r in FLOOR do
	local dirt, x, z, sx, sz = r[1] == 1, r[2], r[3], r[4], r[5]
	local top = if dirt then -1 else 0
	local p = template:Clone()
	p.Name = if dirt then "Dirt" else "Ground"
	p.Size = Vector3.new(sx, top + 2, sz)
	p.CFrame = CFrame.new(x + sx / 2, (top - 2) / 2, z + sz / 2)
	-- (the checker starts from each part's low-x, low-z corner: an odd tile there shifts it a tile)
	local odd = (math.floor(x / 4 + 0.5) + math.floor(z / 4 + 0.5)) % 2
	for _, t in p:GetChildren() do
		if t:IsA("Texture") and t.Name == "Checker" then
			t.OffsetStudsU = odd * t.StudsPerTileU / 2
		end
	end
	p.Parent = world.Ground
end

-- The floor's top under (x, z): 0 on grass, -1 on dirt.
local function topAt(x, z)
	for _, r in FLOOR do
		if r[1] == 1 and x >= r[2] and x < r[2] + r[4] and z >= r[3] and z < r[3] + r[5] then
			return -1
		end
	end
	return 0
end

-- Meadow props round the walls.
local decor = world:FindFirstChild("BaseDecor") or Instance.new("Folder")
decor.Name = "BaseDecor"
decor:ClearAllChildren()
local templates = {}
for _, o in world.Obstacles:GetChildren() do
	local cf = if o:IsA("Model") then o:GetPivot() elseif o:IsA("BasePart") then o.CFrame else nil
	if cf and cf.Z < 0 and cf.Z > -760 and not templates[o.Name] then
		templates[o.Name] = o
	end
end
local placed = 0
for _, r in PROPS do
	local from = templates[r[1]]
	if from then
		local copy = from:Clone()
		for _, name in { "FunnelPivot", "FunnelScale", "FunnelCF", "FunnelSize" } do
			copy:SetAttribute(name, nil)
		end
		-- standing on the floor: its bottom as far over the floor's top as the original's
		local box, size
		if copy:IsA("Model") then
			box, size = copy:GetBoundingBox()
		else
			box, size = copy.CFrame, copy.Size
		end
		local pivot = if copy:IsA("Model") then copy:GetPivot() else copy.CFrame
		local up = pivot.Y - (box.Y - size.Y / 2)
		local cf = CFrame.new(r[2], topAt(r[2], r[3]) + up, r[3]) * CFrame.Angles(0, math.rad(r[4]), 0)
		if copy:IsA("Model") then
			copy:PivotTo(cf)
		else
			copy.CFrame = cf
		end
		copy.Parent = decor
		placed += 1
	end
end
decor.Parent = world

-- Bull pads (placeholders): a red mat 18 across, a post and a bull on it, facing the yard.
local pads = world:FindFirstChild("BullPads") or Instance.new("Folder")
pads.Name = "BullPads"
pads:ClearAllChildren()
local function block(parent, name, size, cf, color, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	if shape then
		p.Shape = shape
	end
	p.Size, p.CFrame, p.Color = size, cf, color
	p.Parent = parent
	return p
end
for _, r in BULLS do
	local at = Vector3.new(r[2], topAt(r[2], r[3]), r[3])
	local face = CFrame.lookAt(at, Vector3.new(YARD.X, at.Y, YARD.Z))
	local m = Instance.new("Model")
	m.Name = "BullPad" .. r[1]
	m:SetAttribute("Pen", r[1])
	block(m, "Mat", Vector3.new(0.4, 18, 18), face * CFrame.new(0, 0.2, 0) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(210, 60, 60), Enum.PartType.Cylinder)
	block(m, "Post", Vector3.new(1, 4, 1), face * CFrame.new(0, 2.4, 0), Color3.fromRGB(90, 90, 100))
	block(m, "Bull", Vector3.new(3, 2.4, 5.5), face * CFrame.new(0, 5.6, 0), Color3.fromRGB(120, 72, 44))
	block(m, "Head", Vector3.new(2.2, 2, 2), face * CFrame.new(0, 6.2, -3.4), Color3.fromRGB(110, 64, 38))
	m.PrimaryPart = m.Mat
	m.Parent = pads
end
pads.Parent = world

return string.format("arc base: %d walls moved, %d floor parts, %d props, %d bull pads", moved, #FLOOR, placed, #BULLS)
