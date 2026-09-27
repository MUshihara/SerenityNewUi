-- Serenity M4 Compact: generated from modular test source. One download; UI only.
local modules = {}
modules["src/core/Runtime.lua"] = (function()
local Runtime = {}
Runtime.__index = Runtime

function Runtime.new(key)
    local self = setmetatable({}, Runtime)
    self.Key = key
    self.Connections = {}
    self.Instances = {}
    self.Cleanup = {}
    self.Destroyed = false
    return self
end

function Runtime:TrackConnection(connection)
    table.insert(self.Connections, connection)
    return connection
end

function Runtime:TrackInstance(instance)
    table.insert(self.Instances, instance)
    return instance
end

function Runtime:TrackCleanup(callback)
    table.insert(self.Cleanup, callback)
end

function Runtime:Destroy()
    if self.Destroyed then return end
    self.Destroyed = true

    for _, callback in ipairs(self.Cleanup) do
        pcall(callback)
    end

    for _, connection in ipairs(self.Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    for _, instance in ipairs(self.Instances) do
        pcall(function()
            instance:Destroy()
        end)
    end
end

return Runtime

end)()
modules["src/core/Tokens.lua"] = (function()
local Tokens = {}

-- Serenity M3: compact 1.4:1 desktop canvas inspired by professional utility panels.
Tokens.Size = {
    Window = Vector2.new(780, 540),
    Topbar = 62,
    Sidebar = 172,
    SidebarBrand = 12,
    SidebarUser = 64,
    SidebarCollapsed = 62,
    Footer = 0,

    NavGroup = 24,
    NavRow = 36,
    NavIcon = 22,
    GameContext = 64,
    MetricPill = 26,
    SegmentTabs = 34,
    InfoBanner = 62,

    SectionLabel = 24,
    SectionHeader = 50,
    Control = 40,
    ControlWithDescription = 56,
    Button = 46,
    Slider = 58,
    Select = 62,
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
    Shell = Color3.fromRGB(15, 36, 53),
    ShellDeep = Color3.fromRGB(2, 3, 9),
    ShellSoft = Color3.fromRGB(8, 9, 18),
    Sidebar = Color3.fromRGB(13, 32, 48),
    Topbar = Color3.fromRGB(22, 48, 69),

    Panel = Color3.fromRGB(24, 49, 68),
    PanelSoft = Color3.fromRGB(29, 57, 79),
    Surface = Color3.fromRGB(14, 16, 26),
    SurfaceSoft = Color3.fromRGB(17, 20, 31),
    Control = Color3.fromRGB(17, 20, 31),
    ControlHover = Color3.fromRGB(23, 27, 40),
    RowHover = Color3.fromRGB(23, 27, 40),
    Inset = Color3.fromRGB(20, 43, 63),
    InsetHover = Color3.fromRGB(24, 28, 42),
    Popup = Color3.fromRGB(13, 15, 25),

    NavActive = Color3.fromRGB(35, 77, 111),
    NavHover = Color3.fromRGB(20, 22, 33),

    Text = Color3.fromRGB(247, 244, 235),
    TextMuted = Color3.fromRGB(171, 177, 191),
    TextDim = Color3.fromRGB(137, 148, 168),

    Divider = Color3.fromRGB(38, 41, 54),
    Stroke = Color3.fromRGB(88, 150, 197),
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
    ShellTransparency = 0.04,
    SidebarTransparency = 0.06,
    TopbarTransparency = 0.08,
    PanelTransparency = 0.06,
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

end)()
modules["src/core/Typography.lua"] = (function()
local Typography = {}

Typography.Font = {
    Regular = Enum.Font.Gotham,
    Medium = Enum.Font.GothamMedium,
    Semibold = Enum.Font.GothamMedium,
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

end)()
modules["src/core/Motion.lua"] = (function()
local TweenService = game:GetService("TweenService")

local Motion = {
    Reduced = false,
    Durations = {
        Hover = 0.11,
        Toggle = 0.14,
        Select = 0.16,
        Popup = 0.18,
        Collapse = 0.18,
        Modal = 0.20,
    }
}

function Motion:Tween(instance, durationKey, props, style, direction)
    local duration = self.Reduced and 0 or (self.Durations[durationKey] or durationKey or 0.15)
    local tween = TweenService:Create(
        instance,
        TweenInfo.new(duration, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out),
        props
    )
    tween:Play()
    return tween
end

return Motion

end)()
modules["src/core/Material.lua"] = (function()
local Material = {}

local SHADOW_IMAGE = "rbxassetid://1316045217"

local function corner(parent, radius, name)
    local c = Instance.new("UICorner")
    c.Name = name or "Corner"
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = parent
    return c
end

local function stroke(parent, color, transparency, thickness, name)
    local s = Instance.new("UIStroke")
    s.Name = name or "Stroke"
    s.Color = color
    s.Transparency = transparency
    s.Thickness = thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

function Material.Shadow(parent, targetSize, radius, tokens)
    -- No external shadow layer: avoids the oversized black backing on desktop.
    return nil
end

function Material.Shell(frame, tokens)
    frame.BackgroundColor3 = tokens.Color.Shell
    frame.BackgroundTransparency = tokens.Material.ShellTransparency
    frame.BorderSizePixel = 0
    corner(frame, tokens.Size.RadiusShell, "ShellCorner")
    stroke(frame, tokens.Color.Stroke, tokens.Material.EdgeTransparency, 1, "ShellEdge")

    local gradient = Instance.new("UIGradient")
    gradient.Name = "ShellTone"
    gradient.Rotation = 118
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(230, 240, 255)),
        ColorSequenceKeypoint.new(0.45, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(215, 231, 250)),
    })
    gradient.Parent = frame

    local topLine = Instance.new("Frame")
    topLine.Name = "TopGlassLine"
    topLine.BackgroundColor3 = Color3.fromRGB(186, 204, 238)
    topLine.BackgroundTransparency = 0.93
    topLine.BorderSizePixel = 0
    topLine.Position = UDim2.fromOffset(14, 0)
    topLine.Size = UDim2.new(1, -28, 0, 1)
    topLine.ZIndex = frame.ZIndex + 1
    topLine.Parent = frame
    return frame
end

function Material.Sidebar(frame, tokens)
    frame.BackgroundColor3 = tokens.Color.Sidebar
    frame.BackgroundTransparency = tokens.Material.SidebarTransparency
    frame.BorderSizePixel = 0

    local divider = Instance.new("Frame")
    divider.Name = "SidebarDivider"
    divider.AnchorPoint = Vector2.new(1, 0)
    divider.Position = UDim2.new(1, 0, 0, 14)
    divider.Size = UDim2.new(0, 1, 1, -28)
    divider.BackgroundColor3 = tokens.Color.Divider
    divider.BackgroundTransparency = 0.34
    divider.BorderSizePixel = 0
    divider.Parent = frame
    return frame
end

function Material.Topbar(frame, tokens)
    frame.BackgroundColor3 = tokens.Color.Topbar
    frame.BackgroundTransparency = tokens.Material.TopbarTransparency
    frame.BorderSizePixel = 0

    local divider = Instance.new("Frame")
    divider.AnchorPoint = Vector2.new(0, 1)
    divider.Position = UDim2.new(0, 12, 1, 0)
    divider.Size = UDim2.new(1, -24, 0, 1)
    divider.BackgroundColor3 = tokens.Color.Divider
    divider.BackgroundTransparency = 0.42
    divider.BorderSizePixel = 0
    divider.Parent = frame
    return frame
end

function Material.Section(frame, tokens)
    frame.BackgroundColor3 = tokens.Color.Panel
    frame.BackgroundTransparency = tokens.Material.PanelTransparency
    frame.BorderSizePixel = 0
    corner(frame, tokens.Size.RadiusPanel, "PanelCorner")
    stroke(frame, tokens.Color.Stroke, 0.56, 1, "PanelStroke")
    return frame
end

function Material.Control(frame, tokens)
    frame.BackgroundColor3 = tokens.Color.PanelSoft
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0

    local separator = frame:FindFirstChild("RowSeparator")
    if not separator then
        separator = Instance.new("Frame")
        separator.Name = "RowSeparator"
        separator.AnchorPoint = Vector2.new(0, 1)
        separator.Position = UDim2.new(0, 12, 1, 0)
        separator.Size = UDim2.new(1, -24, 0, 1)
        separator.BackgroundColor3 = tokens.Color.Divider
        separator.BackgroundTransparency = 0.62
        separator.BorderSizePixel = 0
        separator.Parent = frame
    end
    return frame
end

function Material.Popup(frame, tokens)
    frame.BackgroundColor3 = tokens.Color.Popup
    frame.BackgroundTransparency = tokens.Material.PopupTransparency
    frame.BorderSizePixel = 0
    corner(frame, tokens.Size.RadiusPopup, "PopupCorner")
    stroke(frame, tokens.Color.Stroke, 0.52, 1, "PopupStroke")

    return frame
end

function Material.NavRow(frame, tokens, selected)
    frame.BackgroundColor3 = selected and tokens.Color.NavActive or tokens.Color.NavHover
    frame.BackgroundTransparency = selected and 0.04 or 1
    frame.BorderSizePixel = 0

    local c = frame:FindFirstChild("NavCorner")
    if not c then
        c = corner(frame, tokens.Size.RadiusNav, "NavCorner")
    end
    return frame
end

function Material.NavTile(frame, tokens, color, selected)
    -- Kept for compatibility. M3 uses the icon itself as the strongest accent.
    frame.BackgroundColor3 = selected and tokens.Color.InsetHover or tokens.Color.Inset
    frame.BackgroundTransparency = selected and 0.10 or 0.38
    frame.BorderSizePixel = 0

    local c = frame:FindFirstChild("NavTileCorner")
    if not c then c = corner(frame, 6, "NavTileCorner") end
    local s = frame:FindFirstChild("NavTileStroke")
    if not s then s = stroke(frame, tokens.Color.Stroke, 0.90, 1, "NavTileStroke") end
    s.Color = selected and (color or tokens.Color.Accent) or tokens.Color.Stroke
    s.Transparency = selected and 0.78 or 0.93
    return frame
end

function Material.Inset(frame, tokens)
    frame.BackgroundColor3 = tokens.Color.Inset
    frame.BackgroundTransparency = 0.04
    frame.BorderSizePixel = 0
    corner(frame, 6, "InsetCorner")
    stroke(frame, tokens.Color.Stroke, 0.88, 1, "InsetStroke")
    return frame
end

function Material.Pill(frame, tokens, accent)
    frame.BackgroundColor3 = tokens.Color.Inset
    frame.BackgroundTransparency = 0.04
    frame.BorderSizePixel = 0
    corner(frame, 7, "PillCorner")
    stroke(frame, accent or tokens.Color.Stroke, accent and 0.76 or 0.90, 1, "PillStroke")
    return frame
end

function Material.Hover(frame, tokens, active)
    frame.BackgroundColor3 = active and tokens.Color.RowHover or tokens.Color.PanelSoft
    frame.BackgroundTransparency = active and 0.28 or 1
end

-- Four tapered rays drawn from Frames; independent of font glyph coverage.
function Material.Star(parent, position, size, color, z)
    local root=Instance.new("Frame")
    root.Name="SerenityStar"
    root.BackgroundTransparency=1
    root.Position=position
    root.Size=UDim2.fromOffset(size,size)
    root.ZIndex=z or 2
    root.Parent=parent
    for i=0,11 do
        local distance=i/11
        local thickness=math.max(1, math.floor(size*0.32*(1-distance)^2))
        for _,axis in ipairs({0,1}) do
            for _,sign in ipairs({-1,1}) do
                local ray=Instance.new("Frame")
                ray.BorderSizePixel=0
                ray.BackgroundColor3=color
                ray.AnchorPoint=Vector2.new(0.5,0.5)
                ray.Size=UDim2.fromOffset(axis==0 and thickness or math.max(1,size/24),axis==0 and math.max(1,size/24) or thickness)
                ray.Position=UDim2.fromOffset(size/2+(axis==1 and sign*distance*size*0.46 or 0),size/2+(axis==0 and sign*distance*size*0.46 or 0))
                ray.ZIndex=root.ZIndex
                ray.Parent=root
            end
        end
    end
    return root
end
return Material

end)()
modules["src/core/AcrylicEngine.lua"] = (function()
local Lighting = game:GetService("Lighting")

local AcrylicEngine = {}
AcrylicEngine.__index = AcrylicEngine

function AcrylicEngine.new(runtime, options)
    options = options or {}

    local self = setmetatable({}, AcrylicEngine)
    self.Quality = "Basic"
    self.Visible = true
    self.Amount = options.BasicBlur or 3

    self.Blur = runtime:TrackInstance(Instance.new("BlurEffect"))
    self.Blur.Name = "SerenityAcrylicBlur"
    self.Blur.Size = options.BasicBlur or 3
    self.Blur.Enabled = true
    self.Blur.Parent = Lighting

    self.Depth = runtime:TrackInstance(Instance.new("DepthOfFieldEffect"))
    self.Depth.Name = "SerenityAcrylicDepth"
    self.Depth.Enabled = false
    self.Depth.FocusDistance = 35
    self.Depth.InFocusRadius = 28
    self.Depth.NearIntensity = 0.04
    self.Depth.FarIntensity = 0.08
    self.Depth.Parent = Lighting

    return self
end

function AcrylicEngine:SetQuality(quality)
    quality = quality or "Basic"
    self.Quality = quality

    if not self.Visible or quality == "Off" then
        self.Blur.Enabled = false
        self.Depth.Enabled = false
    elseif quality == "Enhanced" then
        self.Blur.Enabled = true
        self.Blur.Size = self.Amount
        self.Depth.Enabled = true
    else
        self.Blur.Enabled = true
        self.Blur.Size = self.Amount
        self.Depth.Enabled = false
        self.Quality = "Basic"
    end
end

function AcrylicEngine:SetVisible(visible)
    self.Visible = visible
    self:SetQuality(self.Quality)
end

function AcrylicEngine:SetAmount(value)
    self.Amount = math.clamp(value, 0, 8)
    self.Blur.Size = self.Amount
end

function AcrylicEngine:SetEnabled(enabled)
    self:SetQuality(enabled and "Basic" or "Off")
end

return AcrylicEngine

end)()
modules["src/core/Icons.lua"] = (function()
local Icons = {}

Icons.Map = {
    home = "rbxassetid://98755624629571",
    about = "rbxassetid://124560466474914",
    info = "rbxassetid://124560466474914",
    automation = "rbxassetid://80451686744860",
    progression = "rbxassetid://81819858538839",
    shops = "rbxassetid://90338129673705",
    shop = "rbxassetid://90338129673705",
    configs = "rbxassetid://126791525623846",
    misc = "rbxassetid://126791525623846",
    settings = "rbxassetid://80758916183665",
    search = "rbxassetid://121018724060431",
    activity = "rbxassetid://94212016861936",
    webhook = "rbxassetid://94212016861936",
    roll = "rbxassetid://81268120302865",
    target = "rbxassetid://87563802520297",
    inventory = "rbxassetid://140420225386018",
    pets = "rbxassetid://112218825427601",
    world = "rbxassetid://95107167260947",
    server = "rbxassetid://95107167260947",
    store = "rbxassetid://90338129673705",
    shield = "rbxassetid://87354736164608",
    lock = "rbxassetid://134724289526879",
    warning = "rbxassetid://125920361880643",
    check = "rbxassetid://93898873302694",
    chevron_right = "rbxassetid://92473583511724",
    chevron_down = "rbxassetid://134243273101015",
    plus = "rbxassetid://111774323017047",
    minus = "rbxassetid://118026365011536",
    close = "rbxassetid://110786993356448",
    save = "rbxassetid://126116963775616",
}

function Icons.Get(name)
    return Icons.Map[name] or Icons.Map.info
end

function Icons.Create(parent, name, size, color, position)
    local image = Instance.new("ImageLabel")
    image.Name = "Icon_" .. tostring(name)
    image.BackgroundTransparency = 1
    image.Image = Icons.Get(name)
    image.ImageColor3 = color or Color3.new(1, 1, 1)
    image.ScaleType = Enum.ScaleType.Fit
    image.Size = UDim2.fromOffset(size or 18, size or 18)
    if position then image.Position = position end
    image.Parent = parent
    return image
end

return Icons

end)()
modules["src/core/PopupManager.lua"] = (function()
local PopupManager = {}
PopupManager.__index = PopupManager

function PopupManager.new()
    return setmetatable({
        Active = nil,
    }, PopupManager)
end

function PopupManager:Close()
    if self.Active then
        pcall(function()
            self.Active:Destroy()
        end)
        self.Active = nil
    end
end

function PopupManager:Set(frame)
    self:Close()
    self.Active = frame
    return frame
end

return PopupManager

end)()
modules["src/components/NavItem.lua"] = (function()
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
    deps.Material.NavRow(row, tokens, false)

    local icon = deps.Icons.Create(row, props.Icon or "info", tokens.Size.NavIcon, tokens.Color.TextMuted)
    icon.AnchorPoint = Vector2.new(0, 0.5)
    icon.Position = UDim2.new(0, 11, 0.5, 0)

    local label = deps.Typography.Label(
        row,
        "Nav",
        tokens,
        props.Title or "Page",
        UDim2.fromOffset(44, 0),
        UDim2.new(1, -52, 1, 0),
        tokens.Color.TextMuted
    )

    local self = setmetatable({
        Row = row,
        Icon = icon,
        Label = label,
        Accent = props.Accent or tokens.Color.Accent,
        Selected = false,
        Callback = props.Callback,
        Deps = deps,
    }, NavItem)

    row.MouseEnter:Connect(function()
        if not self.Selected then
            row.BackgroundColor3 = tokens.Color.NavHover
            deps.Motion:Tween(row, "Hover", {BackgroundTransparency = 0.34})
            label.TextColor3 = tokens.Color.Text
            icon.ImageColor3 = tokens.Color.Text
        end
    end)

    row.MouseLeave:Connect(function()
        if not self.Selected then
            deps.Motion:Tween(row, "Hover", {BackgroundTransparency = 1})
            label.TextColor3 = tokens.Color.TextMuted
            icon.ImageColor3 = tokens.Color.TextMuted
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
    self.Deps.Material.NavRow(self.Row, tokens, self.Selected)
    self.Icon.ImageColor3 = self.Selected and self.Accent or tokens.Color.TextMuted
    self.Label.TextColor3 = self.Selected and tokens.Color.Text or tokens.Color.TextMuted
end

function NavItem:SetCollapsed(collapsed)
    self.Label.Visible = not collapsed
end

return NavItem

end)()
modules["src/components/Section.lua"] = (function()
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
        UDim2.new(1, props.Status and -110 or -22, 1, 0),
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

end)()
modules["src/components/Toggle.lua"] = (function()
local Toggle = {}
Toggle.__index = Toggle

function Toggle.new(parent, deps, props)
    local tokens = deps.Tokens
    props = props or {}
    local hasDescription = props.Description and props.Description ~= ""
    local height = hasDescription and tokens.Size.ControlWithDescription or tokens.Size.Control

    local row = Instance.new("CanvasGroup")
    row.Name = props.Id or "Toggle"
    row.Size = UDim2.new(1, 0, 0, height)
    row.Parent = parent
    deps.Material.Control(row, tokens)

    local titleY = hasDescription and 6 or 0
    local titleH = hasDescription and 19 or height
    deps.Typography.Label(
        row,
        "Control",
        tokens,
        props.Title or "Toggle",
        UDim2.fromOffset(13, titleY),
        UDim2.new(1, -108, 0, titleH),
        tokens.Color.Text
    )

    if hasDescription then
        deps.Typography.Label(
            row,
            "Description",
            tokens,
            props.Description,
            UDim2.fromOffset(13, 27),
            UDim2.new(1, -108, 0, 15),
            tokens.Color.TextDim
        )
    end

    if props.Settings and props.OnSettings then
        local dots = deps.Typography.Label(row, "Value", tokens, "•••", UDim2.new(1, -96, 0, 0), UDim2.fromOffset(34, height), tokens.Color.TextDim)
        dots.TextXAlignment = Enum.TextXAlignment.Center
    end

    local switch = Instance.new("Frame")
    switch.AnchorPoint = Vector2.new(1, 0.5)
    switch.Position = UDim2.new(1, -13, 0.5, 0)
    switch.Size = UDim2.fromOffset(38, 21)
    switch.BorderSizePixel = 0
    switch.Parent = row
    local switchCorner = Instance.new("UICorner")
    switchCorner.CornerRadius = UDim.new(1, 0)
    switchCorner.Parent = switch

    local knob = Instance.new("Frame")
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Size = UDim2.fromOffset(15, 15)
    knob.BackgroundColor3 = Color3.fromRGB(249, 250, 255)
    knob.BorderSizePixel = 0
    knob.Parent = switch
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    local hit = Instance.new("TextButton")
    hit.BackgroundTransparency = 1
    hit.Text = ""
    hit.AutoButtonColor = false
    hit.Size = UDim2.fromScale(1, 1)
    hit.Parent = row

    local self = setmetatable({
        Frame = row,
        Value = not not props.Default,
        Enabled = props.Enabled ~= false,
        Switch = switch,
        Knob = knob,
        Callback = props.Callback,
        Motion = deps.Motion,
        Tokens = tokens,
    }, Toggle)

    function self:_render(animate)
        self.Switch.BackgroundColor3 = self.Value and self.Tokens.Color.Accent or self.Tokens.Color.Disabled
        local pos = self.Value and UDim2.new(1, -10.5, 0.5, 0) or UDim2.fromOffset(10.5, 10.5)
        if animate then
            self.Motion:Tween(self.Knob, "Toggle", {Position = pos})
        else
            self.Knob.Position = pos
        end
        self.Frame.GroupTransparency = self.Enabled and 0 or 0.45
    end

    self:_render(false)

    hit.MouseEnter:Connect(function()
        if self.Enabled then deps.Material.Hover(row, tokens, true) end
    end)
    hit.MouseLeave:Connect(function()
        deps.Material.Hover(row, tokens, false)
    end)
    hit.MouseButton1Click:Connect(function()
        if not self.Enabled then return end
        self:Set(not self.Value)
    end)

    return self
end

function Toggle:Set(value, silent)
    self.Value = not not value
    self:_render(true)
    if self.Callback and not silent then self.Callback(self.Value) end
end

function Toggle:SetEnabled(value)
    self.Enabled = not not value
    self:_render(false)
end

return Toggle

end)()
modules["src/components/Slider.lua"] = (function()
local Slider = {}
Slider.__index = Slider

function Slider.new(parent, deps, props)
    local tokens = deps.Tokens
    props = props or {}

    local min = props.Min or 0
    local max = props.Max or 100
    local step = math.max(0.000001, props.Step or 1)
    max = math.max(min, max)
    local value = math.clamp(props.Default or min, min, max)
    local suffix = props.Suffix or ""

    local row = Instance.new("CanvasGroup")
    row.Name = props.Id or "Slider"
    row.Size = UDim2.new(1, 0, 0, tokens.Size.Slider)
    row.Parent = parent
    deps.Material.Control(row, tokens)

    deps.Typography.Label(
        row,
        "Control",
        tokens,
        props.Title or "Slider",
        UDim2.fromOffset(13, 0),
        UDim2.new(1, -86, 0, 29),
        tokens.Color.Text
    )

    if props.Settings and props.OnSettings then
        local dots = deps.Typography.Label(row, "Value", tokens, "•••", UDim2.new(0.39, 0, 0, 0), UDim2.fromOffset(30, tokens.Size.Slider), tokens.Color.TextDim)
        dots.TextXAlignment = Enum.TextXAlignment.Center
    end

    local valueBox = Instance.new("Frame")
    valueBox.AnchorPoint = Vector2.new(1, 0.5)
    valueBox.Position = UDim2.new(1, -12, 0, 15)
    valueBox.Size = UDim2.fromOffset(48, 26)
    valueBox.Parent = row
    deps.Material.Inset(valueBox, tokens)

    local valueLabel = Instance.new("TextBox")
    valueLabel.Size=UDim2.fromScale(1,1)
    valueLabel.ClearTextOnFocus=false
    valueLabel.Text=tostring(value)
    valueLabel.Parent=valueBox
    deps.Typography.Apply(valueLabel,"Value",tokens,tokens.Color.TextMuted)
    valueLabel.TextXAlignment = Enum.TextXAlignment.Center

    local bar = Instance.new("Frame")
    bar.AnchorPoint = Vector2.new(1, 0.5)
    bar.Position = UDim2.new(1, -16, 0, 42)
    bar.Size = UDim2.new(1, -32, 0, 4)
    bar.BackgroundColor3 = tokens.Color.Disabled
    bar.BackgroundTransparency = 0.34
    bar.BorderSizePixel = 0
    bar.Parent = row
    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(1, 0)
    barCorner.Parent = bar

    local fill = Instance.new("Frame")
    fill.BackgroundColor3 = tokens.Color.Accent
    fill.BorderSizePixel = 0
    fill.Parent = bar
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill

    local knob = Instance.new("Frame")
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Size = UDim2.fromOffset(12, 12)
    knob.BackgroundColor3 = Color3.fromRGB(247, 249, 255)
    knob.BorderSizePixel = 0
    knob.Parent = bar
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    local hit = Instance.new("TextButton")
    hit.BackgroundTransparency = 1
    hit.Text = ""
    hit.AutoButtonColor = false
    hit.AnchorPoint = Vector2.new(1, 0.5)
    hit.Position = UDim2.new(1, -8, 0, 42)
    hit.Size = UDim2.new(1, -16, 0, 28)
    hit.Parent = row

    local self = setmetatable({
        Frame = row,
        Value = value,
        Enabled = props.Enabled ~= false,
        Min = min,
        Max = max,
        Step = step,
        Suffix = suffix,
        Fill = fill,
        Knob = knob,
        Label = valueLabel,
        Callback = props.Callback,
        Tokens = tokens,
    }, Slider)

    local function roundToStep(v)
        local snapped = math.floor(((v - min) / step) + 0.5) * step + min
        return math.clamp(snapped, min, max)
    end

    function self:_render()
        local alpha = (self.Value - self.Min) / math.max(0.0001, self.Max - self.Min)
        self.Fill.Size = UDim2.new(alpha, 0, 1, 0)
        self.Knob.Position = UDim2.new(alpha, 0, 0.5, 0)
        self.Label.Text = string.format("%.3f", self.Value):gsub("0+$", ""):gsub("%.$", "") .. self.Suffix
        self.Frame.GroupTransparency = self.Enabled and 0 or 0.45
    end

    function self:_setFromX(x)
        if not self.Enabled then return end
        local alpha = math.clamp((x - bar.AbsolutePosition.X) / math.max(1, bar.AbsoluteSize.X), 0, 1)
        local raw = self.Min + (self.Max - self.Min) * alpha
        self:Set(roundToStep(raw))
    end

    local dragging = false
    hit.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            self:_setFromX(input.Position.X)
        end
    end)

    deps.Runtime:TrackConnection(deps.UserInputService.InputChanged:Connect(function(input)
        if dragging and deps.WindowFrame.Visible and deps.WindowFrame.Parent.Visible and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            self:_setFromX(input.Position.X)
        end
    end))

    deps.Runtime:TrackConnection(deps.UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))

    valueLabel.Focused:Connect(function()
        if not self.Enabled then valueLabel:ReleaseFocus() return end
        valueLabel.Text=tostring(self.Value)
    end)
    valueLabel.FocusLost:Connect(function()
        local number=tonumber(valueLabel.Text)
        if self.Enabled and number and number==number and math.abs(number)<math.huge then self:Set(number) end
        self:_render()
    end)
    valueBox.InputChanged:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseWheel and self.Enabled then
            self:Set(self.Value+input.Position.Z*self.Step)
        end
    end)
    self:_render()
    return self
