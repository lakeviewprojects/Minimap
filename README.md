# Minimap

Server-side minimap builder and client-side keybind for the Phone2 Map app. This module is **optional** — Phone2's Map app works without it if a `PhoneMinimap` folder already exists in ReplicatedStorage by other means.

## Dependencies

| Submodule | Location (Rojo tree) | Required |
|---|---|---|
| **Phone2** | `StarterGui.Phone2` | Yes (client keybind opens the Map app) |
| **Fusion3** | `ReplicatedFirst.Fusion3` | Yes (client keybind uses `peek`) |

## Rojo Setup

Add to your `default.project.json`:

```json
"ServerScriptService": {
  "$ignoreUnknownInstances": true,

  "MinimapService": {
    "$path": "submodules/Minimap/ServerScriptService/"
  }
},

"StarterGui": {
  "$ignoreUnknownInstances": true,

  "Minimap": {
    "$path": "submodules/Minimap/StarterGui/"
  }
}
```

## File Structure

```
Minimap/
├── README.md
├── ServerScriptService/
│   └── init.server.luau       # Minimap builder (clones terrain + MapLabels → ReplicatedStorage)
└── StarterGui/
    └── init.client.luau       # M key binding to toggle Phone2 Map app
```

## How It Works

### Server — Minimap Builder (`init.server.luau`)

Runs once on server start (after a 5-second yield). Builds a `Folder` named `PhoneMinimap` in `ReplicatedStorage`:

1. **Terrain cloning** — Scans all `Workspace` descendants for objects named `Road`, `Grass`, `Tree`, `Sidewalk`, `Roof`, `Wood`, or `Rock`. Clones them (skipping duplicates covered by already-cloned ancestors), anchors all `BasePart`s, and strips non-visual children (scripts, sounds, particles).

2. **MapLabel markers** — Iterates all instances tagged `"MapLabel"` via `CollectionService`. For each tagged `BasePart` or `Model`, creates a tiny invisible `Part` at the instance's world position with a `Label` string attribute.

The resulting folder is replicated to all clients for use in ViewportFrame-based minimaps.

### Client — M Key Binding (`init.client.luau`)

Binds the **M** key via `ContextActionService`:

- If the Phone2 Map app is already open → closes the phone.
- Otherwise → opens the phone and navigates to the Map app.

The binding auto-unbinds on respawn (since the ScreenGui is destroyed).

## Setting Up MapLabels

MapLabels are the location markers that appear on the minimap. They are defined in Studio using **CollectionService tags** and **Attributes**.

### Step-by-Step

1. **Select** the `BasePart` or `Model` in Studio that represents the location.
2. **Add the tag** `MapLabel` via the Tag Editor plugin (or the command bar):
   ```lua
   game:GetService("CollectionService"):AddTag(workspace.MyPart, "MapLabel")
   ```
3. **Set attributes** on the instance:

| Attribute | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `Label` | `string` | No | Instance name | Display name shown on the minimap |
| `Floor` | `number` | No | `nil` (ground) | Floor number for multi-story buildings (e.g. `2`) |
| `Stairs` | `boolean` | No | `false` | Mark as a staircase waypoint for floor-aware routing |

### Stairs Auto-Detection

If a MapLabel's `Label` text contains `"stair"` (case-insensitive), the builder automatically sets `Stairs = true` on the marker — no manual attribute needed.

### Floor-Aware Routing

When the Map app navigates to a location on a higher floor, it first routes the player to the nearest `Stairs` MapLabel, then switches to the real destination once the player climbs above the floor threshold. Floor thresholds are configured in the Map app's `FLOOR_HEIGHT` table.

### Example MapLabel Setup

| Instance | Tag | Label | Floor | Stairs | Behaviour |
|----------|-----|-------|-------|--------|-----------|
| `Workspace.GymEntrance` | `MapLabel` | `"Gym"` | — | — | Normal white dot + "Gym" text |
| `Workspace.ScienceRoom` | `MapLabel` | `"Science"` | `2` | — | Shows "Science is on floor 2" when navigating |
| `Workspace.MainStairs` | `MapLabel` | `"Main Stairs"` | — | `true` | Renders stairs icon (auto-detected from name) |
| `Workspace.BackStairs` | `MapLabel` | `"Back Stairwell"` | — | — | Auto-detected as stairs (name contains "stair") |

### Terrain Object Names

The server builder clones Workspace objects with these exact names:

| Name | Typical Usage |
|------|---------------|
| `Road` | Streets, pathways |
| `Grass` | Lawns, fields |
| `Tree` | Tree models/parts |
| `Sidewalk` | Pedestrian paths |
| `Roof` | Building rooftops |
| `Wood` | Wooden structures |
| `Rock` | Rock formations |

To add geometry to the minimap, simply name the part or model one of these names. The builder strips all non-visual children (scripts, sounds, particles) from clones.
