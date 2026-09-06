local Section = {}
Section.__index = Section

function Section.new(parent, deps, props)
    local tokens = deps.Tokens
    props = props or {}

    local frame = Instance.new("Frame")
    frame.Name = props.Id or "Section"
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.new(1, 0, 0, 0)
    frame.AutomaticSize = Enum.AutomaticSize.Y
    frame.Parent = parent

    local stack = Instance.new("UIListLayout")
    stack.Padding = UDim.new(0, 3)
    stack.SortOrder = Enum.SortOrder.LayoutOrder
    stack.Parent = frame

    local header = Instance.new("TextButton")
    header.BackgroundTransparency = 1
    header.Text = ""
    header.AutoButtonColor = false
    header.Size = UDim2.new(1, 0, 0, tokens.Size.SectionLabel)
    header.LayoutOrder = 1
    header.Parent = frame

    local title = deps.Typography.Label(
        header,
        "Section",
        tokens,
        string.upper(props.Title or "SECTION"),
        UDim2.fromOffset(2, 0),
        UDim2.new(1, -110, 1, 0),
        tokens.Color.TextDim
    )
    title.TextTransparency = 0.16

    local status
    if props.Status then
        status = deps.Typography.Label(
            header,
            "Status",
            tokens,
            string.upper(props.Status),
            UDim2.new(1, -104, 0, 0),
            UDim2.fromOffset(80, tokens.Size.SectionLabel),
            props.StatusColor or tokens.Color.TextDim
        )
        status.TextXAlignment = Enum.TextXAlignment.Right
    end

    local caret
    if props.Collapsible then
        caret = deps.Icons.Create(header, props.Open == false and "plus" or "minus", 12, tokens.Color.TextDim)
        caret.AnchorPoint = Vector2.new(1, 0.5)
        caret.Position = UDim2.new(1, -2, 0.5, 0)
    end

    local body = Instance.new("Frame")
    body.Name = "Panel"
    body.Size = UDim2.new(1, 0, 0, 0)
    body.AutomaticSize = Enum.AutomaticSize.Y
    body.Visible = props.Open ~= false
    body.LayoutOrder = 2
    body.Parent = frame
    deps.Material.Section(body, tokens)

    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 0)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Parent = body

    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 2)
    pad.PaddingBottom = UDim.new(0, 2)
    pad.Parent = body

    local self = setmetatable({
        Frame = frame,
        Header = header,
        Body = body,
        Open = props.Open ~= false,
        Status = status,
        Caret = caret,
        Collapsible = props.Collapsible == true,
        Deps = deps,
    }, Section)

    header.MouseButton1Click:Connect(function()
        if self.Collapsible then
            self:SetOpen(not self.Open)
        end
    end)

    return self
end

function Section:SetOpen(value)
    self.Open = not not value
    self.Body.Visible = self.Open
    if self.Caret then
        self.Caret.Image = self.Deps.Icons.Get(self.Open and "minus" or "plus")
    end
end

function Section:SetStatus(text, color)
    if not self.Status then return end
    self.Status.Text = string.upper(tostring(text))
    if color then self.Status.TextColor3 = color end
end

return Section
