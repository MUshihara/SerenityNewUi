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
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
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
        local fit = math.min(1, (viewport.X - 24) / tokens.Size.Window.X, (viewport.Y - inset.Y - 24) / tokens.Size.Window.Y)
        uiScale.Scale = math.clamp(fit, 0.62, 1)
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
    deps.UIScale = uiScale

    -- LEFT SIDEBAR ------------------------------------------------------------
    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0, tokens.Size.Sidebar, 1, 0)
    sidebar.ZIndex = 3
    sidebar.Parent = shell
    deps.Material.Sidebar(sidebar, tokens)

    local brand = Instance.new("Frame")
    brand.BackgroundTransparency = 1
    brand.Size = UDim2.new(1, 0, 0, tokens.Size.SidebarBrand)
    brand.ZIndex = 4
    brand.Parent = sidebar

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
    topbar.Position = UDim2.fromOffset(tokens.Size.Sidebar, 0)
    topbar.Size = UDim2.new(1, -tokens.Size.Sidebar, 0, tokens.Size.Topbar)
    topbar.ZIndex = 3
    topbar.Parent = shell
    deps.Material.Topbar(topbar, tokens)

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

    local pageButton, pageText = createTopSelect(56, 132, "Automation")
    local scopeButton, scopeText = createTopSelect(198, 108, "Global")

    local searchButton = Instance.new("TextButton")
    searchButton.AnchorPoint = Vector2.new(1, 0.5)
    searchButton.Position = UDim2.new(1, -17, 0.5, 0)
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
    makeDraggable(runtime, holder, brand)

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
        local order = props.Order or (#navItems + 1)

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

    local function createSearchPopup()
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
        task.defer(function() input:CaptureFocus() end)
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

    searchButton.MouseButton1Click:Connect(createSearchPopup)
    pageButton.MouseButton1Click:Connect(createSearchPopup)
    scopeButton.MouseButton1Click:Connect(createScopePopup)

    runtime:TrackConnection(UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.K and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            createSearchPopup()
        elseif input.KeyCode == Enum.KeyCode.RightControl then
            shell.Visible = not shell.Visible
        elseif input.KeyCode == Enum.KeyCode.Escape then
            deps.PopupManager:Close()
        end
    end))

    task.spawn(function()
        local ok, info = pcall(function() return MarketplaceService:GetProductInfo(game.PlaceId) end)
        if ok and info and info.Name then
            brandSub.Text = info.Name
        end
    end)

    return app
end

return Desktop
