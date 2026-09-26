-- Serenity Denim UI: isolated visual prototype. No gameplay or telemetry.
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer
assert(player, "Run this preview on the client")
local env = (getgenv and getgenv()) or _G
local KEY = "__SerenityDenimPreview"
if env[KEY] then env[KEY]() end
local connections = {}
local dead = false
local gui = Instance.new("ScreenGui")
gui.Name = "SerenityDenimPreview"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 120
gui.Parent = player:WaitForChild("PlayerGui")
local function cleanup()
 if dead then return end
 dead = true
 for _, c in ipairs(connections) do c:Disconnect() end
 gui:Destroy()
 if env[KEY] == cleanup then env[KEY] = nil end
end
env[KEY] = cleanup
local function on(signal, fn)
 local c = signal:Connect(fn)
 table.insert(connections, c)
 return c
end
local C = {
 bg=Color3.fromRGB(13,32,48), panel=Color3.fromRGB(19,43,62),
 side=Color3.fromRGB(11,28,42), line=Color3.fromRGB(43,76,101),
 blue=Color3.fromRGB(42,89,124), bright=Color3.fromRGB(81,151,220),
 text=Color3.fromRGB(243,237,222), muted=Color3.fromRGB(166,190,210),
 green=Color3.fromRGB(96,212,174)
}
local function make(class, parent, props)
 local o=Instance.new(class)
 for k,v in pairs(props or {}) do o[k]=v end
 o.Parent=parent
 return o
end
local function round(o,r)
 make("UICorner",o,{CornerRadius=UDim.new(0,r or 10)})
end
local function frame(parent, color)
 local o=make("Frame",parent,{BackgroundColor3=color or C.panel,BorderSizePixel=0})
 round(o)
 make("UIStroke",o,{Color=C.line,Thickness=1,Transparency=0.25})
 return o
end
local function text(parent, value, size, color)
 return make("TextLabel",parent,{BackgroundTransparency=1,Text=value,TextSize=size or 14,
 TextColor3=color or C.text,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,
 TextYAlignment=Enum.TextYAlignment.Center,TextWrapped=true,Size=UDim2.new(1,0,0,24)})
end
local function button(parent,value)
 local b=make("TextButton",parent,{Text=value,TextSize=14,Font=Enum.Font.GothamMedium,
 TextColor3=C.text,BackgroundColor3=C.blue,BorderSizePixel=0,AutoButtonColor=true})
 round(b,8)
 return b
end
local function pad(parent,n)
 make("UIPadding",parent,{PaddingLeft=UDim.new(0,n),PaddingRight=UDim.new(0,n),
 PaddingTop=UDim.new(0,n),PaddingBottom=UDim.new(0,n)})
end
local function list(parent,gap)
 return make("UIListLayout",parent,{Padding=UDim.new(0,gap or 8),SortOrder=Enum.SortOrder.LayoutOrder})
end
local shell=frame(gui,C.bg)
shell.AnchorPoint=Vector2.new(0.5,0.5)
shell.Position=UDim2.fromScale(0.5,0.5)
local header=make("Frame",shell,{BackgroundColor3=C.side,BorderSizePixel=0,Size=UDim2.new(1,0,0,56)})
round(header,12)
make("UIGradient",header,{Color=ColorSequence.new(C.side,C.panel),Rotation=10})
local title=text(header,"✦  SERENITY HUB",18)
title.Position=UDim2.fromOffset(16,10)
title.Size=UDim2.new(1,-150,0,36)
local mini=button(header,"—")
mini.Size=UDim2.fromOffset(38,34)
mini.Position=UDim2.new(1,-90,0,11)
local close=button(header,"×")
close.Size=UDim2.fromOffset(38,34)
close.Position=UDim2.new(1,-46,0,11)
on(close.Activated,cleanup)
local sidebar=make("Frame",shell,{BackgroundColor3=C.side,BorderSizePixel=0})
local nav=make("Frame",sidebar,{BackgroundTransparency=1,Size=UDim2.new(1,0,1,-48)})
pad(nav,8)
local navLayout=list(nav,7)
local foot=text(sidebar,"●  Visual test",12,C.green)
foot.Position=UDim2.new(0,12,1,-40)
foot.Size=UDim2.new(1,-24,0,32)
local body=make("ScrollingFrame",shell,{BackgroundTransparency=1,BorderSizePixel=0,
 ScrollBarThickness=4,ScrollBarImageColor3=C.blue,CanvasSize=UDim2.new(),
 AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollingDirection=Enum.ScrollingDirection.Y})
