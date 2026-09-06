-- Finite contract tests. No HTTP, real filesystem, or Roblox side effects.
local function copy(v)
    if type(v)~='table' then return v end
    local o={}; for k,x in pairs(v) do o[k]=copy(x) end; return o
end
math.clamp=function(v,lo,hi) assert(lo<=hi,'invalid clamp range'); return math.max(lo,math.min(hi,v)) end
Enum=setmetatable({Font={Gotham='Gotham',GothamMedium='GothamMedium',GothamBold='GothamBold'}},{__index=function(t,k)
    local values=setmetatable({},{__index=function(a,b) rawset(a,b,k..'.'..b);return rawget(a,b) end});rawset(t,k,values);return values
end})
Color3={fromRGB=function(r,g,b) return {R=r/255,G=g/255,B=b/255} end,new=function(r,g,b)return{R=r,G=g,B=b}end}
Vector2={new=function(x,y) return {X=x,Y=y} end}
UDim={new=function(s,o)return{Scale=s or 0,Offset=o or 0}end}
UDim2={new=function(xs,xo,ys,yo)return{X=UDim.new(xs,xo),Y=UDim.new(ys,yo)}end}
UDim2.fromScale=function(x,y)return UDim2.new(x,0,y,0)end
UDim2.fromOffset=function(x,y)return UDim2.new(0,x,0,y)end
Rect={new=function(...)return {...}end}; TweenInfo={new=function(...)return {...}end}
local delayed,deferred={},{}
task={delay=function(_,f)delayed[#delayed+1]=f end,defer=function(f)deferred[#deferred+1]=f end,spawn=function(f)f()end}
local function flushDeferred()
    local current=deferred;deferred={};for _,f in ipairs(current)do f()end
end
local activeConnections=0
local function signal()
    local s={Slots={}}
    function s:Connect(f)
        local c={Connected=true,Kind='RBXScriptConnection',Callback=f};activeConnections=activeConnections+1
        function c:Disconnect() if self.Connected then self.Connected=false;activeConnections=activeConnections-1 end end
        self.Slots[#self.Slots+1]=c;return c
    end
    function s:Fire(...)
        local slots={};for i,c in ipairs(self.Slots)do slots[i]=c end
        for _,c in ipairs(slots)do if c.Connected then c.Callback(...) end end
    end
    return s
end
local focus=nil
local methods={}
local signals={Activated=true,InputBegan=true,InputChanged=true,InputEnded=true,FocusLost=true,MouseEnter=true,MouseLeave=true}
local mt={}
local function parentSize(o) return o.Props.Parent and o.Props.Parent.AbsoluteSize or Vector2.new(1280,720) end
function mt.__index(o,k)
    if methods[k] then return methods[k] end
    if signals[k] then if not o.Events[k]then o.Events[k]=signal()end;return o.Events[k]end
    if k=='AbsoluteSize' then
        if o.ClassName=='ScreenGui' or o.ClassName=='PlayerGui' then return Vector2.new(1280,720) end
        local p=parentSize(o);local s=o.Props.Size or UDim2.new();return Vector2.new(p.X*s.X.Scale+s.X.Offset,p.Y*s.Y.Scale+s.Y.Offset)
    end
    if k=='AbsolutePosition' then
        if not o.Props.Parent then return Vector2.new(0,0)end
        local p=o.Props.Parent.AbsolutePosition;local z=parentSize(o);local s=o.Props.Position or UDim2.new();local a=o.Props.AnchorPoint or Vector2.new(0,0)
        return Vector2.new(p.X+z.X*s.X.Scale+s.X.Offset-o.AbsoluteSize.X*a.X,p.Y+z.Y*s.Y.Scale+s.Y.Offset-o.AbsoluteSize.Y*a.Y)
    end
    if k=='AbsoluteContentSize' then
        local h=0
        if o.Parent then for _,child in ipairs(o.Parent.Children)do if child~=o and child.Props.Size and child.Visible~=false then h=h+child.AbsoluteSize.Y end end end
        return Vector2.new(0,h)
    end
    return o.Props[k]
end
function mt.__newindex(o,k,v)
    if k=='Parent' then
        if o.Props.Parent then for i,c in ipairs(o.Props.Parent.Children)do if c==o then table.remove(o.Props.Parent.Children,i);break end end end
        if v then v.Children[#v.Children+1]=o end
    end
    local old=o.Props[k];o.Props[k]=v
    if old~=v and o.Events['Changed:'..k] then o.Events['Changed:'..k]:Fire() end
end
function methods:GetPropertyChangedSignal(k)
    local name='Changed:'..k;if not self.Events[name]then self.Events[name]=signal()end;return self.Events[name]
end
function methods:Destroy()
    if self.Props.Destroyed then return end;self.Props.Destroyed=true
    local children={};for i,c in ipairs(self.Children)do children[i]=c end
    for _,c in ipairs(children)do c:Destroy()end
    for _,s in pairs(self.Events)do for _,c in ipairs(s.Slots)do c:Disconnect()end end
    self.Parent=nil
end
function methods:IsDescendantOf(target)local p=self.Parent;while p do if p==target then return true end;p=p.Parent end;return false end
function methods:CaptureFocus()focus=self end
function methods:ReleaseFocus()focus=nil;self.FocusLost:Fire()end
function methods:GetChildren()return self.Children end
function methods:IsA(kind)return kind==self.ClassName end
Instance={new=function(kind)return setmetatable({ClassName=kind,Kind='Instance',Props={BackgroundTransparency=0,CanvasPosition=Vector2.new(0,0),Visible=true},Children={},Events={}},mt)end}
typeof=function(v)return type(v)=='table' and v.Kind or type(v)end
local pg=Instance.new('PlayerGui')
local input={InputChanged=signal(),InputEnded=signal(),InputBegan=signal(),GetFocusedTextBox=function()return focus end,IsKeyDown=function()return false end}
local files,json,seq={}, {},0
readfile=function(p)return files[p]end;writefile=function(p,v)assert(p:find('^SerenityConcept02/'),'production config write');files[p]=v end
isfile=function(p)return files[p]~=nil end;makefolder=function(p)assert(p=='SerenityConcept02')end
local services={
    UserInputService=input,
    Players={LocalPlayer={WaitForChild=function()return pg end}},
    MarketplaceService={GetProductInfo=function()return{Name='Mock Game'}end},
    HttpService={JSONEncode=function(_,v)seq=seq+1;local k=tostring(seq);json[k]=copy(v);return k end,JSONDecode=function(_,v)return copy(json[v])end},
    TweenService={Create=function(_,obj,_,props)return{Play=function()for k,v in pairs(props)do obj[k]=v end end,Cancel=function()end}end},
}
game={GameId=42,PlaceId=123,GetService=function(_,k)return assert(services[k],k)end,HttpGet=function()error('Unexpected network call')end}
getgenv=function()return _G end
local production={Destroy=function()error('Production destroyed')end};_G.__SERENITY_RUNTIME_V3=production
local function start()local app=dofile('__BUNDLE_PATH__');flushDeferred();return app end
local app=start()
assert(app.Current=='About')
assert(app.GameTitle.Text=='Mock Game')
assert(app.Controls['Automation.Farming.AutoCollect']:Get()==false)
local c=app.Controls['Automation.Farming.AutoCollect']
local writes=0;local original=app.Config.Set
app.Config.Set=function(self,k,v)if k=='Automation.Farming.AutoCollect'then writes=writes+1 end;return original(self,k,v)end
c:Set(true);c:Set(true);assert(writes==1,'duplicate callback')
assert(app.Config:Get('Automation.Farming.AutoCollect')==true)
c:SetEnabled(false)
for _,child in ipairs(c.Frame:GetChildren())do if child.ClassName=='TextButton'then child.Activated:Fire()end end
assert(c:Get()==true and writes==1,'disabled toggle fired')
local slider=app.Controls['Automation.Farming.CollectDelay'];slider:Set(100);assert(slider:Get()==30);slider:Set(-5);assert(slider:Get()==1)
slider:Set(5.4);assert(slider:Get()==5);slider:Set(0/0);assert(slider:Get()==5)
local multi=app.Controls['Automation.Selection.Rarities'];multi:Set({'Rare','Epic'})
local value=multi:Get();value[1]='HACK';assert(multi:Get()[1]=='Rare','selection leaked by reference')
local baseline=activeConnections
local owned=#app.Runtime.Cleanups
for i=1,20 do
    for _,child in ipairs(multi.Frame:GetChildren())do if child.ClassName=='TextButton'then child.Activated:Fire()end end
    assert(app.Popup.Owner==multi)
    multi:Refresh({'Rare','Epic','Mythic'},true);assert(app.Popup.Owner==multi)
    app.Popup:Close()
end
assert(activeConnections==baseline,'popup connection leak')
assert(#app.Runtime.Cleanups==owned,'popup cleanup list growth')
multi:Refresh({'Rare','Mythic'},true);assert(#multi:Get()==1 and multi:Get()[1]=='Rare')
multi:Set({});assert(#multi:Get()==0,'empty selection became all')
local stored=app.Config:Get('Automation.Selection.Rarities');assert(#stored==0)
app:Search();flushDeferred();assert(app.Popup.Active and focus)
input.InputBegan:Fire({KeyCode=Enum.KeyCode.Escape},true);assert(not app.Popup.Active and not focus,'Escape failed in textbox')
app:SetVisible(false);assert(not app.Holder.Visible);app:SetVisible(true);assert(app.Holder.Visible)
app:SelectPage('Settings');app.Tabs.Settings.Select('Profiles');app.Config:Save()
local second=start();assert(app.Runtime.Destroyed,'reexecute did not clean old preview')
assert(second.Current=='Settings' and second.Config:Get('View.Tab.Settings')=='Profiles','layout not restored')
assert(second.Controls['Automation.Farming.AutoCollect']:Get()==true,'value not restored')
assert(_G.__SERENITY_RUNTIME_V3==production,'production runtime changed')
second:Destroy();second:Destroy();assert(activeConnections==0,'connections remained after destroy')
assert(_G.__SERENITY_CONCEPT_02==nil)
for _,f in ipairs(delayed)do f()end
print('PASS: mount; isolated state; single callback; disabled toggle; slider bounds; copied multiselect; open-menu refresh; popup cleanup; Escape; hide/show; re-execute; config restoration; teardown.')
