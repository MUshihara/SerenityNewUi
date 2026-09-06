local Tokens = {}

Tokens.Size = {
    Window = Vector2.new(720, 460),
    Topbar = 56,
    Sidebar = 118,
    SidebarCollapsed = 58,
    Footer = 0,

    SectionHeader = 54,
    Control = 54,
    Button = 50,
    Slider = 62,
    Select = 54,
    Status = 48,

    RadiusShell = 16,
    RadiusSection = 11,
    RadiusControl = 9,
    RadiusPopup = 11,
}

Tokens.Type = {
    Brand = 15,
    BrandSub = 9,
    Page = 22,
    PageSub = 10,
    Section = 14,
    Control = 13,
    Description = 10,
    Value = 11,
    Status = 9,
    Nav = 11,
}

Tokens.Space = {
    XXS = 3,
    XS = 5,
    S = 7,
    M = 10,
    L = 14,
    XL = 18,
}

Tokens.Color = {
    Shell = Color3.fromRGB(11, 16, 25),
    ShellDeep = Color3.fromRGB(7, 11, 18),
    Sidebar = Color3.fromRGB(11, 17, 27),

    Surface = Color3.fromRGB(24, 31, 43),
    SurfaceSoft = Color3.fromRGB(28, 36, 49),
    Control = Color3.fromRGB(23, 30, 42),
    ControlHover = Color3.fromRGB(31, 40, 55),
    Inset = Color3.fromRGB(15, 21, 31),
    Popup = Color3.fromRGB(20, 27, 39),

    Text = Color3.fromRGB(244, 247, 252),
    TextMuted = Color3.fromRGB(183, 193, 211),
    TextDim = Color3.fromRGB(122, 135, 158),

    Stroke = Color3.fromRGB(87, 101, 125),
    StrokeBright = Color3.fromRGB(140, 166, 196),

    Accent = Color3.fromRGB(77, 220, 242),
    Mint = Color3.fromRGB(82, 231, 184),
    Lavender = Color3.fromRGB(177, 130, 255),
    Amber = Color3.fromRGB(247, 190, 79),
    Red = Color3.fromRGB(246, 103, 132),
    Disabled = Color3.fromRGB(71, 81, 101),
}

Tokens.Material = {
    ShellTransparency = 0.10,
    SidebarTransparency = 0.18,
    SectionTransparency = 0.24,
    ControlTransparency = 0.28,
    PopupTransparency = 0.05,
    ShadowTransparency = 0.58,
    EdgeTransparency = 0.62,
    HighlightTransparency = 0.82,
}

Tokens.Motion = {
    Hover = 0.11,
    Toggle = 0.14,
    Popup = 0.17,
    Page = 0.16,
    Collapse = 0.18,
}

return Tokens