end

function Slider:Set(value, silent)
    if type(value)~="number" or value~=value or math.abs(value)==math.huge then return end
    local nextValue = math.clamp(self.Min + math.floor((value - self.Min) / self.Step + 0.5) * self.Step, self.Min, self.Max)
    if nextValue == self.Value then return end
    self.Value = nextValue
    self:_render()
    if self.Callback and not silent then self.Callback(self.Value) end
end

function Slider:SetEnabled(value)
    self.Enabled = not not value
    self:_render()
end

return Slider

end)()
modules["src/components/Select.lua"] = (function()
local Select = {}
Select.__index = Select

local function popupPosition(deps, button, width, height)
    local scale = (deps.UIScale and deps.UIScale.Scale) or 1
    local shell = deps.WindowFrame
    local x = (button.AbsolutePosition.X - shell.AbsolutePosition.X) / scale
    local y = (button.AbsolutePosition.Y - shell.AbsolutePosition.Y) / scale
    local bw = button.AbsoluteSize.X / scale
    local bh = button.AbsoluteSize.Y / scale
    local maxW = shell.AbsoluteSize.X / scale
    local maxH = shell.AbsoluteSize.Y / scale
    return UDim2.fromOffset(
        math.clamp(x + bw - width, 8, math.max(8, maxW - width - 8)),
        math.clamp(y + bh + height + 12 <= maxH and (y + bh + 4) or (y - height - 4), 8, math.max(8, maxH - height - 8))
    )
end

function Select.new(parent, deps, props)
    local tokens = deps.Tokens
    props = props or {}
    local hasDescription = props.Description and props.Description ~= ""
    local height = hasDescription and tokens.Size.ControlWithDescription or tokens.Size.Select

    local row = Instance.new("CanvasGroup")
    row.Name = props.Id or "Select"
    row.Size = UDim2.new(1, 0, 0, height)
    row.Parent = parent
    deps.Material.Control(row, tokens)

    local titleY = 0
    local titleH = 24
    deps.Typography.Label(row, "Control", tokens, props.Title or "Select", UDim2.fromOffset(13, titleY), UDim2.new(1, -26, 0, titleH), tokens.Color.Text)
    if hasDescription then
        deps.Typography.Label(row, "Description", tokens, props.Description, UDim2.fromOffset(13, 27), UDim2.new(0.47, -12, 0, 15), tokens.Color.TextDim)
    end

    local button = Instance.new("TextButton")
    button.AnchorPoint = Vector2.new(1, 0.5)
    button.Position = UDim2.new(1, -12, 1, -19)
    button.Size = UDim2.new(1, -24, 0, 30)
    button.Text = ""
    button.AutoButtonColor = false
    button.Parent = row
    deps.Material.Inset(button, tokens)

    local valueLabel = deps.Typography.Label(button, "Value", tokens, tostring(props.Default or "Select"), UDim2.fromOffset(10, 0), UDim2.new(1, -34, 1, 0), tokens.Color.TextMuted)
    local chevron = deps.Icons.Create(button, "chevron_down", 13, tokens.Color.TextDim)
    chevron.AnchorPoint = Vector2.new(1, 0.5)
    chevron.Position = UDim2.new(1, -9, 0.5, 0)

    local self = setmetatable({
        Frame = row,
        Button = button,
        Label = valueLabel,
        Value = props.Default,
        Options = props.Options or {},
        Enabled = props.Enabled ~= false,
        Callback = props.Callback,
        Deps = deps,
    }, Select)

    function self:_render()
        self.Label.Text = tostring(self.Value or "Select")
        self.Frame.GroupTransparency = self.Enabled and 0 or 0.45
    end

    button.MouseEnter:Connect(function()
        if self.Enabled then button.BackgroundColor3 = tokens.Color.InsetHover end
    end)
    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = tokens.Color.Inset
    end)

    button.MouseButton1Click:Connect(function()
        if not self.Enabled then return end
        deps.PopupManager:Close()

        local width = math.max(180, math.floor(button.AbsoluteSize.X / math.max(0.001, (deps.UIScale and deps.UIScale.Scale) or 1)))
        local heightPopup = math.min(230, 12 + (#self.Options * 34))
        local popup = Instance.new("Frame")
        popup.Size = UDim2.fromOffset(width, heightPopup)
        popup.Position = popupPosition(deps, button, width, heightPopup)
        popup.ZIndex = 80
        popup.Parent = deps.PopupHost
        deps.Material.Popup(popup, tokens)

        local scroller = Instance.new("ScrollingFrame")
        scroller.BackgroundTransparency = 1
        scroller.BorderSizePixel = 0
        scroller.Position = UDim2.fromOffset(6, 6)
        scroller.Size = UDim2.new(1, -12, 1, -12)
        scroller.CanvasSize = UDim2.new()
        scroller.AutomaticCanvasSize = Enum.AutomaticSize.Y
        scroller.ScrollBarThickness = 2
        scroller.ScrollBarImageColor3 = tokens.Color.Accent
        scroller.ScrollBarImageTransparency = 0.35
        scroller.ZIndex = 81
        scroller.Parent = popup

        local list = Instance.new("UIListLayout")
        list.Padding = UDim.new(0, 3)
        list.Parent = scroller

        for _, option in ipairs(self.Options) do
            local selected = option == self.Value
            local item = Instance.new("TextButton")
            item.Size = UDim2.new(1, -2, 0, 31)
            item.BackgroundColor3 = selected and tokens.Color.NavActive or tokens.Color.PanelSoft
            item.BackgroundTransparency = selected and 0.08 or 0.55
            item.BorderSizePixel = 0
            item.Text = tostring(option)
            item.TextColor3 = selected and tokens.Color.Text or tokens.Color.TextMuted
            item.TextSize = tokens.Type.Value
            item.Font = selected and deps.Typography.Font.Semibold or deps.Typography.Font.Medium
            item.AutoButtonColor = false
            item.ZIndex = 82
            item.Parent = scroller
            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0, 6)
            c.Parent = item

            if selected then
                local dot = Instance.new("Frame")
                dot.AnchorPoint = Vector2.new(0, 0.5)
                dot.Position = UDim2.new(0, 8, 0.5, 0)
                dot.Size = UDim2.fromOffset(4, 4)
                dot.BackgroundColor3 = tokens.Color.Accent
                dot.BorderSizePixel = 0
                dot.ZIndex = 83
                dot.Parent = item
                local dc = Instance.new("UICorner") dc.CornerRadius = UDim.new(1, 0) dc.Parent = dot
            end

            item.MouseButton1Click:Connect(function()
                self:Set(option)
                deps.PopupManager:Close()
            end)
        end

        deps.PopupManager:Set(popup)
    end)

    self:_render()
    return self
end

function Select:Set(value, silent)
    local found = false
    for _, option in ipairs(self.Options) do
        if option == value then found = true break end
    end
    if not found and #self.Options > 0 then return end
    self.Value = value
    self:_render()
    if self.Callback and not silent then self.Callback(self.Value) end
end

function Select:Refresh(options, preserve)
    local previous = self.Value
    self.Options = options or {}
    if preserve then
        for _, option in ipairs(self.Options) do
            if option == previous then self:Set(previous, true) return end
        end
    end
    self:Set(self.Options[1], true)
end

function Select:SetEnabled(value)
    self.Enabled = not not value
    self:_render()
end

return Select

end)()
modules["src/components/ColumnLayout.lua"] = (function()
local ColumnLayout = {}
ColumnLayout.__index = ColumnLayout

function ColumnLayout.new(parent, deps, props)
    props = props or {}
    local gap = props.Gap or 12

    local frame = Instance.new("Frame")
    frame.Name = props.Id or "ColumnLayout"
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.new(1, 0, 0, 0)
    frame.LayoutOrder = props.LayoutOrder or 1
    frame.Parent = parent

    local left = Instance.new("Frame")
    left.Name = "Left"
    left.BackgroundTransparency = 1
    left.Position = UDim2.fromOffset(0, 0)
    left.Size = UDim2.new(0.5, -(gap / 2), 0, 0)
    left.AutomaticSize = Enum.AutomaticSize.Y
    left.Parent = frame

    local right = Instance.new("Frame")
    right.Name = "Right"
    right.BackgroundTransparency = 1
    right.Position = UDim2.new(0.5, gap / 2, 0, 0)
    right.Size = UDim2.new(0.5, -(gap / 2), 0, 0)
    right.AutomaticSize = Enum.AutomaticSize.Y
    right.Parent = frame

    local leftList = Instance.new("UIListLayout")
    leftList.Padding = UDim.new(0, props.RowGap or 10)
    leftList.SortOrder = Enum.SortOrder.LayoutOrder
    leftList.Parent = left

    local rightList = Instance.new("UIListLayout")
    rightList.Padding = UDim.new(0, props.RowGap or 10)
    rightList.SortOrder = Enum.SortOrder.LayoutOrder
    rightList.Parent = right

    local self = setmetatable({
        Frame = frame,
        Left = left,
        Right = right,
        LeftList = leftList,
        RightList = rightList,
        Deps = deps,
    }, ColumnLayout)

    local function refresh()
        local scale = deps.UIScale and deps.UIScale.Scale or 1
        local narrow = frame.AbsoluteSize.X / scale < 550
        left.Size = UDim2.new(narrow and 1 or 0.5, narrow and 0 or -(gap / 2), 0, 0)
        right.Size = left.Size
        local leftH = leftList.AbsoluteContentSize.Y / scale
        local rightH = rightList.AbsoluteContentSize.Y / scale
        right.Position = narrow and UDim2.fromOffset(0, leftH + gap) or UDim2.new(0.5, gap / 2, 0, 0)
        frame.Size = UDim2.new(1, 0, 0, narrow and (leftH + gap + rightH) or math.max(leftH, rightH))
    end

    if deps.Runtime then
        deps.Runtime:TrackConnection(leftList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(refresh))
        deps.Runtime:TrackConnection(rightList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(refresh))
    else
        leftList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(refresh)
        rightList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(refresh)
    end

    deps.Runtime:TrackConnection(frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(refresh))
    task.defer(refresh)
    return self
end

return ColumnLayout

end)()
modules["src/renderers/Desktop.lua"] = (function()
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")

local Desktop = {}

local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = parent
    return c
end

local function makeDraggable(runtime, frame, handle)
    local dragging = false
    local dragStart
    local startPos

    runtime:TrackConnection(handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end))

    runtime:TrackConnection(UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            local parentSize = frame.Parent.AbsoluteSize
            local size = frame.AbsoluteSize
            local x = startPos.X.Scale * parentSize.X + startPos.X.Offset + delta.X
            local y = startPos.Y.Scale * parentSize.Y + startPos.Y.Offset + delta.Y
            frame.Position = UDim2.fromOffset(math.clamp(x, size.X / 2, math.max(size.X / 2, parentSize.X - size.X / 2)), math.clamp(y, size.Y / 2, math.max(size.Y / 2, parentSize.Y - size.Y / 2)))
        end
    end))

    runtime:TrackConnection(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))
