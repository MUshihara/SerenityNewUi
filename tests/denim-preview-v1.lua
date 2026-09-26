-- Serenity Denim UI: isolated visual prototype. No gameplay or telemetry.
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
assert(player, "Run this preview on the client")

local env = (getgenv and getgenv()) or _G
local KEY = "__SerenityDenimPreview"
if env[KEY] then env[KEY]() end

local connections = {}
local dead = false

local gui = Instance.new("ScreenGui")
gui.Name = "SerenityDenimPreview"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 120
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local function cleanup()
 if dead then return end
 dead = true
 for _, c in ipairs(connections) do c:Disconnect() end
 gui:Destroy()
 if env[KEY] == cleanup then env[KEY] = nil end
end
env[KEY] = cleanup

local function on(signal, fn)
 local c = signal:Connect(fn)
 table.insert(connections, c)
 return c
end

local C = {
 bg = Color3.fromRGB(10, 30, 46),
 side = Color3.fromRGB(8, 25, 39),
 panel = Color3.fromRGB(17, 43, 63),
 panel2 = Color3.fromRGB(21, 51, 75),
 line = Color3.fromRGB(49, 84, 111),
 lineSoft = Color3.fromRGB(36, 67, 91),
 blue = Color3.fromRGB(46, 96, 133),
 blueDeep = Color3.fromRGB(31, 74, 108),
 bright = Color3.fromRGB(78, 153, 226),
 text = Color3.fromRGB(244, 239, 226),
 muted = Color3.fromRGB(182, 202, 219),
 muted2 = Color3.fromRGB(137, 166, 190),
 green = Color3.fromRGB(99, 220, 179)
}

local function make(class, parent, props)
 local o = Instance.new(class)
 for k, v in pairs(props or {}) do o[k] = v end
 o.Parent = parent
 return o
end

local function round(o, r)
 local old = o:FindFirstChildOfClass("UICorner")
 if old then
  old.CornerRadius = UDim.new(0, r or 10)
  return old
 end
 return make("UICorner", o, {CornerRadius = UDim.new(0, r or 10)})
end

local function stroke(o, color, transparency, thickness)
 return make("UIStroke", o, {
  Color = color or C.line,
  Thickness = thickness or 1,
  Transparency = transparency == nil and 0.28 or transparency
 })
end

local function frame(parent, color, radius)
 local o = make("Frame", parent, {
  BackgroundColor3 = color or C.panel,
  BorderSizePixel = 0
 })
 round(o, radius or 10)
 stroke(o)
 return o
end

local function text(parent, value, size, color)
 return make("TextLabel", parent, {
  BackgroundTransparency = 1,
  Text = value,
  TextSize = size or 14,
  TextColor3 = color or C.text,
  Font = Enum.Font.Gotham,
  TextXAlignment = Enum.TextXAlignment.Left,
  TextYAlignment = Enum.TextYAlignment.Center,
  TextWrapped = true,
  Size = UDim2.new(1, 0, 0, 24)
 })
end

local function button(parent, value, color)
 local b = make("TextButton", parent, {
  Text = value,
  TextSize = 14,
  Font = Enum.Font.GothamMedium,
  TextColor3 = C.text,
  BackgroundColor3 = color or C.blue,
  BorderSizePixel = 0,
  AutoButtonColor = true
 })
 round(b, 8)
 return b
end

local function pad(parent, left, right, top, bottom)
 if right == nil then right = left end
 if top == nil then top = left end
 if bottom == nil then bottom = top end
 return make("UIPadding", parent, {
  PaddingLeft = UDim.new(0, left),
  PaddingRight = UDim.new(0, right),
  PaddingTop = UDim.new(0, top),
  PaddingBottom = UDim.new(0, bottom)
 })
end

local function list(parent, gap)
 return make("UIListLayout", parent, {
  Padding = UDim.new(0, gap or 8),
  SortOrder = Enum.SortOrder.LayoutOrder
 })
end

local function separator(parent, y)
 return make("Frame", parent, {
  BackgroundColor3 = C.lineSoft,
  BackgroundTransparency = 0.18,
  BorderSizePixel = 0,
  Position = UDim2.new(0, 0, 1, y or -1),
  Size = UDim2.new(1, 0, 0, 1)
 })
end

-- Lightweight opaque "liquid glass": color gradients + edge highlights only.
-- No blur, transparency, images, polling, or per-frame animation.
local function glassColors(base, strength)
 strength = strength or 1
 local cool = Color3.fromRGB(111, 171, 219)
 local shadow = Color3.fromRGB(2, 12, 22)
 return
  base:Lerp(cool, math.clamp(.16 * strength, 0, .26)),
  base:Lerp(cool, math.clamp(.055 * strength, 0, .10)),
  base:Lerp(shadow, math.clamp(.16 * strength, 0, .25))
end

local function setGlassBase(o, base, strength)
 local top, mid, bottom = glassColors(base, strength)
 o.BackgroundColor3 = base
 local g = o:FindFirstChild("SerenityGlassGradient")
 if g and g:IsA("UIGradient") then
  g.Color = ColorSequence.new({
   ColorSequenceKeypoint.new(0.00, top),
   ColorSequenceKeypoint.new(0.24, mid),
   ColorSequenceKeypoint.new(0.58, base),
   ColorSequenceKeypoint.new(1.00, bottom)
  })
 end
end

