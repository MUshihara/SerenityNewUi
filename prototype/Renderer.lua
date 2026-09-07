return function(ui,input,state,options,mobileLayout)
    local T=ui.T
    local parent=options.Parent
    if not parent and type(gethui)=='function' then pcall(function() parent=gethui() end) end
    if not parent then parent=game:GetService('Players').LocalPlayer:WaitForChild('PlayerGui') end
    local screen=ui.R:Own(ui:New('ScreenGui',parent,{Name='SerenityConcept02',ResetOnSpawn=false,IgnoreGuiInset=false,DisplayOrder=999999,ZIndexBehavior=Enum.ZIndexBehavior.Sibling}))
    local holder=ui:Frame(screen,{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(T.Width,T.Height)})
    local scale=ui:New('UIScale',holder,{Scale=1})
    local shadow=ui:New('ImageLabel',holder,{BackgroundTransparency=1,AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),
        Size=UDim2.new(1,38,1,38),Image='rbxassetid://1316045217',ImageColor3=Color3.new(0,0,0),ImageTransparency=0.42,
        ScaleType=Enum.ScaleType.Slice,SliceCenter=Rect.new(10,10,118,118),ZIndex=1})
    local shell=ui:Panel(holder,{Size=UDim2.fromScale(1,1),BackgroundColor3=T.Shell,ZIndex=2})
    local divider=ui:Frame(shell,{Position=UDim2.fromOffset(T.Sidebar,14),Size=UDim2.new(0,1,1,-28),BackgroundColor3=T.Line,BackgroundTransparency=0.1})
    local logo='rbxthumb://type=Asset&id=89023606689629&w=420&h=420'
    local brand=ui:Frame(shell,{Size=UDim2.new(1,0,0,44),Active=true})
    local topLine=ui:Frame(brand,{Position=UDim2.new(0,12,1,-1),Size=UDim2.new(1,-24,0,1),BackgroundColor3=T.Accent,BackgroundTransparency=0.35})
    ui:Accent(function(color) topLine.BackgroundColor3=color end)
    ui:New('ImageLabel',brand,{Image=logo,BackgroundTransparency=1,Position=UDim2.fromOffset(14,6),Size=UDim2.fromOffset(32,32),ScaleType=Enum.ScaleType.Fit})
    local brandTitle=ui:Label(brand,'SERENITY HUB',13,UDim2.fromOffset(54,12),UDim2.fromOffset(126,20),nil,true)
    local subtitle=ui:Label(brand,'UI Playground',10,UDim2.fromOffset(190,14),UDim2.new(1,-370,0,18),T.Muted)
    local navigation=ui:New('ScrollingFrame',shell,{BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromOffset(14,76),Size=UDim2.new(0,T.Sidebar-27,1,-149),
        CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=2,ScrollBarImageColor3=T.Muted})
    ui:List(navigation,5)
    local gameCard=ui:Panel(shell,{Position=UDim2.new(0,12,1,-65),Size=UDim2.fromOffset(T.Sidebar-24,53),BackgroundColor3=T.Shell})
    local gameImage=ui:New('ImageLabel',gameCard,{BackgroundColor3=T.Inset,BorderSizePixel=0,Position=UDim2.fromOffset(6,6),Size=UDim2.fromOffset(40,40),
        Image='rbxthumb://type=GameIcon&id='..tostring(game.GameId)..'&w=150&h=150',ScaleType=Enum.ScaleType.Crop}); ui:Round(gameImage,7)
    local gameTitle=ui:Label(gameCard,'Current game',11,UDim2.fromOffset(53,9),UDim2.new(1,-60,0,17),nil,true)
    local dot=ui:Frame(gameCard,{Position=UDim2.fromOffset(54,32),Size=UDim2.fromOffset(5,5),BackgroundColor3=T.Green,BackgroundTransparency=0}); ui:Round(dot,3)
    ui:Label(gameCard,'UI preview',9,UDim2.fromOffset(64,26),UDim2.new(1,-67,0,17),T.Muted)
    local header=ui:Frame(shell,{Position=UDim2.fromOffset(T.Sidebar+16,0),Size=UDim2.new(1,-T.Sidebar-32,0,T.Header),Active=true})
    local title=ui:Label(header,'About',16,UDim2.fromOffset(0,16),UDim2.new(1,-175,0,23),nil,true)
    local description=ui:Label(header,'Welcome to Serenity',10,UDim2.fromOffset(0,39),UDim2.new(1,-175,0,16),T.Muted)
    local badge=ui:Panel(brand,{Position=UDim2.new(1,-174,0,9),Size=UDim2.fromOffset(80,26),BackgroundColor3=T.Shell})
    local badgeText=ui:Label(badge,'Preview',10); badgeText.TextXAlignment=Enum.TextXAlignment.Center
    local search=ui:Button(brand,'',{Position=UDim2.new(1,-88,0,2),Size=UDim2.fromOffset(40,40),BackgroundTransparency=1})
    ui:Icon(search,'search',22,UDim2.fromOffset(9,9),T.Text)
    local minimize=ui:Button(brand,'',{Position=UDim2.new(1,-44,0,2),Size=UDim2.fromOffset(40,40),BackgroundTransparency=1})
    ui:Icon(minimize,'minus',22,UDim2.fromOffset(9,9),T.Muted)
    local content=ui:Frame(shell,{Position=UDim2.fromOffset(T.Sidebar+16,T.Header+9),Size=UDim2.new(1,-T.Sidebar-32,1,-T.Header-23)})
    local launcher=ui:Button(screen,'',{Position=UDim2.fromOffset(18,180),Size=UDim2.fromOffset(56,56),Visible=true,BackgroundColor3=T.Panel,ZIndex=4})
    ui:Stroke(launcher); ui:New('ImageLabel',launcher,{Image=logo,BackgroundTransparency=1,Position=UDim2.fromOffset(9,9),Size=UDim2.fromOffset(38,38)})
    local app={Screen=screen,Holder=holder,Shell=shell,Content=content,Scale=scale,Pages={},Current=nil,SearchButton=search,Visible=true,GameTitle=gameTitle,Subtitle=subtitle,Launcher=launcher,LayoutWidth=T.Width,LayoutHeight=T.Height,SidebarWidth=T.Sidebar}
    function app:Fit()
        local view=screen.AbsoluteSize
        if view.X<10 or view.Y<10 then return end
        local desired=tonumber(state:Get('Settings.Appearance.Scale',100)) or 100
        local mobile=ui.Touch or view.X<700
        local layout=mobile and mobileLayout(view) or {Width=T.Width,Height=T.Height,Sidebar=T.Sidebar,Header=T.Header,Rail=false}
        local compact=layout.Rail
        local width,height,sidebar=layout.Width,layout.Height,layout.Sidebar
        local topHeight=44
        local headerHeight=mobile and 44 or 54
        self.Mobile=mobile
        self.LayoutWidth=width; self.LayoutHeight=height; self.SidebarWidth=sidebar
        holder.Size=UDim2.fromOffset(width,height)
        scale.Scale=math.max(0.2,math.min(desired/100,(view.X-24)/width,(view.Y-24)/height))
        ui.ScaleFactor=scale.Scale
        divider.Position=UDim2.fromOffset(sidebar,topHeight+10); divider.Size=UDim2.new(0,1,1,-topHeight-22)
        brand.Size=UDim2.new(1,0,0,topHeight); brandTitle.Visible=true; subtitle.Visible=not mobile
        navigation.Size=UDim2.new(0,sidebar-20,1,compact and -137 or -149)
        navigation.Position=UDim2.fromOffset(10,topHeight+10)
        navigation.Size=UDim2.new(0,sidebar-20,1,-topHeight-80)
        gameCard.Size=UDim2.fromOffset(sidebar-16,53); gameCard.Position=UDim2.new(0,8,1,-61)
        gameTitle.Visible=not compact; dot.Visible=not compact
        for _,child in ipairs(gameCard:GetChildren()) do if child:IsA('TextLabel') then child.Visible=not compact end end
        header.Position=UDim2.fromOffset(sidebar+12,topHeight); header.Size=UDim2.new(1,-sidebar-24,0,headerHeight)
        badge.Visible=not mobile
        title.Position=UDim2.fromOffset(0,mobile and 10 or 6); title.Size=UDim2.new(1,0,0,23); title.TextSize=18
        description.Position=UDim2.fromOffset(0,30); description.Size=UDim2.new(1,0,0,16); description.TextSize=11
        content.Position=UDim2.fromOffset(sidebar+12,topHeight+headerHeight+5); content.Size=UDim2.new(1,-sidebar-24,1,-topHeight-headerHeight-17)
        for _,entry in pairs(self.Pages) do
            entry.Row.Size=UDim2.new(1,0,0,compact and 56 or 44)
            entry.Tile.Position=UDim2.fromOffset(compact and 7 or 0,compact and 0 or 5)
            entry.Label.TextSize=compact and 9 or 13
            entry.Label.TextXAlignment=compact and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left
            entry.Label.Position=compact and UDim2.fromOffset(-3,35) or UDim2.fromOffset(44,0)
            entry.Label.Size=compact and UDim2.new(1,6,0,18) or UDim2.new(1,-48,1,0)
        end
        description.Visible=not mobile
        subtitle.Visible=not mobile
        shadow.Visible=not ui.LowEffects
        local x=math.clamp(holder.AbsolutePosition.X+holder.AbsoluteSize.X/2,width*scale.Scale/2+12,math.max(width*scale.Scale/2+12,view.X-width*scale.Scale/2-12))
        local y=math.clamp(holder.AbsolutePosition.Y+holder.AbsoluteSize.Y/2,height*scale.Scale/2+12,math.max(height*scale.Scale/2+12,view.Y-height*scale.Scale/2-12))
        holder.Position=UDim2.fromOffset(x,y)
        self:FitLauncher()
        for _,callback in ipairs(ui.LayoutCallbacks) do callback() end
        if self.Popup then self.Popup:Close(true) end
    end
    function app:FitLauncher()
        local view=screen.AbsoluteSize
        local x=math.clamp(tonumber(state:Get('View.LauncherX',18)) or 18,8,math.max(8,view.X-64))
        local y=math.clamp(tonumber(state:Get('View.LauncherY',180)) or 180,8,math.max(8,view.Y-64))
        launcher.Position=UDim2.fromOffset(x,y)
    end
    function app:SetVisible(value)
        self.Visible=value==true; input:Cancel(); if self.Popup then self.Popup:Close(true) end
        holder.Visible=self.Visible; launcher.Visible=true
    end
    function app:AddPage(spec)
        self.NavCount=(self.NavCount or 0)+1
        local row=ui:Button(navigation,'',{Name=spec.Id,LayoutOrder=self.NavCount,Size=UDim2.new(1,0,0,44),BackgroundTransparency=1})
        local tile=ui:Frame(row,{Size=UDim2.fromOffset(34,34),Position=UDim2.fromOffset(0,3),BackgroundColor3=T.Inset,BackgroundTransparency=0}); ui:Round(tile,7)
        local tileScale=ui:New('UIScale',tile,{Scale=1})
        local icon=ui:Icon(tile,spec.Icon,22,UDim2.fromOffset(6,6),T.Muted)
        local navText=ui:Label(row,spec.Title,13,UDim2.fromOffset(44,0),UDim2.new(1,-40,1,0))
        local page=ui:Frame(content,{Size=UDim2.fromScale(1,1),Visible=false})
        local entry={Row=row,Frame=page,Spec=spec,Tile=tile,TileScale=tileScale,Icon=icon,Label=navText}
        self.Pages[spec.Id]=entry
        row.Activated:Connect(function() self:SelectPage(spec.Id) end)
        ui:Accent(function(color)
            local selected=self.Current==spec.Id
            tile.BackgroundColor3=selected and color or T.Inset; icon.ImageColor3=selected and T.Text or T.Muted
        end)
        return page
    end
    function app:SelectPage(id)
        local target=self.Pages[id]; if not target then return end
        input:Cancel(); if self.Popup then self.Popup:Close(true) end
        self.Current=id; state:Set('View.Page',id)
        title.Text=target.Spec.Title; description.Text=target.Spec.Description or ''
        for key,entry in pairs(self.Pages) do
            local selected=key==id; entry.Frame.Visible=selected
            if selected then entry.TileScale.Scale=(ui.Reduced or ui.LowEffects) and 1 or 0.9 end
            ui:Tween(entry.TileScale,0.18,{Scale=1})
            ui:Tween(entry.Tile,0.12,{BackgroundColor3=selected and T.Accent or T.Inset})
            entry.Icon.ImageColor3=selected and T.Text or T.Muted
            entry.Label.TextColor3=selected and T.Text or T.Muted
        end
        target.Frame.Position=UDim2.fromOffset(ui.Reduced and 0 or 5,0)
        ui:Tween(target.Frame,0.13,{Position=UDim2.fromOffset(0,0)})
    end
    local function dragRegion(region)
        ui.R:Connect(region.InputBegan,function(event)
            if event.UserInputType~=Enum.UserInputType.MouseButton1 and event.UserInputType~=Enum.UserInputType.Touch then return end
            local start=event.Position; local center=Vector2.new(holder.AbsolutePosition.X+holder.AbsoluteSize.X/2,holder.AbsolutePosition.Y+holder.AbsoluteSize.Y/2)
            input:Capture(event,function(pos)
                local view=screen.AbsoluteSize; local half=Vector2.new(app.LayoutWidth*scale.Scale/2,app.LayoutHeight*scale.Scale/2)
                holder.Position=UDim2.fromOffset(math.clamp(center.X+pos.X-start.X,half.X+8,math.max(half.X+8,view.X-half.X-8)),math.clamp(center.Y+pos.Y-start.Y,half.Y+8,math.max(half.Y+8,view.Y-half.Y-8)))
            end)
        end)
    end
    dragRegion(brand); dragRegion(header)
    minimize.Activated:Connect(function() app:SetVisible(false) end)
    local dragged=false
    launcher.InputBegan:Connect(function(event)
        if event.UserInputType~=Enum.UserInputType.MouseButton1 and event.UserInputType~=Enum.UserInputType.Touch then return end
        local start=event.Position;local origin=launcher.Position
        dragged=false
        input:Capture(event,function(pos)
            local dx,dy=pos.X-start.X,pos.Y-start.Y
            if dx*dx+dy*dy>36 then dragged=true end
            if dragged then
                local view=screen.AbsoluteSize
                launcher.Position=UDim2.fromOffset(math.clamp(origin.X.Offset+dx,8,math.max(8,view.X-64)),math.clamp(origin.Y.Offset+dy,8,math.max(8,view.Y-64)))
            end
        end,function()
            if dragged then
                state:Set('View.LauncherX',launcher.Position.X.Offset);state:Set('View.LauncherY',launcher.Position.Y.Offset)
            end
        end)
    end)
    launcher.Activated:Connect(function() if not dragged then app:SetVisible(not app.Visible) end end)
    table.insert(input.Shortcuts,function(event)
        if event.KeyCode==Enum.KeyCode.RightControl then app:SetVisible(not app.Visible); return true end
    end)
    ui.R:Connect(screen:GetPropertyChangedSignal('AbsoluteSize'),function() app:Fit() end)
    task.defer(function() if not ui.R.Destroyed then app:Fit() end end)
    task.spawn(function()
        local ok,info=pcall(function() return game:GetService('MarketplaceService'):GetProductInfo(game.PlaceId) end)
        if ok and info and info.Name and not ui.R.Destroyed then gameTitle.Text=info.Name; subtitle.Text=info.Name end
    end)
    return app
end
