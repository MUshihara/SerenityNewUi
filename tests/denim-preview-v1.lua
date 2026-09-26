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
gui.IgnoreGuiInset = true
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
 text=Color3.fromRGB(243,237,222), muted=Color3.fromRGB(181,201,219),
 green=Color3.fromRGB(96,212,174)
}
local function make(class, parent, props)
 local o=Instance.new(class)
 for k,v in pairs(props or {}) do o[k]=v end
 o.Parent=parent
 return o
end
local function round(o,r)
 local old=o:FindFirstChildOfClass("UICorner")
 if old then old.CornerRadius=UDim.new(0,r or 10) return end
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
-- Draw icons using GUI geometry; no font-dependent symbols or remote assets.
local function icon(parent,kind,x,y,size,color)
 local root=make("Frame",parent,{Name="Icon_"..kind,BackgroundTransparency=1,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(size,size)})
 local c=color or C.muted
 local function line(x1,y1,x2,y2)
  local dx,dy=x2-x1,y2-y1
  make("Frame",root,{BorderSizePixel=0,BackgroundColor3=c,AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale((x1+x2)/2,(y1+y2)/2),Size=UDim2.new(0,math.sqrt(dx*dx+dy*dy)*size,0,1.5),Rotation=math.deg(math.atan2(dy,dx))})
 end
 local function box(x1,y1,w,h,r)
  local f=make("Frame",root,{BackgroundTransparency=1,Position=UDim2.fromScale(x1,y1),Size=UDim2.fromScale(w,h)})
  round(f,r or 2) make("UIStroke",f,{Color=c,Thickness=1.4}) return f
 end
 if kind=="star" then
  for _,r in ipairs({0,90}) do
   local f=make("Frame",root,{BorderSizePixel=0,BackgroundColor3=c,AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromScale(0.23,0.85),Rotation=r}) round(f,5)
  end
  make("Frame",root,{BorderSizePixel=0,BackgroundColor3=c,AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromScale(0.46,0.46),Rotation=45})
 elseif kind=="Dashboard" then for _,v in ipairs({{.12,.12},{.58,.12},{.12,.58},{.58,.58}}) do box(v[1],v[2],.29,.29) end
 elseif kind=="About" or kind=="clock" then
  box(.08,.08,.84,.84,100)
  if kind=="clock" then line(.5,.25,.5,.5) line(.5,.5,.7,.65) else line(.5,.46,.5,.73) box(.47,.26,.05,.05) end
 elseif kind=="Automation" then line(.1,.75,.4,.45) line(.4,.45,.6,.62) line(.6,.62,.9,.2) line(.65,.2,.9,.2) line(.9,.2,.9,.45)
 elseif kind=="Inventory" then box(.1,.24,.8,.65) line(.1,.43,.9,.43) line(.36,.12,.64,.12) line(.36,.12,.36,.24) line(.64,.12,.64,.24)
 elseif kind=="Settings" then
  for i,v in ipairs({.23,.5,.77}) do line(.1,v,.9,v) local x=i==2 and .65 or .35 box(x-.08,v-.09,.16,.18,3) end
 elseif kind=="user" then box(.34,.1,.32,.32,100) box(.17,.55,.66,.35,7)
 elseif kind=="doc" then box(.22,.1,.56,.8) line(.35,.35,.65,.35) line(.35,.5,.65,.5) line(.35,.65,.58,.65)
 elseif kind=="down" then line(.22,.35,.5,.65) line(.5,.65,.78,.35)
 elseif kind=="close" then line(.25,.25,.75,.75) line(.25,.75,.75,.25)
 elseif kind=="minus" then line(.2,.5,.8,.5)
 end
 return root