local function clearGlass(o)
 for _, name in ipairs({"SerenityGlassGradient","SerenityGlassHighlight","SerenityGlassShade"}) do
  local child = o:FindFirstChild(name)
  if child then child:Destroy() end
 end
end

local function glassify(o, base, strength, rotation, refineStroke)
 clearGlass(o)
 local g = make("UIGradient", o, {
  Name = "SerenityGlassGradient",
  Rotation = rotation or 90
 })
 setGlassBase(o, base, strength)

 local hi = make("Frame", o, {
  Name = "SerenityGlassHighlight",
  BackgroundColor3 = Color3.fromRGB(214, 236, 255),
  BackgroundTransparency = .72,
  BorderSizePixel = 0,
  Position = UDim2.fromOffset(8, 1),
  Size = UDim2.new(1, -16, 0, 1),
  ZIndex = o.ZIndex + 1
 })
 make("UIGradient", hi, {
  Transparency = NumberSequence.new({
   NumberSequenceKeypoint.new(0.00, 1.00),
   NumberSequenceKeypoint.new(0.16, .48),
   NumberSequenceKeypoint.new(0.52, .28),
   NumberSequenceKeypoint.new(0.84, .62),
   NumberSequenceKeypoint.new(1.00, 1.00)
  })
 })

 local shade = make("Frame", o, {
  Name = "SerenityGlassShade",
  BackgroundColor3 = Color3.fromRGB(1, 9, 16),
  BackgroundTransparency = .58,
  BorderSizePixel = 0,
  AnchorPoint = Vector2.new(0, 1),
  Position = UDim2.new(0, 8, 1, -1),
  Size = UDim2.new(1, -16, 0, 1),
  ZIndex = o.ZIndex + 1
 })
 make("UIGradient", shade, {
  Transparency = NumberSequence.new({
   NumberSequenceKeypoint.new(0.00, 1.00),
   NumberSequenceKeypoint.new(0.20, .68),
   NumberSequenceKeypoint.new(0.50, .50),
   NumberSequenceKeypoint.new(0.80, .72),
   NumberSequenceKeypoint.new(1.00, 1.00)
  })
 })

 if refineStroke ~= false then
  local edge = o:FindFirstChildOfClass("UIStroke")
  if edge then
   edge.Color = base:Lerp(C.bright, .32)
   edge.Transparency = .26
  end
 end
 return g
end

