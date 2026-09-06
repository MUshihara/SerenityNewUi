-- SERENITY HUB // NEXT UI M3 PRECISION
-- Visual playground only. No game remotes or automation actions are executed.

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
local Section = loadModule("src/components/Section.lua")
local Toggle = loadModule("src/components/Toggle.lua")
local Slider = loadModule("src/components/Slider.lua")
local Select = loadModule("src/components/Select.lua")
local ColumnLayout = loadModule("src/components/ColumnLayout.lua")
local Desktop = loadModule("src/renderers/Desktop.lua")

local G = (getgenv and getgenv()) or _G
for _, oldKey in ipairs({"__SERENITY_NEW_UI_GLASS_LAB_M2", "__SERENITY_NEW_UI_PRECISION_M3"}) do
    if G[oldKey] and G[oldKey].Destroy then
        pcall(function() G[oldKey]:Destroy() end)
    end
end

local KEY = "__SERENITY_NEW_UI_PRECISION_M3"
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
}

local app = Desktop.Mount(deps, {
    Title = "SERENITY HUB",
    Subtitle = "UI PLAYGROUND",
    BlurSize = 3,
})

local automation = app:AddPage({Id="Automation", Title="Automation", Icon="automation", Accent=Tokens.Color.Accent, Group="Main", Order=1})
local progression = app:AddPage({Id="Progression", Title="Progression", Icon="progression", Accent=Tokens.Color.Lavender, Group="Main", Order=2})
local shop = app:AddPage({Id="Shop", Title="Shop", Icon="shop", Accent=Tokens.Color.Amber, Group="Common", Order=3})
local server = app:AddPage({Id="Server", Title="Server", Icon="server", Accent=Tokens.Color.Cyan, Group="Common", Order=4})
local webhook = app:AddPage({Id="Webhook", Title="Webhook", Icon="webhook", Accent=Tokens.Color.Pink, Group="Common", Order=5})
local misc = app:AddPage({Id="Misc", Title="Misc", Icon="misc", Accent=Tokens.Color.Mint, Group="Common", Order=6})
local settings = app:AddPage({Id="Settings", Title="Settings", Icon="settings", Accent=Tokens.Color.Pink, Group="System", Order=7})

-- AUTOMATION ---------------------------------------------------------------
local autoCols = ColumnLayout.new(automation, deps, {Gap=12, RowGap=12})

local main = Section.new(autoCols.Left, deps, {Title="Main"})
Toggle.new(main.Body, deps, {Title="Enabled", Default=true, Settings=true})
Toggle.new(main.Body, deps, {Title="Auto Roll", Default=true, Settings=true})
Toggle.new(main.Body, deps, {Title="Automatic Collect", Default=true})
Toggle.new(main.Body, deps, {Title="Fast Actions", Default=true})
Slider.new(main.Body, deps, {Title="Action Delay", Min=0, Max=2, Step=0.1, Default=0.2, Suffix="s"})

local selection = Section.new(autoCols.Left, deps, {Title="Selection"})
Select.new(selection.Body, deps, {Title="Target Priority", Options={"Highest Value","Nearest","Lowest HP","Newest"}, Default="Highest Value"})
Select.new(selection.Body, deps, {Title="Minimum Rarity", Options={"Common","Rare","Epic","Legendary","Mythic"}, Default="Epic"})
Select.new(selection.Body, deps, {Title="Target Set", Options={"All Valid","Selected Only","Whitelist"}, Default="Selected Only"})
Slider.new(selection.Body, deps, {Title="Priority Weight", Min=0, Max=100, Step=1, Default=68, Suffix="%", Settings=true})
Toggle.new(selection.Body, deps, {Title="Smart Priority", Default=true})

local other = Section.new(autoCols.Right, deps, {Title="Other"})
Select.new(other.Body, deps, {Title="History", Options={"Off","Low","Medium","High"}, Default="High"})
Toggle.new(other.Body, deps, {Title="Auto Sell", Default=true})
Toggle.new(other.Body, deps, {Title="Auto Upgrade", Default=true})
Toggle.new(other.Body, deps, {Title="Auto Restock", Default=true})
Toggle.new(other.Body, deps, {Title="Quick Retry", Default=false})
Slider.new(other.Body, deps, {Title="Retry Delay", Min=0, Max=10, Step=0.5, Default=1.5, Suffix="s"})

local routes = Section.new(autoCols.Right, deps, {Title="Routing"})
Toggle.new(routes.Body, deps, {Title="Story", Default=true, Settings=true})
Toggle.new(routes.Body, deps, {Title="Tower", Default=true, Settings=true})
Toggle.new(routes.Body, deps, {Title="Expedition", Default=false, Settings=true})
Select.new(routes.Body, deps, {Title="Route Mode", Options={"Balanced","Fastest","Safest"}, Default="Balanced"})

