local NavItem = {}
NavItem.__index = NavItem

function NavItem.new(parent, deps, props)
    local tokens = deps.Tokens
    props = props or {}

    local row = Instance.new("TextButton")
    row.Name = props.Id or props.Title or "NavItem"
    row.Size = UDim2.new(1, 0, 0, tokens.Size.NavRow)
    row.BackgroundTransparency = 1
    row.BorderSizePixel = 0
    row.Text = ""
    row.AutoButtonColor = false
    row.LayoutOrder = props.Order or 1
    row.Parent = parent

    local tile = Instance.new("Frame")
    tile.Position = UDim2.fromOffset(4, 6)
    tile.Size = UDim2.fromOffset(tokens.Size.NavIcon, tokens.Size.NavIcon)
    tile.Parent = row
    deps.Material.NavTile(tile, tokens, props.Accent, false)

    local icon = deps.Icons.Create(tile, props.Icon or "info", 17, tokens.Color.TextMuted)
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.Position = UDim2.fromScale(0.5, 0.5)

    local label = deps.Typography.Label(
        row,
        "Nav",
        tokens,
        props.Title or "Page",
        UDim2.fromOffset(44, 0),
        UDim2.new(1, -48, 1, 0),
        tokens.Color.TextMuted
    )

    local self = setmetatable({
        Row = row,
        Tile = tile,
        Icon = icon,
        Label = label,
        Accent = props.Accent or tokens.Color.Accent,
        Selected = false,
        Collapsed = false,
        Callback = props.Callback,
        Deps = deps,
    }, NavItem)

    row.MouseEnter:Connect(function()
        if not self.Selected then
            deps.Motion:Tween(tile, "Hover", {BackgroundTransparency = 0.22})
            label.TextColor3 = tokens.Color.Text
        end
    end)

    row.MouseLeave:Connect(function()
        if not self.Selected then
            deps.Motion:Tween(tile, "Hover", {BackgroundTransparency = 0.34})
            label.TextColor3 = tokens.Color.TextMuted
        end
    end)

    row.MouseButton1Click:Connect(function()
        if self.Callback then self.Callback() end
    end)

    return self
end

function NavItem:SetSelected(selected)
    self.Selected = not not selected
    local tokens = self.Deps.Tokens
    self.Deps.Material.NavTile(self.Tile, tokens, self.Accent, self.Selected)
    self.Icon.ImageColor3 = self.Selected and Color3.new(1, 1, 1) or tokens.Color.TextMuted
    self.Label.TextColor3 = self.Selected and tokens.Color.Text or tokens.Color.TextMuted
end

function NavItem:SetCollapsed(collapsed)
    self.Collapsed = not not collapsed
    self.Label.Visible = not self.Collapsed
end

return NavItem
