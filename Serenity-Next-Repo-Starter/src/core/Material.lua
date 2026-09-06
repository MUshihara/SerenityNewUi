local Material = {}

local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = parent
    return c
end

local function stroke(parent, color, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Transparency = transparency
    s.Thickness = 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

function Material.Shell(frame, tokens)
    frame.BackgroundColor3 = tokens.Color.Shell
    frame.BackgroundTransparency = 0.04
    frame.BorderSizePixel = 0

    corner(frame, tokens.Size.RadiusShell)
    stroke(frame, tokens.Color.Stroke, 0.38)

    local gradient = Instance.new("UIGradient")
    gradient.Rotation = 112
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(19, 29, 46)),
        ColorSequenceKeypoint.new(0.52, Color3.fromRGB(11, 18, 29)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 23, 38)),
    })
    gradient.Parent = frame
end

function Material.Section(frame, tokens)
    frame.BackgroundColor3 = tokens.Color.Surface
    frame.BackgroundTransparency = 0.10
    frame.BorderSizePixel = 0

    corner(frame, tokens.Size.RadiusSection)
    stroke(frame, tokens.Color.Stroke, 0.70)
end

function Material.Control(frame, tokens)
    frame.BackgroundColor3 = tokens.Color.Surface2
    frame.BackgroundTransparency = 0.18
    frame.BorderSizePixel = 0

    corner(frame, tokens.Size.RadiusControl)
    stroke(frame, tokens.Color.Stroke, 0.78)
end

function Material.Popup(frame, tokens)
    frame.BackgroundColor3 = tokens.Color.Surface2
    frame.BackgroundTransparency = 0.01
    frame.BorderSizePixel = 0

    corner(frame, tokens.Size.RadiusPopup)
    stroke(frame, tokens.Color.Accent, 0.50)
end

return Material
