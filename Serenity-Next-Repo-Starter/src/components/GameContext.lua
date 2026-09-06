local GameContext = {}
GameContext.__index = GameContext

function GameContext.new(parent, deps, props)
    local tokens = deps.Tokens
    props = props or {}

    local button = Instance.new("TextButton")
    button.AnchorPoint = Vector2.new(0, 1)
    button.Position = UDim2.new(0, 7, 1, -7)
    button.Size = UDim2.new(1, -14, 0, tokens.Size.GameContext)
    button.BackgroundColor3 = tokens.Color.Surface
    button.BackgroundTransparency = 0.30
    button.BorderSizePixel = 0
    button.Text = ""
    button.AutoButtonColor = false
    button.Parent = parent

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 10)
    c.Parent = button

    local s = Instance.new("UIStroke")
    s.Color = tokens.Color.Stroke
    s.Transparency = 0.86
    s.Parent = button

    local thumb = Instance.new("ImageLabel")
    thumb.BackgroundColor3 = tokens.Color.Inset
    thumb.BorderSizePixel = 0
    thumb.Position = UDim2.fromOffset(8, 10)
    thumb.Size = UDim2.fromOffset(42, 42)
    thumb.Image = props.Image or ""
    thumb.ScaleType = Enum.ScaleType.Crop
    thumb.Parent = button
    local tc = Instance.new("UICorner")
    tc.CornerRadius = UDim.new(0, 9)
    tc.Parent = thumb

    local title = deps.Typography.Label(
        button,
        "Control",
        tokens,
        props.Title or "Current Game",
        UDim2.fromOffset(58, 11),
        UDim2.new(1, -66, 0, 18),
        tokens.Color.Text
    )

    local status = deps.Typography.Label(
        button,
        "Description",
        tokens,
        props.Status or "Connected",
        UDim2.fromOffset(58, 30),
        UDim2.new(1, -66, 0, 16),
        tokens.Color.Mint
    )

    local self = setmetatable({
        Frame = button,
        Thumb = thumb,
        Title = title,
        Status = status,
        Callback = props.Callback,
    }, GameContext)

    button.MouseButton1Click:Connect(function()
        if self.Callback then self.Callback() end
    end)

    return self
end

function GameContext:SetTitle(text)
    self.Title.Text = text
end

function GameContext:SetCollapsed(collapsed)
    self.Title.Visible = not collapsed
    self.Status.Visible = not collapsed
    if collapsed then
        self.Frame.Size = UDim2.new(1, -14, 0, 56)
        self.Thumb.Position = UDim2.new(0.5, -21, 0, 7)
    else
        self.Frame.Size = UDim2.new(1, -14, 0, 64)
        self.Thumb.Position = UDim2.fromOffset(8, 10)
    end
end

return GameContext
