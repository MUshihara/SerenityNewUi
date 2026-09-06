local Typography = {}

Typography.Font = {
    Regular = Enum.Font.Gotham,
    Medium = Enum.Font.GothamMedium,
    Semibold = Enum.Font.GothamSemibold,
    Bold = Enum.Font.GothamBold,
}

local function specFor(role, tokens)
    local sizes = tokens.Type
    local map = {
        Brand = {sizes.Brand, Typography.Font.Bold},
        BrandSub = {sizes.BrandSub, Typography.Font.Medium},
        TopSelect = {sizes.TopSelect, Typography.Font.Medium},
        Page = {sizes.Page, Typography.Font.Bold},
        PageSub = {sizes.PageSub, Typography.Font.Regular},
        NavGroup = {sizes.NavGroup, Typography.Font.Semibold},
        Nav = {sizes.Nav, Typography.Font.Medium},
        Section = {sizes.Section, Typography.Font.Semibold},
        Control = {sizes.Control, Typography.Font.Semibold},
        Description = {sizes.Description, Typography.Font.Regular},
        Value = {sizes.Value, Typography.Font.Medium},
        Status = {sizes.Status, Typography.Font.Bold},
        User = {sizes.User, Typography.Font.Semibold},
        UserSub = {sizes.UserSub, Typography.Font.Medium},
        Metric = {sizes.Metric, Typography.Font.Medium},
        BannerTitle = {sizes.BannerTitle, Typography.Font.Semibold},
        BannerBody = {sizes.BannerBody, Typography.Font.Regular},
    }
    return map[role] or map.Control
end

function Typography.Apply(label, role, tokens, color)
    local spec = specFor(role, tokens)
    label.TextSize = spec[1] or 12
    label.Font = spec[2] or Typography.Font.Medium
    label.TextColor3 = color or tokens.Color.Text
    label.BackgroundTransparency = 1
    return label
end

function Typography.Label(parent, role, tokens, text, position, size, color)
    local label = Instance.new("TextLabel")
    label.Text = text or ""
    label.Position = position or UDim2.new()
    label.Size = size or UDim2.fromScale(1, 1)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextTruncate = Enum.TextTruncate.AtEnd
    label.Parent = parent
    Typography.Apply(label, role, tokens, color)
    return label
end

return Typography
