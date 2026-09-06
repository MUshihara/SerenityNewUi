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
