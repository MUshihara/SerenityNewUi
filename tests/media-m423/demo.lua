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
    TextDim = Color3.fromRGB(161, 173, 192),

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
    frame:SetAttribute("GlassRole", "Shell")
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
    frame:SetAttribute("GlassRole", "Sidebar")
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
    frame:SetAttribute("GlassRole", "Topbar")
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
    frame:SetAttribute("GlassRole", "Section")
    frame.BackgroundColor3 = tokens.Color.Panel
    frame.BackgroundTransparency = tokens.Material.PanelTransparency
    frame.BorderSizePixel = 0
    corner(frame, tokens.Size.RadiusPanel, "PanelCorner")
    stroke(frame, tokens.Color.Stroke, 0.56, 1, "PanelStroke")
    local sheen=Instance.new("UIGradient")
    sheen.Name="GlassSheen"
    sheen.Rotation=110
    sheen.Color=ColorSequence.new(Color3.fromRGB(255,255,255),Color3.fromRGB(191,212,235))
    sheen.Transparency=NumberSequence.new({
        NumberSequenceKeypoint.new(0,0.04),
        NumberSequenceKeypoint.new(0.42,0),
        NumberSequenceKeypoint.new(1,0.03)
    })
    sheen.Parent=frame
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
-- Small vector emblems; no font glyphs or external image downloads.
function Material.Emblem(parent,position,size,color,kind)
    local root=Instance.new("Frame")
    root.Name="SerenityEmblem";root.BackgroundTransparency=1
    root.Position=position;root.Size=UDim2.fromOffset(size,size);root.Parent=parent
    local function line(x1,y1,x2,y2,width)
        local dx,dy=x2-x1,y2-y1
        local f=Instance.new("Frame");f.BorderSizePixel=0;f.BackgroundColor3=color
        f.AnchorPoint=Vector2.new(0.5,0.5);f.Position=UDim2.fromOffset((x1+x2)*size/2,(y1+y2)*size/2)
        f.Size=UDim2.fromOffset(math.sqrt(dx*dx+dy*dy)*size,width or 1.5)
        f.Rotation=math.deg(math.atan2(dy,dx));f.ZIndex=2;f.Parent=root
        local c=Instance.new("UICorner");c.CornerRadius=UDim.new(1,0);c.Parent=f
    end
    if kind=="compass" then
        -- Open orbital arc around an asymmetric navigation needle.
        for i=0,13 do
            local a=math.rad(35+i*21);local b=math.rad(35+(i+1)*21)
            line(0.5+0.43*math.cos(a),0.5+0.43*math.sin(a),0.5+0.43*math.cos(b),0.5+0.43*math.sin(b),1.2)
        end
        line(0.68,0.23,0.57,0.58,1.8);line(0.57,0.58,0.29,0.74,1.8)
        line(0.29,0.74,0.41,0.39,1.8);line(0.41,0.39,0.68,0.23,1.8)
        line(0.41,0.39,0.57,0.58,1.2)
    else
        -- Two interlocking open loops: connection and community.
        for _,offset in ipairs({0,0.3}) do
            for i=0,11 do
                local a=math.rad(-50+i*25);local b=math.rad(-50+(i+1)*25)
                line(0.34+offset+0.25*math.cos(a),0.39+offset*0.5+0.25*math.sin(a),0.34+offset+0.25*math.cos(b),0.39+offset*0.5+0.25*math.sin(b),1.6)
            end
        end
        line(0.38,0.62,0.65,0.34,1.8)
    end
    return root
end

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
    if self.OnChange then self.OnChange(nil) end
end

function PopupManager:Set(frame)
    self:Close()
    self.Active = frame
    frame.Active=true
    if self.OnChange then self.OnChange(frame) end
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

    local tile=Instance.new("Frame")
    tile.Name="NavGlassTile";tile.Size=UDim2.fromOffset(28,28)
    tile.AnchorPoint=Vector2.new(0.5,0.5);tile.Position=UDim2.new(0,22,0.5,0)
    tile.BackgroundColor3=tokens.Color.PanelSoft;tile.BackgroundTransparency=0.5
    tile.BorderSizePixel=0;tile.Parent=row
    local rounding=Instance.new("UICorner");rounding.CornerRadius=UDim.new(0,8);rounding.Parent=tile
    local rim=Instance.new("UIStroke");rim.Name="NavGlassEdge";rim.Color=Color3.new(1,1,1)
    rim.Transparency=0.72;rim.Thickness=1;rim.Parent=tile
    local spectrum=Instance.new("UIGradient");spectrum.Rotation=35
    spectrum.Color=ColorSequence.new(Color3.fromRGB(135,217,255),Color3.fromRGB(222,175,243));spectrum.Parent=rim
    local shine=Instance.new("UIGradient");shine.Rotation=115
    shine.Color=ColorSequence.new(Color3.new(1,1,1),Color3.fromRGB(139,167,204));shine.Parent=tile
    local scale=Instance.new("UIScale");scale.Parent=tile
    local marker=Instance.new("Frame");marker.Name="SelectionMarker";marker.BorderSizePixel=0
    marker.Size=UDim2.fromOffset(2,16);marker.Position=UDim2.new(0,1,0.5,-8)
    marker.BackgroundColor3=tokens.Color.Accent;marker.BackgroundTransparency=1;marker.Parent=row
    local curve=Instance.new("UICorner");curve.CornerRadius=UDim.new(1,0);curve.Parent=marker
    local icon = deps.Icons.Create(tile, props.Icon or "info", tokens.Size.NavIcon-2, tokens.Color.TextMuted)
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.Position = UDim2.fromScale(0.5,0.5)

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
        Tile=tile, Rim=rim, Marker=marker, Scale=scale,
        Accent = props.Accent or tokens.Color.Accent,
        Selected = false,
        Callback = props.Callback,
        Deps = deps,
    }, NavItem)

    row.MouseEnter:Connect(function()
        deps.Motion:Tween(tile,"Hover",{BackgroundTransparency=0.18})
        deps.Motion:Tween(rim,"Hover",{Transparency=0.25})
        deps.Motion:Tween(label,"Hover",{Position=UDim2.fromOffset(deps.Motion.Reduced and 44 or 46,0)})
        if not self.Selected then
            row.BackgroundColor3 = tokens.Color.NavHover
            deps.Motion:Tween(row, "Hover", {BackgroundTransparency = 0.34})
            label.TextColor3 = tokens.Color.Text
            icon.ImageColor3 = tokens.Color.Text
        end
    end)

    row.MouseLeave:Connect(function()
        deps.Motion:Tween(tile,"Hover",{BackgroundTransparency=self.Selected and 0.2 or 0.5})
        deps.Motion:Tween(rim,"Hover",{Transparency=self.Selected and 0.3 or 0.72})
        deps.Motion:Tween(label,"Hover",{Position=UDim2.fromOffset(44,0)})
        deps.Motion:Tween(scale,"Hover",{Scale=1})
        if not self.Selected then
            deps.Motion:Tween(row, "Hover", {BackgroundTransparency = 1})
            label.TextColor3 = tokens.Color.TextMuted
            icon.ImageColor3 = tokens.Color.TextMuted
        end
    end)

    row.MouseButton1Down:Connect(function()
        deps.Motion:Tween(scale,0.08,{Scale=deps.Motion.Reduced and 1 or 0.9})
    end)
    row.MouseButton1Up:Connect(function()
        deps.Motion:Tween(scale,"Select",{Scale=1})
    end)
    row.Activated:Connect(function()
        if self.Callback then self.Callback() end
    end)

    return self
