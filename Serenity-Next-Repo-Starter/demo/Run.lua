-- SERENITY HUB // NEXT UI GLASS LAB M1
-- Run this file directly with loadstring(game:HttpGet(...))().
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
local Icons = loadModule("src/core/Icons.lua")
local PopupManagerClass = loadModule("src/core/PopupManager.lua")

local Section = loadModule("src/components/Section.lua")
local Toggle = loadModule("src/components/Toggle.lua")
local Slider = loadModule("src/components/Slider.lua")
local Select = loadModule("src/components/Select.lua")
local MultiSelect = loadModule("src/components/MultiSelect.lua")
local Button = loadModule("src/components/Button.lua")
local Status = loadModule("src/components/Status.lua")
local Desktop = loadModule("src/renderers/Desktop.lua")

local G = (getgenv and getgenv()) or _G
local KEY = "__SERENITY_NEW_UI_GLASS_LAB_M1"
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
    Icons = Icons,
    PopupManager = PopupManagerClass.new(),
    UserInputService = UserInputService,
}

local app = Desktop.Mount(deps, {
    Title = "SERENITY HUB",
    Subtitle = "NEXT UI · GLASS LAB",
    BlurSize = 4,
})

local home = app:AddPage({
    Id = "Home",
    Title = "Overview",
    Description = "A calmer glass surface with readable controls and real iconography.",
    Icon = "home",
    Order = 1,
})

local auto = app:AddPage({
    Id = "Automation",
    Title = "Automation",
    Description = "Interactive component test — nothing here touches the game.",
    Icon = "automation",
    Order = 2,
})

local progression = app:AddPage({
    Id = "Progression",
    Title = "Progression",
    Description = "Conditional and state-aware controls.",
    Icon = "progression",
    Order = 3,
})

local settings = app:AddPage({
    Id = "Settings",
    Title = "Interface",
    Description = "Material and comfort controls for the new design.",
    Icon = "settings",
    Order = 4,
})

local homeSection = Section.new(home, deps, {
    Title = "Serenity Next",
    Description = "Milestone 1 · material, typography, icons, interaction",
    Status = "LIVE LAB",
    StatusColor = Tokens.Color.Mint,
})

Status.new(homeSection.Body, deps, {
    Title = "Material Engine",
    Description = "Layered tint, reflection, edge light and controlled blur.",
    Text = "ACTIVE",
    Color = Tokens.Color.Mint,
})
Status.new(homeSection.Body, deps, {
    Title = "Typography",
    Description = "Important text stays readable instead of shrinking to fit.",
    Text = "COMFORT",
    Color = Tokens.Color.Accent,
})
Status.new(homeSection.Body, deps, {
    Title = "Icon System",
    Description = "Real Serenity/Lucide image assets replace placeholder glyphs.",
    Text = "LUCIDE",
    Color = Tokens.Color.Lavender,
})
Button.new(homeSection.Body, deps, {
    Title = "Open Automation Playground",
    Description = "Try toggles, dropdowns, multi-select and sliders.",
    Icon = "chevron_right",
    Callback = function() app:SelectPage("Automation") end,
})

local rolling = Section.new(auto, deps, {
    Title = "Rolling",
    Description = "Primary worker controls without giant nested cards.",
    Status = "RUNNING",
    StatusColor = Tokens.Color.Mint,
})
local autoRoll = Toggle.new(rolling.Body, deps, {
    Title = "Auto Roll",
    Description = "Continuously perform configured rolls.",
    Default = true,
    Callback = function(v) rolling:SetStatus(v and "RUNNING" or "READY", v and Tokens.Color.Mint or Tokens.Color.TextMuted) end,
})
Select.new(rolling.Body, deps, {
    Title = "Minimum Rarity",
    Description = "Keep results at or above this rarity.",
    Options = {"Common", "Rare", "Epic", "Legendary", "Mythic", "Divine"},
    Default = "Epic",
})
MultiSelect.new(rolling.Body, deps, {
    Title = "Target Rarities",
    Description = "Pick several values without filling the page with chips.",
    Options = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Divine", "Exotic"},
    Default = {"Legendary", "Mythic"},
})
Slider.new(rolling.Body, deps, {
    Title = "Roll Delay",
    Description = "Large hit target with a visible numeric value.",
    Min = 0,
    Max = 5,
    Step = 0.1,
    Default = 0.5,
})

local utility = Section.new(auto, deps, {
    Title = "Collection & Selling",
    Description = "Secondary workers stay readable and calm.",
    Status = "READY",
    StatusColor = Tokens.Color.Accent,
})
Toggle.new(utility.Body, deps, {Title = "Auto Collect", Description = "Collect available objects automatically.", Default = true})
Toggle.new(utility.Body, deps, {Title = "Auto Sell", Description = "Sell using the selected rule.", Default = true})
Select.new(utility.Body, deps, {
    Title = "Sell Rule",
    Description = "Choose when a sell cycle begins.",
    Options = {"When Full", "Every 5 Minutes", "Best Value", "Manual Only"},
    Default = "When Full",
})

local tower = Section.new(progression, deps, {
    Title = "Tower",
    Description = "Disabled state demo with explicit visual hierarchy.",
    Status = "READY",
    StatusColor = Tokens.Color.TextMuted,
})
local towerFloor = Select.new(tower.Body, deps, {
    Title = "Floor Target",
    Description = "Only becomes interactive when Auto Tower is on.",
    Options = {"Highest Available", "25", "50", "75", "100", "120"},
    Default = "Highest Available",
    Enabled = false,
})
local towerRetry = Slider.new(tower.Body, deps, {
    Title = "Retry Delay",
    Description = "Conditional secondary setting.",
    Min = 1,
    Max = 30,
    Step = 1,
    Default = 5,
    Enabled = false,
})
Toggle.new(tower.Body, deps, {
    Title = "Auto Tower",
    Description = "Enable this to unlock the settings above.",
    Default = false,
    Callback = function(v)
        towerFloor:SetEnabled(v)
        towerRetry:SetEnabled(v)
        tower:SetStatus(v and "RUNNING" or "READY", v and Tokens.Color.Mint or Tokens.Color.TextMuted)
    end,
})

local material = Section.new(settings, deps, {
    Title = "Glass & Comfort",
    Description = "The design should be beautiful without becoming hard to read.",
    Status = "SERENITY",
    StatusColor = Tokens.Color.Lavender,
})
Toggle.new(material.Body, deps, {
    Title = "Backdrop Blur",
    Description = "Use a restrained world blur under the tinted glass shell.",
    Default = true,
    Callback = function(v) app:SetBlur(v) end,
})
Slider.new(material.Body, deps, {
    Title = "UI Comfort Scale",
    Description = "Prototype slider for spacing/scale direction.",
    Min = 0.9,
    Max = 1.1,
    Step = 0.05,
    Default = 1.0,
})
Status.new(material.Body, deps, {
    Title = "Current Direction",
    Description = "Real tool first · glass material second · decoration last.",
    Text = "M1",
    Color = Tokens.Color.Mint,
})

app:SelectPage("Home")
return app
