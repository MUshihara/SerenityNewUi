# SERENITY HUB — NEXT UI

A modular rebuild of Serenity's interface.

## Goal

Serenity Next should feel like a polished compact product, not a generic Roblox UI library.

Core rules:

- readable before compact
- glass through layered material, not blur everywhere
- one semantic UI model, desktop/mobile adaptations
- no game mechanics inside renderer/components
- centralized motion/input/popup management
- real icon system, no Unicode placeholder squares
- search as navigation
- explicit running/waiting/locked/error states
- re-execute cleanup
- preserve existing Serenity engine/game APIs

## Main visual direction

- dark graphite / smoked navy base
- subtle translucent material
- soft edge reflection
- thin low-contrast strokes
- cyan/mint/lavender primary Serenity palette
- game-specific accent may be layered on top
- larger typography than V2/V3
- fewer visible card borders
- flatter sections
- floating acrylic only for menus/dialogs/toasts
- no giant AI-style gradient blobs

## Structure

```text
src/
  core/
    Runtime.lua
    Tokens.lua
    Typography.lua
    Motion.lua
    Material.lua
    Icons.lua
    InputRouter.lua
    PopupManager.lua
    Search.lua

  components/
    Window.lua
    Sidebar.lua
    PageHeader.lua
    Section.lua
    Toggle.lua
    Slider.lua
    Select.lua
    MultiSelect.lua
    Input.lua
    Button.lua
    Status.lua
    Toast.lua
    Modal.lua
    Tooltip.lua

  renderers/
    Desktop.lua
    Mobile.lua

  assets/
    icon-map.lua

demo/
  Manifest.lua
  Demo.lua

docs/
  DESIGN_RULES.md
  COMPONENT_SPEC.md
```

## Why modular

A single source file can technically render this UI, but separating visual systems lets us:

- tune typography without touching controls
- replace the glass material once for every component
- update icon rendering globally
- reuse one popup manager
- change motion timing globally
- profile input/event usage
- maintain desktop/mobile variations cleanly
- eventually integrate with Serenity V3 manifests without rewriting game mechanics