pad(body,14)
list(body,12)
local heading=text(body,"Dashboard",23)
heading.Font=Enum.Font.GothamBold
heading.Size=UDim2.new(1,0,0,30)
heading.LayoutOrder=1
local subtitle=text(body,"Isolated preview • Sample controls only",13,C.muted)
subtitle.LayoutOrder=2
local stats=make("Frame",body,{BackgroundTransparency=1,Size=UDim2.new(1,0,0,78),LayoutOrder=3})
local statCards={}
for i,info in ipairs({{"Session","Preview"},{"Active now","—"},{"Status","UI only"}}) do
 local card=frame(stats)
 card.Size=UDim2.new(1/3,-6,1,0)
 card.Position=UDim2.new((i-1)/3, (i-1)*3,0,0)
 local label=text(card,info[1],12,C.muted)
 label.Position=UDim2.fromOffset(10,8)
 label.Size=UDim2.new(1,-20,0,24)
 local value=text(card,info[2],18,i==3 and C.green or C.text)
 value.Position=UDim2.fromOffset(10,35)
 value.Size=UDim2.new(1,-20,0,28)
 value.Font=Enum.Font.GothamBold
 statCards[i]=card
end
local welcome=frame(body,C.blue)
welcome.LayoutOrder=4
welcome.Size=UDim2.new(1,0,0,58)
local welcomeText=text(welcome,"✦  Welcome to the denim preview",15)
welcomeText.Position=UDim2.fromOffset(14,8)
welcomeText.Size=UDim2.new(1,-28,1,-16)
local controls=frame(body)
controls.LayoutOrder=5
controls.AutomaticSize=Enum.AutomaticSize.Y
controls.Size=UDim2.new(1,0,0,0)
pad(controls,14)
list(controls,8)
local controlTitle=text(controls,"Quick settings",17)
controlTitle.Font=Enum.Font.GothamBold
local rowOrder=0
local function row(label,height)
 rowOrder=rowOrder+1
 local r=make("Frame",controls,{BackgroundTransparency=1,Size=UDim2.new(1,0,0,height or 48),LayoutOrder=rowOrder})
 local l=text(r,label,14)
 l.Size=UDim2.new(1,-120,1,0)
 return r
end
local function toggle(label,initial,callback)
 local r=row(label)
 local b=button(r,"")
 b.Size=UDim2.fromOffset(52,28)
 b.Position=UDim2.new(1,-52,0.5,-14)
 round(b,14)
 local knob=make("Frame",b,{Size=UDim2.fromOffset(22,22),BackgroundColor3=C.text,BorderSizePixel=0})
 round(knob,11)
 local value=initial
 local function paint()
  b.BackgroundColor3=value and C.bright or C.line
  knob.Position=UDim2.fromOffset(value and 27 or 3,3)
 end
 paint()
 on(b.Activated,function() value=not value paint() if callback then callback(value) end end)
end
toggle("Auto collect (demo)",true)
toggle("Auto sell (demo)",false)
toggle("Panel transparency",false,function(v) shell.BackgroundTransparency=v and 0.12 or 0 end)
local dropRow=row("Effects")
local drop=button(dropRow,"Reduced  ▾")
drop.Size=UDim2.fromOffset(114,34)
drop.Position=UDim2.new(1,-114,0.5,-17)
local choices=make("Frame",controls,{BackgroundTransparency=1,Size=UDim2.new(1,0,0,84),Visible=false,LayoutOrder=rowOrder+1})
rowOrder=rowOrder+1
list(choices,6)
for _,label in ipairs({"Reduced","Standard"}) do
 local b=button(choices,label)
 b.Size=UDim2.new(1,0,0,38)
 on(b.Activated,function() drop.Text=label.."  ▾" choices.Visible=false end)
end
on(drop.Activated,function() choices.Visible=not choices.Visible end)
local sliderRow=row("Accent intensity",64)
local track=make("TextButton",sliderRow,{Text="",AutoButtonColor=false,BorderSizePixel=0,
 BackgroundColor3=C.line,Position=UDim2.new(0,0,1,-16),Size=UDim2.new(1,-52,0,8)})
round(track,4)
local fill=make("Frame",track,{BackgroundColor3=C.bright,BorderSizePixel=0,Size=UDim2.fromScale(0.65,1)})
round(fill,4)
local knob=make("Frame",track,{BackgroundColor3=C.text,BorderSizePixel=0,Size=UDim2.fromOffset(18,18),
 AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.65,0.5)})
round(knob,9)
local pct=text(sliderRow,"65%",12,C.muted)
pct.Size=UDim2.fromOffset(46,24)
pct.Position=UDim2.new(1,-46,1,-24)
local dragging=nil
local function slide(x)
 local v=math.clamp((x-track.AbsolutePosition.X)/math.max(track.AbsoluteSize.X,1),0,1)
 fill.Size=UDim2.fromScale(v,1)
 knob.Position=UDim2.fromScale(v,0.5)
 pct.Text=tostring(math.floor(v*100+0.5)).."%"
 welcome.BackgroundColor3=C.panel:Lerp(C.blue,v)
