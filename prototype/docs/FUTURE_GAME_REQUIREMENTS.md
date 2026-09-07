# SEPTEMBER 7, 2026 — SHARED UI AND FUTURE-GAME CONTRACT

This revision updates the working guide for Serenity's new UI. Preserve the discovery and mechanic-validation chapters below. This section supersedes older UI version, page-placement and reporting instructions where they differ.

**Release state:** Phonk Evolution RC1 is an isolated test candidate in `MUshihara/SerenityNewUi`, branch `concept-02-preview`. The production repository `MUshihara/Serenity-hub` has NOT been migrated. The owner must approve the Phonk test before production rollout; approval does not replace compatibility checks for other games.

## A. Learn the existing contract before changing a game

Read the actual game source, current shared entry point, controller lifecycle, configuration paths and manifest. A guide's date does not prove which runtime the game uses. Both supplied Phonk and Sell Ores examples use V3-style manifests, but their startup/configuration policies differ. Phonk starts automation OFF; Sell Ores has saved-value restoration behavior. Preserve each policy deliberately.

The current Phonk bridge is Phonk-specific, not a drop-in replacement for all V3 games. Keep stable Page.Feature.Control IDs, callbacks, default values, `Adapter:SetLive`, cleanup contracts and state ownership. Visual regrouping must preserve configuration keys or provide explicit migration. One controller serves desktop and mobile. Never put mechanics into renderers or duplicate game logic per device.

## B. Shared features required in future builds

Default inclusion means every new game must implement or explicitly report support for these shared capabilities. It does not mean activating automations on startup. Never add nonfunctional switches to satisfy a checklist.

| Location | Required content and ownership |
|---|---|
| About | Avatar, display name, username, current game, session elapsed time, community card with Discord symbol, actual version/date and release notes. |
| Game pages | Only this game's verified farming, progression, inventory, reward, shop or other mechanics. Use exact game wording. |
| Feedback | Shared hub bug report, feedback, new feature and new game request form. Sends to the hub owner's destination. Available in every integration. |
| Webhook | Player-configured gameplay notifications: enable switch, destination, verified event selection, cooldown and delivery status. Distinct from hub Feedback. |
| Misc → Performance | FPS cap, reversible lag reduction and disable 3D. Keep reopening controls usable with 3D off. |
| Misc → Session | Auto execute after supported teleport, auto reconnect with bounded backoff, manual rejoin and capability status. |
| Misc → Travel | Current Place ID, Universe ID and Job ID; copy actions; validated destination list or explicit destination Place ID and optional Job ID. |
| Settings → Appearance | Accent/theme, readable UI scale, transparency, reduced UI motion and Low Effects. |
| Settings → Interface | Start minimized preference; persistent, movable launcher; saved launcher position. |
| Settings → Profiles | Debounced autosave, save/load/reset configuration, and named profiles when implemented. Do not label basic save/reset as complete named-profile support. |

Game rendering/performance controls belong in Misc. Settings changes the hub's appearance and preferences. Existing game-specific tuning may remain in a clearly labeled game page while stable IDs are preserved.

### Gameplay notification discovery

During FIRST GUIDE, identify meaningful candidate events: rare drops or pets, achievements, unlocks, prestige/rebirth milestones, completed quests, useful earnings summaries and recoverable failures. Record each authoritative state source. Implement only validated events. If no suitable events exist, explain that instead of fabricating them.

Deduplicate by event identity/state transition; throttle delivery; use bounded retries. Gameplay notifications start OFF until the player configures them. Do not send player rewards or account activity to the hub's feedback destination automatically.

### Session, travel and performance behavior

Auto execute queues the approved loader once for a supported teleport. It does not promise launch after closing Roblox. Auto reconnect responds only to detected recoverable conditions, supports cancellation, and never creates duplicate runtimes. Expose unsupported runtime APIs clearly. Check actual place IDs; a destination can reject entry even when the ID is valid.

FPS cap is a user choice with sensible bounds; never force extreme low FPS on everyone. Record original settings before applying reversible lag reduction or disable-3D. Restore what this runtime changed when disabled/destroyed. Avoid destructive map cleanup sold as a reversible toggle.

## C. Hub feedback delivery

The owner explicitly approved a directly embedded public Discord reporting destination for this test. Hosting is optional under that choice. Keep the default in the shared Feedback module so every device has it; never depend on a PC-only local destination file. This is a narrow owner-authorized exception to the general rule against publishing secrets, not permission to publish other credentials.

