local Select = {}
Select.__index = Select

local function popupPosition(deps, button, width, height)
    local scale = (deps.UIScale and deps.UIScale.Scale) or 1
    local shell = deps.WindowFrame
    local x = (button.AbsolutePosition.X - shell.AbsolutePosition.X) / scale
    local y = (button.AbsolutePosition.Y - shell.AbsolutePosition.Y) / scale
    local bw = button.AbsoluteSize.X / scale
    local bh = button.AbsoluteSize.Y / scale
    local maxW = shell.AbsoluteSize.X / scale
    local maxH = shell.AbsoluteSize.Y / scale
    return UDim2.fromOffset(
        math.clamp(x + bw - width, 8, maxW - width - 8),
        math.clamp(y + bh + 5, 8, maxH - height - 8)
    )
end

function Select.new(parent, deps, props)
    local tokens = deps.Tokens
    props = props or {}

    local row = Instance.new("CanvasGroup")
    row.Name = props.Id or "Select"
    row.Size = UDim2.new(1, 0, 0, tokens.Size.Select)
    row.Parent = parent
    deps.Material.Control(row, tokens)

    deps.Typography.Label(row, "Control", tokens, props.Title or "Select", UDim2.fromOffset(14, 7), UDim2.new(1, -205, 0, 19), tokens.Color.Text)
    deps.Typography.Label(row, "Description", tokens, props.Description or "", UDim2.fromOffset(14, 28), UDim2.new(1, -205, 0, 16), tokens.Color.TextDim)

    local button = Instance.new("TextButton")
    button.AnchorPoint = Vector2.new(1, 0.5)
    button.Position = UDim2.new(1, -14, 0.5, 0)
    button.Size = UDim2.fromOffset(180, 34)
    button.BackgroundColor3 = tokens.Color.Inset
    button.BackgroundTransparency = 0.03
    button.BorderSizePixel = 0
    button.TextColor3 = tokens.Color.Text
    button.TextSize = tokens.Type.Value
    button.Font = deps.Typography.Font.Medium
    button.AutoButtonColor = false
    button.Parent = row
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 8)
    buttonCorner.Parent = button
    local buttonStroke = Instance.new("UIStroke")
    buttonStroke.Color = tokens.Color.Stroke
    buttonStroke.Transparency = 0.75
    buttonStroke.Parent = button

    local chevron = deps.Icons.Create(button, "chevron_down", 14, tokens.Color.TextDim)
    chevron.AnchorPoint = Vector2.new(1, 0.5)
    chevron.Position = UDim2.new(1, -10, 0.5, 0)

    local self = setmetatable({
        Frame = row,
        Button = button,
        Value = props.Default,
        Options = props.Options or {},
        Enabled = props.Enabled ~= false,
        Callback = props.Callback,
        Deps = deps,
    }, Select)

    function self:_render()
        self.Button.Text = tostring(self.Value or "Select") .. "        "
        self.Frame.GroupTransparency = self.Enabled and 0 or 0.42
    end

    button.MouseButton1Click:Connect(function()
        if not self.Enabled then return end
        deps.PopupManager:Close()

        local height = math.min(206, 12 + (#self.Options * 34))
        local popup = Instance.new("Frame")
        popup.Size = UDim2.fromOffset(198, height)
        popup.Position = popupPosition(deps, button, 198, height)
        popup.ZIndex = 80
        popup.Parent = deps.PopupHost
        deps.Material.Popup(popup, tokens)

        local scroller = Instance.new("ScrollingFrame")
        scroller.BackgroundTransparency = 1
        scroller.BorderSizePixel = 0
        scroller.Position = UDim2.fromOffset(6, 6)
        scroller.Size = UDim2.new(1, -12, 1, -12)
        scroller.CanvasSize = UDim2.new()
        scroller.AutomaticCanvasSize = Enum.AutomaticSize.Y
        scroller.ScrollBarThickness = 2
        scroller.ScrollBarImageColor3 = tokens.Color.Accent
        scroller.ZIndex = 81
        scroller.Parent = popup

        local list = Instance.new("UIListLayout")
        list.Padding = UDim.new(0, 4)
        list.Parent = scroller

        for _, option in ipairs(self.Options) do
            local selected = option == self.Value
            local item = Instance.new("TextButton")
            item.Size = UDim2.new(1, -2, 0, 30)
            item.BackgroundColor3 = selected and tokens.Color.SurfaceSoft or tokens.Color.Control
            item.BackgroundTransparency = selected and 0.08 or 0.34
            item.BorderSizePixel = 0
            item.Text = tostring(option)
            item.TextColor3 = selected and tokens.Color.Accent or tokens.Color.TextMuted
            item.TextSize = tokens.Type.Value
            item.Font = selected and deps.Typography.Font.Semibold or deps.Typography.Font.Medium
            item.AutoButtonColor = false
            item.ZIndex = 82
            item.Parent = scroller
            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0, 7)
            c.Parent = item

            item.MouseButton1Click:Connect(function()
                self:Set(option)
                deps.PopupManager:Close()
            end)
        end

        deps.PopupManager:Set(popup)
    end)

    self:_render()
    return self
end

function Select:Set(value, silent)
    local found = false
    for _, option in ipairs(self.Options) do
        if option == value then found = true break end
    end
    if not found and #self.Options > 0 then return end
    self.Value = value
    self:_render()
    if self.Callback and not silent then self.Callback(self.Value) end
end

function Select:Refresh(options, preserve)
    local previous = self.Value
    self.Options = options or {}
    if preserve then
        for _, option in ipairs(self.Options) do
            if option == previous then self:Set(previous, true) return end
        end
    end
    self:Set(self.Options[1], true)
end

function Select:SetEnabled(value)
    self.Enabled = not not value
    self:_render()
end

return Select
