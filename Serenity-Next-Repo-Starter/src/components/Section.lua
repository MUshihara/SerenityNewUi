local Section = {}
Section.__index = Section

function Section.new(parent, deps, props)
    local tokens = deps.Tokens
    local frame = Instance.new("Frame")
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

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Position = UDim2.fromOffset(14, 8)
    title.Size = UDim2.new(1, -180, 0, 20)
    title.Text = props.Title or "Section"
    title.TextColor3 = tokens.Color.Text
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header
    deps.Typography.Apply(title, "Section", tokens)

    local description = Instance.new("TextLabel")
    description.BackgroundTransparency = 1
    description.Position = UDim2.fromOffset(14, 30)
    description.Size = UDim2.new(1, -180, 0, 16)
    description.Text = props.Description or ""
    description.TextColor3 = tokens.Color.TextMuted
    description.TextXAlignment = Enum.TextXAlignment.Left
    description.Parent = header
    deps.Typography.Apply(description, "Description", tokens)

    local body = Instance.new("Frame")
    body.BackgroundTransparency = 1
    body.Position = UDim2.fromOffset(8, tokens.Size.SectionHeader + 2)
    body.Size = UDim2.new(1, -16, 0, 0)
    body.AutomaticSize = Enum.AutomaticSize.Y
    body.Visible = props.Open ~= false
    body.Parent = frame

    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, tokens.Space.S)
    list.Parent = body

    local pad = Instance.new("UIPadding")
    pad.PaddingBottom = UDim.new(0, 8)
    pad.Parent = body

    local self = setmetatable({
        Frame = frame,
        Header = header,
        Body = body,
        Open = props.Open ~= false,
    }, Section)

    header.MouseButton1Click:Connect(function()
        self:SetOpen(not self.Open)
    end)

    return self
end

function Section:SetOpen(value)
    self.Open = not not value
    self.Body.Visible = self.Open
end

return Section
