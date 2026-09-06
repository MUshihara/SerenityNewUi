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
    shadow.Size = UDim2.new(targetSize.X.Scale, targetSize.X.Offset + 38, targetSize.Y.Scale, targetSize.Y.Offset + 38)
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
    local outer = stroke(frame, tokens.Color.StrokeBright, tokens.Material.EdgeTransparency, 1)
    outer.Name = "GlassEdge"

    local gradient = Instance.new("UIGradient")
    gradient.Rotation = 118
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(24, 34, 49)),
        ColorSequenceKeypoint.new(0.42, Color3.fromRGB(12, 18, 28)),
        ColorSequenceKeypoint.new(0.72, Color3.fromRGB(15, 20, 31)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 22, 39)),
    })
    gradient.Parent = frame

    local topGlow = Instance.new("Frame")
    topGlow.Name = "TopReflection"
    topGlow.BackgroundColor3 = Color3.fromRGB(200, 235, 255)
    topGlow.BackgroundTransparency = tokens.Material.HighlightTransparency
    topGlow.BorderSizePixel = 0
    topGlow.Position = UDim2.fromOffset(15, 0)
    topGlow.Size = UDim2.new(1, -30, 0, 1)
    topGlow.ZIndex = frame.ZIndex + 1
    topGlow.Parent = frame

    local accentReflection = Instance.new("Frame")
    accentReflection.Name = "AccentReflection"
    accentReflection.BackgroundColor3 = tokens.Color.Accent
    accentReflection.BackgroundTransparency = 0.89
    accentReflection.BorderSizePixel = 0
    accentReflection.AnchorPoint = Vector2.new(0.5, 1)
    accentReflection.Position = UDim2.new(0.5, 0, 1, 0)
    accentReflection.Size = UDim2.new(0.62, 0, 0, 1)
    accentReflection.ZIndex = frame.ZIndex + 1
    accentReflection.Parent = frame

    local accentGradient = Instance.new("UIGradient")
    accentGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.5, 0),
        NumberSequenceKeypoint.new(1, 1),
    })
    accentGradient.Parent = accentReflection

    return frame
end

function Material.Sidebar(frame, tokens)
    frame.BackgroundColor3 = tokens.Color.Sidebar
    frame.BackgroundTransparency = tokens.Material.SidebarTransparency
    frame.BorderSizePixel = 0
    corner(frame, tokens.Size.RadiusSection)
    stroke(frame, tokens.Color.Stroke, 0.82, 1)
    return frame
end

function Material.Section(frame, tokens)
    frame.BackgroundColor3 = tokens.Color.Surface
    frame.BackgroundTransparency = tokens.Material.SectionTransparency
    frame.BorderSizePixel = 0
    corner(frame, tokens.Size.RadiusSection)
    stroke(frame, tokens.Color.Stroke, 0.84, 1)

    local highlight = Instance.new("Frame")
    highlight.BackgroundColor3 = Color3.new(1, 1, 1)
    highlight.BackgroundTransparency = 0.965
    highlight.BorderSizePixel = 0
    highlight.Position = UDim2.fromOffset(10, 0)
    highlight.Size = UDim2.new(1, -20, 0, 1)
    highlight.Parent = frame
    return frame
end

function Material.Control(frame, tokens)
    frame.BackgroundColor3 = tokens.Color.Control
    frame.BackgroundTransparency = tokens.Material.ControlTransparency
    frame.BorderSizePixel = 0
    corner(frame, tokens.Size.RadiusControl)
    stroke(frame, tokens.Color.Stroke, 0.90, 1)
    return frame
end

function Material.Popup(frame, tokens)
    frame.BackgroundColor3 = tokens.Color.Popup
    frame.BackgroundTransparency = tokens.Material.PopupTransparency
    frame.BorderSizePixel = 0
    corner(frame, tokens.Size.RadiusPopup)
    stroke(frame, tokens.Color.StrokeBright, 0.68, 1)
    return frame
end

function Material.Hover(frame, tokens, active)
    frame.BackgroundColor3 = active and tokens.Color.ControlHover or tokens.Color.Control
    frame.BackgroundTransparency = active and 0.16 or tokens.Material.ControlTransparency
end

return Material
