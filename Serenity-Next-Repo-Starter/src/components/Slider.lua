local Slider = {}
Slider.__index = Slider

function Slider.new(parent, deps, props)
    local tokens = deps.Tokens
    props = props or {}

    local min = props.Min or 0
    local max = props.Max or 100
    local step = props.Step or 1
    local value = math.clamp(props.Default or min, min, max)
    local suffix = props.Suffix or ""

    local row = Instance.new("CanvasGroup")
    row.Name = props.Id or "Slider"
    row.Size = UDim2.new(1, 0, 0, tokens.Size.Slider)
    row.Parent = parent
    deps.Material.Control(row, tokens)

    deps.Typography.Label(
        row,
        "Control",
        tokens,
        props.Title or "Slider",
        UDim2.fromOffset(13, 0),
        UDim2.new(0.43, -12, 1, 0),
        tokens.Color.Text
    )

    if props.Settings then
        local dots = deps.Typography.Label(row, "Value", tokens, "•••", UDim2.new(0.39, 0, 0, 0), UDim2.fromOffset(30, tokens.Size.Slider), tokens.Color.TextDim)
        dots.TextXAlignment = Enum.TextXAlignment.Center
    end

    local valueBox = Instance.new("Frame")
    valueBox.AnchorPoint = Vector2.new(1, 0.5)
    valueBox.Position = UDim2.new(1, -12, 0.5, 0)
    valueBox.Size = UDim2.fromOffset(48, 26)
    valueBox.Parent = row
    deps.Material.Inset(valueBox, tokens)

    local valueLabel = deps.Typography.Label(valueBox, "Value", tokens, tostring(value) .. suffix, UDim2.new(), UDim2.fromScale(1, 1), tokens.Color.TextMuted)
    valueLabel.TextXAlignment = Enum.TextXAlignment.Center

    local bar = Instance.new("Frame")
    bar.AnchorPoint = Vector2.new(1, 0.5)
    bar.Position = UDim2.new(1, -71, 0.5, 0)
    bar.Size = UDim2.new(0.38, -52, 0, 4)
    bar.BackgroundColor3 = tokens.Color.Disabled
    bar.BackgroundTransparency = 0.34
    bar.BorderSizePixel = 0
    bar.Parent = row
    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(1, 0)
    barCorner.Parent = bar

    local fill = Instance.new("Frame")
    fill.BackgroundColor3 = tokens.Color.Accent
    fill.BorderSizePixel = 0
    fill.Parent = bar
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill

    local knob = Instance.new("Frame")
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Size = UDim2.fromOffset(12, 12)
    knob.BackgroundColor3 = Color3.fromRGB(247, 249, 255)
    knob.BorderSizePixel = 0
    knob.Parent = bar
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    local hit = Instance.new("TextButton")
    hit.BackgroundTransparency = 1
    hit.Text = ""
    hit.AutoButtonColor = false
    hit.AnchorPoint = Vector2.new(1, 0.5)
    hit.Position = UDim2.new(1, -65, 0.5, 0)
    hit.Size = UDim2.new(0.40, -42, 0, 28)
    hit.Parent = row

    local self = setmetatable({
        Frame = row,
        Value = value,
        Enabled = props.Enabled ~= false,
        Min = min,
        Max = max,
        Step = step,
        Suffix = suffix,
        Fill = fill,
        Knob = knob,
        Label = valueLabel,
        Callback = props.Callback,
        Tokens = tokens,
    }, Slider)

    local function roundToStep(v)
        local snapped = math.floor(((v - min) / step) + 0.5) * step + min
        return math.clamp(snapped, min, max)
    end

    function self:_render()
        local alpha = (self.Value - self.Min) / math.max(0.0001, self.Max - self.Min)
        self.Fill.Size = UDim2.new(alpha, 0, 1, 0)
        self.Knob.Position = UDim2.new(alpha, 0, 0.5, 0)
        self.Label.Text = tostring(self.Value) .. self.Suffix
        self.Frame.GroupTransparency = self.Enabled and 0 or 0.45
    end

    function self:_setFromX(x)
        if not self.Enabled then return end
        local alpha = math.clamp((x - bar.AbsolutePosition.X) / math.max(1, bar.AbsoluteSize.X), 0, 1)
        local raw = self.Min + (self.Max - self.Min) * alpha
        self:Set(roundToStep(raw))
    end

    local dragging = false
    hit.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            self:_setFromX(input.Position.X)
        end
    end)

    deps.Runtime:TrackConnection(deps.UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            self:_setFromX(input.Position.X)
        end
    end))

    deps.Runtime:TrackConnection(deps.UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))

    self:_render()
    return self
end

function Slider:Set(value, silent)
    self.Value = math.clamp(value, self.Min, self.Max)
    self:_render()
    if self.Callback and not silent then self.Callback(self.Value) end
end

function Slider:SetEnabled(value)
    self.Enabled = not not value
    self:_render()
end

return Slider