end

function NavItem:SetSelected(selected)
    self.Selected = not not selected
    local tokens = self.Deps.Tokens
    self.Row.BackgroundColor3=tokens.Color.NavActive
    self.Deps.Motion:Tween(self.Row,"Select",{BackgroundTransparency=self.Selected and 0.18 or 1})
    self.Tile.BackgroundColor3=tokens.Color.PanelSoft
    self.Marker.BackgroundColor3=tokens.Color.Accent
    self.Deps.Motion:Tween(self.Marker,"Select",{BackgroundTransparency=self.Selected and 0 or 1})
    self.Deps.Motion:Tween(self.Tile,"Select",{BackgroundTransparency=self.Selected and 0.2 or 0.5})
    self.Deps.Motion:Tween(self.Rim,"Select",{Transparency=self.Selected and 0.3 or 0.72})
    self.Icon.ImageColor3 = self.Selected and tokens.Color.Accent or tokens.Color.TextMuted
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
    row:SetAttribute("FeatureTitle", props.Title or "Toggle")
    row:SetAttribute("FeatureDescription", props.Description or "")
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
    row:SetAttribute("FeatureTitle", props.Title or "Slider")
    row:SetAttribute("FeatureDescription", props.Description or "")
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
    row:SetAttribute("FeatureTitle", props.Title or "Select")
    row:SetAttribute("FeatureDescription", props.Description or "")
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
        local narrow = deps.Mobile or frame.AbsoluteSize.X / scale < 550
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
        -- Keep an open picker stable while the mobile keyboard changes the viewport.
        local focused=UserInputService:GetFocusedTextBox()
        if focused and focused:IsDescendantOf(screen) then return end
        local camera = workspace.CurrentCamera
        local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
        local inset = GuiService:GetGuiInset()
        local touchLayout=UserInputService.TouchEnabled and (not UserInputService.KeyboardEnabled or viewport.Y<600)
        if touchLayout then
            -- Keep a complete logical canvas, then fit all of it into the phone.
            -- Shrinking only the frame left desktop-size controls in a short viewport.
            local availableW=math.max(1,viewport.X-32)
            local availableH=math.max(1,viewport.Y-inset.Y-32)
            local scale=math.min(1.35,availableW*0.94/tokens.Size.Window.X,availableH*0.94/tokens.Size.Window.Y)
            holder.Size=UDim2.fromOffset(tokens.Size.Window.X,tokens.Size.Window.Y)
            uiScale.Scale=scale
        else
            uiScale.Scale = 1
            holder.Size = UDim2.fromOffset(math.min(tokens.Size.Window.X, math.max(320, viewport.X - 24)), math.min(tokens.Size.Window.Y, math.max(240, viewport.Y - inset.Y - 24)))
        end
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
    local shield=Instance.new("TextButton")
    shield.Name="PopupInputShield";shield.Text="";shield.AutoButtonColor=false
    shield.BackgroundColor3=Color3.new(0,0,0);shield.BackgroundTransparency=0.75
    shield.Size=UDim2.fromScale(1,1);shield.ZIndex=71;shield.Visible=false
    shield.Active=true;shield.Parent=overlay
    shield.Activated:Connect(function() deps.PopupManager:Close() end)
    local lockedScrollers={}
    deps.PopupManager.OnChange=function(active)
        for frame,enabled in pairs(lockedScrollers) do
            if frame.Parent then frame.ScrollingEnabled=enabled end
        end
        table.clear(lockedScrollers)
        shield.Visible=active~=nil
        if active then
            for _,frame in ipairs(shell:GetDescendants()) do
                if frame:IsA("ScrollingFrame") and not frame:IsDescendantOf(active) then
                    lockedScrollers[frame]=frame.ScrollingEnabled
                    frame.ScrollingEnabled=false
                end
            end
        end
    end
    -- Edge treatment sits above the surfaces, without a shadow image.
    local rim=Instance.new("Frame")
    rim.Name="GlassRim"
    rim.BackgroundTransparency=1
    rim.Size=UDim2.new(1,-4,1,-4)
    rim.Position=UDim2.fromOffset(2,2)
    rim.ZIndex=69
    rim.Parent=shell
    corner(rim,tokens.Size.RadiusShell-2)
    local edge=Instance.new("UIStroke")
    edge.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
    edge.Color=tokens.Color.Stroke
    edge.Thickness=1.4
    edge.Transparency=0.22
    edge.Parent=rim
    local edgeFade=Instance.new("UIGradient")
    edgeFade.Rotation=65
    edgeFade.Transparency=NumberSequence.new({
        NumberSequenceKeypoint.new(0,0.05),
        NumberSequenceKeypoint.new(0.45,0.65),
        NumberSequenceKeypoint.new(1,0.12)
    })
    edgeFade.Parent=edge

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
        runtime:TrackConnection(page:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
            if app.OnViewChanged then app.OnViewChanged() end
        end))

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
        local changed=currentPage~=id
        currentPage = id
        if app.OnViewChanged then app.OnViewChanged() end
        pageText.Text = target.Title
        for pageId, entry in pairs(pages) do
            local selected = pageId == id
            if entry.Transition then entry.Transition:Cancel();entry.Transition=nil end
            entry.Page.Position=UDim2.fromOffset(0,0)
            entry.Page.Visible = selected
            entry.NavItem:SetSelected(selected)
            if selected and changed and not deps.Motion.Reduced then
                entry.Page.Position=UDim2.fromOffset(0,4)
                entry.Transition=deps.Motion:Tween(entry.Page,"Select",{Position=UDim2.fromOffset(0,0)})
            end
        end
    end

    function app:GetViewState()
        local positions={}
        for id,entry in pairs(pages) do positions[id]=entry.Page.CanvasPosition.Y end
        return {Page=currentPage,Positions=positions}
    end
    function app:RestoreViewState(view)
        if type(view)~="table" then return end
        if type(view.Page)=="string" and pages[view.Page] then self:SelectPage(view.Page) end
        task.defer(function()
            if runtime.Destroyed then return end
            if type(view.Positions)~="table" then return end
            for id,y in pairs(view.Positions) do
                local entry=pages[id]
                if entry and type(y)=="number" and y==y and math.abs(y)<1000000 then
                    local maximum=math.max(0,entry.Page.AbsoluteCanvasSize.Y-entry.Page.AbsoluteWindowSize.Y)
                    entry.Page.CanvasPosition=Vector2.new(0,math.clamp(y,0,maximum))
                end
            end
        end)
    end
    runtime:TrackCleanup(function()
        deps.PopupManager:Close()
        for _,entry in pairs(pages) do if entry.Transition then entry.Transition:Cancel() end end
    end)
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

    local function createSearchPopup(categoriesOnly)
        if not holder.Visible then return end
        deps.PopupManager:Close()
        local popup = Instance.new("Frame")
        popup.AnchorPoint = Vector2.new(1, 0)
        popup.Position = UDim2.new(1, -16, 0, tokens.Size.Topbar - 2)
        local logicalWidth=holder.Size.X.Offset
        local popupWidth=math.min(deps.Mobile and 340 or 292,logicalWidth-24)
        local popupHeight=math.min(340,holder.Size.Y.Offset-tokens.Size.Topbar-14)
        popup.Size = UDim2.fromOffset(popupWidth,popupHeight)
        if categoriesOnly then
            popup.AnchorPoint=Vector2.new(0,0)
            popup.Position=UDim2.fromOffset(math.clamp(pageButton.Position.X.Offset,12,logicalWidth-popupWidth-12),tokens.Size.Topbar+2)
        end
        popup.ZIndex = 80
        popup.Parent = overlay
        deps.Material.Popup(popup, tokens)

        local caption=deps.Typography.Label(popup,"Value",tokens,categoriesOnly and "Categories" or "All features",UDim2.fromOffset(12,6),UDim2.new(1,-60,0,30),tokens.Color.Text)
        caption.ZIndex=81
        local close=Instance.new("TextButton")
        close.Text="×";close.TextSize=22;close.TextColor3=tokens.Color.TextMuted
        close.BackgroundTransparency=1;close.Size=UDim2.fromOffset(40,36)
        close.Position=UDim2.new(1,-44,0,2);close.ZIndex=82;close.Parent=popup
        close.Activated:Connect(function() deps.PopupManager:Close() end)
        local input = Instance.new("TextBox")
        input.Position = UDim2.fromOffset(8, 42)
        input.Size = UDim2.new(1, -16, 0, 34)
        input.Text = ""
        input.PlaceholderText = categoriesOnly and "Filter categories..." or "Search all features..."
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
        listFrame.Position = UDim2.fromOffset(8, 84)
        listFrame.Size = UDim2.new(1, -16, 1, -92)
        listFrame.CanvasSize = UDim2.new()
        listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
        listFrame.ScrollBarThickness = deps.Mobile and 4 or 2
        listFrame.ScrollBarImageColor3 = tokens.Color.Accent
        listFrame.ZIndex = 81
        listFrame.Parent = popup
        local ll = Instance.new("UIListLayout") ll.Padding = UDim.new(0, 3) ll.Parent = listFrame

        local matches = {}
        for _, entry in ipairs(navItems) do
            if categoriesOnly then
                table.insert(matches,{Entry=entry,Title=entry.Title})
            else
                for _, target in ipairs(entry.Page:GetDescendants()) do
                    local title=target:GetAttribute("FeatureTitle")
                    if not title and target:IsA("TextButton") and target.Text~="" then title=target.Text end
                    if not title and target:IsA("TextBox") and target.PlaceholderText~="" then title=target.PlaceholderText end
                    if title then table.insert(matches,{Entry=entry,Title=title,Target=target,Description=target:GetAttribute("FeatureDescription") or ""}) end
                end
            end
        end
        table.sort(matches,function(a,b) return (a.Title..a.Entry.Title)<(b.Title..b.Entry.Title) end)
        local rows={}
        local function jump(match)
            app:SelectPage(match.Entry.Id)
            local target=match.Target
            if not target then return end
            local ancestor=target.Parent
            while ancestor and ancestor~=match.Entry.Page do
                if ancestor:IsA("GuiObject") then ancestor.Visible=true end
                ancestor=ancestor.Parent
            end
            task.defer(function()
                if runtime.Destroyed or not target.Parent then return end
                local page=match.Entry.Page
                local y=(target.AbsolutePosition.Y-page.AbsolutePosition.Y)/math.max(uiScale.Scale,0.01)+page.CanvasPosition.Y-18
                page.CanvasPosition=Vector2.new(0,math.clamp(y,0,math.max(0,page.AbsoluteCanvasSize.Y-page.AbsoluteWindowSize.Y)))
                local outline=Instance.new("UIStroke")
                outline.Name="SearchHighlight";outline.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
                outline.Color=tokens.Color.Accent;outline.Thickness=2;outline.Parent=target
                task.delay(1.5,function() if outline.Parent then outline:Destroy() end end)
            end)
        end
        for _,match in ipairs(matches) do
            local row=Instance.new("TextButton")
            row.Size=UDim2.new(1,-2,0,categoriesOnly and (deps.Mobile and 44 or 35) or 48)
            row.BackgroundColor3=(categoriesOnly and match.Entry.Id==currentPage) and tokens.Color.Accent or tokens.Color.PanelSoft;row.BackgroundTransparency=0.12
            row.BorderSizePixel=0;row.Text="";row.AutoButtonColor=false;row.ZIndex=82;row.Parent=listFrame
            corner(row,6)
            local title=deps.Typography.Label(row,"Value",tokens,match.Title,UDim2.fromOffset(10,4),UDim2.new(1,-20,0,25),tokens.Color.Text)
            title.ZIndex=83
            if not categoriesOnly then
                local subtitle=deps.Typography.Label(row,"Description",tokens,match.Entry.Title,UDim2.fromOffset(10,28),UDim2.new(1,-20,0,15),tokens.Color.TextMuted)
                subtitle.ZIndex=83
            end
            table.insert(rows,{Frame=row,Match=match,Search=string.lower(match.Title.." "..match.Entry.Title.." "..(match.Description or ""))})
            row.Activated:Connect(function() jump(match) end)
        end
        local empty=deps.Typography.Label(listFrame,"Value",tokens,categoriesOnly and "No matching categories" or "No matching features",UDim2.new(),UDim2.new(1,-10,0,40),tokens.Color.TextMuted)
        empty.ZIndex=83;empty.Visible=false
        input:GetPropertyChangedSignal("Text"):Connect(function()
            local q=string.lower(input.Text or "")
            local count=0
            for _,data in ipairs(rows) do
                local visible=true
                for word in q:gmatch("%S+") do if not string.find(data.Search,word,1,true) then visible=false break end end
                data.Frame.Visible=visible
                if visible then count=count+1 end
            end
            empty.Visible=count==0
            listFrame.CanvasPosition=Vector2.new()
        end)
        input.FocusLost:Connect(function(enter)
            if enter then for _,data in ipairs(rows) do if data.Frame.Visible then jump(data.Match) break end end end
        end)

        deps.PopupManager:Set(popup)
        -- TextBox receives focus only from an explicit click or tap.
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

    searchButton.Activated:Connect(function() createSearchPopup(false) end)
    pageButton.Activated:Connect(function() createSearchPopup(true) end)
    scopeButton.MouseButton1Click:Connect(createScopePopup)

    runtime:TrackConnection(UserInputService.InputBegan:Connect(function(input, processed)
        if input.KeyCode==Enum.KeyCode.Escape and deps.PopupManager.Active then
            deps.PopupManager:Close()
            return
        end
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

    if deps.Mobile then
        sidebar.Visible=true
        -- Use the existing vertical categories and profile on mobile too.
        content.Position=UDim2.fromOffset(tokens.Size.Sidebar+14,tokens.Size.Topbar+8)
        content.Size=UDim2.new(1,-(tokens.Size.Sidebar+28),1,-(tokens.Size.Topbar+18))
        heading.Text="SERENITY";heading.TextSize=16
        heading.Position=UDim2.fromOffset(47,0);heading.Size=UDim2.fromOffset(115,48)
        star.Position=UDim2.fromOffset(13,10);star.Size=UDim2.fromOffset(30,30)
        pageButton.Position=UDim2.fromOffset(165,5);pageButton.Size=UDim2.fromOffset(110,38)
    end
    return app
end

return Desktop

end)()

modules["src/components/MultiSelect.lua"]=(function()
local MultiSelect = {}
MultiSelect.__index = MultiSelect

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
        math.clamp(x + bw - width, 8, maxW - width - 8),
        math.clamp(y + bh + 5, 8, maxH - height - 8)
    )
end

function MultiSelect.new(parent, deps, props)
    local tokens = deps.Tokens
    props = props or {}
    local selected = {}
    for k,v in pairs(props.Default or {}) do if type(k)=="number" then selected[v]=true elseif v==true then selected[k]=true end end

    local row = Instance.new("CanvasGroup")
    row.Name = props.Id or "MultiSelect"
    row:SetAttribute("FeatureTitle",props.Title or "Multi Select")
    row:SetAttribute("FeatureDescription","")
    row.Size = UDim2.new(1, 0, 0, tokens.Size.Select)
    row.Parent = parent
    deps.Material.Control(row, tokens)

    deps.Typography.Label(row, "Control", tokens, props.Title or "Multi Select", UDim2.fromOffset(13, 0), UDim2.new(1, -26, 0, 24), tokens.Color.Text)
    deps.Typography.Label(row, "Description", tokens, "", UDim2.fromOffset(14, 28), UDim2.new(1, -205, 0, 16), tokens.Color.TextDim)

    local button = Instance.new("TextButton")
    button.AnchorPoint = Vector2.new(1, 0.5)
    button.Position = UDim2.new(1, -12, 1, -19)
    button.Size = UDim2.new(1,-24,0,30)
    button.BackgroundColor3 = tokens.Color.Inset
    button.BackgroundTransparency = 0.03
    button.BorderSizePixel = 0
    button.TextColor3 = tokens.Color.Text
    button.TextSize = tokens.Type.Value
    button.Font = deps.Typography.Font.Medium
    button.AutoButtonColor = false
    button.Parent = row
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 8)
    buttonCorner.Parent = button
    local buttonStroke = Instance.new("UIStroke")
    buttonStroke.Color = tokens.Color.Stroke
    buttonStroke.Transparency = 0.75
    buttonStroke.Parent = button

    local self = setmetatable({
        Frame = row,
        Button = button,
        Selected = selected,
        Options = props.Options or {},
        Callback = props.Callback,
        Deps = deps,
    }, MultiSelect)

    function self:_count()
        local n = 0
        for _, state in pairs(self.Selected) do if state then n = n + 1 end end
        return n
    end

    function self:_render()
        local n = self:_count()
        if n == 0 then
            self.Button.Text = "None selected"
        elseif n == 1 then
            for name, state in pairs(self.Selected) do
                if state then self.Button.Text = name break end
            end
        else
            self.Button.Text = tostring(n) .. " selected"
        end
    end

    button.MouseButton1Click:Connect(function()
        if not self.Enabled then return end
        deps.PopupManager:Close()
        local popup = Instance.new("Frame")
        popup.Size = UDim2.fromOffset(238, 280)
        popup.Position = popupPosition(deps, button, 238, 280)
        popup.ZIndex = 80
        popup.Parent = deps.PopupHost
        deps.Material.Popup(popup, tokens)

        deps.Typography.Label(popup, "Control", tokens, props.Title or "Select", UDim2.fromOffset(12, 8), UDim2.new(1, -24, 0, 20), tokens.Color.Text).ZIndex = 81

        local search = Instance.new("TextBox")
        search.Position = UDim2.fromOffset(10, 34)
        search.Size = UDim2.new(1, -20, 0, 32)
        search.BackgroundColor3 = tokens.Color.Inset
        search.BorderSizePixel = 0
        search.Text = ""
        search.PlaceholderText = "Search options..."
        search.PlaceholderColor3 = tokens.Color.TextDim
        search.TextColor3 = tokens.Color.Text
        search.TextSize = tokens.Type.Description
        search.Font = deps.Typography.Font.Regular
        search.TextXAlignment = Enum.TextXAlignment.Left
        search.ClearTextOnFocus = false
        search.ZIndex = 81
        search.Parent = popup
        local sc = Instance.new("UICorner") sc.CornerRadius = UDim.new(0, 7) sc.Parent = search
        local pad = Instance.new("UIPadding") pad.PaddingLeft = UDim.new(0, 10) pad.PaddingRight = UDim.new(0, 8) pad.Parent = search

        local all = Instance.new("TextButton")
        all.Position = UDim2.fromOffset(10, 72)
        all.Size = UDim2.new(0.5, -14, 0, 28)
        all.BackgroundColor3 = tokens.Color.SurfaceSoft
        all.BackgroundTransparency = 0.16
        all.BorderSizePixel = 0
        all.Text = "ALL"
        all.TextColor3 = tokens.Color.Accent
        all.TextSize = tokens.Type.Status
        all.Font = deps.Typography.Font.Bold
        all.ZIndex = 81
        all.Parent = popup
        local ac = Instance.new("UICorner") ac.CornerRadius = UDim.new(0, 7) ac.Parent = all

        local clear = all:Clone()
        clear.Position = UDim2.new(0.5, 4, 0, 72)
        clear.Text = "CLEAR"
        clear.TextColor3 = tokens.Color.TextMuted
        clear.Parent = popup

        local list = Instance.new("ScrollingFrame")
        list.Position = UDim2.fromOffset(10, 108)
        list.Size = UDim2.new(1, -20, 1, -118)
        list.BackgroundTransparency = 1
        list.BorderSizePixel = 0
        list.CanvasSize = UDim2.new()
        list.AutomaticCanvasSize = Enum.AutomaticSize.Y
        list.ScrollBarThickness = 2
        list.ScrollBarImageColor3 = tokens.Color.Accent
        list.ZIndex = 81
        list.Parent = popup
        local ll = Instance.new("UIListLayout") ll.Padding = UDim.new(0, 4) ll.Parent = list

        local rows = {}
        local function emit()
            self:_render()
            if self.Callback then self.Callback(self:Get()) end
        end

        for _, option in ipairs(self.Options) do
            local item = Instance.new("TextButton")
            item.Size = UDim2.new(1, -2, 0, 29)
            item.BackgroundColor3 = tokens.Color.Control
            item.BackgroundTransparency = 0.35
            item.BorderSizePixel = 0
            item.Text = ""
            item.AutoButtonColor = false
            item.ZIndex = 82
            item.Parent = list
            local ic = Instance.new("UICorner") ic.CornerRadius = UDim.new(0, 7) ic.Parent = item

            local check = Instance.new("Frame")
            check.Position = UDim2.fromOffset(8, 7)
            check.Size = UDim2.fromOffset(15, 15)
            check.BackgroundColor3 = self.Selected[option] and tokens.Color.Accent or tokens.Color.SurfaceSoft
            check.BorderSizePixel = 0
            check.ZIndex = 83
            check.Parent = item
            local cc = Instance.new("UICorner") cc.CornerRadius = UDim.new(0, 4) cc.Parent = check

            local tick = deps.Icons.Create(check, "check", 10, Color3.new(1, 1, 1), UDim2.fromOffset(2.5, 2.5))
            tick.Visible = self.Selected[option] == true
            tick.ZIndex = 84

            deps.Typography.Label(item, "Value", tokens, option, UDim2.fromOffset(31, 0), UDim2.new(1, -36, 1, 0), tokens.Color.TextMuted).ZIndex = 83
            rows[option] = item

            item.MouseButton1Click:Connect(function()
                self.Selected[option] = not self.Selected[option]
                check.BackgroundColor3 = self.Selected[option] and tokens.Color.Accent or tokens.Color.SurfaceSoft
                tick.Visible = self.Selected[option] == true
                emit()
            end)
        end

        search:GetPropertyChangedSignal("Text"):Connect(function()
            local q = string.lower(search.Text or "")
            for option, item in pairs(rows) do
                item.Visible = q == "" or string.find(string.lower(option), q, 1, true) ~= nil
            end
        end)

        all.MouseButton1Click:Connect(function()
            for _, option in ipairs(self.Options) do self.Selected[option] = true end
            deps.PopupManager:Close()
            emit()
        end)
        clear.MouseButton1Click:Connect(function()
            table.clear(self.Selected)
            deps.PopupManager:Close()
            emit()
        end)

        deps.PopupManager:Set(popup)
    end)

    function self:Get()
        local values={};for _,v in ipairs(self.Options) do if self.Selected[v] then values[#values+1]=v end end;return values
    end
    function self:Set(values,silent)
        local requested={};for k,v in pairs(type(values)=="table" and values or {}) do if type(k)=="number" then requested[v]=true elseif v==true then requested[k]=true end end
        self.Selected={};for _,v in ipairs(self.Options) do if requested[v] then self.Selected[v]=true end end
        self:_render();if not silent and self.Callback then self.Callback(self:Get()) end
    end
    function self:Refresh(options,preserve)
        local values=preserve and self:Get() or {};deps.PopupManager:Close();self.Options=options or {};self:Set(values,true)
    end
    function self:SetEnabled(enabled) self.Enabled=enabled==true;self.Frame.GroupTransparency=self.Enabled and 0 or 0.45 end
    self:SetEnabled(props.Enabled~=false)
    self:_render()
    return self
end

return MultiSelect


end)()
local Library={Version="M4.23-Media-Test2",APIVersion=3,Build=function(manifest,options)
assert(type(manifest)=="table","Expected UI demo manifest")
for _,page in ipairs(manifest.Pages or {}) do
    for _,feature in ipairs(page.Features or {}) do
        for _,control in ipairs(feature.Controls or {}) do
            assert(control.Type=="Switch" or control.Type=="Slider" or control.Type=="Paragraph" or control.Type=="Select" or control.Type=="MultiSelect" or control.Type=="Input" or control.Type=="Action" or control.Type=="Image" or control.Type=="Banner","Unsupported demo control: "..tostring(control.Type))
        end
    end
end
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
for _, oldKey in ipairs({"__SERENITY_NEW_UI_GLASS_LAB_M2", "__SERENITY_NEW_UI_PRECISION_M3", "__SERENITY_NEW_UI_COMPACT_M4", "__SERENITY_MEDIA_M423_TEST"}) do
    if G[oldKey] and G[oldKey].Destroy then
        pcall(function() G[oldKey]:Destroy() end)
    end
end

local KEY = "__SERENITY_MEDIA_M423_TEST"
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

local camera=workspace.CurrentCamera
local viewport=camera and camera.ViewportSize or Vector2.new(1280,720)
deps.Mobile=UserInputService.TouchEnabled and (not UserInputService.KeyboardEnabled or viewport.Y<600)
if deps.Mobile then
    Tokens.Size.Window=Vector2.new(viewport.X<viewport.Y and 380 or 600,380)
    Tokens.Size.Topbar=48
    Tokens.Size.Control=46
    Tokens.Size.Slider=66
    Tokens.Size.Select=72
end

local app = Desktop.Mount(deps, {
    Title = "SERENITY HUB",
    Subtitle = "UI PLAYGROUND",
    BlurSize = 3,
})


app.Runtime=runtime
app.Screen=app.ScreenGui
app.Window=app
app.Controls={}
app.Manifest=manifest
app.Version="M4.23-Media-Test2"
app.APIVersion=3
function app:Destroy() runtime:Destroy() end
runtime.OnDestroy=runtime.TrackCleanup
function app:SetLive(id,value)
    local control=self.Controls[id]
    if control and control.Set then control:Set(value,true) end
end
app.Adapter={Controls=app.Controls,SetLive=function(_,id,value) app:SetLive(id,value) end}
local function paragraph(parent,title,text)
    local row=Instance.new("Frame")
    row.BackgroundTransparency=1
    row.Size=UDim2.new(1,0,0,0)
    row.AutomaticSize=Enum.AutomaticSize.Y
    row:SetAttribute("FeatureTitle",title or "Information")
    row.Parent=parent
    local label=Typography.Label(row,"Control",Tokens,(title or "").."\n"..(text or ""),UDim2.fromOffset(12,8),UDim2.new(1,-24,0,0),Tokens.Color.Text)
    label.TextWrapped=true
    label.AutomaticSize=Enum.AutomaticSize.Y
    label.TextYAlignment=Enum.TextYAlignment.Top
    local padding=Instance.new("UIPadding")
    padding.PaddingBottom=UDim.new(0,16)
    padding.Parent=row
    return {Set=function(_,value) label.Text=(title or "").."\n"..tostring(value) end}
end
local about=app:AddPage({Id="About",Title="About",Icon="info",Order=-3})
local aboutCols=ColumnLayout.new(about,deps,{})
local intro=Section.new(aboutCols.Left,deps,{Title="Serenity · Component test"})
paragraph(intro.Body,"M4.23", "Image and Banner preview. M4.23 sizing with separate test settings. Open Dashboard to test the components.")
local stop=Instance.new("TextButton")
stop.Size=UDim2.new(1,0,0,40);stop.Text="Test information"
stop.Font=Enum.Font.GothamMedium;stop.TextSize=13;stop.TextColor3=Tokens.Color.Text
stop.Parent=intro.Body;Material.Inset(stop,Tokens)
runtime:TrackConnection(stop.Activated:Connect(function() app:Notify("Use Dashboard for media tests and Settings for appearance.") end))
-- Gameplay owns its persisted settings; this facade supports its existing
-- rollback/reset callbacks without introducing a second autosave loop.
local config={Data={},SchemaVersion=1}
function config:Set(key,value) self.Data[key]=value end
function config:Get(key,fallback) local v=self.Data[key];if v==nil then return fallback end;return v end
function config:SaveNow()
    if type(writefile)~="function" then return false end
    return pcall(function()
        if type(makefolder)=="function" then pcall(makefolder,"SerenityHub") end
        writefile("SerenityHub/Media_M423Test_UI_Config.json",game:GetService("HttpService"):JSONEncode(self.Data))
    end)
end
app.Config=config;app.Adapter.Config=config
function app:Notify(title,text)
    if self.Toast then self.Toast:Destroy() end
    local toast=Instance.new("TextLabel")
    toast.Size=UDim2.new(1,-32,0,64);toast.Position=UDim2.new(0,16,1,-80)
    toast.Text=text and (tostring(title)..": "..tostring(text)) or tostring(title)
    toast.TextWrapped=true;toast.TextColor3=Tokens.Color.Text
    toast.Font=Enum.Font.GothamMedium;toast.TextSize=13;toast.ZIndex=100
    toast.Parent=self.Overlay;Material.Popup(toast,Tokens);self.Toast=toast
    task.delay(4,function() if toast.Parent then toast:Destroy() end end)
end
local function makeInput(parent,props)
    local row=Instance.new("Frame");row.Size=UDim2.new(1,0,0,72);row.Parent=parent
    row:SetAttribute("FeatureTitle",props.Title or "Input");row:SetAttribute("FeatureDescription",props.Description or "")
    Material.Control(row,Tokens)
    Typography.Label(row,"Control",Tokens,props.Title,UDim2.fromOffset(12,0),UDim2.new(1,-24,0,28),Tokens.Color.Text)
    local box=Instance.new("TextBox");box.Size=UDim2.new(1,-24,0,32);box.Position=UDim2.fromOffset(12,32)
    box.Text=tostring(props.Default or "");box.ClearTextOnFocus=false;box.TextSize=13;box.Font=Enum.Font.GothamMedium
    box.TextColor3=Tokens.Color.Text;box.PlaceholderText=props.Placeholder or "";box.Parent=row;Material.Inset(box,Tokens)
    local c={Frame=row,Value=box.Text,Enabled=props.Enabled~=false}
    function c:Get() return self.Value end
    function c:Set(v,silent)
        local nextValue=tostring(v or "");local changed=self.Value~=nextValue;self.Value=nextValue;box.Text=nextValue
        if changed and not silent and props.Callback then props.Callback(nextValue) end
    end
    function c:SetEnabled(v) self.Enabled=v==true;box.TextEditable=self.Enabled end
    c:SetEnabled(c.Enabled)
    runtime:TrackConnection(box.FocusLost:Connect(function() if c.Enabled then c:Set(box.Text) end end))
    return c
end
local function makeAction(parent,props)
    local b=Instance.new("TextButton");b.Size=UDim2.new(1,0,0,44);b.Text=props.Title or "Action"
    b:SetAttribute("FeatureTitle",b.Text);b:SetAttribute("FeatureDescription",props.Description or "")
    b.Font=Enum.Font.GothamMedium;b.TextSize=13;b.TextColor3=Tokens.Color.Text;b.Parent=parent;Material.Inset(b,Tokens)
    local c={Frame=b,Enabled=props.Enabled~=false,Busy=false}
    function c:SetEnabled(v) self.Enabled=v==true;b.AutoButtonColor=self.Enabled end
    runtime:TrackConnection(b.Activated:Connect(function()
        if runtime.Destroyed or not c.Enabled or c.Busy then return end
        c.Busy=true
        local ok,err=pcall(function()if props.Callback then props.Callback(app,app.Adapter) end end)
        c.Busy=false;if not ok then app:Notify(tostring(err)) end
    end))
    return c
end


local function makeMedia(parent,props,isBanner)
    local row=Instance.new("Frame")
    row.Size=UDim2.new(1,0,0,160);row.ClipsDescendants=true;row.Parent=parent
    row:SetAttribute("FeatureTitle",props.Title or "Image")
    row:SetAttribute("FeatureDescription",props.Description or "")
    Material.Control(row,Tokens)
    local picture=Instance.new("ImageLabel")
    picture.BackgroundTransparency=1;picture.Size=UDim2.fromScale(1,1);picture.Parent=row
    picture.ScaleType=Enum.ScaleType.Fit
    local fallback=Instance.new("TextLabel")
    fallback.BackgroundTransparency=1;fallback.Size=UDim2.fromScale(1,1)
    fallback.Text=isBanner and "" or "No image loaded\nTry Restore avatar image";fallback.TextWrapped=true
    fallback.Font=Enum.Font.Gotham;fallback.TextSize=12;fallback.TextColor3=Tokens.Color.Text;fallback.Parent=row
    local overlay=Instance.new("Frame");overlay.Size=UDim2.fromScale(1,1)
    overlay.BackgroundColor3=Color3.fromRGB(7,19,32);overlay.BackgroundTransparency=0.45
    overlay.BorderSizePixel=0;overlay.Visible=isBanner;overlay.Parent=row
    local title=Instance.new("TextLabel");title.BackgroundTransparency=1
    title.Position=UDim2.fromOffset(14,12);title.Size=UDim2.new(1,-28,0,0)
    title.AutomaticSize=Enum.AutomaticSize.Y;title.TextWrapped=true;title.TextXAlignment=Enum.TextXAlignment.Left
    title.Font=Enum.Font.GothamBold;title.TextSize=18;title.TextColor3=Tokens.Color.Text;title.Parent=overlay
    local description=title:Clone();description.Font=Enum.Font.Gotham;description.TextSize=12;description.Parent=overlay
    local button=Instance.new("TextButton");button.Size=UDim2.new(1,-28,0,34)
    button.Position=UDim2.new(0,14,1,-46);button.Text=props.ButtonText or "Preview"
    button.Font=Enum.Font.GothamMedium;button.TextSize=12;button.TextColor3=Tokens.Color.Text
    button.Visible=isBanner and props.ButtonText~=nil;button.Parent=overlay;Material.Inset(button,Tokens)
    local requestId=0
    local c={Frame=row,Image=picture,Ratio=props.AspectRatio or (isBanner and 2.5 or 1.6)}
    local function layout()
        local w=row.AbsoluteSize.X
        if w<=0 then return end
        description.Position=UDim2.fromOffset(14,title.AbsoluteSize.Y+20)
        local textHeight=title.AbsoluteSize.Y+description.AbsoluteSize.Y+36+(button.Visible and 46 or 0)
        row.Size=UDim2.new(1,0,0,math.max(isBanner and textHeight or 90,math.min(320,w/c.Ratio)))
    end
    function c:Set(value)
        if type(value)=="string" then value={Image=value} end
        value=type(value)=="table" and value or {}
        if value.Image~=nil then
            local source=tostring(value.Image)
            source=source:match("^%s*(.-)%s*$")
            local assetId=source:match("^%d+$")
            if source:match("^https?://") then assetId=source:match("[?&]id=(%d+)") or source:match("/catalog/(%d+)") or source:match("/library/(%d+)") end
            if assetId then source="rbxthumb://type=Asset&id="..assetId.."&w=420&h=420" end
            requestId=requestId+1
            local current=requestId
            picture.Image=source
            if not isBanner then fallback.Text=source=="" and "No image selected" or "Loading image..." end
            if source~="" then
                task.defer(function()
                    local success=true
                    local ok=pcall(function()
                        game:GetService("ContentProvider"):PreloadAsync({picture},function(_,status)
                            if status~=Enum.AssetFetchStatus.Success then success=false end
                        end)
                    end)
                    if runtime.Destroyed or current~=requestId then return end
                    fallback.Visible=not picture.IsLoaded
                    if not isBanner then
                        fallback.Text=(ok and success and picture.IsLoaded) and "" or "Image could not load\nTry Restore avatar image or another public asset"
                    end
                end)
            end
        end
        if value.Title~=nil then title.Text=tostring(value.Title) end
        if value.Description~=nil then description.Text=tostring(value.Description) end
        if value.AspectRatio then
            local r=tonumber(value.AspectRatio);if r and r==r then self.Ratio=math.clamp(r,0.8,4) end
        end
        if value.ScaleType then picture.ScaleType=value.ScaleType=="Crop" and Enum.ScaleType.Crop or Enum.ScaleType.Fit end
        fallback.Visible=not picture.IsLoaded or picture.Image==""
        layout()
    end
    function c:SetVisible(value) row.Visible=value==true end
    function c:SetEnabled(value) button.Active=value==true;button.AutoButtonColor=value==true end
    runtime:TrackConnection(row:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout))
    runtime:TrackConnection(title:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout))
    runtime:TrackConnection(description:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout))
    runtime:TrackConnection(picture:GetPropertyChangedSignal("IsLoaded"):Connect(function()
        fallback.Visible=not picture.IsLoaded or picture.Image==""
    end))
    runtime:TrackConnection(button.Activated:Connect(function()
        if button.Active and props.Changed then
            local ok,err=pcall(props.Changed,app,app.Adapter)
            if not ok then app:Notify(tostring(err)) end
        end
    end))
    c:Set({Image=props.Image or "",Title=props.Title or "",Description=props.Description or "",ScaleType=props.ScaleType})
    return c