end

function Desktop.Mount(deps, options)
    options = options or {}
    local tokens = deps.Tokens
    local runtime = deps.Runtime
    local localPlayer = Players.LocalPlayer

    local parentGui
    pcall(function() if gethui then parentGui = gethui() end end)
    if not parentGui then pcall(function() parentGui = game:GetService("CoreGui") end) end
    if not parentGui then parentGui = localPlayer:WaitForChild("PlayerGui") end

    local screen = runtime:TrackInstance(Instance.new("ScreenGui"))
    screen.Name = options.Name or "SerenityNextM3"
    screen.ResetOnSpawn = false
    screen.IgnoreGuiInset = false
    screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screen.DisplayOrder = 999999
    screen.Parent = parentGui
    pcall(function() if protect_gui then protect_gui(screen) end end)

    local acrylic = deps.AcrylicEngine and deps.AcrylicEngine.new(runtime, {BasicBlur = options.BlurSize or 3}) or nil

    local holder = Instance.new("Frame")
    holder.AnchorPoint = Vector2.new(0.5, 0.5)
    holder.Position = UDim2.fromScale(0.5, 0.5)
    holder.Size = UDim2.fromOffset(tokens.Size.Window.X, tokens.Size.Window.Y)
    holder.BackgroundTransparency = 1
    holder.Parent = screen

    local uiScale = Instance.new("UIScale")
    uiScale.Scale = 1
    uiScale.Parent = holder

    local function refreshScale()
        local camera = workspace.CurrentCamera
        local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
        local inset = GuiService:GetGuiInset()
        uiScale.Scale = 1
        holder.Size = UDim2.fromOffset(math.min(tokens.Size.Window.X, math.max(320, viewport.X - 24)), math.min(tokens.Size.Window.Y, math.max(240, viewport.Y - inset.Y - 24)))
        holder.Position = UDim2.fromScale(0.5, 0.5)
        deps.PopupManager:Close()
    end
    local cameraConnection
    local function bindCamera()
        if cameraConnection then cameraConnection:Disconnect() end
        if workspace.CurrentCamera then
            cameraConnection = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(refreshScale)
        end
        refreshScale()
    end
    runtime:TrackConnection(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCamera))
    runtime:TrackCleanup(function() if cameraConnection then cameraConnection:Disconnect() end deps.PopupManager:Close() end)
    bindCamera()

    deps.Material.Shadow(holder, UDim2.fromScale(1, 1), tokens.Size.RadiusShell, tokens)

    local shell = Instance.new("Frame")
    shell.Name = "Shell"
    shell.Size = UDim2.fromScale(1, 1)
    shell.ClipsDescendants = true
    shell.ZIndex = 2
    shell.Parent = holder
    deps.Material.Shell(shell, tokens)

    deps.WindowFrame = shell
    deps.UIScale = uiScale

    -- LEFT SIDEBAR ------------------------------------------------------------
    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Position = UDim2.fromOffset(0, tokens.Size.Topbar)
    sidebar.Size = UDim2.new(0, tokens.Size.Sidebar, 1, -tokens.Size.Topbar)
    sidebar.ZIndex = 3
    sidebar.Parent = shell
    deps.Material.Sidebar(sidebar, tokens)
    corner(sidebar,tokens.Size.RadiusShell)

    local brand = Instance.new("Frame")
    brand.BackgroundTransparency = 1
    brand.Size = UDim2.new(1, 0, 0, tokens.Size.SidebarBrand)
    brand.ZIndex = 4
    brand.Parent = sidebar
    brand.Visible = false

    local logoWrap = Instance.new("Frame")
    logoWrap.Position = UDim2.fromOffset(14, 14)
    logoWrap.Size = UDim2.fromOffset(38, 38)
    logoWrap.BackgroundColor3 = tokens.Color.Inset
    logoWrap.BackgroundTransparency = 0.05
    logoWrap.BorderSizePixel = 0
    logoWrap.ZIndex = 5
    logoWrap.Parent = brand
    corner(logoWrap, 9)

    local logo = Instance.new("ImageLabel")
    logo.BackgroundTransparency = 1
    logo.Position = UDim2.fromOffset(5, 5)
    logo.Size = UDim2.fromOffset(28, 28)
    logo.Image = "rbxthumb://type=Asset&id=89023606689629&w=420&h=420"
    logo.ScaleType = Enum.ScaleType.Fit
    logo.ZIndex = 6
    logo.Parent = logoWrap

    deps.Typography.Label(brand, "Brand", tokens, options.Title or "SERENITY HUB", UDim2.fromOffset(63, 12), UDim2.new(1, -70, 0, 21), tokens.Color.Text).ZIndex = 5
    local brandSub = deps.Typography.Label(brand, "BrandSub", tokens, options.Subtitle or "Interface Prototype", UDim2.fromOffset(63, 34), UDim2.new(1, -70, 0, 16), tokens.Color.TextDim)
    brandSub.ZIndex = 5

    local navHolder = Instance.new("ScrollingFrame")
    navHolder.Name = "Navigation"
    navHolder.BackgroundTransparency = 1
    navHolder.BorderSizePixel = 0
    navHolder.Position = UDim2.fromOffset(11, tokens.Size.SidebarBrand)
    navHolder.Size = UDim2.new(1, -22, 1, -(tokens.Size.SidebarBrand + tokens.Size.SidebarUser + 8))
    navHolder.CanvasSize = UDim2.new()
    navHolder.AutomaticCanvasSize = Enum.AutomaticSize.Y
    navHolder.ScrollBarThickness = 0
    navHolder.ZIndex = 4
    navHolder.Parent = sidebar

    local navList = Instance.new("UIListLayout")
    navList.Padding = UDim.new(0, 2)
    navList.SortOrder = Enum.SortOrder.LayoutOrder
    navList.Parent = navHolder

    local userFrame = Instance.new("TextButton")
    userFrame.Name = "UserContext"
    userFrame.AnchorPoint = Vector2.new(0, 1)
    userFrame.Position = UDim2.new(0, 11, 1, -10)
    userFrame.Size = UDim2.new(1, -22, 0, tokens.Size.SidebarUser - 8)
    userFrame.BackgroundColor3 = tokens.Color.PanelSoft
    userFrame.BackgroundTransparency = 0.62
    userFrame.BorderSizePixel = 0
    userFrame.Text = ""
    userFrame.AutoButtonColor = false
    userFrame.ZIndex = 5
    userFrame.Parent = sidebar
    corner(userFrame, 8)

    local avatar = Instance.new("ImageLabel")
    avatar.BackgroundColor3 = tokens.Color.Inset
    avatar.BorderSizePixel = 0
    avatar.Position = UDim2.fromOffset(10, 13)
    avatar.Size = UDim2.fromOffset(34, 34)
    avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(localPlayer.UserId) .. "&w=150&h=150"
    avatar.ScaleType = Enum.ScaleType.Crop
    avatar.ZIndex = 6
    avatar.Parent = userFrame
    corner(avatar, 17)

    deps.Typography.Label(userFrame, "User", tokens, localPlayer.DisplayName, UDim2.fromOffset(54, 11), UDim2.new(1, -78, 0, 19), tokens.Color.Text).ZIndex = 6
    deps.Typography.Label(userFrame, "UserSub", tokens, "UI TESTER", UDim2.fromOffset(54, 31), UDim2.new(1, -78, 0, 16), tokens.Color.TextDim).ZIndex = 6
    local userChevron = deps.Icons.Create(userFrame, "chevron_right", 13, tokens.Color.TextDim)
    userChevron.AnchorPoint = Vector2.new(1, 0.5)
    userChevron.Position = UDim2.new(1, -10, 0.5, 0)
    userChevron.ZIndex = 6

    -- RIGHT TOPBAR ------------------------------------------------------------
    local topbar = Instance.new("Frame")
    topbar.Name = "Topbar"
    topbar.Position = UDim2.fromOffset(0, 0)
    topbar.Size = UDim2.new(1, 0, 0, tokens.Size.Topbar)
    topbar.ZIndex = 3
    topbar.Parent = shell
    deps.Material.Topbar(topbar, tokens)
    corner(topbar,tokens.Size.RadiusShell)

    local saveTile = Instance.new("Frame")
    saveTile.Position = UDim2.fromOffset(15, 15)
    saveTile.Size = UDim2.fromOffset(32, 32)
    saveTile.BackgroundColor3 = tokens.Color.Inset
    saveTile.BackgroundTransparency = 0.10
    saveTile.BorderSizePixel = 0
    saveTile.ZIndex = 4
    saveTile.Parent = topbar
    corner(saveTile, 7)
    local saveIcon = deps.Icons.Create(saveTile, "save", 15, tokens.Color.TextMuted)
    saveIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    saveIcon.Position = UDim2.fromScale(0.5, 0.5)
    saveIcon.ZIndex = 5

    local function createTopSelect(x, width, initial)
        local button = Instance.new("TextButton")
        button.Position = UDim2.fromOffset(x, 13)
        button.Size = UDim2.fromOffset(width, 36)
        button.BackgroundColor3 = tokens.Color.Inset
        button.BackgroundTransparency = 0.34
        button.BorderSizePixel = 0
        button.Text = ""
        button.AutoButtonColor = false
        button.ZIndex = 4
        button.Parent = topbar
        corner(button, 7)

        local text = deps.Typography.Label(button, "TopSelect", tokens, initial, UDim2.fromOffset(12, 0), UDim2.new(1, -34, 1, 0), tokens.Color.TextMuted)
        text.ZIndex = 5
        local chevron = deps.Icons.Create(button, "chevron_down", 12, tokens.Color.TextDim)
        chevron.AnchorPoint = Vector2.new(1, 0.5)
        chevron.Position = UDim2.new(1, -10, 0.5, 0)
        chevron.ZIndex = 5
        return button, text
    end

    saveTile.Visible = false
    local pageButton, pageText = createTopSelect(252, 112, "Dashboard")
    local star = deps.Material.Star(topbar, UDim2.fromOffset(20, 16), 30, Color3.fromRGB(249,233,198), 5)
    local heading = deps.Typography.Label(topbar, "Brand", tokens, "SERENITY HUB", UDim2.fromOffset(62, 0), UDim2.fromOffset(182, tokens.Size.Topbar), tokens.Color.Text)
    heading.Font = Enum.Font.GothamBold
    heading.TextSize = 19
    heading.ZIndex = 5
    local scopeButton, scopeText = createTopSelect(170, 108, "Global")
    scopeButton.Visible = false

    local searchButton = Instance.new("TextButton")
    searchButton.AnchorPoint = Vector2.new(1, 0.5)
    searchButton.Position = UDim2.new(1, -51, 0.5, 0)
    searchButton.Size = UDim2.fromOffset(34, 34)
    searchButton.BackgroundTransparency = 1
    searchButton.Text = ""
    searchButton.AutoButtonColor = false
    searchButton.ZIndex = 4
    searchButton.Parent = topbar
    local searchIcon = deps.Icons.Create(searchButton, "search", 17, tokens.Color.TextMuted)
    searchIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    searchIcon.Position = UDim2.fromScale(0.5, 0.5)
    searchIcon.ZIndex = 5

    -- CONTENT -----------------------------------------------------------------
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.BackgroundTransparency = 1
    content.Position = UDim2.fromOffset(tokens.Size.Sidebar + 14, tokens.Size.Topbar + 10)
    content.Size = UDim2.new(1, -(tokens.Size.Sidebar + 28), 1, -(tokens.Size.Topbar + 22))
    content.ZIndex = 3
    content.Parent = shell

    local overlay = Instance.new("Frame")
    overlay.Name = "Overlay"
    overlay.BackgroundTransparency = 1
    overlay.Size = UDim2.fromScale(1, 1)
    overlay.ZIndex = 70
    overlay.Parent = shell
    deps.PopupHost = overlay

    makeDraggable(runtime, holder, topbar)
    makeDraggable(runtime, holder, heading)

    local pages = {}
    local navItems = {}
    local groups = {}
    local currentPage

    local app = {
        ScreenGui = screen,
        Holder = holder,
        Shell = shell,
        Sidebar = sidebar,
        Content = content,
        Overlay = overlay,
        Pages = pages,
        SearchButton = searchButton,
        PageButton = pageButton,
        ScopeButton = scopeButton,
        Acrylic = acrylic,
        ProfileButton = userFrame,
    }

    local function addGroupLabel(name, order)
        if not name or name == "" or groups[name] then return end
        groups[name] = true
        local label = deps.Typography.Label(navHolder, "NavGroup", tokens, string.upper(name), UDim2.new(), UDim2.new(1, 0, 0, tokens.Size.NavGroup), tokens.Color.TextDim)
        label.LayoutOrder = order
        label.TextYAlignment = Enum.TextYAlignment.Bottom
        local pad = Instance.new("UIPadding")
        pad.PaddingLeft = UDim.new(0, 8)
        pad.PaddingBottom = UDim.new(0, 3)
        pad.Parent = label
    end

    function app:AddPage(props)
        props = props or {}
        local id = props.Id or props.Title
        local accent = props.Accent or tokens.Color.Accent
        local order = (props.Order or (#navItems + 1)) + 4

        if props.Group then addGroupLabel(props.Group, order * 10 - 1) end

        local page = Instance.new("ScrollingFrame")
        page.Name = id
        page.Visible = false
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.Size = UDim2.fromScale(1, 1)
        page.CanvasSize = UDim2.new()
        page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        page.ScrollBarThickness = 2
        page.ScrollBarImageColor3 = accent
        page.ScrollBarImageTransparency = 0.56
        page.ScrollingDirection = Enum.ScrollingDirection.Y
        page.Parent = content

        local padding = Instance.new("UIPadding")
        padding.PaddingRight = UDim.new(0, 5)
        padding.PaddingBottom = UDim.new(0, 8)
        padding.Parent = page

        local list = Instance.new("UIListLayout")
        list.Padding = UDim.new(0, 10)
        list.SortOrder = Enum.SortOrder.LayoutOrder
        list.Parent = page

        local navItem = deps.NavItem.new(navHolder, deps, {
            Id = id,
            Title = props.Title or id,
            Icon = props.Icon or "info",
            Accent = accent,
            Order = order * 10,
            Callback = function() app:SelectPage(id) end,
        })

        local entry = {Id = id, Page = page, NavItem = navItem, Accent = accent, Title = props.Title or id}
        pages[id] = entry
        table.insert(navItems, entry)

        if not currentPage then app:SelectPage(id) end
        return page
    end

    function app:SelectPage(id)
        local target = pages[id]
        if not target then return end
        deps.PopupManager:Close()
        currentPage = id
        pageText.Text = target.Title
        for pageId, entry in pairs(pages) do
            local selected = pageId == id
            entry.Page.Visible = selected
            entry.NavItem:SetSelected(selected)
        end
    end

    function app:SetGlassQuality(quality)
        if acrylic then acrylic:SetQuality(quality) end
    end

    function app:SetBlur(enabled)
        if acrylic then acrylic:SetEnabled(enabled) end
    end

    function app:SetVisible(visible)
        deps.PopupManager:Close()
        holder.Visible = visible
        if acrylic then acrylic:SetVisible(visible) end
    end

    local minimize = Instance.new("TextButton")
    minimize.Size = UDim2.fromOffset(28, 28)
    minimize.Position = UDim2.new(1, -40, 0.5, -14)
    minimize.BackgroundTransparency = 1
    minimize.Text = "−"
    minimize.TextSize = 24
    minimize.TextColor3 = tokens.Color.TextMuted
    minimize.ZIndex = 5
    minimize.Parent = topbar
    local restore = Instance.new("TextButton")
    restore.Size = UDim2.fromOffset(44, 32)
    restore.Position = UDim2.new(0, 12, 0.5, -16)
    restore.Text = "SH"
    restore.TextColor3 = tokens.Color.Text
    restore.BackgroundColor3 = tokens.Color.Inset
    restore.Visible = false
    restore.Parent = screen
    corner(restore, 8)
    minimize.Activated:Connect(function() app:SetVisible(false) restore.Visible = true end)
    restore.Activated:Connect(function() app:SetVisible(true) restore.Visible = false end)

    local function createSearchPopup()
        if not holder.Visible then return end
        deps.PopupManager:Close()
        local popup = Instance.new("Frame")
        popup.AnchorPoint = Vector2.new(1, 0)
        popup.Position = UDim2.new(1, -16, 0, tokens.Size.Topbar - 2)
        popup.Size = UDim2.fromOffset(292, 300)
        popup.ZIndex = 80
        popup.Parent = overlay
        deps.Material.Popup(popup, tokens)

        local input = Instance.new("TextBox")
        input.Position = UDim2.fromOffset(8, 8)
        input.Size = UDim2.new(1, -16, 0, 34)
        input.Text = ""
        input.PlaceholderText = "Search pages..."
        input.PlaceholderColor3 = tokens.Color.TextDim
        input.TextColor3 = tokens.Color.Text
        input.TextSize = tokens.Type.Value
        input.Font = deps.Typography.Font.Medium
        input.TextXAlignment = Enum.TextXAlignment.Left
        input.ClearTextOnFocus = false
        input.ZIndex = 81
        input.Parent = popup
        deps.Material.Inset(input, tokens)
        local inputPad = Instance.new("UIPadding") inputPad.PaddingLeft = UDim.new(0, 10) inputPad.PaddingRight = UDim.new(0, 8) inputPad.Parent = input

        local listFrame = Instance.new("ScrollingFrame")
        listFrame.BackgroundTransparency = 1
        listFrame.BorderSizePixel = 0
        listFrame.Position = UDim2.fromOffset(8, 50)
        listFrame.Size = UDim2.new(1, -16, 1, -58)
        listFrame.CanvasSize = UDim2.new()
        listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
        listFrame.ScrollBarThickness = 2
        listFrame.ScrollBarImageColor3 = tokens.Color.Accent
        listFrame.ZIndex = 81
        listFrame.Parent = popup
        local ll = Instance.new("UIListLayout") ll.Padding = UDim.new(0, 3) ll.Parent = listFrame

        local rows = {}
        for _, entry in ipairs(navItems) do
            local row = Instance.new("TextButton")
            row.Size = UDim2.new(1, -2, 0, 35)
            row.BackgroundColor3 = tokens.Color.PanelSoft
            row.BackgroundTransparency = 0.44
            row.BorderSizePixel = 0
            row.Text = ""
            row.AutoButtonColor = false
            row.ZIndex = 82
            row.Parent = listFrame
            corner(row, 6)
            local icon = deps.Icons.Create(row, entry.NavItem.Icon.Name:gsub("Icon_", ""), 14, entry.Accent)
            icon.Position = UDim2.fromOffset(10, 10)
            icon.ZIndex = 83
            local text = deps.Typography.Label(row, "Value", tokens, entry.Title, UDim2.fromOffset(34, 0), UDim2.new(1, -42, 1, 0), tokens.Color.TextMuted)
            text.ZIndex = 83
            rows[entry.Id] = {Frame = row, Search = string.lower(entry.Title)}
            row.MouseButton1Click:Connect(function()
                app:SelectPage(entry.Id)
                deps.PopupManager:Close()
            end)
        end

        input:GetPropertyChangedSignal("Text"):Connect(function()
            local q = string.lower(input.Text or "")
            for _, data in pairs(rows) do
                data.Frame.Visible = q == "" or string.find(data.Search, q, 1, true) ~= nil
            end
        end)

        deps.PopupManager:Set(popup)
        task.defer(function() if input.Parent and not runtime.Destroyed then input:CaptureFocus() end end)
    end

    local function createScopePopup()
        deps.PopupManager:Close()
        local popup = Instance.new("Frame")
        popup.Position = UDim2.fromOffset(tokens.Size.Sidebar + 198, tokens.Size.Topbar - 2)
        popup.Size = UDim2.fromOffset(108, 116)
        popup.ZIndex = 80
        popup.Parent = overlay
        deps.Material.Popup(popup, tokens)

        local list = Instance.new("UIListLayout")
        list.Padding = UDim.new(0, 3)
        list.Parent = popup
        local pad = Instance.new("UIPadding")
        pad.PaddingLeft = UDim.new(0, 6)
        pad.PaddingRight = UDim.new(0, 6)
        pad.PaddingTop = UDim.new(0, 6)
        pad.Parent = popup

        for _, name in ipairs({"Global", "Session", "Safe"}) do
            local item = Instance.new("TextButton")
            item.Size = UDim2.new(1, 0, 0, 30)
            item.BackgroundColor3 = tokens.Color.PanelSoft
            item.BackgroundTransparency = name == scopeText.Text and 0.14 or 0.56
            item.BorderSizePixel = 0
            item.Text = name
            item.TextColor3 = name == scopeText.Text and tokens.Color.Text or tokens.Color.TextMuted
            item.TextSize = tokens.Type.Value
            item.Font = deps.Typography.Font.Medium
            item.AutoButtonColor = false
            item.ZIndex = 81
            item.Parent = popup
            corner(item, 6)
            item.MouseButton1Click:Connect(function()
                scopeText.Text = name
                deps.PopupManager:Close()
            end)
        end
        deps.PopupManager:Set(popup)
    end

    runtime:TrackConnection(UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local active = deps.PopupManager.Active
        if not active then return end
        local p, size = active.AbsolutePosition, active.AbsoluteSize
        local point = UserInputService:GetMouseLocation()
        if input.UserInputType == Enum.UserInputType.Touch then point = Vector2.new(input.Position.X, input.Position.Y) end
        local inset = GuiService:GetGuiInset()
        point = point - inset
        if point.X < p.X or point.Y < p.Y or point.X > p.X + size.X or point.Y > p.Y + size.Y then deps.PopupManager:Close() end
    end))

    searchButton.MouseButton1Click:Connect(createSearchPopup)
    pageButton.MouseButton1Click:Connect(createSearchPopup)
    scopeButton.MouseButton1Click:Connect(createScopePopup)

    runtime:TrackConnection(UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.K and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            createSearchPopup()
        elseif input.KeyCode == Enum.KeyCode.RightControl then
            app:SetVisible(not holder.Visible)
            restore.Visible = not holder.Visible
        elseif input.KeyCode == Enum.KeyCode.Escape then
            deps.PopupManager:Close()
        end
    end))

    task.spawn(function()
        local ok, info = pcall(function() return MarketplaceService:GetProductInfo(game.PlaceId) end)
        if not runtime.Destroyed and ok and info and info.Name then
            brandSub.Text = info.Name
        end
    end)

    return app
