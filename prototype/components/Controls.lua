return function(ui,input,popup)
    local Controls={}
    local function emit(self,silent)
        if not silent and self.Callback then self.Callback(self:Get()) end
    end
    function Controls.Switch(parent,props)
        local row,label=ui:Row(parent,props.Title)
        local track=ui:Frame(row,{Size=UDim2.fromOffset(42,24),Position=UDim2.new(1,-54,0.5,-12),BackgroundTransparency=0})
        ui:Round(track,12)
        local dot=ui:Frame(track,{Size=UDim2.fromOffset(18,18),BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=0})
        ui:Round(dot,10)
        local control={Frame=row,Value=props.Default==true,Enabled=props.Enabled~=false,Callback=props.Callback}
        function control:Get() return self.Value end
        function control:Render(animate)
            track.BackgroundColor3=self.Value and ui.T.Accent or Color3.fromRGB(57,57,68)
            label.TextColor3=self.Enabled and ui.T.Text or ui.T.Dim
            dot.BackgroundTransparency=self.Enabled and 0 or 0.5
            ui:Tween(dot,animate and 0.12 or 0,{Position=UDim2.fromOffset(self.Value and 21 or 3,3)})
        end
        function control:Set(value,silent)
            local old=self.Value; self.Value=value==true; self:Render(true)
            if old~=self.Value then emit(self,silent) end
        end
        function control:SetEnabled(value) self.Enabled=value==true; self:Render(false) end
        ui:Button(row,'',{Size=UDim2.fromScale(1,1),BackgroundTransparency=1},function() if control.Enabled then control:Set(not control.Value) end end)
        ui:Accent(function() control:Render(false) end)
        return control
    end
    function Controls.Slider(parent,props)
        local row,label=ui:Row(parent,props.Title,62)
        label.Size=UDim2.new(0.65,0,0,30)
        local box=ui:New('TextBox',row,{Position=UDim2.new(1,-81,0,2),Size=UDim2.fromOffset(69,27),Text='',ClearTextOnFocus=false,
            Font=ui.T.Medium,TextSize=12,TextColor3=ui.T.Accent,TextXAlignment=Enum.TextXAlignment.Right,BackgroundTransparency=1})
        local bar=ui:Frame(row,{Position=UDim2.fromOffset(12,43),Size=UDim2.new(1,-24,0,5),BackgroundColor3=Color3.fromRGB(42,42,51),BackgroundTransparency=0})
        ui:Round(bar,4)
        local fill=ui:Frame(bar,{Size=UDim2.fromScale(0,1),BackgroundTransparency=0}); ui:Round(fill,4)
        local dot=ui:Frame(bar,{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0,0.5),Size=UDim2.fromOffset(14,14),BackgroundColor3=ui.T.Text,BackgroundTransparency=0}); ui:Round(dot,8)
        local hit=ui:Button(row,'',{Position=UDim2.fromOffset(6,31),Size=UDim2.new(1,-12,0,28),BackgroundTransparency=1})
        local min,max,step=props.Min or 0,props.Max or 100,props.Step or 1
        assert(max>min and step>0,'Invalid slider bounds')
        local control={Frame=row,Value=min,Enabled=props.Enabled~=false,Callback=props.Callback}
        function control:Get() return self.Value end
        function control:Render()
            local a=(self.Value-min)/(max-min); fill.Size=UDim2.fromScale(a,1); dot.Position=UDim2.fromScale(a,0.5)
            box.Text=string.format('%.4f',self.Value):gsub('0+$',''):gsub('%.$','')..(props.Suffix or '')
            label.TextColor3=self.Enabled and ui.T.Text or ui.T.Dim
        end
        function control:Set(value,silent)
            value=tonumber(value); if not value or value~=value or math.abs(value)==math.huge then self:Render(); return end
            value=math.clamp(min+math.floor((value-min)/step+0.5)*step,min,max)
            local old=self.Value; self.Value=value; self:Render(); if old~=value then emit(self,silent) end
        end
        function control:SetEnabled(value) self.Enabled=value==true; box.TextEditable=self.Enabled; self:Render() end
        ui.R:Connect(hit.InputBegan,function(event)
            if control.Enabled and (event.UserInputType==Enum.UserInputType.MouseButton1 or event.UserInputType==Enum.UserInputType.Touch) then
                input:Cancel()
                local ancestor=row.Parent
                while ancestor and not ancestor:IsA('ScrollingFrame') do ancestor=ancestor.Parent end
                local scrollEnabled=ancestor and ancestor.ScrollingEnabled
                if ancestor then ancestor.ScrollingEnabled=false end
                input:Capture(event,function(pos)
                    local a=math.clamp((pos.X-bar.AbsolutePosition.X)/math.max(1,bar.AbsoluteSize.X),0,1)
                    control:Set(min+a*(max-min))
                end,function() if ancestor and ancestor.Parent then ancestor.ScrollingEnabled=scrollEnabled end end)
            end
        end)
        ui.R:Connect(box.FocusLost,function() if control.Enabled then control:Set(box.Text:match('[-+]?%d*%.?%d+')) else control:Render() end end)
        ui:Accent(function(color) fill.BackgroundColor3=color; box.TextColor3=color end)
        control:Set(props.Default or min,true)
        return control
    end
    function Controls.Input(parent,props)
        local row,label=ui:Row(parent,props.Title,68); label.Size=UDim2.new(1,-24,0,28)
        local box=ui:New('TextBox',row,{Position=UDim2.fromOffset(12,30),Size=UDim2.new(1,-24,0,28),Text='',PlaceholderText=props.Placeholder or '',
            PlaceholderColor3=ui.T.Dim,TextColor3=ui.T.Text,Font=ui.T.Medium,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,
            ClearTextOnFocus=false,BackgroundColor3=ui.T.Inset,BorderSizePixel=0}); ui:Round(box,6); ui:Pad(box,8,0,8,0)
        local control={Frame=row,Value='',Enabled=props.Enabled~=false,Callback=props.Callback}
        function control:Get() return self.Value end
        function control:Set(value,silent)
            value=tostring(value or ''):sub(1,512); local old=self.Value; self.Value=value; box.Text=value
            if old~=value then emit(self,silent) end
        end
        function control:SetEnabled(value) self.Enabled=value==true; box.TextEditable=self.Enabled end
        ui.R:Connect(box.FocusLost,function() if control.Enabled then control:Set(box.Text) end end)
        control:Set(props.Default,true); return control
    end
    function Controls.Action(parent,props)
        local row,label=ui:Row(parent,props.Title,42); label.Size=UDim2.new(1,-45,1,0)
        ui:Icon(row,props.Icon or 'chevron-right',15,UDim2.new(1,-28,0.5,-7.5))
        local control={Frame=row,Enabled=props.Enabled~=false,Busy=false}
        function control:SetEnabled(value) self.Enabled=value==true; label.TextColor3=self.Enabled and ui.T.Text or ui.T.Dim end
        ui:Button(row,'',{Size=UDim2.fromScale(1,1),BackgroundTransparency=1},function()
            if not control.Enabled or control.Busy then return end
            control.Busy=true
            local ok,err=pcall(function() if props.Callback then props.Callback() end end)
            control.Busy=false
            if not ok then popup:Message('Action unavailable',tostring(err)) end
        end)
        return control
    end
    function Controls.Paragraph(parent,props)
        local row=ui:Frame(parent,{Size=UDim2.new(1,0,0,props.Height or 76)})
        local panel=ui:Panel(row,{Position=UDim2.fromOffset(10,6),Size=UDim2.new(1,-20,1,-12),BackgroundColor3=Color3.fromRGB(22,40,52)})
        ui:Icon(panel,'info',16,UDim2.fromOffset(10,11),ui.T.Blue)
        ui:Label(panel,props.Title or 'Information',11,UDim2.fromOffset(34,7),UDim2.new(1,-44,0,20))
        local text=ui:Label(panel,props.Text or '',10,UDim2.fromOffset(34,28),UDim2.new(1,-44,1,-31),Color3.fromRGB(167,196,214))
        text.TextWrapped=true; text.TextTruncate=Enum.TextTruncate.None; text.TextYAlignment=Enum.TextYAlignment.Top
        return {Frame=row}
    end
    function Controls.Live(parent,props)
        local row,label=ui:Row(parent,props.Title)
        local value=ui:Label(row,tostring(props.Default or '--'),12,UDim2.new(0.5,0,0,0),UDim2.new(0.5,-12,1,0),ui.T.Muted); value.TextXAlignment=Enum.TextXAlignment.Right
        return {Frame=row,Set=function(_,v) value.Text=tostring(v) end}
    end
    function Controls.Progress(parent,props)
        local row=ui:Frame(parent,{Size=UDim2.new(1,0,0,53)})
        ui:Label(row,props.Title,12,UDim2.fromOffset(12,0),UDim2.new(1,-80,0,30))
        local value=ui:Label(row,'',11,UDim2.new(1,-70,0,0),UDim2.fromOffset(58,30),ui.T.Muted); value.TextXAlignment=Enum.TextXAlignment.Right
        local bar=ui:Frame(row,{Position=UDim2.fromOffset(12,37),Size=UDim2.new(1,-24,0,5),BackgroundColor3=ui.T.Inset,BackgroundTransparency=0}); ui:Round(bar,4)
        local fill=ui:Frame(bar,{Size=UDim2.fromScale(0,1),BackgroundTransparency=0}); ui:Round(fill,4); ui:Accent(function(c) fill.BackgroundColor3=c end)
        local api={Frame=row}
        function api:Set(v)
            local min,max=props.Min or 0,props.Max or 100
            local n=math.clamp(tonumber(v) or min,min,max)
            fill.Size=UDim2.fromScale((n-min)/math.max(1,max-min),1); value.Text=tostring(n)..(props.Suffix or '%')
        end
        api:Set(props.Default or 0); return api
    end
    return Controls
end
