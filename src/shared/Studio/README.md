# Native rider renders

Manual Studio edit-mode tooling; gameplay never imports it. The poses use the
existing `Animals.Horse` and `Animals.Cactus` rigs and their gallop animations,
with an R6 bacon-hair avatar looking back and a physical overhead lasso.
All six body colors are exactly `#FFFFFF`; normal game lighting still shades them.

After Rojo sync, invoke through Studio MCP `execute_luau` in the Edit datamodel:

```lua
local renders = require(game.ReplicatedStorage.Shared.Studio.RiderRenders)
renders.create()
renders.face("Reference") -- or "Smug", "Grin"
renders.view("Horse") -- or "Cactus"
```

Studio caches `require` results. When iterating on the repo file, execute the
freshly synced source without changing any script in Studio:

```lua
local source = game.ReplicatedStorage.Shared.Studio.RiderRenders
local run = assert(loadstring(source.Source))
setfenv(run, setmetatable({ script = source }, { __index = getfenv() }))
local renders = run()
renders.create()
renders.face("Reference")
renders.view("Horse")
```

For each mount/face pair, capture with the Studio MCP `screen_capture` tool after
the texture is visibly loaded. For transparent exports, capture the identical
pose and camera against both backgrounds, allowing a render frame to settle:

```lua
renders.view("Horse", Color3.new(1, 1, 1)) -- horse-reference-white.jpg
-- capture, then:
renders.view("Horse", Color3.new(0, 0, 0)) -- horse-reference-black.jpg
```

Repeat for `horse` / `cactus` and `smug` / `grin` / `reference`, then run:

```sh
node src/shared/Studio/export-cutouts.cjs /absolute/path/to/captures
```

The exporter requires the `sharp` Node package. It recovers alpha from the paired
Studio captures, removes tiny isolated JPEG flecks and crops with 32px padding.
It does not regenerate or repaint the avatar, mount, pose or lasso. Keep the
original captures alongside the six transparent PNGs.

Always finish with `renders.cleanup()`. It removes `Workspace.RiderRenderStage`
and restores the original camera, field of view and selection. The stage is far
away from the course; `Workspace.World`, `Workspace.Pens` and Lighting are never
modified. Neither the stage nor its poses are saved in the map files.

## Faces

| Variant | Source | Texture |
| --- | --- | --- |
| Smug | Roblox classic face 406001308 | 405706038 |
| Grin | Roblox Know-It-All Grin face 26424808 | 26424652 |
| Reference | Face decal derived from the supplied expression image | 111969738039607 |

The Reference texture was created with built-in image generation, then uploaded
through Studio MCP. Its PNG and exact prompt are in `FaceAssets/`. Only this
decal is generated artwork; all rider images are native Studio captures.

## Meadow diorama

`MeadowDiorama.luau` creates a separate, manually invoked photo set at
`(20000, 1000, 4000)`, outside the stampede course. It clones the actual meadow
grass/dirt layout and rock/bush models, extends the grass to an open horizon,
and frames the scene with a level camera, 60-degree field of view, and sky in
the upper half. There are no walls, animals, spawns, nests, or runtime scripts.
The native Studio capture is `MeadowDiorama.jpg`.

```lua
local meadow = require(game.ReplicatedStorage.Shared.Studio.MeadowDiorama)
meadow.create() -- creates Workspace.MeadowDiorama and frames the shot
meadow.view() -- return to the photo camera after moving around
meadow.cleanup() -- remove the set and restore the previous camera/selection
```

Use the fresh-source loading pattern above when iterating. The set can remain
in the open Studio session for photos; it is not added to the saved map and is
never created automatically in gameplay. `World`, `Pens`, and Lighting are
untouched. Cleanup/recreation and original-camera restoration were checked in
Studio; the original World/Pens descendant counts remained 49,875 / 2,910.
