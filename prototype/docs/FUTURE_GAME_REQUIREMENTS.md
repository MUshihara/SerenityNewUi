# Serenity shared features and future game requirements

User requirements, September 6, 2026. Applies to future integrations; this document does not claim these capabilities are implemented in the isolated preview. Production integration awaits explicit user approval and compatibility testing.

## Architecture and compatibility

Preserve Page → Feature → Control, one game controller and config for both PC and mobile. Shared core owns lifecycle, configuration, routing and shared capabilities. Renderers own presentation. Game adapters own verified mechanics and event detection. New games target the verified current V3 entry point. Preserve existing Page.Feature.Control IDs; visual regrouping must not silently rename saved settings. Introduce aliases/migrations where necessary.

The supplied master handoff and short start-here file are architecture snapshots, not the two full diagnostic/finalization guides. Do not equate a guide generation with a confirmed runtime version. Inspect Sell Ores and Phonk Evolution raw sources before claiming legacy/current compatibility. Preserve their validated mechanics and restoration semantics. Compare callbacks, defaults, IDs, controller lifecycle, reload/respawn and routing on both devices.

## Required page ownership

| Page | Content |
| --- | --- |
| About | Shared avatar, account/game identity, session duration, Discord community and actual release notes |
| Game pages | Verified game automation, progression, shops and game-specific controls |
| Webhook | Destination, enable switch, supported event selection, cooldown, test message and delivery status |
| Misc → Performance | FPS cap, lag reduction, disable 3D rendering and restoration |
| Misc → Session | Auto execute after teleport, auto reconnect, rejoin and capability status |
| Misc → Travel | Current Place ID, universe ID, Job ID, copy actions and explicit destination Place ID/optional Job ID |
| Settings → Appearance | Theme/accent, text/window sizing, transparency, Low Effects and reduced UI motion |
| Settings → Profiles | Profile selection, save/load/reset, autosave and configuration preferences |

Consolidate user-facing server/travel utilities under Misc. Preserve or migrate pre-existing IDs if their former page was Server. UI Low Effects belongs in Settings; game rendering/performance changes belong in Misc.

## Default inclusion is not default activation

All future builds must assess and provide the shared capabilities above. Webhook sending, auto execute, auto reconnect, game lag reduction and disable-3D start off until configured/enabled. Do not install fake working switches: unsupported capabilities must show a clear unavailable state and reason. Expose an FPS cap with a sensible default and supported range; do not silently force every user to an extremely low FPS.

Webhook events must come from verified game state: rare drops/pets, milestone or quest completion, prestige/unlocks, meaningful earnings summaries, and failures where useful. The first diagnostic phase records candidate events and their evidence; final integration implements validated ones. Deduplicate events, throttle sends, use bounded retries and clear status. Keep webhook secrets out of logs, public source and exported profiles by default. Never send a test webhook during development without user authorization.

Auto execute means restoring the approved loader after supported teleports; it cannot promise execution after closing the client. Auto reconnect uses detected recoverable conditions with bounded backoff and must not duplicate controllers. Unsupported queue/connection APIs are reported. Travel uses verified current IDs and user-selected destinations; arbitrary places may deny access. Never guess game-specific destination IDs.

Performance controllers share cleanup and restore changed rendering settings when disabled/destroyed where possible. Disabling 3D must leave UI restoration controls accessible. Avoid per-control frame loops, repeated scans and heavy protection on hot loops. Measure real device performance before claiming savings.

## Presentation acceptance

Use shared catalog icons for every page and feature; use appropriate control/action icons where they aid recognition. Check resolution and actual image loading on both devices; catalog fallback alone is not visual verification. Do not assume the provided screenshot proves missing icons: its visible sidebar entries have symbols.

Aim for readable main labels around 13–14 logical pixels, secondary text around 11–12 and navigation icons around 20–24. Validate effective size after scaling on real phones. Important labels must not depend on tiny captions or hover. Touch targets and scrolling require device checks.

What's New must show the actual release version/date and concise changes/fixes. Separate UI changes from game changes. Never present placeholder notes as live updates.

## Release gate

Before final: approved PC/mobile visuals; real old/current game compatibility; configuration preservation; working shared capabilities or explicit unsupported states; exact published-loader test; reload/cleanup and low-end soak. UI approval alone does not prove mechanic compatibility. The current preview is not production-ready solely because it looks complete.