end
local shell=frame(gui,C.bg)
shell.AnchorPoint=Vector2.new(0.5,0.5)
shell.Position=UDim2.fromScale(0.5,0.5)
local header=make("Frame",shell,{BackgroundColor3=C.side,BorderSizePixel=0,Size=UDim2.new(1,0,0,48)})
round(header,12)
make("UIGradient",header,{Color=ColorSequence.new(C.side,C.panel),Rotation=10})
icon(header,"star",14,12,24,C.text)
local title=text(header,"SERENITY HUB",16)
title.Position=UDim2.fromOffset(46,7)
title.Size=UDim2.new(1,-150,0,36)
local mini=button(header,"")
icon(mini,"minus",7,7,18)
mini.Size=UDim2.fromOffset(32,32)
mini.Position=UDim2.new(1,-78,0,8)
local close=button(header,"")
icon(close,"close",7,7,18)
close.Size=UDim2.fromOffset(32,32)
close.Position=UDim2.new(1,-40,0,8)
on(close.Activated,cleanup)
local sidebar=make("Frame",shell,{BackgroundColor3=C.side,BorderSizePixel=0})
local nav=make("Frame",sidebar,{BackgroundTransparency=1,Size=UDim2.new(1,0,1,-48)})
pad(nav,8)
local navLayout=list(nav,7)
local foot=text(sidebar,"Font test v3",12,C.green)
foot.Position=UDim2.new(0,12,1,-40)
foot.Size=UDim2.new(1,-24,0,32)
local body=make("ScrollingFrame",shell,{BackgroundTransparency=1,BorderSizePixel=0,
 ScrollBarThickness=4,ScrollBarImageColor3=C.blue,CanvasSize=UDim2.new(),
 AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollingDirection=Enum.ScrollingDirection.Y})
pad(body,12)
list(body,8)
local pageHead=make("Frame",body,{BackgroundTransparency=1,Size=UDim2.new(1,0,0,46),LayoutOrder=1})
local heading=text(pageHead,"Dashboard",23)
heading.Font=Enum.Font.GothamBold
heading.Size=UDim2.new(1,0,0,30)
heading.LayoutOrder=1
local subtitle=text(pageHead,"Design preview / no gameplay actions",13,C.muted)
subtitle.Position=UDim2.fromOffset(0,27)
subtitle.Size=UDim2.new(1,0,0,19)
local stats=make("Frame",body,{BackgroundTransparency=1,Size=UDim2.new(1,0,0,64),LayoutOrder=3})
local statCards={}
for i,info in ipairs({{"Session","Preview"},{"Active now","—"},{"Status","UI only"}}) do
 local card=frame(stats)
 card.Size=UDim2.new(1/3,-6,1,0)
 card.Position=UDim2.new((i-1)/3, (i-1)*3,0,0)
 icon(card,i==1 and "clock" or i==2 and "user" or "Automation",10,21,22,i==3 and C.green or C.muted)
 local label=text(card,info[1],12,C.muted)
 label.Position=UDim2.fromOffset(42,8)
 label.Size=UDim2.new(1,-48,0,20)
 local value=text(card,info[2],20,i==3 and C.green or C.text)
 value.Position=UDim2.fromOffset(42,29)
 value.Size=UDim2.new(1,-48,0,24)
 value.Font=Enum.Font.GothamBold
 statCards[i]=card
end
local welcome=frame(body,C.blue)
welcome.LayoutOrder=4
welcome.Size=UDim2.new(1,0,0,46)
icon(welcome,"star",12,12,22,C.text)
local welcomeText=text(welcome,"Welcome back. Make yourself at home.",14)
welcomeText.Position=UDim2.fromOffset(44,6)
welcomeText.Size=UDim2.new(1,-56,1,-12)
local columns=make("Frame",body,{Name="Columns",BackgroundTransparency=1,Size=UDim2.new(1,0,0,294),LayoutOrder=5})
local controls=frame(columns)
controls.LayoutOrder=5
controls.AutomaticSize=Enum.AutomaticSize.Y
controls.Size=UDim2.new(1,0,0,0)
pad(controls,12)
list(controls,4)
local controlTitle=text(controls,"Quick settings",17)
controlTitle.Font=Enum.Font.GothamBold
local rowOrder=0
local function row(label,height)
 rowOrder=rowOrder+1
 local r=make("Frame",controls,{BackgroundTransparency=1,Size=UDim2.new(1,0,0,height or 36),LayoutOrder=rowOrder})
 local l=text(r,label,14)
 l.Size=UDim2.new(1,-120,1,0)
 return r
end
local function toggle(label,initial,callback)
 local r=row(label)
 local b=button(r,"")
 b.Size=UDim2.fromOffset(44,24)
 b.Position=UDim2.new(1,-44,0.5,-12)
 round(b,14)
 local knob=make("Frame",b,{Size=UDim2.fromOffset(18,18),BackgroundColor3=C.text,BorderSizePixel=0})
 round(knob,11)
 local value=initial
 local function paint()
  b.BackgroundColor3=value and C.bright or C.line
  knob.Position=UDim2.fromOffset(value and 23 or 3,3)
 end
 paint()
 on(b.Activated,function() value=not value paint() if callback then callback(value) end end)
