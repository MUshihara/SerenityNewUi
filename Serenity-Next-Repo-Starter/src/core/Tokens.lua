local Tokens = {}

-- Serenity M3: compact 1.4:1 desktop canvas inspired by professional utility panels.
Tokens.Size = {
    Window = Vector2.new(900, 640),
    Topbar = 62,
    Sidebar = 190,
    SidebarBrand = 78,
    SidebarUser = 72,
    SidebarCollapsed = 62,
    Footer = 0,

    NavGroup = 24,
    NavRow = 42,
    NavIcon = 22,
    GameContext = 64,
    MetricPill = 26,
    SegmentTabs = 34,
    InfoBanner = 62,

    SectionLabel = 24,
    SectionHeader = 50,
    Control = 46,
    ControlWithDescription = 56,
    Button = 46,
    Slider = 50,
    Select = 46,
    Status = 46,

    RadiusShell = 14,
    RadiusPanel = 10,
    RadiusSection = 10,
    RadiusControl = 7,
    RadiusPopup = 9,
    RadiusNav = 7,
    RadiusTile = 7,
}

Tokens.Type = {
    Brand = 15,
    BrandSub = 9,
    TopSelect = 13,
    Page = 17,
    PageSub = 9,
    NavGroup = 9,
    Nav = 12,
    Section = 10,
    Control = 13,
    Description = 9,
    Value = 12,
    Status = 9,
    User = 12,
    UserSub = 9,
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
    Shell = Color3.fromRGB(4, 5, 14),
    ShellDeep = Color3.fromRGB(2, 3, 9),
    ShellSoft = Color3.fromRGB(8, 9, 18),
    Sidebar = Color3.fromRGB(7, 8, 15),
    Topbar = Color3.fromRGB(7, 8, 16),

    Panel = Color3.fromRGB(14, 16, 26),
    PanelSoft = Color3.fromRGB(17, 20, 31),
    Surface = Color3.fromRGB(14, 16, 26),
    SurfaceSoft = Color3.fromRGB(17, 20, 31),
    Control = Color3.fromRGB(17, 20, 31),
    ControlHover = Color3.fromRGB(23, 27, 40),
    RowHover = Color3.fromRGB(23, 27, 40),
    Inset = Color3.fromRGB(18, 21, 33),
    InsetHover = Color3.fromRGB(24, 28, 42),
    Popup = Color3.fromRGB(13, 15, 25),

    NavActive = Color3.fromRGB(34, 36, 49),
    NavHover = Color3.fromRGB(20, 22, 33),

    Text = Color3.fromRGB(242, 244, 249),
    TextMuted = Color3.fromRGB(171, 177, 191),
    TextDim = Color3.fromRGB(99, 104, 119),

    Divider = Color3.fromRGB(38, 41, 54),
    Stroke = Color3.fromRGB(66, 71, 90),
    StrokeBright = Color3.fromRGB(112, 121, 146),

    Accent = Color3.fromRGB(72, 130, 255),
    AccentBright = Color3.fromRGB(97, 151, 255),
    Blue = Color3.fromRGB(72, 130, 255),
    Cyan = Color3.fromRGB(73, 216, 239),
    Mint = Color3.fromRGB(82, 224, 177),
    Lavender = Color3.fromRGB(173, 126, 255),
    Pink = Color3.fromRGB(241, 79, 170),
    Amber = Color3.fromRGB(242, 185, 77),
    Red = Color3.fromRGB(239, 91, 116),
    Disabled = Color3.fromRGB(66, 70, 82),
}

Tokens.Material = {
    ShellTransparency = 0.10,
    SidebarTransparency = 0.06,
    TopbarTransparency = 0.08,
    PanelTransparency = 0.12,
    SectionTransparency = 0.12,
    ControlTransparency = 1,
    PopupTransparency = 0.04,
    ShadowTransparency = 0.46,
    EdgeTransparency = 0.78,
    HighlightTransparency = 0.92,
}

Tokens.Motion = {
    Hover = 0.10,
    Toggle = 0.13,
    Popup = 0.16,
    Page = 0.12,
    Collapse = 0.14,
    Nav = 0.11,
}

return Tokens
