return function(ui,input,screen,getScale)
    local Popup={Active=nil,Owner=nil,Closing=nil,Panel=nil}
    function Popup:Discard(root)
        if not root then return end
        local function cancel(object)
            ui.R:CancelTween(object)
            for _,child in ipairs(object:GetChildren()) do cancel(child) end
        end
        cancel(root)
        root:Destroy()
    end
    function Popup:Close(instant)
        self:Discard(self.Closing); self.Closing=nil
        local root,panel=self.Active,self.Panel
        local focused=input.Service:GetFocusedTextBox()
        if focused and root and focused:IsDescendantOf(root) then focused:ReleaseFocus() end
        self.Active=nil; self.Owner=nil; self.Panel=nil
        if not root then return end
        if instant or ui.R.Destroyed or ui.Reduced then self:Discard(root); return end
        self.Closing=root
        ui:Tween(panel,0.12,{GroupTransparency=1},function()
            if self.Closing==root then self.Closing=nil; self:Discard(root) end
        end)
    end
    function Popup:Open(owner,width,height,anchor)
        self:Close(true); input:Cancel()
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
        local panel=ui:New('CanvasGroup',root,{BackgroundTransparency=0,BorderSizePixel=0,GroupTransparency=ui.Reduced and 0 or 1,Size=UDim2.fromOffset(width,height),Position=UDim2.fromOffset(x,y),ZIndex=2,Active=true})
        ui:New('UIScale',panel,{Scale=scale})
        panel.BackgroundColor3=Color3.fromRGB(19,19,24)
        ui:Round(panel,10)
        self.Panel=panel
        panel.Position=UDim2.fromOffset(x,y+(ui.Reduced and 0 or 6))
        ui:Tween(panel,0.16,{GroupTransparency=0,Position=UDim2.fromOffset(x,y)})
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