end
toggle("Auto collect (demo)",true)
toggle("Auto sell (demo)",false)

local dropRow=row("Effects")
local drop=button(dropRow,"Reduced")
drop.Size=UDim2.fromOffset(114,34)
drop.Position=UDim2.new(1,-114,0.5,-17)
icon(drop,"down",92,9,16)
local choices=make("Frame",controls,{BackgroundTransparency=1,Size=UDim2.new(1,0,0,84),Visible=false,LayoutOrder=rowOrder+1})
rowOrder=rowOrder+1
list(choices,6)
for _,label in ipairs({"Reduced","Standard"}) do
 local b=button(choices,label)
 b.Size=UDim2.new(1,0,0,38)
 on(b.Activated,function() drop.Text=label choices.Visible=false end)
end
on(drop.Activated,function() choices.Visible=not choices.Visible end)
local sliderRow=row("Accent intensity",48)
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
local updates=frame(columns)
updates.LayoutOrder=6
updates.Size=UDim2.new(1,0,0,294)
pad(updates,14)
local upd=text(updates,"What's new",17)
upd.Font=Enum.Font.GothamBold
local updateRows={}
for i,info in ipairs({{"New blue theme","Calmer colors, finer borders."},{"Compact navigation","More room for your controls."},{"Mobile layout","Cards stack without tiny text."}}) do
 local item=make("Frame",updates,{BackgroundTransparency=1,Position=UDim2.fromOffset(0,32+(i-1)*58),Size=UDim2.new(1,0,0,58)})
 icon(item,"doc",0,8,20)
 local a=text(item,info[1],14) a.Font=Enum.Font.GothamMedium a.Position=UDim2.fromOffset(30,0) a.Size=UDim2.new(1,-30,0,24)
 local b=text(item,info[2],13,C.muted) b.Position=UDim2.fromOffset(30,24) b.Size=UDim2.new(1,-30,0,30)
 updateRows[i]=item
end
local community=frame(body)
community.LayoutOrder=6 community.Size=UDim2.new(1,0,0,54)
icon(community,"user",12,15,22)
local communityTitle=text(community,"Community",14) communityTitle.Position=UDim2.fromOffset(44,5) communityTitle.Size=UDim2.new(1,-174,0,22)
local communitySub=text(community,"News and updates",13,C.muted) communitySub.Position=UDim2.fromOffset(44,26) communitySub.Size=UDim2.new(1,-174,0,20)
local notice=frame(shell,C.panel)
notice.Visible=false
notice.ZIndex=10
local nt=text(notice,"Serenity preview",14)
nt.ZIndex=11
nt.Position=UDim2.fromOffset(12,6)
nt.Size=UDim2.new(1,-50,0,24)
local nb=text(notice,"Notification placement test.",12,C.muted)
nb.ZIndex=11
nb.Position=UDim2.fromOffset(12,31)
nb.Size=UDim2.new(1,-24,0,30)
local nx=button(notice,"")
icon(nx,"close",5,5,18)
nx.ZIndex=12
nx.Size=UDim2.fromOffset(28,28)
nx.Position=UDim2.new(1,-34,0,5)
on(nx.Activated,function() notice.Visible=false end)
local test=button(community,"Test notice")
test.LayoutOrder=7
test.Size=UDim2.fromOffset(102,32)
test.Position=UDim2.new(1,-112,0,11)
on(test.Activated,function() notice.Visible=not notice.Visible end)
local inventoryInfo=frame(body)
inventoryInfo.LayoutOrder=5 inventoryInfo.Size=UDim2.new(1,0,0,116) inventoryInfo.Visible=false
pad(inventoryInfo,16)
local inventoryTitle=text(inventoryInfo,"Inventory preview",18) inventoryTitle.Font=Enum.Font.GothamBold
local inventoryDesc=text(inventoryInfo,"This isolated UI test does not read or modify your items. Use Dashboard to compare the same controls in each font.",14,C.muted)
inventoryDesc.Position=UDim2.fromOffset(0,32) inventoryDesc.Size=UDim2.new(1,0,0,64)
local fontBar=frame(body)
fontBar.Name="FontComparison" fontBar.LayoutOrder=2 fontBar.Size=UDim2.new(1,0,0,72)
local fontStatus=text(fontBar,"Compare fonts: A / Builder Sans",12,C.muted)
fontStatus.Position=UDim2.fromOffset(10,5) fontStatus.Size=UDim2.new(1,-20,0,20)
local fontOptions={
 {label="A: Builder",name="Builder Sans",family="BuilderSans"},
 {label="B: Source",name="Source Sans Pro",family="SourceSansPro"},
 {label="C: Roboto",name="Roboto",family="Roboto"}
}
local fontButtons={}
for i,option in ipairs(fontOptions) do
 local b=button(fontBar,option.label)
 b.Position=UDim2.new((i-1)/3,6,0,30) b.Size=UDim2.new(1/3,-12,0,34)
 fontButtons[i]=b
