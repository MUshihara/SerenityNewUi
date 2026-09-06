return function(runtime)
    local service=game:GetService('UserInputService')
    local input={Drag=nil,Shortcuts={},Service=service}
    function input:Cancel() self.Drag=nil end
    function input:Capture(source,onMove,onEnd)
        self.Drag={Source=source,Move=onMove,Finish=onEnd}; onMove(source.Position)
    end
    runtime:Connect(service.InputChanged,function(event)
        local drag=input.Drag
        if drag and (event==drag.Source or (drag.Source.UserInputType==Enum.UserInputType.MouseButton1 and event.UserInputType==Enum.UserInputType.MouseMovement)) then drag.Move(event.Position) end
    end)
    runtime:Connect(service.InputEnded,function(event)
        local drag=input.Drag
        if drag and (event==drag.Source or (drag.Source.UserInputType==Enum.UserInputType.MouseButton1 and event.UserInputType==Enum.UserInputType.MouseButton1)) then
            input.Drag=nil; if drag.Finish then drag.Finish() end
        end
    end)
    runtime:Connect(service.InputBegan,function(event,processed)
        if (processed or service:GetFocusedTextBox()) and event.KeyCode~=Enum.KeyCode.Escape then return end
        for _,fn in ipairs(input.Shortcuts) do if fn(event,service) then break end end
    end)
    return input
end
