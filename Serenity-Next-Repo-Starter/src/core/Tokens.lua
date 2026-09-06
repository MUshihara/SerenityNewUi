local Tokens = {}

Tokens.Size = {
    Window = Vector2.new(760, 480),
    Topbar = 52,
    Sidebar = 120,
    SidebarCollapsed = 58,
    Footer = 0,

    NavRow = 42,
    NavIcon = 30,
    GameContext = 64,
    MetricPill = 26,
    SegmentTabs = 34,
    InfoBanner = 62,

    SectionHeader = 50,
    Control = 52,
    Button = 48,
    Slider = 60,
    Select = 52,
    Status = 46,

    RadiusShell = 16,
    RadiusSection = 10,
    RadiusControl = 8,
    RadiusPopup = 11,
    RadiusTile = 9,
}

Tokens.Type = {
    Brand = 14,
    BrandSub = 8,
    Page = 17,
    PageSub = 9,
    Section = 13,
    Control = 12,
    Description = 10,
    Value = 11,
    Status = 9,
    Nav = 11,
    Metric = 9,
    BannerTitle = 11,
    BannerBody = 9,
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
    Shell = Color3.fromRGB(9, 14, 22),
    ShellDeep = Color3.fromRGB(5, 8, 13),
    Sidebar = Color3.fromRGB(8, 12, 19),

    Surface = Color3.fromRGB(23, 30, 42),
    SurfaceSoft = Color3.fromRGB(29, 38, 52),
    Control = Color3.fromRGB(22, 29, 40),
    ControlHover = Color3.fromRGB(32, 41, 55),
    Inset = Color3.fromRGB(13, 19, 28),
    Popup = Color3.fromRGB(18, 25, 36),

    Text = Color3.fromRGB(246, 248, 252),
    TextMuted = Color3.fromRGB(188, 197, 214),
    TextDim = Color3.fromRGB(126, 138, 160),

    Stroke = Color3.fromRGB(83, 97, 119),
    StrokeBright = Color3.fromRGB(153, 177, 205),

    Accent = Color3.fromRGB(78, 220, 242),
    Mint = Color3.fromRGB(82, 232, 184),
    Lavender = Color3.fromRGB(188, 116, 255),
    Pink = Color3.fromRGB(244, 73, 171),
    Blue = Color3.fromRGB(87, 163, 255),
    Amber = Color3.fromRGB(247, 190, 79),
    Red = Color3.fromRGB(246, 103, 132),
    Disabled = Color3.fromRGB(68, 79, 98),
}

Tokens.Material = {
    ShellTransparency = 0.07,
    SidebarTransparency = 0.04,
    SectionTransparency = 0.70,
    ControlTransparency = 0.48,
    PopupTransparency = 0.05,
    ShadowTransparency = 0.56,
    EdgeTransparency = 0.66,
    HighlightTransparency = 0.88,
}

Tokens.Motion = {
    Hover = 0.10,
    Toggle = 0.14,
    Popup = 0.17,
    Page = 0.14,
    Collapse = 0.17,
    Nav = 0.14,
}

return Tokens