-- PROGRESSION --------------------------------------------------------------
local progCols = ColumnLayout.new(progression, deps, {Gap=12, RowGap=12})
local story = Section.new(progCols.Left, deps, {Title="Story"})
Toggle.new(story.Body, deps, {Title="Auto Story", Default=true, Settings=true})
Select.new(story.Body, deps, {Title="Mode", Options={"Auto Pick","Selected Stage"}, Default="Auto Pick"})
Select.new(story.Body, deps, {Title="Difficulty", Options={"Normal","Hard","Highest"}, Default="Highest"})
Slider.new(story.Body, deps, {Title="Retry Delay", Min=0, Max=15, Step=0.5, Default=1.5, Suffix="s"})

local upgrades = Section.new(progCols.Left, deps, {Title="Upgrades"})
Toggle.new(upgrades.Body, deps, {Title="Auto Trait", Default=false, Settings=true})
Toggle.new(upgrades.Body, deps, {Title="Auto Gem", Default=false, Settings=true})
Toggle.new(upgrades.Body, deps, {Title="Auto Skill", Default=true, Settings=true})
Select.new(upgrades.Body, deps, {Title="Priority", Options={"Damage","Speed","Balanced"}, Default="Balanced"})

local tower = Section.new(progCols.Right, deps, {Title="Tower"})
Toggle.new(tower.Body, deps, {Title="Auto Tower", Default=true, Settings=true})
Select.new(tower.Body, deps, {Title="Floor", Options={"Highest Available","25","50","75","100"}, Default="Highest Available"})
Slider.new(tower.Body, deps, {Title="Retry Delay", Min=1, Max=30, Step=1, Default=5, Suffix="s"})
Toggle.new(tower.Body, deps, {Title="Continue After Clear", Default=true})

local expedition = Section.new(progCols.Right, deps, {Title="Expedition"})
Toggle.new(expedition.Body, deps, {Title="Auto Expedition", Default=true, Settings=true})
Select.new(expedition.Body, deps, {Title="Location", Options={"Forest","Ruins","Abyss","Sanctum"}, Default="Ruins"})
Select.new(expedition.Body, deps, {Title="Aura Mode", Options={"Best","Whitelist","Any"}, Default="Best"})
Toggle.new(expedition.Body, deps, {Title="Auto Claim", Default=true})

-- SHOP ---------------------------------------------------------------------
local shopCols = ColumnLayout.new(shop, deps, {Gap=12, RowGap=12})
local petShop = Section.new(shopCols.Left, deps, {Title="Pet Shop"})
Toggle.new(petShop.Body, deps, {Title="Auto Buy", Default=false, Settings=true})
Select.new(petShop.Body, deps, {Title="Pet", Options={"Wolf","Fox","Swan","Turkey","Dragon"}, Default="Wolf"})
Slider.new(petShop.Body, deps, {Title="Amount", Min=1, Max=100, Step=1, Default=5})
Toggle.new(petShop.Body, deps, {Title="Equip Best", Default=true})

local gearShop = Section.new(shopCols.Left, deps, {Title="Gear"})
Toggle.new(gearShop.Body, deps, {Title="Auto Buy Gear", Default=false, Settings=true})
Select.new(gearShop.Body, deps, {Title="Quality", Options={"Any","Rare+","Epic+","Best"}, Default="Epic+"})
Toggle.new(gearShop.Body, deps, {Title="Auto Equip", Default=true})

local safety = Section.new(shopCols.Right, deps, {Title="Safety"})
Toggle.new(safety.Body, deps, {Title="Block Paid Routes", Default=true})
Toggle.new(safety.Body, deps, {Title="Require Confirmation", Default=true})
Toggle.new(safety.Body, deps, {Title="Affordability Check", Default=true})
Select.new(safety.Body, deps, {Title="Purchase Mode", Options={"Whitelist","Selected Only","Manual"}, Default="Selected Only"})

local limits = Section.new(shopCols.Right, deps, {Title="Limits"})
Slider.new(limits.Body, deps, {Title="Max Per Cycle", Min=1, Max=100, Step=1, Default=10})
Slider.new(limits.Body, deps, {Title="Reserve Currency", Min=0, Max=100000, Step=1000, Default=10000})
Toggle.new(limits.Body, deps, {Title="Pause When Low", Default=true})

-- SERVER -------------------------------------------------------------------
local serverCols = ColumnLayout.new(server, deps, {Gap=12, RowGap=12})
local session = Section.new(serverCols.Left, deps, {Title="Session"})
Toggle.new(session.Body, deps, {Title="Reconnect", Default=false})
Select.new(session.Body, deps, {Title="Join Mode", Options={"Current","Lowest Players","Private"}, Default="Current"})
Toggle.new(session.Body, deps, {Title="Server Hop", Default=false, Settings=true})

