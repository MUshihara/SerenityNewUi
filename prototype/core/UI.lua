return function(theme, runtime, icons)
    local UI={T=theme,R=runtime,AccentBindings={},Reduced=false}
    function UI:New(kind,parent,props)
        local object=Instance.new(kind)
        for key,value in pairs(props or {}) do object[key]=value end
        object.Parent=parent; return object
    end
    function UI:Frame(parent,props)
        local f=self:New('Frame',parent,{BorderSizePixel=0,BackgroundTransparency=1})
        for k,v in pairs(props or {}) do f[k]=v end; return f
    end
    function UI:Round(parent,radius) return self:New('UICorner',parent,{CornerRadius=UDim.new(0,radius or 8)}) end
    function UI:Stroke(parent,color,transparency)
        return self:New('UIStroke',parent,{Color=color or theme.Line,Thickness=1,Transparency=transparency or 0.3,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
    end
    function UI:Panel(parent,props)
        local f=self:Frame(parent,{BackgroundColor3=theme.Panel,BackgroundTransparency=0})
        for k,v in pairs(props or {}) do f[k]=v end
        self:Round(f,10); self:Stroke(f); return f
    end
    function UI:Label(parent,text,size,pos,dimensions,color,bold)
        return self:New('TextLabel',parent,{Text=text,Font=bold and theme.Bold or theme.Medium,TextSize=size or 13,
            TextColor3=color or theme.Text,BackgroundTransparency=1,Position=pos or UDim2.new(),Size=dimensions or UDim2.fromScale(1,1),
            TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd})
    end
    function UI:Icon(parent,name,size,pos,color)
        return self:New('ImageLabel',parent,{BackgroundTransparency=1,Image=icons.Resolve(name),ImageColor3=color or theme.Muted,
            ScaleType=Enum.ScaleType.Fit,Size=UDim2.fromOffset(size or 16,size or 16),Position=pos or UDim2.new()})
    end
    function UI:Button(parent,text,props,callback)
        local b=self:New('TextButton',parent,{Text=text or '',Font=theme.Medium,TextSize=12,TextColor3=theme.Text,
            BorderSizePixel=0,AutoButtonColor=false,BackgroundColor3=theme.Inset,Size=UDim2.fromOffset(100,30)})
        for k,v in pairs(props or {}) do b[k]=v end
        self:Round(b,7)
        if callback then b.Activated:Connect(function() if not runtime.Destroyed then callback() end end) end
        return b
    end
    function UI:List(parent,gap,horizontal)
        return self:New('UIListLayout',parent,{Padding=UDim.new(0,gap or 0),SortOrder=Enum.SortOrder.LayoutOrder,
            FillDirection=horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical})
    end
    function UI:Pad(parent,left,top,right,bottom)
        self:New('UIPadding',parent,{PaddingLeft=UDim.new(0,left),PaddingTop=UDim.new(0,top or left),
            PaddingRight=UDim.new(0,right or left),PaddingBottom=UDim.new(0,bottom or top or left)})
    end
    function UI:Accent(callback)
        self.AccentBindings[#self.AccentBindings+1]=callback; callback(theme.Accent)
    end
    function UI:SetAccent(color)
        theme.Accent=color
        for _,fn in ipairs(self.AccentBindings) do fn(color) end
    end
    function UI:Tween(object,time,props) return runtime:Tween(object,time,props,self.Reduced) end
    function UI:Row(parent,title,height)
        local row=self:Frame(parent,{Size=UDim2.new(1,0,0,height or 40)})
        local label=self:Label(row,title,12,UDim2.fromOffset(12,0),UDim2.new(0.5,-18,1,0))
        self:Frame(row,{Position=UDim2.new(0,12,1,-1),Size=UDim2.new(1,-24,0,1),BackgroundColor3=theme.Line,BackgroundTransparency=0.65})
        return row,label
    end
    return UI
end
