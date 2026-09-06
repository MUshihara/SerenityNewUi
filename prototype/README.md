# Serenity Concept 02 — isolated desktop preview

Interactive Roblox/Luau implementation of the approved dark, rose-accented concept.

All changes live under `prototype/`. The existing `Serenity-Next-Repo-Starter` demo and the `Serenity-hub` production repository are untouched. No farming, purchase, movement, webhook or other game-action calls are made.

## Run

Execute `dist/SerenityConcept.lua` in the Roblox test environment. The published handoff provides an immutable raw loader for the tested source revision. Right Ctrl hides/shows; Ctrl+K searches; Escape closes a menu. The launcher restores the minimized window. Settings → Profiles → Close Preview tears it down.

The preview can coexist with the production UI. Re-executing replaces only `__SERENITY_CONCEPT_02`. Settings are written only to `SerenityConcept02/settings-v1.json` when file APIs exist. Prototype values never modify production config.

## Images

The real Serenity logo and canonical icon catalog use existing Roblox assets. The current game thumbnail is requested from Roblox. Two original standalone PNG banners are included in `assets/`, generated using the built-in image-generation tool: a midnight-blue alpine lake and a rose-cloud mountain sunset, both without lettering or UI.

Where `getcustomasset`/`getsynasset`, read/write file APIs and HTTP access are available, the demo downloads and caches these versioned PNGs. Otherwise the cards retain a colored image area and an icon. To use Roblox-hosted pictures, upload the PNGs and configure their working image IDs before running:

```lua
getgenv().SerenityConceptOptions = {
    CommunityImage = "rbxassetid://YOUR_IMAGE_ID",
    UpdatesImage = "rbxassetid://YOUR_IMAGE_ID",
    -- DiscordInvite = "https://discord.gg/YOUR_INVITE",
}
```

The default invite is copied from the current production UI source; live invite validity is not assumed. Clipboard support is optional: a selectable text field is provided as fallback. Changelog opens inside the UI.

## Source structure

- `core/`: lifecycle, theme, icons, copied serializable state, widgets, input, image loading, popup ownership.
- `components/`: expandable groups, value/action controls, searchable single/multiple selections.
- `Renderer.lua`: fixed shell, navigation, scale, drag, hide/show, game identity.
- `Manifest.lua`: V3-shaped demonstration pages and controls with stable semantic IDs.
- `App.lua`: manifest composition, sub-tabs, state bridge, search, About cards, preview actions.
- `build.py`: reproducible standalone distribution; no runtime source-module downloads.

This is an isolated prototype, not a drop-in replacement for the production V3 renderer. The production bridge, readable game integration evidence, mobile renderer and live regression checks remain separate work.

## Validation

See `VALIDATION.md` for the exact checks performed and limits. No claim of live Roblox visual or performance verification is made until the user runs the prototype and returns screenshots.
