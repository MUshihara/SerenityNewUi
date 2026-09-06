return function(ui,input,state,options)
    local T=ui.T
    local parent=options.Parent
    if not parent and type(gethui)=='function' then pcall(function() parent=gethui() end) end
    if not parent then parent=game:GetService('Players').LocalPlayer:WaitForChild('PlayerGui') end
    local screen=ui.R:Own(ui:New('ScreenGui',parent,{Name='SerenityConcept02',ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=999999,ZIndexBehavior=Enum.ZIndexBehavior.Sibling}))
    local holder=ui:Frame(screen,{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(T.Width,T.Height)})
    local scale=ui:New('UIScale',holder,{Scale=1})
    local shadow=ui:New('ImageLabel',holder,{BackgroundTransparency=1,AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),
        Size=UDim2.new(1,38,1,38),Image='rbxassetid://1316045217',ImageColor3=Color3.new(0,0,0),ImageTransparency=0.42,
        ScaleType=Enum.ScaleType.Slice,SliceCenter=Rect.new(10,10,118,118),ZIndex=1})
    local shell=ui:Panel(holder,{Size=UDim2.fromScale(1,1),BackgroundColor3=T.Shell,ZIndex=2})
    ui:Frame(shell,{Position=UDim2.fromOffset(T.Sidebar,14),Size=UDim2.new(0,1,1,-28),BackgroundColor3=T.Line,BackgroundTransparency=0.1})
    local logo='rbxthumb://type=Asset&id=89023606689629&w=420&h=420'
    local brand=ui:Frame(shell,{Size=UDim2.fromOffset(T.Sidebar,T.Header),Active=true})
    ui:New('ImageLabel',brand,{Image=logo,BackgroundTransparency=1,Position=UDim2.fromOffset(15,18),Size=UDim2.fromOffset(28,28),ScaleType=Enum.ScaleType.Fit})
    ui:Label(brand,'SERENITY HUB',13,UDim2.fromOffset(53,17),UDim2.new(1,-59,0,19),nil,true)
    local subtitle=ui:Label(brand,'UI Playground',10,UDim2.fromOffset(53,38),UDim2.new(1,-59,0,15),T.Muted)
    local navigation=ui:New('ScrollingFrame',shell,{BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromOffset(14,76),Size=UDim2.new(0,T.Sidebar-27,1,-149),
        CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=0})
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
    local badge=ui:Panel(header,{Position=UDim2.new(1,-153,0,19),Size=UDim2.fromOffset(80,26),BackgroundColor3=T.Shell})
    local badgeText=ui:Label(badge,'Preview',10); badgeText.TextXAlignment=Enum.TextXAlignment.Center
    local search=ui:Button(header,'',{Position=UDim2.new(1,-65,0,18),Size=UDim2.fromOffset(28,28),BackgroundTransparency=1})
    ui:Icon(search,'search',17,UDim2.fromOffset(5,5),T.Text)
    local minimize=ui:Button(header,'',{Position=UDim2.new(1,-29,0,18),Size=UDim2.fromOffset(28,28),BackgroundTransparency=1})
    ui:Icon(minimize,'minus',18,UDim2.fromOffset(5,5),T.Muted)
    local content=ui:Frame(shell,{Position=UDim2.fromOffset(T.Sidebar+16,T.Header+9),Size=UDim2.new(1,-T.Sidebar-32,1,-T.Header-23)})
    local launcher=ui:Button(screen,'',{Position=UDim2.fromOffset(18,180),Size=UDim2.fromOffset(43,43),Visible=false,BackgroundColor3=T.Panel,ZIndex=4})
    ui:Stroke(launcher); ui:New('ImageLabel',launcher,{Image=logo,BackgroundTransparency=1,Position=UDim2.fromOffset(9,9),Size=UDim2.fromOffset(25,25)})
    local app={Screen=screen,Holder=holder,Shell=shell,Content=content,Scale=scale,Pages={},Current=nil,SearchButton=search,Visible=true,GameTitle=gameTitle,Subtitle=subtitle}
    function app:Fit()
        local view=screen.AbsoluteSize
        if view.X<10 or view.Y<10 then return end
        local desired=tonumber(state:Get('Settings.Appearance.Scale',100)) or 100
        scale.Scale=math.max(0.2,math.min(desired/100,(view.X-24)/T.Width,(view.Y-24)/T.Height))
        local x=math.clamp(holder.AbsolutePosition.X+holder.AbsoluteSize.X/2,T.Width*scale.Scale/2+12,math.max(T.Width*scale.Scale/2+12,view.X-T.Width*scale.Scale/2-12))
        local y=math.clamp(holder.AbsolutePosition.Y+holder.AbsoluteSize.Y/2,T.Height*scale.Scale/2+12,math.max(T.Height*scale.Scale/2+12,view.Y-T.Height*scale.Scale/2-12))
        holder.Position=UDim2.fromOffset(x,y)
        if self.Popup then self.Popup:Close() end
    end
    function app:SetVisible(value)
        self.Visible=value==true; input:Cancel(); if self.Popup then self.Popup:Close() end
        holder.Visible=self.Visible; launcher.Visible=not self.Visible
    end
    function app:AddPage(spec)
        local row=ui:Button(navigation,'',{Name=spec.Id,Size=UDim2.new(1,0,0,33),BackgroundTransparency=1})
        local tile=ui:Frame(row,{Size=UDim2.fromOffset(26,26),Position=UDim2.fromOffset(0,3),BackgroundColor3=T.Inset,BackgroundTransparency=0}); ui:Round(tile,7)
        local icon=ui:Icon(tile,spec.Icon,15,UDim2.fromOffset(5.5,5.5),T.Muted)
        local navText=ui:Label(row,spec.Title,11,UDim2.fromOffset(36,0),UDim2.new(1,-40,1,0))
        local page=ui:Frame(content,{Size=UDim2.fromScale(1,1),Visible=false})
        local entry={Frame=page,Spec=spec,Tile=tile,Icon=icon,Label=navText}
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
        input:Cancel(); if self.Popup then self.Popup:Close() end
        self.Current=id; state:Set('View.Page',id)
        title.Text=target.Spec.Title; description.Text=target.Spec.Description or ''
        for key,entry in pairs(self.Pages) do
            local selected=key==id; entry.Frame.Visible=selected
            entry.Tile.BackgroundColor3=selected and T.Accent or T.Inset
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
                local view=screen.AbsoluteSize; local half=Vector2.new(T.Width*scale.Scale/2,T.Height*scale.Scale/2)
                holder.Position=UDim2.fromOffset(math.clamp(center.X+pos.X-start.X,half.X+8,math.max(half.X+8,view.X-half.X-8)),math.clamp(center.Y+pos.Y-start.Y,half.Y+8,math.max(half.Y+8,view.Y-half.Y-8)))
            end)
        end)
    end
    dragRegion(brand); dragRegion(header)
    minimize.Activated:Connect(function() app:SetVisible(false) end)
    launcher.Activated:Connect(function() app:SetVisible(true) end)
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
