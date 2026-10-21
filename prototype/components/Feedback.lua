-- Shared, user-submitted reports. No automatic collection or startup sends.
return function(ui,app,parent,options,choice)
    local service=game:GetService('HttpService')
    local relay=options.FeedbackRelay or ((getgenv and getgenv()) or _G).SerenityFeedbackRelay
    if type(relay)~='string' or not relay:match('^https://[%w%.%-]+/') then relay=nil end
    -- Owner-approved public reporting destination. Shared across PC/mobile; not profile data.
    local defaultEndpoint='https://discord.com/api/webhooks/1546188887808938128/TXP6NrlEBnS9HX4lZLRb0_UEUkd8cEJgr-BXz-fOpQ5-O6GuAaV0DiAYSDHQXESydyoo'
    local function valid(url) return type(url)=='string' and url:match('^https://discord%.com/api/webhooks/%d+/[%w_%-]+$')~=nil end
    local endpoint=options.FeedbackWebhook or ((getgenv and getgenv()) or _G).SerenityFeedbackWebhook
    if not valid(endpoint) then endpoint=defaultEndpoint end
    local function length(text) return utf8.len(text) or #text end
    local scroll=ui:New('ScrollingFrame',parent,{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=3})
    ui:List(scroll,10);ui:Pad(scroll,2,2,6,10)
    local function field(title,height)
        local row=ui:Panel(scroll,{Size=UDim2.new(1,0,0,height)})
        ui:Label(row,title,13,UDim2.fromOffset(12,6),UDim2.new(1,-24,0,24),nil,true)
        return row
    end
    local category=choice(scroll,{Title='Report type',Options={'Bug Report','Feedback','New Feature','New Game Request'},Default='Bug Report'},false)
    local draft=field('Bug report or feedback',202)
    local box=ui:New('TextBox',draft,{Position=UDim2.fromOffset(12,36),Size=UDim2.new(1,-24,0,128),Text='',PlaceholderText='What happened? What did you expect? Include steps to reproduce.',MultiLine=true,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,ClearTextOnFocus=false,Font=ui.T.Font,TextSize=13,TextColor3=ui.T.Text,BackgroundColor3=ui.T.Inset,BorderSizePixel=0})
    ui:Round(box,6);ui:Pad(box,8)
    local count=ui:Label(draft,'0 / 1800 characters',11,UDim2.fromOffset(12,174),UDim2.new(1,-24,0,18),ui.T.Muted)
    ui.R:Connect(box:GetPropertyChangedSignal('Text'),function()
        count.Text=tostring(length(box.Text))..' / 1800 characters'
        count.TextColor3=length(box.Text)>1800 and ui.T.Accent or ui.T.Muted
    end)
    local context=field('Included with your report',108)
    ui:Label(context,'Game: '..tostring(options.Manifest and options.Manifest.GameName or app.GameTitle.Text)..'\nPlace: '..tostring(game.PlaceId)..'\nServer Job ID and preview version. No profile settings.',11,UDim2.fromOffset(12,34),UDim2.new(1,-24,0,66),ui.T.Muted).TextWrapped=true
    local configured=relay or valid(endpoint)
    local status=ui:Label(scroll,configured and 'Sends to Serenity when you press Submit.' or 'Shared reporting is awaiting server setup. Your draft stays here.',12,nil,UDim2.new(1,0,0,36),ui.T.Muted)
    status.TextWrapped=true; status.TextTruncate=Enum.TextTruncate.None
    local busy,last=false,-math.huge
    local button
    local function submit()
        if busy then return end
        if not relay and not valid(endpoint) then status.Text='Serenity’s report server is not connected yet. Your draft is safe.';return end
        local message=box.Text:match('^%s*(.-)%s*$')
        if length(message)<10 or length(message)>1800 then status.Text='Write between 10 and 1800 characters.';return end
        if os.clock()-last<30 then status.Text='Please wait 30 seconds between reports.';return end
        local send
        for _,name in ipairs({'request','http_request'}) do
            local candidate=((getgenv and getgenv()) or _G)[name]
            if type(candidate)=='function' then send=candidate;break end
        end
        send=send or (type(request)=='function' and request) or (type(http_request)=='function' and http_request) or (type(syn)=='table' and type(syn.request)=='function' and syn.request)
        if type(send)~='function' then status.Text='HTTP requests are unavailable on this device.';return end
        busy=true;last=os.clock();button.Text='Sending…';status.Text='Sending your report…'
        local body=service:JSONEncode({allowed_mentions={parse={}},embeds={{title='Serenity · '..category:Get(),description=message,fields={
            {name='Game',value=tostring(options.Manifest and options.Manifest.GameName or app.GameTitle.Text)},
            {name='Place ID',value=tostring(game.PlaceId)},
            {name='Job ID',value=tostring(game.JobId or 'Unavailable')},
            {name='UI build',value='Phonk UI · RC1'},
        }}}})
        task.spawn(function()
            local ok,response=pcall(send,{Url=relay or endpoint,Method='POST',Headers={['Content-Type']='application/json'},Body=body})
            if ui.R.Destroyed then return end
            busy=false;button.Text='Submit report'
            local code=ok and type(response)=='table' and tonumber(response.StatusCode or response.Status)
            if code and code>=200 and code<300 then
                if box.Text:match('^%s*(.-)%s*$')==message then box.Text='' end
                status.Text='Report delivered. Thank you.';app:Notify('Report delivered')
            else
                if code==429 then status.Text='Discord rate limit. Try again later.'
                elseif code==401 or code==403 or code==404 then status.Text='Report destination unavailable. Please tell Serenity staff.'
                else status.Text='Not delivered. Your draft is still here.' end
            end
        end)
    end
    button=ui:Button(scroll,configured and 'Submit report' or 'Reporting unavailable',{Size=UDim2.new(1,0,0,44),BackgroundColor3=ui.T.Accent},submit)
    app.Feedback={Submit=submit,Draft=box,Category=category,Status=status}
end
