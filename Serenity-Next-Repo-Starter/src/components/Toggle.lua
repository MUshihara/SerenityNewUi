local Toggle = {}
Toggle.__index = Toggle

function Toggle.new(parent, deps, props)
    local tokens = deps.Tokens

    local row = Instance.new("CanvasGroup")
    row.Size = UDim2.new(1, 0, 0, tokens.Size.Control)
    row.Parent = parent
    deps.Material.Control(row, tokens)

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Position = UDim2.fromOffset(14, 8)
    title.Size = UDim2.new(1, -220, 0, 18)
    title.Text = props.Title
    title.TextColor3 = tokens.Color.Text
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = row
    deps.Typography.Apply(title, "Control", tokens)

    local desc = Instance.new("TextLabel")
    desc.BackgroundTransparency = 1
    desc.Position = UDim2.fromOffset(14, 28)
    desc.Size = UDim2.new(1, -220, 0, 16)
    desc.Text = props.Description or ""
    desc.TextColor3 = tokens.Color.TextDim
    desc.TextXAlignment = Enum.TextXAlignment.Left
    desc.Parent = row
    deps.Typography.Apply(desc, "Description", tokens)

    local switch = Instance.new("Frame")
    switch.AnchorPoint = Vector2.new(1, 0.5)
    switch.Position = UDim2.new(1, -16, 0.5, 0)
    switch.Size = UDim2.fromOffset(48, 26)
    switch.BorderSizePixel = 0
    switch.Parent = row

    local switchCorner = Instance.new("UICorner")
    switchCorner.CornerRadius = UDim.new(1, 0)
    switchCorner.Parent = switch

    local knob = Instance.new("Frame")
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Size = UDim2.fromOffset(18, 18)
    knob.BackgroundColor3 = Color3.fromRGB(247, 250, 255)
    knob.BorderSizePixel = 0
    knob.Parent = switch

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    local hit = Instance.new("TextButton")
    hit.BackgroundTransparency = 1
    hit.Text = ""
    hit.AutoButtonColor = false
    hit.Size = UDim2.fromScale(1, 1)
    hit.Parent = row

    local self = setmetatable({
        Frame = row,
        Value = not not props.Default,
        Enabled = true,
        Switch = switch,
        Knob = knob,
        Callback = props.Callback,
        Motion = deps.Motion,
        Tokens = tokens,
    }, Toggle)

    self:Set(self.Value, true)

    hit.MouseButton1Click:Connect(function()
        if not self.Enabled then return end
        self:Set(not self.Value)
    end)

    return self
end

function Toggle:Set(value, silent)
    self.Value = not not value

    self.Switch.BackgroundColor3 =
        self.Value and self.Tokens.Color.Accent or self.Tokens.Color.Stroke

    self.Motion:Tween(self.Knob, "Toggle", {
        Position = self.Value
            and UDim2.new(1, -13, 0.5, 0)
            or UDim2.fromOffset(13, 13),
    })

    if self.Callback and not silent then
        self.Callback(self.Value)
    end
end

function Toggle:SetEnabled(value)
    self.Enabled = not not value
    self.Frame.GroupTransparency = self.Enabled and 0 or 0.42
end

return Toggle
