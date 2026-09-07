return function(ui,popup)
    return function(parent,props,multiple)
        local row,label=ui:Row(parent,props.Title,42)
        local button=ui:Button(row,'',{Position=UDim2.new(0.5,0,0.5,-22),Size=UDim2.new(0.5,-12,0,44)})
        ui:Stroke(button,nil,0.65)
        local summary=ui:Label(button,'',11,UDim2.fromOffset(9,0),UDim2.new(1,-31,1,0),ui.T.Muted)
        ui:Icon(button,'chevron-down',18,UDim2.new(1,-26,0.5,-9))
        local self={Frame=row,Enabled=props.Enabled~=false,Options=props.Options or {},Value=multiple and {} or nil,Callback=props.Callback}
        local function same(a,b)
            if type(a)~='table' then return a==b end
            if type(b)~='table' or #a~=#b then return false end
            for i,v in ipairs(a) do if b[i]~=v then return false end end
            return true
        end
        function self:Get()
            if not multiple then return self.Value end
            local out={}; for i,v in ipairs(self.Value) do out[i]=v end; return out
        end
        function self:Render()
            if multiple then summary.Text=#self.Value==0 and 'None selected' or (#self.Value==1 and self.Value[1] or tostring(#self.Value)..' selected')
            else summary.Text=self.Value or 'No options' end
            label.TextColor3=self.Enabled and ui.T.Text or ui.T.Dim
            button.BackgroundTransparency=self.Enabled and 0 or 0.5
        end
        function self:Set(value,silent)
            local normalized
            if multiple then
                local requested={}
                if type(value)=='table' then for k,v in pairs(value) do if type(k)=='number' then requested[v]=true elseif v==true then requested[k]=true end end end
                normalized={}; for _,option in ipairs(self.Options) do if requested[option] then normalized[#normalized+1]=option end end
            else
                for _,option in ipairs(self.Options) do if option==value then normalized=option; break end end
                if not normalized then normalized=self.Options[1] end
            end
            local changed=not same(self.Value,normalized); self.Value=normalized; self:Render()
            if changed and not silent and self.Callback then self.Callback(self:Get()) end
        end
        function self:SetEnabled(value)
            self.Enabled=value==true; if not self.Enabled and popup.Owner==self then popup:Close() end; self:Render()
        end
        local function open()
            if not self.Enabled then return end
            if popup.Owner==self then popup:Close(); return end
            local panel=popup:Open(self,270,320,button)
            ui:Label(panel,props.Title,13,UDim2.fromOffset(12,8),UDim2.new(1,-45,0,24),nil,true)
            ui:Button(panel,'',{Position=UDim2.new(1,-34,0,7),Size=UDim2.fromOffset(26,26),BackgroundTransparency=1},function() popup:Close() end)
            ui:Icon(panel,'x',12,UDim2.new(1,-27,0,14))
            local search=ui:New('TextBox',panel,{Text='',PlaceholderText='Search options...',ClearTextOnFocus=false,Font=ui.T.Font,TextSize=12,
                TextColor3=ui.T.Text,PlaceholderColor3=ui.T.Dim,TextXAlignment=Enum.TextXAlignment.Left,BackgroundColor3=ui.T.Inset,BorderSizePixel=0,
                Position=UDim2.fromOffset(12,40),Size=UDim2.new(1,-24,0,30)}); ui:Round(search,6); ui:Pad(search,9,0,9,0)
            local top=80
            if multiple then
                ui:Button(panel,'Select all',{Position=UDim2.fromOffset(12,78),Size=UDim2.fromOffset(119,27)},function() self:Set(self.Options); popup:Close() end)
                ui:Button(panel,'Clear',{Position=UDim2.fromOffset(139,78),Size=UDim2.fromOffset(119,27)},function() self:Set({}); popup:Close() end)
                top=113
            end
            local scroll=ui:New('ScrollingFrame',panel,{BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromOffset(10,top),Size=UDim2.new(1,-20,1,-top-10),
                CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=2,ScrollBarImageColor3=ui.T.Accent})
            ui:List(scroll,3)
            local rows={}
            for _,option in ipairs(self.Options) do
                local function selected()
                    if not multiple then return self.Value==option end
                    for _,v in ipairs(self.Value) do if v==option then return true end end
                    return false
                end
                local item=ui:Button(scroll,'',{Size=UDim2.new(1,-4,0,44)})
                local tick=ui:Icon(item,'check',13,UDim2.fromOffset(9,9),ui.T.Accent)
                ui:Label(item,option,11,UDim2.fromOffset(30,0),UDim2.new(1,-38,1,0))
                local function render() tick.Visible=selected(); item.BackgroundTransparency=selected() and 0 or 0.65 end
                render(); rows[#rows+1]={Button=item,Text=string.lower(option)}
                item.Activated:Connect(function()
                    if ui.R.Destroyed then return end
                    if multiple then
                        local values=self:Get(); local nextValues={}; local existed=selected()
                        for _,v in ipairs(values) do if v~=option then nextValues[#nextValues+1]=v end end
                        if not existed then nextValues[#nextValues+1]=option end
                        self:Set(nextValues); render()
                    else self:Set(option); popup:Close() end
                end)
            end
            local empty=ui:Label(scroll,'No matching options',11,nil,UDim2.new(1,-12,0,30),ui.T.Dim)
            local function filter()
                local n=0; local q=string.lower(search.Text)
                for _,r in ipairs(rows) do r.Button.Visible=r.Text:find(q,1,true)~=nil; if r.Button.Visible then n=n+1 end end
                empty.Visible=n==0
            end
            search:GetPropertyChangedSignal('Text'):Connect(filter); filter()
        end
        function self:Refresh(options,preserve)
            local wasOpen=popup.Owner==self
            if wasOpen then popup:Close() end
            self.Options=options or {}
            self:Set(preserve~=false and self:Get() or (multiple and {} or self.Options[1]),false)
            if wasOpen then open() end
        end
        button.Activated:Connect(open)
        self:Set(props.Default,true); return self
    end
end
