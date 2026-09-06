local MultiSelect = {}
MultiSelect.__index = MultiSelect

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

function MultiSelect.new(parent, deps, props)
    local tokens = deps.Tokens
    props = props or {}
    local selected = {}
    for _, value in ipairs(props.Default or {}) do selected[value] = true end

    local row = Instance.new("CanvasGroup")
    row.Name = props.Id or "MultiSelect"
    row.Size = UDim2.new(1, 0, 0, tokens.Size.Select)
    row.Parent = parent
    deps.Material.Control(row, tokens)

    deps.Typography.Label(row, "Control", tokens, props.Title or "Multi Select", UDim2.fromOffset(14, 7), UDim2.new(1, -205, 0, 19), tokens.Color.Text)
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

    local self = setmetatable({
        Frame = row,
        Button = button,
        Selected = selected,
        Options = props.Options or {},
        Callback = props.Callback,
        Deps = deps,
    }, MultiSelect)

    function self:_count()
        local n = 0
        for _, state in pairs(self.Selected) do if state then n += 1 end end
        return n
    end

    function self:_render()
        local n = self:_count()
        if n == 0 then
            self.Button.Text = "None selected"
        elseif n == 1 then
            for name, state in pairs(self.Selected) do
                if state then self.Button.Text = name break end
            end
        else
            self.Button.Text = tostring(n) .. " selected"
        end
    end

    button.MouseButton1Click:Connect(function()
        deps.PopupManager:Close()
        local popup = Instance.new("Frame")
        popup.Size = UDim2.fromOffset(238, 280)
        popup.Position = popupPosition(deps, button, 238, 280)
        popup.ZIndex = 80
        popup.Parent = deps.PopupHost
        deps.Material.Popup(popup, tokens)

        deps.Typography.Label(popup, "Control", tokens, props.Title or "Select", UDim2.fromOffset(12, 8), UDim2.new(1, -24, 0, 20), tokens.Color.Text).ZIndex = 81

        local search = Instance.new("TextBox")
        search.Position = UDim2.fromOffset(10, 34)
        search.Size = UDim2.new(1, -20, 0, 32)
        search.BackgroundColor3 = tokens.Color.Inset
        search.BorderSizePixel = 0
        search.Text = ""
        search.PlaceholderText = "Search options..."
        search.PlaceholderColor3 = tokens.Color.TextDim
        search.TextColor3 = tokens.Color.Text
        search.TextSize = tokens.Type.Description
        search.Font = deps.Typography.Font.Regular
        search.TextXAlignment = Enum.TextXAlignment.Left
        search.ClearTextOnFocus = false
        search.ZIndex = 81
        search.Parent = popup
        local sc = Instance.new("UICorner") sc.CornerRadius = UDim.new(0, 7) sc.Parent = search
        local pad = Instance.new("UIPadding") pad.PaddingLeft = UDim.new(0, 10) pad.PaddingRight = UDim.new(0, 8) pad.Parent = search

        local all = Instance.new("TextButton")
        all.Position = UDim2.fromOffset(10, 72)
        all.Size = UDim2.new(0.5, -14, 0, 28)
        all.BackgroundColor3 = tokens.Color.SurfaceSoft
        all.BackgroundTransparency = 0.16
        all.BorderSizePixel = 0
        all.Text = "ALL"
        all.TextColor3 = tokens.Color.Accent
        all.TextSize = tokens.Type.Status
        all.Font = deps.Typography.Font.Bold
        all.ZIndex = 81
        all.Parent = popup
        local ac = Instance.new("UICorner") ac.CornerRadius = UDim.new(0, 7) ac.Parent = all

        local clear = all:Clone()
        clear.Position = UDim2.new(0.5, 4, 0, 72)
        clear.Text = "CLEAR"
        clear.TextColor3 = tokens.Color.TextMuted
        clear.Parent = popup

        local list = Instance.new("ScrollingFrame")
        list.Position = UDim2.fromOffset(10, 108)
        list.Size = UDim2.new(1, -20, 1, -118)
        list.BackgroundTransparency = 1
        list.BorderSizePixel = 0
        list.CanvasSize = UDim2.new()
        list.AutomaticCanvasSize = Enum.AutomaticSize.Y
        list.ScrollBarThickness = 2
        list.ScrollBarImageColor3 = tokens.Color.Accent
        list.ZIndex = 81
        list.Parent = popup
        local ll = Instance.new("UIListLayout") ll.Padding = UDim.new(0, 4) ll.Parent = list

        local rows = {}
        local function emit()
            self:_render()
            if self.Callback then self.Callback(self.Selected) end
        end

        for _, option in ipairs(self.Options) do
            local item = Instance.new("TextButton")
            item.Size = UDim2.new(1, -2, 0, 29)
            item.BackgroundColor3 = tokens.Color.Control
            item.BackgroundTransparency = 0.35
            item.BorderSizePixel = 0
            item.Text = ""
            item.AutoButtonColor = false
            item.ZIndex = 82
            item.Parent = list
            local ic = Instance.new("UICorner") ic.CornerRadius = UDim.new(0, 7) ic.Parent = item

            local check = Instance.new("Frame")
            check.Position = UDim2.fromOffset(8, 7)
            check.Size = UDim2.fromOffset(15, 15)
            check.BackgroundColor3 = self.Selected[option] and tokens.Color.Accent or tokens.Color.SurfaceSoft
            check.BorderSizePixel = 0
            check.ZIndex = 83
            check.Parent = item
            local cc = Instance.new("UICorner") cc.CornerRadius = UDim.new(0, 4) cc.Parent = check

            local tick = deps.Icons.Create(check, "check", 10, Color3.new(1, 1, 1), UDim2.fromOffset(2.5, 2.5))
            tick.Visible = self.Selected[option] == true
            tick.ZIndex = 84

            deps.Typography.Label(item, "Value", tokens, option, UDim2.fromOffset(31, 0), UDim2.new(1, -36, 1, 0), tokens.Color.TextMuted).ZIndex = 83
            rows[option] = item

            item.MouseButton1Click:Connect(function()
                self.Selected[option] = not self.Selected[option]
                check.BackgroundColor3 = self.Selected[option] and tokens.Color.Accent or tokens.Color.SurfaceSoft
                tick.Visible = self.Selected[option] == true
                emit()
            end)
        end

        search:GetPropertyChangedSignal("Text"):Connect(function()
            local q = string.lower(search.Text or "")
            for option, item in pairs(rows) do
                item.Visible = q == "" or string.find(string.lower(option), q, 1, true) ~= nil
            end
        end)

        all.MouseButton1Click:Connect(function()
            for _, option in ipairs(self.Options) do self.Selected[option] = true end
            deps.PopupManager:Close()
            emit()
        end)
        clear.MouseButton1Click:Connect(function()
            table.clear(self.Selected)
            deps.PopupManager:Close()
            emit()
        end)

        deps.PopupManager:Set(popup)
    end)

    self:_render()
    return self
end

return MultiSelect