end

local icons={Dashboard="dashboard",Automation="automation",PetsTrails="shop",Rewards="progression",Performance="misc",Settings="settings"}
for order,page in ipairs(manifest.Pages) do
    local viewId=page.Id=="Settings" and "GameTuning" or page.Id
    local view=app:AddPage({Id=viewId,Title=page.Id=="Settings" and "Game Tuning" or page.Title,Icon=icons[page.Id] or "info",Group="Components",Order=order})
    local columns=ColumnLayout.new(view,deps,{Gap=12,RowGap=12})
    for index,feature in ipairs(page.Features or {}) do
        local section=Section.new(index%2==1 and columns.Left or columns.Right,deps,{Title=feature.Title,Open=feature.Expanded~=false})
        local spacing=section.Body:FindFirstChildOfClass("UIListLayout")
        if spacing then spacing.Padding=UDim.new(0,10) end
        for n,control in ipairs(feature.Controls or {}) do
            local id=page.Id.."."..feature.Id.."."..(control.Id or ("Info"..n))
            local props={}
            for k,v in pairs(control) do props[k]=v end
            props.Id=id
            props.Callback=function(value)
                if runtime.Destroyed then return end
                local callback=control.Changed or control.Callback
                if callback then
                    local ok,err=pcall(callback,value,app,app.Adapter)
                    if not ok then app:Notify(tostring(err)) end
                end
            end
            local widget
            if control.Type=="Switch" then
                props.Default=control.Default==true
                widget=Toggle.new(section.Body,deps,props)
            elseif control.Type=="Slider" then
                props.Step=control.Step or ((control.Min or 0)%1~=0 and 0.01 or 1)
                widget=Slider.new(section.Body,deps,props)
            elseif control.Type=="Select" then
                widget=Select.new(section.Body,deps,props)
                function widget:Get() return self.Value end
            elseif control.Type=="MultiSelect" then
                widget=modules["src/components/MultiSelect.lua"].new(section.Body,deps,props)
            elseif control.Type=="Image" or control.Type=="Banner" then
                widget=makeMedia(section.Body,control,control.Type=="Banner")
            elseif control.Type=="Input" then
                widget=makeInput(section.Body,props)
            elseif control.Type=="Action" then
                widget=makeAction(section.Body,control)
            else
                widget=paragraph(section.Body,control.Title,control.Text)
            end
            app.Controls[id]=widget
        end
    end