end

return Desktop

end)()
-- SERENITY HUB // NEXT UI M4 COMPACT
-- Visual playground only. No game remotes or automation actions are executed.

local function loadModule(path) return assert(modules[path], "Missing bundled module: " .. path) end

local UserInputService = game:GetService("UserInputService")

local RuntimeClass = loadModule("src/core/Runtime.lua")
local Tokens = loadModule("src/core/Tokens.lua")
local Typography = loadModule("src/core/Typography.lua")
local Motion = loadModule("src/core/Motion.lua")
local Material = loadModule("src/core/Material.lua")
local AcrylicEngine = loadModule("src/core/AcrylicEngine.lua")
local Icons = loadModule("src/core/Icons.lua")
local PopupManagerClass = loadModule("src/core/PopupManager.lua")

local NavItem = loadModule("src/components/NavItem.lua")
local Section = loadModule("src/components/Section.lua")
local Toggle = loadModule("src/components/Toggle.lua")
local Slider = loadModule("src/components/Slider.lua")
local Select = loadModule("src/components/Select.lua")
local ColumnLayout = loadModule("src/components/ColumnLayout.lua")
local Desktop = loadModule("src/renderers/Desktop.lua")

local G = (getgenv and getgenv()) or _G
for _, oldKey in ipairs({"__SERENITY_NEW_UI_GLASS_LAB_M2", "__SERENITY_NEW_UI_PRECISION_M3", "__SERENITY_NEW_UI_COMPACT_M4"}) do
    if G[oldKey] and G[oldKey].Destroy then
        pcall(function() G[oldKey]:Destroy() end)
    end
