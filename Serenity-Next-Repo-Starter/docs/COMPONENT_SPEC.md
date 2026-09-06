# Component Spec

## Window
- draggable
- minimize to launcher
- close = cleanup
- responsive scale
- optional sidebar collapse

## Sidebar
- icon + readable label
- selected state uses edge marker + tint
- no tiny two-letter placeholders in final build
- category headers optional

## Section
- title
- optional description
- optional semantic state
- collapsible
- body spacing controlled by tokens

## Toggle
- 44–48 x 24–26 px track
- explicit enabled/disabled state
- entire row clickable
- clear focus/hover feedback

## Select
- closed value field
- floating popup
- searchable when options > threshold
- disabled items supported
- refresh options without rebuilding control

## MultiSelect
- search
- ALL / CLEAR
- selected count summary
- preserve selections when refreshing options
- optional chips inside popup, not row clutter

## Slider
- large hit target
- visible value
- optional step/precision
- keyboard/gamepad later

## Status
Supported:
- READY
- RUNNING
- WAITING
- COOLDOWN
- LOCKED
- MANUAL
- WARNING
- ERROR

## Search
- Ctrl+K
- result shows Page › Section
- click switches page
- expands section
- scrolls to control
- brief highlight