end
on(track.InputBegan,function(input)
 if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
 dragging=input slide(input.Position.X)
 end
end)
on(UIS.InputChanged,function(input)
 if dragging and (input==dragging or (dragging.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseMovement)) then slide(input.Position.X) end
end)
on(UIS.InputEnded,function(input) if input==dragging then dragging=nil end end)
local updates=frame(body)
updates.LayoutOrder=6
updates.Size=UDim2.new(1,0,0,100)
pad(updates,14)
local upd=text(updates,"What’s new",17)
upd.Font=Enum.Font.GothamBold
local desc=text(updates,"Denim-blue surfaces • Readable controls\nResponsive navigation • No live stats requests",13,C.muted)
desc.Position=UDim2.fromOffset(0,30)
desc.Size=UDim2.new(1,0,0,48)
local notice=frame(shell,C.panel)
notice.Visible=false
notice.ZIndex=10
local nt=text(notice,"✦  Serenity preview",14)
nt.ZIndex=11
nt.Position=UDim2.fromOffset(12,6)
nt.Size=UDim2.new(1,-50,0,24)
local nb=text(notice,"Notification placement test.",12,C.muted)
nb.ZIndex=11
nb.Position=UDim2.fromOffset(12,31)
nb.Size=UDim2.new(1,-24,0,30)
local nx=button(notice,"×")
nx.ZIndex=12
nx.Size=UDim2.fromOffset(28,28)
nx.Position=UDim2.new(1,-34,0,5)
on(nx.Activated,function() notice.Visible=false end)
local test=button(body,"Test notification")
test.LayoutOrder=7
test.Size=UDim2.new(1,0,0,42)
on(test.Activated,function() notice.Visible=not notice.Visible end)
local navButtons={}
for _,name in ipairs({"About","Dashboard","Automation","Inventory","Settings"}) do
 local b=button(nav,name)
 navButtons[name]=b
 on(b.Activated,function()
  heading.Text=name
  subtitle.Text=name=="Dashboard" and "Isolated preview • Sample controls only" or name.." layout preview • No gameplay actions"
  for n,other in pairs(navButtons) do other.BackgroundColor3=n==name and C.blue or C.side end
  body.CanvasPosition=Vector2.new(0,0)
 end)
 b.BackgroundColor3=name=="Dashboard" and C.blue or C.side
end
local minimized=false
local function layout()
 local camera=workspace.CurrentCamera
 if not camera then return end
 local vp=camera.ViewportSize
 local w=math.min(960, math.max(260,vp.X-24))
 local h=math.min(690,math.max(220,vp.Y-76))
 local compact=w<700 or h<460
 shell.Size=UDim2.fromOffset(w,minimized and 56 or h)
 sidebar.Visible=not minimized
 body.Visible=not minimized
 if compact then
  sidebar.Position=UDim2.fromOffset(0,56)
  sidebar.Size=UDim2.new(1,0,0,52)
  nav.Size=UDim2.fromScale(1,1)
  navLayout.FillDirection=Enum.FillDirection.Horizontal
  navLayout.Padding=UDim.new(0,4)
  foot.Visible=false
  for _,b in pairs(navButtons) do b.Size=UDim2.new(0.2,-4,0,36) b.TextSize=11 end
  body.Position=UDim2.fromOffset(0,108)
  body.Size=UDim2.new(1,0,1,-108)
 else
  sidebar.Position=UDim2.fromOffset(0,56)
  sidebar.Size=UDim2.new(0,176,1,-56)
  nav.Size=UDim2.new(1,0,1,-48)
  navLayout.FillDirection=Enum.FillDirection.Vertical
  navLayout.Padding=UDim.new(0,7)
  foot.Visible=true
  for _,b in pairs(navButtons) do b.Size=UDim2.new(1,0,0,42) b.TextSize=14 end
  body.Position=UDim2.fromOffset(176,56)
  body.Size=UDim2.new(1,-176,1,-56)
 end
 notice.Size=UDim2.fromOffset(math.min(286,w-24),70)
 notice.Position=UDim2.new(1,-12,0,compact and 112 or 66)
 notice.AnchorPoint=Vector2.new(1,0)
 if minimized then notice.Visible=false end
 title.TextSize=w<400 and 14 or 18
end
on(mini.Activated,function() minimized=not minimized layout() end)
local cameraConnection=nil
local function watchCamera()
 if cameraConnection then cameraConnection:Disconnect() end
 if workspace.CurrentCamera then cameraConnection=on(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"),layout) end
 layout()
end
on(workspace:GetPropertyChangedSignal("CurrentCamera"),watchCamera)
watchCamera()
return {Destroy=cleanup}