end

local KEY = "__SERENITY_NEW_UI_COMPACT_M4"
local runtime = RuntimeClass.new(KEY)
G[KEY] = runtime
runtime:TrackCleanup(function()
    if G[KEY] == runtime then G[KEY] = nil end
end)

local deps = {
    Runtime = runtime,
    Tokens = Tokens,
    Typography = Typography,
    Motion = Motion,
    Material = Material,
    AcrylicEngine = AcrylicEngine,
    Icons = Icons,
    PopupManager = PopupManagerClass.new(),
    UserInputService = UserInputService,
    NavItem = NavItem,
}

local app = Desktop.Mount(deps, {
    Title = "SERENITY HUB",
    Subtitle = "UI PLAYGROUND",
    BlurSize = 3,
})

local dashboard = app:AddPage({Id="Dashboard", Title="Dashboard", Icon="dashboard", Accent=Tokens.Color.Accent, Order=-2})
local about = app:AddPage({Id="About", Title="About", Icon="info", Accent=Tokens.Color.Cyan, Order=-3})
local automation = app:AddPage({Id="Automation", Title="Automation", Icon="automation", Accent=Tokens.Color.Accent, Group="Main", Order=1})
local progression = app:AddPage({Id="Progression", Title="Progression", Icon="progression", Accent=Tokens.Color.Lavender, Group="Main", Order=2})
local shop = app:AddPage({Id="Shop", Title="Shop", Icon="shop", Accent=Tokens.Color.Amber, Group="Common", Order=3})
local server = app:AddPage({Id="Server", Title="Server", Icon="server", Accent=Tokens.Color.Cyan, Group="Common", Order=4})
local webhook = app:AddPage({Id="Webhook", Title="Webhook", Icon="webhook", Accent=Tokens.Color.Pink, Group="Common", Order=5})
local misc = app:AddPage({Id="Misc", Title="Misc", Icon="misc", Accent=Tokens.Color.Mint, Group="Common", Order=6})
local settings = app:AddPage({Id="Settings", Title="Settings", Icon="settings", Accent=Tokens.Color.Pink, Group="System", Order=7})

