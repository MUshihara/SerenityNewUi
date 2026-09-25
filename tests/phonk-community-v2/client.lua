-- Isolated Phonk community test. Adapted API contract from TripNation/announcement.
-- Manual test only: never referenced by Serenity's production loader or UI.
return function(Core,Bridge)
if game.PlaceId~=104809044319701 and game.GameId~=10544327471 then
    warn("[Serenity test] Open +1 Phonk Evolution to test this module.")
    return
end
local env=(getgenv and getgenv()) or _G
local prior=env.__SERENITY_PHONK_COMMUNITY_TEST
if prior and prior.Stop then prior:Stop() end
local http=game:GetService("HttpService")
local players=game:GetService("Players")
local player=players.LocalPlayer
local send=request or http_request or (syn and syn.request) or (type(env.http)=="table" and env.http.request)
if not player or type(send)~="function" then warn("[Serenity test] HTTP request support is required.");return end
local S={Stopped=false,threads={},connections={},opened=false,muted=false,banned=false,globalMuted=false}
env.__SERENITY_PHONK_COMMUNITY_TEST=S
env.__SERENITY_COMMUNITY_SEEN=env.__SERENITY_COMMUNITY_SEEN or {}
local seen=env.__SERENITY_COMMUNITY_SEEN
local function connect(signal,fn) local c=signal:Connect(fn);S.connections[#S.connections+1]=c;return c end
local function spawn(fn)
    local thread
    thread=task.defer(function() local ok,e=pcall(fn);S.threads[coroutine.running()]=nil;if not ok and not S.Stopped then warn("[Serenity community test] "..tostring(e)) end end)
    S.threads[thread]=true
    return thread
end
function S:Stop()
    if self.Stopped then return end
    self.Stopped=true
    for _,c in ipairs(self.connections) do pcall(function() c:Disconnect() end) end
    for t in pairs(self.threads) do if t~=coroutine.running() then pcall(task.cancel,t) end end
    if self.bridge then pcall(self.bridge.Stop) end
    if self.gui then self.gui:Destroy() end
    if env.__SERENITY_PHONK_COMMUNITY_TEST==self then env.__SERENITY_PHONK_COMMUNITY_TEST=nil end
end
local parent
pcall(function() parent=(gethui and gethui()) or game:GetService("CoreGui") end)
parent=parent or player:WaitForChild("PlayerGui")
local host=Bridge.Find(parent)
if not host then error("Run the official Serenity loader in Phonk first, then this test loader.") end
local function make(class,props,parentObject)
    local o=Instance.new(class)
    for k,v in pairs(props) do o[k]=v end
    o.Parent=parentObject
    return o
end
local gui=make("ScreenGui",{Name="SerenityPhonkCommunityTest",ResetOnSpawn=false,DisplayOrder=1000001,IgnoreGuiInset=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},parent)
S.gui=gui
local bg=Color3.fromRGB(18,18,25)
local white=Color3.fromRGB(238,238,245)
local muted=Color3.fromRGB(159,161,181)
local orange=Color3.fromRGB(255,178,83)
local function corner(o,n) make("UICorner",{CornerRadius=UDim.new(0,n or 10)},o) end
local function label(parentObject,text,pos,size,color,fontSize)
    return make("TextLabel",{Text=text,Position=pos,Size=size,BackgroundTransparency=1,TextColor3=color or white,Font=Enum.Font.Gotham,TextSize=fontSize or 13,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true},parentObject)
end
local function button(parentObject,text,pos,size)
    local b=make("TextButton",{Text=text,Position=pos,Size=size,BackgroundColor3=Color3.fromRGB(40,39,54),TextColor3=white,Font=Enum.Font.Gotham,TextSize=13,AutoButtonColor=true,BorderSizePixel=0},parentObject)
    corner(b,8);return b
end
-- One compact top-center banner. Warnings take priority over announcements.
local TextService=game:GetService("TextService")
local banner=make("Frame",{AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,12),Size=UDim2.fromOffset(420,76),BackgroundColor3=bg,BorderSizePixel=0,Visible=false},gui)
corner(banner)
local border=make("UIStroke",{Color=orange,Thickness=1},banner)
local title=label(banner,"",UDim2.fromOffset(48,8),UDim2.new(1,-100,0,22),orange,14)
title.Font=Enum.Font.GothamBold
local message=label(banner,"",UDim2.fromOffset(48,31),UDim2.new(1,-100,1,-43),white,13)
message.TextYAlignment=Enum.TextYAlignment.Top
message.TextTruncate=Enum.TextTruncate.AtEnd
local mark=label(banner,"i",UDim2.fromOffset(10,12),UDim2.fromOffset(28,28),orange,19)
mark.TextXAlignment=Enum.TextXAlignment.Center;mark.Font=Enum.Font.GothamBold
local accent=make("Frame",{Position=UDim2.fromOffset(0,10),Size=UDim2.new(0,3,1,-20),BackgroundColor3=orange,BorderSizePixel=0},banner)
corner(accent,2)
local progress=make("Frame",{Position=UDim2.new(0,12,1,-4),Size=UDim2.new(1,-24,0,2),BackgroundColor3=orange,BorderSizePixel=0},banner)
local countdown=label(banner,"",UDim2.new(1,-39,0,40),UDim2.fromOffset(28,18),muted,10)
local function fitBanner()
    local camera=workspace.CurrentCamera
    local width=math.min(420,math.max(200,(camera and camera.ViewportSize.X or 440)-24))
    local bounds=TextService:GetTextSize(message.Text,13,Enum.Font.Gotham,Vector2.new(width-100,1000))
    banner.Size=UDim2.fromOffset(width,math.max(72,math.min(150,bounds.Y+48)))
