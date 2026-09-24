-- Attach a reversible test page to the existing official Phonk UI instance.
-- No hooks, game callback replacement, or changes to production source.
local Bridge={}
function Bridge.Find(root)
    local screen=root:FindFirstChild('SerenityConcept02')
    if not screen then return nil end
    local about=screen:FindFirstChild('About',true)
    if not about or not about:IsA('TextButton') or not about.Parent:IsA('ScrollingFrame') then return nil end
    local nav=about.Parent
    local shell=nav.Parent
    local content,header,best=nil,nil,0
    for _,frame in ipairs(shell:GetChildren()) do
        if frame:IsA('Frame') then
            local count=0
            for _,child in ipairs(frame:GetChildren()) do
                if child:IsA('Frame') and child.Size.X.Scale==1 and child.Size.Y.Scale==1 then count=count+1 end
            end
            if count>best then best=count;content=frame end
            if frame.Active and frame.Position.X.Offset>0 then
                local textCount=0
                for _,c in ipairs(frame:GetChildren()) do if c:IsA('TextLabel')then textCount=textCount+1 end end
                if textCount>=2 then header=frame end
            end
        end
    end
    if not content or best<2 or not header then return nil end
    local heading,description
    for _,c in ipairs(header:GetChildren())do
        if c:IsA('TextLabel')then
            if not heading or c.TextSize>heading.TextSize then description=heading;heading=c else description=c end
        end
    end
    if not heading or not description then return nil end
    return {Screen=screen,Content=content,Nav=nav,About=about,Heading=heading,Description=description,Holder=shell.Parent}
end
function Bridge.Attach(host,panel,connect,onVisibility)
    local entry=host.About:Clone()
    entry.Name='SerenityGlobalChatTest'
    local rowLabel=entry:FindFirstChildWhichIsA('TextLabel')
    assert(rowLabel,'Unsupported Serenity navigation layout')
    rowLabel.Text='Global Chat'
    local icon=entry:FindFirstChildWhichIsA('ImageLabel',true)
    if icon then icon.Visible=false end
    local badge=Instance.new('TextLabel')
    badge.Text='…';badge.Font=Enum.Font.GothamBold;badge.TextSize=22
    badge.BackgroundTransparency=1;badge.TextColor3=Color3.fromRGB(183,160,239)
    badge.Size=UDim2.fromOffset(34,34);badge.Position=UDim2.fromOffset(0,5);badge.Parent=entry
    local tile=entry:FindFirstChildWhichIsA('Frame')
    local baseColor=tile and tile.BackgroundColor3
    local oldOrders={}
    for _,row in ipairs(host.Nav:GetChildren())do
        if row:IsA('GuiButton')then
            oldOrders[row]=row.LayoutOrder
            if row.LayoutOrder>host.About.LayoutOrder then row.LayoutOrder=row.LayoutOrder+1 end
        end
    end
    entry.LayoutOrder=host.About.LayoutOrder+1;entry.Parent=host.Nav
    panel.Parent=host.Content;panel.AnchorPoint=Vector2.new(0,0)
    panel.Position=UDim2.fromOffset(0,0);panel.Size=UDim2.fromScale(1,1);panel.Visible=false
    local selected,suppress=false,false
    local savedPages,savedHeading,savedDescription={}
    local stopped=false
    local function isOpen()return not stopped and selected and host.Holder.Visible and host.Screen.Enabled and host.Screen.Parent~=nil end
    local function update()onVisibility(isOpen())end
    local function deselect(restore)
        if not selected then return end
        selected=false;panel.Visible=false
        if tile then tile.BackgroundColor3=baseColor end
        if restore then
            suppress=true
            for page,visible in pairs(savedPages)do if page.Parent then page.Visible=visible end end
            host.Heading.Text=savedHeading or 'About';host.Description.Text=savedDescription or ''
            suppress=false
        end
        update()
    end
    local function select()
        if stopped or selected then return end
        savedHeading=host.Heading.Text;savedDescription=host.Description.Text;savedPages={}
        suppress=true
        for _,page in ipairs(host.Content:GetChildren())do
            if page:IsA('GuiObject') and page~=panel then savedPages[page]=page.Visible;page.Visible=false end
        end
        host.Heading.Text='Global Chat';host.Description.Text='Community · Phonk test'
        selected=true;panel.Visible=true;suppress=false
        if tile then tile.BackgroundColor3=Color3.fromRGB(119,80,171) end
        update()
    end
    for page in pairs((function()local t={};for _,p in ipairs(host.Content:GetChildren())do if p:IsA('GuiObject')and p~=panel then t[p]=true end end;return t end)())do
        connect(page:GetPropertyChangedSignal('Visible'),function()if not suppress and selected and page.Visible then deselect(false) end end)
    end
    for row in pairs(oldOrders)do connect(row.Activated,function()deselect(false)end)end
    connect(entry.Activated,select)
    connect(host.Holder:GetPropertyChangedSignal('Visible'),update)
    connect(host.Screen:GetPropertyChangedSignal('Enabled'),update)
    local function fit()
        entry.Size=host.About.Size
        local original=host.About:FindFirstChildWhichIsA('TextLabel')
        if original then rowLabel.Position=original.Position;rowLabel.Size=original.Size;rowLabel.TextSize=original.TextSize;rowLabel.TextXAlignment=original.TextXAlignment end
        local originalTile=host.About:FindFirstChildWhichIsA('Frame')
        if tile and originalTile then tile.Position=originalTile.Position;badge.Position=originalTile.Position end
    end
    connect(host.About:GetPropertyChangedSignal('Size'),fit);fit()
    return {Select=select,Close=function()deselect(true)end,Stop=function()
        deselect(true);stopped=true
        for row,order in pairs(oldOrders)do if row.Parent then row.LayoutOrder=order end end
        panel:Destroy();entry:Destroy()
    end}
end
return Bridge
