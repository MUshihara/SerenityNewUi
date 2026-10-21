return function(M,options)
    options=options or {}
    options.AssetBase=options.AssetBase or 'https://raw.githubusercontent.com/MUshihara/SerenityNewUi/77e5a1d2a4bc5e662bf52258a22b2976aedba1f8/prototype/assets/'
    options.DiscordInvite=options.DiscordInvite or 'https://discord.gg/ccsvkN7Pp'
    local sourceManifest=options.Manifest or M.Manifest
    local manifest={};for k,v in pairs(sourceManifest)do manifest[k]=v end
    manifest.Pages={};for _,page in ipairs(sourceManifest.Pages)do manifest.Pages[#manifest.Pages+1]=page end
    manifest.Pages[#manifest.Pages+1]={Id='Feedback',Title='Feedback',Description='Report a bug or share an idea',Icon='message-square',Features={},SharedPreview=true}
    assert(manifest.SerenityAPIVersion==3,'Expected V3 manifest')
    local runtime=M.Runtime.new()
    local defaults={['View.Page']='About',['View.LauncherX']=18,['View.LauncherY']=180}
    for _,page in ipairs(manifest.Pages) do
        defaults['View.Tab.'..page.Id]=(page.Tabs and page.Tabs[1].Id) or 'Main'
        for _,feature in ipairs(page.Features) do
            defaults['View.Section.'..page.Id..'.'..feature.Id]=feature.Expanded~=false
            for _,control in ipairs(feature.Controls) do
                if control.Default~=nil then defaults[(feature.ConfigPage or page.Id)..'.'..feature.Id..'.'..control.Id]=control.Default end
            end
        end
    end
    defaults['Settings.Appearance.LowEffects']=options.LowEffects==true or options.Mobile==true or game:GetService('UserInputService').TouchEnabled==true
    local state=M.State.new(defaults,runtime,options.ConfigPath)
    if options.Manifest then
        for _,page in ipairs(manifest.Pages) do
            if not page.SharedPreview then
                for _,feature in ipairs(page.Features) do
                    for _,control in ipairs(feature.Controls) do
                        if control.Default~=nil then state.Data[(feature.ConfigPage or page.Id)..'.'..feature.Id..'.'..control.Id]=control.Default end
                    end
                end
            end
        end
    end
    if options.LowEffects~=nil then state:Set('Settings.Appearance.LowEffects',options.LowEffects==true) end
    local ui=M.UI(M.Theme,runtime,M.Icons)
    local input=M.Input(runtime)
    ui.Touch=options.Mobile==true or input.Service.TouchEnabled==true
    ui.LowEffects=state:Get('Settings.Appearance.LowEffects',ui.Touch)==true
    if options.LowEffects~=nil then ui.LowEffects=options.LowEffects==true end
    local app
    local ok,err=xpcall(function()
        app=M.Renderer(ui,input,state,options,M.MobileLayout)
        local popup=M.Popup(ui,input,app.Screen,function() return app.Scale.Scale end)
        app.Popup=popup; app.Runtime=runtime; app.Config=state; app.Controls={}; app.Sections={}; app.Tabs={}; app.SearchEntries={}
        options.DiscordBytes=M.DiscordAsset
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
            elseif effect=='Motion' then ui.Reduced=value==true
            elseif effect=='LowEffects' then ui.LowEffects=value==true; popup:Close(true); self:Fit() end
        end
        function app:Notify(message)
            if self.Toast then self.Toast:Destroy() end
            local toast=ui:Panel(self.Screen,{AnchorPoint=Vector2.new(0.5,1),Position=UDim2.new(0.5,0,1,-14),Size=UDim2.new(0,280,0,44),ZIndex=150})
            ui:Icon(toast,'check',20,UDim2.fromOffset(12,12),ui.T.Accent)
            ui:Label(toast,message,12,UDim2.fromOffset(42,0),UDim2.new(1,-52,1,0))
            self.Toast=toast
            task.delay(2.5,function()
                if not runtime.Destroyed and self.Toast==toast then toast:Destroy(); self.Toast=nil end
            end)
        end
        function app:Copy(text,title)
            if type(setclipboard)=='function' then
                local good=pcall(setclipboard,text)
                if good then self:Notify((title or 'Value')..' copied'); return end
            end
            popup:Message(title or 'Copy this value','Select the value below and copy it manually.',text)
        end
        function app:Action(name)
            if name=='CopyPlace' then self:Copy(tostring(game.PlaceId),'Place ID')
            elseif name=='Search' then self:Search()
            elseif name=='Minimize' then self:SetVisible(false)
            elseif name=='Center' then self.Holder.Position=UDim2.fromScale(0.5,0.5); self:Fit()
            elseif name=='Save' then local saved=state:Save(); self:Notify(saved and 'Settings saved' or 'Session settings only')
            elseif name=='Reset' then
                local panel=popup:Open(nil,340,170)
                ui:Label(panel,'Reset preview settings?',15,UDim2.fromOffset(16,12),UDim2.new(1,-32,0,30),nil,true)
                ui:Label(panel,'Only this prototype’s settings will reset.',11,UDim2.fromOffset(16,48),UDim2.new(1,-32,0,35),ui.T.Muted)
                ui:Button(panel,'Cancel',{Position=UDim2.fromOffset(16,114),Size=UDim2.fromOffset(142,32)},function() popup:Close() end)
                ui:Button(panel,'Reset',{Position=UDim2.fromOffset(172,114),Size=UDim2.fromOffset(152,32),BackgroundColor3=ui.T.Accent},function()
                    popup:Close()
                    for key,control in pairs(self.Controls) do if defaults[key]~=nil and control.Set then control:Set(defaults[key],false) end end
                    state.Data={}
                    for key,value in pairs(defaults) do state.Data[key]=value end
                    self:FitLauncher()
                    self:SelectPage('About')
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
            return frame
        end
        for _,page in ipairs(manifest.Pages) do
            local pageFrame=app:AddPage(page)
            app.SearchEntries[#app.SearchEntries+1]={Title=page.Title,Path=page.Title,Page=page.Id,Target=pageFrame}
            if page.Id=='Feedback' then
                M.Feedback(ui,app,pageFrame,options,choice)
            elseif page.Id=='About' then
                local scroll=scroller(pageFrame,104)
                local player=game:GetService('Players').LocalPlayer
                local profile=ui:Panel(pageFrame,{Size=UDim2.new(1,0,0,94),LayoutOrder=-2})
                local avatar=ui:New('ImageLabel',profile,{BackgroundColor3=ui.T.Inset,BorderSizePixel=0,Image='rbxthumb://type=AvatarHeadShot&id='..tostring(player.UserId or 0)..'&w=150&h=150',Position=UDim2.fromOffset(12,14),Size=UDim2.fromOffset(52,52)})
                ui:Round(avatar,26)
                ui:Label(profile,player.DisplayName or 'Welcome',15,UDim2.fromOffset(76,12),UDim2.new(1,-88,0,24),nil,true)
                ui:Label(profile,'@'..(player.Name or 'Player'),11,UDim2.fromOffset(76,36),UDim2.new(1,-88,0,18),ui.T.Muted)
                local timer=ui:Label(profile,'Session · 00:00:00',11,UDim2.fromOffset(76,60),UDim2.new(1,-88,0,22),ui.T.Muted)
                local started=os.clock()
                local function tick()
                    if runtime.Destroyed then return end
                    if app.Visible and app.Current=='About' then
                        local seconds=math.floor(os.clock()-started)
                        timer.Text=string.format('Session · %02d:%02d:%02d',math.floor(seconds/3600),math.floor(seconds/60)%60,seconds%60)
                    end
                    task.delay(1,tick)
                end
                task.delay(1,tick)
                local section=M.Section(ui,scroll,'What’s new',false,function() popup:Close() end)
                controls.Paragraph(section.Body,{Title='RC1 · September 7, 2026',Text='Final Phonk test: shared feedback destination, movable launcher, saved UI preferences and mobile layout.',Height=80})
                local cards=ui:Frame(scroll,{Size=UDim2.new(1,0,0,280)})
                local community=card(cards,'Community',0,'Serenity Community','Meet the community','messages-square','Copy Discord Link',function() app:Copy(options.DiscordInvite,'Discord invite') end)
                local discord=ui:New('ImageLabel',community,{BackgroundTransparency=1,Position=UDim2.new(1,-36,0,7),Size=UDim2.fromOffset(24,24),Image=''})
                assets:Load('Discord',discord)
                local updates=card(cards,'Updates',0.5,'Release Notes','See the latest changes','megaphone','View Changelog',function()
                    popup:Message('Header update','• Full-width title bar and accent divider\n• Clearer sections and larger titles\n• Report character counter\n• Shared PC/mobile report destination\n\n'..(options.Manifest and 'Connected to the supplied game controls.' or 'Standalone UI demonstration.'))
                end)
                app.AboutCards={Container=cards,Community=community,Updates=updates}
                local function arrangeCards()
                    local narrow=app.LayoutWidth-app.SidebarWidth-32<460
                    cards.Size=UDim2.new(1,0,0,narrow and 572 or 280)
                    community.Size=UDim2.new(narrow and 1 or 0.5,narrow and 0 or -6,0,280)
                    updates.Size=community.Size
                    updates.Position=narrow and UDim2.fromOffset(0,292) or UDim2.new(0.5,6,0,0)
                end
                table.insert(ui.LayoutCallbacks,arrangeCards); arrangeCards()
            else
                local tabMap={}; local tabOrder=page.Tabs or {{Id='Main'}}
                local tabBar
                if page.Tabs then tabBar=ui:New('ScrollingFrame',pageFrame,{Size=UDim2.new(1,0,0,44),BackgroundTransparency=1,BorderSizePixel=0,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.X,ScrollingDirection=Enum.ScrollingDirection.X,ScrollBarThickness=0}); ui:List(tabBar,7,true) end
                local function selectTab(id)
                    if not tabMap[id] then return end
                    input:Cancel(); popup:Close(); state:Set('View.Tab.'..page.Id,id)
                    for key,tab in pairs(tabMap) do
                        tab.Scroll.Visible=key==id
                        if key==id then
                            tab.Scroll.Position=UDim2.fromOffset(ui.Reduced and 0 or 5,tabBar and 52 or 0)
                            ui:Tween(tab.Scroll,0.16,{Position=UDim2.fromOffset(0,tabBar and 52 or 0)})
                        end
                        if tab.Button then tab.Button.BackgroundColor3=key==id and ui.T.Accent or ui.T.Inset end
                    end
                end
                for _,spec in ipairs(tabOrder) do
                    local scroll=scroller(pageFrame,tabBar and 52 or 0)
                    local tab={Scroll=scroll}; tabMap[spec.Id]=tab
                    if tabBar then
                        local width=math.max(76,#spec.Id*8+42)
                        tab.Button=ui:Button(tabBar,'',{Size=UDim2.fromOffset(width,42)},function() selectTab(spec.Id) end)
                        ui:Stroke(tab.Button,nil,0.5)
                        ui:Icon(tab.Button,spec.Icon or 'menu',18,UDim2.fromOffset(10,12),ui.T.Text)
                        ui:Label(tab.Button,spec.Id,12,UDim2.fromOffset(34,0),UDim2.new(1,-39,1,0))
                    end
                end
                app.Tabs[page.Id]={Select=selectTab,Items=tabMap}
                ui:Accent(function(color)
                    for key,tab in pairs(tabMap) do if tab.Button then tab.Button.BackgroundColor3=key==state:Get('View.Tab.'..page.Id) and color or ui.T.Inset end end
                end)
                for _,feature in ipairs(page.Features) do
                    local tabId=feature.Tab or 'Main'; local scroll=assert(tabMap[tabId],'Missing sub-tab').Scroll
                    local sectionKey=(feature.ConfigPage or page.Id)..'.'..feature.Id
                    local section=M.Section(ui,scroll,feature.Title,state:Get('View.Section.'..sectionKey,feature.Expanded~=false),function(open)
                        input:Cancel(); popup:Close(); state:Set('View.Section.'..sectionKey,open)
                    end)
                    app.Sections[sectionKey]=section
                    for _,spec in ipairs(feature.Controls) do
                        local key=sectionKey..'.'..spec.Id
                        local props={}; for k,v in pairs(spec) do props[k]=v end
                        if spec.Default~=nil then props.Default=state:Get(key,spec.Default) end
                        props.Callback=function(value)
                            if spec.Type=='Action' then
                                if spec.Callback then spec.Callback(app,app.Adapter) else app:Action(spec.Action) end
                            else
                                state:Set(key,value)
                                if spec.Changed then spec.Changed(value,app,app.Adapter) end
                                if spec.Effect then app:ApplyEffect(spec.Effect,value) end
                            end
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
            local function fitSearch()
                if runtime.Destroyed or popup.Panel~=panel then return end
                ui.R:CancelTween(panel)
                if panel:IsA('CanvasGroup') then panel.GroupTransparency=0 end
                local view=self.Screen.AbsoluteSize
                local available=view.Y
                pcall(function()
                    if input.Service.OnScreenKeyboardVisible then
                        available=math.max(120,view.Y-input.Service.OnScreenKeyboardSize.Y)
                    end
                end)
                local scale=math.min(1,(view.X-20)/430)
                panel.Size=UDim2.fromOffset(430,math.max(115,math.min(350,(available-16)/scale)))
                panel.Position=UDim2.fromOffset((view.X-430*scale)/2,8)
                for _,child in ipairs(panel:GetChildren()) do if child:IsA('UIScale') then child.Scale=scale end end
            end
            if ui.Touch then
                fitSearch()
                local connections={}
                for _,property in ipairs({'OnScreenKeyboardVisible','OnScreenKeyboardSize'}) do
                    local ok,connection=pcall(function() return input.Service:GetPropertyChangedSignal(property):Connect(fitSearch) end)
                    if ok then connections[#connections+1]=connection end
                end
                popup.OnClose=function() for _,connection in ipairs(connections) do connection:Disconnect() end end
            end
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
                            local y=(entry.Target.AbsolutePosition.Y-entry.Scroll.AbsolutePosition.Y)/math.max(0.2,ui.ScaleFactor)+entry.Scroll.CanvasPosition.Y-7
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
        for _,effect in ipairs({'Motion','Accent','Transparency','Scale','LowEffects'}) do
            local names={Motion='ReducedMotion',Accent='Accent',Transparency='Transparency',Scale='Scale',LowEffects='LowEffects'}
            app:ApplyEffect(effect,state:Get('Settings.Appearance.'..names[effect]))
        end
        app:SetLive('Server.Session.Place',game.PlaceId)
        local saved=state:Get('View.Page','About')
        app:SelectPage(app.Pages[saved] and saved or 'About')
        app:SetVisible(not state:Get('Settings.Interface.StartMinimized',false))
        app.Adapter={Controls=app.Controls,SetLive=function(_,...) app:SetLive(...) end}
    end,debug.traceback)
    if not ok then runtime:Destroy(); error(err,0) end
    return app
end
