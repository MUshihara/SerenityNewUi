local Section = {}
Section.__index = Section

function Section.new(parent, deps, props)
    local tokens = deps.Tokens
    props = props or {}

    local frame = Instance.new("Frame")
    frame.Name = props.Id or "Section"
    frame.Size = UDim2.new(1, 0, 0, tokens.Size.SectionHeader)
    frame.AutomaticSize = Enum.AutomaticSize.Y
    frame.Parent = parent
    deps.Material.Section(frame, tokens)

    local header = Instance.new("TextButton")
    header.BackgroundTransparency = 1
    header.Text = ""
    header.AutoButtonColor = false
    header.Size = UDim2.new(1, 0, 0, tokens.Size.SectionHeader)
    header.Parent = frame

    deps.Typography.Label(
        header,
        "Section",
        tokens,
        props.Title or "Section",
        UDim2.fromOffset(14, 7),
        UDim2.new(1, -150, 0, 20),
        tokens.Color.Text
    )

    deps.Typography.Label(
        header,
        "Description",
        tokens,
        props.Description or "",
        UDim2.fromOffset(14, 28),
        UDim2.new(1, -150, 0, 17),
        tokens.Color.TextMuted
    )

    local status
    if props.Status then
        status = Instance.new("TextLabel")
        status.AnchorPoint = Vector2.new(1, 0.5)
        status.Position = UDim2.new(1, -39, 0.5, 0)
        status.Size = UDim2.fromOffset(78, 24)
        status.BackgroundColor3 = tokens.Color.Inset
        status.BackgroundTransparency = 0.08
        status.BorderSizePixel = 0
        status.Text = props.Status
        status.TextColor3 = props.StatusColor or tokens.Color.TextMuted
        status.Parent = header
        deps.Typography.Apply(status, "Status", tokens, status.TextColor3)
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 7)
        c.Parent = status
        local s = Instance.new("UIStroke")
        s.Color = status.TextColor3
        s.Transparency = 0.62
        s.Parent = status
    end

    local caret = deps.Icons.Create(header, props.Open == false and "plus" or "minus", 15, tokens.Color.TextDim)
    caret.AnchorPoint = Vector2.new(1, 0.5)
    caret.Position = UDim2.new(1, -12, 0.5, 0)

    local body = Instance.new("Frame")
    body.BackgroundTransparency = 1
    body.Position = UDim2.fromOffset(8, tokens.Size.SectionHeader + 1)
    body.Size = UDim2.new(1, -16, 0, 0)
    body.AutomaticSize = Enum.AutomaticSize.Y
    body.Visible = props.Open ~= false
    body.Parent = frame

    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, tokens.Space.S)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Parent = body

    local pad = Instance.new("UIPadding")
    pad.PaddingBottom = UDim.new(0, 8)
    pad.Parent = body

    local self = setmetatable({
        Frame = frame,
        Header = header,
        Body = body,
        Open = props.Open ~= false,
        Status = status,
        Caret = caret,
        Deps = deps,
    }, Section)

    header.MouseButton1Click:Connect(function()
        self:SetOpen(not self.Open)
    end)

    return self
end

function Section:SetOpen(value)
    self.Open = not not value
    self.Body.Visible = self.Open
    self.Caret.Image = self.Deps.Icons.Get(self.Open and "minus" or "plus")
end

function Section:SetStatus(text, color)
    if not self.Status then return end
    self.Status.Text = text
    if color then
        self.Status.TextColor3 = color
        local stroke = self.Status:FindFirstChildOfClass("UIStroke")
        if stroke then stroke.Color = color end
    end
end

return Section