end
local navButtons={}
local navIcons={}
local selected="Dashboard"
local arrangeColumns
local navLabels={}
for _,name in ipairs({"About","Dashboard","Automation","Inventory","Settings"}) do
 local b=button(nav,name)
 b.TextXAlignment=Enum.TextXAlignment.Left
 navIcons[name]=icon(b,name,10,10,18)
 b.Text=""
 local caption=text(b,name,14)
 caption.Position=UDim2.fromOffset(38,0) caption.Size=UDim2.new(1,-44,1,0)
 navLabels[name]=caption
 navButtons[name]=b
 on(b.Activated,function()
  selected=name
  stats.Visible=name=="Dashboard" or name=="About"
  welcome.Visible=name=="Dashboard" or name=="About"
  columns.Visible=name~="Inventory"
  test.Visible=true
  controls.Visible=name~="About"
  updates.Visible=name=="Dashboard" or name=="About"
  community.Visible=name=="Dashboard" or name=="About"
  inventoryInfo.Visible=name=="Inventory"
  heading.Text=name
  if arrangeColumns then arrangeColumns() end
  subtitle.Text=name=="Dashboard" and "Design preview / no gameplay actions" or name.." layout preview • No gameplay actions"
  for n,other in pairs(navButtons) do other.BackgroundColor3=n==name and C.blue or C.side end
  body.CanvasPosition=Vector2.new(0,0)
 end)
 b.BackgroundColor3=name=="Dashboard" and C.blue or C.side
end
local minimized=false
local function layout()
 local vp=gui.AbsoluteSize
 if vp.X<1 or vp.Y<1 then vp=workspace.CurrentCamera.ViewportSize end
 local w=math.min(820,math.floor(vp.X*0.84))
 if vp.X<600 then w=vp.X-24 end
 local h=math.min(580,math.floor(vp.Y*0.84))
 local narrow=w<620
 local compactNav=w<700
 local sideWidth=compactNav and 52 or 146
 shell.Size=UDim2.fromOffset(w,minimized and 48 or h)
 sidebar.Visible=not minimized body.Visible=not minimized
 sidebar.Position=UDim2.fromOffset(0,48) sidebar.Size=UDim2.new(0,sideWidth,1,-48)
 nav.Size=UDim2.new(1,0,1,-44)
 navLayout.FillDirection=Enum.FillDirection.Vertical navLayout.Padding=UDim.new(0,5)
 foot.Visible=not compactNav
 for name,b in pairs(navButtons) do
  b.Size=UDim2.new(1,0,0,38) b.Text=""
  navLabels[name].Visible=not compactNav
  navIcons[name].Position=UDim2.fromOffset(compactNav and 9 or 10,10)
 end
 body.Position=UDim2.fromOffset(sideWidth,48) body.Size=UDim2.new(1,-sideWidth,1,-48)
 if arrangeColumns then arrangeColumns() end
 for i,card in ipairs(statCards) do
  card.Position=UDim2.new((i-1)/3,2,0,0) card.Size=UDim2.new(1/3,-6,1,0)
  for _,child in ipairs(card:GetChildren()) do
   if child:IsA("TextLabel") then child.Position=UDim2.fromOffset(narrow and 8 or 42,child.Position.Y.Offset) child.Size=UDim2.new(1,narrow and -16 or -48,0,child.Size.Y.Offset) end
   if child.Name:sub(1,5)=="Icon_" then child.Visible=not narrow end
  end
 end
 notice.Size=UDim2.fromOffset(math.min(260,w-24),70)
 notice.Position=UDim2.new(1,-12,0,58) notice.AnchorPoint=Vector2.new(1,0)
 if minimized then notice.Visible=false end
 title.TextSize=w<400 and 16 or 19
 shell.Position=UDim2.fromScale(.5,.5)