-- Draw icons using native GUI geometry only; no remote assets.
local function icon(parent, kind, x, y, size, color)
 local root = make("Frame", parent, {
  Name = "Icon_" .. kind,
  BackgroundTransparency = 1,
  Position = UDim2.fromOffset(x, y),
  Size = UDim2.fromOffset(size, size)
 })
 local c = color or C.muted
 local function line(x1, y1, x2, y2, thickness)
  local dx, dy = x2 - x1, y2 - y1
  make("Frame", root, {
   BorderSizePixel = 0,
   BackgroundColor3 = c,
   AnchorPoint = Vector2.new(0.5, 0.5),
   Position = UDim2.fromScale((x1 + x2) / 2, (y1 + y2) / 2),
   Size = UDim2.new(0, math.sqrt(dx * dx + dy * dy) * size, 0, thickness or 1.6),
   Rotation = math.deg(math.atan2(dy, dx))
  })
 end
 local function box(x1, y1, w, h, r)
  local f = make("Frame", root, {
   BackgroundTransparency = 1,
   Position = UDim2.fromScale(x1, y1),
   Size = UDim2.fromScale(w, h)
  })
  round(f, r or 2)
  stroke(f, c, 0, 1.4)
  return f
 end
 if kind == "star" then
  local points = {{.5,.03},{.61,.38},{.97,.5},{.61,.62},{.5,.97},{.39,.62},{.03,.5},{.39,.38}}
  for i, p in ipairs(points) do
   local q = points[i % #points + 1]
   line(p[1], p[2], q[1], q[2], 1.7)
  end
 elseif kind == "Dashboard" then
  for _, v in ipairs({{.12,.12},{.58,.12},{.12,.58},{.58,.58}}) do box(v[1],v[2],.29,.29) end
 elseif kind == "About" or kind == "clock" then
  box(.08,.08,.84,.84,100)
  if kind == "clock" then
   line(.5,.25,.5,.5)
   line(.5,.5,.7,.65)
  else
   line(.5,.46,.5,.73)
   box(.47,.26,.05,.05)
  end
 elseif kind == "Automation" then
  line(.1,.75,.4,.45)
  line(.4,.45,.6,.62)
  line(.6,.62,.9,.2)
  line(.65,.2,.9,.2)
  line(.9,.2,.9,.45)
 elseif kind == "Inventory" then
  box(.1,.24,.8,.65)
  line(.1,.43,.9,.43)
  line(.36,.12,.64,.12)
  line(.36,.12,.36,.24)
  line(.64,.12,.64,.24)
 elseif kind == "Settings" then
  for i, v in ipairs({.23,.5,.77}) do
   line(.1,v,.9,v)
   local px = i == 2 and .65 or .35
   box(px-.08,v-.09,.16,.18,3)
  end
 elseif kind == "user" then
  box(.34,.1,.32,.32,100)
  box(.17,.55,.66,.35,7)
 elseif kind == "doc" then
  box(.22,.1,.56,.8)
  line(.35,.35,.65,.35)
  line(.35,.5,.65,.5)
  line(.35,.65,.58,.65)
 elseif kind == "down" then
  line(.22,.35,.5,.65)
  line(.5,.65,.78,.35)
 elseif kind == "close" then
  line(.25,.25,.75,.75)
  line(.25,.75,.75,.25)
 elseif kind == "minus" then
  line(.2,.5,.8,.5)
 elseif kind == "search" then
  box(.12,.12,.56,.56,100)
  line(.61,.61,.88,.88,1.8)
 end
 return root
end

local shell = frame(gui, C.bg, 12)
shell.AnchorPoint = Vector2.new(0.5, 0.5)
shell.Position = UDim2.fromScale(0.5, 0.5)
local shellStroke = shell:FindFirstChildOfClass("UIStroke")
if shellStroke then
 shellStroke.Color = Color3.fromRGB(58, 105, 141)
 shellStroke.Transparency = 0.12
 shellStroke.Thickness = 1.2
end
glassify(shell, C.bg, .72, 90, true)

local header = make("Frame", shell, {
 BackgroundColor3 = Color3.fromRGB(12, 35, 52),
 BorderSizePixel = 0,
 Size = UDim2.new(1, 0, 0, 50)
})
round(header, 12)
-- Fill lower header corners so only the shell controls outer rounding.
make("Frame", header, {
 BackgroundColor3 = Color3.fromRGB(12, 35, 52),
 BorderSizePixel = 0,
 Position = UDim2.new(0, 0, 1, -10),
 Size = UDim2.new(1, 0, 0, 10)
})
glassify(header, Color3.fromRGB(12, 35, 52), 1.08, 8, false)
icon(header, "star", 14, 13, 24, C.text)

local title = text(header, "SERENITY HUB", 20)
title.Font = Enum.Font.GothamBold
title.Position = UDim2.fromOffset(46, 6)
title.Size = UDim2.new(0, 175, 0, 36)

local previewPill = make("Frame", header, {
 BackgroundColor3 = C.blueDeep,
 BorderSizePixel = 0,
 Position = UDim2.fromOffset(204, 12),
 Size = UDim2.fromOffset(72, 26)
})
round(previewPill, 13)
stroke(previewPill, C.bright, 0.42, 1)
glassify(previewPill, C.blueDeep, 1.15, 18, true)
local previewText = text(previewPill, "Preview", 11, C.muted)
previewText.TextXAlignment = Enum.TextXAlignment.Center
previewText.Size = UDim2.fromScale(1, 1)

local searchBtn = make("TextButton", header, {
 Text = "",
 BackgroundTransparency = 1,
 BorderSizePixel = 0,
 AutoButtonColor = false,
 Size = UDim2.fromOffset(32, 32),
 Position = UDim2.new(1, -112, 0, 9)
})
icon(searchBtn, "search", 6, 6, 20, C.muted)

local mini = button(header, "", C.blueDeep)
mini.Size = UDim2.fromOffset(32, 32)
mini.Position = UDim2.new(1, -74, 0, 9)
glassify(mini, C.blueDeep, .95, 90, false)
icon(mini, "minus", 7, 7, 18, C.muted)

local close = button(header, "", C.blueDeep)
close.Size = UDim2.fromOffset(32, 32)
close.Position = UDim2.new(1, -36, 0, 9)
glassify(close, C.blueDeep, .95, 90, false)
icon(close, "close", 7, 7, 18, C.muted)
on(close.Activated, cleanup)

local sidebar = make("Frame", shell, {
 BackgroundColor3 = C.side,
 BorderSizePixel = 0
})
round(sidebar, 12)
glassify(sidebar, C.side, .55, 90, false)
make("Frame", sidebar, {BackgroundColor3=C.side, BorderSizePixel=0, Size=UDim2.new(1,0,0,12)})
make("Frame", sidebar, {
 BackgroundColor3 = C.line,
 BackgroundTransparency = .48,
 BorderSizePixel = 0,
 Position = UDim2.new(1, -1, 0, 10),
 Size = UDim2.new(0, 1, 1, -20)
})
make("Frame", header, {
 BackgroundColor3 = C.line,
 BackgroundTransparency = .4,
 BorderSizePixel = 0,
 Position = UDim2.new(0, 12, 1, -1),
 Size = UDim2.new(1, -24, 0, 1)
})

local nav = make("Frame", sidebar, {BackgroundTransparency=1})
pad(nav, 8, 8, 9, 7)
local navLayout = list(nav, 6)

local sidebarCard = frame(sidebar, C.panel, 9)
glassify(sidebarCard, C.panel, .92, 82, true)
sidebarCard.AnchorPoint = Vector2.new(0, 1)
sidebarCard.Position = UDim2.new(0, 9, 1, -10)
sidebarCard.Size = UDim2.new(1, -18, 0, 58)
icon(sidebarCard, "user", 10, 16, 23, C.muted)
local sideCardTitle = text(sidebarCard, "Preview", 12)
sideCardTitle.Font = Enum.Font.GothamMedium
sideCardTitle.Position = UDim2.fromOffset(41, 7)
sideCardTitle.Size = UDim2.new(1, -48, 0, 21)
local sideCardSub = text(sidebarCard, "Local UI only", 11, C.green)
sideCardSub.Size = UDim2.new(1, -57, 0, 19)
local dot = make("Frame", sidebarCard, {
 BackgroundColor3 = C.green,
 BorderSizePixel = 0,
 Position = UDim2.fromOffset(41, 36),
 Size = UDim2.fromOffset(6, 6)
})
round(dot, 6)
sideCardSub.Position = UDim2.fromOffset(52, 28)

local foot = text(sidebar, "PC preview · v8", 10, C.muted2)
foot.AnchorPoint = Vector2.new(0, 1)
foot.Position = UDim2.new(0, 12, 1, -73)
foot.Size = UDim2.new(1, -24, 0, 18)

local body = make("ScrollingFrame", shell, {
 BackgroundTransparency = 1,
 BorderSizePixel = 0,
 ScrollBarThickness = 4,
 ScrollBarImageColor3 = C.blue,
 CanvasSize = UDim2.new(),
 AutomaticCanvasSize = Enum.AutomaticSize.Y,
 ScrollingDirection = Enum.ScrollingDirection.Y
})
pad(body, 12)
list(body, 8)

local pageHead = make("Frame", body, {
 BackgroundTransparency = 1,
 Size = UDim2.new(1,0,0,46),
 LayoutOrder = 1
})
local heading = text(pageHead, "Dashboard", 23)
heading.Font = Enum.Font.GothamBold
heading.Size = UDim2.new(1,0,0,28)
local subtitle = text(pageHead, "Design preview / no gameplay actions", 12, C.muted)
subtitle.Position = UDim2.fromOffset(0, 27)
subtitle.Size = UDim2.new(1,0,0,18)

local stats = make("Frame", body, {
 BackgroundTransparency = 1,
 Size = UDim2.new(1,0,0,68),
 LayoutOrder = 3
})
local statCards = {}
local statData = {{"Session","Preview","clock"},{"Active now","—","user"},{"Status","UI only","Automation"}}
for i, info in ipairs(statData) do
 local card = frame(stats, C.panel, 10)
 glassify(card, C.panel, .88, 82, true)
 card.Size = UDim2.new(1/3, -7, 1, 0)
 card.Position = UDim2.new((i-1)/3, (i-1)*3.5, 0, 0)
 local tile = make("Frame", card, {
  BackgroundColor3 = i == 3 and Color3.fromRGB(19, 68, 67) or C.blueDeep,
  BorderSizePixel = 0,
  Position = UDim2.fromOffset(10, 17),
  Size = UDim2.fromOffset(34, 34)
 })
 round(tile, 8)
 icon(tile, info[3], 7, 7, 20, i == 3 and C.green or C.muted)
 local label = text(card, info[1], 11, C.muted)
 label.Position = UDim2.fromOffset(53, 7)
 label.Size = UDim2.new(1, -60, 0, 20)
 local value = text(card, info[2], 18, i == 3 and C.green or C.text)
 value.Position = UDim2.fromOffset(53, 26)
 value.Size = UDim2.new(1, -60, 0, 26)
 value.Font = Enum.Font.GothamBold
 statCards[i] = card
end

local welcome = frame(body, C.panel:Lerp(C.blue, .65), 10)
welcome.LayoutOrder = 4
welcome.Size = UDim2.new(1,0,0,48)
glassify(welcome, C.panel:Lerp(C.blue, .65), 1.28, 14, true)
icon(welcome, "star", 13, 13, 23, C.text)
local welcomeTitle = text(welcome, "Welcome back", 14)
welcomeTitle.Font = Enum.Font.GothamBold
welcomeTitle.Position = UDim2.fromOffset(47, 5)
welcomeTitle.Size = UDim2.new(1,-58,0,21)
local welcomeText = text(welcome, "Choose a category to continue exploring the preview.", 11, C.muted)
welcomeText.Position = UDim2.fromOffset(47, 24)
welcomeText.Size = UDim2.new(1,-58,0,18)

local columns = make("Frame", body, {
 Name = "Columns",
 BackgroundTransparency = 1,
 Size = UDim2.new(1,0,0,300),
 LayoutOrder = 5
})

local controls = frame(columns, C.panel, 10)
glassify(controls, C.panel, .78, 88, true)
controls.AutomaticSize = Enum.AutomaticSize.Y
controls.Size = UDim2.new(1,0,0,0)
pad(controls, 12)
list(controls, 0)
local controlTitle = text(controls, "Quick settings", 16)
controlTitle.Font = Enum.Font.GothamBold
controlTitle.LayoutOrder = 0
controlTitle.Size = UDim2.new(1,0,0,30)

local rowOrder = 0
local function row(label, description, height)
 rowOrder += 1
 local h = height or 46
 local r = make("Frame", controls, {
  BackgroundTransparency = 1,
  Size = UDim2.new(1,0,0,h),
  LayoutOrder = rowOrder
 })
 local l = text(r, label, 13)
 l.Font = Enum.Font.GothamMedium
 l.Position = UDim2.fromOffset(0, 3)
 l.Size = UDim2.new(1,-118,0,21)
 if description then
  local d = text(r, description, 11, C.muted)
  d.Position = UDim2.fromOffset(0, 22)
  d.Size = UDim2.new(1,-118,0,18)
 end
 separator(r, -1)
 return r
end

local function toggle(label, description, initial, callback)
 local r = row(label, description, 48)
 local b = button(r, "", C.line)
 b.Size = UDim2.fromOffset(44, 24)
 b.Position = UDim2.new(1, -44, 0.5, -12)
 round(b, 13)
 local knob = make("Frame", b, {
  Size = UDim2.fromOffset(18,18),
  BackgroundColor3 = C.text,
  BorderSizePixel = 0
 })
 round(knob, 11)
 local value = initial
 local function paint()
  b.BackgroundColor3 = value and C.bright or C.line
  knob.Position = UDim2.fromOffset(value and 23 or 3, 3)
 end
 local function flip()
  value = not value
  paint()
  if callback then callback(value) end
 end
 paint()
 local hit = make("TextButton", r, {
  Name = "ToggleHit",
  Text = "",
  BackgroundTransparency = 1,
  Size = UDim2.fromScale(1,1),
  ZIndex = 3
 })
 on(hit.Activated, flip)
 on(b.Activated, flip)
end

toggle("Auto collect (demo)", "Layout-only interaction; no gameplay action.", true)
toggle("Auto sell (demo)", "Preview state only; no items are modified.", false)

local dropRow = row("Effects (demo)", "Visual preference preview only.", 50)
local drop = button(dropRow, "", C.blueDeep)
glassify(drop, C.blueDeep, .88, 90, false)
drop.Size = UDim2.fromOffset(112, 32)
drop.Position = UDim2.new(1, -112, 0.5, -16)
stroke(drop, C.line, 0.2, 1)
local dropLabel = text(drop, "Reduced", 12)
dropLabel.Position = UDim2.fromOffset(10,0)
dropLabel.Size = UDim2.new(1,-34,1,0)
local dropArrow = icon(drop, "down", 89, 8, 16, C.muted)

local choices = frame(controls, C.side, 8)
glassify(choices, C.side, .72, 90, true)
choices.BackgroundTransparency = 0
choices.Size = UDim2.new(1,0,0,88)
choices.Visible = false
choices.LayoutOrder = rowOrder + 1
rowOrder += 1
pad(choices, 6)
list(choices, 6)
local choiceButtons = {}
for _, label in ipairs({"Reduced","Standard"}) do
 local b = button(choices, label, label == "Reduced" and C.blue or C.side)
 b.Size = UDim2.new(1,0,0,35)
 choiceButtons[label] = b
 on(b.Activated, function()
  dropLabel.Text = label
  choices.Visible = false
  dropArrow.Rotation = 0
  for name, other in pairs(choiceButtons) do
   other.BackgroundColor3 = name == label and C.blue or C.side
  end
 end)
end
on(drop.Activated, function()
 choices.Visible = not choices.Visible
 dropArrow.Rotation = choices.Visible and 180 or 0
end)

local sliderRow = row("Accent intensity", "Adjusts this preview's welcome-strip tint.", 58)
local track = make("TextButton", sliderRow, {
 Text = "",
 AutoButtonColor = false,
 BorderSizePixel = 0,
 BackgroundColor3 = C.line,
 Position = UDim2.new(0,0,1,-17),
 Size = UDim2.new(1,-55,0,7)
})
round(track, 4)
local fill = make("Frame", track, {
 BackgroundColor3 = C.bright,
 BorderSizePixel = 0,
 Size = UDim2.fromScale(.65,1)
})
round(fill,4)
local sliderKnob = make("Frame", track, {
 BackgroundColor3 = C.text,
 BorderSizePixel = 0,
 Size = UDim2.fromOffset(18,18),
 AnchorPoint = Vector2.new(.5,.5),
 Position = UDim2.fromScale(.65,.5)
})
round(sliderKnob,9)
local pct = text(sliderRow, "65%", 12, C.muted)
pct.Size = UDim2.fromOffset(48,24)
pct.Position = UDim2.new(1,-48,1,-26)
pct.TextXAlignment = Enum.TextXAlignment.Right
local sliderHit = make("TextButton", sliderRow, {
 Name = "SliderHit",
 Text = "",
 BackgroundTransparency = 1,
 Position = UDim2.new(0,0,1,-30),
 Size = UDim2.new(1,-55,0,30),
 ZIndex = 3
})
local dragging = nil
local function slide(x)
 local v = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
 fill.Size = UDim2.fromScale(v,1)
 sliderKnob.Position = UDim2.fromScale(v,.5)
 pct.Text = tostring(math.floor(v * 100 + .5)) .. "%"
 setGlassBase(welcome, C.panel:Lerp(C.blue, v), 1.28)
end
on(sliderHit.InputBegan, function(input)
 if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
  dragging = input
  slide(input.Position.X)
 end
end)
on(UIS.InputChanged, function(input)
 if dragging and (input == dragging or (dragging.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement)) then
  slide(input.Position.X)
 end
end)
on(UIS.InputEnded, function(input)
 if input == dragging then dragging = nil end
end)

local updates = frame(columns, C.panel, 10)
glassify(updates, C.panel, .80, 86, true)
updates.Size = UDim2.new(1,0,0,252)
pad(updates, 12)
local upd = text(updates, "What's new", 16)
upd.Font = Enum.Font.GothamBold
upd.Size = UDim2.new(1,0,0,28)

local updateRows = {}
local updatesData = {
 {"Refined denim surfaces", "Softer contrast, cleaner borders."},
 {"Stronger navigation", "Clearer active states and spacing."},
 {"Desktop readability", "Native-size text with less crowding."}
}
for i, info in ipairs(updatesData) do
 local item = make("Frame", updates, {
  BackgroundTransparency = 1,
  Position = UDim2.fromOffset(0, 30 + (i-1)*52),
  Size = UDim2.new(1,0,0,52)
 })
 local tile = make("Frame", item, {
  BackgroundColor3 = C.blueDeep,
  BorderSizePixel = 0,
  Position = UDim2.fromOffset(0, 9),
  Size = UDim2.fromOffset(30, 30)
 })
 round(tile, 7)
 icon(tile, "doc", 6, 6, 18, C.muted)
 local a = text(item, info[1], 13)
 a.Font = Enum.Font.GothamMedium
 a.Position = UDim2.fromOffset(40, 2)
 a.Size = UDim2.new(1,-40,0,22)
 local b = text(item, info[2], 11, C.muted)
 b.Position = UDim2.fromOffset(40, 22)
 b.Size = UDim2.new(1,-40,0,24)
 if i < #updatesData then separator(item, -1) end
 updateRows[i] = item
end

local viewUpdates = button(updates, "View updates", C.blueDeep)
glassify(viewUpdates, C.blueDeep, 1.02, 90, false)
viewUpdates.Size = UDim2.fromOffset(98, 30)
viewUpdates.Position = UDim2.new(1, -98, 1, -30)
viewUpdates.TextSize = 12
stroke(viewUpdates, C.line, 0.24, 1)

local community = frame(body, C.panel, 10)
glassify(community, C.panel, .80, 88, true)
community.LayoutOrder = 6
community.Size = UDim2.new(1,0,0,54)
local communityTile = make("Frame", community, {
 BackgroundColor3 = C.blueDeep,
 BorderSizePixel = 0,
 Position = UDim2.fromOffset(10, 10),
 Size = UDim2.fromOffset(34,34)
})
round(communityTile,8)
icon(communityTile,"user",7,7,20,C.muted)
local communityTitle = text(community,"Community",13)
communityTitle.Font = Enum.Font.GothamMedium
communityTitle.Position = UDim2.fromOffset(54,5)
communityTitle.Size = UDim2.new(1,-174,0,21)
local communitySub = text(community,"News and updates preview",11,C.muted)
communitySub.Position = UDim2.fromOffset(54,25)
communitySub.Size = UDim2.new(1,-174,0,18)

local notice = frame(shell, C.panel2, 10)
glassify(notice, C.panel2, 1.04, 76, true)
notice.Visible = false
notice.ZIndex = 20
local nt = text(notice,"Serenity preview",14)
nt.Font = Enum.Font.GothamBold
nt.ZIndex = 21
nt.Position = UDim2.fromOffset(12,5)
nt.Size = UDim2.new(1,-48,0,24)
local nb = text(notice,"Notification placement test only.",12,C.muted)
nb.ZIndex = 21
nb.Position = UDim2.fromOffset(12,29)
nb.Size = UDim2.new(1,-24,0,30)
local nx = button(notice,"",C.blueDeep)
nx.ZIndex = 22
nx.Size = UDim2.fromOffset(28,28)
nx.Position = UDim2.new(1,-34,0,6)
icon(nx,"close",5,5,18,C.muted)
on(nx.Activated,function() notice.Visible=false end)

local test = button(community,"Preview notice",C.blue)
glassify(test, C.blue, 1.04, 90, false)
test.Size = UDim2.fromOffset(104,32)
test.Position = UDim2.new(1,-114,0,11)
test.TextSize = 12
on(test.Activated,function()
 nt.Text = "Serenity preview"
 nb.Text = "Notification placement test only."
 notice.Visible = not notice.Visible
end)
on(viewUpdates.Activated,function()
 nt.Text = "What's new"
 nb.Text = "This button is visual-only in the isolated preview."
 notice.Visible = true
end)
on(searchBtn.Activated,function()
 nt.Text = "Search preview"
 nb.Text = "Search is not connected in this visual prototype."
 notice.Visible = true
end)

local inventoryInfo = frame(body, C.panel, 10)
glassify(inventoryInfo, C.panel, .78, 88, true)
inventoryInfo.LayoutOrder = 5
inventoryInfo.Size = UDim2.new(1,0,0,112)
inventoryInfo.Visible = false
pad(inventoryInfo,16)
local inventoryTitle = text(inventoryInfo,"Inventory preview",18)
inventoryTitle.Font = Enum.Font.GothamBold
local inventoryDesc = text(inventoryInfo,"This isolated visual test does not read or modify your items. It exists only to evaluate layout, typography, controls, and spacing.",14,C.muted)
inventoryDesc.Position = UDim2.fromOffset(0,34)
inventoryDesc.Size = UDim2.new(1,0,0,70)

local fontBar = frame(body, C.panel, 10)
glassify(fontBar, C.panel, .78, 88, true)
fontBar.Visible = false
fontBar.Name = "FontComparison"
fontBar.LayoutOrder = 2
fontBar.Size = UDim2.new(1,0,0,74)
local fontStatus = text(fontBar,"Selected font: Ubuntu",12,C.muted)
fontStatus.Position = UDim2.fromOffset(11,5)
fontStatus.Size = UDim2.new(1,-22,0,21)
local fontOptions = {
 {label="Roboto",name="Roboto",family="Roboto"},
 {label="Montserrat",name="Montserrat",family="Montserrat"},
 {label="Ubuntu",name="Ubuntu",family="Ubuntu"}
}
local fontButtons = {}
for i, option in ipairs(fontOptions) do
 local b = button(fontBar,option.label,C.side)
 b.Position = UDim2.new((i-1)/3,7,0,31)
 b.Size = UDim2.new(1/3,-14,0,34)
 stroke(b,C.line,0.3,1)
 fontButtons[i] = b
end

local navButtons = {}
local navIcons = {}
local navMarkers = {}
local navLabels = {}
local selected = "Dashboard"
local arrangeColumns

for _, name in ipairs({"About","Dashboard","Automation","Inventory","Settings"}) do
 local b = button(nav,"",C.side)
 b.Size = UDim2.new(1,0,0,38)
 navIcons[name] = icon(b,name,10,10,18,name=="Dashboard" and C.text or C.muted)
 local caption = text(b,name,14)
 caption.Position = UDim2.fromOffset(38,0)
 caption.Size = UDim2.new(1,-44,1,0)
 navLabels[name] = caption
 navButtons[name] = b
 local mark = make("Frame",b,{
  BackgroundColor3 = C.bright,
  BorderSizePixel = 0,
  Position = UDim2.fromOffset(0,8),
  Size = UDim2.fromOffset(3,22),
  Visible = name == "Dashboard"
 })
 round(mark,2)
 navMarkers[name] = mark
 on(b.MouseEnter,function()
  if selected ~= name then b.BackgroundColor3 = C.panel2 end
 end)
 on(b.MouseLeave,function()
  if selected ~= name then b.BackgroundColor3 = C.side end
 end)
 on(b.Activated,function()
  selected = name
  choices.Visible = false
  dropArrow.Rotation = 0
  fontBar.Visible = name == "Settings"
  stats.Visible = name == "Dashboard" or name == "About"
  welcome.Visible = name == "Dashboard" or name == "About"
  columns.Visible = name ~= "Inventory"
  controls.Visible = name ~= "About"
  updates.Visible = name == "Dashboard" or name == "About"
  community.Visible = name == "Dashboard" or name == "About"
  inventoryInfo.Visible = name == "Inventory"
  heading.Text = name
  if arrangeColumns then arrangeColumns() end
  if name == "Dashboard" then
   subtitle.Text = "Design preview / no gameplay actions"
  elseif name == "Settings" then
   subtitle.Text = "Typography and control layout preview • No gameplay actions"
  else
   subtitle.Text = name .. " layout preview • No gameplay actions"
  end
  for n, other in pairs(navButtons) do
   local active = n == name
   if active then
    glassify(other, C.blue, .94, 90, false)
   else
    clearGlass(other)
    other.BackgroundColor3 = C.side
   end
   navMarkers[n].Visible = active
   navLabels[n].TextColor3 = active and C.text or C.muted
   for _, child in ipairs(navIcons[n]:GetDescendants()) do
    if child:IsA("Frame") and child.BackgroundTransparency < 1 then
     child.BackgroundColor3 = active and C.text or C.muted
    elseif child:IsA("UIStroke") then
     child.Color = active and C.text or C.muted
    end
   end
  end
  body.CanvasPosition = Vector2.new(0,0)
 end)
 if name == "Dashboard" then
  glassify(b, C.blue, .94, 90, false)
 else
  b.BackgroundColor3 = C.side
 end
 caption.TextColor3 = name == "Dashboard" and C.text or C.muted
end

local minimized = false
local HEADER_H = 50
local function layout()
 local vp = gui.AbsoluteSize
 if vp.X < 1 or vp.Y < 1 then vp = workspace.CurrentCamera.ViewportSize end
 local w = math.min(860, math.floor(vp.X * .80))
 if vp.X < 620 then w = math.max(1, vp.X - 20) end
 local h = math.min(580, math.floor(vp.Y * .82))
 if vp.Y < 540 then h = math.max(1, vp.Y - 20) end
 local narrow = w < 630
 local compactNav = w < 710
 local sideWidth = compactNav and 54 or 154
 local shownH = minimized and HEADER_H or h
 shell.Size = UDim2.fromOffset(w, shownH)
 sidebar.Visible = not minimized
 body.Visible = not minimized
 sidebar.Position = UDim2.fromOffset(0,HEADER_H)
 sidebar.Size = UDim2.new(0,sideWidth,1,-HEADER_H)
 nav.Size = UDim2.new(1,0,1, compactNav and -14 or -94)
 navLayout.FillDirection = Enum.FillDirection.Vertical
 navLayout.Padding = UDim.new(0,5)
 foot.Visible = not compactNav
 sidebarCard.Visible = not compactNav
 for name,b in pairs(navButtons) do
  b.Size = UDim2.new(1,0,0,38)
  navLabels[name].Visible = not compactNav
  navIcons[name].Position = UDim2.fromOffset(compactNav and 10 or 10,10)
 end
 body.Position = UDim2.fromOffset(sideWidth,HEADER_H)
 body.Size = UDim2.new(1,-sideWidth,1,-HEADER_H)
 previewPill.Visible = w >= 560
 searchBtn.Visible = w >= 680
 if arrangeColumns then arrangeColumns() end
 for _, card in ipairs(statCards) do
  local tile = card:FindFirstChildWhichIsA("Frame")
  for _, child in ipairs(card:GetChildren()) do
   if child:IsA("TextLabel") then
    child.Position = UDim2.fromOffset(narrow and 10 or 53, child.Position.Y.Offset)
    child.Size = UDim2.new(1, narrow and -20 or -60, 0, child.Size.Y.Offset)
   end
  end
  if tile then tile.Visible = not narrow end
 end
 notice.Size = UDim2.fromOffset(math.min(286,w-24),72)
 notice.Position = UDim2.new(1,-12,0,HEADER_H+10)
 notice.AnchorPoint = Vector2.new(1,0)
 if minimized then notice.Visible = false end
 title.TextSize = w < 420 and 18 or 20
 local px, py = shell.Position.X, shell.Position.Y
 local cx = px.Scale * vp.X + px.Offset
 local cy = py.Scale * vp.Y + py.Offset
 shell.Position = UDim2.fromOffset(
  math.clamp(cx, w/2, math.max(w/2, vp.X-w/2)),
  math.clamp(cy, shownH/2, math.max(shownH/2, vp.Y-shownH/2))
 )
end

arrangeColumns = function()
 local stacked = shell.Size.X.Offset < 710
 local ch = math.max(252, controls.AbsoluteSize.Y)
 local dashboard = selected == "Dashboard"
 if selected == "About" then
  updates.Position = UDim2.fromOffset(0,0)
  updates.Size = UDim2.new(1,0,0,236)
  columns.Size = UDim2.new(1,0,0,236)
 elseif dashboard then
  controls.Size = UDim2.new(stacked and 1 or .61, stacked and 0 or -5, 0, 0)
  controls.Position = UDim2.fromOffset(0,0)
  updates.Position = stacked and UDim2.fromOffset(0,ch+8) or UDim2.new(.61,5,0,0)
  updates.Size = UDim2.new(stacked and 1 or .39, stacked and 0 or -5, 0, math.max(ch,252))
  columns.Size = UDim2.new(1,0,0, stacked and ch + math.max(ch,252) + 8 or math.max(ch,252))
 else
  controls.Size = UDim2.new(1,0,0,0)
  controls.Position = UDim2.fromOffset(0,0)
  columns.Size = UDim2.new(1,0,0,ch)
 end
end

on(controls:GetPropertyChangedSignal("AbsoluteSize"), arrangeColumns)
on(gui:GetPropertyChangedSignal("AbsoluteSize"), layout)
on(body:GetPropertyChangedSignal("CanvasPosition"), function()
 if choices.Visible and selected ~= "Dashboard" and selected ~= "Automation" and selected ~= "Settings" then
  choices.Visible = false
  dropArrow.Rotation = 0
 end
end)

on(mini.Activated,function()
 local oldHeight = shell.Size.Y.Offset
 minimized = not minimized
 layout()
 local newHeight = shell.Size.Y.Offset
 local vp = gui.AbsoluteSize
 local center = shell.Position.Y.Offset + (newHeight-oldHeight)/2
 shell.Position = UDim2.fromOffset(
  shell.Position.X.Offset,
  math.clamp(center,newHeight/2,math.max(newHeight/2,vp.Y-newHeight/2))
 )
end)

-- Drag only from the title/header area and preserve viewport bounds.
local dragInput, dragStart, windowStart
local function startDrag(input)
 if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
  dragInput = input
  dragStart = input.Position
  windowStart = shell.AbsolutePosition
 end
end
header.Active = true
title.Active = true
on(header.InputBegan,startDrag)
on(title.InputBegan,startDrag)
on(UIS.InputChanged,function(input)
 if not dragInput then return end
 if input ~= dragInput and not (dragInput.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement) then return end
 local dx,dy = input.Position.X-dragStart.X,input.Position.Y-dragStart.Y
 local sz = shell.AbsoluteSize
 local vp = gui.AbsoluteSize
 local x = math.clamp(windowStart.X+dx,0,math.max(0,vp.X-sz.X))
 local y = math.clamp(windowStart.Y+dy,0,math.max(0,vp.Y-sz.Y))
 shell.Position = UDim2.fromOffset(x+sz.X/2,y+sz.Y/2)
end)
on(UIS.InputEnded,function(input)
 if input == dragInput then dragInput = nil end
end)

local cameraConnection = nil
local function watchCamera()
 if cameraConnection then cameraConnection:Disconnect() end
 if workspace.CurrentCamera then
  cameraConnection = on(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"),layout)
 end
 layout()
end
on(workspace:GetPropertyChangedSignal("CurrentCamera"),watchCamera)

-- Apply one native Roblox FontFace family while preserving weight hierarchy.
local fontNodes = {}
for _, node in ipairs(gui:GetDescendants()) do
 if node:IsA("TextLabel") or node:IsA("TextButton") then
  local weight = Enum.FontWeight.Regular
  if node.Font == Enum.Font.GothamBold then
   weight = Enum.FontWeight.Bold
  elseif node.Font == Enum.Font.GothamMedium or node.ClassName == "TextButton" then
   weight = Enum.FontWeight.Medium
  end
  fontNodes[#fontNodes+1] = {node=node,weight=weight}
 end
end

local function chooseFont(index)
 local option = fontOptions[index]
 local failed = false
 local faces = {}
 for _, entry in ipairs(fontNodes) do
  local ok = pcall(function()
   if not faces[entry.weight] then
    faces[entry.weight] = Font.new(
     "rbxasset://fonts/families/" .. option.family .. ".json",
     entry.weight,
     Enum.FontStyle.Normal
    )
   end
   entry.node.FontFace = faces[entry.weight]
  end)
  if not ok then failed = true end
 end
 fontStatus.Text = failed and "Font unavailable on this client" or ("Selected font: " .. option.name)
 for i,b in ipairs(fontButtons) do
  b.BackgroundColor3 = i == index and C.blue or C.side
 end
end
for i,b in ipairs(fontButtons) do
 on(b.Activated,function() chooseFont(i) end)
end

chooseFont(3)
watchCamera()
arrangeColumns()

return {Destroy=cleanup}