-- AUTOMATION ---------------------------------------------------------------
local autoCols = ColumnLayout.new(automation, deps, {Gap=12, RowGap=12})

local main = Section.new(autoCols.Left, deps, {Title="Main"})
Toggle.new(main.Body, deps, {Title="Enabled", Default=true, Settings=true})
Toggle.new(main.Body, deps, {Title="Auto Roll", Default=true, Settings=true})
Toggle.new(main.Body, deps, {Title="Automatic Collect", Default=true})
Toggle.new(main.Body, deps, {Title="Fast Actions", Default=true})
Slider.new(main.Body, deps, {Title="Action Delay", Min=0, Max=2, Step=0.1, Default=0.2, Suffix="s"})

local selection = Section.new(autoCols.Left, deps, {Title="Selection"})
Select.new(selection.Body, deps, {Title="Target Priority", Options={"Highest Value","Nearest","Lowest HP","Newest"}, Default="Highest Value"})
Select.new(selection.Body, deps, {Title="Minimum Rarity", Options={"Common","Rare","Epic","Legendary","Mythic"}, Default="Epic"})
Select.new(selection.Body, deps, {Title="Target Set", Options={"All Valid","Selected Only","Whitelist"}, Default="Selected Only"})
Slider.new(selection.Body, deps, {Title="Priority Weight", Min=0, Max=100, Step=1, Default=68, Suffix="%", Settings=true})
Toggle.new(selection.Body, deps, {Title="Smart Priority", Default=true})