end
local settings=app:AddPage({Id="Settings",Title="Settings",Icon="settings",Group="System",Order=20})
local settingsCols = ColumnLayout.new(settings, deps, {})

local themeBindings=setmetatable({}, {__mode="k"})
local refreshMaterials
local saveAppearance=function() end
local selectedTheme="Ocean"
local originalColors={}
for key,color in pairs(Tokens.Color) do originalColors[key]=color end
local function applyTheme(name)
    selectedTheme=name
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
    if refreshMaterials then refreshMaterials() end
    saveAppearance()
end

-- Event-driven materials: no heartbeat, textures or animated full-screen layers.
local materialState={Mode="Enhanced",Opacity=85,Edge=54,Palette="Aurora",Blur=3}
local appearancePath="Serenity_Media_M423_Appearance_v1.json"
local HttpService=game:GetService("HttpService")
local saveRevision=0
saveAppearance=function()
    saveRevision=saveRevision+1
    local revision=saveRevision
    task.delay(0.7,function()
        if runtime.Destroyed or revision~=saveRevision or type(writefile)~="function" then return end
        pcall(function()
            writefile(appearancePath,HttpService:JSONEncode({Version=1,Theme=selectedTheme,Mode=materialState.Mode,Opacity=materialState.Opacity,Edge=materialState.Edge,Palette=materialState.Palette,Blur=materialState.Blur,View=app:GetViewState()}))
        end)
    end)
