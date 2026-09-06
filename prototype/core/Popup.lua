return function(ui,input,screen,getScale)
    local Popup={Active=nil,Owner=nil}
    function Popup:Close()
        local focused=input.Service:GetFocusedTextBox()
        if focused and self.Active and focused:IsDescendantOf(self.Active) then focused:ReleaseFocus() end
        if self.Active then self.Active:Destroy() end
        self.Active=nil; self.Owner=nil
    end
    function Popup:Open(owner,width,height,anchor)
        self:Close(); input:Cancel()
        local root=ui:Frame(screen,{Size=UDim2.fromScale(1,1),ZIndex=100})
        self.Active=root; self.Owner=owner
        local shield=ui:Button(root,'',{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ZIndex=1},function() self:Close() end)
        local view=screen.AbsoluteSize
        local scale=math.min(getScale(),(view.X-20)/width,(view.Y-20)/height)
        scale=math.max(0.2,scale)
        local x,y=(view.X-width*scale)/2,(view.Y-height*scale)/2
        if anchor then
            x=anchor.AbsolutePosition.X+anchor.AbsoluteSize.X-width*scale
            y=anchor.AbsolutePosition.Y+anchor.AbsoluteSize.Y+5
            if y+height*scale>view.Y-10 then y=anchor.AbsolutePosition.Y-height*scale-5 end
        end
        x=math.clamp(x,10,math.max(10,view.X-width*scale-10))
        y=math.clamp(y,10,math.max(10,view.Y-height*scale-10))
        local panel=ui:Panel(root,{Size=UDim2.fromOffset(width,height),Position=UDim2.fromOffset(x,y),ZIndex=2,Active=true})
        ui:New('UIScale',panel,{Scale=scale})
        panel.BackgroundColor3=Color3.fromRGB(19,19,24)
        return panel
    end
    function Popup:Message(title,message,link)
        local panel=self:Open(nil,380,link and 236 or 210)
        ui:Label(panel,title,16,UDim2.fromOffset(18,14),UDim2.new(1,-36,0,28),nil,true)
        local body=ui:Label(panel,message,12,UDim2.fromOffset(18,51),UDim2.new(1,-36,0,100),ui.T.Muted)
        body.TextWrapped=true; body.TextTruncate=Enum.TextTruncate.None; body.TextYAlignment=Enum.TextYAlignment.Top
        if link then
            local box=ui:New('TextBox',panel,{Position=UDim2.fromOffset(18,148),Size=UDim2.new(1,-36,0,30),Text=link,ClearTextOnFocus=false,
                TextSize=11,Font=ui.T.Font,TextColor3=ui.T.Text,BackgroundColor3=ui.T.Inset,BorderSizePixel=0})
            ui:Round(box,6)
        end
        ui:Button(panel,'Close',{AnchorPoint=Vector2.new(1,1),Position=UDim2.new(1,-18,1,-16),Size=UDim2.fromOffset(80,30)},function() self:Close() end)
    end
    ui.R:OnDestroy(function() Popup:Close() end)
    table.insert(input.Shortcuts,function(event) if event.KeyCode==Enum.KeyCode.Escape and Popup.Active then Popup:Close(); return true end end)
    return Popup
end
