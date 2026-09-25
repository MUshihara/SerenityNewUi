# Phonk Community V2 — manual test in the official window

Hosted only under MUshihara/SerenityNewUi/tests/phonk-community-v2.
No production Serenity loader, game payload, UI bundle or backend is changed.

1. Open +1 Phonk Evolution and run your normal official Serenity loader.
2. Execute the following separately:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/MUshihara/SerenityNewUi/main/tests/phonk-community-v2/loader.lua"))()
```

3. Global Chat appears immediately below About inside that existing window.
4. Open Global Chat and use Test warning for a local-only preview.
5. Stop test removes the added page, restores navigation order, and stops listeners.

The test rejects other place/universe IDs before requests. It does not start by itself
for normal users, other games, or new sessions. Rerunning replaces the prior v1/v2 test.
Restarting the official UI stops this attachment; run the test again afterward.

## Integration
bridge.lua locates the current official Phonk ScreenGui and validates its navigation,
content and heading structure before attaching a reversible page. It clones the About
row's visual style, adds Global Chat after it, and restores original row orders on stop.
It does not replace game callbacks, hook HTTP or change production configuration. The
test listens to native page visibility so normal navigation/search hides chat correctly.
Chat polling pauses when you leave the page or minimize the official window.
Because this is an instance-level test bridge, future changes to official UI hierarchy
may require adapting bridge.lua. A permanent release should use the shared UI's native
page API, after approval and backend review.

## Banner changes
Top-center compact card, colored left accent and information/warning marker, dismiss
button, seconds remaining and thin countdown strip. Height follows message length
between 72 and 150 pixels, rather than leaving a large empty 100-pixel card for one line.
Width fits the viewport; fonts stay at readable fixed sizes. Long messages wrap and
truncate at the bounded height. Warnings take priority, with no blur or forced sounds.

## Service behavior and limits
The live serenityhub.site announcement/chat endpoints are used. Test warning does not
publish anything. Pressing Send posts to the LIVE global chat, visible to its users.
Six existing room codes use server-provided translations when present; no external
Google requests. No independent active-count polling or stats reporting is added.
Announcements poll at ten seconds and back off on errors; open chat polls at four
seconds, moderation at fifteen. Closed chat has no message/moderation polling, so
warnings received while closed appear on the next open/check. Same warning IDs are
deduplicated in a bounded session cache; it is not persisted across rejoins.
Server identity verification, permissions and filtering remain unverified without
the backend source. A chat restriction does not disable the rest of Serenity.

## Verification
Local Lua mocks verify Phonk-only guards, exact targeting, warning deduplication,
bounded caches, official UI discovery, insertion after About, repeated execution,
stop cleanup/restored navigation, no blur and closed-chat polling suppression.
No real chat messages or announcements were sent during development. Actual Roblox
PC/mobile visuals and live-service behavior still need user testing.

## Chat styling update
Distinct General, Spanish, Indonesian, Filipino, Vietnamese and Portuguese tabs now
select their exact language instead of cycling on each click. The existing server
room codes are retained. This is the same global feed viewed with available server
translations, not a promise of separate private rooms or automatic translation.
Selected tabs are highlighted; the tab strip scrolls horizontally on narrow screens.
Message rows include avatars, escaped role/name headings, game/time metadata and
translation indicators. Search filters the already-loaded messages locally. No owner
console, delete-message or moderation privileges are added to the client. Connection
and mute status use the existing responses; no extra counter polling is introduced.

### Message card refresh
Opaque message cards, larger message text, full-width search and an overflow menu for test controls. User display names mask their second half with asterisks (Unicode-aware); search uses masked names. This is display-only masking, not backend anonymization. System messages retain the Serenity System label.

### Compact conversation bubbles
Content-sized bubbles replace full-width cards. Current account messages align right by numeric userId; all others and system messages align left. Smaller avatars, padding and metadata keep more messages visible.
