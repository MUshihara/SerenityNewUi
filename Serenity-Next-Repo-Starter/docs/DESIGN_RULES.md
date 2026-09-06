# Serenity Next — Design Rules

## 1. Comfort target

Default desktop reference size:

- ~760–820 px wide
- ~500–540 px high
- UI Scale exposed separately from density

Default text targets:

- Brand: 15–16 px
- Page title: 22–26 px
- Section title: 14–16 px
- Control title: 12–13 px
- Description: 10–11 px
- Value: 11–12 px
- Small status: 9–10 px

Nothing important should depend on 6–8 px text.

## 2. Material stack

Base:
- near-black navy/graphite shell
- 93–97% opaque

Section:
- subtle tint difference
- minimal border

Control:
- slightly lighter/darker inset surface
- hover state via tint/brightness, not giant glow

Floating surfaces:
- dropdown
- multiselect
- tooltip
- command palette
- toast
- modal

These may use stronger translucency + backdrop blur.

## 3. Glass recipe

Roblox has no native per-Gui true backdrop blur.

We emulate premium glass with:
- tinted transparency
- subtle UIGradient
- soft external shadow
- 1 px cool stroke
- very faint top/left highlight
- optional fine noise texture
- restrained global BlurEffect only when appropriate
- darker background under text for contrast

Avoid stacking many transparent panels.

## 4. Layout

- fewer cards
- more flat grouped sections
- generous readable rows
- avoid micro-chip overload
- sections may collapse
- advanced settings should appear conditionally
- dropdowns float above layout rather than expand page height

## 5. Identity

Serenity should retain:
- cyan family as primary active state
- mint success
- lavender secondary/identity accent
- official Serenity logo
- compact utility ancestry from CompKiller

But should move beyond:
- CompKiller-like boxed density
- generic rounded dashboard cards
- tiny text
- Unicode placeholder icons
