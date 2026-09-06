local Tokens = {}

Tokens.Size = {
    Window = Vector2.new(800, 520),
    Topbar = 58,
    Sidebar = 128,
    SidebarCollapsed = 62,
    Footer = 34,

    Control = 56,
    Button = 52,
    Slider = 64,
    SectionHeader = 58,

    RadiusShell = 18,
    RadiusSection = 12,
    RadiusControl = 9,
    RadiusPopup = 12,
}

Tokens.Type = {
    Brand = 15,
    Page = 24,
    Section = 15,
    Control = 13,
    Description = 10,
    Value = 11,
    Status = 9,
}

Tokens.Space = {
    XS = 4,
    S = 7,
    M = 10,
    L = 14,
    XL = 20,
}

Tokens.Color = {
    Shell = Color3.fromRGB(13, 19, 30),
    Sidebar = Color3.fromRGB(12, 19, 31),
    Surface = Color3.fromRGB(21, 30, 46),
    Surface2 = Color3.fromRGB(26, 36, 54),
    Inset = Color3.fromRGB(14, 22, 34),

    Text = Color3.fromRGB(241, 246, 255),
    TextMuted = Color3.fromRGB(181, 193, 216),
    TextDim = Color3.fromRGB(120, 134, 160),

    Stroke = Color3.fromRGB(73, 90, 116),

    Accent = Color3.fromRGB(86, 223, 244),
    Mint = Color3.fromRGB(90, 235, 191),
    Lavender = Color3.fromRGB(183, 136, 255),
    Amber = Color3.fromRGB(255, 197, 87),
    Red = Color3.fromRGB(255, 107, 142),
}

return Tokens
