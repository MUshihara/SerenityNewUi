-- Prototype-only settings. Never reads/writes production Serenity config.
local State={}; State.__index=State
local function copy(v)
    if type(v)~='table' then return v end
    local out={}; for k,x in pairs(v) do out[k]=copy(x) end; return out
end
function State.new(defaults, runtime, path)
    local self=setmetatable({Data=copy(defaults), Defaults=copy(defaults), Runtime=runtime, Revision=0,
        Path=path or 'SerenityConcept02/settings-v1.json', FileAPI=type(readfile)=='function' and type(writefile)=='function' and type(isfile)=='function'},State)
    if self.FileAPI then
        local ok,decoded=pcall(function()
            if isfile(self.Path) then return game:GetService('HttpService'):JSONDecode(readfile(self.Path)) end
        end)
        if ok and type(decoded)=='table' and decoded.Schema==1 and type(decoded.Values)=='table' then
            for key,default in pairs(defaults) do
                if type(decoded.Values[key])==type(default) then self.Data[key]=copy(decoded.Values[key]) end
            end
        end
    end
    runtime:OnDestroy(function() self:Save() end)
    return self
end
function State:Get(key, fallback)
    if self.Data[key]==nil then return copy(fallback) end
    return copy(self.Data[key])
end
function State:Set(key,value)
    self.Data[key]=copy(value); self.Revision=self.Revision+1
    local revision=self.Revision
    task.delay(0.55,function() if not self.Runtime.Destroyed and revision==self.Revision then self:Save() end end)
end
function State:Save()
    if not self.FileAPI then return false end
    return pcall(function()
        if type(makefolder)=='function' then pcall(makefolder,'SerenityConcept02') end
        writefile(self.Path,game:GetService('HttpService'):JSONEncode({Schema=1,Values=self.Data}))
    end)
end
return State
