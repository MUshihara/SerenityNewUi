# Phonk M4.23 test 1

Manual test for place 104809044319701 only. The official Serenity loader and all other games are unchanged.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/MUshihara/SerenityNewUi/62a0527f5c1e93086e6488adb16bd11d1ee9d0c5/tests/phonk-m423/loader.lua"))()
```

The loader pins the gameplay test and UI dependencies. Use in a fresh Phonk session. This starts real gameplay callbacks when switches are enabled; it is not the visual playground. All 17 switches start OFF. Seven sliders retain manifest defaults. Three paragraphs complete the 27 mapped controls. About has Stop test and close; rerunning replaces the test. Run the normal official loader to return to production.

## Provenance

UI modules and scaling derive from accepted compact-v4.lua commit 771bcc1a51b08e2224cca33391da63a499e506d1 (M4.23). The manifest replaces demonstration pages; appearance controls remain. Game Settings becomes Game Tuning visually while original control IDs retain Settings as their prefix. Appearance persistence uses Serenity_Phonk_M423_Appearance_v1.json.

Gameplay is the readable prototype/games/PhonkPreview.luau from concept-02-preview commit a4424120b5b446687883adeb0fc0a85185100943. Only its UI URL, unused session config path and provenance comment change. It is an older test baseline, NOT verified equivalent to today's obfuscated production payload. This test does not modify or bypass the production payload guard.

Supported adapter contract is limited to Phonk's Switch, Slider and Paragraph controls, Changed/Callback, Runtime.TrackCleanup/OnDestroy, Destroy, Controls and Adapter:SetLive. Unsupported control types fail before mounting. This is not yet the complete reusable Serenity library API.

## Verification

Passed local Lua syntax compilation for the UI; manifest mock checks for all 27 IDs/defaults, callback wiring, silent SetLive, callbacks blocked after destruction, and fractional Click Delay step. Wrong-game loader exits before downloads. Published files verified against local contents. The inherited Luau gameplay was not executed locally; no Roblox runtime or device was available.

## Device test

1. Join Phonk fresh and run the loader above.
2. Check phone/tablet/PC size, left navigation, category dropdown and global feature search.
3. Check all switches start OFF.
4. Enable one feature at a time, verify behavior, then disable it.
5. Test Click Delay and game tuning sliders.
6. Minimize/restore, change appearance, scroll, and rerun.
7. Use Stop test and close; confirm game controls/visual rendering restore.

Current test provides a concise About status card; it does not include the visual playground's welcome/news content, production localization, community chat, Feedback or presence reporting. Those are separate integration work.
