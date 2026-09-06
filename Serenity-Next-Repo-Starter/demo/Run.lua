-- SERENITY HUB // NEXT UI GLASS LAB M2
-- Visual playground only: no game automation/remotes.

local BASE = "https://raw.githubusercontent.com/MUshihara/SerenityNewUi/main/Serenity-Next-Repo-Starter/"

local function loadModule(path)
    local source = game:HttpGet(BASE .. path)
    local chunk, err = loadstring(source)
    assert(chunk, "Serenity module compile failed: " .. path .. " | " .. tostring(err))
    return chunk()
end

local UserInputService = game:GetService("UserInputService")

local RuntimeClass = loadModule("src/core/Runtime.lua")
local Tokens = loadModule("src/core/Tokens.lua")
local Typography = loadModule("src/core/Typography.lua")
local Motion = loadModule("src/core/Motion.lua")
local Material = loadModule("src/core/Material.lua")
local AcrylicEngine = loadModule("src/core/AcrylicEngine.lua")
local Icons = loadModule("src/core/Icons.lua")
local PopupManagerClass = loadModule("src/core/PopupManager.lua")

local NavItem = loadModule("src/components/NavItem.lua")
local MetricPill = loadModule("src/components/MetricPill.lua")
local GameContext = loadModule("src/components/GameContext.lua")
local SegmentedTabs = loadModule("src/components/SegmentedTabs.lua")
local InfoBanner = loadModule("src/components/InfoBanner.lua")
local Section = loadModule("src/components/Section.lua")
local Toggle = loadModule("src/components/Toggle.lua")
local Slider = loadModule("src/components/Slider.lua")
local Select = loadModule("src/components/Select.lua")
local MultiSelect = loadModule("src/components/MultiSelect.lua")
local Button = loadModule("src/components/Button.lua")
local Status = loadModule("src/components/Status.lua")
local Desktop = loadModule("src/renderers/Desktop.lua")

local G = (getgenv and getgenv()) or _G
local KEY = "__SERENITY_NEW_UI_GLASS_LAB_M2"
if G[KEY] and G[KEY].Destroy then pcall(function() G[KEY]:Destroy() end) end

local runtime = RuntimeClass.new(KEY)
G[KEY] = runtime
runtime:TrackCleanup(function()
    if G[KEY] == runtime then G[KEY] = nil end
end)

local deps = {
    Runtime = runtime,
    Tokens = Tokens,
    Typography = Typography,
    Motion = Motion,
    Material = Material,
    AcrylicEngine = AcrylicEngine,
    Icons = Icons,
    PopupManager = PopupManagerClass.new(),
    UserInputService = UserInputService,
    NavItem = NavItem,
    MetricPill = MetricPill,
    GameContext = GameContext,
}

local app = Desktop.Mount(deps, {
    Title = "SERENITY HUB",
    Subtitle = "NEXT UI · M2 GLASS LAB",
    BlurSize = 3,
})

local about = app:AddPage({Id="About", Title="About", Description="A flatter, calmer glass tool instead of a boxed dashboard.", Icon="about", Accent=Tokens.Color.Accent, Order=1})
local auto = app:AddPage({Id="Automation", Title="Automation", Description="Worker controls with progressive disclosure.", Icon="automation", Accent=Tokens.Color.Mint, Order=2})
local progression = app:AddPage({Id="Progression", Title="Progression", Description="Story, tower, and route controls.", Icon="progression", Accent=Tokens.Color.Lavender, Order=3})
local shop = app:AddPage({Id="Shop", Title="Shop", Description="Purchasing controls with clearer safety states.", Icon="shop", Accent=Tokens.Color.Amber, Order=4})
local server = app:AddPage({Id="Server", Title="Server", Description="Session and environment information.", Icon="server", Accent=Tokens.Color.Blue, Order=5})
local webhook = app:AddPage({Id="Webhook", Title="Webhook", Description="Notification and delivery settings.", Icon="webhook", Accent=Tokens.Color.Pink, Order=6})
local misc = app:AddPage({Id="Misc", Title="Misc", Description="Utility actions and secondary tools.", Icon="misc", Accent=Tokens.Color.Accent, Order=7})
local settings = app:AddPage({Id="Settings", Title="Settings", Description="Glass quality, comfort, and behavior.", Icon="settings", Accent=Tokens.Color.Pink, Order=8})