end
arrangeColumns=function()
 local stacked=shell.Size.X.Offset<700
 local ch=math.max(232,controls.AbsoluteSize.Y)
 local dashboard=selected=="Dashboard"
 controls.Size=UDim2.new((stacked or not dashboard) and 1 or .59,(stacked or not dashboard) and 0 or -5,0,0)
 controls.Position=UDim2.fromOffset(0,0)
 if selected=="About" then
  updates.Position=UDim2.fromOffset(0,0) updates.Size=UDim2.new(1,0,0,244)
  columns.Size=UDim2.new(1,0,0,244)
 elseif dashboard then
  updates.Position=stacked and UDim2.fromOffset(0,ch+10) or UDim2.new(.59,5,0,0)
  updates.Size=UDim2.new(stacked and 1 or .41,stacked and 0 or -5,0,244)
  columns.Size=UDim2.new(1,0,0,stacked and ch+254 or math.max(ch,244))
 else
  columns.Size=UDim2.new(1,0,0,ch)
 end
end
on(controls:GetPropertyChangedSignal("AbsoluteSize"),arrangeColumns)
on(gui:GetPropertyChangedSignal("AbsoluteSize"),layout)
on(mini.Activated,function() minimized=not minimized layout() end)
-- Drag only from the title area, with mouse/touch tracking and viewport bounds.
local dragInput,dragStart,windowStart
local function startDrag(input)
 if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
  dragInput=input dragStart=input.Position windowStart=shell.AbsolutePosition
 end
end
header.Active=true title.Active=true
on(header.InputBegan,startDrag) on(title.InputBegan,startDrag)
on(UIS.InputChanged,function(input)
 if not dragInput then return end
 if input~=dragInput and not (dragInput.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseMovement) then return end
 local dx,dy=input.Position.X-dragStart.X,input.Position.Y-dragStart.Y
 local sz=shell.AbsoluteSize local vp=gui.AbsoluteSize
 local x=math.clamp(windowStart.X+dx,0,math.max(0,vp.X-sz.X))
 local y=math.clamp(windowStart.Y+dy,0,math.max(0,vp.Y-sz.Y))
 shell.Position=UDim2.fromOffset(x+sz.X/2,y+sz.Y/2)
end)
on(UIS.InputEnded,function(input) if input==dragInput then dragInput=nil end end)
local cameraConnection=nil
local function watchCamera()
 if cameraConnection then cameraConnection:Disconnect() end
 if workspace.CurrentCamera then cameraConnection=on(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"),layout) end
 layout()
end
on(workspace:GetPropertyChangedSignal("CurrentCamera"),watchCamera)
local fontNodes={}
for _,node in ipairs(gui:GetDescendants()) do
 if node:IsA("TextLabel") or node:IsA("TextButton") then
  local weight=Enum.FontWeight.Regular
  if node.Font==Enum.Font.GothamBold then weight=Enum.FontWeight.Bold
  elseif node.Font==Enum.Font.GothamMedium or node.ClassName=="TextButton" then weight=Enum.FontWeight.Medium end
  if node~=title then fontNodes[#fontNodes+1]={node=node,weight=weight} end
 end
end
local function chooseFont(index)
 local option=fontOptions[index]
 local failed=false
 for _,entry in ipairs(fontNodes) do
  local ok=pcall(function()
   entry.node.FontFace=Font.new("rbxasset://fonts/families/"..option.family..".json",entry.weight,Enum.FontStyle.Normal)
  end)
  if not ok then failed=true end
 end
 fontStatus.Text=failed and "Font unavailable on this client" or ("Selected: "..string.char(64+index).." / "..option.name)
 for i,b in ipairs(fontButtons) do b.BackgroundColor3=i==index and C.blue or C.side end
end
pcall(function() title.FontFace=Font.new("rbxasset://fonts/families/AccanthisADFStd.json",Enum.FontWeight.Regular,Enum.FontStyle.Normal) end)
for i,b in ipairs(fontButtons) do on(b.Activated,function() chooseFont(i) end) end
chooseFont(1)
watchCamera()
return {Destroy=cleanup}

