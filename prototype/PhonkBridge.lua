-- Phonk-specific V3 adapter. Not a general production V3 replacement.
local function copy(value)
    if type(value)~='table' then return value end
    local result={};for k,v in pairs(value)do result[k]=copy(v)end;return result
end
return {Build=function(source)
    local env=(getgenv and getgenv()) or _G
    local key='__SERENITY_PHONK_UI_PREVIEW'
    if env[key] then env[key]:Destroy() end
    local manifest=copy(source)
    local pages={}
    local about=copy(M.Manifest.Pages[1]);about.SharedPreview=true;pages[#pages+1]=about
    local icons={Dashboard='layout-dashboard',Automation='bot',PetsTrails='paw-print',Rewards='gift',Performance='gauge',Settings='sliders-horizontal'}
    for _,page in ipairs(manifest.Pages) do
        page.Icon=page.Icon or icons[page.Id] or 'menu'
        if page.Id=='Settings' then
            for _,feature in ipairs(page.Features)do feature.ConfigPage='Settings' end
            page.Id='GameTuning';page.Title='Game Tuning'
        elseif page.Id=='Performance' then page.Title='Misc'
        elseif page.Id=='Dashboard' then page.Title='Game Info' end
        for _,feature in ipairs(page.Features)do
            for i,control in ipairs(feature.Controls)do control.Id=control.Id or ('Info'..i) end
        end
        pages[#pages+1]=page
    end
    local settings=copy(M.Manifest.Pages[#M.Manifest.Pages]);settings.SharedPreview=true;pages[#pages+1]=settings
    manifest.Pages=pages
    local app=M.App(M,{Manifest=manifest,ConfigPath='SerenityConcept02/phonk-preview.json'})
    app.Window=app;app.Adapter={SetLive=function(_,id,value) app:SetLive(id,value) end}
    env[key]=app
    app.Runtime:OnDestroy(function()if env[key]==app then env[key]=nil end end)
    return app
end}