end
local savedAppearance
if type(readfile)=="function" then
    local ok,data=pcall(function() return HttpService:JSONDecode(readfile(appearancePath)) end)
    if ok and type(data)=="table" and data.Version==1 then savedAppearance=data end
end
local glassSelectors={}
local edgePalettes={
    Aurora={Color3.fromRGB(107,224,255),Color3.fromRGB(174,153,255),Color3.fromRGB(255,206,163)},
    Ice={Color3.fromRGB(111,190,255),Color3.fromRGB(222,250,255),Color3.fromRGB(112,240,219)},
    Sunset={Color3.fromRGB(255,170,114),Color3.fromRGB(255,148,200),Color3.fromRGB(175,158,255)},
}
refreshMaterials=function()
    local enhanced=materialState.Mode=="Enhanced"
    local off=materialState.Mode=="Off"
    local colors=edgePalettes[materialState.Palette]
    if not colors then
        local h=select(1,Tokens.Color.Accent:ToHSV())
        colors={Color3.fromHSV(h,0.60,1),Color3.fromHSV((h+0.13)%1,0.32,1),Color3.fromHSV((h+0.28)%1,0.48,1)}
    end
    local spectrum=ColorSequence.new({ColorSequenceKeypoint.new(0,colors[1]),ColorSequenceKeypoint.new(0.48,colors[2]),ColorSequenceKeypoint.new(1,colors[3])})
    for _,object in ipairs(app.ScreenGui:GetDescendants()) do
        local role=object:GetAttribute("GlassRole")
        if role and object:IsA("GuiObject") then
            -- Do not give intentionally transparent heading containers a fill.
            if not (role=="Section" and not object:FindFirstChild("PanelStroke")) then
                local amount=(100-materialState.Opacity)/100
                if deps.Mobile then amount=math.min(amount,0.08) end
                object.BackgroundTransparency=off and 0 or (role=="Shell" and amount or role=="Sidebar" and amount*0.55 or amount*0.8)
                local g=object:FindFirstChild("GlassSheen") or object:FindFirstChild("ShellTone")
                if not g then g=Instance.new("UIGradient");g.Name="GlassSheen";g.Parent=object end
                g.Rotation=115
                g.Color=off and ColorSequence.new(Color3.new(1,1,1)) or ColorSequence.new({
                    ColorSequenceKeypoint.new(0,Color3.new(1,1,1)),
                    ColorSequenceKeypoint.new(0.34,Color3.fromRGB(184,208,237)),
                    ColorSequenceKeypoint.new(0.52,Color3.fromRGB(232,241,255)),
                    ColorSequenceKeypoint.new(1,Color3.fromRGB(144,170,209))})
                g.Transparency=NumberSequence.new(0)
                if not object:FindFirstChildOfClass("UIListLayout") and not object:FindFirstChildOfClass("UIGridLayout") then
                local lip=object:FindFirstChild("SpecularLip")
                if not lip then
                    lip=Instance.new("Frame");lip.Name="SpecularLip";lip.BorderSizePixel=0
                    lip.Position=UDim2.fromOffset(12,1);lip.Size=UDim2.new(1,-24,0,1)
                    lip.ZIndex=object.ZIndex+1;lip.Active=false;lip.Parent=object
                    local gl=Instance.new("UIGradient");gl.Name="Spectrum";gl.Parent=lip
                    gl.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(0.3,0.1),NumberSequenceKeypoint.new(0.7,0.35),NumberSequenceKeypoint.new(1,1)})
                end
                lip.Visible=enhanced;lip.BackgroundColor3=Color3.new(1,1,1);lip.BackgroundTransparency=0.24
                lip.Spectrum.Color=spectrum
                end
            end
        end
        if object:IsA("UIStroke") and (object.Name=="PanelStroke" or object.Name=="ShellEdge" or object.Parent.Name=="GlassRim") then
            local outer=object.Parent.Name=="GlassRim"
            object.Color=Color3.new(1,1,1)
            object.Thickness=outer and 1.7 or 1
            object.Transparency=1-(materialState.Edge/100)*(outer and 1 or 0.57)
            local g=object:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient")
            g.Parent=object;g.Color=spectrum;g.Rotation=35
            g.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.52,0.25),NumberSequenceKeypoint.new(1,0)})
        end
    end