end
local dismiss=button(banner,"X",UDim2.new(1,-40,0,6),UDim2.fromOffset(34,30))
local noticeQueue,current={},nil
local function notify(heading,text,duration,warning)
    local item={heading=heading,text=tostring(text or ""),duration=Core.Duration(duration),warning=warning}
    if warning then table.insert(noticeQueue,1,item);current=nil;banner.Visible=false else noticeQueue[#noticeQueue+1]=item end
    if #noticeQueue>5 then table.remove(noticeQueue) end
end
connect(dismiss.Activated,function() current=nil;banner.Visible=false end)
spawn(function()
    while not S.Stopped do
        if current then
            local remaining=math.max(0,current.untilTime-os.clock())
            progress.Size=UDim2.new(remaining/current.duration,-24*(remaining/current.duration),0,2)
            countdown.Text=tostring(math.ceil(remaining)).."s"
        end
        if current and os.clock()>=current.untilTime then current=nil;banner.Visible=false end
        if not current and #noticeQueue>0 then
            current=table.remove(noticeQueue,1);current.untilTime=os.clock()+current.duration
            title.Text=current.heading;message.Text=current.text
            title.TextColor3=current.warning and orange or Color3.fromRGB(183,160,239)
            border.Color=title.TextColor3;accent.BackgroundColor3=title.TextColor3;progress.BackgroundColor3=title.TextColor3;mark.TextColor3=title.TextColor3;mark.Text=current.warning and "!" or "i";fitBanner();banner.Visible=true
        end
        task.wait(.2)
    end
end)
local panel=make("Frame",{AnchorPoint=Vector2.new(1,1),Position=UDim2.new(1,-12,1,-56),Size=UDim2.fromOffset(440,400),BackgroundColor3=bg,BorderSizePixel=0,Visible=false},gui)
corner(panel)
local purple=Color3.fromRGB(187,151,242)
make("UIStroke",{Color=Color3.fromRGB(47,48,64),Thickness=1},panel)
local network=label(panel,"○  Community",UDim2.fromOffset(12,8),UDim2.new(1,-172,0,24),Color3.fromRGB(105,219,169),13)
network.Font=Enum.Font.GothamBold
local close=button(panel,"About",UDim2.new(1,-64,0,6),UDim2.fromOffset(54,28))
local stop=button(panel,"Stop test",UDim2.new(1,-152,0,6),UDim2.fromOffset(80,28))
local search=make("TextBox",{Name="ChatSearch",Position=UDim2.fromOffset(12,42),Size=UDim2.new(1,-150,0,30),Text="",PlaceholderText="Search messages or users…",ClearTextOnFocus=false,BackgroundColor3=Color3.fromRGB(25,26,36),TextColor3=white,PlaceholderColor3=muted,TextSize=12,Font=Enum.Font.Gotham,BorderSizePixel=0,TextXAlignment=Enum.TextXAlignment.Left},panel)
corner(search,6);make("UIPadding",{PaddingLeft=UDim.new(0,10)},search)
local preview=button(panel,"Test warning",UDim2.new(1,-128,0,42),UDim2.fromOffset(116,30))
local tabs=make("ScrollingFrame",{Name="LanguageTabs",Position=UDim2.fromOffset(12,82),Size=UDim2.new(1,-24,0,38),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=2,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.X,ScrollingDirection=Enum.ScrollingDirection.X},panel)
make("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder},tabs)
local status=label(panel,"Choose a language · Open chat to connect",UDim2.fromOffset(12,124),UDim2.new(1,-24,0,24),muted,11)
local scroll=make("ScrollingFrame",{Name="MessageFeed",Position=UDim2.fromOffset(12,154),Size=UDim2.new(1,-24,1,-211),BackgroundColor3=Color3.fromRGB(13,14,21),BackgroundTransparency=0,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=Color3.fromRGB(71,73,95),CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y},panel)
corner(scroll,8);make("UIPadding",{PaddingTop=UDim.new(0,10),PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,8),PaddingBottom=UDim.new(0,10)},scroll)
make("UIListLayout",{Padding=UDim.new(0,12),SortOrder=Enum.SortOrder.LayoutOrder},scroll)
local input=make("TextBox",{Position=UDim2.new(0,12,1,-45),Size=UDim2.new(1,-94,0,34),Text="",PlaceholderText="Message the live global chat…",ClearTextOnFocus=false,BackgroundColor3=Color3.fromRGB(30,30,41),TextColor3=white,PlaceholderColor3=muted,TextSize=13,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,BorderSizePixel=0},panel)
corner(input,7)
make("UIPadding",{PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,8)},input)
local sendButton=button(panel,"Send",UDim2.new(1,-74,1,-45),UDim2.fromOffset(62,34))
sendButton.BackgroundColor3=Color3.fromRGB(229,223,247);sendButton.TextColor3=Color3.fromRGB(29,23,44);sendButton.Font=Enum.Font.GothamBold
local function resize() fitBanner() end
local cameraConnection
local function watchCamera()
    if cameraConnection then cameraConnection:Disconnect() end
    if workspace.CurrentCamera then cameraConnection=connect(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"),resize) end
    resize()
end
connect(workspace:GetPropertyChangedSignal("CurrentCamera"),watchCamera);watchCamera()
S.bridge=Bridge.Attach(host,panel,connect,function(open) S.opened=open end)
connect(host.Screen.Destroying,function()S:Stop()end)
connect(close.Activated,function()S.bridge.Close()end)
connect(stop.Activated,function() S:Stop() end)
connect(preview.Activated,function() notify("Community warning · Preview","Please keep the chat respectful. This preview is visible only to you.",8,true) end)
local rooms={{"English","en","General"},{"spanish","es","Spanish"},{"indonesian","id","Indonesian"},{"philippines","fil","Filipino"},{"vietnam","vi","Vietnamese"},{"brazilian","pt","Portuguese"}}
local roomIndex=1
local messages,ids,cursor={}, {},0
local function render(force)
    local lang=rooms[roomIndex][2]
    local query=search.Text:lower()
    local nearBottom=scroll.CanvasPosition.Y>=math.max(0,scroll.AbsoluteCanvasSize.Y-scroll.AbsoluteSize.Y-60)
    local position=scroll.CanvasPosition
    for _,child in ipairs(scroll:GetChildren()) do if child.Name=="MessageRow" or child.Name=="ChatEmpty" then child:Destroy() end end
    local shown=0
    for i,m in ipairs(messages) do
        local text=tostring(m.message or "")
        local translated=false
        if type(m.translations)=="table" and type(m.translations[lang])=="string" and m.translations[lang]~="" then
            translated=m.translations[lang]~=text;text=m.translations[lang]
        end
        local name=tostring(m.displayName or m.username or "User")
        local gameName=tostring(m.gameName or "Global")
        if query=="" or (name.." "..gameName.." "..text):lower():find(query,1,true) then
            shown=shown+1
            local width=math.max(100,scroll.AbsoluteSize.X-78)
            local bounds=TextService:GetTextSize(text,13,Enum.Font.Gotham,Vector2.new(width,10000))
            local height=math.max(56,bounds.Y+40)
            local row=make("Frame",{Name="MessageRow",Size=UDim2.new(1,-4,0,height),BackgroundTransparency=1,LayoutOrder=i},scroll)
            local uid=tonumber(m.userId)
            local image=(uid and uid>0) and ("rbxthumb://type=AvatarHeadShot&id="..string.format("%.0f",uid).."&w=48&h=48") or "rbxassetid://10709790644"
            local avatar=make("ImageLabel",{Size=UDim2.fromOffset(30,30),Position=UDim2.fromOffset(0,2),BackgroundColor3=Color3.fromRGB(26,29,41),Image=image,BorderSizePixel=0},row)
            corner(avatar,15);make("UIStroke",{Color=Color3.fromRGB(54,58,79),Thickness=1},avatar)
            local role=m.system==true and "SYSTEM" or tostring(m.role or ""):upper()
            if role~="OWNER" and role~="ADMIN" and role~="DEV" and role~="SYSTEM" then role="" end
            local roleColor=role=="SYSTEM" and "#FFC061" or role=="OWNER" and "#F4CE67" or role=="ADMIN" and "#6BCCF2" or "#C59AF3"
            local badge=role~="" and ('<font color="'..roleColor..'"><b>['..role..']</b></font>  ') or ""
            local header=label(row,badge..'<font color="#C5A4F4"><b>'..Core.Escape(name)..'</b></font>',UDim2.fromOffset(40,0),UDim2.new(1,-42,0,18),white,12)
            header.RichText=true;header.TextWrapped=false;header.TextTruncate=Enum.TextTruncate.AtEnd
            local meta=gameName..(m.time and (' · '..tostring(m.time)) or '')..(translated and ' · translated' or '')
            local details=label(row,meta,UDim2.fromOffset(40,18),UDim2.new(1,-42,0,16),translated and Color3.fromRGB(104,189,218) or muted,10)
            details.TextWrapped=false;details.TextTruncate=Enum.TextTruncate.AtEnd
            local body=label(row,text,UDim2.fromOffset(40,36),UDim2.new(1,-42,0,bounds.Y+2),white,13)
            body.TextYAlignment=Enum.TextYAlignment.Top
        end
    end
    if shown==0 then
        local empty=label(scroll,query~="" and "No matching messages" or "No messages yet. Start the conversation.",UDim2.new(),UDim2.new(1,-12,0,50),muted,13);empty.Name="ChatEmpty"
    end
    spawn(function()
        task.wait()
        if not S.Stopped and scroll.Parent then
            scroll.CanvasPosition=(nearBottom or force) and Vector2.new(0,math.max(0,scroll.AbsoluteCanvasSize.Y-scroll.AbsoluteSize.Y)) or position
        end
    end)
end
local roomButtons={}
local function selectRoom(index)
    roomIndex=index
    for i,b in ipairs(roomButtons) do
        b.BackgroundColor3=i==index and Color3.fromRGB(63,49,86) or Color3.fromRGB(27,28,39)
        b.TextColor3=i==index and white or muted
        b.Font=i==index and Enum.Font.GothamBold or Enum.Font.Gotham
    end
    input.PlaceholderText="Message · "..rooms[index][3]
    render(true)
end
for i,spec in ipairs(rooms) do
    local b=button(tabs,spec[3],UDim2.new(),UDim2.fromOffset(math.max(76,#spec[3]*7+22),30))
    b.Name="Language_"..spec[2];b.LayoutOrder=i;roomButtons[i]=b
    connect(b.Activated,function()selectRoom(i)end)
end
connect(search:GetPropertyChangedSignal("Text"),function()render(true)end)
connect(scroll:GetPropertyChangedSignal("AbsoluteSize"),function()if S.opened then render(false)end end)
selectRoom(1)
local BASE="https://serenityhub.site/api"
local function api(path,body)
    if S.Stopped then return nil end
    local ok,response=pcall(send,{Url=BASE..path,Method=body and "POST" or "GET",Headers={["Content-Type"]="application/json"},Body=body and http:JSONEncode(body) or nil,Timeout=10})
    if S.Stopped then return nil end
    if not ok or type(response)~="table" then return nil end
    local code=tonumber(response.StatusCode or response.Status)
    local decoded,data=pcall(http.JSONDecode,http,response.Body or response.body or "")
    if not decoded or type(data)~="table" then return nil,code end
    return data,code
end
local function moderation()
    local d,code=api("/moderation/status?userId="..tostring(player.UserId))
    if not d or not Core.Status(code) or d.success~=true then return false end
    S.muted=d.isMuted==true;S.banned=d.isBanned==true
    if S.banned then
        if Core.Remember(seen,"chat-ban:"..player.UserId,os.time()) then notify("Chat access restricted","Contact staff to appeal. Your game and other Serenity features remain available.",10,true) end
    end
    local key=Core.WarningKey(d.warning)
    if key and Core.Remember(seen,key,os.time()) then notify("Community warning",d.warning.message,8,true) end
    return true
end
local nextMod=0
spawn(function()
    local delay=4
    while not S.Stopped do
        if S.opened then
            if os.clock()>=nextMod then moderation();nextMod=os.clock()+15 end
            if not S.banned then
                local data,code=api("/chat/messages?after="..cursor.."&limit=100")
                if data and Core.Status(code) and data.success==true and type(data.messages)=="table" then
                    delay=4;S.globalMuted=data.isChatMuted==true
                    network.Text=S.globalMuted and "●  Chat muted" or "●  Live Network";network.TextColor3=S.globalMuted and orange or Color3.fromRGB(105,219,169)
                    if data.cleared then messages={};ids={};cursor=0 end
                    local changed=data.cleared==true
                    for _,m in ipairs(data.messages) do
                        local id=tonumber(m.id)
                        if id and id>=0 and id==math.floor(id) and not ids[id] then
                            ids[id]=true;cursor=math.max(cursor,id);messages[#messages+1]=m;changed=true
                        end
                    end
                    table.sort(messages,function(a,b)return tonumber(a.id)<tonumber(b.id) end)
                    while #messages>100 do local old=table.remove(messages,1);ids[tonumber(old.id)]=nil end
                    if changed then render() end
                    status.Text=(S.muted or S.globalMuted) and "Chat muted · You can still read messages." or "Live chat · Sends are visible to other users."
                else
                    network.Text="○  Reconnecting";network.TextColor3=muted
                    delay=math.min(delay*2,60);status.Text="Chat unavailable · Retrying automatically."
                end
            else status.Text="Chat access restricted · Contact staff." end
            task.wait(delay)
        else task.wait(1) end
    end
end)
local sending,lastSend=false,-math.huge
local function sendMessage()
    if sending or S.Stopped or os.clock()-lastSend<3 then return end
    local text=input.Text:match("^%s*(.-)%s*$")
    if text=="" then return end
    local n=utf8.len(text)
    if not n or n>200 then notify("Message too long","Use 200 characters or fewer.",5,true);return end
    sending=true;lastSend=os.clock();sendButton.Text="…"
    spawn(function()
        local verified=moderation()
        if not verified then status.Text="Unable to check chat permissions. Try again."
        elseif S.banned or S.muted or S.globalMuted then notify("Chat unavailable","Your account or the global chat is currently restricted.",6,true)
        else
            local d,code=api("/chat/messages",{userId=tostring(player.UserId),username=player.Name,displayName=player.DisplayName,gameName="+1 Phonk Evolution",room=rooms[roomIndex][1],message=text})
            if d and Core.Status(code) and d.success~=false then if input.Text==text then input.Text="" end
            elseif code==403 then notify("Message blocked","Your message was rejected by chat moderation.",6,true)
            elseif code==429 then notify("Please wait","You are sending messages too quickly. Try again shortly.",5,true)
            else status.Text="Message could not be confirmed. Check the feed before retrying." end
        end
        sending=false;if not S.Stopped then sendButton.Text="Send" end
    end)
end
connect(sendButton.Activated,sendMessage)
connect(input.FocusLost,function(enter) if enter then sendMessage() end end)
local categories={announcement="Announcement",update="Update",important="Important",warning="Important",urgent="Urgent",maintenance="Maintenance"}
spawn(function()
    local delay=10
    while not S.Stopped do
        local a,code=api("/announcements/latest")
        if Core.Status(code) then
            delay=10
            if a and a.id and Core.Target(a,game.PlaceId,game.GameId,"+1 Phonk Evolution") then
                local eligible=true
                if a.expiresAt then
                    local ok,expiry=pcall(function() return DateTime.fromIsoDate(tostring(a.expiresAt)).UnixTimestamp end)
                    eligible=ok and expiry>os.time()
                end
                if eligible and Core.Remember(seen,"announcement:"..tostring(a.id),os.time()) then
                    notify("Serenity · "..(categories[tostring(a.type):lower()] or "Announcement"),a.message,a.duration,false)
                end
            end
        else delay=math.min(delay*2,120) end
        task.wait(delay)
    end
end)
notify("SERENITY · TEST CONNECTED","Global Chat is now below About. Only this session uses the test.",6,false)
return S
end
