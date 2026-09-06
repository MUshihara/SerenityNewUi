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
local viewport=Vector2.new(1280,720)
local mt={}
local function parentSize(o) return o.Props.Parent and o.Props.Parent.AbsoluteSize or Vector2.new(1280,720) end
function mt.__index(o,k)
    if methods[k] then return methods[k] end
    if signals[k] then if not o.Events[k]then o.Events[k]=signal()end;return o.Events[k]end
    if k=='AbsoluteSize' then
        if o.ClassName=='ScreenGui' or o.ClassName=='PlayerGui' then return viewport end
        local p=parentSize(o);local s=o.Props.Size or UDim2.new();return Vector2.new(p.X*s.X.Scale+s.X.Offset,p.Y*s.Y.Scale+s.Y.Offset)
    end
    if k=='AbsolutePosition' then
        if not o.Props.Parent then return Vector2.new(0,0)end
        local p=o.Props.Parent.AbsolutePosition;local z=parentSize(o);local s=o.Props.Position or UDim2.new();local a=o.Props.AnchorPoint or Vector2.new(0,0)
        return Vector2.new(p.X+z.X*s.X.Scale+s.X.Offset-o.AbsoluteSize.X*a.X,p.Y+z.Y*s.Y.Scale+s.Y.Offset-o.AbsoluteSize.Y*a.Y)
    end
    if k=='AbsoluteContentSize' then
        if o.Props.TestContentSize then return o.Props.TestContentSize end
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
local keyboardSignals={}
function input:GetPropertyChangedSignal(name)
    keyboardSignals[name]=keyboardSignals[name] or signal();return keyboardSignals[name]