local diagnostics = Section.new(serverCols.Right, deps, {Title="Diagnostics"})
Toggle.new(diagnostics.Body, deps, {Title="Live Metrics", Default=true})
Toggle.new(diagnostics.Body, deps, {Title="Worker Status", Default=true})
Toggle.new(diagnostics.Body, deps, {Title="Route Status", Default=true})
Slider.new(diagnostics.Body, deps, {Title="Refresh Rate", Min=0.5, Max=5, Step=0.5, Default=1, Suffix="s"})

-- WEBHOOK ------------------------------------------------------------------
local hookCols = ColumnLayout.new(webhook, deps, {Gap=12, RowGap=12})
local delivery = Section.new(hookCols.Left, deps, {Title="Delivery"})
Toggle.new(delivery.Body, deps, {Title="Enabled", Default=false, Settings=true})
Select.new(delivery.Body, deps, {Title="Minimum Event", Options={"Any","Rare+","Legendary+","Errors"}, Default="Legendary+"})
Toggle.new(delivery.Body, deps, {Title="Include Session", Default=true})
Toggle.new(delivery.Body, deps, {Title="Include Screenshot", Default=false})

local alerts = Section.new(hookCols.Right, deps, {Title="Alerts"})
Toggle.new(alerts.Body, deps, {Title="Rare Finds", Default=true})
Toggle.new(alerts.Body, deps, {Title="Errors", Default=true})
Toggle.new(alerts.Body, deps, {Title="Disconnect", Default=true})
Toggle.new(alerts.Body, deps, {Title="Milestones", Default=false})

-- MISC ---------------------------------------------------------------------
local miscCols = ColumnLayout.new(misc, deps, {Gap=12, RowGap=12})
local utility = Section.new(miscCols.Left, deps, {Title="Utility"})
Toggle.new(utility.Body, deps, {Title="Reduced Motion", Default=false, Callback=function(v) Motion.Reduced = v end})
Toggle.new(utility.Body, deps, {Title="Preserve UI State", Default=true})
Toggle.new(utility.Body, deps, {Title="Compact Popups", Default=true})

local interaction = Section.new(miscCols.Right, deps, {Title="Interaction"})
Select.new(interaction.Body, deps, {Title="Toggle Key", Options={"RightControl","Insert","Home"}, Default="RightControl"})
Select.new(interaction.Body, deps, {Title="Search Key", Options={"Ctrl+K","Ctrl+F","Slash"}, Default="Ctrl+K"})
Toggle.new(interaction.Body, deps, {Title="Close Popups Outside", Default=true})

-- SETTINGS -----------------------------------------------------------------
local settingsCols = ColumnLayout.new(settings, deps, {Gap=12, RowGap=12})
local appearance = Section.new(settingsCols.Left, deps, {Title="Appearance"})
Select.new(appearance.Body, deps, {
    Title="Glass Quality",
    Options={"Off","Basic","Enhanced"},
    Default="Basic",
    Callback=function(v) app:SetGlassQuality(v) end,
})
Slider.new(appearance.Body, deps, {Title="Background Blur", Min=0, Max=8, Step=1, Default=3})
Toggle.new(appearance.Body, deps, {Title="Soft Shadow", Default=true})
Toggle.new(appearance.Body, deps, {Title="High Contrast Text", Default=true})

local behavior = Section.new(settingsCols.Left, deps, {Title="Behavior"})
Toggle.new(behavior.Body, deps, {Title="Preserve State", Default=true})
Toggle.new(behavior.Body, deps, {Title="Notifications", Default=true})
Toggle.new(behavior.Body, deps, {Title="Confirm Dangerous Actions", Default=true})

local interface = Section.new(settingsCols.Right, deps, {Title="Interface"})
Select.new(interface.Body, deps, {Title="Density", Options={"Comfortable","Compact","Dense"}, Default="Comfortable"})
Select.new(interface.Body, deps, {Title="Accent", Options={"Serenity Blue","Cyan","Lavender","Pink"}, Default="Serenity Blue"})
Toggle.new(interface.Body, deps, {Title="Show Page Groups", Default=true})
Toggle.new(interface.Body, deps, {Title="Show User Card", Default=true})

local debug = Section.new(settingsCols.Right, deps, {Title="Component Test"})
Toggle.new(debug.Body, deps, {Title="Enabled Toggle", Default=true, Settings=true})
local disabled = Toggle.new(debug.Body, deps, {Title="Disabled Toggle", Default=false, Enabled=false})
Slider.new(debug.Body, deps, {Title="Slider", Min=0, Max=100, Step=1, Default=50, Suffix="%", Settings=true})
Select.new(debug.Body, deps, {Title="Dropdown", Options={"Option A","Option B","Option C"}, Default="Option A"})

app:SelectPage("Automation")
app:SetGlassQuality("Basic")

print("SERENITY NEXT M3 PRECISION READY | UI ONLY | RightCtrl = toggle | Ctrl+K = page search")
