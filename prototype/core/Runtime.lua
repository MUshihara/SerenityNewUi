local Runtime = {}
Runtime.__index = Runtime
function Runtime.new()
    return setmetatable({Destroyed=false, Cleanups={}, Tweens={}, TweenConnections={}}, Runtime)
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
function Runtime:CancelTween(object)
    local connection=self.TweenConnections[object]
    if connection then connection:Disconnect(); self.TweenConnections[object]=nil end
    if self.Tweens[object] then self.Tweens[object]:Cancel(); self.Tweens[object]=nil end
end
function Runtime:Tween(object, seconds, properties, reduced, completed)
    if self.Destroyed then return end
    self:CancelTween(object)
    if reduced or seconds==0 then
        for k,v in pairs(properties) do object[k]=v end
        if completed then completed() end
        return
    end
    local tween=game:GetService('TweenService'):Create(object,TweenInfo.new(seconds,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),properties)
    self.Tweens[object]=tween
    self.TweenConnections[object]=tween.Completed:Connect(function(status)
        if self.Tweens[object]~=tween then return end
        self.TweenConnections[object]:Disconnect(); self.TweenConnections[object]=nil
        self.Tweens[object]=nil
        if status==Enum.PlaybackState.Completed and not self.Destroyed and completed then completed() end
    end)
    tween:Play()
    return tween
end
function Runtime:Destroy()
    if self.Destroyed then return end
    self.Destroyed=true
    for _,c in pairs(self.TweenConnections) do c:Disconnect() end
    self.TweenConnections={}
    for _,t in pairs(self.Tweens) do pcall(function() t:Cancel() end) end
    self.Tweens={}
    for i=#self.Cleanups,1,-1 do pcall(self.Cleanups[i]) end
    self.Cleanups={}
end
return Runtime