InfoBanner.new(about, deps, {
    Icon = "check",
    Title = "Milestone 2 · visual reset",
    Description = "Navigation is now icon-led, sections are flatter, and color is reserved for meaning instead of decorating every box.",
    Color = Tokens.Color.Mint,
})

InfoBanner.new(about, deps, {
    Icon = "info",
    Title = "Why this should feel different",
    Description = "No giant footer, no full-row nav highlight, fewer visible borders, compact metrics in the top bar, and a game context card pinned to the sidebar.",
    Color = Tokens.Color.Blue,
})

local aboutSection = Section.new(about, deps, {
    Title = "Serenity design direction",
    Description = "Real tool first · material second · decoration last.",
    Status = "M2",
    StatusColor = Tokens.Color.Lavender,
})
Status.new(aboutSection.Body, deps, {Title="Icon language", Description="Consistent image icons inside compact tiles.", Text="LUCIDE", Color=Tokens.Color.Lavender})
Status.new(aboutSection.Body, deps, {Title="Glass system", Description="Basic and enhanced scene treatment with safe fallback.", Text="ACTIVE", Color=Tokens.Color.Mint})
Button.new(aboutSection.Body, deps, {Title="Open Automation", Description="Try the new segmented layout and compact controls.", Icon="chevron_right", Callback=function() app:SelectPage("Automation") end})

-- AUTOMATION: sub-tabs
local autoGeneral = Instance.new("Frame")
autoGeneral.BackgroundTransparency = 1
autoGeneral.Size = UDim2.new(1,0,0,0)
autoGeneral.AutomaticSize = Enum.AutomaticSize.Y
autoGeneral.Parent = auto
local agl = Instance.new("UIListLayout") agl.Padding = UDim.new(0,8) agl.Parent = autoGeneral

local autoFilters = Instance.new("Frame")
autoFilters.BackgroundTransparency = 1
autoFilters.Size = UDim2.new(1,0,0,0)
autoFilters.AutomaticSize = Enum.AutomaticSize.Y
autoFilters.Parent = auto
local afl = Instance.new("UIListLayout") afl.Padding = UDim.new(0,8) afl.Parent = autoFilters

local autoAdvanced = Instance.new("Frame")
autoAdvanced.BackgroundTransparency = 1
autoAdvanced.Size = UDim2.new(1,0,0,0)
autoAdvanced.AutomaticSize = Enum.AutomaticSize.Y
autoAdvanced.Parent = auto
local aal = Instance.new("UIListLayout") aal.Padding = UDim.new(0,8) aal.Parent = autoAdvanced

local autoTabs = SegmentedTabs.new(auto, deps, {Accent=Tokens.Color.Mint})
autoTabs.Frame.LayoutOrder = -90
autoTabs:Add("General", "General", autoGeneral)
autoTabs:Add("Filters", "Filters", autoFilters)
autoTabs:Add("Advanced", "Advanced", autoAdvanced)

local rolling = Section.new(autoGeneral, deps, {Title="Rolling", Description="Primary worker controls.", Status="RUNNING", StatusColor=Tokens.Color.Mint})
Toggle.new(rolling.Body, deps, {Title="Auto Roll", Description="Continuously perform configured rolls.", Default=true, Callback=function(v) rolling:SetStatus(v and "RUNNING" or "READY", v and Tokens.Color.Mint or Tokens.Color.TextMuted) end})
Slider.new(rolling.Body, deps, {Title="Roll Delay", Description="Delay between attempts.", Min=0, Max=5, Step=0.1, Default=0.5})

local selling = Section.new(autoGeneral, deps, {Title="Collection & Selling", Description="Independent utility workers.", Status="READY", StatusColor=Tokens.Color.Accent})
Toggle.new(selling.Body, deps, {Title="Auto Collect", Description="Collect available objects automatically.", Default=true})
Toggle.new(selling.Body, deps, {Title="Auto Sell", Description="Sell using the selected rule.", Default=true})
Select.new(selling.Body, deps, {Title="Sell Rule", Description="Choose when a sell cycle begins.", Options={"When Full","Every 5 Minutes","Best Value","Manual Only"}, Default="When Full"})

local filters = Section.new(autoFilters, deps, {Title="Roll Filters", Description="Only filter controls live on this tab.", Status="FILTER", StatusColor=Tokens.Color.Lavender})
Select.new(filters.Body, deps, {Title="Minimum Rarity", Description="Keep results at or above this rarity.", Options={"Common","Rare","Epic","Legendary","Mythic","Divine"}, Default="Epic"})
MultiSelect.new(filters.Body, deps, {Title="Target Rarities", Description="Choose several values without page clutter.", Options={"Common","Uncommon","Rare","Epic","Legendary","Mythic","Divine","Exotic"}, Default={"Legendary","Mythic"}})