Do not require end users to supply their own webhook to report a hub bug. Keep Feedback separate from gameplay Webhook configuration. Resetting profiles must not erase the built-in hub destination. Owner endpoint rotation requires updating the shared source, rebuilding bundles and repinning dependent loaders; old pinned versions retain their old destination. Never repeat the endpoint in logs, release notes or this guide.

Required report behavior:

- Categories: Bug Report, Feedback, New Feature, New Game Request.
- Message validation and visible character count; include current game, Place ID, Job ID and build label.
- Show the included context. Submit only on an explicit user action; no startup or automatic feedback sends.
- Disable Discord mentions in the payload; preserve the draft on failure; show success only on a successful HTTP response.
- Support available request APIs on desktop/mobile and clearly report missing HTTP capability.
- Prevent double submission while busy; enforce a local cooldown and respect rate-limit failures. A local cooldown is not protection against someone calling a public webhook directly.
- Test fresh-device behavior with no saved destination, failed response, unavailable API, success, cooldown and teardown. Mocked HTTP is not proof of Discord delivery.

## D. Presentation and mobile acceptance

Keep the new full-width brand/title bar with an accent divider, top-right search/minimize, and a separate readable page heading. Section headers use a restrained accent underline. Keep the existing Serenity identity rather than copying another hub wholesale.

Use the shared image icon catalog with a known fallback, not text emoji. Target navigation symbols around 22–24 logical pixels and main labels around 13–14, secondary labels around 11–12; verify actual device size after scaling. Confirm images really load on PC and mobile. Provide a usable fallback for missing thumbnails/assets.

The launcher stays visible while the window is open or minimized, is around 56px with a larger centered logo, supports mouse/touch dragging, remains inside viewport bounds and saves its position. A drag must not trigger a click. Start minimized is optional and saved. Re-execution creates one launcher and one UI runtime.

Use distinct portrait/landscape arrangements rather than only shrinking the PC window. Preserve readable labels, 44–48px logical touch targets, scrollable navigation/content, safe screen insets and keyboard access. Cards stack on narrow screens. Popups close reliably and sliders restore scrolling after drag/cancel.

Motion should be short, cancelable and event-driven. Reduced Motion/Low Effects removes optional animation and heavy shadows. No perpetual icon animations or per-control frame loops. Update the session timer at most once per second; pause unnecessary hidden-page updates. Do not claim FPS savings without measurement.

Autosave UI preferences with a short debounce and on orderly teardown when file APIs are supported. Report unavailable persistence honestly. Reset Saved Config requires an explicit reset action and affects only Serenity-owned configuration. It must not delete production files while testing an isolated preview.

## E. Current implementation versus future requirements

RC1 includes the Phonk controls, shared About/Feedback, title bar, icons, session timer, launcher drag/show/minimize preference, UI autosave/reset and device layouts. Feedback now has an owner-approved default destination and request fallback; live delivery still requires a device test.

The candidate does NOT establish universal V3 compatibility, full named profiles, every future gameplay webhook event, or all future session/travel/performance controllers. Existing Phonk controls stay connected; missing future controls must be implemented and validated when that game is integrated. Keep this distinction in every handoff.

## F. Exact RC1 test and rollout gate

On PC AND mobile, run the exact pinned Phonk loader from a clean session:

1. Check every page/icon, portrait and landscape layout, scrolling, search, popup dismissal and keyboard interaction.
2. Drag the launcher; minimize/reopen; enable Start minimized and execute again. Confirm one runtime and saved launcher position.
3. Change appearance, reload, reset saved config and reload again. Confirm Phonk automation remains OFF at startup.
4. Submit one report and verify it reaches the owner's Discord channel with correct game context. Check failure text and draft retention when delivery is unavailable.
5. Exercise each original game control and compare behavior with the accepted source; stop/re-execute/respawn and check cleanup. Test existing performance toggles and restoration.
6. Complete a representative low-end soak; record actual observations and unresolved failures.

After owner approval, audit and adapt Sell Ores next, preserving its saved-state policy. Inventory every remaining game's entrypoint and adapter contract before switching the shared production UI. Stage rollout with a recorded rollback commit, cache/version update and exact published-loader checks. Do not point every script at the Phonk bridge or silently replace game payloads.

The final-phase AI must complete the required shared-feature table, identify unavailable items honestly, preserve proven game behavior, and record device validation separately from mocked checks.

---

