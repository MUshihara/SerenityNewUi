local Material = {}

local SHADOW_IMAGE = "rbxassetid://1316045217"

local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = parent
    return c
end

local function stroke(parent, color, transparency, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Transparency = transparency
    s.Thickness = thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

function Material.Shadow(parent, targetSize, radius, tokens)
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "SoftShadow"
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.Position = UDim2.fromScale(0.5, 0.5)
    shadow.Size = UDim2.new(targetSize.X.Scale, targetSize.X.Offset + 42, targetSize.Y.Scale, targetSize.Y.Offset + 42)
    shadow.BackgroundTransparency = 1
    shadow.Image = SHADOW_IMAGE
    shadow.ImageColor3 = Color3.new(0, 0, 0)
    shadow.ImageTransparency = tokens.Material.ShadowTransparency
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(10, 10, 118, 118)
    shadow.ZIndex = 0
    shadow.Parent = parent
    return shadow
end

function Material.Shell(frame, tokens)
    frame.BackgroundColor3 = tokens.Color.Shell
    frame.BackgroundTransparency = tokens.Material.ShellTransparency
    frame.BorderSizePixel = 0
    corner(frame, tokens.Size.RadiusShell)

    local edge = stroke(frame, tokens.Color.StrokeBright, tokens.Material.EdgeTransparency, 1)
    edge.Name = "GlassEdge"

    local gradient = Instance.new("UIGradient")
    gradient.Rotation = 122
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 29, 43)),
        ColorSequenceKeypoint.new(0.38, Color3.fromRGB(9, 14, 22)),
        ColorSequenceKeypoint.new(0.72, Color3.fromRGB(11, 16, 25)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 17, 31)),
    })
    gradient.Parent = frame

    local reflection = Instance.new("Frame")
    reflection.Name = "TopReflection"
    reflection.BackgroundColor3 = Color3.fromRGB(218, 238, 255)
    reflection.BackgroundTransparency = tokens.Material.HighlightTransparency
    reflection.BorderSizePixel = 0
    reflection.Position = UDim2.fromOffset(16, 0)
    reflection.Size = UDim2.new(1, -32, 0, 1)
    reflection.ZIndex = frame.ZIndex + 1
    reflection.Parent = frame

    local accent = Instance.new("Frame")
    accent.Name = "AccentReflection"
    accent.AnchorPoint = Vector2.new(0.5, 1)
    accent.Position = UDim2.new(0.5, 0, 1, 0)
    accent.Size = UDim2.new(0.54, 0, 0, 1)
    accent.BackgroundColor3 = tokens.Color.Lavender
    accent.BackgroundTransparency = 0.90
    accent.BorderSizePixel = 0
    accent.ZIndex = frame.ZIndex + 1
    accent.Parent = frame

    local fade = Instance.new("UIGradient")
    fade.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.5, 0),
        NumberSequenceKeypoint.new(1, 1),
    })
    fade.Parent = accent

    return frame
end

function Material.Sidebar(frame, tokens)
    frame.BackgroundColor3 = tokens.Color.Sidebar
    frame.BackgroundTransparency = tokens.Material.SidebarTransparency
    frame.BorderSizePixel = 0
    corner(frame, tokens.Size.RadiusSection)
    stroke(frame, tokens.Color.Stroke, 0.90, 1)
    return frame
end

function Material.Section(frame, tokens)
    frame.BackgroundColor3 = tokens.Color.Surface
    frame.BackgroundTransparency = tokens.Material.SectionTransparency
    frame.BorderSizePixel = 0
    corner(frame, tokens.Size.RadiusSection)
    stroke(frame, tokens.Color.Stroke, 0.93, 1)

    local top = Instance.new("Frame")
    top.Name = "SectionHairline"
    top.BackgroundColor3 = tokens.Color.StrokeBright
    top.BackgroundTransparency = 0.94
    top.BorderSizePixel = 0
    top.Position = UDim2.fromOffset(10, 0)
    top.Size = UDim2.new(1, -20, 0, 1)
    top.Parent = frame
    return frame
end

function Material.Control(frame, tokens)
    frame.BackgroundColor3 = tokens.Color.Control
    frame.BackgroundTransparency = tokens.Material.ControlTransparency
    frame.BorderSizePixel = 0
    corner(frame, tokens.Size.RadiusControl)
    stroke(frame, tokens.Color.Stroke, 0.94, 1)
    return frame
end

function Material.Popup(frame, tokens)
    frame.BackgroundColor3 = tokens.Color.Popup
    frame.BackgroundTransparency = tokens.Material.PopupTransparency
    frame.BorderSizePixel = 0
    corner(frame, tokens.Size.RadiusPopup)
    stroke(frame, tokens.Color.StrokeBright, 0.67, 1)

    local glow = Instance.new("Frame")
    glow.BackgroundColor3 = tokens.Color.Accent
    glow.BackgroundTransparency = 0.91
    glow.BorderSizePixel = 0
    glow.Size = UDim2.new(0.42, 0, 0, 1)
    glow.Position = UDim2.fromOffset(12, 0)
    glow.Parent = frame
    return frame
end

function Material.NavTile(frame, tokens, color, selected)
    frame.BackgroundColor3 = selected and (color or tokens.Color.Accent) or tokens.Color.SurfaceSoft
    frame.BackgroundTransparency = selected and 0.03 or 0.34
    frame.BorderSizePixel = 0

    local tileCorner = frame:FindFirstChild("NavTileCorner")
    if not tileCorner then
        tileCorner = corner(frame, tokens.Size.RadiusTile)
        tileCorner.Name = "NavTileCorner"
    end

    local s = frame:FindFirstChild("NavTileStroke") or stroke(frame, selected and (color or tokens.Color.Accent) or tokens.Color.Stroke, selected and 0.48 or 0.86, 1)
    s.Name = "NavTileStroke"
    s.Color = selected and (color or tokens.Color.Accent) or tokens.Color.Stroke
    s.Transparency = selected and 0.48 or 0.86
    return frame
end

function Material.Pill(frame, tokens, accent)
    frame.BackgroundColor3 = tokens.Color.Inset
    frame.BackgroundTransparency = 0.06
    frame.BorderSizePixel = 0
    corner(frame, 8)
    stroke(frame, accent or tokens.Color.Stroke, accent and 0.70 or 0.84, 1)
    return frame
end

function Material.Banner(frame, tokens, accent)
    accent = accent or tokens.Color.Accent
    frame.BackgroundColor3 = accent
    frame.BackgroundTransparency = 0.88
    frame.BorderSizePixel = 0
    corner(frame, 10)
    stroke(frame, accent, 0.70, 1)

    local bar = Instance.new("Frame")
    bar.Name = "AccentBar"
    bar.BackgroundColor3 = accent
    bar.BorderSizePixel = 0
    bar.Position = UDim2.fromOffset(0, 9)
    bar.Size = UDim2.fromOffset(3, 44)
    bar.Parent = frame
    corner(bar, 2)
    return frame
end

function Material.Hover(frame, tokens, active)
    frame.BackgroundColor3 = active and tokens.Color.ControlHover or tokens.Color.Control
    frame.BackgroundTransparency = active and 0.30 or tokens.Material.ControlTransparency
end

return Material