end
function app:SetGlassQuality(value)
    materialState.Mode=value
    if self.Acrylic then self.Acrylic:SetQuality(value) end
    for _,control in ipairs(glassSelectors) do control:Set(value,true) end
    refreshMaterials()
    saveAppearance()
end
local function glassSelector(parent,title)
    local control=Select.new(parent,deps,{Title=title,Options={"Off","Basic","Enhanced"},Default=materialState.Mode,Callback=function(v) app:SetGlassQuality(v) end})
    table.insert(glassSelectors,control)
    return control
end
local appearance = Section.new(settingsCols.Left, deps, {Title="Appearance"})
local themeControl=Select.new(appearance.Body,deps,{Title="Color theme",Options={"Ocean","Lavender","Rose","Emerald","Slate"},Default="Ocean",Callback=applyTheme})
glassSelector(appearance.Body,"Glass material")
local paletteControl=Select.new(appearance.Body,deps,{Title="Border colors",Options={"Aurora","Ice","Sunset","Match theme"},Default="Aurora",Callback=function(v) materialState.Palette=v;refreshMaterials();saveAppearance() end})
local edgeControl=Slider.new(appearance.Body,deps,{Title="Border intensity",Min=0,Max=100,Step=1,Default=54,Suffix="%",Callback=function(v) materialState.Edge=v;refreshMaterials();saveAppearance() end})
local opacityControl=Slider.new(appearance.Body,deps,{Title="Material opacity",Min=50,Max=100,Step=1,Default=85,Suffix="%",Callback=function(v) materialState.Opacity=v;refreshMaterials();saveAppearance() end})
local blurControl=Slider.new(appearance.Body, deps, {Title="Blur Amount", Min=0, Max=8, Step=1, Default=3, Callback=function(v) materialState.Blur=v;if app.Acrylic then app.Acrylic:SetAmount(v) end;saveAppearance() end})
local function restoreAppearance(data)
    data=data or {}
    local function choice(value,options,fallback)
        for _,v in ipairs(options) do if value==v then return value end end
        return fallback
    end
    local function number(value,low,high,fallback)
        if type(value)~="number" or value~=value or math.abs(value)==math.huge then return fallback end
        return math.clamp(value,low,high)
    end
    materialState.Mode=choice(data.Mode,{"Off","Basic","Enhanced"},"Enhanced")
    materialState.Palette=choice(data.Palette,{"Aurora","Ice","Sunset","Match theme"},"Aurora")
    materialState.Edge=number(data.Edge,0,100,54)
    materialState.Opacity=number(data.Opacity,50,100,85)
    materialState.Blur=number(data.Blur,0,8,3)
    local theme=choice(data.Theme,{"Ocean","Lavender","Rose","Emerald","Slate"},"Ocean")
    themeControl:Set(theme,true);paletteControl:Set(materialState.Palette,true)
    edgeControl:Set(materialState.Edge,true);opacityControl:Set(materialState.Opacity,true);blurControl:Set(materialState.Blur,true)
    applyTheme(theme)
    if app.Acrylic then app.Acrylic:SetAmount(materialState.Blur) end
    app:SetGlassQuality(materialState.Mode)
