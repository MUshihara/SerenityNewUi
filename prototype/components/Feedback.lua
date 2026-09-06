-- Shared, user-submitted reports. No automatic collection or startup sends.
return function(ui,app,parent,options)
    local service=game:GetService('HttpService')
    local endpoint=options.FeedbackWebhook or ((getgenv and getgenv()) or _G).SerenityFeedbackWebhook or ''
    local path='SerenityConcept02/feedback-destination.txt'
    if endpoint=='' and type(isfile)=='function' and type(readfile)=='function' then
        pcall(function() if isfile(path) then endpoint=readfile(path) end end)
    end
    local function valid(url) return type(url)=='string' and url:match('^https://discord%.com/api/webhooks/%d+/[%w_%-]+$')~=nil end
    local scroll=ui:New('ScrollingFrame',parent,{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=3})
    ui:List(scroll,10);ui:Pad(scroll,2,2,6,10)
    local function field(title,height)
        local row=ui:Panel(scroll,{Size=UDim2.new(1,0,0,height)})
        ui:Label(row,title,13,UDim2.fromOffset(12,6),UDim2.new(1,-24,0,24),nil,true)
        return row
    end
    local destination=field('Report destination · local setup',86)
    local url=ui:New('TextBox',destination,{Position=UDim2.fromOffset(12,36),Size=UDim2.new(1,-24,0,38),Text='',PlaceholderText=valid(endpoint) and 'Configured on this device' or 'Paste your Discord webhook here',ClearTextOnFocus=false,Font=ui.T.Font,TextSize=12,TextColor3=ui.T.Text,BackgroundColor3=ui.T.Inset,BorderSizePixel=0})
    ui:Round(url,6)
    local draft=field('Bug report or feedback',176)
    local box=ui:New('TextBox',draft,{Position=UDim2.fromOffset(12,36),Size=UDim2.new(1,-24,0,128),Text='',PlaceholderText='What happened? What did you expect? Include steps to reproduce.',MultiLine=true,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,ClearTextOnFocus=false,Font=ui.T.Font,TextSize=13,TextColor3=ui.T.Text,BackgroundColor3=ui.T.Inset,BorderSizePixel=0})
    ui:Round(box,6);ui:Pad(box,8)
    local context=field('Included with your report',108)
    ui:Label(context,'Game: '..tostring(options.Manifest and options.Manifest.GameName or app.GameTitle.Text)..'\nPlace: '..tostring(game.PlaceId)..'\nServer Job ID and preview version. No profile settings.',11,UDim2.fromOffset(12,34),UDim2.new(1,-24,0,66),ui.T.Muted).TextWrapped=true
    local status=ui:Label(scroll,'Sends only when you press Submit.',12,nil,UDim2.new(1,0,0,36),ui.T.Muted)
    local busy,last=false,-math.huge
    local button
    url.FocusLost:Connect(function()
        if url.Text=='' then return end
        if not valid(url.Text) then status.Text='Enter a valid Discord webhook URL.';return end
        endpoint=url.Text;url.Text='';url.PlaceholderText='Configured for this session'
        if type(writefile)=='function' then
            local ok=pcall(function() if type(makefolder)=='function' then pcall(makefolder,'SerenityConcept02') end;writefile(path,endpoint) end)
            if ok then url.PlaceholderText='Configured on this device' end
        end
        status.Text='Destination configured. Nothing sent.'
    end)
    local function submit()
        if busy then return end
        if not valid(endpoint) then status.Text='Configure the report destination first.';return end
        local message=box.Text:match('^%s*(.-)%s*$')
        if #message<10 or #message>1800 then status.Text='Write between 10 and 1800 characters.';return end
        if os.clock()-last<30 then status.Text='Please wait 30 seconds between reports.';return end
        local send=request or http_request or (syn and syn.request)
        if type(send)~='function' then status.Text='HTTP requests are unavailable on this device.';return end
        busy=true;last=os.clock();button.Text='Sending…';status.Text='Sending your report…'
        local body=service:JSONEncode({allowed_mentions={parse={}},embeds={{title='Serenity · User feedback',description=message,fields={
            {name='Game',value=tostring(options.Manifest and options.Manifest.GameName or app.GameTitle.Text)},
            {name='Place ID',value=tostring(game.PlaceId)},
            {name='Job ID',value=tostring(game.JobId or 'Unavailable')},
            {name='UI build',value='Concept 02 · Feedback preview'},
        }}}})
        task.spawn(function()
            local ok,response=pcall(send,{Url=endpoint,Method='POST',Headers={['Content-Type']='application/json'},Body=body})
            if ui.R.Destroyed then return end
            busy=false;button.Text='Submit report'
            local code=ok and type(response)=='table' and tonumber(response.StatusCode or response.Status)
            if code and code>=200 and code<300 then
                if box.Text==message then box.Text='' end
                status.Text='Report delivered. Thank you.';app:Notify('Report delivered')
            else
                status.Text=code==429 and 'Discord rate limit. Try again later.' or 'Not delivered. Your draft is still here.'
            end
        end)
    end
    button=ui:Button(scroll,'Submit report',{Size=UDim2.new(1,0,0,44),BackgroundColor3=ui.T.Accent},submit)
    app.Feedback={Submit=submit,Draft=box,Destination=url,Status=status}
end
