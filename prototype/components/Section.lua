return function(ui,parent,title,open,onOpen)
    local root=ui:Panel(parent,{Size=UDim2.new(1,0,0,34),ClipsDescendants=true})
    local head=ui:Button(root,'',{Size=UDim2.new(1,0,0,34),BackgroundTransparency=1})
    ui:Label(head,string.upper(title),10,UDim2.fromOffset(12,0),UDim2.new(1,-45,1,0),ui.T.Muted)
    local caret=ui:Icon(head,'chevron-down',13,UDim2.new(1,-26,0,10))
    local body=ui:Frame(root,{Position=UDim2.fromOffset(0,34),Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y})
    local list=ui:List(body,0)
    local section={Frame=root,Body=body,Open=open~=false,Revision=0}
    local function size(animate)
        ui:Tween(caret,animate and 0.18 or 0,{Rotation=section.Open and 180 or 0})
        local target=34+(section.Open and (list.AbsoluteContentSize.Y+5) or 0)
        ui:Tween(root,animate and 0.18 or 0,{Size=UDim2.new(1,0,0,target)})
    end
    function section:SetOpen(value,instant)
        self.Open=value==true; size(not instant)
        if onOpen then onOpen(self.Open) end
    end
    ui.R:Connect(head.Activated,function() section:SetOpen(not section.Open) end)
    ui.R:Connect(list:GetPropertyChangedSignal('AbsoluteContentSize'),function() size(false) end)
    size(false)
    return section
end