InfoBanner.new(autoAdvanced, deps, {Icon="warning", Title="Advanced settings", Description="Secondary tuning stays out of the main workflow until you actually need it.", Color=Tokens.Color.Amber})
local advanced = Section.new(autoAdvanced, deps, {Title="Worker tuning", Description="Less common options.", Open=true})
Slider.new(advanced.Body, deps, {Title="Retry Delay", Description="Wait before another attempt.", Min=0, Max=30, Step=1, Default=3})
Toggle.new(advanced.Body, deps, {Title="Preserve Worker State", Description="Keep configured UI state during test re-renders.", Default=true})

-- PROGRESSION tabs
local storyFrame = Instance.new("Frame") storyFrame.BackgroundTransparency=1 storyFrame.Size=UDim2.new(1,0,0,0) storyFrame.AutomaticSize=Enum.AutomaticSize.Y storyFrame.Parent=progression local sfl=Instance.new("UIListLayout") sfl.Padding=UDim.new(0,8) sfl.Parent=storyFrame
local towerFrame = Instance.new("Frame") towerFrame.BackgroundTransparency=1 towerFrame.Size=UDim2.new(1,0,0,0) towerFrame.AutomaticSize=Enum.AutomaticSize.Y towerFrame.Parent=progression local tfl=Instance.new("UIListLayout") tfl.Padding=UDim.new(0,8) tfl.Parent=towerFrame
local expeditionFrame = Instance.new("Frame") expeditionFrame.BackgroundTransparency=1 expeditionFrame.Size=UDim2.new(1,0,0,0) expeditionFrame.AutomaticSize=Enum.AutomaticSize.Y expeditionFrame.Parent=progression local efl=Instance.new("UIListLayout") efl.Padding=UDim.new(0,8) efl.Parent=expeditionFrame
local progTabs = SegmentedTabs.new(progression, deps, {Accent=Tokens.Color.Lavender})
progTabs.Frame.LayoutOrder = -90
progTabs:Add("Story","Story",storyFrame)
progTabs:Add("Tower","Tower",towerFrame)
progTabs:Add("Expedition","Expedition",expeditionFrame)

local story = Section.new(storyFrame, deps, {Title="Story", Description="Only story controls are visible here.", Status="READY", StatusColor=Tokens.Color.TextMuted})
Select.new(story.Body, deps, {Title="Story Mode", Description="Choose automatic or selected-stage behavior.", Options={"Auto Pick","Selected Stage"}, Default="Auto Pick"})
Slider.new(story.Body, deps, {Title="Retry Delay", Description="Time before another story attempt.", Min=0.5, Max=15, Step=0.5, Default=1.5})

local tower = Section.new(towerFrame, deps, {Title="Tower", Description="Conditional controls stay visibly intentional.", Status="READY", StatusColor=Tokens.Color.TextMuted})
local towerFloor = Select.new(tower.Body, deps, {Title="Floor Target", Description="Unlocked when Auto Tower is enabled.", Options={"Highest Available","25","50","75","100","120"}, Default="Highest Available", Enabled=false})
local towerRetry = Slider.new(tower.Body, deps, {Title="Retry Delay", Description="Secondary tower setting.", Min=1, Max=30, Step=1, Default=5, Enabled=false})
Toggle.new(tower.Body, deps, {Title="Auto Tower", Description="Enable to reveal active tower tuning.", Default=false, Callback=function(v) towerFloor:SetEnabled(v) towerRetry:SetEnabled(v) tower:SetStatus(v and "RUNNING" or "READY", v and Tokens.Color.Mint or Tokens.Color.TextMuted) end})

local expedition = Section.new(expeditionFrame, deps, {Title="Expedition", Description="Route controls in their own focused view.", Status="RUNNING", StatusColor=Tokens.Color.Mint})
Select.new(expedition.Body, deps, {Title="Location", Description="Choose a route destination.", Options={"Forest","Ruins","Abyss","Sanctum"}, Default="Ruins"})
MultiSelect.new(expedition.Body, deps, {Title="Traveller Auras", Description="Choose allowed route auras.", Options={"Wind","Fortune","Wisdom","Fury","Grace","Void"}, Default={"Fortune","Grace"}})
Toggle.new(expedition.Body, deps, {Title="Auto Expedition", Description="Manage configured expedition cycles.", Default=true})

