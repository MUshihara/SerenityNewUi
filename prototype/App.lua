return function(M,options)
    options=options or {}
    options.AssetBase=options.AssetBase or 'https://raw.githubusercontent.com/MUshihara/SerenityNewUi/77e5a1d2a4bc5e662bf52258a22b2976aedba1f8/prototype/assets/'
    options.DiscordInvite=options.DiscordInvite or 'https://discord.gg/ccsvkN7Pp'
    local manifest=M.Manifest
    assert(manifest.SerenityAPIVersion==3,'Expected V3 manifest')
    local runtime=M.Runtime.new()
    local defaults={['View.Page']='About'}
    for _,page in ipairs(manifest.Pages) do
        defaults['View.Tab.'..page.Id]=(page.Tabs and page.Tabs[1].Id) or 'Main'
        for _,feature in ipairs(page.Features) do
            defaults['View.Section.'..page.Id..'.'..feature.Id]=feature.Expanded~=false
            for _,control in ipairs(feature.Controls) do
                if control.Default~=nil then defaults[page.Id..'.'..feature.Id..'.'..control.Id]=control.Default end
            end
        end
    end
    local state=M.State.new(defaults,runtime)
    local ui=M.UI(M.Theme,runtime,M.Icons)
    local input=M.Input(runtime)
    local app
    local ok,err=xpcall(function()
        app=M.Renderer(ui,input,state,options)
        local popup=M.Popup(ui,input,app.Screen,function() return app.Scale.Scale end)
        app.Popup=popup; app.Runtime=runtime; app.Config=state; app.Controls={}; app.Sections={}; app.Tabs={}; app.SearchEntries={}
        local assets=M.Assets(runtime,options)
        local controls=M.Controls(ui,input,popup)
        local choice=M.Choice(ui,popup)
        function app:Destroy() runtime:Destroy() end
        function app:SetLive(key,value) if self.Controls[key] and self.Controls[key].Set then self.Controls[key]:Set(value,true) end end
        function app:ApplyEffect(effect,value)
            if effect=='Accent' then
                local colors={Rose=Color3.fromRGB(235,58,151),Cyan=Color3.fromRGB(62,193,216),Lavender=Color3.fromRGB(163,122,224)}
                ui:SetAccent(colors[value] or colors.Rose)
            elseif effect=='Scale' then self:Fit()
            elseif effect=='Transparency' then self.Shell.BackgroundTransparency=math.clamp(tonumber(value) or 0,0,20)/100
            elseif effect=='Motion' then ui.Reduced=value==true end
        end
        function app:Copy(text,title)
            if type(setclipboard)=='function' then
                local good=pcall(setclipboard,text)
                if good then popup:Message(title or 'Copied','The link or value has been copied to your clipboard.'); return end
            end
            popup:Message(title or 'Copy this value','Select the value below and copy it manually.',text)
        end
        function app:Action(name)
            if name=='CopyPlace' then self:Copy(tostring(game.PlaceId),'Place ID')
            elseif name=='Search' then self:Search()
            elseif name=='Minimize' then self:SetVisible(false)
            elseif name=='Center' then self.Holder.Position=UDim2.fromScale(0.5,0.5); self:Fit()
            elseif name=='Save' then local saved=state:Save(); popup:Message('Preview settings',saved and 'Your preview settings have been saved.' or 'Local file access is unavailable. Settings will last for this session.')
            elseif name=='Reset' then
                local panel=popup:Open(nil,340,170)
                ui:Label(panel,'Reset preview settings?',15,UDim2.fromOffset(16,12),UDim2.new(1,-32,0,30),nil,true)
                ui:Label(panel,'Only this prototype’s settings will reset.',11,UDim2.fromOffset(16,48),UDim2.new(1,-32,0,35),ui.T.Muted)
                ui:Button(panel,'Cancel',{Position=UDim2.fromOffset(16,114),Size=UDim2.fromOffset(142,32)},function() popup:Close() end)
                ui:Button(panel,'Reset',{Position=UDim2.fromOffset(172,114),Size=UDim2.fromOffset(152,32),BackgroundColor3=ui.T.Accent},function()
                    popup:Close()
                    for key,control in pairs(self.Controls) do if defaults[key]~=nil and control.Set then control:Set(defaults[key],false) end end
                    state:Save()
                end)
            elseif name=='Destroy' then self:Destroy() end
        end
        local function scroller(parent,y)
            local scroll=ui:New('ScrollingFrame',parent,{Position=UDim2.fromOffset(0,y or 0),Size=UDim2.new(1,0,1,-(y or 0)),
                BackgroundTransparency=1,BorderSizePixel=0,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=2,
                ScrollBarImageColor3=ui.T.Dim,ScrollBarImageTransparency=0.4})
            ui:Pad(scroll,1,1,4,8); ui:List(scroll,10); return scroll
        end
        local function card(parent,kind,x,title,description,icon,buttonText,callback)
            local frame=ui:Panel(parent,{Position=UDim2.new(x,x>0 and 6 or 0,0,0),Size=UDim2.new(0.5,-6,0,280)})
            ui:Label(frame,string.upper(kind),10,UDim2.fromOffset(12,0),UDim2.new(1,-24,0,32),ui.T.Muted)
            local pic=ui:Frame(frame,{Position=UDim2.fromOffset(10,33),Size=UDim2.new(1,-20,0,130),ClipsDescendants=true,BackgroundColor3=kind=='Community' and Color3.fromRGB(22,42,62) or Color3.fromRGB(58,33,51),BackgroundTransparency=0}); ui:Round(pic,7)
            ui:Icon(pic,icon,34,UDim2.new(0.5,-17,0.5,-17),Color3.fromRGB(178,175,204))
            local image=ui:New('ImageLabel',pic,{BackgroundTransparency=1,Size=UDim2.fromScale(1,1),Image='',ScaleType=Enum.ScaleType.Crop,ZIndex=2}); ui:Round(image,7)
            assets:Load(kind,image)
            local badge=ui:Panel(pic,{Position=UDim2.new(0,8,1,-37),Size=UDim2.fromOffset(29,29),ZIndex=3,BackgroundTransparency=0.1})
            ui:Icon(badge,icon,16,UDim2.fromOffset(6.5,6.5),ui.T.Text)
            ui:Label(frame,title,13,UDim2.fromOffset(12,174),UDim2.new(1,-24,0,24),nil,true)
            ui:Label(frame,description,10,UDim2.fromOffset(12,201),UDim2.new(1,-24,0,21),ui.T.Muted)
            local b=ui:Button(frame,buttonText,{Position=UDim2.fromOffset(12,235),Size=UDim2.new(1,-24,0,32)},callback); ui:Stroke(b,nil,0.5)
        end
        for _,page in ipairs(manifest.Pages) do
            local pageFrame=app:AddPage(page)
            app.SearchEntries[#app.SearchEntries+1]={Title=page.Title,Path=page.Title,Page=page.Id,Target=pageFrame}
            if page.Id=='About' then
                local scroll=scroller(pageFrame)
                local section=M.Section(ui,scroll,'What’s new',false,function() popup:Close() end)
                controls.Paragraph(section.Body,{Title='Concept 02',Text='Compact navigation, image cards, working controls and saved preview settings.',Height=80})
                local cards=ui:Frame(scroll,{Size=UDim2.new(1,0,0,280)})
                card(cards,'Community',0,'Serenity Community','Meet the community','messages-square','Copy Discord Link',function() app:Copy(options.DiscordInvite,'Discord invite') end)
                card(cards,'Updates',0.5,'Release Notes','See the latest changes','megaphone','View Changelog',function()
                    popup:Message('Concept 02 — preview','Added compact navigation, expandable sections, searchable selections, image cards, UI scale, accent colors, and isolated preview settings.\n\nGame automation is not connected.')
                end)
            else
                local tabMap={}; local tabOrder=page.Tabs or {{Id='Main'}}
                local tabBar
                if page.Tabs then tabBar=ui:Frame(pageFrame,{Size=UDim2.new(1,0,0,32)}); ui:List(tabBar,7,true) end
                local function selectTab(id)
                    if not tabMap[id] then return end
                    input:Cancel(); popup:Close(); state:Set('View.Tab.'..page.Id,id)
                    for key,tab in pairs(tabMap) do
                        tab.Scroll.Visible=key==id
                        if key==id then
                            tab.Scroll.Position=UDim2.fromOffset(ui.Reduced and 0 or 5,tabBar and 42 or 0)
                            ui:Tween(tab.Scroll,0.16,{Position=UDim2.fromOffset(0,tabBar and 42 or 0)})
                        end
                        if tab.Button then tab.Button.BackgroundColor3=key==id and ui.T.Accent or ui.T.Inset end
                    end
                end
                for _,spec in ipairs(tabOrder) do
                    local scroll=scroller(pageFrame,tabBar and 42 or 0)
                    local tab={Scroll=scroll}; tabMap[spec.Id]=tab
                    if tabBar then
                        local width=math.max(76,#spec.Id*7+35)
                        tab.Button=ui:Button(tabBar,'',{Size=UDim2.fromOffset(width,30)},function() selectTab(spec.Id) end)
                        ui:Stroke(tab.Button,nil,0.5)
                        ui:Icon(tab.Button,spec.Icon or 'menu',12,UDim2.fromOffset(9,9),ui.T.Text)
                        ui:Label(tab.Button,spec.Id,10,UDim2.fromOffset(27,0),UDim2.new(1,-32,1,0))
                    end
                end
                app.Tabs[page.Id]={Select=selectTab,Items=tabMap}
                ui:Accent(function(color)
                    for key,tab in pairs(tabMap) do if tab.Button then tab.Button.BackgroundColor3=key==state:Get('View.Tab.'..page.Id) and color or ui.T.Inset end end
                end)
                for _,feature in ipairs(page.Features) do
                    local tabId=feature.Tab or 'Main'; local scroll=assert(tabMap[tabId],'Missing sub-tab').Scroll
                    local sectionKey=page.Id..'.'..feature.Id
                    local section=M.Section(ui,scroll,feature.Title,state:Get('View.Section.'..sectionKey,feature.Expanded~=false),function(open)
                        input:Cancel(); popup:Close(); state:Set('View.Section.'..sectionKey,open)
                    end)
                    app.Sections[sectionKey]=section
                    for _,spec in ipairs(feature.Controls) do
                        local key=sectionKey..'.'..spec.Id
                        local props={}; for k,v in pairs(spec) do props[k]=v end
                        if spec.Default~=nil then props.Default=state:Get(key,spec.Default) end
                        props.Callback=function(value)
                            if spec.Type=='Action' then app:Action(spec.Action)
                            else state:Set(key,value); if spec.Effect then app:ApplyEffect(spec.Effect,value) end end
                        end
                        local control
                        if spec.Type=='Select' or spec.Type=='MultiSelect' then control=choice(section.Body,props,spec.Type=='MultiSelect')
                        else control=assert(controls[spec.Type],'Unknown control type')(section.Body,props) end
                        app.Controls[key]=control
                        if spec.Default~=nil and control.Get then state:Set(key,control:Get()) end
                        app.SearchEntries[#app.SearchEntries+1]={Title=spec.Title,Path=page.Title..' / '..(feature.Tab and feature.Tab..' / ' or '')..feature.Title,
                            Page=page.Id,Tab=tabId,Section=section,Scroll=scroll,Target=control.Frame}
                    end
                end
                local savedTab=state:Get('View.Tab.'..page.Id,tabOrder[1].Id)
                selectTab(tabMap[savedTab] and savedTab or tabOrder[1].Id)
            end
        end
        function app:Search()
            if not self.Visible then self:SetVisible(true) end
            local panel=popup:Open(nil,430,350)
            ui:Label(panel,'Search controls',15,UDim2.fromOffset(14,10),UDim2.new(1,-28,0,28),nil,true)
            local box=ui:New('TextBox',panel,{Position=UDim2.fromOffset(12,46),Size=UDim2.new(1,-24,0,33),BackgroundColor3=ui.T.Inset,BorderSizePixel=0,
                Text='',PlaceholderText='Page, tab or control...',ClearTextOnFocus=false,TextSize=12,Font=ui.T.Medium,TextColor3=ui.T.Text,PlaceholderColor3=ui.T.Dim,TextXAlignment=Enum.TextXAlignment.Left}); ui:Round(box,6); ui:Pad(box,10,0,10,0)
            local list=ui:New('ScrollingFrame',panel,{Position=UDim2.fromOffset(12,88),Size=UDim2.new(1,-24,1,-100),BackgroundTransparency=1,BorderSizePixel=0,
                CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=2,ScrollBarImageColor3=ui.T.Accent}); ui:List(list,4)
            local rows={}
            for _,entry in ipairs(self.SearchEntries) do
                local button=ui:Button(list,'',{Size=UDim2.new(1,-4,0,45)},function()
                    popup:Close(); self:SelectPage(entry.Page)
                    if entry.Tab then self.Tabs[entry.Page].Select(entry.Tab) end
                    if entry.Section then entry.Section:SetOpen(true,true) end
                    task.defer(function()
                        if runtime.Destroyed or self.Current~=entry.Page then return end
                        if entry.Scroll then
                            local y=entry.Target.AbsolutePosition.Y-entry.Scroll.AbsolutePosition.Y+entry.Scroll.CanvasPosition.Y-7
                            entry.Scroll.CanvasPosition=Vector2.new(0,math.max(0,y))
                        end
                        local flash=ui:Stroke(entry.Target,ui.T.Accent,0.05)
                        ui:Tween(flash,0.65,{Transparency=1})
                        task.delay(0.7,function() if flash.Parent then flash:Destroy() end end)
                    end)
                end)
                ui:Label(button,entry.Title,12,UDim2.fromOffset(10,3),UDim2.new(1,-20,0,21))
                ui:Label(button,entry.Path,9,UDim2.fromOffset(10,24),UDim2.new(1,-20,0,16),ui.T.Muted)
                rows[#rows+1]={Button=button,Text=string.lower(entry.Title..' '..entry.Path)}
            end
            local empty=ui:Label(list,'No matching controls',12,nil,UDim2.new(1,0,0,32),ui.T.Muted)
            local function filter()
                local count=0; local q=string.lower(box.Text)
                for _,row in ipairs(rows) do row.Button.Visible=row.Text:find(q,1,true)~=nil; if row.Button.Visible then count=count+1 end end
                empty.Visible=count==0
            end
            box:GetPropertyChangedSignal('Text'):Connect(filter); filter()
            task.defer(function() if not runtime.Destroyed and box.Parent then box:CaptureFocus() end end)
        end
        app.SearchButton.Activated:Connect(function() app:Search() end)
        table.insert(input.Shortcuts,function(event,service)
            if event.KeyCode==Enum.KeyCode.K and (service:IsKeyDown(Enum.KeyCode.LeftControl) or service:IsKeyDown(Enum.KeyCode.RightControl)) then app:Search(); return true end
        end)
        for _,effect in ipairs({'Motion','Accent','Transparency','Scale'}) do
            local names={Motion='ReducedMotion',Accent='Accent',Transparency='Transparency',Scale='Scale'}
            app:ApplyEffect(effect,state:Get('Settings.Appearance.'..names[effect]))
        end
        app:SetLive('Server.Session.Place',game.PlaceId)
        local saved=state:Get('View.Page','About')
        app:SelectPage(app.Pages[saved] and saved or 'About')
        app.Adapter={Controls=app.Controls,SetLive=function(_,...) app:SetLive(...) end}
    end,debug.traceback)
    if not ok then runtime:Destroy(); error(err,0) end
    return app
end
