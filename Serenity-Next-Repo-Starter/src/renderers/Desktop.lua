local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local MarketplaceService = game:GetService("MarketplaceService")

local Desktop = {}

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
    screen.Name = options.Name or "SerenityNextM2"
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

    local scale = Instance.new("UIScale")
    scale.Scale = 1
    scale.Parent = holder

    local function refreshScale()
        local camera = workspace.CurrentCamera
        local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
        local inset = GuiService:GetGuiInset()
        local fit = math.min(1, (viewport.X - 22) / tokens.Size.Window.X, (viewport.Y - inset.Y - 22) / tokens.Size.Window.Y)
        scale.Scale = math.clamp(fit, 0.70, 1)
    end
    refreshScale()
    if workspace.CurrentCamera then
        runtime:TrackConnection(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(refreshScale))
    end

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
    logoWrap.Position = UDim2.fromOffset(12, 8)
    logoWrap.Size = UDim2.fromOffset(34, 34)
    logoWrap.BackgroundColor3 = tokens.Color.Surface
    logoWrap.BackgroundTransparency = 0.34
    logoWrap.BorderSizePixel = 0
    logoWrap.ZIndex = 4
    logoWrap.Parent = topbar
    local lc = Instance.new("UICorner") lc.CornerRadius = UDim.new(0, 10) lc.Parent = logoWrap
    local ls = Instance.new("UIStroke") ls.Color = tokens.Color.Stroke ls.Transparency = 0.82 ls.Parent = logoWrap

    local logo = Instance.new("ImageLabel")
    logo.BackgroundTransparency = 1
    logo.Position = UDim2.fromOffset(4, 4)
    logo.Size = UDim2.fromOffset(26, 26)
    logo.Image = "rbxthumb://type=Asset&id=89023606689629&w=420&h=420"
    logo.ScaleType = Enum.ScaleType.Fit
    logo.ZIndex = 5
    logo.Parent = logoWrap

    deps.Typography.Label(topbar, "Brand", tokens, options.Title or "SERENITY HUB", UDim2.fromOffset(54, 7), UDim2.fromOffset(160, 19), tokens.Color.Text).ZIndex = 4
    deps.Typography.Label(topbar, "BrandSub", tokens, options.Subtitle or "NEXT UI · M2", UDim2.fromOffset(54, 25), UDim2.fromOffset(150, 14), tokens.Color.TextDim).ZIndex = 4

    local metrics = Instance.new("Frame")
    metrics.AnchorPoint = Vector2.new(1, 0.5)
    metrics.Position = UDim2.new(1, -47, 0.5, 0)
    metrics.Size = UDim2.fromOffset(176, tokens.Size.MetricPill)
    metrics.BackgroundTransparency = 1
    metrics.ZIndex = 4
    metrics.Parent = topbar
    local ml = Instance.new("UIListLayout")
    ml.FillDirection = Enum.FillDirection.Horizontal
    ml.HorizontalAlignment = Enum.HorizontalAlignment.Right
    ml.Padding = UDim.new(0, 6)
    ml.Parent = metrics

    local fpsPill = deps.MetricPill.new(metrics, deps, {Width = 76, Text = "FPS --", Accent = tokens.Color.Mint, Color = tokens.Color.TextMuted})
    local memPill = deps.MetricPill.new(metrics, deps, {Width = 94, Text = "MEM -- MB", Accent = tokens.Color.Lavender, Color = tokens.Color.TextMuted})

    local searchButton = Instance.new("TextButton")
    searchButton.AnchorPoint = Vector2.new(1, 0.5)
    searchButton.Position = UDim2.new(1, -222, 0.5, 0)
    searchButton.Size = UDim2.fromOffset(30, 30)
    searchButton.BackgroundColor3 = tokens.Color.Inset
    searchButton.BackgroundTransparency = 0.14
    searchButton.BorderSizePixel = 0
    searchButton.Text = ""
    searchButton.AutoButtonColor = false
    searchButton.ZIndex = 4
    searchButton.Parent = topbar
    local sbc = Instance.new("UICorner") sbc.CornerRadius = UDim.new(0, 9) sbc.Parent = searchButton
    local sbs = Instance.new("UIStroke") sbs.Color = tokens.Color.Stroke sbs.Transparency = 0.82 sbs.Parent = searchButton
    local searchIcon = deps.Icons.Create(searchButton, "search", 15, tokens.Color.TextMuted)
    searchIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    searchIcon.Position = UDim2.fromScale(0.5, 0.5)
    searchIcon.ZIndex = 5

    local close = deps.Icons.Create(topbar, "close", 16, tokens.Color.TextMuted)
    close.AnchorPoint = Vector2.new(1, 0.5)
    close.Position = UDim2.new(1, -13, 0.5, 0)
    close.ZIndex = 5
    local closeHit = Instance.new("TextButton")
    closeHit.AnchorPoint = Vector2.new(1, 0.5)
    closeHit.Position = UDim2.new(1, -6, 0.5, 0)
    closeHit.Size = UDim2.fromOffset(30, 30)
    closeHit.BackgroundTransparency = 1
    closeHit.Text = ""
    closeHit.ZIndex = 6
    closeHit.Parent = topbar
    closeHit.MouseButton1Click:Connect(function() runtime:Destroy() end)

    local sidebar = Instance.new("Frame")
    sidebar.Position = UDim2.fromOffset(8, tokens.Size.Topbar)
    sidebar.Size = UDim2.new(0, tokens.Size.Sidebar, 1, -(tokens.Size.Topbar + 8))
    sidebar.ZIndex = 3
    sidebar.Parent = shell
    deps.Material.Sidebar(sidebar, tokens)

    local navHolder = Instance.new("Frame")
    navHolder.BackgroundTransparency = 1
    navHolder.Position = UDim2.fromOffset(6, 8)
    navHolder.Size = UDim2.new(1, -12, 1, -(tokens.Size.GameContext + 24))
    navHolder.ZIndex = 4
    navHolder.Parent = sidebar
    local navList = Instance.new("UIListLayout")
    navList.Padding = UDim.new(0, 2)
    navList.SortOrder = Enum.SortOrder.LayoutOrder
    navList.Parent = navHolder

    local content = Instance.new("Frame")
    content.BackgroundTransparency = 1
    content.Position = UDim2.fromOffset(tokens.Size.Sidebar + 17, tokens.Size.Topbar)
    content.Size = UDim2.new(1, -(tokens.Size.Sidebar + 25), 1, -(tokens.Size.Topbar + 8))
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
        Acrylic = acrylic,
    }

    local gameContext = deps.GameContext.new(sidebar, deps, {
        Title = "Current Game",
        Status = "● Connected",
        Image = game.GameId ~= 0 and ("rbxthumb://type=GameIcon&id=" .. tostring(game.GameId) .. "&w=150&h=150") or "",
        Callback = function()
            if navItems[1] then app:SelectPage(navItems[1].Id) end
        end,
    })
    app.GameContext = gameContext

    task.spawn(function()
        local ok, info = pcall(function() return MarketplaceService:GetProductInfo(game.PlaceId) end)
        if ok and info and info.Name then gameContext:SetTitle(info.Name) end
    end)

    function app:AddPage(props)
        props = props or {}
        local id = props.Id or props.Title
        local accent = props.Accent or tokens.Color.Accent

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
        page.ScrollBarImageTransparency = 0.52
        page.Parent = content
        local padding = Instance.new("UIPadding")
        padding.PaddingRight = UDim.new(0, 5)
        padding.PaddingBottom = UDim.new(0, 9)
        padding.Parent = page
        local list = Instance.new("UIListLayout")
        list.Padding = UDim.new(0, 8)
        list.SortOrder = Enum.SortOrder.LayoutOrder
        list.Parent = page

        local header = Instance.new("Frame")
        header.BackgroundTransparency = 1
        header.Size = UDim2.new(1, 0, 0, 42)
        header.LayoutOrder = -100
        header.Parent = page
        deps.Typography.Label(header, "Page", tokens, props.Title or id, UDim2.fromOffset(1, 1), UDim2.new(1, -10, 0, 21), tokens.Color.Text)
        deps.Typography.Label(header, "PageSub", tokens, props.Description or "", UDim2.fromOffset(1, 22), UDim2.new(1, -10, 0, 16), tokens.Color.TextMuted)

        local navItem = deps.NavItem.new(navHolder, deps, {
            Id = id,
            Title = props.Title or id,
            Icon = props.Icon or "info",
            Accent = accent,
            Order = props.Order or (#navItems + 1),
            Callback = function() app:SelectPage(id) end,
        })

        local entry = {Id = id, Page = page, NavItem = navItem, Accent = accent}
        pages[id] = entry
        table.insert(navItems, entry)

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
            entry.NavItem:SetSelected(selected)
        end
    end

    function app:SetGlassQuality(quality)
        if acrylic then acrylic:SetQuality(quality) end
    end

    function app:SetBlur(enabled)
        if acrylic then acrylic:SetEnabled(enabled) end
    end

    function app:SetSearchCallback(callback)
        app.SearchCallback = callback
    end

    local function openPageSearch()
        deps.PopupManager:Close()

        local popup = Instance.new("Frame")
        popup.AnchorPoint = Vector2.new(0.5, 0)
        popup.Position = UDim2.new(0.5, 0, 0, 45)
        popup.Size = UDim2.fromOffset(310, 282)
        popup.ZIndex = 80
        popup.Parent = overlay
        deps.Material.Popup(popup, tokens)

        local input = Instance.new("TextBox")
        input.Position = UDim2.fromOffset(8, 8)
        input.Size = UDim2.new(1, -16, 0, 34)
        input.BackgroundColor3 = tokens.Color.Inset
        input.BackgroundTransparency = 0.02
        input.BorderSizePixel = 0
        input.Text = ""
        input.PlaceholderText = "Jump to a page..."
        input.PlaceholderColor3 = tokens.Color.TextDim
        input.TextColor3 = tokens.Color.Text
        input.TextSize = tokens.Type.Value
        input.Font = deps.Typography.Font.Medium
        input.TextXAlignment = Enum.TextXAlignment.Left
        input.ClearTextOnFocus = false
        input.ZIndex = 81
        input.Parent = popup
        local ic = Instance.new("UICorner") ic.CornerRadius = UDim.new(0, 8) ic.Parent = input
        local ip = Instance.new("UIPadding") ip.PaddingLeft = UDim.new(0, 11) ip.PaddingRight = UDim.new(0, 10) ip.Parent = input

        local list = Instance.new("ScrollingFrame")
        list.BackgroundTransparency = 1
        list.BorderSizePixel = 0
        list.Position = UDim2.fromOffset(8, 49)
        list.Size = UDim2.new(1, -16, 1, -57)
        list.CanvasSize = UDim2.new()
        list.AutomaticCanvasSize = Enum.AutomaticSize.Y
        list.ScrollBarThickness = 2
        list.ScrollBarImageColor3 = tokens.Color.Accent
        list.ZIndex = 81
        list.Parent = popup
        local ll = Instance.new("UIListLayout") ll.Padding = UDim.new(0, 3) ll.Parent = list

        local rows = {}
        for _, entry in ipairs(navItems) do
            local row = Instance.new("TextButton")
            row.Size = UDim2.new(1, -2, 0, 34)
            row.BackgroundColor3 = tokens.Color.Control
            row.BackgroundTransparency = 0.50
            row.BorderSizePixel = 0
            row.Text = ""
            row.AutoButtonColor = false
            row.ZIndex = 82
            row.Parent = list
            local rc = Instance.new("UICorner") rc.CornerRadius = UDim.new(0, 8) rc.Parent = row

            local iconName = entry.NavItem.Icon.Name:gsub("Icon_", "")
            local icon = deps.Icons.Create(row, iconName, 15, entry.Accent, UDim2.fromOffset(10, 9))
            icon.ZIndex = 83
            local text = deps.Typography.Label(row, "Value", tokens, entry.NavItem.Label.Text, UDim2.fromOffset(34, 0), UDim2.new(1, -42, 1, 0), tokens.Color.TextMuted)
            text.ZIndex = 83

            rows[entry.Id] = {Frame = row, Search = string.lower(entry.NavItem.Label.Text .. " " .. entry.Id)}
            row.MouseButton1Click:Connect(function()
                deps.PopupManager:Close()
                app:SelectPage(entry.Id)
            end)
        end

        input:GetPropertyChangedSignal("Text"):Connect(function()
            local q = string.lower(input.Text or "")
            for _, rowData in pairs(rows) do
                rowData.Frame.Visible = q == "" or string.find(rowData.Search, q, 1, true) ~= nil
            end
        end)

        deps.PopupManager:Set(popup)
        input:CaptureFocus()
    end

    searchButton.MouseButton1Click:Connect(function()
        if app.SearchCallback then
            app.SearchCallback()
        else
            openPageSearch()
        end
    end)

    runtime:TrackConnection(deps.UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.K and deps.UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            openPageSearch()
        elseif input.KeyCode == Enum.KeyCode.Escape then
            deps.PopupManager:Close()
        end
    end))

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

    do
        local frames = 0
        local elapsed = 0
        runtime:TrackConnection(RunService.RenderStepped:Connect(function(dt)
            frames += 1
            elapsed += dt
            if elapsed >= 1 then
                fpsPill:SetText("FPS " .. tostring(math.floor(frames / elapsed + 0.5)))
                frames = 0
                elapsed = 0

                local ok, mem = pcall(function() return Stats:GetTotalMemoryUsageMb() end)
                if ok and mem then
                    memPill:SetText("MEM " .. tostring(math.floor(mem + 0.5)) .. " MB")
                end
            end
        end))
    end

    return app
end

return Desktop