end
local reset=Instance.new("TextButton")
reset.Size=UDim2.new(1,0,0,36);reset.Text="Restore preferred appearance"
reset.Font=Enum.Font.GothamMedium;reset.TextSize=12;reset.TextColor3=Tokens.Color.Text
reset.Parent=appearance.Body;Material.Inset(reset,Tokens)
reset.Activated:Connect(function() restoreAppearance(nil) end)

local motion=Section.new(settingsCols.Right,deps,{Title="Interaction"})
Toggle.new(motion.Body,deps,{Title="Reduced Motion",Default=false,Callback=function(v) Motion.Reduced=v end})
app:SelectPage("Dashboard")
restoreAppearance(savedAppearance)
if savedAppearance then app:RestoreViewState(savedAppearance.View) end
app.OnViewChanged=saveAppearance
return app
end}

local thumbnail="rbxthumb://type=AvatarHeadShot&id="..tostring(game:GetService("Players").LocalPlayer.UserId).."&w=420&h=420"
local function media(app,id,value) app:SetLive("Dashboard.Preview."..id,value) end
local app=Library.Build({
 SerenityAPIVersion=3,GameName="Serenity Component Demo",
 Pages={{Id="Dashboard",Title="Dashboard",Features={
 {Id="Preview",Title="Media preview",Controls={
 {Id="Welcome",Type="Banner",Title="Welcome to Serenity",Description="Image + title + description + touch button. Resize or rotate your device to check the layout.",Image=thumbnail,AspectRatio=2.5,ScaleType="Crop",ButtonText="Test banner button",Changed=function(a) a:Notify("Banner button","Working") end},
 {Id="Artwork",Type="Image",Title="Image preview",Image=thumbnail,AspectRatio=1.6,ScaleType="Fit"}
 }},
 {Id="Tools",Title="Try the components",Controls={
 {Id="Visible",Type="Switch",Title="Show banner",Default=true,Changed=function(v,a) a.Controls["Dashboard.Preview.Welcome"]:SetVisible(v) end},
 {Id="Ratio",Type="Slider",Title="Image aspect ratio",Min=0.8,Max=4,Step=0.1,Default=1.6,Changed=function(v,a) media(a,"Artwork",{AspectRatio=v}) end},
 {Id="Fit",Type="Select",Title="Image mode",Options={"Fit","Crop"},Default="Fit",Changed=function(v,a) media(a,"Artwork",{ScaleType=v}) end},
 {Id="Source",Type="Input",Title="Roblox asset ID or image URI",Placeholder="Asset ID, Roblox URL, or rbxassetid://",Changed=function(v,a) media(a,"Artwork",{Image=v});media(a,"Welcome",{Image=v}) end},
 {Id="Missing",Type="Action",Title="Test missing-image fallback",Callback=function(a) media(a,"Artwork",{Image=""});media(a,"Welcome",{Image=""}) end},
 {Id="Restore",Type="Action",Title="Restore avatar image",Callback=function(a) media(a,"Artwork",{Image=thumbnail});media(a,"Welcome",{Image=thumbnail}) end},
 {Id="Text",Type="Action",Title="Test long banner text",Callback=function(a) media(a,"Welcome",{Title="Serenity adapts to your device",Description="This longer description checks wrapping on a phone, tablet, and PC. The card should grow so the text and button remain readable."}) end},
 {Id="Destroy",Type="Action",Title="Close component test",Callback=function(a) a:Destroy() end}
 }}
 }}}
})
return app
