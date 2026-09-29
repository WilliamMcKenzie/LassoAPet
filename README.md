# Lasso For Eggs

Roblox game, synced into Studio with [Rojo](https://rojo.space) 7.7.

## Run it

```bash
rojo build -o LassoForEggs.rbxlx
```

Open `LassoForEggs.rbxlx` in Roblox Studio, then keep it in sync while editing:

```bash
rojo serve
```

In Studio, open the Rojo plugin and press Connect.

## Layout

- `src/shared` → `ReplicatedStorage.Shared` (config, animal models)
- `src/server` → `ServerScriptService.Server` (sky, live colours)
- `src/world` → `Workspace` (the map as a saved model; edit it in Studio, then right-click `Workspace.World` → Save to File over `src/world/World.rbxmx`)
- `src/client` → `StarterPlayerScripts.Client` (ride controller, HUD)
