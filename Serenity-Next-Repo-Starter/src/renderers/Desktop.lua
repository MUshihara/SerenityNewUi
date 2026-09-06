local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local Lighting = game:GetService("Lighting")

local Desktop = {}

function Desktop.Mount(deps, options)
    options = options or {}
    local tokens = deps.Tokens
    local runtime = deps.Runtime
    local localPlayer = Players.LocalPlayer

    local parentGui
    pcall(function()
        if gethui then parentGui = gethui() end
    end)
    if not parentGui then pcall(function() parentGui = game:GetService("CoreGui") end) end
    if not parentGui then parentGui = localPlayer:WaitForChild("PlayerGui") end

    local screen = runtime:TrackInstance(Instance.new("ScreenGui"))
    screen.Name = options.Name or "SerenityNextGlassLab"
    screen.ResetOnSpawn = false
    screen.IgnoreGuiInset = false
    screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screen.DisplayOrder = 999999
    screen.Parent = parentGui
    pcall(function() if protect_gui then protect_gui(screen) end end)

    local blur = runtime:TrackInstance(Instance.new("BlurEffect"))
    blur.Name = "SerenityGlassBlur"
    blur.Size = options.BlurSize or 4
    blur.Parent = Lighting

    local holder = Instance.new("Frame")
    holder.AnchorPoint = Vector2.new(0.5, 0.5)
    holder.Position = UDim2.fromScale(0.5, 0.5)
    holder.Size = UDim2.fromOffset(tokens.Size.Window.X, tokens.Size.Window.Y)
    holder.BackgroundTransparency = 1
    holder.Parent = screen

    local scale = Instance.new("UIScale")
    scale.Scale = 1
    scale.Parent = holder

    local function refreshScale()
        local camera = workspace.CurrentCamera
        local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
        local inset = GuiService:GetGuiInset()
        local fit = math.min(1, (viewport.X - 22) / tokens.Size.Window.X, (viewport.Y - inset.Y - 22) / tokens.Size.Window.Y)
        scale.Scale = math.clamp(fit, 0.68, 1)
    end
    refreshScale()
    if workspace.CurrentCamera then runtime:TrackConnection(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(refreshScale)) end

    deps.Material.Shadow(holder, UDim2.fromScale(1, 1), tokens.Size.RadiusShell, tokens)

    local shell = Instance.new("Frame")
    shell.Name = "Shell"
    shell.Size = UDim2.fromScale(1, 1)
    shell.ClipsDescendants = true
    shell.ZIndex = 2
    shell.Parent = holder
    deps.Material.Shell(shell, tokens)

    deps.WindowFrame = shell
    deps.UIScale = scale

    local topbar = Instance.new("Frame")
    topbar.BackgroundTransparency = 1
    topbar.Size = UDim2.new(1, 0, 0, tokens.Size.Topbar)
    topbar.ZIndex = 3
    topbar.Parent = shell

    local logoWrap = Instance.new("Frame")
    logoWrap.Position = UDim2.fromOffset(13, 10)
    logoWrap.Size = UDim2.fromOffset(36, 36)
    logoWrap.BackgroundColor3 = tokens.Color.Surface
    logoWrap.BackgroundTransparency = 0.25
    logoWrap.BorderSizePixel = 0
    logoWrap.ZIndex = 4
    logoWrap.Parent = topbar
    local lc = Instance.new("UICorner") lc.CornerRadius = UDim.new(0, 10) lc.Parent = logoWrap
    local ls = Instance.new("UIStroke") ls.Color = tokens.Color.Stroke ls.Transparency = 0.76 ls.Parent = logoWrap

    local logo = Instance.new("ImageLabel")
    logo.BackgroundTransparency = 1
    logo.Position = UDim2.fromOffset(4, 4)
    logo.Size = UDim2.fromOffset(28, 28)
    logo.Image = "rbxthumb://type=Asset&id=89023606689629&w=420&h=420"
    logo.ScaleType = Enum.ScaleType.Fit
    logo.ZIndex = 5
    logo.Parent = logoWrap

    deps.Typography.Label(topbar, "Brand", tokens, options.Title or "SERENITY HUB", UDim2.fromOffset(58, 9), UDim2.fromOffset(170, 20), tokens.Color.Text).ZIndex = 4
    deps.Typography.Label(topbar, "BrandSub", tokens, options.Subtitle or "GLASS LAB", UDim2.fromOffset(58, 29), UDim2.fromOffset(150, 15), tokens.Color.TextDim).ZIndex = 4

    local searchButton = Instance.new("TextButton")
    searchButton.AnchorPoint = Vector2.new(0.5, 0)
    searchButton.Position = UDim2.new(0.57, 0, 0, 11)
    searchButton.Size = UDim2.fromOffset(240, 33)
    searchButton.BackgroundColor3 = tokens.Color.Inset
    searchButton.BackgroundTransparency = 0.16
    searchButton.BorderSizePixel = 0
    searchButton.Text = ""
    searchButton.AutoButtonColor = false
    searchButton.ZIndex = 4
    searchButton.Parent = topbar
    local sbc = Instance.new("UICorner") sbc.CornerRadius = UDim.new(0, 8) sbc.Parent = searchButton
    local sbs = Instance.new("UIStroke") sbs.Color = tokens.Color.Stroke sbs.Transparency = 0.78 sbs.Parent = searchButton
    local searchIcon = deps.Icons.Create(searchButton, "search", 15, tokens.Color.TextDim, UDim2.fromOffset(10, 9))
    searchIcon.ZIndex = 5
    deps.Typography.Label(searchButton, "Description", tokens, "Search controls...", UDim2.fromOffset(32, 0), UDim2.new(1, -42, 1, 0), tokens.Color.TextDim).ZIndex = 5

    local close = deps.Icons.Create(topbar, "close", 16, tokens.Color.TextMuted)
    close.AnchorPoint = Vector2.new(1, 0.5)
    close.Position = UDim2.new(1, -14, 0.5, 0)
    close.ZIndex = 5
    local closeHit = Instance.new("TextButton")
    closeHit.AnchorPoint = Vector2.new(1, 0.5)
    closeHit.Position = UDim2.new(1, -7, 0.5, 0)
    closeHit.Size = UDim2.fromOffset(30, 30)
    closeHit.BackgroundTransparency = 1
    closeHit.Text = ""
    closeHit.ZIndex = 6
    closeHit.Parent = topbar
    closeHit.MouseButton1Click:Connect(function() runtime:Destroy() end)

    local sidebar = Instance.new("Frame")
    sidebar.Position = UDim2.fromOffset(9, tokens.Size.Topbar + 1)
    sidebar.Size = UDim2.new(0, tokens.Size.Sidebar, 1, -(tokens.Size.Topbar + 10))
    sidebar.ZIndex = 3
    sidebar.Parent = shell
    deps.Material.Sidebar(sidebar, tokens)

    local navHolder = Instance.new("Frame")
    navHolder.BackgroundTransparency = 1
    navHolder.Position = UDim2.fromOffset(7, 9)
    navHolder.Size = UDim2.new(1, -14, 1, -18)
    navHolder.ZIndex = 4
    navHolder.Parent = sidebar
    local navList = Instance.new("UIListLayout")
    navList.Padding = UDim.new(0, 5)
    navList.SortOrder = Enum.SortOrder.LayoutOrder
    navList.Parent = navHolder

    local content = Instance.new("Frame")
    content.BackgroundTransparency = 1
    content.Position = UDim2.fromOffset(tokens.Size.Sidebar + 18, tokens.Size.Topbar + 1)
    content.Size = UDim2.new(1, -(tokens.Size.Sidebar + 27), 1, -(tokens.Size.Topbar + 10))
    content.ZIndex = 3
    content.Parent = shell

    local overlay = Instance.new("Frame")
    overlay.Name = "Overlay"
    overlay.BackgroundTransparency = 1
    overlay.Size = UDim2.fromScale(1, 1)
    overlay.ZIndex = 70
    overlay.Parent = shell
    deps.PopupHost = overlay

    local pages = {}
    local navItems = {}
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
        Blur = blur,
    }

    function app:AddPage(props)
        props = props or {}
        local id = props.Id or props.Title

        local page = Instance.new("ScrollingFrame")
        page.Name = id
        page.Visible = false
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.Size = UDim2.fromScale(1, 1)
        page.CanvasSize = UDim2.new()
        page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        page.ScrollBarThickness = 2
        page.ScrollBarImageColor3 = tokens.Color.Accent
        page.ScrollBarImageTransparency = 0.45
        page.Parent = content
        local padding = Instance.new("UIPadding")
        padding.PaddingRight = UDim.new(0, 5)
        padding.PaddingBottom = UDim.new(0, 10)
        padding.Parent = page
        local list = Instance.new("UIListLayout")
        list.Padding = UDim.new(0, 9)
        list.SortOrder = Enum.SortOrder.LayoutOrder
        list.Parent = page

        local header = Instance.new("Frame")
        header.BackgroundTransparency = 1
        header.Size = UDim2.new(1, 0, 0, 48)
        header.LayoutOrder = -100
        header.Parent = page
        deps.Typography.Label(header, "Page", tokens, props.Title or id, UDim2.fromOffset(1, 0), UDim2.new(1, -10, 0, 26), tokens.Color.Text)
        deps.Typography.Label(header, "PageSub", tokens, props.Description or "", UDim2.fromOffset(1, 27), UDim2.new(1, -10, 0, 17), tokens.Color.TextMuted)

        local nav = Instance.new("TextButton")
        nav.Name = id
        nav.Size = UDim2.new(1, 0, 0, 40)
        nav.BackgroundColor3 = tokens.Color.Surface
        nav.BackgroundTransparency = 1
        nav.BorderSizePixel = 0
        nav.Text = ""
        nav.AutoButtonColor = false
        nav.LayoutOrder = props.Order or #navItems + 1
        nav.ZIndex = 5
        nav.Parent = navHolder
        local nc = Instance.new("UICorner") nc.CornerRadius = UDim.new(0, 8) nc.Parent = nav

        local marker = Instance.new("Frame")
        marker.Visible = false
        marker.Position = UDim2.fromOffset(0, 9)
        marker.Size = UDim2.fromOffset(2, 22)
        marker.BackgroundColor3 = tokens.Color.Accent
        marker.BorderSizePixel = 0
        marker.ZIndex = 6
        marker.Parent = nav
        local mc = Instance.new("UICorner") mc.CornerRadius = UDim.new(1, 0) mc.Parent = marker

        local icon = deps.Icons.Create(nav, props.Icon or "info", 18, tokens.Color.TextDim, UDim2.fromOffset(12, 11))
        icon.ZIndex = 6
        local text = deps.Typography.Label(nav, "Nav", tokens, props.Title or id, UDim2.fromOffset(40, 0), UDim2.new(1, -46, 1, 0), tokens.Color.TextMuted)
        text.ZIndex = 6

        local entry = {Id = id, Page = page, Nav = nav, Marker = marker, Icon = icon, Text = text}
        pages[id] = entry
        table.insert(navItems, entry)

        nav.MouseEnter:Connect(function()
            if currentPage ~= id then
                deps.Motion:Tween(nav, "Hover", {BackgroundTransparency = 0.74})
            end
        end)
        nav.MouseLeave:Connect(function()
            if currentPage ~= id then
                deps.Motion:Tween(nav, "Hover", {BackgroundTransparency = 1})
            end
        end)
        nav.MouseButton1Click:Connect(function() app:SelectPage(id) end)

        if not currentPage then app:SelectPage(id) end
        return page
    end

    function app:SelectPage(id)
        if not pages[id] then return end
        deps.PopupManager:Close()
        currentPage = id
        for pageId, entry in pairs(pages) do
            local selected = pageId == id
            entry.Page.Visible = selected
            entry.Nav.BackgroundTransparency = selected and 0.54 or 1
            entry.Marker.Visible = selected
            entry.Icon.ImageColor3 = selected and tokens.Color.Accent or tokens.Color.TextDim
            entry.Text.TextColor3 = selected and tokens.Color.Text or tokens.Color.TextMuted
        end
    end

    function app:SetBlur(enabled)
        blur.Enabled = enabled
    end

    function app:Destroy()
        runtime:Destroy()
    end

    do
        local dragging = false
        local dragStart
        local startPos
        runtime:TrackConnection(topbar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = holder.Position
            end
        end))
        runtime:TrackConnection(deps.UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                holder.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end))
        runtime:TrackConnection(deps.UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
        end))
    end

    return app
end

return Desktop