-- SHOP
InfoBanner.new(shop, deps, {Icon="shield", Title="Purchase safety enabled", Description="This playground never sends a purchase. The banner is here to show stronger semantic color surfaces.", Color=Tokens.Color.Mint})
local petShop = Section.new(shop, deps, {Title="Pet Shop", Description="Comfortable purchasing layout.", Status="READY", StatusColor=Tokens.Color.TextMuted})
Select.new(petShop.Body, deps, {Title="Pet", Description="Select a sample item.", Options={"Wolf","Fox","Swan","Turkey","Dragon"}, Default="Wolf"})
Slider.new(petShop.Body, deps, {Title="Amount", Description="Purchase quantity.", Min=1, Max=100, Step=1, Default=5})
Button.new(petShop.Body, deps, {Title="Test Purchase", Description="Visual feedback only.", Icon="chevron_right"})

-- SERVER
InfoBanner.new(server, deps, {Icon="server", Title="Session connected", Description="Compact status information belongs inside the page or top metrics, not in a permanent bottom footer.", Color=Tokens.Color.Blue})
local serverState = Section.new(server, deps, {Title="Environment", Description="Sample session state.", Status="ONLINE", StatusColor=Tokens.Color.Mint})
Status.new(serverState.Body, deps, {Title="Broker", Description="Route safety state.", Text="SAFE", Color=Tokens.Color.Mint})
Status.new(serverState.Body, deps, {Title="Workers", Description="Active demo workers.", Text="5 ACTIVE", Color=Tokens.Color.Accent})
Status.new(serverState.Body, deps, {Title="Configuration", Description="Current profile state.", Text="SYNCED", Color=Tokens.Color.Lavender})

-- WEBHOOK
InfoBanner.new(webhook, deps, {Icon="webhook", Title="Notification delivery", Description="Color can identify a page without turning the whole interface into neon.", Color=Tokens.Color.Pink})
local hook = Section.new(webhook, deps, {Title="Webhook", Description="UI-only delivery controls.", Status="OFF", StatusColor=Tokens.Color.TextMuted})
Toggle.new(hook.Body, deps, {Title="Enabled", Description="Enable sample webhook delivery state.", Default=false, Callback=function(v) hook:SetStatus(v and "ON" or "OFF", v and Tokens.Color.Mint or Tokens.Color.TextMuted) end})
Select.new(hook.Body, deps, {Title="Minimum Event", Description="Choose when a notification should be shown.", Options={"Any","Rare+","Legendary+","Errors Only"}, Default="Legendary+"})

-- MISC
local miscSection = Section.new(misc, deps, {Title="Utilities", Description="Secondary actions without a wall of cards.", Status="READY", StatusColor=Tokens.Color.TextMuted})
Button.new(miscSection.Body, deps, {Title="Test Notification", Description="Placeholder action for the component playground.", Icon="chevron_right"})
Toggle.new(miscSection.Body, deps, {Title="Reduced Motion", Description="Demonstration toggle for calmer animation.", Default=false, Callback=function(v) Motion.Reduced=v end})

-- SETTINGS
InfoBanner.new(settings, deps, {Icon="settings", Title="Glass quality", Description="Enhanced adds a very subtle depth-of-field layer. Basic uses only restrained blur; Off disables scene treatment entirely.", Color=Tokens.Color.Pink})
local glass = Section.new(settings, deps, {Title="Appearance", Description="Tune material without sacrificing readability.", Status="BASIC", StatusColor=Tokens.Color.Accent})
Select.new(glass.Body, deps, {Title="Glass Quality", Description="Choose scene treatment quality.", Options={"Off","Basic","Enhanced"}, Default="Basic", Callback=function(v) app:SetGlassQuality(v) glass:SetStatus(string.upper(v), v=="Enhanced" and Tokens.Color.Lavender or (v=="Off" and Tokens.Color.TextMuted or Tokens.Color.Accent)) end})
Slider.new(glass.Body, deps, {Title="UI Comfort Scale", Description="Prototype control for preferred sizing.", Min=0.9, Max=1.1, Step=0.05, Default=1.0})
Toggle.new(glass.Body, deps, {Title="Reduced Motion", Description="Use shorter or instant transitions.", Default=false, Callback=function(v) Motion.Reduced=v end})

app:SelectPage("About")
return app
