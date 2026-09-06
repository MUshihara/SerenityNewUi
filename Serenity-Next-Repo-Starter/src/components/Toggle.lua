local Toggle = {}
Toggle.__index = Toggle

function Toggle.new(parent, deps, props)
    local tokens = deps.Tokens
    props = props or {}
    local hasDescription = props.Description and props.Description ~= ""
    local height = hasDescription and tokens.Size.ControlWithDescription or tokens.Size.Control

    local row = Instance.new("CanvasGroup")
    row.Name = props.Id or "Toggle"
    row.Size = UDim2.new(1, 0, 0, height)
    row.Parent = parent
    deps.Material.Control(row, tokens)

    local titleY = hasDescription and 6 or 0
    local titleH = hasDescription and 19 or height
    deps.Typography.Label(
        row,
        "Control",
        tokens,
        props.Title or "Toggle",
        UDim2.fromOffset(13, titleY),
        UDim2.new(1, -108, 0, titleH),
        tokens.Color.Text
    )

    if hasDescription then
        deps.Typography.Label(
            row,
            "Description",
            tokens,
            props.Description,
            UDim2.fromOffset(13, 27),
            UDim2.new(1, -108, 0, 15),
            tokens.Color.TextDim
        )
    end

    if props.Settings then
        local dots = deps.Typography.Label(row, "Value", tokens, "•••", UDim2.new(1, -96, 0, 0), UDim2.fromOffset(34, height), tokens.Color.TextDim)
        dots.TextXAlignment = Enum.TextXAlignment.Center
    end

    local switch = Instance.new("Frame")
    switch.AnchorPoint = Vector2.new(1, 0.5)
    switch.Position = UDim2.new(1, -13, 0.5, 0)
    switch.Size = UDim2.fromOffset(38, 21)
    switch.BorderSizePixel = 0
    switch.Parent = row
    local switchCorner = Instance.new("UICorner")
    switchCorner.CornerRadius = UDim.new(1, 0)
    switchCorner.Parent = switch

    local knob = Instance.new("Frame")
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Size = UDim2.fromOffset(15, 15)
    knob.BackgroundColor3 = Color3.fromRGB(249, 250, 255)
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
        Enabled = props.Enabled ~= false,
        Switch = switch,
        Knob = knob,
        Callback = props.Callback,
        Motion = deps.Motion,
        Tokens = tokens,
    }, Toggle)

    function self:_render(animate)
        self.Switch.BackgroundColor3 = self.Value and self.Tokens.Color.Accent or self.Tokens.Color.Disabled
        local pos = self.Value and UDim2.new(1, -10.5, 0.5, 0) or UDim2.fromOffset(10.5, 10.5)
        if animate then
            self.Motion:Tween(self.Knob, "Toggle", {Position = pos})
        else
            self.Knob.Position = pos
        end
        self.Frame.GroupTransparency = self.Enabled and 0 or 0.45
    end

    self:_render(false)

    hit.MouseEnter:Connect(function()
        if self.Enabled then deps.Material.Hover(row, tokens, true) end
    end)
    hit.MouseLeave:Connect(function()
        deps.Material.Hover(row, tokens, false)
    end)
    hit.MouseButton1Click:Connect(function()
        if not self.Enabled then return end
        self:Set(not self.Value)
    end)

    return self
end

function Toggle:Set(value, silent)
    self.Value = not not value
    self:_render(true)
    if self.Callback and not silent then self.Callback(self.Value) end
end

function Toggle:SetEnabled(value)
    self.Enabled = not not value
    self:_render(false)
end

return Toggle
