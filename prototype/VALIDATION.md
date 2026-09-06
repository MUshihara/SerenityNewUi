# Concept 02 validation

2026-09-06. This is an isolated UI prototype, not a production UI migration.

## Completed

- All source modules and the generated distribution compile in the Lua 5.4-compatible subset used here. This is not a Luau type analysis or Roblox engine test.
- The complete generated distribution mounts in a finite mocked Roblox environment.
- Stable control keys and prototype-only config paths are verified.
- Repeating the same toggle value emits no duplicate change callback.
- Disabled toggle clicks are ignored.
- Sliders clamp and snap values and reject NaN.
- MultiSelect returns copied selections and preserves explicit empty selections.
- Refreshing an open selection menu preserves valid choices and refreshes visible options.
- Twenty open/refresh/close cycles leave no growing event-connection or runtime-cleanup registry.
- Escape closes a popup while its textbox has focus.
- Hide/show, saved page/sub-tab restoration and control-value restoration pass.
- Re-execution destroys the prior preview only; a production runtime sentinel remains intact.
- Destroy is idempotent and disconnects all tracked and instance-owned mock signals.
- No gameplay remote calls are present; MarketplaceService is used only for current-place display metadata.

Run: `python3 prototype/build.py` followed by `python3 prototype/tests/check.py`.
The test runner uses the system Lua 5.4 library and stubs engine services; it does not download or execute outside scripts.

## Pending live checks

- Actual Roblox text measurements, layout, ZIndex, image moderation/loading and clipping.
- Executor support for local banner images; Roblox image-ID overrides are available.
- Window drag, scale, touch input and popup placement on real viewports.
- Transition appearance and rapid navigation in the Roblox engine.
- In-game FPS, memory and connection counts.
- Comparison screenshots against Concept 02 and the uploaded video.

The current mobile renderer and production V3 bridge are outside this desktop preview. Existing production routes are not changed.

## Motion revision

Added original implementations of completion-driven popup fades, short popup entry movement, sub-tab movement, animated navigation colors and section arrows, and button hover/press outlines. No third-party code copied. Runtime disconnects completion handlers on interruption and teardown. Popup replacement cancels descendant tweens before destruction.

Syntax and mocked lifecycle suite pass, including delayed completion after popup close/reopen and destruction during an exit. These tests do not measure rendering quality, CanvasGroup texture behavior, or frame rate; a Roblox recording remains required.

## Responsive and readability revision

Corrected section height conversion from scaled AbsoluteContentSize to logical offsets, and scaled search-scroll targeting. Added 22 px navigation icons, 44–48 px common rows, larger toggles, scrolling sub-tabs, responsive card stacking and compact phone navigation. Touch sliders restore page scrolling on release/cancellation. Low Effects removes popup CanvasGroups and motion, with no new frame loop.

Mock checks pass for 390×760 portrait, 844×350 landscape and 360×640 portrait: shell bounds, scale 1, touch rows, card stacking, lightweight popup class, and complete cleanup. A controlled 90% scale measurement verifies section sizing. Prior callback, state and popup-interruption checks still pass. No on-device performance claim or rendered mobile screenshot is available.

## Mobile stability follow-up

Reviewed both new recordings and the production V14 mobile source (head-02 and part-02): its default geometry is 650×420 with a 50 px header and separate sidebar. Added an independent layouts/Mobile.lua geometry profile using that compact landscape approach, with a portrait variant and functional scale control. Existing production rendering code is unchanged. Navigation gets explicit order.

Replaced the earlier scale-dependent section-height approach with the sum of explicit logical row heights. The earlier synthetic AbsoluteContentSize test did not establish real engine behavior; the new regression checks invariant logical height at 75, 90, 100 and 115 percent. Phone bounds and cleanup mocks pass. Actual phone stability and visual output remain unverified pending device testing.

## Personal About revision

Added one Roblox avatar thumbnail, display name, username and elapsed session timer. Timer uses one delayed tick per second, updates text only on the visible About page and exits after destruction. Compact replaceable copy/save notifications dismiss after 2.5 seconds. Discord mark is bundled as PNG bytes generated from Simple Icons' Discord SVG (https://github.com/simple-icons/simple-icons/blob/develop/icons/discord.svg); local-image support or a DiscordImage override is still needed to display it. Release notes show this preview's changes.

Mobile search listens for keyboard visibility/size while open, sizes results above the keyboard and disconnects on close. Mock tests cover toast replacement and keyboard bounds alongside previous cleanup checks. Actual thumbnail loading and phone keyboard positioning still require device verification.

## Shared feedback preview

Added reusable Feedback page to both standalone and Phonk builds. Destination is configured locally or via SerenityFeedbackWebhook, outside profile config and public source. Submit includes explicit draft plus game name, Place ID, Job ID and UI version; no automatic reports. Status distinguishes success/failure, drafts survive failure, requests have a 30-second local cooldown, and mentions are disabled. No live request was sent. Mock checks cover setup-without-send, HTTP 204 success, payload context and cooldown.

Pinned About profile outside its scroller; added interaction-only icon selection scale and truthful integration release text. Low Effects remains available. A public, preconfigured reporting service for all users still requires a server-side relay so the Discord credential is not shipped in client code. The preview uses per-device destination setup.

## Launcher and report categories

Launcher is 56×56, stays visible when the window is open or minimized, toggles the window on tap, and uses drag-distance detection to avoid toggling after a drag. It clamps to the viewport and saves coordinates on release. Start Minimized is saved separately from game automation defaults. Reset Saved Config replaces saved config data with defaults and resets navigation/launcher placement; Phonk still starts automation OFF.

Feedback destination setup removed from the normal form. Four categories are available. Existing locally configured owner endpoint remains supported; a shared FeedbackRelay endpoint is supported for future distribution. Relay source is prepared but not hosted; public owner routing is not yet operational.

Patterns reviewed: WindUI's recent draggable-element improvements (https://github.com/Footagesus/WindUI/releases) and Rayfield configuration persistence (https://docs.sirius.menu/rayfield/getting-started). No code copied from those libraries.
