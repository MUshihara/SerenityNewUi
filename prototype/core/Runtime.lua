local Runtime = {}
Runtime.__index = Runtime
function Runtime.new()
    return setmetatable({Destroyed=false, Cleanups={}, Tweens={}}, Runtime)
end
function Runtime:Own(value)
    if self.Destroyed then
        pcall(function() if typeof(value)=='RBXScriptConnection' then value:Disconnect() else value:Destroy() end end)
        return value
    end
    self.Cleanups[#self.Cleanups+1] = function()
        if typeof(value)=='RBXScriptConnection' then value:Disconnect() else value:Destroy() end
    end
    return value
end
function Runtime:OnDestroy(callback) self.Cleanups[#self.Cleanups+1]=callback end
function Runtime:Connect(signal, callback)
    return self:Own(signal:Connect(function(...) if not self.Destroyed then callback(...) end end))
end
function Runtime:Tween(object, seconds, properties, reduced)
    if self.Destroyed then return end
    if self.Tweens[object] then self.Tweens[object]:Cancel(); self.Tweens[object]=nil end
    if reduced or seconds==0 then
        for k,v in pairs(properties) do object[k]=v end
        return
    end
    local tween=game:GetService('TweenService'):Create(object,TweenInfo.new(seconds,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),properties)
    self.Tweens[object]=tween
    tween:Play()
    task.delay(seconds+0.05,function() if self.Tweens[object]==tween then self.Tweens[object]=nil end end)
    return tween
end
function Runtime:Destroy()
    if self.Destroyed then return end
    self.Destroyed=true
    for _,t in pairs(self.Tweens) do pcall(function() t:Cancel() end) end
    self.Tweens={}
    for i=#self.Cleanups,1,-1 do pcall(self.Cleanups[i]) end
    self.Cleanups={}
end
return Runtime
