local DIR=debug.getinfo(1,"S").source:gsub("^@", ""):match("^(.*[/])") or "./"
local Core=dofile(DIR..'core.lua')
local env={};getgenv=function()return env end
local signals={}
local function signal()
 local s={listeners={}}
 function s:Connect(fn)local c={Connected=true,fn=fn};function c:Disconnect()self.Connected=false end;self.listeners[#self.listeners+1]=c;signals[#signals+1]=c;return c end
 function s:Fire(...)for _,c in ipairs(self.listeners)do if c.Connected then c.fn(...)end end end
 return s
end
local nodes={}
local methods={}
function methods:GetChildren()local a={};for _,n in ipairs(nodes)do if n.Parent==self then a[#a+1]=n end end;return a end
function methods:IsA(c)return self.ClassName==c or (c=='GuiButton' and self.ClassName=='TextButton') or (c=='GuiObject' and (self.ClassName=='TextButton' or self.ClassName=='TextLabel' or self.ClassName=='Frame' or self.ClassName=='ScrollingFrame')) end
function methods:FindFirstChild(name,recursive)for _,c in ipairs(self:GetChildren())do if c.Name==name then return c end;if recursive then local v=c:FindFirstChild(name,true);if v then return v end end end end
function methods:FindFirstChildWhichIsA(class,recursive)for _,c in ipairs(self:GetChildren())do if c:IsA(class)then return c end;if recursive then local v=c:FindFirstChildWhichIsA(class,true);if v then return v end end end end
function methods:Clone()local n=Instance.new(self.ClassName);for k,v in pairs(self)do if k~='Parent' and k~='signals' and type(v)~='table' then n[k]=v end end;for _,k in ipairs({'Size','Position'})do n[k]=self[k]end;for _,c in ipairs(self:GetChildren())do local child=c:Clone();child.Parent=n end;return n end
function methods:Destroy()for _,c in ipairs(self:GetChildren())do c:Destroy()end;self.Parent=nil end
function methods:GetPropertyChangedSignal(k)self.signals=self.signals or {};self.signals[k]=self.signals[k] or signal();return self.signals[k] end
Instance={new=function(class)local o={CanvasPosition={X=0,Y=0},AbsoluteCanvasSize={X=420,Y=200},AbsoluteSize={X=420,Y=220},ClassName=class,Visible=true,Enabled=true,Size=UDim2.new(),Position=UDim2.new(),LayoutOrder=0};setmetatable(o,{__index=function(t,k)if methods[k]then return methods[k]end;if k=='Activated' or k=='FocusLost' or k=='Destroying' then local s=signal();rawset(t,k,s);return s end end});nodes[#nodes+1]=o;return o end}
local function vec(x,y,...)return {X=x,Y=y,x,y,...}end
UDim={new=vec};UDim2={new=function(a,b,c,d)return {X={Scale=a or 0,Offset=b or 0},Y={Scale=c or 0,Offset=d or 0}}end};UDim2.fromOffset=function(x,y)return UDim2.new(0,x,0,y)end;UDim2.fromScale=function(x,y)return UDim2.new(x,0,y,0)end;Vector2={new=vec};Color3={fromRGB=vec}
Enum=setmetatable({},{__index=function(t,k)local v=setmetatable({},{__index=function(_,x)return x end});rawset(t,k,v);return v end})
local camera=Instance.new('Camera');camera.ViewportSize={X=360,Y=740}
workspace=Instance.new('Workspace');workspace.CurrentCamera=camera
local root=Instance.new('CoreGui')
local player={UserId=123,Name='Tester',DisplayName='Tester'}
local responseMap={};local index=0
local Http={JSONDecode=function(_,key)return responseMap[key]end,JSONEncode=function(_,body)return body end}
game={PlaceId=104809044319701,GameId=10544327471,GetService=function(_,name)if name=='HttpService'then return Http elseif name=='Players'then return {LocalPlayer=player}elseif name=='TextService'then return {GetTextSize=function()return {Y=28}end}else return root end end}
local requests={};local warning={id='one',message='Be respectful'}
request=function(r)
 requests[#requests+1]=r
 local data
 if r.Url:find('/moderation/')then data={success=true,warning=warning}
 elseif r.Url:find('/chat/messages')then data={success=true,messages={{id=1,userId='123',displayName='<Admin>',role='Dev',gameName='Phonk',message='Hello',translations={fil='Kumusta'}}}}
 else data={id='unrelated',active=true,target='everyone',targetPlaceId='999',message='Wrong game'}end
 index=index+1;responseMap[tostring(index)]=data;return {StatusCode=200,Body=tostring(index)}
end
local threads={}
task={defer=function(fn)local t=coroutine.create(fn);threads[#threads+1]=t;return t end,wait=function()coroutine.yield()end,cancel=function(t)coroutine.close(t)end}
warn=print
local function tick()local snapshot={table.unpack(threads)};for _,t in ipairs(snapshot)do if coroutine.status(t)=='suspended'then local ok,e=coroutine.resume(t);assert(ok,e)end end end
local start=dofile(DIR..'client.lua')
local function make(c,name,parent)local o=Instance.new(c);o.Name=name;o.Parent=parent;return o end
local official=make('ScreenGui','SerenityConcept02',root)
local holder=make('Frame','Holder',official)
local shell=make('Frame','Shell',holder)
local nav=make('ScrollingFrame','Navigation',shell)
local about=make('TextButton','About',nav);about.LayoutOrder=1
local aboutText=make('TextLabel','Label',about);aboutText.Text='About';aboutText.TextSize=13
local tile=make('Frame','Tile',about);tile.BackgroundColor3='selected'
local other=make('TextButton','Automation',nav);other.LayoutOrder=2
local header=make('Frame','Header',shell);header.Active=true;header.Position=UDim2.fromOffset(200,44)
local heading=make('TextLabel','Heading',header);heading.Text='About';heading.TextSize=18
local description=make('TextLabel','Description',header);description.Text='Welcome';description.TextSize=11
local content=make('Frame','Content',shell)
local aboutPage=make('Frame','AboutPage',content);aboutPage.Size=UDim2.fromScale(1,1)
local autoPage=make('Frame','AutoPage',content);autoPage.Size=UDim2.fromScale(1,1);autoPage.Visible=false
local Bridge=dofile(DIR..'bridge.lua')
assert(Bridge.Find(root).Content==content)
local a=start(Core,Bridge);tick()
assert(nav:FindFirstChild('SerenityGlobalChatTest').LayoutOrder==2 and other.LayoutOrder==3)
assert(#requests==1 and requests[1].Url:find('/announcements/')) -- closed chat does not poll
local function find(text)for i=#nodes,1,-1 do local n=nodes[i];if n.Parent and n.Text==text then return n end end end
nav:FindFirstChild('SerenityGlobalChatTest').Activated:Fire();tick();tick();assert(heading.Text=='Global Chat' and not aboutPage.Visible)
assert(#requests>=3)
assert(env.__SERENITY_COMMUNITY_SEEN['warning:one'])
find('Filipino').Activated:Fire();tick();assert(find('Kumusta'))
find('Filipino').Activated:Fire();assert(find('Kumusta')) -- clicking selected tab does not cycle
find('General').Activated:Fire();assert(find('Hello'))
local masked=false
for _,n in ipairs(nodes) do if n.Parent and n.RichText and type(n.Text)=='string' then assert(not n.Text:find('&lt;Admin&gt;',1,true));if n.Text:find('&lt;Ad****',1,true) then masked=true end end end
assert(masked,'display name must mask its second half')
assert(find('[DEV]')==nil) -- badge is formatted safely in the header
for _,n in ipairs(nodes)do if n.Parent and n.Name=='ChatSearch' then n.Text='nomatch';n:GetPropertyChangedSignal('Text'):Fire();assert(find('No matching messages'));n.Text='';n:GetPropertyChangedSignal('Text'):Fire()end end
for _,n in ipairs(nodes)do assert(n.ClassName~='BlurEffect')end
holder.Visible=false;holder:GetPropertyChangedSignal('Visible'):Fire();assert(not a.opened)
holder.Visible=true;holder:GetPropertyChangedSignal('Visible'):Fire();assert(a.opened)
autoPage.Visible=true;autoPage:GetPropertyChangedSignal('Visible'):Fire();assert(not a.opened)
heading.Text='Automation';description.Text='Controls'
aboutPage.Visible=true;autoPage.Visible=false;heading.Text='About';description.Text='Welcome'
nav:FindFirstChild('SerenityGlobalChatTest').Activated:Fire();assert(a.opened)
find('Test warning').Activated:Fire();tick()
assert(find('Community warning · Preview'))
local b=start(Core,Bridge);assert(a.Stopped);assert(other.LayoutOrder==3);tick()
local count=#requests;b:Stop();tick();assert(#requests==count)
assert(other.LayoutOrder==2 and aboutPage.Visible and not nav:FindFirstChild('SerenityGlobalChatTest'));for _,c in ipairs(signals)do assert(not c.Connected)end
print('PASS: closed-chat request suppression, moderation banner, no blur, rerun cancellation, stop cleanup, mobile viewport construction.')
