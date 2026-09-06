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
        math.clamp(y + bh + 4, 8, maxH - height - 8)
    )
end

function Select.new(parent, deps, props)
    local tokens = deps.Tokens
    props = props or {}
    local hasDescription = props.Description and props.Description ~= ""
    local height = hasDescription and tokens.Size.ControlWithDescription or tokens.Size.Select

    local row = Instance.new("CanvasGroup")
    row.Name = props.Id or "Select"
    row.Size = UDim2.new(1, 0, 0, height)
    row.Parent = parent
    deps.Material.Control(row, tokens)

    local titleY = hasDescription and 6 or 0
    local titleH = hasDescription and 19 or height
    deps.Typography.Label(row, "Control", tokens, props.Title or "Select", UDim2.fromOffset(13, titleY), UDim2.new(0.47, -12, 0, titleH), tokens.Color.Text)
    if hasDescription then
        deps.Typography.Label(row, "Description", tokens, props.Description, UDim2.fromOffset(13, 27), UDim2.new(0.47, -12, 0, 15), tokens.Color.TextDim)
    end

    local button = Instance.new("TextButton")
    button.AnchorPoint = Vector2.new(1, 0.5)
    button.Position = UDim2.new(1, -12, 0.5, 0)
    button.Size = UDim2.new(0.50, -10, 0, 30)
    button.Text = ""
    button.AutoButtonColor = false
    button.Parent = row
    deps.Material.Inset(button, tokens)

    local valueLabel = deps.Typography.Label(button, "Value", tokens, tostring(props.Default or "Select"), UDim2.fromOffset(10, 0), UDim2.new(1, -34, 1, 0), tokens.Color.TextMuted)
    local chevron = deps.Icons.Create(button, "chevron_down", 13, tokens.Color.TextDim)
    chevron.AnchorPoint = Vector2.new(1, 0.5)
    chevron.Position = UDim2.new(1, -9, 0.5, 0)

    local self = setmetatable({
        Frame = row,
        Button = button,
        Label = valueLabel,
        Value = props.Default,
        Options = props.Options or {},
        Enabled = props.Enabled ~= false,
        Callback = props.Callback,
        Deps = deps,
    }, Select)

    function self:_render()
        self.Label.Text = tostring(self.Value or "Select")
        self.Frame.GroupTransparency = self.Enabled and 0 or 0.45
    end

    button.MouseEnter:Connect(function()
        if self.Enabled then button.BackgroundColor3 = tokens.Color.InsetHover end
    end)
    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = tokens.Color.Inset
    end)

    button.MouseButton1Click:Connect(function()
        if not self.Enabled then return end
        deps.PopupManager:Close()

        local width = math.max(180, math.floor(button.AbsoluteSize.X / math.max(0.001, (deps.UIScale and deps.UIScale.Scale) or 1)))
        local heightPopup = math.min(230, 12 + (#self.Options * 34))
        local popup = Instance.new("Frame")
        popup.Size = UDim2.fromOffset(width, heightPopup)
        popup.Position = popupPosition(deps, button, width, heightPopup)
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
        scroller.ScrollBarImageTransparency = 0.35
        scroller.ZIndex = 81
        scroller.Parent = popup

        local list = Instance.new("UIListLayout")
        list.Padding = UDim.new(0, 3)
        list.Parent = scroller

        for _, option in ipairs(self.Options) do
            local selected = option == self.Value
            local item = Instance.new("TextButton")
            item.Size = UDim2.new(1, -2, 0, 31)
            item.BackgroundColor3 = selected and tokens.Color.NavActive or tokens.Color.PanelSoft
            item.BackgroundTransparency = selected and 0.08 or 0.55
            item.BorderSizePixel = 0
            item.Text = tostring(option)
            item.TextColor3 = selected and tokens.Color.Text or tokens.Color.TextMuted
            item.TextSize = tokens.Type.Value
            item.Font = selected and deps.Typography.Font.Semibold or deps.Typography.Font.Medium
            item.AutoButtonColor = false
            item.ZIndex = 82
            item.Parent = scroller
            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0, 6)
            c.Parent = item

            if selected then
                local dot = Instance.new("Frame")
                dot.AnchorPoint = Vector2.new(0, 0.5)
                dot.Position = UDim2.new(0, 8, 0.5, 0)
                dot.Size = UDim2.fromOffset(4, 4)
                dot.BackgroundColor3 = tokens.Color.Accent
                dot.BorderSizePixel = 0
                dot.ZIndex = 83
                dot.Parent = item
                local dc = Instance.new("UICorner") dc.CornerRadius = UDim.new(1, 0) dc.Parent = dot
            end

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