end
local files,json,seq={}, {},0
readfile=function(p)return files[p]end;writefile=function(p,v)assert(p:find('^SerenityConcept02/'),'production config write');files[p]=v end
isfile=function(p)return files[p]~=nil end;makefolder=function(p)assert(p=='SerenityConcept02')end
local holdTweens=false
local pendingTweens={}
local services={
    UserInputService=input,
    Players={LocalPlayer={WaitForChild=function()return pg end}},
    MarketplaceService={GetProductInfo=function()return{Name='Mock Game'}end},
    HttpService={JSONEncode=function(_,v)seq=seq+1;local k=tostring(seq);json[k]=copy(v);return k end,JSONDecode=function(_,v)return copy(json[v])end},
    TweenService={Create=function(_,obj,_,props)local t={Completed=signal()};function t:Play() for k,v in pairs(props)do obj[k]=v end;if holdTweens then pendingTweens[#pendingTweens+1]=self else self.Completed:Fire(Enum.PlaybackState.Completed) end end;function t:Cancel()self.Completed:Fire(Enum.PlaybackState.Cancelled)end;return t end},
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
second:Notify('First');local firstToast=second.Toast
second:Notify('Second');assert(firstToast.Destroyed and second.Toast~=firstToast,'toast replacement failed')
holdTweens=true
second:Search();flushDeferred()
local old=second.Popup.Active
second.Popup:Close();assert(second.Popup.Closing==old,'exit animation discarded early')
second:Search();flushDeferred()
local latest=second.Popup.Active
for _,t in ipairs(pendingTweens)do t.Completed:Fire(Enum.PlaybackState.Completed)end
pendingTweens={}
assert(second.Popup.Active==latest and latest~=old,'old close affected reopened popup')
second.Popup:Close()
second:Destroy();second:Destroy();assert(activeConnections==0,'connections remained after destroy')
assert(_G.__SERENITY_CONCEPT_02==nil)
for _,f in ipairs(delayed)do f()end
-- Explicit scale regression: physical layout measurements must become logical offsets.
_G.SerenityConceptOptions={LowEffects=true}
local scaled=start()
scaled.Config:Set('Settings.Appearance.Scale',90);scaled:Fit()
local section=scaled.Sections['Settings.Appearance']
local expected=49
for _,child in ipairs(section.Body:GetChildren()) do
    if child.ClassName=='Frame' then expected=expected+child.Size.Y.Offset end
end
for _,percent in ipairs({75,90,100,115}) do
    scaled.Config:Set('Settings.Appearance.Scale',percent);scaled:Fit();section:SetOpen(true,true)
    assert(section.Frame.Size.Y.Offset==expected,'section height changed with UI scale')
end
scaled:Destroy()
-- Phone layouts preserve control scale and stack cards; rotation recomputes the shell.
input.TouchEnabled=true
for _,size in ipairs({Vector2.new(390,760),Vector2.new(844,350),Vector2.new(360,640)}) do
    viewport=size
    local mobile=start()
    assert(mobile.Mobile and mobile.SidebarWidth==(size.Y>size.X and 68 or 144),'incorrect mobile profile')
    assert(mobile.LayoutWidth*mobile.Scale.Scale<=size.X-24 and mobile.LayoutHeight*mobile.Scale.Scale<=size.Y-24,'phone shell overflow')
    assert(mobile.Pages.About.Icon.Size.X.Offset==22,'small navigation icons')
    assert(mobile.Controls['Automation.Farming.AutoCollect'].Frame.Size.Y.Offset>=48,'small touch row')
    if size.X<500 then assert(mobile.AboutCards.Updates.Position.Y.Offset==292,'cards failed to stack') end
    mobile:Search();flushDeferred()
    assert(mobile.Popup.Panel.ClassName=='Frame','low effects allocated CanvasGroup')
    input.OnScreenKeyboardVisible=true;input.OnScreenKeyboardSize=Vector2.new(size.X,math.floor(size.Y/2))
    keyboardSignals.OnScreenKeyboardVisible:Fire()
    local panel=mobile.Popup.Panel
    local popupScale=1
    for _,child in ipairs(panel:GetChildren()) do if child.ClassName=='UIScale' then popupScale=child.Scale end end
    assert(panel.Position.Y.Offset+panel.Size.Y.Offset*popupScale<=size.Y-input.OnScreenKeyboardSize.Y,'search overlaps keyboard')
    input.OnScreenKeyboardVisible=false
    mobile:Destroy()
end
_G.SerenityConceptOptions=nil
assert(activeConnections==0,'mobile cleanup leaked connections')
print('PASS: scaled section measurement; portrait/landscape phone bounds; full-size touch rows; stacked cards; low-effects popup; mobile cleanup.')
print('PASS: mount; isolated state; single callback; disabled toggle; slider bounds; copied multiselect; open-menu refresh; popup cleanup; Escape; hide/show; re-execute; config restoration; teardown.')

-- Actual supplied Phonk manifest: no gameplay code is executed by this fixture.
local base=('__BUNDLE_PATH__'):gsub('dist/SerenityConcept.lua$','')
local manifest=dofile(base..'tests/PhonkManifest.lua')
local bridge=dofile(base..'dist/SerenityPhonkUI.lua')
local callbackCount=0
setBool=function(key,value) assert(key=='AutoClick');callbackCount=callbackCount+1 end
local phonk=bridge.Build(manifest);flushDeferred()
assert(callbackCount==0,'construction activated Phonk')
local count=0
for _,page in ipairs(manifest.Pages)do for _,feature in ipairs(page.Features)do
    for _,spec in ipairs(feature.Controls)do
        if spec.Id then assert(phonk.Controls[page.Id..'.'..feature.Id..'.'..spec.Id],'missing Phonk control');count=count+1 end
    end
end end
phonk.Controls['Automation.Farm.AutoClick']:Set(true)
assert(callbackCount==1,'Changed callback was not called exactly once')
local cleaned=false;phonk.Runtime:TrackCleanup(function() cleaned=true end)
phonk.Controls['Settings.Interface.StartMinimized']:Set(true);phonk.Config:Save()
_G.SerenityFeedbackWebhook='https://discord.com/api/webhooks/123/test'
local nextPhonk=bridge.Build(manifest);flushDeferred()
assert(not nextPhonk.Visible and nextPhonk.Launcher.Visible,'startup minimize or persistent launcher failed')
nextPhonk.Launcher.Activated:Fire();assert(nextPhonk.Visible and nextPhonk.Launcher.Visible,'launcher toggle failed')
assert(cleaned and phonk.Runtime.Destroyed,'Phonk replacement missed cleanup')
assert(nextPhonk.Controls['Automation.Farm.AutoClick']:Get()==false,'Phonk did not start OFF')
assert(nextPhonk.Pages.GameTuning and nextPhonk.Pages.Settings,'game tuning and UI settings collided')
local touch={UserInputType=Enum.UserInputType.Touch,Position=Vector2.new(20,180)}
nextPhonk.Launcher.InputBegan:Fire(touch)
touch.Position=Vector2.new(120,230);input.InputChanged:Fire(touch);input.InputEnded:Fire(touch)
nextPhonk.Launcher.Activated:Fire()
assert(nextPhonk.Visible,'drag incorrectly toggled window')
assert(nextPhonk.Config:Get('View.LauncherX')==118,'launcher position was not saved')
nextPhonk:Action('Reset')
for _,child in ipairs(nextPhonk.Popup.Panel:GetChildren())do if child.ClassName=='TextButton' and child.Text=='Reset' then child.Activated:Fire();break end end
assert(nextPhonk.Config:Get('View.LauncherX')==18 and nextPhonk.Config:Get('Settings.Interface.StartMinimized')==false,'reset failed to clear saved preferences')
local sent=0
request=function(payload)
    sent=sent+1
    local body=json[payload.Body]
    assert(payload.Method=='POST' and body.embeds[1].fields[1].value=='+1 Phonk Evolution','missing game report context')
    assert(body.allowed_mentions and #body.allowed_mentions.parse==0,'mentions enabled')
    return {StatusCode=204}
end
assert(nextPhonk.Feedback,'missing shared report form')
nextPhonk.Feedback.Category:Set('New Feature')
assert(sent==0,'destination setup sent a report')
nextPhonk.Feedback.Draft.Text='The dropdown is clipped on my screen.'
nextPhonk.Feedback.Submit();assert(sent==1 and nextPhonk.Feedback.Draft.Text=='','report success path failed')
nextPhonk.Feedback.Draft.Text='A second report should be throttled.'
nextPhonk.Feedback.Submit();assert(sent==1,'report cooldown failed')
request=nil
_G.SerenityFeedbackWebhook=nil
nextPhonk:Destroy();assert(activeConnections==0,'Phonk UI connection leak')
print('PASS: actual Phonk manifest controls '..count..'; callback wiring; OFF on restart; cleanup; settings separation.')
