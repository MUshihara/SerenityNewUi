local Typography = {}

Typography.Font = {
    Regular = Enum.Font.Gotham,
    Medium = Enum.Font.GothamMedium,
    Semibold = Enum.Font.GothamSemibold,
    Bold = Enum.Font.GothamBold,
}

function Typography.Apply(label, role, tokens)
    local sizes = tokens.Type
    local roleMap = {
        Brand = {sizes.Brand, Typography.Font.Bold},
        Page = {sizes.Page, Typography.Font.Bold},
        Section = {sizes.Section, Typography.Font.Bold},
        Control = {sizes.Control, Typography.Font.Semibold},
        Description = {sizes.Description, Typography.Font.Regular},
        Value = {sizes.Value, Typography.Font.Medium},
        Status = {sizes.Status, Typography.Font.Bold},
    }

    local spec = roleMap[role] or roleMap.Control
    label.TextSize = spec[1]
    label.Font = spec[2]

    return label
end

return Typography