local other = Section.new(autoCols.Right, deps, {Title="Other"})
Select.new(other.Body, deps, {Title="History", Options={"Off","Low","Medium","High"}, Default="High"})
Toggle.new(other.Body, deps, {Title="Auto Sell", Default=true})
Toggle.new(other.Body, deps, {Title="Auto Upgrade", Default=true})
Toggle.new(other.Body, deps, {Title="Auto Restock", Default=true})
Toggle.new(other.Body, deps, {Title="Quick Retry", Default=false})
Slider.new(other.Body, deps, {Title="Retry Delay", Min=0, Max=10, Step=0.5, Default=1.5, Suffix="s"})

local routes = Section.new(autoCols.Right, deps, {Title="Routing"})
Toggle.new(routes.Body, deps, {Title="Story", Default=true, Settings=true})
Toggle.new(routes.Body, deps, {Title="Tower", Default=true, Settings=true})
Toggle.new(routes.Body, deps, {Title="Expedition", Default=false, Settings=true})
Select.new(routes.Body, deps, {Title="Route Mode", Options={"Balanced","Fastest","Safest"}, Default="Balanced"})

-- PROGRESSION --------------------------------------------------------------
local progCols = ColumnLayout.new(progression, deps, {Gap=12, RowGap=12})
local story = Section.new(progCols.Left, deps, {Title="Story"})
Toggle.new(story.Body, deps, {Title="Auto Story", Default=true, Settings=true})
Select.new(story.Body, deps, {Title="Mode", Options={"Auto Pick","Selected Stage"}, Default="Auto Pick"})
Select.new(story.Body, deps, {Title="Difficulty", Options={"Normal","Hard","Highest"}, Default="Highest"})
Slider.new(story.Body, deps, {Title="Retry Delay", Min=0, Max=15, Step=0.5, Default=1.5, Suffix="s"})

local upgrades = Section.new(progCols.Left, deps, {Title="Upgrades"})
Toggle.new(upgrades.Body, deps, {Title="Auto Trait", Default=false, Settings=true})
Toggle.new(upgrades.Body, deps, {Title="Auto Gem", Default=false, Settings=true})
Toggle.new(upgrades.Body, deps, {Title="Auto Skill", Default=true, Settings=true})
Select.new(upgrades.Body, deps, {Title="Priority", Options={"Damage","Speed","Balanced"}, Default="Balanced"})

local tower = Section.new(progCols.Right, deps, {Title="Tower"})
Toggle.new(tower.Body, deps, {Title="Auto Tower", Default=true, Settings=true})
Select.new(tower.Body, deps, {Title="Floor", Options={"Highest Available","25","50","75","100"}, Default="Highest Available"})
Slider.new(tower.Body, deps, {Title="Retry Delay", Min=1, Max=30, Step=1, Default=5, Suffix="s"})
Toggle.new(tower.Body, deps, {Title="Continue After Clear", Default=true})

local expedition = Section.new(progCols.Right, deps, {Title="Expedition"})
Toggle.new(expedition.Body, deps, {Title="Auto Expedition", Default=true, Settings=true})
Select.new(expedition.Body, deps, {Title="Location", Options={"Forest","Ruins","Abyss","Sanctum"}, Default="Ruins"})
Select.new(expedition.Body, deps, {Title="Aura Mode", Options={"Best","Whitelist","Any"}, Default="Best"})
Toggle.new(expedition.Body, deps, {Title="Auto Claim", Default=true})

-- SHOP ---------------------------------------------------------------------
local shopCols = ColumnLayout.new(shop, deps, {Gap=12, RowGap=12})
local petShop = Section.new(shopCols.Left, deps, {Title="Pet Shop"})
Toggle.new(petShop.Body, deps, {Title="Auto Buy", Default=false, Settings=true})
Select.new(petShop.Body, deps, {Title="Pet", Options={"Wolf","Fox","Swan","Turkey","Dragon"}, Default="Wolf"})
Slider.new(petShop.Body, deps, {Title="Amount", Min=1, Max=100, Step=1, Default=5})
Toggle.new(petShop.Body, deps, {Title="Equip Best", Default=true})

local gearShop = Section.new(shopCols.Left, deps, {Title="Gear"})
Toggle.new(gearShop.Body, deps, {Title="Auto Buy Gear", Default=false, Settings=true})
Select.new(gearShop.Body, deps, {Title="Quality", Options={"Any","Rare+","Epic+","Best"}, Default="Epic+"})
Toggle.new(gearShop.Body, deps, {Title="Auto Equip", Default=true})

local safety = Section.new(shopCols.Right, deps, {Title="Safety"})
Toggle.new(safety.Body, deps, {Title="Block Paid Routes", Default=true})
Toggle.new(safety.Body, deps, {Title="Require Confirmation", Default=true})
Toggle.new(safety.Body, deps, {Title="Affordability Check", Default=true})
Select.new(safety.Body, deps, {Title="Purchase Mode", Options={"Whitelist","Selected Only","Manual"}, Default="Selected Only"})

local limits = Section.new(shopCols.Right, deps, {Title="Limits"})
Slider.new(limits.Body, deps, {Title="Max Per Cycle", Min=1, Max=100, Step=1, Default=10})
Slider.new(limits.Body, deps, {Title="Reserve Currency", Min=0, Max=100000, Step=1000, Default=10000})
Toggle.new(limits.Body, deps, {Title="Pause When Low", Default=true})

-- SERVER -------------------------------------------------------------------
local serverCols = ColumnLayout.new(server, deps, {Gap=12, RowGap=12})
local session = Section.new(serverCols.Left, deps, {Title="Session"})
Toggle.new(session.Body, deps, {Title="Reconnect", Default=false})
Select.new(session.Body, deps, {Title="Join Mode", Options={"Current","Lowest Players","Private"}, Default="Current"})
Toggle.new(session.Body, deps, {Title="Server Hop", Default=false, Settings=true})

local diagnostics = Section.new(serverCols.Right, deps, {Title="Diagnostics"})
Toggle.new(diagnostics.Body, deps, {Title="Live Metrics", Default=true})
Toggle.new(diagnostics.Body, deps, {Title="Worker Status", Default=true})
Toggle.new(diagnostics.Body, deps, {Title="Route Status", Default=true})
Slider.new(diagnostics.Body, deps, {Title="Refresh Rate", Min=0.5, Max=5, Step=0.5, Default=1, Suffix="s"})

-- WEBHOOK ------------------------------------------------------------------
local hookCols = ColumnLayout.new(webhook, deps, {Gap=12, RowGap=12})
local delivery = Section.new(hookCols.Left, deps, {Title="Delivery"})
Toggle.new(delivery.Body, deps, {Title="Enabled", Default=false, Settings=true})
Select.new(delivery.Body, deps, {Title="Minimum Event", Options={"Any","Rare+","Legendary+","Errors"}, Default="Legendary+"})
Toggle.new(delivery.Body, deps, {Title="Include Session", Default=true})
Toggle.new(delivery.Body, deps, {Title="Include Screenshot", Default=false})

local alerts = Section.new(hookCols.Right, deps, {Title="Alerts"})
Toggle.new(alerts.Body, deps, {Title="Rare Finds", Default=true})
Toggle.new(alerts.Body, deps, {Title="Errors", Default=true})
Toggle.new(alerts.Body, deps, {Title="Disconnect", Default=true})
Toggle.new(alerts.Body, deps, {Title="Milestones", Default=false})

-- UI SETTINGS: only connected behavior is exposed.
local miscCols = ColumnLayout.new(misc, deps, {})
local utility = Section.new(miscCols.Left, deps, {Title="Interaction"})
Toggle.new(utility.Body, deps, {Title="Reduced Motion", Default=false, Callback=function(v) Motion.Reduced = v end})
local settingsCols = ColumnLayout.new(settings, deps, {})

local themeBindings={}
local originalColors={}
for key,color in pairs(Tokens.Color) do originalColors[key]=color end
local function applyTheme(name)
    local hue=({Ocean=0.57,Lavender=0.72,Rose=0.94,Emerald=0.43,Slate=0.60})[name] or 0.57
    for key,original in pairs(originalColors) do
        local _,sat,val=original:ToHSV()
        local semantic=key=="Mint" or key=="Red" or key=="Amber"
        Tokens.Color[key]=semantic and original or Color3.fromHSV(hue,name=="Slate" and sat*0.18 or sat,val)
    end
    for _,object in ipairs(app.ScreenGui:GetDescendants()) do
        local props={}
        if object:IsA("GuiObject") then table.insert(props,"BackgroundColor3") end
        if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then table.insert(props,"TextColor3") end
        if object:IsA("UIStroke") then table.insert(props,"Color") end
        if object:IsA("ImageLabel") or object:IsA("ImageButton") then table.insert(props,"ImageColor3") end
        for _,prop in ipairs(props) do
            themeBindings[object]=themeBindings[object] or {}
            local binding=themeBindings[object][prop]
            if not binding then
                local original=object[prop]
                for key,color in pairs(originalColors) do
                    if original==color then binding=key break end
                end
                if not binding then binding=original end
                themeBindings[object][prop]=binding
            end
            if type(binding)=="string" then object[prop]=Tokens.Color[binding]
            elseif object.Name~="" and object.Parent and object.Parent.Name~="SerenityStar" then
                local _,sat,val=binding:ToHSV()
                if sat>0.25 and val<0.65 then object[prop]=Color3.fromHSV(hue,name=="Slate" and sat*0.18 or sat,val) end
            end
        end
    end
end

local appearance = Section.new(settingsCols.Left, deps, {Title="Appearance"})
Select.new(appearance.Body,deps,{Title="Color theme",Options={"Ocean","Lavender","Rose","Emerald","Slate"},Default="Ocean",Callback=applyTheme})
Select.new(appearance.Body, deps, {Title="Glass Quality", Options={"Off","Basic","Enhanced"}, Default="Off", Callback=function(v) app:SetGlassQuality(v) end})
Slider.new(appearance.Body, deps, {Title="Blur Amount", Min=0, Max=8, Step=1, Default=3, Callback=function(v) if app.Acrylic then app.Acrylic:SetAmount(v) end end})
local controls = Section.new(settingsCols.Right, deps, {Title="Component Test"})
Toggle.new(controls.Body, deps, {Title="Enabled Toggle", Default=true})
Toggle.new(controls.Body, deps, {Title="Disabled Toggle", Default=false, Enabled=false})
Slider.new(controls.Body, deps, {Title="Slider", Min=0, Max=100, Step=1, Default=50, Suffix="%"})
Select.new(controls.Body, deps, {Title="Dropdown", Options={"Option A","Option B","Option C"}, Default="Option A"})

-- Dashboard: local UI preview; no simulated live service counts.
do
    local function card(parent, height, color)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, -4, 0, height)
        frame.Parent = parent
        Material.Section(frame, Tokens)
        if color then frame.BackgroundColor3 = color end
        return frame
    end
    local function label(parent, text, x, y, w, h, size, color)
        local l = Typography.Label(parent, "Control", Tokens, text, UDim2.fromOffset(x,y), UDim2.new(1,w,0,h), color or Tokens.Color.Text)
        l.TextSize = size
        return l
    end
    local title = card(dashboard, 53)
    title.BackgroundTransparency = 1
    title:FindFirstChild("PanelStroke"):Destroy()
    label(title,"Dashboard",0,0,0,29,23)
    label(title,"Everything you need, in one place.",0,29,0,22,12,Tokens.Color.TextMuted)
    local metrics = Instance.new("Frame")
    metrics.Size = UDim2.new(1,-4,0,58)
    metrics.BackgroundTransparency = 1
    metrics.Parent = dashboard
    for i, entry in ipairs({{"SESSION", "Preview"},{"ACTIVE NOW", "Not connected"},{"STATUS", "UI ready"}}) do
        local tile = card(metrics,58)
        tile.Size = UDim2.new(1/3,-7,1,0)
        tile.Position = UDim2.new((i-1)/3,(i-1)*3,0,0)
        label(tile,entry[1],10,7,-20,17,9,Tokens.Color.TextMuted)
        label(tile,entry[2],10,26,-20,23,13,i==3 and Tokens.Color.Mint or Tokens.Color.Text)
    end
    local welcome = card(dashboard,60,Color3.fromRGB(36,83,119))
    Material.Star(welcome,UDim2.fromOffset(17,16),28,Color3.fromRGB(249,233,198),2)
    label(welcome,"Welcome back",57,8,-70,22,16)
    label(welcome,"Choose a category to get started.",57,31,-70,19,11,Tokens.Color.TextMuted)
    local cols = ColumnLayout.new(dashboard,deps,{LayoutOrder=4,Gap=10})
    local quick = Section.new(cols.Left,deps,{Title="Quick settings"})
    Toggle.new(quick.Body,deps,{Title="Reduced motion",Default=false,Callback=function(v) Motion.Reduced=v end})
    Select.new(quick.Body,deps,{Title="Glass quality",Options={"Off","Basic","Enhanced"},Default="Off",Callback=function(v) app:SetGlassQuality(v) end})
    local news = Section.new(cols.Right,deps,{Title="What's new"})
    for _,item in ipairs({{"Refreshed blue theme","Ivory stars and softer panels."},{"Compact navigation","Readable text, less clutter."},{"Smoother controls","Long sliders and clear selections."}}) do
        local row=Instance.new("Frame")
        row.Size=UDim2.new(1,0,0,48)
        row.BackgroundTransparency=1
        row.Parent=news.Body
        label(row,item[1],12,5,-24,20,12)
        label(row,item[2],12,25,-24,18,10,Tokens.Color.TextMuted)
    end
    local community=card(dashboard,51)
    community.LayoutOrder=5
    label(community,"Community",13,5,-135,21,14)
    label(community,"News, releases and updates.",13,27,-135,18,11,Tokens.Color.TextMuted)
    local button=Instance.new("TextButton")
    button.Size=UDim2.fromOffset(100,31)
    button.Position=UDim2.new(1,-113,0.5,-15)
    button.Text="Discord  ›"
    button.Font=Enum.Font.GothamMedium
    button.TextSize=12
    button.TextColor3=Tokens.Color.Text
    button.Parent=community
    Material.Inset(button,Tokens)
    button.Activated:Connect(function()
        local copy = setclipboard or toclipboard
        if copy then
            local ok=pcall(copy,"https://discord.gg/pWPs7428wE")
            button.Text=ok and "Copied" or "Copy failed"
        else button.Text="Copy unavailable" end
    end)
    title.LayoutOrder=1;metrics.LayoutOrder=2;welcome.LayoutOrder=3
    local info=card(about,98)
    label(info,"Serenity preview",14,12,-28,26,18)
    local body=label(info,"A compact blue interface. Gameplay controls are demonstrations; live statistics are not connected in this test.",14,43,-28,45,12,Tokens.Color.TextMuted)
    body.TextWrapped=true
end


-- Interactive component laboratory. All actions remain local to this preview.
do
    local player=game:GetService("Players").LocalPlayer
    local profile=app:AddPage({Id="Profile",Title="Profile",Icon="info",Group="System",Order=8})
    app.ProfileButton.Activated:Connect(function() app:SelectPage("Profile") end)
    local lab=app:AddPage({Id="Playground",Title="Playground",Icon="settings",Group="System",Order=9})
    local function text(parent,message,height)
        local label=Typography.Label(parent,"Control",Tokens,message,UDim2.new(),UDim2.new(1,-20,0,height or 32),Tokens.Color.Text)
        label.TextWrapped=true
        return label
    end
    local function button(parent,title,callback)
        local b=Instance.new("TextButton")
        b.Size=UDim2.new(1,0,0,34)
        b.Text=title;b.TextSize=12;b.Font=Enum.Font.GothamMedium
        b.TextColor3=Tokens.Color.Text;b.Parent=parent
        Material.Inset(b,Tokens)
        b.Activated:Connect(callback)
        return b
    end
    local profileSection=Section.new(profile,deps,{Title="Your profile"})
    text(profileSection.Body,player.DisplayName,32)
    text(profileSection.Body,"@"..player.Name,28)
    text(profileSection.Body,"User ID: "..player.UserId,28)
    text(profileSection.Body,"Local UI preview — no account changes.",32)
    button(profileSection.Body,"Open component playground",function() app:SelectPage("Playground") end)
    local columns=ColumnLayout.new(lab,deps,{Gap=10})
    local status=Section.new(columns.Left,deps,{Title="Interaction result"})
    local result=text(status.Body,"Ready — try a control.",48)
    local function report(value) result.Text=tostring(value) end
    local actions=Section.new(columns.Left,deps,{Title="Buttons & toggles",Collapsible=true})
    local count=0
    button(actions.Body,"Click counter",function() count=count+1;report("Button clicks: "..count) end)
    local disabled=button(actions.Body,"Disabled button",function() end)
    disabled.Active=false;disabled.AutoButtonColor=false;disabled.TextTransparency=0.6
    Toggle.new(actions.Body,deps,{Title="Enabled toggle",Default=true,Callback=function(v) report("Toggle: "..tostring(v)) end})
    Toggle.new(actions.Body,deps,{Title="Disabled toggle",Enabled=false,Default=false})
    local numbers=Section.new(columns.Left,deps,{Title="Drag / type / wheel"})
    Slider.new(numbers.Body,deps,{Title="Amount (1–100)",Min=1,Max=100,Step=1,Default=5,Callback=report})
    Slider.new(numbers.Body,deps,{Title="Delay (0–2 seconds)",Min=0,Max=2,Step=0.1,Default=0.5,Suffix="s",Callback=report})
    Slider.new(numbers.Body,deps,{Title="Signed (-50–50)",Min=-50,Max=50,Step=5,Default=0,Callback=report})
    local choices=Section.new(columns.Right,deps,{Title="Dropdown & multi-select",Collapsible=true})
    local options={};for i=1,30 do options[i]="Option "..i end
    Select.new(choices.Body,deps,{Title="Scrollable options",Options=options,Default=options[1],Callback=report})
    local selected={}
    for _,name in ipairs({"Rare","Epic","Legendary"}) do
        Toggle.new(choices.Body,deps,{Title=name,Default=false,Callback=function(v)
            selected[name]=v
            local names={};for _,n in ipairs({"Rare","Epic","Legendary"}) do if selected[n] then table.insert(names,n) end end
            report("Selected: "..(#names>0 and table.concat(names,", ") or "none"))
        end})
    end
    local inputs=Section.new(columns.Right,deps,{Title="Text input"})
    local input=Instance.new("TextBox")
    input.Size=UDim2.new(1,0,0,34);input.Text="";input.PlaceholderText="Type here, then press Enter"
    input.ClearTextOnFocus=false;input.TextSize=12;input.Font=Enum.Font.GothamMedium
    input.TextColor3=Tokens.Color.Text;input.PlaceholderColor3=Tokens.Color.TextMuted
    input.Parent=inputs.Body;Material.Inset(input,Tokens)
    input.FocusLost:Connect(function(enter) if enter then report("Submitted: "..input.Text:sub(1,100)) end end)
    local list=Section.new(columns.Right,deps,{Title="Searchable scrolling list"})
    local search=input:Clone();search.PlaceholderText="Filter items";search.Parent=list.Body
    local scroller=Instance.new("ScrollingFrame")
    scroller.Size=UDim2.new(1,0,0,140);scroller.BackgroundTransparency=1;scroller.BorderSizePixel=0
    scroller.CanvasSize=UDim2.new();scroller.AutomaticCanvasSize=Enum.AutomaticSize.Y
    scroller.ScrollBarThickness=3;scroller.Parent=list.Body
    local layout=Instance.new("UIListLayout");layout.Padding=UDim.new(0,3);layout.Parent=scroller
    local rows={}
    for i=1,25 do
        local name=string.format("Test item %02d",i)
        rows[i]=button(scroller,name,function() report("Picked "..name) end)
    end
    search:GetPropertyChangedSignal("Text"):Connect(function()
        for _,row in ipairs(rows) do row.Visible=string.find(string.lower(row.Text),string.lower(search.Text),1,true)~=nil end
        scroller.CanvasPosition=Vector2.new()
    end)
    local confirm=Section.new(columns.Left,deps,{Title="Confirmation"})
    local armed=false
    local confirmButton
    confirmButton=button(confirm.Body,"Test confirmation",function()
        if armed then armed=false;confirmButton.Text="Test confirmation";report("Confirmed — no external action performed.")
        else armed=true;confirmButton.Text="Click again to confirm";report("Awaiting confirmation") end
    end)
    button(confirm.Body,"Cancel",function() armed=false;confirmButton.Text="Test confirmation";report("Cancelled") end)
end

app:SelectPage("Dashboard")
app:SetGlassQuality("Off")
print("SERENITY M4.4 PLAYGROUND | VISUAL TEST ONLY | RightCtrl: toggle | Ctrl+K: search")




