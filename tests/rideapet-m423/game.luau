
local VERSION = "RAP-80.2.99-M423-UI-TEST1"

-- ============================================================
-- BOOT SOURCE / AUTO EXECUTE GUARD
--
-- IMPORTANT:
-- Manual execution must NEVER be rejected because a queue marker from an old
-- teleport still exists. New queued boots explicitly identify themselves.
-- ============================================================
do
    local bootEnv =
        (type(getgenv) == "function" and getgenv())
        or _G

    local job =
        tostring(game.JobId or "")

    local now =
        os.clock()

    local source =
        bootEnv.__SERENITY_RAP_BOOT_SOURCE

    local queuedBoot =
        type(source) == "table"
        and source.Kind == "queue"
        and tostring(source.Job or "") == job

    -- Consume the explicit source marker immediately. A later manual execute
    -- in this same server is therefore always treated as manual.
    if queuedBoot then
        bootEnv.__SERENITY_RAP_BOOT_SOURCE =
            nil
    end

    -- Compatibility only for already-stored v2.29-v2.32 queue payloads.
    -- Those payloads only set __SERENITY_RAP_QUEUED_BOOT_JOB. If Auto Execute
    -- is saved OFF, suppress that legacy queued boot ONCE and clear its marker.
    if not queuedBoot
        and job ~= ""
        and tostring(
            bootEnv.__SERENITY_RAP_QUEUED_BOOT_JOB
            or ""
        ) == job
        and tostring(
            bootEnv.__SERENITY_RAP_LAST_BOOT_JOB
            or ""
        ) ~= job then

        local autoExecuteDisabled =
            false

        if type(isfile) == "function"
            and type(readfile) == "function"
            and isfile(
                "SerenityHub/RideAPet_M423Test_Config.json"
            ) then

            pcall(function()
                local raw =
                    readfile(
                        "SerenityHub/RideAPet_M423Test_Config.json"
                    )

                local data =
                    game:GetService("HttpService")
                        :JSONDecode(raw)

                autoExecuteDisabled =
                    type(data) == "table"
                    and data.AutoExecuteOnTeleport
                        == false
            end)
        end

        if autoExecuteDisabled then
            -- Critical fix: never leave this marker behind indefinitely.
            bootEnv.__SERENITY_RAP_QUEUED_BOOT_JOB =
                nil

            bootEnv.__SERENITY_RAP_LEGACY_QUEUE_BLOCK_JOB =
                job

            bootEnv.__SERENITY_RAP_LEGACY_QUEUE_BLOCK_UNTIL =
                now + 2

            return
        end
    end

    -- If several OLD duplicate queued entries arrive together, suppress them
    -- briefly. This expires after two seconds, so normal manual execution can
    -- always recover without needing another rejoin.
    if job ~= ""
        and tostring(
            bootEnv.__SERENITY_RAP_LEGACY_QUEUE_BLOCK_JOB
            or ""
        ) == job
        and now
            < (
                tonumber(
                    bootEnv.__SERENITY_RAP_LEGACY_QUEUE_BLOCK_UNTIL
                )
                or 0
            ) then

        return
    end

    -- Duplicate debounce applies ONLY to an explicitly queued execution.
    -- A user manually executing Serenity is always allowed to rebuild/recover.
    if queuedBoot then
        local lastQueuedJob =
            tostring(
                bootEnv.__SERENITY_RAP_LAST_QUEUED_BOOT_JOB
                or ""
            )

        local lastQueuedClock =
            tonumber(
                bootEnv.__SERENITY_RAP_LAST_QUEUED_BOOT_CLOCK
            )
            or -math.huge

        if job ~= ""
            and lastQueuedJob == job
            and now - lastQueuedClock < 8 then

            return
        end

        bootEnv.__SERENITY_RAP_LAST_QUEUED_BOOT_JOB =
            job

        bootEnv.__SERENITY_RAP_LAST_QUEUED_BOOT_CLOCK =
            now
    end

    -- This is informational/recovery state only. It no longer blocks manual
    -- execution.
    bootEnv.__SERENITY_RAP_LAST_BOOT_JOB =
        job

    bootEnv.__SERENITY_RAP_LAST_BOOT_CLOCK =
        now
end

local EXPECTED_PLACE = 124216119978534
local EXPECTED_UNIVERSE = 10035204815
-- Separate movement speeds so each phase can be tuned independently.
local EGG_TWEEN_SPEED = 2000
local GARDEN_RETURN_TWEEN_SPEED = 2000
local LOCAL_ACTION_TWEEN_SPEED = 2200
local LOCAL_RETURN_TWEEN_SPEED = 2600
local FINAL_GARDEN_WALK_SPEED = 28
local TWEEN_SEGMENT_LENGTH = 500
local ARRIVAL_SERVER_SETTLE = 0.18

-- v35 movement order:
-- find egg -> fast tween to egg -> steal -> fast tween back ->
-- stop ~10 studs OUTSIDE own garden -> normal walk across boundary.
local GARDEN_OUTSIDE_STOP_DISTANCE = 30
local GARDEN_BEFORE_WALK_WAIT = 0
local VOID_RETURN_DEPTH = 125 -- shallow hidden route below the map/base
local GARDEN_INSIDE_WALK_DISTANCE = 8
local GARDEN_FINAL_WALK_MAX_SECONDS = 6
local GARDEN_ENTRY_SETTLE = 0.65
local POST_GARDEN_CLAIM_WAIT = 3
local POST_HATCH_FREE_SLOT_TIMEOUT = 15
local FULL_NEST_RECHECK_SECONDS = 1

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")

local LP = Players.LocalPlayer
local Character = LP.Character or LP.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid", 10)
local HRP = Character:WaitForChild("HumanoidRootPart", 10)
local Backpack = LP:FindFirstChildOfClass("Backpack") or LP:WaitForChild("Backpack", 10)


-- ============================================================
-- GAMEPLAY PAUSED SUPPRESSION / PROACTIVE STREAMING
-- ============================================================

-- Official Roblox client control for the default "Gameplay Paused" modal.
-- This remains disabled for the current client session.
pcall(function()
    GuiService:SetGameplayPausedNotificationEnabled(false)
end)

-- Re-apply after respawn as a defensive measure.
-- Keep exactly ONE CharacterAdded recovery connection across re-executions.
pcall(function()
    local runtimeEnv =
        (getgenv and getgenv())
        or _G

    local oldConnection =
        runtimeEnv.__SERENITY_RAP_CHARACTER_ADDED_CONNECTION

    if oldConnection then
        pcall(function()
            oldConnection:Disconnect()
        end)
    end

    runtimeEnv.__SERENITY_RAP_CHARACTER_ADDED_CONNECTION =
        LP.CharacterAdded:Connect(function()
            pcall(function()
                GuiService:SetGameplayPausedNotificationEnabled(false)
            end)

            -- Long-session/mobile recovery: old character references can become
            -- stale after respawn or resume. Resolve the new objects and force
            -- a fresh movement owner without touching stock/filter state.
            task.defer(function()
                for _ = 1, 80 do
                    local rap =
                        runtimeEnv
                        and runtimeEnv.SerenityRideAPet

                    if rap
                        and type(rap.RefreshRuntimeCharacterRefs) == "function" then

                        rap.RefreshRuntimeCharacterRefs(8)

                        if type(rap.EnsureMovementLaneWorker) == "function" then
                            rap.EnsureMovementLaneWorker(
                                "CharacterAdded",
                                true
                            )
                        end

                        return
                    end

                    task.wait(0.10)
                end
            end)
        end)
end)


local function envfn(name)
    local ok, v = pcall(function()
        return getfenv and getfenv()[name]
    end)
    if ok and type(v) == "function" then return v end
    v = rawget(_G, name)
    return type(v) == "function" and v or nil
end

local fireproximityprompt_f = envfn("fireproximityprompt")
local writefile_f = envfn("writefile")
local setclipboard_f = envfn("setclipboard")

local readfile_f = envfn("readfile")
local isfile_f = envfn("isfile")
local makefolder_f = envfn("makefolder")
local isfolder_f = envfn("isfolder")

-- ============================================================
-- PERSISTENT USER SETTINGS
-- First run: automation toggles are OFF except Volcanic Mutation (In Steal),
-- which is intentionally ON by default for the updated Auto Steal flow.
-- Any change through SerenityRideAPet.Set / SetNested is saved.
-- ============================================================

local CONFIG_FOLDER = "SerenityHub"
local CONFIG_FILE = CONFIG_FOLDER .. "/RideAPet_M423Test_Config.json"

local DEFAULT_CONFIG = {
    AutoSteal = false,

    -- Normal Auto Steal movement mode.
    -- OFF (default) = Tween using GardenReturnTweenSpeed.
    -- ON = direct teleport for normal Auto Steal travel.
    -- The special Volcanic Egg route keeps its proven collision-safe tween path.
    InstantSteal = false,
    GardenReturnTweenSpeed = "2000",

    -- Optional Auto Steal post-pickup Volcano mutation.
    -- When enabled, every successfully stolen egg gets one Volcano mutation
    -- attempt. Success or failure, Serenity waits for the Volcano lifecycle
    -- to finish when accepted, then ALWAYS returns home for the normal claim.
    VolcanicMutationInSteal = true,

    -- v80.2.53 one-time rollout marker.
    -- 0 means this install has not yet received the default-ON migration.
    -- After migration it becomes 1, so a later user-selected OFF value persists.
    VolcanicMutationInStealDefaultVersion = 0,

    AutoPlace = false,
    PlaceKnownMaxEggs = 0,
    AutoHatch = false,

    -- Session protection is intentionally ON by default.
    AntiAFK = true,

    -- Queue the deployed Serenity loader for ANY later teleport/reconnect.
    -- This is independent from Auto Hop No K.G Match.
    AutoExecuteOnTeleport = false,

    -- Recover from Roblox disconnect/error prompts by rejoining the experience.
    -- OFF by default. A user-saved ON value remains ON.
    AutoReconnectOnDisconnect = false,
    AutoReconnectDelaySeconds = "3",

    -- Manual local movement controls. All OFF by default.
    PlayerNoclip = false,
    SpeedHackEnabled = false,
    SpeedHackSpeed = 16,
    FlyEnabled = false,
    FlySpeed = 70,

    -- Client-only optimization options are opt-in.
    ReduceLag = false,
    Disable3DRendering = false,
    BlackScreen = false,
    RemoveOtherGardens = false,

    -- Rejoin is opt-in. It only runs after the movement lane is idle.
    AutoRejoinNoEgg = false,

    -- Internal Auto Hop hunt latch. These are intentionally hidden from the UI.
    -- A confirmed target survives a manual rejoin, but real new egg stock or a
    -- target-filter change clears the latch and starts a fresh hunt.
    AutoHopKGSatisfied = false,
    AutoHopKGSatisfiedSignature = "",
    AutoHopKGSatisfiedEggType = "",
    AutoHopKGSatisfiedKG = 0,
    -- Legacy per-egg Cycle captured when the qualifying egg is won. Kept as
    -- a fallback/migration signal when the global EggCycle module is unavailable.
    AutoHopKGSatisfiedStockCycle = 0,
    -- Authoritative global stock identity from GameServices.EggCycle.Index.
    -- A completed hunt is valid only while this exact global stock is active.
    AutoHopKGSatisfiedGlobalCycle = 0,

    -- Current-server no-K.G-match interval.
    -- Auto Server Hop uses the same target qualification as Auto Steal: Minimum
    -- K.G first, then Minimum Luck OR Specific Eggs.
    RejoinIntervalSeconds = "5",

    -- Visual ESP remains opt-in.
    EggESP = false,
    EggMutationESP = false,
    EggESPMinLuck = "1M",
    PlacedEggESP = false,
    PlayerESP = false,

    StealMinLuck = "Any",
    StealMinKG = "0",
    StealPriority = "Highest to Lowest",
    StealEggs = {},
    OptionalStealFiltersVersion = 1,

    -- Confirmed-steal Discord webhook.
    -- Empty WebhookEggs means all egg types.
    WebhookEnabled = false,
    WebhookURL = "",
    WebhookEggs = {},
    WebhookRarities = {},
    WebhookMinKG = "0",
    MutationWebhookEnabled = false,

    -- Legacy restock fields kept only so old saved configs migrate cleanly.
    StealRestockPeriodKey = "",
    StealRestockFallbackGeneration = 0,
    StealRestockBlockedEggs = {},
    StealRestockFailures = {},
    StealRestockTrackerVersion = 4,

    PlaceFilterMode = "All Eggs",
    PlacePriority = "Highest to Lowest",
    PlaceRarities = {},
    PlaceEggs = {},
    PlaceMinKG = "0",

    AutoWeatherPetSwap = false,
    WeatherPetNames = "", -- legacy single-weather migration field
    WeatherVariants = {},
    WeatherPetMode = "Manual", -- legacy migration field
    WeatherAutoHighestNoMutation = false,
    WeatherPetKeys = {},
    WeatherRestorePrevious = true,
    BaseMaintenanceIdleReturn = true,
    BaseMaintenanceIdleSeconds = "60",
    BaseMaintenanceIdleVersion = 2,

    AutoShopFood = false,
    AutoShopGears = false,
    ShopFoodAutoBuyItems = {},
    ShopGearAutoBuyItems = {},

    AutoHatchLuck = false,
    AutoRebirth = false,

    AutoSell = false,
    AutoEquipBest = false,
    AutoSellRarities = {},
    AutoSellProtectFavorites = true,
    AutoSellProtectLocked = true,
    AutoSellProtectCurrentPet = true,
    AutoSellProtectGardenPets = true,
    AutoSellMaxPerSecond = "0",
    SellIntervalSeconds = 8,

    AutoFeed = false,
    AutoFeedFoods = {},
    AutoFeedTargetMode = "All Placed Pets",
    AutoFeedPetKeys = {},

    HatchLuckIntervalSeconds = 1,
}

local function deepCopy(v)
    if type(v) ~= "table" then
        return v
    end

    local t = {}
    for k, x in pairs(v) do
        t[k] = deepCopy(x)
    end
    return t
end

local function mergeDefaults(dst, defaults)
    for k, v in pairs(defaults) do
        if dst[k] == nil then
            dst[k] = deepCopy(v)
        elseif type(v) == "table" and type(dst[k]) == "table" then
            mergeDefaults(dst[k], v)
        end
    end
end

local Config = deepCopy(DEFAULT_CONFIG)

local function ensureConfigFolder()
    if makefolder_f and isfolder_f then
        local ok, exists = pcall(isfolder_f, CONFIG_FOLDER)
        if ok and not exists then
            pcall(makefolder_f, CONFIG_FOLDER)
        end
    elseif makefolder_f then
        pcall(makefolder_f, CONFIG_FOLDER)
    end
end

local function saveConfig()
    if not writefile_f then
        return false, "writefile unavailable"
    end

    ensureConfigFolder()

    local okJson, encoded = pcall(function()
        return HttpService:JSONEncode(Config)
    end)

    if not okJson then
        return false, encoded
    end

    local okWrite, err = pcall(writefile_f, CONFIG_FILE, encoded)
    return okWrite, err
end

local function loadConfig()
    if not readfile_f or not isfile_f then
        mergeDefaults(Config, DEFAULT_CONFIG)
        return false, "file persistence unavailable"
    end

    local okExists, exists = pcall(isfile_f, CONFIG_FILE)

    if not okExists or not exists then
        mergeDefaults(Config, DEFAULT_CONFIG)
        saveConfig()
        return true, "created defaults"
    end

    local okRead, raw = pcall(readfile_f, CONFIG_FILE)
    if not okRead or type(raw) ~= "string" then
        mergeDefaults(Config, DEFAULT_CONFIG)
        return false, "read failed"
    end

    local okDecode, decoded = pcall(function()
        return HttpService:JSONDecode(raw)
    end)

    if okDecode and type(decoded) == "table" then
        Config = decoded
        mergeDefaults(Config, DEFAULT_CONFIG)
        saveConfig()
        return true, "loaded"
    end

    Config = deepCopy(DEFAULT_CONFIG)
    saveConfig()
    return false, "invalid config reset"
end

local function setConfig(key, value)
    if DEFAULT_CONFIG[key] == nil then
        return false, "unknown setting: " .. tostring(key)
    end

    Config[key] = value
    local ok, err = saveConfig()

    return ok, err
end

local function setNestedConfig(group, key, value)
    if type(Config[group]) ~= "table"
        or type(DEFAULT_CONFIG[group]) ~= "table" then

        return false, "unknown setting group: " .. tostring(group)
    end

    if DEFAULT_CONFIG[group][key] == nil then
        return false, "unknown nested setting: "
            .. tostring(group) .. "." .. tostring(key)
    end

    Config[group][key] = value
    local ok, err = saveConfig()

    return ok, err
end

local configLoaded, configLoadInfo = loadConfig()

-- v66 migration: Pet Income worker stays removed.
-- Auto Sell is restored with the low-lag cached implementation below.
Config.AutoPetCollect = nil

-- v80.1.5: Hatch Luck is represented by multiplier/progress in-game,
-- not a player-facing level. Remove the old target/reserve settings.
Config.HatchLuckTargetLevel = nil
Config.HatchLuckKeepCash = nil

-- v80.1.1 migration: movement Speed was the wrong sell stat.
-- Sell filtering now uses the pet's displayed money-per-second ($/s).
Config.AutoSellMaxSpeed = nil

-- v67: Auto Steal is based on current server Egg Luck, not rarity.
Config.StealFilterMode = nil
Config.StealRarities = nil

if type(Config.StealRestockBlockedEggs) ~= "table" then
    Config.StealRestockBlockedEggs = {}
end

if type(Config.StealRestockFailures) ~= "table" then
    Config.StealRestockFailures = {}
end

Config.StealRestockFallbackGeneration =
    math.max(
        0,
        math.floor(
            tonumber(Config.StealRestockFallbackGeneration) or 0
        )
    )

-- v80.2.2 migration:
-- Period-index based locks were not a reliable representation of the actual
-- world egg stock. v4 uses runtime 3-failure + new-stock evidence instead.
if tonumber(Config.StealRestockTrackerVersion) ~= 4 then
    Config.StealRestockTrackerVersion = 4
    Config.StealRestockBlockedEggs = {}
    Config.StealRestockFailures = {}
    Config.StealRestockPeriodKey = ""
end


mergeDefaults(Config, DEFAULT_CONFIG)

-- v80.2.53 migration:
-- Roll the newly validated Volcanic Mutation (In Steal) feature out ON once
-- for both fresh installs and existing saved configs.
--
-- IMPORTANT:
-- This is intentionally a ONE-TIME migration. Once the marker reaches 1,
-- a player who manually turns the feature OFF keeps it OFF on later rejoins.
if tonumber(Config.VolcanicMutationInStealDefaultVersion) ~= 1 then
    Config.VolcanicMutationInSteal = true
    Config.VolcanicMutationInStealDefaultVersion = 1
end

-- v80.2.48 migration:
-- Remove the retired lightning feature settings from older saved configs.
Config["LightningStrikeIndicator"] = nil
Config["AutoLightningMutation"] = nil

-- Migrate only the old untouched 10-second default to the new 60-second
-- default. Any custom idle value is preserved.
if tonumber(Config.BaseMaintenanceIdleVersion) ~= 2 then
    if tostring(Config.BaseMaintenanceIdleSeconds or "10") == "10" then
        Config.BaseMaintenanceIdleSeconds = "60"
    end

    Config.BaseMaintenanceIdleVersion = 2
end

Config.BaseMaintenanceIdleSeconds =
    tostring(
        math.clamp(
            tonumber(Config.BaseMaintenanceIdleSeconds) or 60,
            3,
            300
        )
    )

Config.SpeedHackSpeed =
    math.floor(
        math.clamp(
            tonumber(Config.SpeedHackSpeed) or 16,
            16,
            5000
        )
        + 0.5
    )

Config.FlySpeed =
    math.floor(
        math.clamp(
            tonumber(Config.FlySpeed) or 70,
            1,
            5000
        )
        + 0.5
    )

local validStealMinLuck = {
    ["Any"] = true,
    ["1M"] = true,
    ["10M"] = true,
    ["100M"] = true,
    ["1B"] = true,
    ["5B"] = true,
    ["10B"] = true,
    ["100B"] = true,
    ["1T"] = true,
    ["10T"] = true,
    ["100T"] = true,
}

if tonumber(Config.OptionalStealFiltersVersion) ~= 1 then
    -- Prior builds used 1M as an unavoidable default. Treat that old default
    -- as "not selected" once so K.G-only / egg-only configurations work.
    if tostring(Config.StealMinLuck) == "1M" then
        Config.StealMinLuck = "Any"
    end

    Config.OptionalStealFiltersVersion = 1
end

if not validStealMinLuck[tostring(Config.StealMinLuck)] then
    Config.StealMinLuck = "Any"
end

if not validStealMinLuck[tostring(Config.EggESPMinLuck)] then
    Config.EggESPMinLuck = "1M"
end

if tostring(Config.AutoFeedTargetMode) ~= "All Placed Pets"
    and tostring(Config.AutoFeedTargetMode) ~= "Selected Pets" then
    Config.AutoFeedTargetMode = "All Placed Pets"
end

Config.RejoinIntervalSeconds =
    tostring(
        math.clamp(
            tonumber(Config.RejoinIntervalSeconds) or 5,
            0,
            3600
        )
    )

Config.AutoReconnectDelaySeconds =
    tostring(
        math.clamp(
            tonumber(Config.AutoReconnectDelaySeconds) or 3,
            1,
            30
        )
    )

-- Remove abandoned two-timer fields from older local test configs.
Config.RejoinNoTargetDelaySeconds = nil
Config.LastAutoRejoinUnix = nil

if type(Config.WebhookEggs) ~= "table" then
    Config.WebhookEggs = {}
end

if type(Config.WebhookRarities) ~= "table" then
    Config.WebhookRarities = {}
end

Config.WebhookURL = tostring(Config.WebhookURL or "")
Config.WebhookMinKG = tostring(Config.WebhookMinKG or "0")

saveConfig()

local shared = getgenv and getgenv() or _G
shared.SerenityRideAPet = shared.SerenityRideAPet or {}

shared.SerenityRideAPet.Config = Config

-- Refresh the runtime character references without creating another top-level
-- local helper (the main chunk is already close to Luau's local-register cap).
shared.SerenityRideAPet.RefreshRuntimeCharacterRefs = function(timeoutSeconds)
    local current = LP.Character

    if not current
        or current.Parent == nil then

        return false
    end

    local timeout =
        math.max(
            0,
            tonumber(timeoutSeconds) or 0
        )

    local humanoid =
        current:FindFirstChildOfClass("Humanoid")

    local root =
        current:FindFirstChild("HumanoidRootPart")

    if timeout > 0 then
        if not humanoid then
            humanoid =
                current:WaitForChild(
                    "Humanoid",
                    timeout
                )
        end

        if not root then
            root =
                current:WaitForChild(
                    "HumanoidRootPart",
                    timeout
                )
        end
    end

    if not humanoid
        or not root
        or humanoid.Parent == nil
        or root.Parent == nil then

        return false
    end

    Character = current
    Humanoid = humanoid
    HRP = root

    local currentBackpack =
        LP:FindFirstChildOfClass("Backpack")

    if currentBackpack then
        Backpack = currentBackpack
    end

    return true
end

-- User-entered compact number parser for egg Weight/K.G filters.
-- Examples: 50k -> 50000, 50,000 -> 50000, 1.5m -> 1500000.
shared.SerenityRideAPet.ParseCompactNumber = function(value)
    if type(value) == "number" then
        if value >= 0 and value < math.huge then
            return value
        end
        return nil
    end

    local s = string.lower(tostring(value or ""))
    s = s:gsub("[%s,_]", "")

    -- Since the UI already says KG, "50kg" is also accepted as 50.
    if s:sub(-2) == "kg" then
        s = s:sub(1, -3)
    end

    if s == "" then
        return nil
    end

    local multiplier = 1
    local suffix = s:sub(-1)

    if suffix == "k" then
        multiplier = 1e3
        s = s:sub(1, -2)
    elseif suffix == "m" then
        multiplier = 1e6
        s = s:sub(1, -2)
    elseif suffix == "b" then
        multiplier = 1e9
        s = s:sub(1, -2)
    elseif suffix == "t" then
        multiplier = 1e12
        s = s:sub(1, -2)
    elseif suffix == "q" then
        multiplier = 1e15
        s = s:sub(1, -2)
    end

    local n = tonumber(s)
    if not n or n < 0 or n == math.huge then
        return nil
    end

    return n * multiplier
end

shared.SerenityRideAPet.ActiveStealSetting = function(key, fallback)
    local runtime =
        shared.SerenityRideAPet.StealActionRuntime

    local snapshot =
        runtime
        and runtime.Busy == true
        and runtime.SettingsSnapshot
        or nil

    if type(snapshot) == "table"
        and snapshot[key] ~= nil then

        return snapshot[key]
    end

    local value =
        Config[key]

    if value == nil then
        return fallback
    end

    return value
end

shared.SerenityRideAPet.MinimumStealKG = function()
    return
        shared.SerenityRideAPet.ParseCompactNumber(
            shared.SerenityRideAPet.ActiveStealSetting(
                "StealMinKG",
                "0"
            )
        )
        or 0
end

shared.SerenityRideAPet.MinimumPlaceKG = function()
    return shared.SerenityRideAPet.ParseCompactNumber(Config.PlaceMinKG) or 0
end

-- ============================================================
-- REAL EGG K.G
--
-- VALIDATED 2026-09-18:
-- Replicated ActiveEgg.Weight / Tool.Data.Weight is a RAW weight input.
-- It is NOT the number the game displays as K.G.
--
-- The game's exact conversion is:
-- ReplicatedStorage.GameServices.PetAging.FormatWeight(rawWeight)
--
-- Proven examples:
--   1.93 -> "117,933 KG"
--   1.40 -> "323 KG"
--   0.93 -> "1 KG"
--   0.99 -> "2 KG"
--   1.19 -> "14 KG"
-- ============================================================

shared.SerenityRideAPet.EggKGCache =
    shared.SerenityRideAPet.EggKGCache or {}

shared.SerenityRideAPet.GetPetAging = function()
    local cached =
        shared.SerenityRideAPet.PetAgingModule

    if type(cached) == "table"
        and type(cached.FormatWeight) == "function" then

        return cached
    end

    local services =
        ReplicatedStorage:FindFirstChild("GameServices")

    local module =
        services
        and services:FindFirstChild("PetAging")

    if not module
        or not module:IsA("ModuleScript") then

        return nil
    end

    local ok, value =
        pcall(require, module)

    if not ok
        or type(value) ~= "table"
        or type(value.FormatWeight) ~= "function" then

        return nil
    end

    shared.SerenityRideAPet.PetAgingModule =
        value

    return value
end

shared.SerenityRideAPet.ResolveEggKG = function(rawWeight)
    local raw =
        tonumber(rawWeight)

    if raw == nil then
        return nil, nil
    end

    local cacheKey =
        string.format("%.12g", raw)

    local cached =
        shared.SerenityRideAPet.EggKGCache[
            cacheKey
        ]

    if type(cached) == "table" then
        return cached.Value, cached.Text
    end

    local petAging =
        shared.SerenityRideAPet.GetPetAging()

    if not petAging then
        return nil, nil
    end

    local ok, formatted =
        pcall(
            petAging.FormatWeight,
            raw
        )

    if not ok
        or formatted == nil then

        return nil, nil
    end

    formatted =
        tostring(formatted)

    local numericText =
        formatted
        :gsub("<.->", "")
        :gsub(
            "%s*[Kk]%.?[Gg]%s*$",
            ""
        )

    local numeric =
        shared.SerenityRideAPet.ParseCompactNumber(
            numericText
        )

    if numeric == nil then
        local cleaned =
            string.lower(
                numericText
                :gsub("[%s,_]", "")
            )

        if cleaned == "inf"
            or cleaned == "infinity" then

            numeric = math.huge
        end
    end

    if numeric == nil then
        return nil, formatted
    end

    shared.SerenityRideAPet.EggKGCache[
        cacheKey
    ] = {
        Value = numeric,
        Text = formatted,
    }

    return numeric, formatted
end

shared.SerenityRideAPet.ActiveEggKG = function(active)
    if not active then
        return nil, nil, nil
    end

    local raw =
        tonumber(
            active:GetAttribute("Weight")
        )

    if raw == nil then
        return nil, nil, nil
    end

    local value, formatted =
        shared.SerenityRideAPet.ResolveEggKG(
            raw
        )

    return value, formatted, raw
end

shared.SerenityRideAPet.ToolEggKG = function(tool)
    if not tool then
        return nil, nil, nil
    end

    local raw =
        tonumber(
            tool:GetAttribute("Weight")
        )

    if raw == nil then
        local data =
            tool:FindFirstChild("Data")

        local weight =
            data
            and data:FindFirstChild("Weight")

        if weight and weight:IsA("ValueBase") then
            raw = tonumber((weight :: any).Value)
        elseif data then
            raw =
                tonumber(
                    data:GetAttribute("Weight")
                )
        end
    end

    if raw == nil then
        return nil, nil, nil
    end

    local value, formatted =
        shared.SerenityRideAPet.ResolveEggKG(
            raw
        )

    return value, formatted, raw
end

shared.SerenityRideAPet.CleanEggKGText = function(
    formatted,
    fallbackValue
)
    if type(formatted) == "string"
        and formatted ~= "" then

        return
            formatted
            :gsub(
                "%s*[Kk]%.?[Gg]%s*$",
                ""
            )
    end

    if fallbackValue ~= nil then
        return tostring(fallbackValue)
    end

    return "?"
end

shared.SerenityRideAPet.MaximumSellPerSecond = function()
    return shared.SerenityRideAPet.ParseCompactNumber(
        Config.AutoSellMaxPerSecond
    ) or 0
end

shared.SerenityRideAPet.SellRateCache =
    shared.SerenityRideAPet.SellRateCache or {}

shared.SerenityRideAPet.SellRuntime =
    shared.SerenityRideAPet.SellRuntime
    or {
        LastAttempt = 0,
    }

if shared.SerenityRideAPet.ParseCompactNumber(Config.StealMinKG) == nil then
    Config.StealMinKG = "0"
    saveConfig()
end

if shared.SerenityRideAPet.ParseCompactNumber(Config.PlaceMinKG) == nil then
    Config.PlaceMinKG = "0"
    saveConfig()
end

if shared.SerenityRideAPet.ParseCompactNumber(
    Config.AutoSellMaxPerSecond
) == nil then
    Config.AutoSellMaxPerSecond = "0"
    saveConfig()
end

Config.PlaceKnownMaxEggs =
    math.max(
        0,
        math.floor(
            tonumber(Config.PlaceKnownMaxEggs) or 0
        )
    )

shared.SerenityRideAPet.Save = saveConfig
shared.SerenityRideAPet.Set = function(key, value)
    local ok, err = setConfig(key, value)
    shared.SerenityRideAPet.Config = Config
    return ok, err
end

shared.SerenityRideAPet.SetNested = function(group, key, value)
    local ok, err = setNestedConfig(group, key, value)
    shared.SerenityRideAPet.Config = Config
    return ok, err
end

shared.SerenityRideAPet.Reset = function()
    Config = deepCopy(DEFAULT_CONFIG)
    saveConfig()
    shared.SerenityRideAPet.Config = Config

    if type(shared.SerenityRideAPet.RefreshOptimizations) == "function" then
        shared.SerenityRideAPet.RefreshOptimizations()
    end

    return true
end

-- ============================================================
-- CLIENT OPTIMIZATION
-- Reversible, client-only performance controls.
-- ============================================================

shared.SerenityRideAPet.OptimizationState =
    shared.SerenityRideAPet.OptimizationState
    or {
        Saved = {},
        Connections = {},
        RefreshQueued = false,
        BlackScreenGui = nil,
    }

shared.SerenityRideAPet.OptimizationSaveSet = function(instance, property, value)
    if typeof(instance) ~= "Instance" then
        return false
    end

    local state = shared.SerenityRideAPet.OptimizationState
    local saved = state.Saved[instance]

    if not saved then
        saved = {}
        state.Saved[instance] = saved
    end

    if saved[property] == nil then
        local okRead, original = pcall(function()
            return instance[property]
        end)

        if not okRead then
            return false
        end

        saved[property] = original
    end

    return pcall(function()
        instance[property] = value
    end)
end

shared.SerenityRideAPet.RestoreOptimizationVisuals = function()
    local state = shared.SerenityRideAPet.OptimizationState

    for _, connection in ipairs(state.Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    state.Connections = {}

    for instance, properties in pairs(state.Saved) do
        if typeof(instance) == "Instance"
            and instance.Parent ~= nil then

            for property, original in pairs(properties) do
                pcall(function()
                    instance[property] = original
                end)
            end
        end
    end

    state.Saved = {}
end

shared.SerenityRideAPet.ApplyReduceLagInstance = function(instance)
    if typeof(instance) ~= "Instance" then
        return
    end

    local set = shared.SerenityRideAPet.OptimizationSaveSet

    if instance:IsA("ParticleEmitter")
        or instance:IsA("Trail")
        or instance:IsA("Beam")
        or instance:IsA("Smoke")
        or instance:IsA("Fire")
        or instance:IsA("Sparkles") then

        set(instance, "Enabled", false)

    elseif instance:IsA("BasePart") then
        set(instance, "CastShadow", false)

    elseif instance:IsA("PostEffect") then
        set(instance, "Enabled", false)
    end
end

shared.SerenityRideAPet.ApplyOtherGardenInstance = function(instance)
    if typeof(instance) ~= "Instance" then
        return
    end

    local set = shared.SerenityRideAPet.OptimizationSaveSet

    if instance:IsA("BasePart") then
        set(instance, "LocalTransparencyModifier", 1)
        set(instance, "CastShadow", false)
        set(instance, "CanCollide", false)
        set(instance, "CanTouch", false)
        set(instance, "CanQuery", false)

    elseif instance:IsA("Decal") or instance:IsA("Texture") then
        set(instance, "Transparency", 1)

    elseif instance:IsA("ParticleEmitter")
        or instance:IsA("Trail")
        or instance:IsA("Beam")
        or instance:IsA("Smoke")
        or instance:IsA("Fire")
        or instance:IsA("Sparkles")
        or instance:IsA("Highlight")
        or instance:IsA("BillboardGui")
        or instance:IsA("SurfaceGui") then

        set(instance, "Enabled", false)
    end
end

shared.SerenityRideAPet.IsOtherPlayerPlot = function(plot)
    if typeof(plot) ~= "Instance" then
        return false
    end

    local owner = tonumber(plot:GetAttribute("NestsOwnerLoaded"))

    return owner ~= nil
        and owner > 0
        and owner ~= LP.UserId
end

shared.SerenityRideAPet.FindPlotAncestor = function(instance)
    local plots = Workspace:FindFirstChild("Plots")

    if not plots or not instance then
        return nil
    end

    local current = instance

    while current and current.Parent do
        if current.Parent == plots then
            return current
        end

        current = current.Parent
    end

    return nil
end

shared.SerenityRideAPet.RefreshBlackScreen = function()
    local state =
        shared.SerenityRideAPet.OptimizationState

    if Config.BlackScreen ~= true then
        if state.BlackScreenGui then
            pcall(function()
                state.BlackScreenGui:Destroy()
            end)

            state.BlackScreenGui = nil
        end

        return true
    end

    local playerGui =
        LP:FindFirstChildOfClass("PlayerGui")

    if not playerGui then
        playerGui =
            LP:WaitForChild(
                "PlayerGui",
                5
            )
    end

    if not playerGui then
        return false
    end

    local gui =
        state.BlackScreenGui

    if not gui
        or gui.Parent == nil then

        gui = Instance.new("ScreenGui")
        gui.Name = "SerenityRideAPetBlackScreen"
        gui.IgnoreGuiInset = true
        gui.ResetOnSpawn = false
        gui.DisplayOrder = -1000
        gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

        local frame =
            Instance.new("Frame")

        frame.Name = "Black"
        frame.BackgroundColor3 =
            Color3.new(0, 0, 0)
        frame.BackgroundTransparency = 0
        frame.BorderSizePixel = 0
        frame.Position =
            UDim2.fromScale(0, 0)
        frame.Size =
            UDim2.fromScale(1, 1)
        frame.Active = false
        frame.Selectable = false
        frame.ZIndex = 1
        frame.Parent = gui

        gui.Parent = playerGui
        state.BlackScreenGui = gui
    end

    gui.Enabled = true

    return true
end

shared.SerenityRideAPet.RefreshOptimizations = function()
    local state = shared.SerenityRideAPet.OptimizationState
    local Lighting = game:GetService("Lighting")

    -- Repeated teleports and heavy Workspace mutation do not mix well on
    -- long AFK sessions. Keep the two expensive Workspace optimizers disabled
    -- while either Auto Server Hop or Auto Reconnect can move this client.
    local hopOptimizationSafe =
        Config.AutoRejoinNoEgg ~= true
        and Config.AutoReconnectOnDisconnect ~= true

    local reduceLagEnabled =
        hopOptimizationSafe
        and Config.ReduceLag == true

    local removeOtherGardensEnabled =
        hopOptimizationSafe
        and Config.RemoveOtherGardens == true

    shared.SerenityRideAPet.RestoreOptimizationVisuals()

    pcall(function()
        RunService:Set3dRenderingEnabled(
            Config.Disable3DRendering ~= true
            and Config.BlackScreen ~= true
        )
    end)

    shared.SerenityRideAPet.RefreshBlackScreen()

    if reduceLagEnabled then
        shared.SerenityRideAPet.OptimizationSaveSet(
            Lighting,
            "GlobalShadows",
            false
        )

        shared.SerenityRideAPet.OptimizationSaveSet(
            Lighting,
            "EnvironmentDiffuseScale",
            0
        )

        shared.SerenityRideAPet.OptimizationSaveSet(
            Lighting,
            "EnvironmentSpecularScale",
            0
        )

        local terrain = Workspace:FindFirstChildOfClass("Terrain")

        if terrain then
            shared.SerenityRideAPet.OptimizationSaveSet(
                terrain,
                "Decoration",
                false
            )
            shared.SerenityRideAPet.OptimizationSaveSet(
                terrain,
                "WaterWaveSize",
                0
            )
            shared.SerenityRideAPet.OptimizationSaveSet(
                terrain,
                "WaterWaveSpeed",
                0
            )
            shared.SerenityRideAPet.OptimizationSaveSet(
                terrain,
                "WaterReflectance",
                0
            )
        end

        for _, instance in ipairs(Workspace:GetDescendants()) do
            shared.SerenityRideAPet.ApplyReduceLagInstance(instance)
        end

        for _, instance in ipairs(Lighting:GetDescendants()) do
            shared.SerenityRideAPet.ApplyReduceLagInstance(instance)
        end
    end

    local plots = Workspace:FindFirstChild("Plots")

    if removeOtherGardensEnabled and plots then
        for _, plot in ipairs(plots:GetChildren()) do
            if shared.SerenityRideAPet.IsOtherPlayerPlot(plot) then
                shared.SerenityRideAPet.ApplyOtherGardenInstance(plot)

                for _, instance in ipairs(plot:GetDescendants()) do
                    shared.SerenityRideAPet.ApplyOtherGardenInstance(instance)
                end
            end
        end
    end

    if reduceLagEnabled or removeOtherGardensEnabled then
        state.Connections[#state.Connections + 1] =
            Workspace.DescendantAdded:Connect(function(instance)
                if reduceLagEnabled then
                    shared.SerenityRideAPet.ApplyReduceLagInstance(instance)
                end

                if removeOtherGardensEnabled then
                    local plot =
                        shared.SerenityRideAPet.FindPlotAncestor(instance)

                    if plot
                        and shared.SerenityRideAPet.IsOtherPlayerPlot(plot) then

                        shared.SerenityRideAPet.ApplyOtherGardenInstance(instance)
                    end
                end
            end)
    end

    if reduceLagEnabled then
        state.Connections[#state.Connections + 1] =
            Lighting.DescendantAdded:Connect(function(instance)
                shared.SerenityRideAPet.ApplyReduceLagInstance(instance)
            end)
    end

    if removeOtherGardensEnabled and plots then
        local function attachPlot(plot)
            state.Connections[#state.Connections + 1] =
                plot:GetAttributeChangedSignal(
                    "NestsOwnerLoaded"
                ):Connect(function()
                    if state.RefreshQueued then
                        return
                    end

                    state.RefreshQueued = true

                    task.defer(function()
                        state.RefreshQueued = false
                        shared.SerenityRideAPet.RefreshOptimizations()
                    end)
                end)
        end

        for _, plot in ipairs(plots:GetChildren()) do
            attachPlot(plot)
        end

        state.Connections[#state.Connections + 1] =
            plots.ChildAdded:Connect(function(plot)
                attachPlot(plot)

                if shared.SerenityRideAPet.IsOtherPlayerPlot(plot) then
                    shared.SerenityRideAPet.ApplyOtherGardenInstance(plot)

                    for _, instance in ipairs(plot:GetDescendants()) do
                        shared.SerenityRideAPet.ApplyOtherGardenInstance(instance)
                    end
                end
            end)
    end

    return true
end

shared.SerenityRideAPet.DisableHopUnsafeOptimizations = function(adapter)
    local changed = false

    if Config.ReduceLag == true then
        Config.ReduceLag = false
        changed = true
    end

    if Config.RemoveOtherGardens == true then
        Config.RemoveOtherGardens = false
        changed = true
    end

    shared.SerenityRideAPet.Config = Config

    if changed then
        saveConfig()
    end

    -- Keep Serenity V3's separate UI-state config in sync too.
    if adapter then
        if type(adapter.SetLive) == "function" then
            pcall(function()
                adapter:SetLive(
                    "Misc.Optimization.ReduceLag",
                    false
                )
            end)

            pcall(function()
                adapter:SetLive(
                    "Misc.Optimization.RemoveOtherGardens",
                    false
                )
            end)
        end

        if adapter.Config
            and type(adapter.Config.Set) == "function" then

            pcall(function()
                adapter.Config:Set(
                    "Misc.Optimization.ReduceLag",
                    false,
                    true
                )

                adapter.Config:Set(
                    "Misc.Optimization.RemoveOtherGardens",
                    false,
                    true
                )

                if type(adapter.Config.SaveNow) == "function" then
                    adapter.Config:SaveNow()
                end
            end)
        end
    end

    shared.SerenityRideAPet.RefreshOptimizations()

    return changed
end

shared.SerenityRideAPet.SetOptimization = function(key, enabled)
    if key ~= "ReduceLag"
        and key ~= "Disable3DRendering"
        and key ~= "BlackScreen"
        and key ~= "RemoveOtherGardens" then

        return false, "unknown optimization"
    end

    if (
        Config.AutoRejoinNoEgg == true
        or Config.AutoReconnectOnDisconnect == true
    )
        and enabled == true
        and (
            key == "ReduceLag"
            or key == "RemoveOtherGardens"
        ) then

        Config[key] = false
        saveConfig()
        shared.SerenityRideAPet.Config = Config
        shared.SerenityRideAPet.RefreshOptimizations()

        return false, "disabled while Auto Server Hop or Auto Reconnect is enabled"
    end

    Config[key] = enabled == true
    saveConfig()
    shared.SerenityRideAPet.Config = Config

    shared.SerenityRideAPet.RefreshOptimizations()

    return true
end

-- Sanitize old gameplay configs immediately, before the first optimization
-- pass can touch Workspace in a teleporting session.
if Config.AutoRejoinNoEgg == true
    or Config.AutoReconnectOnDisconnect == true then

    shared.SerenityRideAPet.DisableHopUnsafeOptimizations(nil)
end

task.defer(function()
    shared.SerenityRideAPet.RefreshOptimizations()
end)

-- Diagnostic exports are assigned after diagnosticText/saveDiagnostic are
-- declared, avoiding forward-reference globals in strict Luau analyzers.

local function selectionHas(selection, wanted)
    if type(selection) ~= "table" then
        return false
    end

    wanted = tostring(wanted)

    if selection[wanted] == true then
        return true
    end

    for k, v in pairs(selection) do
        if type(k) == "number" and tostring(v) == wanted then
            return true
        end

        if tostring(k) == wanted and v == true then
            return true
        end
    end

    return false
end

local function selectionAsArray(selection)
    local out, seen = {}, {}

    if type(selection) ~= "table" then
        return out
    end

    for k, v in pairs(selection) do
        local value = nil

        if type(k) == "number" then
            value = v
        elseif v == true then
            value = k
        end

        if value ~= nil then
            value = tostring(value)
            if not seen[value] then
                seen[value] = true
                out[#out + 1] = value
            end
        end
    end

    table.sort(out)
    return out
end

local function saveSimpleSetting(key, value)
    local ok, err = setConfig(key, value)

    shared.SerenityRideAPet.Config = Config
    return ok
end

local out = {}

-- v80.2.99 production: diagnostics are OFF by default.
-- The logger remains available for targeted troubleshooting if explicitly enabled later.
shared.SerenityRideAPet.DiagnosticEnabled = false
shared.SerenityRideAPet.DiagnosticConsoleEnabled = false

-- Diagnostic logger remains available for targeted troubleshooting only.
-- v80.2.63: disk writes are batched instead of appendfile() on every log line.
-- This keeps the same evidence while reducing executor/mobile filesystem churn.
local function log(...)
    if shared.SerenityRideAPet.DiagnosticEnabled ~= true then
        return
    end

    local state =
        shared.SerenityRideAPet.DiagnosticRuntime

    if type(state) ~= "table"
        or state.Version ~= VERSION then

        state = {
            Version = VERSION,
            StartedAt = os.clock(),
            Lines = {},
            Pending = {},
            File = "SerenityHub/RideAPet_v80_2_97_PERF_DIAGNOSTIC.txt",
            Initialized = false,
            LastFlushAt = 0,
        }

        shared.SerenityRideAPet.DiagnosticRuntime =
            state
    end

    state.Lines =
        state.Lines
        or {}

    state.Pending =
        state.Pending
        or {}

    local now =
        os.clock()

    local parts = {
        string.format(
            "[%08.3f]",
            now
                - (
                    tonumber(state.StartedAt)
                    or now
                )
        ),
    }

    for i = 1, select("#", ...) do
        parts[#parts + 1] =
            tostring(
                select(i, ...)
            )
    end

    local line =
        table.concat(
            parts,
            " | "
        )

    state.Lines[#state.Lines + 1] =
        line

    state.Pending[#state.Pending + 1] =
        line

    if shared.SerenityRideAPet.DiagnosticConsoleEnabled == true then
        print(
            "[SERENITY RAP]",
            line
        )
    end

    local shouldFlush =
        state.Initialized ~= true
        or #state.Pending >= 24
        or now
            - (
                tonumber(state.LastFlushAt)
                or 0
            )
            >= 0.75

    if not shouldFlush then
        return
    end

    pcall(function()
        local env =
            (type(getgenv) == "function" and getgenv())
            or _G

        local append =
            rawget(env, "appendfile")
            or rawget(_G, "appendfile")

        local writer =
            rawget(env, "writefile")
            or rawget(_G, "writefile")

        local folderFn =
            rawget(env, "makefolder")
            or rawget(_G, "makefolder")

        local isFolderFn =
            rawget(env, "isfolder")
            or rawget(_G, "isfolder")

        if state.Initialized ~= true then
            if type(folderFn) == "function"
                and (
                    type(isFolderFn) ~= "function"
                    or not isFolderFn("SerenityHub")
                ) then

                pcall(
                    folderFn,
                    "SerenityHub"
                )
            end

            if type(writer) == "function" then
                writer(
                    state.File,
                    "SERENITY HUB — RIDE A PET DIAGNOSTIC\n"
                    .. "VERSION="
                    .. tostring(VERSION)
                    .. "\n"
                )

                state.Initialized = true
            end
        end

        if type(append) == "function"
            and state.Initialized == true
            and #state.Pending > 0 then

            append(
                state.File,
                table.concat(
                    state.Pending,
                    "\n"
                )
                .. "\n"
            )

            table.clear(
                state.Pending
            )

            state.LastFlushAt =
                now
        end
    end)
end

shared.SerenityRideAPet.StreamingRuntime =
    shared.SerenityRideAPet.StreamingRuntime
    or {
        Busy = false,
        BusySince = 0,
        Serial = 0,
        LastRequestAt = 0,
        LastPosition = nil,
    }

shared.SerenityRideAPet.QueueStreamRequest = function(position, timeout)
    if Workspace.StreamingEnabled == false
        or typeof(position) ~= "Vector3" then

        return false
    end

    local runtime =
        shared.SerenityRideAPet.StreamingRuntime

    local now =
        os.clock()

    if runtime.Busy == true
        and now - (tonumber(runtime.BusySince) or now) > 8 then

        runtime.Busy = false
    end

    if runtime.Busy == true then
        return false
    end

    if now - (tonumber(runtime.LastRequestAt) or 0) < 0.35 then
        return false
    end

    if typeof(runtime.LastPosition) == "Vector3"
        and (runtime.LastPosition - position).Magnitude < 120
        and now - (tonumber(runtime.LastRequestAt) or 0) < 1.5 then

        return false
    end

    runtime.Serial =
        (tonumber(runtime.Serial) or 0)
        + 1

    local serial =
        runtime.Serial

    runtime.Busy = true
    runtime.BusySince = now
    runtime.LastRequestAt = now
    runtime.LastPosition = position

    task.spawn(function()
        pcall(function()
            LP:RequestStreamAroundAsync(
                position,
                tonumber(timeout) or 1.5
            )
        end)

        if runtime.Serial == serial then
            runtime.Busy = false
            runtime.BusySince = 0
        end
    end)

    return true
end

local function prestreamDestination(position, label)
    if typeof(position) ~= "Vector3" then
        return false
    end

    if Workspace.StreamingEnabled == false then
        return true
    end

    -- Only bother for meaningful long-distance movement.
    local currentRoot =
        LP.Character
        and LP.Character:FindFirstChild(
            "HumanoidRootPart"
        )

    if currentRoot
        and (
            currentRoot.Position
            - position
        ).Magnitude < 150 then

        return true
    end

    -- v80.2.54 MOBILE FIX:
    --
    -- RequestStreamAroundAsync() yields the calling coroutine until Roblox
    -- finishes streaming the destination or reaches its timeout. On desktop
    -- this often returned quickly, but on phones it could consume most/all of
    -- the old 4-second timeout before Auto Steal even began moving.
    --
    -- QueueStreamRequest already performs the same request inside task.spawn,
    -- so use that here and let segmented movement start immediately. Long
    -- travel naturally gives streaming time to catch up while we are moving.
    local queued =
        shared.SerenityRideAPet
            .QueueStreamRequest(
                position,
                4
            )

    log(
        (label or "Stream")
        .. ".PreStreamAsyncQueued="
        .. tostring(queued)
    )

    return true
end


local function tweenTravel(targetCFrame, speed, label)
    -- v80.2.58:
    -- Generic movement is now INSTANT for normal Auto Steal and normal
    -- utility movement.
    --
    -- IMPORTANT:
    -- The special Volcanic Egg route does NOT use this helper for its proven
    -- entry/interior/exit path. It keeps segmented tween/collision-aware
    -- movement exactly as before.
    local char = LP.Character
    local root =
        char
        and char:FindFirstChild(
            "HumanoidRootPart"
        )

    if not root then
        return
            false,
            "HumanoidRootPart missing"
    end

    local targetPos =
        targetCFrame.Position

    local distance =
        (
            root.Position
            - targetPos
        ).Magnitude

    log(
        (label or "Teleport")
        .. ".MovementMode=INSTANT_TELEPORT"
    )

    log(
        (label or "Teleport")
        .. ".TeleportDistance="
        .. tostring(distance)
    )

    -- Non-blocking destination streaming request only.
    if Workspace.StreamingEnabled then
        shared.SerenityRideAPet
            .QueueStreamRequest(
                targetPos,
                2
            )
    end

    root.AssemblyLinearVelocity =
        Vector3.zero

    root.AssemblyAngularVelocity =
        Vector3.zero

    root.CFrame =
        targetCFrame

    -- Tiny replication yield; do not turn this into a movement delay.
    task.wait()

    if not root.Parent
        or LP.Character ~= char then

        return
            false,
            "character changed during teleport"
    end

    local errorDistance =
        (
            root.Position
            - targetPos
        ).Magnitude

    log(
        (label or "Teleport")
        .. ".TeleportArrivalError="
        .. tostring(errorDistance)
    )

    if errorDistance <= 18 then
        return true, nil
    end

    return
        false,
        "teleport arrival error "
        .. tostring(errorDistance)
end

-- True tween movement used by normal Auto Steal when Instant Steal is OFF.
-- Kept on shared.SerenityRideAPet to avoid adding another top-level local
-- register in this already-large Luau chunk.
shared.SerenityRideAPet.SmoothTweenTravel =
    function(targetCFrame, speed, label)
        local char =
            LP.Character

        local root =
            char
            and char:FindFirstChild(
                "HumanoidRootPart"
            )

        if not root then
            return false,
                "HumanoidRootPart missing"
        end

        local targetPos =
            targetCFrame.Position

        local travelSpeed =
            math.clamp(
                tonumber(speed)
                    or EGG_TWEEN_SPEED,
                1,
                4000
            )

        local startCF =
            root.CFrame

        local stealRuntime =
            shared.SerenityRideAPet.StealActionRuntime

        local monitorStealStall =
            stealRuntime
            and stealRuntime.Busy == true
            and stealRuntime.VolcanicSpecial ~= true
            and stealRuntime.EmergencyReturn ~= true

        local lastProgressPosition =
            root.Position

        local lastProgressAt =
            os.clock()

        local distance =
            (
                root.Position
                - targetPos
            ).Magnitude

        log(
            (label or "Tween")
            .. ".MovementMode=TWEEN"
        )

        log(
            (label or "Tween")
            .. ".TweenDistance="
            .. tostring(distance)
        )

        log(
            (label or "Tween")
            .. ".TweenSpeed="
            .. tostring(travelSpeed)
        )

        if Workspace.StreamingEnabled then
            shared.SerenityRideAPet
                .QueueStreamRequest(
                    targetPos,
                    math.max(
                        2,
                        distance
                            / math.max(
                                travelSpeed,
                                1
                            )
                    )
                )
        end

        local segmentCount =
            math.max(
                1,
                math.ceil(
                    distance
                    / TWEEN_SEGMENT_LENGTH
                )
            )

        for i = 1, segmentCount do
            if not root.Parent
                or LP.Character ~= char then

                return false,
                    "character changed during tween"
            end

            local alpha =
                i / segmentCount

            local segmentCF =
                startCF:Lerp(
                    targetCFrame,
                    alpha
                )

            local segmentDistance =
                (
                    root.Position
                    - segmentCF.Position
                ).Magnitude

            local duration =
                math.max(
                    0.025,
                    segmentDistance
                        / math.max(
                            travelSpeed,
                            1
                        )
                )

            root.AssemblyLinearVelocity =
                Vector3.zero

            root.AssemblyAngularVelocity =
                Vector3.zero

            local tween =
                TweenService:Create(
                    root,
                    TweenInfo.new(
                        duration,
                        Enum.EasingStyle.Linear
                    ),
                    {
                        CFrame =
                            segmentCF,
                    }
                )

            local done = false

            local connection =
                tween.Completed:Connect(
                    function()
                        done = true
                    end
                )

            tween:Play()

            local deadline =
                os.clock()
                + duration
                + 0.85

            while not done
                and os.clock()
                    < deadline do

                if not root.Parent
                    or LP.Character
                        ~= char then

                    pcall(function()
                        tween:Cancel()
                    end)

                    pcall(function()
                        connection:Disconnect()
                    end)

                    return false,
                        "character changed during tween"
                end

                local movementRuntime =
                    shared.SerenityRideAPet
                        .MovementRuntime

                if movementRuntime then
                    movementRuntime.Heartbeat =
                        os.clock()
                end

                if monitorStealStall then
                    local moved =
                        (
                            root.Position
                            - lastProgressPosition
                        ).Magnitude

                    if moved >= 3 then
                        lastProgressPosition =
                            root.Position

                        lastProgressAt =
                            os.clock()
                    elseif os.clock()
                        - lastProgressAt
                        >= 10 then

                        if stealRuntime then
                            stealRuntime.AbortRequested = true
                            stealRuntime.AbortReason =
                                "normal steal made no movement progress for 10 seconds"
                        end

                        pcall(function()
                            tween:Cancel()
                        end)

                        pcall(function()
                            connection:Disconnect()
                        end)

                        log("")
                        log("=== STEAL_STUCK_FALLBACK ===")
                        log("Reason=no movement progress for 10 seconds")
                        log("Action=ABORT_AND_RETURN_HOME")

                        return false,
                            "steal movement stalled for 10 seconds"
                    end
                end

                task.wait(0.02)
            end

            pcall(function()
                connection:Disconnect()
            end)

            if not done then
                pcall(function()
                    tween:Cancel()
                end)

                return false,
                    "tween timeout"
            end
        end

        root.AssemblyLinearVelocity =
            Vector3.zero

        root.AssemblyAngularVelocity =
            Vector3.zero

        local errorDistance =
            (
                root.Position
                - targetPos
            ).Magnitude

        log(
            (label or "Tween")
            .. ".TweenArrivalError="
            .. tostring(
                errorDistance
            )
        )

        if errorDistance <= 18 then
            return true, nil
        end

        return
            false,
            "tween arrival error "
            .. tostring(
                errorDistance
            )
    end

shared.SerenityRideAPet.AutoStealTweenSpeed =
    function()
        return
            math.clamp(
                tonumber(
                    shared.SerenityRideAPet.ActiveStealSetting(
                        "GardenReturnTweenSpeed",
                        EGG_TWEEN_SPEED
                    )
                )
                    or EGG_TWEEN_SPEED,
                250,
                4000
            )
    end

shared.SerenityRideAPet.AutoStealTravel =
    function(targetCFrame, speed, label)
        local stopHold =
            shared.SerenityRideAPet.StopStealHoverHold

        if type(stopHold) == "function" then
            pcall(
                stopHold,
                "travel:" .. tostring(label or "AutoStealTravel")
            )
        end

        local runtime =
            shared.SerenityRideAPet.StealActionRuntime

        local forceInstant =
            runtime
            and runtime.EmergencyReturn == true

        local instantSteal =
            forceInstant
            or (
                shared.SerenityRideAPet.ActiveStealSetting(
                    "InstantSteal",
                    false
                ) == true
            )

        if instantSteal then

            -- Emergency return also uses this direct helper so a physics/tween
            -- stall cannot trap the character away from base.
            return
                tweenTravel(
                    targetCFrame,
                    speed,
                    label
                )
        end

        return
            shared.SerenityRideAPet
                .SmoothTweenTravel(
                    targetCFrame,
                    speed,
                    label
                )
    end


local function diagnosticText()
    local state =
        shared.SerenityRideAPet.DiagnosticRuntime

    if type(state) ~= "table"
        or type(state.Lines) ~= "table" then

        return ""
    end

    return table.concat(
        state.Lines,
        "\n"
    )
end

local function saveDiagnostic()
    if shared.SerenityRideAPet.DiagnosticEnabled ~= true then
        return false, "diagnostic logging disabled in production"
    end

    local state =
        shared.SerenityRideAPet.DiagnosticRuntime

    if type(state) ~= "table" then
        return false, "diagnostic runtime not started yet"
    end

    if not writefile_f then
        return false, "writefile unavailable"
    end

    local ok, err =
        pcall(function()
            if makefolder_f
                and (
                    not isfolder_f
                    or not isfolder_f(
                        CONFIG_FOLDER
                    )
                ) then

                makefolder_f(
                    CONFIG_FOLDER
                )
            end

            writefile_f(
                state.File
                    or "SerenityHub/RideAPet_v80_2_97_PERF_DIAGNOSTIC.txt",
                "SERENITY HUB — RIDE A PET DIAGNOSTIC\n"
                .. "VERSION="
                .. tostring(VERSION)
                .. "\n"
                .. diagnosticText()
                .. "\n"
            )
        end)

    if not ok then
        return false, tostring(err)
    end

    return true,
        state.File
        or "SerenityHub/RideAPet_v80_2_97_PERF_DIAGNOSTIC.txt"
end

shared.SerenityRideAPet.GetDiagnosticLog =
    diagnosticText

shared.SerenityRideAPet.SaveDiagnosticLog =
    saveDiagnostic

local function finalize()
end

local function hasTag(inst, tag)
    local ok, yes = pcall(function()
        return CollectionService:HasTag(inst, tag)
    end)
    return ok and yes
end

local function roots()
    return {
        Character,
        Backpack,
        Workspace:FindFirstChild(LP.Name),
    }
end

local function eggTools()
    local list, seen = {}, {}

    for _, root in ipairs(roots()) do
        if root then
            for _, x in ipairs(root:GetChildren()) do
                if not seen[x] and x:IsA("Tool") and hasTag(x, "Egg") then
                    seen[x] = true
                    list[#list+1] = x
                end
            end
        end
    end

    return list
end

local function petTools()
    local list, seen = {}, {}

    for _, root in ipairs(roots()) do
        if root then
            for _, x in ipairs(root:GetChildren()) do
                if not seen[x] and x:IsA("Tool") and hasTag(x, "Pet") then
                    seen[x] = true
                    list[#list+1] = x
                end
            end
        end
    end

    return list
end

local function baseEggName(toolName)
    local n = tostring(toolName or "")
    n = n:gsub("%s*%[[^%]]+%]%s*$", "")
    n = n:gsub("%s*%([^%)]*%)%s*$", "")
    return n
end

local function collectedString()
    local v = LP:GetAttribute("CollectedEggs")
    return typeof(v) == "string" and v or ""
end

local function collectedHas(name)
    local s = collectedString()
    return s ~= "" and string.find(s, tostring(name), 1, true) ~= nil
end

local function promptPosition(prompt)
    if not prompt or not prompt.Parent then return nil end

    local p = prompt.Parent

    if p:IsA("Attachment") then
        return p.WorldPosition
    elseif p:IsA("BasePart") then
        return p.Position
    end

    local x = p
    while x and x ~= Workspace do
        if x:IsA("BasePart") then
            return x.Position
        elseif x:IsA("Model") then
            local ok, cf = pcall(function() return x:GetPivot() end)
            if ok then return cf.Position end
        end
        x = x.Parent
    end

    return nil
end

local function restore(cf)
    pcall(function()
        HRP.AssemblyLinearVelocity = Vector3.zero
        HRP.AssemblyAngularVelocity = Vector3.zero
        HRP.CFrame = cf
    end)
end


local function findOwnGardenBaseplate()
    local plots = Workspace:FindFirstChild("Plots")
    if not plots then return nil, nil end

    for _, plot in ipairs(plots:GetChildren()) do
        if plot:GetAttribute("NestsOwnerLoaded") == LP.UserId then
            local base = plot:FindFirstChild("Baseplate")

            if base and base:IsA("BasePart") then
                return plot, base
            end

            -- Fallback: use the largest horizontal BasePart in the own plot.
            local best, bestArea
            for _, d in ipairs(plot:GetDescendants()) do
                if d:IsA("BasePart") then
                    local area = d.Size.X * d.Size.Z
                    if not bestArea or area > bestArea then
                        best = d
                        bestArea = area
                    end
                end
            end

            return plot, best
        end
    end

    return nil, nil
end

local function ownGardenReferenceCFrame()
    local _, base =
        findOwnGardenBaseplate()

    if base
        and base:IsA("BasePart") then

        return
            CFrame.new(
                base.Position
                + Vector3.new(
                    0,
                    base.Size.Y * 0.5 + 3.2,
                    0
                )
            )
    end

    return HRP.CFrame
end

local function ownGardenEntryPoints(fromPosition, savedGardenCFrame)
    local plot, base = findOwnGardenBaseplate()

    if base then
        local localFrom = base.CFrame:PointToObjectSpace(fromPosition)
        local halfX = base.Size.X * 0.5
        local halfZ = base.Size.Z * 0.5

        local edgeX = math.clamp(localFrom.X, -halfX, halfX)
        local edgeZ = math.clamp(localFrom.Z, -halfZ, halfZ)

        -- If the projected point is already inside the rectangle, choose the
        -- nearest edge facing the incoming position.
        if math.abs(localFrom.X) < halfX and math.abs(localFrom.Z) < halfZ then
            local dx = halfX - math.abs(localFrom.X)
            local dz = halfZ - math.abs(localFrom.Z)

            if dx < dz then
                edgeX = localFrom.X >= 0 and halfX or -halfX
            else
                edgeZ = localFrom.Z >= 0 and halfZ or -halfZ
            end
        end

        local edgeLocal = Vector3.new(
            edgeX,
            base.Size.Y * 0.5 + 3.2,
            edgeZ
        )

        local edgeWorld = base.CFrame:PointToWorldSpace(edgeLocal)

        local outward = Vector3.new(
            fromPosition.X - edgeWorld.X,
            0,
            fromPosition.Z - edgeWorld.Z
        )

        if outward.Magnitude < 0.1 then
            outward = Vector3.new(
                fromPosition.X - base.Position.X,
                0,
                fromPosition.Z - base.Position.Z
            )
        end

        if outward.Magnitude < 0.1 then
            outward = Vector3.new(1, 0, 0)
        else
            outward = outward.Unit
        end

        local outside = Vector3.new(
            edgeWorld.X,
            savedGardenCFrame.Position.Y,
            edgeWorld.Z
        ) + outward * GARDEN_OUTSIDE_STOP_DISTANCE

        local inside = Vector3.new(
            edgeWorld.X,
            savedGardenCFrame.Position.Y,
            edgeWorld.Z
        ) - outward * GARDEN_INSIDE_WALK_DISTANCE

        return outside, inside, plot, base
    end

    -- Fallback: saved starting CFrame is known to be the user's garden area.
    local saved = savedGardenCFrame.Position
    local outward = Vector3.new(
        fromPosition.X - saved.X,
        0,
        fromPosition.Z - saved.Z
    )

    if outward.Magnitude < 0.1 then
        outward = Vector3.new(1, 0, 0)
    else
        outward = outward.Unit
    end

    return saved + outward * GARDEN_OUTSIDE_STOP_DISTANCE, saved, nil, nil
end


local function beginTemporaryCharacterNoclip(label)
    -- v80.2.92: automatic noclip remains scoped. Normal-steal outbound travel
    -- is unchanged; the dedicated Volcanic Egg acquisition now intentionally
    -- uses short Chilli-style noclip movement for door/inside travel, while
    -- return-home paths keep their existing temporary noclip behavior.
    local char = LP.Character

    if not char then
        return function() end
    end

    local originals = {}
    local alive = true

    local function apply(part)
        if not alive
            or not part
            or not part:IsA("BasePart") then

            return
        end

        if originals[part] == nil then
            originals[part] = part.CanCollide
        end

        if part.CanCollide then
            part.CanCollide = false
        end
    end

    for _, part in ipairs(char:GetDescendants()) do
        apply(part)
    end

    local addedConnection =
        char.DescendantAdded:Connect(apply)

    local stepConnection =
        RunService.Stepped:Connect(function()
            if not alive
                or LP.Character ~= char then

                return
            end

            for part in pairs(originals) do
                if part
                    and part.Parent
                    and part.CanCollide then

                    part.CanCollide = false
                end
            end
        end)

    log(
        tostring(label or "Auto")
        .. ".NoclipUsed=true"
    )

    return function()
        if not alive then
            return
        end

        alive = false

        pcall(function()
            addedConnection:Disconnect()
        end)

        pcall(function()
            stepConnection:Disconnect()
        end)

        -- Respect the user's manual Noclip toggle. If it is ON, leave parts
        -- non-collidable and let the manual movement controller own them.
        if Config.PlayerNoclip ~= true then
            for part, wasCollidable in pairs(originals) do
                if part and part.Parent then
                    pcall(function()
                        part.CanCollide = wasCollidable
                    end)
                end
            end
        end

        table.clear(originals)
    end
end

-- ============================================================
-- v80.2.90 — SHORT-LIVED STEAL / MUTATION HOVER HOLD
--
-- After Serenity reaches a normal steal pickup point or the Volcano mutation
-- hover point, keep the character at that exact CFrame until the next travel
-- begins. This prevents gravity, residual velocity, floor collision, or physics
-- ownership from slowly dragging the character away / into the void while the
-- script is waiting for a server acknowledgement.
--
-- The proven dedicated Volcanic Egg route never starts this hold.
-- ============================================================
shared.SerenityRideAPet.StealHoverHoldRuntime =
    shared.SerenityRideAPet.StealHoverHoldRuntime
    or {
        Connection = nil,
        NoclipCleanup = nil,
        Root = nil,
        Character = nil,
        CFrame = nil,
        Label = nil,
    }

shared.SerenityRideAPet.StopStealHoverHold = function(reason)
    local state =
        shared.SerenityRideAPet.StealHoverHoldRuntime

    if type(state) ~= "table" then
        return false
    end

    local hadHold =
        state.Connection ~= nil
        or state.NoclipCleanup ~= nil
        or state.CFrame ~= nil

    if state.Connection then
        pcall(function()
            state.Connection:Disconnect()
        end)
        state.Connection = nil
    end

    if state.NoclipCleanup then
        pcall(state.NoclipCleanup)
        state.NoclipCleanup = nil
    end

    local root = state.Root
    if root and root.Parent then
        pcall(function()
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end)
    end

    if hadHold then
        log(
            tostring(state.Label or "StealHover")
            .. ".PositionHold=false"
        )
        log(
            tostring(state.Label or "StealHover")
            .. ".PositionHoldStopReason="
            .. tostring(reason or "stop")
        )
    end

    state.Root = nil
    state.Character = nil
    state.CFrame = nil
    state.Label = nil

    return hadHold
end

shared.SerenityRideAPet.StartStealHoverHold = function(
    holdCFrame,
    label,
    useNoclip
)
    if typeof(holdCFrame) ~= "CFrame" then
        return false, "hold CFrame missing"
    end

    shared.SerenityRideAPet.StopStealHoverHold(
        "replace"
    )

    shared.SerenityRideAPet.RefreshRuntimeCharacterRefs(0)

    local char = LP.Character
    local root = HRP

    if not char
        or not root
        or not root.Parent then

        return false, "HumanoidRootPart missing"
    end

    local state =
        shared.SerenityRideAPet.StealHoverHoldRuntime

    state.Root = root
    state.Character = char
    state.CFrame = holdCFrame
    state.Label = tostring(label or "StealHover")

    if useNoclip == true then
        state.NoclipCleanup =
            beginTemporaryCharacterNoclip(
                state.Label .. ".Hold"
            )
    end

    local function pin()
        if LP.Character ~= char
            or not root.Parent then

            return
        end

        pcall(function()
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            root.CFrame = holdCFrame
        end)
    end

    pin()

    state.Connection =
        RunService.Heartbeat:Connect(pin)

    log(state.Label .. ".PositionHold=true")
    log(
        state.Label
        .. ".PositionHoldNoclip="
        .. tostring(useNoclip == true)
    )
    log(
        state.Label
        .. ".PositionHoldCFrame="
        .. tostring(holdCFrame)
    )

    return true
end

-- ============================================================
-- MANUAL PLAYER MOVEMENT CONTROLS
-- v80.2.48: low-overhead Noclip / Speed Hack / Fly.
-- Disabled features keep no per-frame worker alive.
-- ============================================================
do
    local inputService = game:GetService("UserInputService")

    local previous = shared.SerenityRideAPet.PlayerMovementRuntime

    if type(previous) == "table"
        and type(previous.Cleanup) == "function" then
        pcall(previous.Cleanup)
    end

    local runtime = {
        NoclipOriginal = {},
        NoclipAddedConnection = nil,
        NoclipStepConnection = nil,
        SpeedHumanoid = nil,
        SpeedOriginal = nil,
        SpeedConnection = nil,
        FlyAttachment = nil,
        FlyVelocity = nil,
        FlyConnection = nil,
        CharacterConnection = nil,
    }

    shared.SerenityRideAPet.PlayerMovementRuntime = runtime

    local function disconnect(field)
        local connection = runtime[field]
        if connection then
            pcall(function() connection:Disconnect() end)
            runtime[field] = nil
        end
    end

    local function movementLaneBusyNow()
        local fn = shared.SerenityRideAPet.IsMovementLaneBusy
        if type(fn) == "function" then
            local ok, busy = pcall(fn)
            if ok and busy == true then
                return true
            end
        end

        return type(shared.SerenityRideAPet.IsStealActionBusy) == "function"
            and shared.SerenityRideAPet.IsStealActionBusy()
    end

    local function stopNoclip(restore)
        disconnect("NoclipAddedConnection")
        disconnect("NoclipStepConnection")

        if restore ~= false then
            local stealBusy = type(shared.SerenityRideAPet.IsStealActionBusy) == "function"
                and shared.SerenityRideAPet.IsStealActionBusy()

            for part, wasCollidable in pairs(runtime.NoclipOriginal) do
                if part and part.Parent and not stealBusy then
                    pcall(function() part.CanCollide = wasCollidable end)
                end
            end
        end

        table.clear(runtime.NoclipOriginal)
    end

    local function startNoclip()
        stopNoclip(true)
        local char = LP.Character
        if not char then return false end

        local function track(part)
            if not part or not part:IsA("BasePart") then return end
            if runtime.NoclipOriginal[part] == nil then
                runtime.NoclipOriginal[part] = part.CanCollide
            end
            if part.CanCollide then part.CanCollide = false end
        end

        for _, part in ipairs(char:GetDescendants()) do track(part) end
        runtime.NoclipAddedConnection = char.DescendantAdded:Connect(track)

        runtime.NoclipStepConnection = RunService.Stepped:Connect(function()
            if Config.PlayerNoclip ~= true or LP.Character ~= char or not char.Parent then
                return
            end
            for part in pairs(runtime.NoclipOriginal) do
                if part and part.Parent and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end)

        return true
    end

    local function stopSpeed(restore)
        disconnect("SpeedConnection")
        if restore ~= false and runtime.SpeedHumanoid and runtime.SpeedHumanoid.Parent
            and runtime.SpeedOriginal ~= nil then
            pcall(function() runtime.SpeedHumanoid.WalkSpeed = runtime.SpeedOriginal end)
        end
        runtime.SpeedHumanoid = nil
        runtime.SpeedOriginal = nil
    end

    local function desiredWalkSpeed()
        return math.floor(math.clamp(tonumber(Config.SpeedHackSpeed) or 16, 16, 5000) + 0.5)
    end

    local function startSpeed()
        stopSpeed(true)
        shared.SerenityRideAPet.RefreshRuntimeCharacterRefs(0)
        local humanoid = Humanoid
        if not humanoid or not humanoid.Parent then return false end

        runtime.SpeedHumanoid = humanoid
        runtime.SpeedOriginal = humanoid.WalkSpeed

        local function apply()
            if Config.SpeedHackEnabled ~= true or runtime.SpeedHumanoid ~= humanoid or not humanoid.Parent then
                return
            end
            local wanted = desiredWalkSpeed()
            if math.abs(humanoid.WalkSpeed - wanted) > 0.01 then
                humanoid.WalkSpeed = wanted
            end
        end

        apply()
        runtime.SpeedConnection = humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(apply)
        return true
    end

    local function destroyFlyObjects()
        disconnect("FlyConnection")
        if runtime.FlyVelocity then pcall(function() runtime.FlyVelocity:Destroy() end) end
        if runtime.FlyAttachment then pcall(function() runtime.FlyAttachment:Destroy() end) end
        runtime.FlyVelocity = nil
        runtime.FlyAttachment = nil
    end

    local function startFly()
        destroyFlyObjects()
        shared.SerenityRideAPet.RefreshRuntimeCharacterRefs(0)
        local humanoid = Humanoid
        local root = HRP
        if not humanoid or not humanoid.Parent or not root or not root.Parent then return false end

        local attachment = Instance.new("Attachment")
        attachment.Name = "SerenityManualFlyAttachment"
        attachment.Parent = root

        local velocity = Instance.new("LinearVelocity")
        velocity.Name = "SerenityManualFlyVelocity"
        velocity.Attachment0 = attachment
        velocity.RelativeTo = Enum.ActuatorRelativeTo.World
        velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
        velocity.MaxForce = math.huge
        velocity.VectorVelocity = Vector3.zero
        velocity.Parent = root

        runtime.FlyAttachment = attachment
        runtime.FlyVelocity = velocity

        runtime.FlyConnection = RunService.RenderStepped:Connect(function()
            if Config.FlyEnabled ~= true or LP.Character ~= Character or HRP ~= root
                or not root.Parent or not humanoid.Parent then return end

            if movementLaneBusyNow() then
                velocity.Enabled = false
                velocity.VectorVelocity = Vector3.zero
                return
            end

            if velocity.Enabled == false then
                velocity.Enabled = true
            end

            local speed = math.clamp(tonumber(Config.FlySpeed) or 70, 1, 5000)
            local horizontal = humanoid.MoveDirection
            if horizontal.Magnitude > 1 then horizontal = horizontal.Unit end

            local vertical = 0
            if humanoid.Jump or inputService:IsKeyDown(Enum.KeyCode.Space)
                or inputService:IsKeyDown(Enum.KeyCode.E) then vertical += 1 end
            if inputService:IsKeyDown(Enum.KeyCode.LeftControl)
                or inputService:IsKeyDown(Enum.KeyCode.LeftShift)
                or inputService:IsKeyDown(Enum.KeyCode.Q) then vertical -= 1 end

            velocity.VectorVelocity = horizontal * speed + Vector3.new(0, vertical * speed, 0)
        end)

        return true
    end

    shared.SerenityRideAPet.SetPlayerNoclip = function(enabled)
        if enabled == true then return startNoclip() end
        stopNoclip(true)
        return true
    end

    shared.SerenityRideAPet.SetSpeedHack = function(enabled)
        if enabled == true then return startSpeed() end
        stopSpeed(true)
        return true
    end

    shared.SerenityRideAPet.SetSpeedHackSpeed = function(value)
        Config.SpeedHackSpeed = math.floor(math.clamp(tonumber(value) or 16, 16, 5000) + 0.5)
        if Config.SpeedHackEnabled == true and runtime.SpeedHumanoid and runtime.SpeedHumanoid.Parent then
            local wanted = desiredWalkSpeed()
            if runtime.SpeedHumanoid.WalkSpeed ~= wanted then runtime.SpeedHumanoid.WalkSpeed = wanted end
        end
        return Config.SpeedHackSpeed
    end

    shared.SerenityRideAPet.SetFly = function(enabled)
        if enabled == true then return startFly() end
        destroyFlyObjects()
        return true
    end

    shared.SerenityRideAPet.SetFlySpeed = function(value)
        Config.FlySpeed = math.floor(math.clamp(tonumber(value) or 70, 1, 5000) + 0.5)
        return Config.FlySpeed
    end

    shared.SerenityRideAPet.RefreshPlayerMovementSettings = function()
        if Config.PlayerNoclip == true then startNoclip() else stopNoclip(true) end
        if Config.SpeedHackEnabled == true then startSpeed() else stopSpeed(true) end
        if Config.FlyEnabled == true then startFly() else destroyFlyObjects() end
        return true
    end

    runtime.CharacterConnection = LP.CharacterAdded:Connect(function()
        task.delay(0.35, function()
            if shared.SerenityRideAPet.PlayerMovementRuntime ~= runtime then return end
            shared.SerenityRideAPet.RefreshRuntimeCharacterRefs(0.5)
            shared.SerenityRideAPet.RefreshPlayerMovementSettings()
        end)
    end)

    runtime.Cleanup = function()
        disconnect("CharacterConnection")
        destroyFlyObjects()
        stopSpeed(true)
        stopNoclip(true)
    end

    task.defer(function()
        if shared.SerenityRideAPet.PlayerMovementRuntime == runtime then
            shared.SerenityRideAPet.RefreshPlayerMovementSettings()
        end
    end)
end

local function fastWalkIntoOwnGarden(fromPosition, savedGardenCFrame, label)
    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")

    if not root then
        return false, "HumanoidRootPart missing"
    end

    local outside, inside, plot, base =
        ownGardenEntryPoints(fromPosition, savedGardenCFrame)

    log(label .. ".OwnGardenPlot=" .. tostring(
        plot and plot:GetFullName() or "<fallback-saved-position>"
    ))
    log(label .. ".OwnGardenBaseplate=" .. tostring(
        base and base:GetFullName() or "<fallback>"
    ))
    log(label .. ".GardenTarget=" .. tostring(inside))

    -- SHALLOW VOID RETURN:
    -- Leave the visible map, travel in a hidden band just below it, then rise
    -- DIRECTLY into the user's garden. This avoids the old ~700-stud deep dive.
    local routeReferenceY =
        math.min(
            root.Position.Y,
            inside.Y
        )

    if base then
        local baseBottomY =
            base.Position.Y
            - base.Size.Y * 0.5

        -- Anchor the hidden route to the actual garden/map floor whenever
        -- available, rather than to an unusually high character position.
        routeReferenceY =
            math.min(
                routeReferenceY,
                baseBottomY
            )
    end

    local voidY =
        routeReferenceY
        - VOID_RETURN_DEPTH

    local dropPos = Vector3.new(
        root.Position.X,
        voidY,
        root.Position.Z
    )

    local underGardenPos = Vector3.new(
        inside.X,
        voidY,
        inside.Z
    )

    local dropCF = CFrame.new(dropPos, underGardenPos)
    local underGardenCF = CFrame.new(underGardenPos, inside)
    local gardenCF = CFrame.new(inside)

    local returnTweenSpeed =
        shared.SerenityRideAPet
            .AutoStealTweenSpeed()

    log(label .. ".VoidReturnEnabled=SHALLOW")
    log(label .. ".VoidReturnDepth=" .. tostring(VOID_RETURN_DEPTH))
    log(label .. ".VoidReturnTweenSpeed=" .. tostring(returnTweenSpeed))
    log(label .. ".VoidRouteY=" .. tostring(voidY))
    log(label .. ".FinalReturnMode=SHALLOW_VOID_DIRECT_RISE")

    local stopReturnNoclip =
        beginTemporaryCharacterNoclip(
            label .. ".VoidReturn"
        )

    local function finishReturn(ok, err)
        pcall(stopReturnNoclip)
        return ok, err
    end

    local dropOk, dropErr = shared.SerenityRideAPet.AutoStealTravel(
        dropCF,
        returnTweenSpeed,
        label .. ".VoidDrop"
    )

    if not dropOk then
        return finishReturn(
            false,
            "void drop failed: " .. tostring(dropErr)
        )
    end

    local underOk, underErr = shared.SerenityRideAPet.AutoStealTravel(
        underGardenCF,
        returnTweenSpeed,
        label .. ".VoidTravelUnderMap"
    )

    if not underOk then
        return finishReturn(
            false,
            "void under-map travel failed: " .. tostring(underErr)
        )
    end

    local riseOk, riseErr = shared.SerenityRideAPet.AutoStealTravel(
        gardenCF,
        returnTweenSpeed,
        label .. ".VoidRiseDirectToGarden"
    )

    if not riseOk then
        return finishReturn(
            false,
            "void rise failed: " .. tostring(riseErr)
        )
    end

    log(label .. ".GardenReached=true")
    log(label .. ".DistanceToGardenTarget=" .. tostring(
        (root.Position - inside).Magnitude
    ))

    return finishReturn(true, nil)
end

local function returnHomeAfterStrictStealFailure(label)
    return
        fastWalkIntoOwnGarden(
            HRP.Position,
            ownGardenReferenceCFrame(),
            label or "StrictStealFailureReturn"
        )
end

local function emergencyReturnHomeAfterStuckSteal(label)
    local runtime =
        shared.SerenityRideAPet.StealActionRuntime

    if not runtime then
        return false, "steal runtime missing"
    end

    runtime.EmergencyReturn = true

    local ok, err =
        fastWalkIntoOwnGarden(
            HRP.Position,
            ownGardenReferenceCFrame(),
            label or "StuckStealEmergencyReturn"
        )

    runtime.EmergencyReturn = false
    runtime.AbortRequested = false

    log("")
    log("=== STEAL_STUCK_RETURN_RESULT ===")
    log("ReturnedHome=" .. tostring(ok))
    log("Reason=" .. tostring(err or runtime.AbortReason or "stuck fallback"))

    return ok, err
end

local function triggerPrompt(prompt, holdUntil, maxWait, label, skipPickupHomeReturn, pickupActiveId)
    if not prompt or not prompt.Parent then
        return false, "prompt missing"
    end

    local pos = promptPosition(prompt)
    if not pos then
        return false, "position missing"
    end

    local saved = HRP.CFrame
    local maxDist = tonumber(prompt.MaxActivationDistance) or 15
    local approach = math.max(1.5, math.min(3, maxDist * 0.25))

    pcall(function()
        GuiService:SetGameplayPausedNotificationEnabled(false)
    end)

    prestreamDestination(pos, label)

    local isPickup =
        string.find(
            label or "",
            "Pickup",
            1,
            true
        ) ~= nil

    local pickupFallbackSent =
        false

    local pickupReplyStartedAt =
        os.clock()

    if isPickup
        and pickupActiveId ~= nil then

        local replyRuntime =
            shared.SerenityRideAPet
                .EggPickupReplyRuntime

        if type(replyRuntime) == "table"
            and type(replyRuntime.ByActiveId) == "table" then

            replyRuntime.ByActiveId[
                tostring(
                    pickupActiveId
                )
            ] = nil
        end
    end

    local targetCFrame

    if isPickup then
        -- Follow the prompt's exact Y for newly-added elevated eggs.
        -- Keep a small horizontal/vertical offset only so the character is
        -- inside activation range rather than occupying the prompt itself.
        local rootPos = HRP.Position
        local horizontal =
            Vector3.new(
                rootPos.X - pos.X,
                0,
                rootPos.Z - pos.Z
            )

        local direction =
            horizontal.Magnitude > 0.1
            and horizontal.Unit
            or Vector3.new(1, 0, 0)

        local pickupPos =
            Vector3.new(
                pos.X,
                pos.Y + 0.65,
                pos.Z
            )
            + direction
                * math.max(
                    1.25,
                    math.min(
                        2.25,
                        maxDist * 0.18
                    )
                )

        targetCFrame =
            CFrame.lookAt(
                pickupPos,
                pos
            )
    else
        targetCFrame =
            CFrame.new(
                pos + Vector3.new(approach, 1.25, 0),
                pos
            )
    end

    -- OUTBOUND: normal Auto Steal uses the selected movement mode.
    log(label .. ".MovementMode=" .. (
        isPickup
        and (
            Config.InstantSteal == true
            and "INSTANT_STEAL"
            or "TWEEN_STEAL"
        )
        or "INSTANT_TELEPORT"
    ))

    local outboundSpeed =
        isPickup
        and shared.SerenityRideAPet
            .AutoStealTweenSpeed()
        or LOCAL_ACTION_TWEEN_SPEED

    local travelOk,
        travelErr

    if isPickup then
        travelOk,
            travelErr =
            shared.SerenityRideAPet
                .AutoStealTravel(
                    targetCFrame,
                    outboundSpeed,
                    label
                    .. ".StealTravelToTarget"
                )
    else
        -- Preserve the existing instant utility movement outside Auto Steal.
        travelOk,
            travelErr =
            tweenTravel(
                targetCFrame,
                outboundSpeed,
                label
                .. ".FastTweenToTarget"
            )
    end

    if not travelOk then
        log(label .. ".OutboundTweenError=" .. tostring(travelErr))
        return false, travelErr
    end

    if isPickup then
        shared.SerenityRideAPet.StartStealHoverHold(
            targetCFrame,
            label .. ".PickupHover",
            true
        )
    end

    task.wait(ARRIVAL_SERVER_SETTLE)

    if not prompt.Parent then
        if not isPickup then
            tweenTravel(
                saved,
                LOCAL_RETURN_TWEEN_SPEED,
                label .. ".ReturnAfterPromptRace"
            )
        end

        return false, "prompt raced"
    end

    local current = promptPosition(prompt) or pos
    local triggerDistance = (HRP.Position - current).Magnitude

    log(label .. ".DistanceAtTrigger=" .. tostring(triggerDistance))
    log(label .. ".PromptMaxDistance=" .. tostring(maxDist))
    log(label .. ".InsideNormalPromptRange=" .. tostring(triggerDistance <= maxDist))

    if triggerDistance > maxDist then
        if isPickup then
            local direction =
                HRP.Position - current

            direction =
                Vector3.new(
                    direction.X,
                    0,
                    direction.Z
                )

            if direction.Magnitude < 0.1 then
                direction =
                    Vector3.new(1, 0, 0)
            else
                direction =
                    direction.Unit
            end

            local correctionPos =
                current
                + direction
                    * math.max(
                        1.25,
                        math.min(
                            2.5,
                            maxDist * 0.20
                        )
                    )
                + Vector3.new(
                    0,
                    1.15,
                    0
                )

            local correctionCF =
                CFrame.lookAt(
                    correctionPos,
                    current
                )

            local correctionOk =
                shared.SerenityRideAPet
                    .AutoStealTravel(
                        correctionCF,
                        shared.SerenityRideAPet
                            .AutoStealTweenSpeed(),
                        label
                        .. ".LocalRangeCorrection"
                    )

            if correctionOk then
                shared.SerenityRideAPet.StartStealHoverHold(
                    correctionCF,
                    label .. ".PickupHoverCorrection",
                    true
                )
            end

            task.wait(0.10)

            current =
                promptPosition(prompt)
                or current

            triggerDistance =
                (HRP.Position - current).Magnitude

            if triggerDistance > maxDist then
                return
                    false,
                    "not inside prompt range after local correction"
            end
        else
            tweenTravel(
                saved,
                LOCAL_RETURN_TWEEN_SPEED,
                label .. ".ReturnOutOfRange"
            )

            return false, "not inside prompt range after movement"
        end
    end

    local ok, err = pcall(function()
        fireproximityprompt_f(prompt)
    end)

    log(label .. ".TriggerLocalResult=" .. tostring(ok))

    if not ok then
        log(label .. ".TriggerError=" .. tostring(err))

        if not isPickup then
            tweenTravel(
                saved,
                LOCAL_RETURN_TWEEN_SPEED,
                label .. ".ReturnAfterTriggerFailure"
            )
        end

        return false, err
    end

    local holdStart = os.clock()
    local deadline = holdStart + (maxWait or 1)
    local holdSatisfied =
        holdUntil == nil

    repeat
        if holdUntil
            and holdUntil() then

            holdSatisfied = true
            break
        end

        task.wait(0.025)
    until os.clock() >= deadline

    log(label .. ".HeldNearSeconds=" .. tostring(os.clock() - holdStart))
    log(label .. ".HoldSatisfied=" .. tostring(holdSatisfied))

    -- v80.2.76:
    -- fireproximityprompt() succeeding locally does not guarantee that the
    -- game's Triggered callback reached the server. While still physically
    -- inside the real Pickup range, fall back once to the same native
    -- EggPickup RemoteEvent used by EggSpawning.Client.
    if isPickup
        and not holdSatisfied
        and pickupActiveId ~= nil
        and tostring(pickupActiveId) ~= ""
        and prompt.Parent then

        current =
            promptPosition(prompt)
            or current

        triggerDistance =
            (HRP.Position - current).Magnitude

        if triggerDistance <= maxDist then
            local remotes =
                ReplicatedStorage:FindFirstChild(
                    "Remotes"
                )

            local gameRemotes =
                remotes
                and remotes:FindFirstChild(
                    "Game"
                )

            local eggPickup =
                gameRemotes
                and gameRemotes:FindFirstChild(
                    "EggPickup"
                )

            if eggPickup
                and eggPickup:IsA(
                    "RemoteEvent"
                ) then

                local remoteOk,
                    remoteErr =
                    pcall(function()
                        eggPickup:FireServer(
                            tostring(
                                pickupActiveId
                            )
                        )
                    end)

                log(
                    label
                    .. ".RemoteFallbackSent="
                    .. tostring(remoteOk)
                )

                if not remoteOk then
                    log(
                        label
                        .. ".RemoteFallbackError="
                        .. tostring(remoteErr)
                    )
                else
                    pickupFallbackSent =
                        true

                    local fallbackDeadline =
                        os.clock() + 1.35

                    repeat
                        if holdUntil
                            and holdUntil() then

                            holdSatisfied = true
                            break
                        end

                        task.wait(0.025)
                    until os.clock()
                        >= fallbackDeadline

                    log(
                        label
                        .. ".RemoteFallbackAcknowledged="
                        .. tostring(
                            holdSatisfied
                        )
                    )
                end
            else
                log(
                    label
                    .. ".RemoteFallbackUnavailable=true"
                )
            end
        else
            log(
                label
                .. ".RemoteFallbackSkippedOutOfRange=true"
            )
        end
    end

    if isPickup then
        -- CRITICAL:
        -- Never leave the egg just because fireproximityprompt() returned.
        -- For Auto Steal, ActiveEgg removal is the server acknowledgment.
        if not holdSatisfied then
            log(label .. ".PickupAcknowledged=false")

            local replyRuntime =
                shared.SerenityRideAPet
                    .EggPickupReplyRuntime

            local reply =
                type(replyRuntime) == "table"
                and type(replyRuntime.ByActiveId) == "table"
                and pickupActiveId ~= nil
                and replyRuntime.ByActiveId[
                    tostring(
                        pickupActiveId
                    )
                ]
                or nil

            -- BasketFull may be emitted without an ActiveEgg id. Steal owns
            -- the gameplay lane here, so a fresh id-less native reply in this
            -- exact request window is safe to attribute to this pickup.
            if reply == nil
                and type(replyRuntime) == "table"
                and type(replyRuntime.Last) == "table"
                and (
                    tonumber(
                        replyRuntime.Last.At
                    )
                    or 0
                ) >= pickupReplyStartedAt
                and (
                    replyRuntime.Last.ActiveId == nil
                    or pickupActiveId == nil
                    or tostring(
                        replyRuntime.Last.ActiveId
                    ) == tostring(
                        pickupActiveId
                    )
                ) then

                reply =
                    replyRuntime.Last
            end

            if type(reply) == "table"
                and (
                    tonumber(reply.At)
                    or 0
                ) >= pickupReplyStartedAt then

                local status =
                    tostring(
                        reply.Status
                        or ""
                    )

                log(
                    label
                    .. ".NativeReply="
                    .. status
                )

                log(
                    label
                    .. ".NativeReplyDetail="
                    .. tostring(
                        reply.Detail
                    )
                )

                if status == "BasketFull" then
                    return
                        false,
                        "server reported BasketFull",
                        false
                elseif status == "PickedUp" then
                    return
                        false,
                        "server reported PickedUp but ActiveEgg removal is still replicating",
                        false
                elseif status == "Refused" then
                    return
                        false,
                        "server refused pickup: "
                        .. tostring(
                            reply.Detail
                            or "unknown"
                        ),
                        false
                end
            end

            log(label .. ".Action=STAY_AT_EGG_FOR_NEXT_STRICT_TRY")

            return
                false,
                "pickup was not acknowledged by server",
                pickupFallbackSent == true
        end

        log(label .. ".PickupAcknowledged=true")

        if skipPickupHomeReturn == true then
            -- Volcanic Mutation (In Steal):
            -- keep the newly-stolen egg away from the garden so the normal
            -- home claim does not consume the Basket entry before VolcanoDip.
            log(label .. ".ReturningToOwnGarden=false")
            log(label .. ".DeferredHomeForVolcanicMutation=true")
        else
            -- Normal Auto Steal behavior remains unchanged.
            log(label .. ".ReturningToOwnGarden=true")

            local entered, enterErr =
                fastWalkIntoOwnGarden(
                    HRP.Position,
                    saved,
                    label .. ".ConfirmedReturn"
                )

            log(label .. ".ReturnedToGarden=" .. tostring(entered))

            if not entered then
                log(label .. ".GardenReturnError=" .. tostring(enterErr))
                return false, enterErr
            end
        end
    else
        local returnOk, returnErr = tweenTravel(
            saved,
            LOCAL_RETURN_TWEEN_SPEED,
            label .. ".FastReturn"
        )

        log(label .. ".Returned=" .. tostring(returnOk))

        if not returnOk then
            log(label .. ".ReturnTweenError=" .. tostring(returnErr))
        end

        log(label .. ".ReturnError=" .. tostring(
            (HRP.Position - saved.Position).Magnitude
        ))
    end

    return true
end

-- ============================================================
-- OWN PLOT / NEST HELPERS
-- ============================================================

local function ownPlot()
    local plots = Workspace:FindFirstChild("Plots")
    if not plots then return nil end

    for _, plot in ipairs(plots:GetChildren()) do
        if plot:GetAttribute("NestsOwnerLoaded") == LP.UserId then
            return plot
        end
    end

    return nil
end

local function emptyUnlockedNest()
    local plot = ownPlot()
    local folder = plot and plot:FindFirstChild("Nests")
    if not folder then return nil end

    local list = {}

    for _, nest in ipairs(folder:GetChildren()) do
        if nest:GetAttribute("Unlocked") == true
            and nest:GetAttribute("Occupied") ~= true then

            list[#list+1] = nest
        end
    end

    table.sort(list, function(a,b)
        return (tonumber(a.Name) or 999) < (tonumber(b.Name) or 999)
    end)

    return list[1]
end

local function findPromptInNest(nest, wanted)
    if not nest then return nil end
    wanted = string.lower(wanted)

    for _, d in ipairs(nest:GetDescendants()) do
        if d:IsA("ProximityPrompt") and d.Enabled then
            local a = string.lower(tostring(d.ActionText or ""))
            local n = string.lower(tostring(d.Name or ""))

            if a:find(wanted, 1, true) or n:find(wanted, 1, true) then
                return d
            end
        end
    end

    return nil
end


-- Proven hatch mapping from the successful isolated Hatch validator:
-- Hatch prompt lives under Plot.Eggs.<placed egg>, NOT under the Nest object.
local function nestReferencePosition(nest)
    if not nest then return nil end

    local model = nest:FindFirstChild("Model")
    if model and model:IsA("Model") then
        local ok, cf = pcall(function() return model:GetPivot() end)
        if ok then return cf.Position end
    elseif model and model:IsA("BasePart") then
        return model.Position
    end

    local ok, cf = pcall(function() return nest:GetPivot() end)
    if ok then return cf.Position end

    return nil
end

local function mapPlacedEggToNest(plot, egg)
    if not plot or not egg then return nil, nil end

    local eggPos
    local ok = pcall(function()
        eggPos = egg:GetPivot().Position
    end)
    if not ok or not eggPos then return nil, nil end

    local nests = plot:FindFirstChild("Nests")
    if not nests then return nil, nil end

    local best, bestDist

    for _, nest in ipairs(nests:GetChildren()) do
        if nest:GetAttribute("Unlocked") == true
            and nest:GetAttribute("Occupied") == true then

            local pos = nestReferencePosition(nest)

            if pos then
                local dist = (pos - eggPos).Magnitude
                if not bestDist or dist < bestDist then
                    best = nest
                    bestDist = dist
                end
            end
        end
    end

    return best, bestDist
end


-- ============================================================
-- v80.2.74 — AUTO HATCH V5 NATIVE GROWTH + NEAR-EGG MOVEMENT
--
-- Proven standalone behavior:
--   fully-grown detection is distance-independent
--   -> tween to 0.85 studs
--   -> native HatchInteraction.Ready()
--   -> exactly one Hatch request
--   -> lock stale successful EggKey/model until it disappears/changes.
-- ============================================================
do
    local runtime =
        shared.SerenityRideAPet.AutoHatchV5Runtime
        or {
            FailedUntil = {},
            CompletedLocks = {},
            LastHatchAt = 0,
            TweenSpeed = 150,
            HorizontalOffset = 0.85,
            ArrivalSettle = 0.20,
            NativeReadyTimeout = 1.50,
            HatchReplyTimeout = 4.00,
            FailedCooldown = 2.50,
            MinimumGap = 0.35,
        }

    shared.SerenityRideAPet.AutoHatchV5Runtime = runtime

    if runtime.ModulesLoaded ~= true then
        local gameData = ReplicatedStorage:FindFirstChild("GameData")
        local gameServices = ReplicatedStorage:FindFirstChild("GameServices")

        pcall(function()
            runtime.EggsData =
                require(gameData:WaitForChild("Eggs", 5))
        end)

        pcall(function()
            runtime.GeneralData =
                require(gameData:WaitForChild("General", 5))
        end)

        pcall(function()
            runtime.DayNight =
                require(gameServices:WaitForChild("DayNight", 5))
        end)

        pcall(function()
            runtime.HatchInteraction =
                require(
                    LP
                        :WaitForChild("PlayerScripts", 5)
                        :WaitForChild("Game", 5)
                        :WaitForChild("EggHatching", 5)
                        :WaitForChild("HatchInteraction", 5)
                )
        end)

        runtime.ModulesLoaded = true
    end

    shared.SerenityRideAPet.AutoHatchGrowthReady = function(egg)
        if not egg
            or not egg:IsA("Model")
            or not egg.PrimaryPart then

            return false
        end

        local eggKey = egg:GetAttribute("EggKey")
        if eggKey == nil then
            return false
        end

        if egg:HasTag("Hatching") then
            return false
        end

        if LP:GetAttribute("TutorialHatchLocked") == true then
            local lockedKey =
                LP:GetAttribute("TutorialLockedEggKey")

            if lockedKey ~= nil
                and tostring(lockedKey) ~= tostring(eggKey) then

                return false
            end
        end

        local eggData = egg:FindFirstChild("EggData")
        local placeTimeValue =
            eggData and eggData:FindFirstChild("PlaceTime")

        local placeTime =
            placeTimeValue
            and tonumber(placeTimeValue.Value)

        if not placeTime or placeTime <= 0 then
            return false
        end

        local weightValue =
            eggData and eggData:FindFirstChild("Weight")

        local weight =
            weightValue
            and tonumber(weightValue.Value)
            or 1

        local elapsed = nil

        if egg:GetAttribute("FlatGrow") == true then
            elapsed =
                Workspace:GetServerTimeNow()
                - placeTime
        elseif type(runtime.DayNight) == "table"
            and type(runtime.DayNight.GrowthElapsed) == "function" then

            local ok, value =
                pcall(
                    runtime.DayNight.GrowthElapsed,
                    placeTime
                )

            if ok then
                elapsed = tonumber(value)
            end
        end

        local cfg =
            type(runtime.EggsData) == "table"
            and runtime.EggsData[egg.Name]
            or nil

        local baseGrowth =
            type(cfg) == "table"
            and tonumber(cfg.GrowthTime)
            or nil

        local required = nil

        if baseGrowth
            and type(runtime.GeneralData) == "table"
            and type(runtime.GeneralData.GrowthTimeFor) == "function" then

            local ok, value =
                pcall(
                    runtime.GeneralData.GrowthTimeFor,
                    baseGrowth,
                    weight
                )

            if ok then
                required = tonumber(value)
            end
        end

        if elapsed == nil or required == nil then
            return false
        end

        return elapsed >= required, elapsed, required
    end

    shared.SerenityRideAPet.CleanupAutoHatchV5Locks = function()
        for key, lock in pairs(runtime.CompletedLocks) do
            local egg = lock and lock.Egg

            if not egg
                or not egg.Parent
                or tostring(egg:GetAttribute("EggKey") or "")
                    ~= tostring(key) then

                runtime.CompletedLocks[key] = nil
            end
        end
    end

    shared.SerenityRideAPet.AutoHatchCandidateAllowed = function(egg)
        if not egg then
            return false
        end

        local key = egg:GetAttribute("EggKey")
        if key == nil then
            return false
        end

        key = tostring(key)

        local lock = runtime.CompletedLocks[key]
        if lock and lock.Egg == egg and egg.Parent then
            return false
        end

        if os.clock()
            < (tonumber(runtime.FailedUntil[key]) or 0) then

            return false
        end

        return true
    end

    shared.SerenityRideAPet.AutoHatchNativeReady = function(egg)
        shared.SerenityRideAPet.RefreshRuntimeCharacterRefs(0)
        local root = HRP

        if not root or not egg or not egg.Parent then
            return false
        end

        if type(runtime.HatchInteraction) == "table"
            and type(runtime.HatchInteraction.Ready) == "function" then

            local ok, ready =
                pcall(
                    runtime.HatchInteraction.Ready,
                    egg
                )

            if ok then
                return ready == true
            end
        end

        local growthReady =
            shared.SerenityRideAPet.AutoHatchGrowthReady(egg)

        if not growthReady or not egg.PrimaryPart then
            return false
        end

        local ok, _, size = pcall(egg.GetBoundingBox, egg)
        if not ok or typeof(size) ~= "Vector3" then
            return false
        end

        local nativeRange =
            math.max(
                7,
                math.max(size.X, size.Y, size.Z) * 0.6 + 8
            )

        local p = egg.PrimaryPart.Position
        local horizontal =
            Vector3.new(
                root.Position.X - p.X,
                0,
                root.Position.Z - p.Z
            ).Magnitude

        return horizontal <= nativeRange
    end

    shared.SerenityRideAPet.AutoHatchMoveNearEgg = function(egg, label)
        shared.SerenityRideAPet.RefreshRuntimeCharacterRefs(0)
        local root = HRP

        if not root or not egg or not egg.Parent then
            return false, "egg/character missing"
        end

        local position =
            egg.PrimaryPart
            and egg.PrimaryPart.Position
            or egg:GetPivot().Position

        local away =
            Vector3.new(
                root.Position.X - position.X,
                0,
                root.Position.Z - position.Z
            )

        if away.Magnitude < 0.05 then
            away = Vector3.new(0, 0, 1)
        else
            away = away.Unit
        end

        local target =
            position
            + away * runtime.HorizontalOffset

        target =
            Vector3.new(
                target.X,
                root.Position.Y,
                target.Z
            )

        local targetCF =
            CFrame.lookAt(
                target,
                Vector3.new(
                    position.X,
                    target.Y,
                    position.Z
                )
            )

        local distance =
            (root.Position - target).Magnitude

        if distance <= 0.10 then
            root.CFrame = targetCF
            return true
        end

        local duration =
            math.max(
                distance / runtime.TweenSpeed,
                0.05
            )

        local tween =
            TweenService:Create(
                root,
                TweenInfo.new(
                    duration,
                    Enum.EasingStyle.Linear,
                    Enum.EasingDirection.Out
                ),
                {CFrame = targetCF}
            )

        local done = false
        local playback = nil

        local connection =
            tween.Completed:Connect(function(state)
                done = true
                playback = state
            end)

        tween:Play()

        local deadline =
            os.clock() + duration + 1

        while not done and os.clock() < deadline do
            if not root.Parent or not egg.Parent then
                pcall(function() tween:Cancel() end)
                connection:Disconnect()
                return false, "egg/character disappeared"
            end

            task.wait()
        end

        connection:Disconnect()

        if not done then
            pcall(function() tween:Cancel() end)
            return false, "hatch tween timeout"
        end

        return
            playback == Enum.PlaybackState.Completed,
            tostring(playback)
    end
end

local function hatchCandidatesForOwnPlot()
    local plot = ownPlot()
    local eggsFolder = plot and plot:FindFirstChild("Eggs")
    if not eggsFolder then return {} end

    shared.SerenityRideAPet.CleanupAutoHatchV5Locks()

    local list = {}

    for _, egg in ipairs(eggsFolder:GetChildren()) do
        if egg:IsA("Model")
            and tonumber(egg:GetAttribute("OwnerUserId")) == LP.UserId
            and shared.SerenityRideAPet.AutoHatchCandidateAllowed(egg) then

            local ready, elapsed, required =
                shared.SerenityRideAPet.AutoHatchGrowthReady(egg)

            if ready then
                local prompt = egg:FindFirstChild("Hatch", true)
                local pos =
                    egg.PrimaryPart
                    and egg.PrimaryPart.Position
                    or egg:GetPivot().Position

                local nest, nestDistance =
                    mapPlacedEggToNest(plot, egg)

                local playerDistance =
                    HRP
                    and Vector3.new(
                        pos.X - HRP.Position.X,
                        0,
                        pos.Z - HRP.Position.Z
                    ).Magnitude
                    or math.huge

                list[#list + 1] = {
                    egg = egg,
                    prompt = prompt,
                    nest = nest,
                    nestDistance = nestDistance,
                    playerDistance = playerDistance,
                    growthElapsed = elapsed,
                    growthRequired = required,
                }
            end
        end
    end

    table.sort(list, function(a, b)
        if a.playerDistance ~= b.playerDistance then
            return a.playerDistance < b.playerDistance
        end

        return tostring(a.egg.Name) < tostring(b.egg.Name)
    end)

    return list
end

local function hatchPromptForNest(nest)
    if not nest then return nil, nil, nil end

    for _, candidate in ipairs(hatchCandidatesForOwnPlot()) do
        if candidate.nest == nest then
            return candidate.prompt, candidate.egg, candidate.nestDistance
        end
    end

    return nil, nil, nil
end

local function placeCarriedEgg(label, preferredNest)
    local tools = eggTools()
    if #tools < 1 then
        return false, "no carried Egg Tool"
    end

    -- Multiple stolen eggs are allowed. Place one at a time whenever
    -- a free nest exists; never make stealing wait for placement.
    local tool = tools[1]
    local carriedCountBefore = #tools
    local eggType = baseEggName(tool.Name)

    local nest = preferredNest
    if not nest
        or nest:GetAttribute("Unlocked") ~= true
        or nest:GetAttribute("Occupied") == true then
        nest = emptyUnlockedNest()
    end

    if not nest then
        return false, "no unlocked empty nest"
    end

    log("")
    log("=== " .. label .. "_PLACE ===")
    log("EggType=" .. eggType)
    log("NestId=" .. nest.Name)
    log("NestOccupied BEFORE=" .. tostring(nest:GetAttribute("Occupied")))
    log("PreferredReservedNestUsed=" .. tostring(preferredNest == nest))

    if tool.Parent ~= Character then
        local ok, err = pcall(function()
            Humanoid:EquipTool(tool)
        end)

        log("EquipEggResult=" .. tostring(ok))
        if not ok then
            log("EquipEggError=" .. tostring(err))
            return false, "equip failed"
        end

        local deadline = os.clock() + 2
        repeat
            if tool.Parent == Character then break end
            task.wait(0.05)
        until os.clock() >= deadline
    end

    if tool.Parent ~= Character then
        return false, "egg did not equip"
    end

    -- Freshly picked-up eggs can replicate into Character slightly before
    -- their save/state hook is fully ready. Existing carried eggs normally
    -- already have this true. Wait briefly, but never block indefinitely.
    local saveHookBefore = tool:GetAttribute("EggSaveHooked")
    log("EggSaveHooked BEFORE_WAIT=" .. tostring(saveHookBefore))

    if saveHookBefore ~= true then
        local settleDeadline = os.clock() + 1.5
        repeat
            if tool:GetAttribute("EggSaveHooked") == true then break end
            task.wait(0.05)
        until os.clock() >= settleDeadline
    end

    log("EggSaveHooked AFTER_WAIT=" .. tostring(tool:GetAttribute("EggSaveHooked")))

    local prompt
    local deadline = os.clock() + 4

    repeat
        prompt = findPromptInNest(nest, "place")
        if prompt then break end
        task.wait(0.05)
    until os.clock() >= deadline

    if not prompt then
        return false, "Place prompt missing"
    end

    log("PlacePrompt=" .. prompt:GetFullName())
    log("PlacePrompt.ObjectText=" .. tostring(prompt.ObjectText))

    local plot = ownPlot()
    local plotEggs = plot and plot:FindFirstChild("Eggs")
    local existing = {}

    if plotEggs then
        for _, egg in ipairs(plotEggs:GetChildren()) do
            existing[egg] = true
        end
    end

    local placedModel = nil
    local function findPlacedModel()
        if placedModel and placedModel.Parent then
            return placedModel
        end

        if not plotEggs then return nil end

        for _, egg in ipairs(plotEggs:GetChildren()) do
            if not existing[egg]
                and egg:IsA("Model")
                and egg.Name == eggType
                and egg:GetAttribute("OwnerUserId") == LP.UserId then
                placedModel = egg
                return egg
            end
        end

        return nil
    end

    local ok = triggerPrompt(
        prompt,
        function()
            local placed = findPlacedModel()
            local consumed = tool.Parent == nil
            local occupied = nest:GetAttribute("Occupied") == true

            return placed ~= nil
                or (occupied and consumed)
        end,
        5.0,
        label .. ".Place"
    )

    if not ok then
        return false, "place trigger failed"
    end

    -- Small post-return observation only; no movement is held here.
    local confirmDeadline = os.clock() + 1.0
    repeat
        findPlacedModel()

        local consumed = tool.Parent == nil
        local occupied = nest:GetAttribute("Occupied") == true

        if (placedModel and consumed) or (occupied and consumed) then
            break
        end

        task.wait(0.05)
    until os.clock() >= confirmDeadline

    local consumed = tool.Parent == nil
    local occupied = nest:GetAttribute("Occupied") == true
    local placed = placedModel ~= nil and placedModel.Parent ~= nil

    log("NestOccupied AFTER=" .. tostring(nest:GetAttribute("Occupied")))
    log("EggToolConsumed=" .. tostring(consumed))
    log("EggToolCount BEFORE=" .. tostring(carriedCountBefore))
    log("EggToolCount AFTER=" .. tostring(#eggTools()))
    log("PlacedEggModelFound=" .. tostring(placed))

    if placedModel then
        log("PlacedEggModel=" .. placedModel:GetFullName())
        log("PlacedEgg.EggKey=" .. tostring(placedModel:GetAttribute("EggKey")))
    end

    local validated = (placed and consumed) or (occupied and consumed)
    log("PlaceValidated=" .. tostring(validated))

    if not validated then
        return false, "placement not confirmed"
    end

    return true, nest, eggType
end

local GameRemotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Game")
local HatchRemote = GameRemotes:WaitForChild("Hatch")
local EggPlacedRemote = GameRemotes:WaitForChild("EggPlaced")

-- v80.2.77: observe the game's native EggPickup replies so BasketFull,
-- explicit Refused, or a delayed PickedUp replication never poison the
-- three-strike stock guard.
if shared.SerenityRideAPet.EggPickupReplyConnection then
    pcall(function()
        shared.SerenityRideAPet
            .EggPickupReplyConnection
            :Disconnect()
    end)
end

shared.SerenityRideAPet.EggPickupReplyRuntime = {
    ByActiveId = {},
    Last = nil,
}

shared.SerenityRideAPet.EggPickupReplyRemote =
    GameRemotes:FindFirstChild(
        "EggPickup"
    )

if shared.SerenityRideAPet.EggPickupReplyRemote
    and shared.SerenityRideAPet
        .EggPickupReplyRemote
        :IsA("RemoteEvent") then

    shared.SerenityRideAPet.EggPickupReplyConnection =
        shared.SerenityRideAPet
            .EggPickupReplyRemote
            .OnClientEvent
            :Connect(
                function(status, detail, activeId)
                    local runtime =
                        shared.SerenityRideAPet
                            .EggPickupReplyRuntime

                    local reply = {
                        Status =
                            tostring(
                                status
                                or ""
                            ),
                        Detail = detail,
                        ActiveId =
                            activeId ~= nil
                            and tostring(
                                activeId
                            )
                            or nil,
                        At = os.clock(),
                    }

                    runtime.Last =
                        reply

                    if reply.ActiveId
                        and reply.ActiveId ~= "" then

                        runtime.ByActiveId[
                            reply.ActiveId
                        ] = reply
                    end
                end
            )
else
    shared.SerenityRideAPet.EggPickupReplyConnection =
        nil
end

local EggGameData = {}
pcall(function()
    EggGameData = require(
        ReplicatedStorage
            :WaitForChild("GameData")
            :WaitForChild("Eggs")
    )
end)

local DynamicRarityScores = {}
local DynamicEggNames = {}
local DynamicRarityNames = {}

do
    local raritySeen = {}

    if type(EggGameData) == "table" then
        for eggName, data in pairs(EggGameData) do
            if type(data) == "table" then
                DynamicEggNames[#DynamicEggNames + 1] = tostring(eggName)

                local rarity = tostring(data.Rarity or "Unknown")
                local luck = tonumber(data.Luck) or 0

                DynamicRarityScores[rarity] =
                    math.max(DynamicRarityScores[rarity] or 0, luck)

                if not raritySeen[rarity] then
                    raritySeen[rarity] = true
                    DynamicRarityNames[#DynamicRarityNames + 1] = rarity
                end
            end
        end
    end

    table.sort(DynamicEggNames)

    table.sort(DynamicRarityNames, function(a, b)
        local sa = DynamicRarityScores[a] or 0
        local sb = DynamicRarityScores[b] or 0

        if sa ~= sb then
            return sa < sb
        end

        return a < b
    end)
end

local function eggMetaForName(name)
    local data =
        type(EggGameData) == "table"
        and EggGameData[tostring(name)]
        or nil

    if type(data) ~= "table" then
        return {
            rarity = "Unknown",
            rarityScore = 0,
            luck = 0,
            appearChance = nil,
        }
    end

    local rarity = tostring(data.Rarity or "Unknown")

    return {
        rarity = rarity,
        rarityScore = DynamicRarityScores[rarity] or 0,
        luck = tonumber(data.Luck) or 0,
        appearChance = tonumber(data.AppearChance),
    }
end

local function eggFilterAllows(kind, eggName, rarity)
    local mode = tostring(Config[kind .. "FilterMode"] or "All Eggs")
    local raritySelection = Config[kind .. "Rarities"]
    local eggSelection = Config[kind .. "Eggs"]

    if mode == "All Eggs" then
        return true
    elseif mode == "Selected Rarities" then
        return selectionHas(raritySelection, rarity)
    elseif mode == "Specific Eggs" then
        return selectionHas(eggSelection, eggName)
    elseif mode == "Rarity + Egg" then
        return selectionHas(raritySelection, rarity)
            and selectionHas(eggSelection, eggName)
    end

    return true
end

local function placeEggCandidates()
    local list = {}

    local minimumKG =
        shared.SerenityRideAPet.MinimumPlaceKG()

    for _, tool in ipairs(eggTools()) do
        local eggName = baseEggName(tool.Name)
        local meta = eggMetaForName(eggName)

        local eggKG, eggKGText, rawWeight =
            shared.SerenityRideAPet.ToolEggKG(
                tool
            )

        local passesKG =
            minimumKG <= 0
            or (
                eggKG ~= nil
                and eggKG >= minimumKG
            )

        if passesKG
            and eggFilterAllows("Place", eggName, meta.rarity) then

            list[#list + 1] = {
                tool = tool,
                eggName = eggName,
                rarity = meta.rarity,
                rarityScore = meta.rarityScore,
                luck = meta.luck,
                eggWeight = eggKG,
                eggWeightText = eggKGText,
                rawWeight = rawWeight,
            }
        end
    end

    local lowFirst =
        tostring(Config.PlacePriority) == "Lowest to Highest"

    table.sort(list, function(a, b)
        if a.rarityScore ~= b.rarityScore then
            if lowFirst then
                return a.rarityScore < b.rarityScore
            end

            return a.rarityScore > b.rarityScore
        end

        if a.luck ~= b.luck then
            if lowFirst then
                return a.luck < b.luck
            end

            return a.luck > b.luck
        end

        return a.eggName < b.eggName
    end)

    return list
end

-- ============================================================
-- VALIDATED ZERO-MOVEMENT CORE ACTIONS
-- v57: Hatch:FireServer({EggKey = exactKey}) works from 885+ studs.
-- Current placement: EggPlaced:FireServer({PlantPosition = Vector3}) anywhere inside own plot.
-- ============================================================

local placeCapacityFull = false
local placeCapacityFolder = nil
local placeCapacityConnection = nil

shared.SerenityRideAPet.PlaceCapacityState =
    shared.SerenityRideAPet.PlaceCapacityState
    or {
        CountWhenFull = nil,
        LastProbeAt = 0,
        MaxNotificationHits = 0,
        LastMaxNotificationAt = 0,
        LastMaxValue = nil,
        LastFailureAt = 0,
        FolderConnections = {},
    }

do
    local state =
        shared.SerenityRideAPet.PlaceCapacityState

    for _, connection in ipairs(
        state.FolderConnections or {}
    ) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    state.FolderConnections = {}
end

-- The game exposes the player's real capacity in the notification:
-- "Max 10/10 Eggs In Plot"
-- One exact match is enough; the listener already deduplicates duplicate
-- TextLabels from the same visual notification.
shared.SerenityRideAPet.RecordPlotMaxNotification = function(textValue)
    local raw = tostring(textValue or "")
    local current, maximum =
        raw:match("[Mm]ax%s+(%d+)%s*/%s*(%d+)%s+[Ee]ggs%s+[Ii]n%s+[Pp]lot")

    current = tonumber(current)
    maximum = tonumber(maximum)

    if not current or not maximum or maximum < 1 then
        return false
    end

    local state =
        shared.SerenityRideAPet.PlaceCapacityState

    local now = os.clock()

    -- One visual notification can contain multiple TextLabels.
    -- Count it once inside this small dedupe window.
    if state.LastMaxValue == maximum
        and now - (tonumber(state.LastMaxNotificationAt) or 0) < 0.45 then

        return true
    end

    if state.LastMaxValue ~= maximum then
        state.MaxNotificationHits = 0
    end

    state.LastMaxValue = maximum
    state.LastMaxNotificationAt = now
    state.MaxNotificationHits = 1

    if tonumber(Config.PlaceKnownMaxEggs) ~= maximum then
        Config.PlaceKnownMaxEggs = maximum
        saveConfig()
    end

    state.CountWhenFull = maximum
    placeCapacityFull = current >= maximum

    return true
end

-- ============================================================
-- MANAGED NOTIFICATION BUS
--
-- Older builds connected TextChanged to every text object in PlayerGui.
-- That means cash counters, timers and unrelated UI could wake Serenity
-- continuously during long AFK sessions. Keep one managed DescendantAdded
-- listener and only retain TextChanged listeners for notification-like UI
-- or objects that actually display one of our relevant messages.
-- ============================================================
shared.SerenityRideAPet.NotificationRuntime =
    shared.SerenityRideAPet.NotificationRuntime
    or {
        Connections = {},
        Watched = {},
        RelevantHits = 0,
        SuppressHatchLuckUntil = 0,
    }

shared.SerenityRideAPet.ResetNotificationRuntime = function()
    local runtime =
        shared.SerenityRideAPet.NotificationRuntime

    for _, connection in ipairs(
        runtime.Connections or {}
    ) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    for _, connection in pairs(
        runtime.Watched or {}
    ) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    runtime.Connections = {}
    runtime.SuppressHatchLuckUntil = 0
    runtime.Watched =
        setmetatable(
            {},
            {
                __mode = "k",
            }
        )

    return runtime
end

shared.SerenityRideAPet.IsRelevantNotificationText = function(textValue)
    local raw =
        tostring(textValue or "")

    if raw == "" then
        return false
    end

    local lower =
        string.lower(raw)

    return
        string.find(
            lower,
            " is already max age",
            1,
            true
        ) ~= nil
        or string.find(
            lower,
            "eggs in plot",
            1,
            true
        ) ~= nil
        or (
            string.find(
                lower,
                "egg",
                1,
                true
            ) ~= nil
            and (
                string.find(
                    lower,
                    "restock",
                    1,
                    true
                ) ~= nil
                or string.find(
                    lower,
                    "refreshed",
                    1,
                    true
                ) ~= nil
                or string.find(
                    lower,
                    "spawned",
                    1,
                    true
                ) ~= nil
                or string.find(
                    lower,
                    "new egg",
                    1,
                    true
                ) ~= nil
            )
        )
end

shared.SerenityRideAPet.IsLikelyNotificationTextObject = function(obj)
    if typeof(obj) ~= "Instance"
        or not (
            obj:IsA("TextLabel")
            or obj:IsA("TextButton")
            or obj:IsA("TextBox")
        ) then

        return false
    end

    local current = obj

    for _ = 1, 7 do
        if not current then
            break
        end

        local lower =
            string.lower(
                tostring(current.Name or "")
            )

        if string.find(lower, "notif", 1, true)
            or string.find(lower, "toast", 1, true)
            or string.find(lower, "banner", 1, true)
            or string.find(lower, "alert", 1, true)
            or string.find(lower, "message", 1, true)
            or string.find(lower, "popup", 1, true)
            or string.find(lower, "prompt", 1, true) then

            return true
        end

        current = current.Parent
    end

    return false
end

shared.SerenityRideAPet.SilenceHatchLuckNotificationWindow = function(seconds)
    local runtime =
        shared.SerenityRideAPet.NotificationRuntime

    runtime.SuppressHatchLuckUntil =
        math.max(
            tonumber(runtime.SuppressHatchLuckUntil) or 0,
            os.clock() + math.max(0, tonumber(seconds) or 0)
        )
end

shared.SerenityRideAPet.HideTransientNotificationVisual = function(obj)
    if typeof(obj) ~= "Instance" then
        return false
    end

    local current = obj
    local childBelowMarker = nil

    for _ = 1, 8 do
        if not current then
            break
        end

        local lower =
            string.lower(
                tostring(current.Name or "")
            )

        local markerHit =
            string.find(lower, "notif", 1, true)
            or string.find(lower, "toast", 1, true)
            or string.find(lower, "banner", 1, true)
            or string.find(lower, "alert", 1, true)
            or string.find(lower, "message", 1, true)
            or string.find(lower, "popup", 1, true)

        if markerHit then
            local target =
                childBelowMarker
                or current

            if target:IsA("GuiObject") then
                pcall(function()
                    target.Visible = false
                end)
                return true
            end

            break
        end

        childBelowMarker = current
        current = current.Parent
    end

    if obj:IsA("GuiObject") then
        pcall(function()
            obj.Visible = false
        end)
        return true
    end

    return false
end

shared.SerenityRideAPet.ProcessNotificationText = function(
    textValue,
    allowRestock
)
    local raw =
        tostring(textValue or "")

    if not shared.SerenityRideAPet.IsRelevantNotificationText(
        raw
    ) then
        return false
    end

    local runtime =
        shared.SerenityRideAPet.NotificationRuntime

    runtime.RelevantHits =
        (tonumber(runtime.RelevantHits) or 0)
        + 1

    shared.SerenityRideAPet.RecordPlotMaxNotification(
        raw
    )

    local feedObserver =
        shared.SerenityRideAPet.RecordFeedNotification

    if type(feedObserver) == "function" then
        feedObserver(raw)
    end

    if allowRestock == true then
        local restockObserver =
            shared.SerenityRideAPet.ObserveRestockNotification

        if type(restockObserver) == "function" then
            restockObserver(raw)
        end
    end

    return true
end

do
    local runtime =
        shared.SerenityRideAPet.ResetNotificationRuntime()

    local playerGui =
        LP:FindFirstChildOfClass(
            "PlayerGui"
        )

    if playerGui then
        local function remember(connection)
            runtime.Connections[
                #runtime.Connections + 1
            ] = connection

            return connection
        end

        local function attach(obj, inspectNow, allowRestock)
            if typeof(obj) ~= "Instance"
                or runtime.Watched[obj] then

                return false
            end

            if not (
                obj:IsA("TextLabel")
                or obj:IsA("TextButton")
                or obj:IsA("TextBox")
            ) then

                return false
            end

            local currentText =
                tostring(obj.Text or "")

            local relevantNow =
                shared.SerenityRideAPet.IsRelevantNotificationText(
                    currentText
                )

            if not relevantNow
                and not shared.SerenityRideAPet.IsLikelyNotificationTextObject(
                    obj
                ) then

                return false
            end

            local function inspect()
                if (tonumber(runtime.SuppressHatchLuckUntil) or 0)
                    > os.clock()
                    and shared.SerenityRideAPet.IsLikelyNotificationTextObject(
                        obj
                    ) then

                    shared.SerenityRideAPet.HideTransientNotificationVisual(
                        obj
                    )
                end

                shared.SerenityRideAPet.ProcessNotificationText(
                    obj.Text,
                    true
                )
            end

            runtime.Watched[obj] =
                obj:GetPropertyChangedSignal(
                    "Text"
                ):Connect(inspect)

            if inspectNow == true and relevantNow then
                shared.SerenityRideAPet.ProcessNotificationText(
                    currentText,
                    allowRestock == true
                )
            end

            return true
        end

        -- Existing UI: bind only obvious notification-like branches.
        -- Do not feed old existing text to restock detection.
        for _, obj in ipairs(
            playerGui:GetDescendants()
        ) do
            if shared.SerenityRideAPet.IsLikelyNotificationTextObject(
                obj
            ) then
                attach(
                    obj,
                    false,
                    false
                )
            end
        end

        -- Newly-created notification labels are inspected once immediately.
        -- If their current text is relevant, keep watching that exact object.
        remember(
            playerGui.DescendantAdded:Connect(function(obj)
                if not (
                    obj:IsA("TextLabel")
                    or obj:IsA("TextButton")
                    or obj:IsA("TextBox")
                ) then
                    return
                end

                local currentText =
                    tostring(obj.Text or "")

                if (tonumber(runtime.SuppressHatchLuckUntil) or 0)
                    > os.clock()
                    and shared.SerenityRideAPet.IsLikelyNotificationTextObject(
                        obj
                    ) then

                    shared.SerenityRideAPet.HideTransientNotificationVisual(
                        obj
                    )
                end

                if shared.SerenityRideAPet.IsRelevantNotificationText(
                    currentText
                ) then

                    attach(
                        obj,
                        true,
                        true
                    )

                    return
                end

                if shared.SerenityRideAPet.IsLikelyNotificationTextObject(
                    obj
                ) then

                    attach(
                        obj,
                        false,
                        true
                    )
                end
            end)
        )
    end
end

local function ownPlotBaseplate(plot)
    if not plot then
        return nil
    end

    local direct = plot:FindFirstChild("Baseplate")
    if direct and direct:IsA("BasePart") then
        return direct
    end

    local deep = plot:FindFirstChild("Baseplate", true)
    return deep and deep:IsA("BasePart") and deep or nil
end

local function bindPlaceCapacityFolder(folder)
    if folder == placeCapacityFolder then
        return
    end

    local state =
        shared.SerenityRideAPet.PlaceCapacityState

    for _, connection in ipairs(
        state.FolderConnections or {}
    ) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    state.FolderConnections = {}

    placeCapacityFolder = folder

    local knownMax =
        math.max(
            0,
            math.floor(
                tonumber(Config.PlaceKnownMaxEggs) or 0
            )
        )

    local currentCount =
        folder and #folder:GetChildren() or 0

    placeCapacityFull =
        knownMax > 0
        and currentCount >= knownMax

    state.CountWhenFull =
        placeCapacityFull and knownMax or nil

    state.LastProbeAt = 0

    if folder then
        state.FolderConnections[
            #state.FolderConnections + 1
        ] =
            folder.ChildRemoved:Connect(function()
                local maxEggs =
                    math.max(
                        0,
                        math.floor(
                            tonumber(Config.PlaceKnownMaxEggs) or 0
                        )
                    )

                local count =
                    #folder:GetChildren()

                placeCapacityFull =
                    maxEggs > 0
                    and count >= maxEggs

                if not placeCapacityFull then
                    state.CountWhenFull = nil
                    state.LastProbeAt = 0
                end
            end)

        state.FolderConnections[
            #state.FolderConnections + 1
        ] =
            folder.ChildAdded:Connect(function()
                local maxEggs =
                    math.max(
                        0,
                        math.floor(
                            tonumber(Config.PlaceKnownMaxEggs) or 0
                        )
                    )

                if maxEggs > 0
                    and #folder:GetChildren() >= maxEggs then

                    placeCapacityFull = true
                    state.CountWhenFull =
                        maxEggs
                end
            end)
    end
end

shared.SerenityRideAPet.CanAttemptEggPlacement =
    function(folder)
        if not folder then
            return false,
                "plot egg folder missing"
        end

        bindPlaceCapacityFolder(
            folder
        )

        local state =
            shared.SerenityRideAPet
                .PlaceCapacityState

        local currentCount =
            #folder:GetChildren()

        local knownMax =
            math.max(
                0,
                math.floor(
                    tonumber(
                        Config.PlaceKnownMaxEggs
                    )
                    or 0
                )
            )

        if knownMax > 0 then
            if currentCount >= knownMax then
                placeCapacityFull = true
                state.CountWhenFull =
                    knownMax

                return false,
                    "plot full"
            end

            placeCapacityFull = false
            state.CountWhenFull = nil

            return true
        end

        if placeCapacityFull then
            local blockedCount =
                tonumber(
                    state.CountWhenFull
                )

            -- Stay blocked without polling the server again.
            -- The existing ChildRemoved listener immediately unlocks this
            -- when a real slot opens.
            if blockedCount
                and currentCount < blockedCount then

                placeCapacityFull = false
                state.CountWhenFull = nil

                return true
            end

            return false,
                "plot full"
        end

        return true
    end

shared.SerenityRideAPet.MarkEggPlacementRejected =
    function(folder, count)
        local state =
            shared.SerenityRideAPet
                .PlaceCapacityState

        local currentCount =
            tonumber(count)
            or (
                folder
                and #folder:GetChildren()
            )
            or 0

        placeCapacityFull = true
        state.CountWhenFull =
            currentCount
        state.LastFailureAt =
            os.clock()
        state.LastProbeAt =
            os.clock()

        -- One bounded scan after a real rejected placement. If the native
        -- "Max X/X Eggs In Plot" banner is visible, learn the exact maximum.
        local playerGui =
            LP:FindFirstChildOfClass(
                "PlayerGui"
            )

        if playerGui then
            for _, obj in ipairs(
                playerGui:GetDescendants()
            ) do
                if obj:IsA("TextLabel")
                    or obj:IsA("TextButton")
                    or obj:IsA("TextBox") then

                    if shared.SerenityRideAPet
                        .RecordPlotMaxNotification(
                            obj.Text
                        ) then

                        break
                    end
                end
            end
        end

        return false,
            "plot full"
    end

local function placedEggPositions(folder)
    local positions = {}

    if not folder then
        return positions
    end

    for _, egg in ipairs(folder:GetChildren()) do
        if egg:IsA("Model") then
            local ok, pivot = pcall(function()
                return egg:GetPivot()
            end)

            if ok then
                positions[#positions + 1] = pivot.Position
            end
        end
    end

    return positions
end

local function nextPlantPosition(plot, folder)
    local baseplate = ownPlotBaseplate(plot)
    if not baseplate then
        return nil
    end

    local size = baseplate.Size
    local marginX = math.min(8, math.max(2, size.X * 0.08))
    local marginZ = math.min(8, math.max(2, size.Z * 0.08))
    local halfX = math.max(0, size.X / 2 - marginX)
    local halfZ = math.max(0, size.Z / 2 - marginZ)

    local spacing =
        math.max(
            7,
            math.min(
                12,
                math.max(7, math.min(size.X, size.Z) / 6)
            )
        )

    local candidates = {
        Vector3.new(0, size.Y / 2, 0),
    }

    local z = -halfZ
    while z <= halfZ + 0.01 do
        local x = -halfX

        while x <= halfX + 0.01 do
            candidates[#candidates + 1] =
                Vector3.new(x, size.Y / 2, z)
            x += spacing
        end

        z += spacing
    end

    table.sort(candidates, function(a, b)
        local da = a.X * a.X + a.Z * a.Z
        local db = b.X * b.X + b.Z * b.Z
        return da < db
    end)

    local occupied = placedEggPositions(folder)
    local minDistance = math.max(5.5, spacing * 0.65)

    for _, localPos in ipairs(candidates) do
        local worldPos =
            baseplate.CFrame:PointToWorldSpace(localPos)

        local clear = true

        for _, existingPos in ipairs(occupied) do
            local delta =
                Vector3.new(
                    existingPos.X - worldPos.X,
                    0,
                    existingPos.Z - worldPos.Z
                )

            if delta.Magnitude < minDistance then
                clear = false
                break
            end
        end

        if clear then
            return worldPos
        end
    end

    return baseplate.CFrame:PointToWorldSpace(
        Vector3.new(0, size.Y / 2, 0)
    )
end

shared.SerenityRideAPet.PlacedEggWeightCache =
    shared.SerenityRideAPet.PlacedEggWeightCache
    or {
        ByEggKey = {},
        ByModel = setmetatable({}, {
            __mode = "k",
        }),
    }

shared.SerenityRideAPet.RememberPlacedEggWeight = function(
    model,
    rawWeight
)
    if not model then
        return
    end

    local raw =
        tonumber(rawWeight)

    if raw == nil then
        return
    end

    local cache =
        shared.SerenityRideAPet.PlacedEggWeightCache

    cache.ByModel[model] =
        raw

    local eggKey =
        model:GetAttribute(
            "EggKey"
        )

    if eggKey ~= nil then
        cache.ByEggKey[
            tostring(eggKey)
        ] = raw
    end
end

shared.SerenityRideAPet.GetRememberedPlacedEggWeight = function(
    model
)
    if not model then
        return nil
    end

    local cache =
        shared.SerenityRideAPet.PlacedEggWeightCache

    local direct =
        cache.ByModel[model]

    if direct ~= nil then
        return tonumber(direct)
    end

    local eggKey =
        model:GetAttribute(
            "EggKey"
        )

    if eggKey ~= nil then
        local byKey =
            cache.ByEggKey[
                tostring(eggKey)
            ]

        if byKey ~= nil then
            cache.ByModel[model] =
                byKey

            return tonumber(byKey)
        end
    end

    return nil
end

local function directPlaceCarriedEgg(label)
    local candidates = placeEggCandidates()

    if #candidates < 1 then
        return false, "no carried Egg Tool matching place filter"
    end

    local selected = candidates[1]
    local tool = selected.tool
    local eggType = selected.eggName

    local _, _, selectedRawWeight =
        shared.SerenityRideAPet.ToolEggKG(
            tool
        )

    local plot = ownPlot()
    local plotEggs = plot and plot:FindFirstChild("Eggs")

    if not plot or not plotEggs then
        return false, "own Plot.Eggs missing"
    end

    local canPlace,
        placeReason =
        shared.SerenityRideAPet
            .CanAttemptEggPlacement(
                plotEggs
            )

    if not canPlace then
        return false,
            placeReason
    end

    if tool.Parent ~= Character then
        local currentCharacter =
            LP.Character or LP.CharacterAdded:Wait()

        local currentHumanoid =
            currentCharacter:FindFirstChildOfClass("Humanoid")

        if not currentHumanoid then
            return false, "humanoid missing"
        end

        local ok = pcall(function()
            currentHumanoid:EquipTool(tool)
        end)

        if not ok then
            return false, "equip failed"
        end

        local equipDeadline = os.clock() + 1.5

        repeat
            if tool.Parent == currentCharacter then
                break
            end
            task.wait(0.03)
        until os.clock() >= equipDeadline

        if tool.Parent ~= currentCharacter then
            return false, "egg did not equip"
        end
    end

    if tool:GetAttribute("EggSaveHooked") ~= true then
        local hookDeadline = os.clock() + 1.25

        repeat
            if tool:GetAttribute("EggSaveHooked") == true then
                break
            end
            task.wait(0.03)
        until os.clock() >= hookDeadline
    end

    local targetPosition =
        nextPlantPosition(plot, plotEggs)

    if typeof(targetPosition) ~= "Vector3" then
        return false, "valid plot position unavailable"
    end

    local beforeCount = #plotEggs:GetChildren()
    local beforeModels = {}

    for _, existing in ipairs(
        plotEggs:GetChildren()
    ) do
        beforeModels[existing] = true
    end

    local fireOk = pcall(function()
        EggPlacedRemote:FireServer({
            PlantPosition = targetPosition,
        })
    end)

    if not fireOk then
        return false, "EggPlaced request failed"
    end

    local deadline = os.clock() + 1.5
    local afterCount = beforeCount

    repeat
        afterCount = #plotEggs:GetChildren()

        if tool.Parent == nil
            or afterCount > beforeCount then
            break
        end

        task.wait(0.03)
    until os.clock() >= deadline

    afterCount = #plotEggs:GetChildren()

    local consumed = tool.Parent == nil
    local increased = afterCount > beforeCount

    if consumed or increased then
        local placedModel = nil
        local placedDistance = math.huge

        for _, child in ipairs(
            plotEggs:GetChildren()
        ) do
            if not beforeModels[child]
                and child:IsA("Model") then

                local distance =
                    math.huge

                local okPivot,
                    pivot =
                    pcall(function()
                        return child:GetPivot()
                    end)

                if okPivot
                    and pivot
                    and typeof(
                        targetPosition
                    ) == "Vector3" then

                    distance =
                        (
                            pivot.Position
                            - targetPosition
                        ).Magnitude
                end

                if placedModel == nil
                    or distance < placedDistance then

                    placedModel = child
                    placedDistance = distance
                end
            end
        end

        if placedModel
            and selectedRawWeight ~= nil then

            shared.SerenityRideAPet.RememberPlacedEggWeight(
                placedModel,
                selectedRawWeight
            )

            log(
                label
                .. ".PlacedWeightCached=true"
            )

            log(
                label
                .. ".PlacedEggKey="
                .. tostring(
                    placedModel:GetAttribute(
                        "EggKey"
                    )
                )
            )

            log(
                label
                .. ".PlacedRawWeight="
                .. tostring(
                    selectedRawWeight
                )
            )
        end

        local knownMax =
            math.max(
                0,
                math.floor(
                    tonumber(Config.PlaceKnownMaxEggs) or 0
                )
            )

        placeCapacityFull =
            knownMax > 0
            and afterCount >= knownMax

        shared.SerenityRideAPet.PlaceCapacityState.CountWhenFull =
            placeCapacityFull and knownMax or nil

        shared.SerenityRideAPet.PlaceCapacityState.LastProbeAt = 0

        return true, eggType
    end

    -- A real placement request was rejected while the same Tool remained.
    -- Block further placement requests until a plot slot actually opens.
    return
        shared.SerenityRideAPet
            .MarkEggPlacementRejected(
                plotEggs,
                beforeCount
            )
end

local function directHatchCandidate(candidate, label)
    if not candidate or not candidate.egg then
        return false, "missing hatch candidate"
    end

    local egg = candidate.egg
    local eggKey = egg:GetAttribute("EggKey")

    if eggKey == nil then
        return false, "EggKey missing"
    end

    eggKey = tostring(eggKey)

    local runtime =
        shared.SerenityRideAPet.AutoHatchV5Runtime

    log("")
    log("=== " .. label .. "_HATCH_V5 ===")
    log("Egg=" .. tostring(egg.Name))
    log("EggKey=" .. eggKey)
    log("GrowthReady=true")
    log("DistanceBefore=" .. tostring(candidate.playerDistance))
    log("CloseOffset=" .. tostring(runtime.HorizontalOffset))

    local moved, moveReason =
        shared.SerenityRideAPet.AutoHatchMoveNearEgg(
            egg,
            label .. ".MoveNear"
        )

    if not moved then
        runtime.FailedUntil[eggKey] =
            os.clock() + runtime.FailedCooldown

        return false,
            "hatch move failed: " .. tostring(moveReason)
    end

    task.wait(runtime.ArrivalSettle)

    shared.SerenityRideAPet.RefreshRuntimeCharacterRefs(0)
    local root = HRP

    if not root or not egg.Parent then
        return false, "egg/character disappeared after movement"
    end

    local p =
        egg.PrimaryPart
        and egg.PrimaryPart.Position
        or egg:GetPivot().Position

    local closeDistance =
        Vector3.new(
            root.Position.X - p.X,
            0,
            root.Position.Z - p.Z
        ).Magnitude

    log("DistanceAtEgg=" .. tostring(closeDistance))

    local readyDeadline =
        os.clock() + runtime.NativeReadyTimeout

    local nativeReady = false

    repeat
        nativeReady =
            shared.SerenityRideAPet.AutoHatchNativeReady(egg)

        if nativeReady or not egg.Parent then
            break
        end

        task.wait(0.03)
    until os.clock() >= readyDeadline

    if not nativeReady then
        runtime.FailedUntil[eggKey] =
            os.clock() + runtime.FailedCooldown

        return false, "native HatchInteraction.Ready=false while close"
    end

    local liveKey = egg:GetAttribute("EggKey")
    if liveKey == nil then
        return false, "EggKey missing after movement"
    end

    liveKey = tostring(liveKey)

    local remaining =
        runtime.MinimumGap
        - (
            os.clock()
            - (tonumber(runtime.LastHatchAt) or 0)
        )

    if remaining > 0 then
        task.wait(remaining)
    end

    local eventSeen = false
    local eventPayload = nil

    local conn = HatchRemote.OnClientEvent:Connect(function(payload)
        if type(payload) == "table"
            and tostring(payload.EggKey) == liveKey then

            eventSeen = true
            eventPayload = payload
        end
    end)

    log("DirectCall=Hatch:FireServer({EggKey=" .. liveKey .. "})")
    log("DirectCallCount=1")

    local fireOk, fireErr = pcall(function()
        HatchRemote:FireServer({
            EggKey = liveKey,
        })
    end)

    runtime.LastHatchAt = os.clock()

    if not fireOk then
        conn:Disconnect()
        runtime.FailedUntil[liveKey] =
            os.clock() + runtime.FailedCooldown

        return false,
            "Hatch FireServer failed: " .. tostring(fireErr)
    end

    local deadline =
        os.clock() + runtime.HatchReplyTimeout

    repeat
        if eventSeen or not egg.Parent then
            break
        end

        task.wait(0.03)
    until os.clock() >= deadline

    conn:Disconnect()

    if eventSeen or not egg.Parent then
        if egg.Parent then
            runtime.CompletedLocks[liveKey] = {
                Egg = egg,
                At = os.clock(),
            }
        end

        runtime.FailedUntil[liveKey] = nil

        log("MatchingHatchEvent=" .. tostring(eventSeen))
        log("HatchedPetName=" .. tostring(
            eventPayload and eventPayload.PetName or "?"
        ))
        log("LockedOldEgg=true")

        return true
    end

    runtime.FailedUntil[liveKey] =
        os.clock() + runtime.FailedCooldown

    return false, "matching Hatch event not received"
end

local function hatchNest(nest, expectedEggType, label)
    log("")
    log("=== " .. label .. "_HATCH_V5 ===")
    log("NestId=" .. tostring(nest and nest.Name or "<nil>"))
    log("EggType=" .. tostring(expectedEggType))

    if not nest then
        return false, "missing nest"
    end

    local candidate = nil
    local deadline = os.clock() + 20

    repeat
        for _, current in ipairs(hatchCandidatesForOwnPlot()) do
            if current.nest == nest then
                candidate = current
                break
            end
        end

        if candidate then
            break
        end

        task.wait(0.10)
    until os.clock() >= deadline

    if not candidate then
        return false, "placed egg did not become growth-ready"
    end

    local ok, reason =
        directHatchCandidate(
            candidate,
            label .. ".Native"
        )

    if not ok then
        return false, reason
    end

    local clearDeadline =
        os.clock() + 4

    repeat
        if nest:GetAttribute("Occupied") ~= true then
            break
        end

        task.wait(0.05)
    until os.clock() >= clearDeadline

    return true
end


-- ============================================================
-- SLOT AVAILABILITY
-- ============================================================

local function occupiedUnlockedNests()
    local plot = ownPlot()
    local folder = plot and plot:FindFirstChild("Nests")
    if not folder then return {} end

    local list = {}

    for _, nest in ipairs(folder:GetChildren()) do
        if nest:GetAttribute("Unlocked") == true
            and nest:GetAttribute("Occupied") == true then

            list[#list+1] = nest
        end
    end

    table.sort(list, function(a,b)
        return (tonumber(a.Name) or 999) < (tonumber(b.Name) or 999)
    end)

    return list
end

local function ensureFreeNest(label)
    local free = emptyUnlockedNest()
    if free then
        log(label .. ".FreeNestAlreadyAvailable=" .. free.Name)
        return true, free
    end

    log("")
    log("=== " .. label .. "_FREE_NEST ===")
    log("FreeNestInitially=false")

    local occupied = occupiedUnlockedNests()
    log("OccupiedUnlockedNestCount=" .. tostring(#occupied))

    if #occupied == 0 then
        return false, "no unlocked nest exists"
    end

    -- Wait only for the normal Hatch prompt. Never SkipGrowth.
    local readyNest = nil
    local waitStarted = os.clock()
    local waitDeadline = waitStarted + 30

    repeat
        local hatchable = hatchCandidatesForOwnPlot()

        if Config.AutoHatch and #hatchable > 0 then
            readyNest = hatchable[1].nest
            log("DetectedHatchableEgg=" .. hatchable[1].egg:GetFullName())
            log("DetectedHatchPrompt=" .. hatchable[1].prompt:GetFullName())
            log("DetectedNestId=" .. tostring(readyNest.Name))
            log("EggToNestDistance=" .. tostring(hatchable[1].nestDistance))
        end

        if readyNest then break end
        task.wait(0.10)
    until os.clock() >= waitDeadline

    log("WaitForFreeableNestSeconds=" .. tostring(os.clock() - waitStarted))

    if not readyNest then
        return false, "all unlocked nests occupied and none became hatch-ready within 30s"
    end

    log("FreeingNestId=" .. tostring(readyNest.Name))

    local ok, reason = hatchNest(readyNest, "<existing egg>", label .. ".FreeSlot")

    if not ok then
        return false, "failed to hatch occupied nest: " .. tostring(reason)
    end

    local freeWaitStarted = os.clock()
    local deadline = freeWaitStarted + POST_HATCH_FREE_SLOT_TIMEOUT

    repeat
        free = emptyUnlockedNest()
        if free then break end
        task.wait(0.05)
    until os.clock() >= deadline

    log("PostHatchFreeSlotWaitSeconds=" .. tostring(os.clock() - freeWaitStarted))

    if not free then
        return false, "hatch succeeded but Occupied did not clear within "
            .. tostring(POST_HATCH_FREE_SLOT_TIMEOUT) .. "s"
    end

    log("FreeNestAfterCleanup=" .. tostring(free.Name))
    log("FreeNestOccupied=" .. tostring(free:GetAttribute("Occupied")))
    return true, free
end


-- Full-nest production behavior:
-- If we're already carrying an egg, keep it safely in the basket and wait
-- until a normal Hatch prompt appears on one of our occupied nests.
-- Never SkipGrowth and never discard the carried egg.
local function waitForFreeNestWhileCarrying(label)
    local announcedWaiting = false
    local waitStarted = os.clock()

    while true do
        local free = emptyUnlockedNest()
        if free then
            log(label .. ".FreeNestAvailable=" .. tostring(free.Name))
            log(label .. ".TotalWaitSeconds=" .. tostring(os.clock() - waitStarted))
            return true, free
        end

        local occupied = occupiedUnlockedNests()
        if #occupied == 0 then
            return false, "no unlocked nest exists"
        end

        local hatchable = hatchCandidatesForOwnPlot()

        if #hatchable > 0 then
            local candidate = hatchable[1]

            log("")
            log("=== " .. label .. "_FREEING_OCCUPIED_NEST ===")
            log("HatchableEgg=" .. candidate.egg:GetFullName())
            log("HatchPrompt=" .. candidate.prompt:GetFullName())
            log("NestId=" .. tostring(candidate.nest.Name))
            log("CarriedEggCount=" .. tostring(#eggTools()))

            local ok, reason = hatchNest(
                candidate.nest,
                "<existing egg>",
                label .. ".FreeSlot"
            )

            if ok then
                local deadline = os.clock() + POST_HATCH_FREE_SLOT_TIMEOUT

                repeat
                    free = emptyUnlockedNest()
                    if free then break end
                    task.wait(0.05)
                until os.clock() >= deadline

                if free then
                    log(label .. ".FreedNest=" .. tostring(free.Name))
                    log(label .. ".TotalWaitSeconds=" .. tostring(os.clock() - waitStarted))
                    return true, free
                end
            else
                log(label .. ".HatchAttemptReason=" .. tostring(reason))
            end
        else
            if not announcedWaiting then
                log("")
                log("=== " .. label .. "_WAITING_WITH_CARRIED_EGG ===")
                log("AllNestsOccupied=true")
                log("CarriedEggCount=" .. tostring(#eggTools()))
                log("Policy=KEEP_CARRIED_EGG_AND_WAIT_FOR_NORMAL_HATCH")
                log("SkipGrowth=false")
                announcedWaiting = true
            end
        end

        task.wait(FULL_NEST_RECHECK_SECONDS)
    end
end

-- ============================================================
-- PICKUP HELPERS
-- ============================================================

local ServerData = ReplicatedStorage:FindFirstChild("ServerData") or ReplicatedStorage
local ActiveEggs = ServerData:WaitForChild("ActiveEggs", 10)

local function vectorXZDistance(a,b)
    return (Vector2.new(a.X,a.Z) - Vector2.new(b.X,b.Z)).Magnitude
end

local function renderedModelForPrompt(prompt)
    local x = prompt and prompt.Parent

    while x and x ~= Workspace do
        if x:IsA("Model") and x.Parent and x.Parent.Name == "RenderedEggs" then
            return x
        end
        x = x.Parent
    end

    return nil
end

local function matchActive(model, eggType)
    if not model or not ActiveEggs then return nil, nil end

    local pivot = model:GetPivot().Position
    local best, bestDist

    for _, entry in ipairs(ActiveEggs:GetChildren()) do
        if entry:GetAttribute("Egg") == eggType then
            local privateTo = entry:GetAttribute("PrivateTo")

            if privateTo == nil or privateTo == LP.UserId then
                local pos = entry:GetAttribute("Position")

                if typeof(pos) == "Vector3" then
                    local d = vectorXZDistance(pivot, pos)

                    if bestDist == nil or d < bestDist then
                        best = entry
                        bestDist = d
                    end
                end
            end
        end
    end

    if best and bestDist <= 12 then
        return best, bestDist
    end

    return nil, nil
end

local function eggRarityMetadata()
    local meta = {}
    local rarityScore = {}

    local ok, data = pcall(function()
        return require(ReplicatedStorage:WaitForChild("GameData"):WaitForChild("Eggs"))
    end)

    if ok and type(data) == "table" then
        for name, cfg in pairs(data) do
            if type(cfg) == "table" then
                local rarity = tostring(cfg.Rarity or "?")
                local luck = tonumber(cfg.Luck) or 0
                local appearChance = tonumber(cfg.AppearChance)

                meta[name] = {
                    rarity = rarity,
                    luck = luck,
                    appearChance = appearChance,
                }

                rarityScore[rarity] = math.max(rarityScore[rarity] or 0, luck)
            end
        end
    end

    return meta, rarityScore
end

local eggMeta, rarityScores = eggRarityMetadata()

local STEAL_MIN_LUCK_VALUES = {
    ["1M"] = 1e6,
    ["10M"] = 1e7,
    ["100M"] = 1e8,
    ["1B"] = 1e9,
    ["5B"] = 5e9,
    ["10B"] = 1e10,
    ["100B"] = 1e11,
    ["1T"] = 1e12,
    ["10T"] = 1e13,
    ["100T"] = 1e14,
}

local function minimumLuckValue(label)
    local value =
        tostring(
            label
            or "Any"
        )

    if value == "Any" then
        return 0
    end

    return
        STEAL_MIN_LUCK_VALUES[value]
        or 0
end

local function stealMinimumLuck()
    return
        minimumLuckValue(
            shared.SerenityRideAPet.ActiveStealSetting(
                "StealMinLuck",
                "Any"
            )
        )
end

local function eggEspMinimumLuck()
    return minimumLuckValue(Config.EggESPMinLuck)
end

local function rejoinMinimumLuck()
    return minimumLuckValue(Config.StealMinLuck)
end


-- ServerData.ActiveEggs can temporarily contain stale/ghost entries:
-- they have Egg + Position, but no real rendered Pickup exists there.
-- We only blacklist one AFTER physically validating its server position.
local GHOST_EGG_TTL = 5
local ghostEggs = {}

local function activeEggGhostKey(active)
    if not active then
        return nil
    end

    return tostring(active.Name)
end

local function clearExpiredGhostEggs()
    local now = os.clock()

    for key, data in pairs(ghostEggs) do
        local active = data.active

        if not active
            or active.Parent == nil
            or now >= data.expiresAt then

            ghostEggs[key] = nil
        else
            local currentPos = active:GetAttribute("Position")

            -- If the same ActiveEgg entry moves/changes position,
            -- treat it as fresh and allow it again immediately.
            if typeof(currentPos) == "Vector3"
                and typeof(data.position) == "Vector3"
                and (currentPos - data.position).Magnitude > 3 then

                ghostEggs[key] = nil
            end
        end
    end
end

local function isGhostEgg(active)
    clearExpiredGhostEggs()

    local key = activeEggGhostKey(active)

    return key ~= nil
        and ghostEggs[key] ~= nil
end

local function markGhostEgg(serverEgg, reason)
    if not serverEgg or not serverEgg.active then
        return
    end

    local key = activeEggGhostKey(serverEgg.active)

    if not key then
        return
    end

    ghostEggs[key] = {
        active = serverEgg.active,
        position = serverEgg.position,
        eggType = serverEgg.eggType,
        luck = serverEgg.eggLuck,
        expiresAt = os.clock() + GHOST_EGG_TTL,
    }

    log("")
    log("=== GHOST_EGG_DETECTED ===")
    log("ActiveEggName=" .. tostring(key))
    log("EggType=" .. tostring(serverEgg.eggType))
    log("EggLuck=" .. tostring(serverEgg.eggLuck))
    log("Position=" .. tostring(serverEgg.position))
    log("Reason=" .. tostring(reason))
    log("GhostSkipSeconds=" .. tostring(GHOST_EGG_TTL))
end

local function ghostEggCount()
    clearExpiredGhostEggs()

    local count = 0
    for _ in pairs(ghostEggs) do
        count += 1
    end

    return count
end

-- ============================================================
-- AUTO STEAL STOCK GUARD V5 — STRICT 3-TRY LIMIT
--
-- One actual failed steal cycle = one failure.
--
--   1st failure -> allow another attempt
--   2nd failure -> allow one final attempt
--   3rd failure -> LOCK that egg type and STOP trying it
--
-- The failure counter is NEVER cleared by old/stale UI text.
-- A locked type is reopened only by real evidence of new world stock:
--
--   * a newly-created positive restock/new-eggs notification,
--   * or 8+ new ActiveEgg instances arriving in <= 3 seconds.
--
-- A single new ActiveEgg id does NOT clear a strict lock for NORMAL eggs.
-- Volcanic Egg is intentionally exempt: only the exact attempted Volcanic
-- ActiveEgg id is exhausted, because new Volcanic ids are independent spawns.
--
-- A locked normal egg type no longer pins Auto Server Hop in the same server.
-- The K.G hunt may move to a fresh server after the strict local retries fail.
-- ============================================================

shared.SerenityRideAPet.StockGuard =
    shared.SerenityRideAPet.StockGuard
    or {}

shared.SerenityRideAPet.ResetStockGuardRuntime = function()
    local state =
        shared.SerenityRideAPet.StockGuard

    for _, connection in ipairs(
        state.Connections or {}
    ) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    state.Connections = {}
    state.JobId = tostring(game.JobId)
    state.TypeLocks = {}
    state.TypeFailures = {}
    state.ExhaustedActiveIds = {}
    state.LockKnownIds = {}
    state.BurstStartedAt = os.clock()
    state.BurstAdds = 0
    state.StockGeneration = 0
    -- Auto Hop re-arms only from the game's explicit egg-restock notice.
    -- The 8+ ActiveEgg burst remains stock-guard evidence only.
    state.KGHuntRestockGeneration = 0
    state.LastKGHuntRestockAt = 0
    state.LastRestockNotice = ""
    state.LastRestockNoticeAt = 0
    state.LastStockSignalAt = 0
    state.LastStockSignalReason = ""
    state.StartedAt = os.clock()

    return state
end

local restockState =
    shared.SerenityRideAPet.ResetStockGuardRuntime()

-- Volcanic Egg is a special world spawn, not a normal batch-stock type.
-- Never let one failed/claimed Volcanic instance lock future Volcanic ids.
shared.SerenityRideAPet.IsVolcanicStockType =
    function(eggType)
        return
            string.find(
                string.lower(
                    tostring(
                        eggType
                        or ""
                    )
                ),
                "volcanic",
                1,
                true
            ) ~= nil
    end

shared.SerenityRideAPet.VolcanicRetryRuntime =
    shared.SerenityRideAPet.VolcanicRetryRuntime
    or {
        RetryAt = 0,
        RetryDelay = 0,
        LastActive = nil,
        LastReason = nil,
    }

shared.SerenityRideAPet.SetVolcanicRetryCooldown =
    function(active, reason)
        local state =
            shared.SerenityRideAPet
                .VolcanicRetryRuntime

        local text =
            string.lower(
                tostring(
                    reason
                    or ""
                )
            )

        -- Do not hammer a bad starting position every 0.75s. Collision /
        -- entry failures get a longer hands-off window so the player can move
        -- to a clearer area. Prompt replication failures use a shorter retry.
        local retryDelay = 1.25

        if string.find(text, "sky escape", 1, true)
            or string.find(text, "physical collision", 1, true)
            or string.find(text, "volcanovalidated", 1, true)
            or string.find(text, "validation", 1, true) then

            retryDelay = 3.0
        elseif string.find(text, "pickup", 1, true)
            or string.find(text, "basket count did not increase", 1, true) then

            -- The route itself is long and bounded. If the server rejects the
            -- pickup, do not immediately run the entire Volcano trip again.
            retryDelay = 15.0
        elseif string.find(text, "prompt", 1, true)
            or string.find(text, "rendered", 1, true) then

            retryDelay = 1.75
        elseif string.find(text, "disappeared", 1, true) then
            retryDelay = 0.35
        end

        state.RetryDelay =
            retryDelay

        state.RetryAt =
            os.clock() + retryDelay

        state.LastActive =
            active

        state.LastReason =
            tostring(
                reason
                or ""
            )

        log(
            "Volcanic.RetryCooldownSeconds="
            .. tostring(retryDelay)
            .. " Reason="
            .. tostring(state.LastReason)
        )
    end

shared.SerenityRideAPet.VolcanicRetryReady =
    function(active)
        local state =
            shared.SerenityRideAPet
                .VolcanicRetryRuntime

        if state.LastActive ~= active then
            state.LastActive = active
            state.RetryAt = 0
            state.LastReason = nil

            return true
        end

        return
            os.clock()
            >= (
                tonumber(
                    state.RetryAt
                )
                or 0
            )
    end

local function activeEggType(active)
    if not active then
        return ""
    end

    return tostring(
        active:GetAttribute("Egg")
        or ""
    )
end

-- v80.2.76: mirror EggSpawning.Client's native readiness rule exactly.
-- Native client logic is:
--   (tonumber(active:GetAttribute("DropEndsAt")) or 0)
--       <= Workspace:GetServerTimeNow()
-- Therefore a missing DropEndsAt is READY, not permanently blocked.
shared.SerenityRideAPet.ActiveEggDropReady = function(active)
    if not active
        or active.Parent == nil then

        return false, math.huge, nil
    end

    local dropEndsAt =
        tonumber(
            active:GetAttribute(
                "DropEndsAt"
            )
        )

    local effectiveEndsAt =
        dropEndsAt
        or 0

    local remaining =
        effectiveEndsAt
        - Workspace:GetServerTimeNow()

    return
        remaining <= 0,
        math.max(0, remaining),
        dropEndsAt
end

shared.SerenityRideAPet.ActiveEggPrivateAllowed = function(active)
    if not active then
        return false
    end

    local privateTo =
        active:GetAttribute(
            "PrivateTo"
        )

    if privateTo == nil
        or privateTo == false
        or privateTo == ""
        or privateTo == 0 then

        return true
    end

    return
        tostring(privateTo)
            == tostring(LP.UserId)
        or tostring(privateTo)
            == tostring(LP.Name)
end

local function activeCountForType(eggType)
    if not ActiveEggs then
        return 0
    end

    local count = 0

    for _, active in ipairs(
        ActiveEggs:GetChildren()
    ) do
        if activeEggType(active) == eggType then
            count += 1
        end
    end

    return count
end



-- v80.2.74: mirror the game's own EggSpawning HasClaimed() rule.
-- ActiveEgg.Name is only a temporary replicated id; normal stock ownership is
-- authoritative by EggType + Cycle via LocalPlayer.CollectedEggCycles.
shared.SerenityRideAPet.NativeEggClaimRuntime =
    shared.SerenityRideAPet.NativeEggClaimRuntime
    or {
        Raw = nil,
        Cycles = {},
        RecentActiveIds = {},
    }

-- v80.2.78: pending protection is exact-ActiveEgg only. A successful pickup
-- must not temporarily blacklist every other same-type/same-cycle repeatable
-- egg while native CollectedEggCycles replication catches up.
shared.SerenityRideAPet.NativeEggClaimRuntime.RecentActiveIds =
    shared.SerenityRideAPet.NativeEggClaimRuntime.RecentActiveIds
    or {}

-- Remove the old v80.2.77 type-wide pending cache on re-execution.
shared.SerenityRideAPet.NativeEggClaimRuntime.Recent = nil

shared.SerenityRideAPet.ReadCollectedEggCycles = function()
    local state =
        shared.SerenityRideAPet.NativeEggClaimRuntime

    local raw =
        LP:GetAttribute("CollectedEggCycles")

    if type(raw) ~= "string" then
        raw = ""
    end

    if state.Raw == raw then
        return state.Cycles
    end

    state.Raw = raw
    state.Cycles = {}

    if raw ~= "" then
        local ok, decoded =
            pcall(
                HttpService.JSONDecode,
                HttpService,
                raw
            )

        if ok and type(decoded) == "table" then
            state.Cycles = decoded
        end
    end

    return state.Cycles
end

shared.SerenityRideAPet.MarkNativeClaimPending = function(active, eggType)
    if not active then
        return false
    end

    local activeId =
        tostring(
            active.Name
            or ""
        )

    if activeId == "" then
        return false
    end

    local recentById =
        shared.SerenityRideAPet
            .NativeEggClaimRuntime
            .RecentActiveIds

    local now =
        os.clock()

    for id, info in pairs(recentById) do
        if type(info) ~= "table"
            or now > (tonumber(info.Until) or 0) then

            recentById[id] = nil
        end
    end

    recentById[activeId] = {
        EggType = tostring(eggType or ""),
        Cycle = tonumber(active:GetAttribute("Cycle")),
        Until = now + 2.0,
    }

    return true
end

shared.SerenityRideAPet.IsNativeEggClaimed = function(active)
    if not active then
        return true, "NoActiveEgg"
    end

    local eggType = activeEggType(active)
    if eggType == "" then
        return true, "MissingEggType"
    end

    -- Volcanic has its own continuously reusable special-spawn policy.
    if shared.SerenityRideAPet.IsVolcanicStockType(eggType) then
        return false, "VolcanicAlwaysEligible"
    end

    if active:GetAttribute("AdminSpawn") == true then
        local adminId = active:GetAttribute("AdminEggId")
        local collectedAdmin =
            LP:GetAttribute("CollectedAdminEggs")

        if type(adminId) == "string"
            and type(collectedAdmin) == "string"
            and string.find(
                collectedAdmin,
                "," .. adminId .. ",",
                1,
                true
            ) ~= nil then

            return true, "CollectedAdminEggs"
        end

        return false, "AdminNotCollected"
    end

    local cycle =
        tonumber(active:GetAttribute("Cycle"))

    local cycles =
        shared.SerenityRideAPet.ReadCollectedEggCycles()

    local collectedCycle =
        tonumber(cycles[eggType])

    if cycle and collectedCycle
        and cycle <= collectedCycle then

        return true, "CollectedEggCycles"
    end

    local activeId =
        tostring(
            active.Name
            or ""
        )

    local recentById =
        shared.SerenityRideAPet
            .NativeEggClaimRuntime
            .RecentActiveIds

    local recent =
        recentById[activeId]

    if type(recent) == "table" then
        if os.clock()
            <= (tonumber(recent.Until) or 0) then

            return true, "RecentConfirmedActiveClaim"
        end

        recentById[activeId] = nil
    end

    local collected =
        LP:GetAttribute("CollectedEggs")

    if (not cycle or not collectedCycle)
        and type(collected) == "string"
        and collected ~= ""
        and string.find(
            collected,
            eggType .. ",",
            1,
            true
        ) ~= nil then

        return true, "CollectedEggs"
    end

    return false, "NotClaimed", collectedCycle
end

shared.SerenityRideAPet.IsActiveEggExhausted = function(active)
    if not active then
        return true
    end

    local eggType =
        activeEggType(
            active
        )

    -- Volcanic is a continuously re-usable special spawn lane.
    -- Never let a previous attempt blacklist the current replicated entry,
    -- even if the game reuses the same ActiveEgg Name/Object across spawns.
    if shared.SerenityRideAPet
        .IsVolcanicStockType(
            eggType
        ) then

        restockState.ExhaustedActiveIds[
            tostring(
                active.Name
            )
        ] = nil

        return false
    end

    return
        restockState.ExhaustedActiveIds[
            tostring(active.Name)
        ] == true
end

shared.SerenityRideAPet.MarkCurrentTypeEntriesExhausted = function(
    eggType
)
    eggType = tostring(eggType or "")

    if eggType == ""
        or not ActiveEggs then

        return
    end

    restockState.LockKnownIds[eggType] =
        restockState.LockKnownIds[eggType]
        or {}

    for _, active in ipairs(
        ActiveEggs:GetChildren()
    ) do
        if activeEggType(active) == eggType then
            local id =
                tostring(active.Name)

            restockState.ExhaustedActiveIds[id] =
                true

            restockState.LockKnownIds[eggType][id] =
                true
        end
    end
end

shared.SerenityRideAPet.LockEggTypeForStock = function(
    eggType,
    reason,
    activeName
)
    eggType = tostring(eggType or "")

    if eggType == "" then
        return false
    end

    -- Critical v80.2.72 fix:
    -- Volcanic Egg can spawn independently many times. The old generic
    -- stock guard locked the ENTIRE egg type after one confirmed claim or
    -- three route/prompt failures. A single new Volcanic ActiveEgg id was
    -- intentionally not enough to unlock that type, so later Volcanic
    -- spawns could be ignored indefinitely.
    --
    -- For Volcanic only, exhaust the exact attempted ActiveEgg id and keep
    -- the egg TYPE open. This preserves the strict stock guard for every
    -- normal egg while making each genuinely new Volcanic spawn eligible.
    if shared.SerenityRideAPet
        .IsVolcanicStockType(
            eggType
        ) then

        -- v80.2.73:
        -- NO type lock and NO exact-id exhaustion for Volcanic.
        -- The game may reuse the same ActiveEgg Name/Object for repeated
        -- Volcanic spawns, so even exact-id blacklisting can starve it.
        restockState.TypeLocks[
            eggType
        ] = nil

        restockState.TypeFailures[
            eggType
        ] = nil

        if activeName ~= nil
            and tostring(activeName) ~= "" then

            restockState.ExhaustedActiveIds[
                tostring(
                    activeName
                )
            ] = nil
        end

        log("")
        log(
            "=== VOLCANIC_STOCK_BYPASS ==="
        )
        log("EggType=" .. eggType)
        log(
            "ActiveName="
            .. tostring(
                activeName
                or ""
            )
        )
        log(
            "Reason="
            .. tostring(
                reason
                or ""
            )
        )
        log(
            "Policy=NEVER_PERSISTENTLY_BLACKLIST_VOLCANIC"
        )

        return false
    end

    shared.SerenityRideAPet.MarkCurrentTypeEntriesExhausted(
        eggType
    )

    if activeName ~= nil
        and tostring(activeName) ~= "" then

        local id =
            tostring(activeName)

        restockState.ExhaustedActiveIds[id] =
            true

        restockState.LockKnownIds[eggType] =
            restockState.LockKnownIds[eggType]
            or {}

        restockState.LockKnownIds[eggType][id] =
            true
    end

    restockState.TypeLocks[eggType] = {
        Reason = tostring(reason or "stock locked"),
        LockedAt = os.clock(),
        JobId = tostring(game.JobId),
        Generation =
            tonumber(
                restockState.StockGeneration
            )
            or 0,
        ActiveName = tostring(activeName or ""),
        Cycle =
            ActiveEggs
            and activeName ~= nil
            and ActiveEggs:FindFirstChild(tostring(activeName))
            and tonumber(
                ActiveEggs
                    :FindFirstChild(tostring(activeName))
                    :GetAttribute("Cycle")
            )
            or nil,
    }

    log("")
    log("=== STOCK_GUARD_LOCK ===")
    log("EggType=" .. eggType)
    log(
        "FailureCount="
        .. tostring(
            tonumber(
                restockState.TypeFailures[
                    eggType
                ]
            )
            or 0
        )
        .. "/3"
    )
    log("Reason=" .. tostring(reason))
    log("Action=WAIT_FOR_NEW_STOCK")

    return true
end

shared.SerenityRideAPet.UnlockEggTypeForNewStock = function(
    eggType,
    reason
)
    eggType = tostring(eggType or "")

    if eggType == ""
        or restockState.TypeLocks[eggType] == nil then

        return false
    end

    local known =
        restockState.LockKnownIds[eggType]

    if type(known) == "table" then
        for id in pairs(known) do
            restockState.ExhaustedActiveIds[id] = nil
        end
    end

    restockState.TypeLocks[eggType] = nil
    restockState.TypeFailures[eggType] = nil
    restockState.LockKnownIds[eggType] = nil

    log("")
    log("=== STOCK_GUARD_UNLOCK ===")
    log("EggType=" .. eggType)
    log("Reason=" .. tostring(reason))
    log("Action=ALLOW_3_NEW_ATTEMPTS")

    return true
end

shared.SerenityRideAPet.SignalNewEggStock = function(reason)
    local now =
        os.clock()

    local sinceLast =
        now
        - (
            tonumber(
                restockState.LastStockSignalAt
            )
            or 0
        )

    -- One real restock can produce a banner plus several bursts of ChildAdded
    -- events. Treat them as one generation.
    if restockState.LastStockSignalAt ~= 0
        and sinceLast < 4 then

        log("")
        log("=== NEW_EGG_STOCK_SIGNAL_DEDUPED ===")
        log("Reason=" .. tostring(reason))
        log("SinceLastSeconds=" .. tostring(sinceLast))

        return false
    end

    restockState.LastStockSignalAt =
        now

    restockState.LastStockSignalReason =
        tostring(reason or "")

    restockState.StockGeneration =
        (tonumber(
            restockState.StockGeneration
        ) or 0)
        + 1

    local unlocked = 0

    for eggType in pairs(
        restockState.TypeLocks
    ) do
        local known =
            restockState.LockKnownIds[eggType]

        if type(known) == "table" then
            for id in pairs(known) do
                restockState.ExhaustedActiveIds[id] = nil
            end
        end

        restockState.TypeLocks[eggType] = nil
        restockState.TypeFailures[eggType] = nil
        restockState.LockKnownIds[eggType] = nil
        unlocked += 1
    end

    -- Any partial failure sequence belongs to the old stock too.
    restockState.TypeFailures = {}

    log("")
    log("=== NEW_EGG_STOCK_SIGNAL ===")
    log(
        "Generation="
        .. tostring(
            restockState.StockGeneration
        )
    )
    log("UnlockedTypes=" .. tostring(unlocked))
    log("Reason=" .. tostring(reason))

    return true
end

shared.SerenityRideAPet.SyncStealRestockState = function()
    return
        "stock-guard-v5:"
        .. tostring(
            restockState.StockGeneration
            or 0
        )
end

shared.SerenityRideAPet.IsEggRestockBlocked = function(eggType, active)
    eggType =
        tostring(
            eggType
            or ""
        )

    if shared.SerenityRideAPet
        .IsVolcanicStockType(
            eggType
        ) then

        -- Defensive cleanup for any stale pre-v80.2.72 runtime lock.
        restockState.TypeLocks[
            eggType
        ] = nil

        return false
    end

    local lock =
        restockState.TypeLocks[
            eggType
        ]

    if not lock then
        return false
    end

    -- If the game exposes a strictly newer stock cycle, the old 3-failure
    -- lock belongs to the prior cycle and must not block the new stock.
    if active then
        local activeCycle =
            tonumber(active:GetAttribute("Cycle"))

        local lockCycle =
            tonumber(lock.Cycle)

        if activeCycle and lockCycle
            and activeCycle > lockCycle then

            shared.SerenityRideAPet.UnlockEggTypeForNewStock(
                eggType,
                "newer native egg cycle"
            )

            return false
        end
    end

    return true
end

shared.SerenityRideAPet.RecordStealRestockFailure = function(
    eggType,
    reason,
    activeName
)
    eggType = tostring(eggType or "")

    if eggType == "" then
        return false
    end

    if shared.SerenityRideAPet
        .IsVolcanicStockType(
            eggType
        ) then

        restockState.TypeLocks[
            eggType
        ] = nil

        restockState.TypeFailures[
            eggType
        ] = nil

        if ActiveEggs
            and activeName ~= nil then

            local active =
                ActiveEggs:FindFirstChild(
                    tostring(
                        activeName
                    )
                )

            shared.SerenityRideAPet
                .SetVolcanicRetryCooldown(
                    active,
                    reason
                )
        end

        return false
    end

    if restockState.TypeLocks[eggType] ~= nil then
        return true
    end

    local failures =
        math.min(
            3,
            (tonumber(
                restockState.TypeFailures[eggType]
            ) or 0)
            + 1
        )

    restockState.TypeFailures[eggType] =
        failures

    log("")
    log("=== STOCK_GUARD_FAILURE ===")
    log("EggType=" .. eggType)
    log(
        "Attempt="
        .. tostring(failures)
        .. "/3"
    )
    log("Reason=" .. tostring(reason))

    if failures >= 3 then
        return
            shared.SerenityRideAPet.LockEggTypeForStock(
                eggType,
                "strict 3-failure limit reached: "
                    .. tostring(reason),
                activeName
            )
    end

    return false
end

shared.SerenityRideAPet.RecordStealRestockSuccess = function(
    eggType,
    activeOrName
)
    eggType = tostring(eggType or "")

    restockState.TypeFailures[eggType] = nil
    restockState.TypeLocks[eggType] = nil

    local active =
        typeof(activeOrName) == "Instance"
        and activeOrName
        or (
            ActiveEggs
            and activeOrName ~= nil
            and ActiveEggs:FindFirstChild(
                tostring(activeOrName)
            )
            or nil
        )

    if shared.SerenityRideAPet
        .IsVolcanicStockType(
            eggType
        ) then

        if activeOrName ~= nil then
            local id =
                typeof(activeOrName) == "Instance"
                and tostring(activeOrName.Name)
                or tostring(activeOrName)

            restockState.ExhaustedActiveIds[id] = nil
        end

        local retry =
            shared.SerenityRideAPet
                .VolcanicRetryRuntime

        retry.RetryAt = 0
        retry.LastActive = nil
        retry.LastReason = nil

        return false
    end

    -- Native EggType+Cycle ownership is now authoritative. Do not lock the
    -- whole normal egg type after one success. A second same-name entry is
    -- allowed only if the native cycle says it is genuinely newer/unclaimed.
    if active then
        shared.SerenityRideAPet.MarkNativeClaimPending(
            active,
            eggType
        )
    end

    if activeOrName ~= nil then
        local id =
            typeof(activeOrName) == "Instance"
            and tostring(activeOrName.Name)
            or tostring(activeOrName)

        restockState.ExhaustedActiveIds[id] = nil
    end

    return false
end

shared.SerenityRideAPet.HasBlockedMatchingEggInServer = function()
    for eggType in pairs(
        restockState.TypeLocks
    ) do
        return true, eggType
    end

    return false
end

shared.SerenityRideAPet.StockGuardState = function()
    return restockState
end

-- v80.2.82: native stock Cycle is the authoritative Auto Hop restock marker.
-- Normal batch-stock eggs replicate with a Cycle; Volcanic/Admin spawns are
-- excluded because they are independent of the normal account stock window.
shared.SerenityRideAPet.CurrentNativeStockCycle = function(onlyEggType)
    if not ActiveEggs then
        return nil
    end

    local requestedType =
        tostring(onlyEggType or "")

    local newest = nil

    for _, active in ipairs(
        ActiveEggs:GetChildren()
    ) do
        local eggType =
            activeEggType(active)

        if eggType ~= ""
            and (requestedType == "" or eggType == requestedType)
            and active:GetAttribute("Area") ~= true
            and active:GetAttribute("AdminSpawn") ~= true
            and not shared.SerenityRideAPet.IsVolcanicStockType(
                eggType
            ) then

            local cycle =
                tonumber(
                    active:GetAttribute("Cycle")
                )

            if cycle
                and (newest == nil or cycle > newest) then

                newest = cycle
            end
        end
    end

    return newest
end

-- The game exposes one deterministic stock clock through GameServices.EggCycle.
-- Live v88 tests proved EggCycle.Index advanced exactly with the real global egg
-- restock (4263872 -> 4263873) and was identical to the normal ActiveEgg Cycle.
-- Use that Index as Auto Hop's primary stock identity across every server.
shared.SerenityRideAPet.GlobalEggCycleRuntime =
    shared.SerenityRideAPet.GlobalEggCycleRuntime
    or {
        Module = nil,
        LastTryAt = 0,
    }

shared.SerenityRideAPet.ReadGlobalEggCycle = function()
    local runtime =
        shared.SerenityRideAPet.GlobalEggCycleRuntime

    if type(runtime.Module) ~= "table"
        and (
            (tonumber(runtime.LastTryAt) or 0) <= 0
            or os.clock() - (tonumber(runtime.LastTryAt) or 0) >= 2
        ) then

        runtime.LastTryAt = os.clock()

        local ok, moduleOrErr =
            pcall(function()
                return require(
                    ReplicatedStorage
                        :WaitForChild("GameServices", 5)
                        :WaitForChild("EggCycle", 5)
                )
            end)

        if ok and type(moduleOrErr) == "table" then
            runtime.Module = moduleOrErr
            runtime.LastError = nil
        else
            runtime.Module = nil
            runtime.LastError = tostring(moduleOrErr)
        end
    end

    local module = runtime.Module
    if type(module) ~= "table" then
        return nil, nil, nil, runtime.LastError
    end

    local nowValue = nil
    local indexValue = nil
    local remainingValue = nil

    if type(module.Now) == "function" then
        local ok, value = pcall(module.Now)
        if ok then
            nowValue = tonumber(value)
        end
    end

    if type(module.Index) == "function" then
        local ok, value

        if nowValue ~= nil then
            ok, value = pcall(module.Index, nowValue)
        end

        if not ok then
            ok, value = pcall(module.Index)
        end

        if ok then
            indexValue = tonumber(value)
        end
    end

    if type(module.SecondsRemaining) == "function" then
        local ok, value

        if nowValue ~= nil then
            ok, value = pcall(
                module.SecondsRemaining,
                nowValue
            )
        end

        if not ok then
            ok, value = pcall(module.SecondsRemaining)
        end

        if ok then
            remainingValue = tonumber(value)
        end
    end

    return indexValue, remainingValue, nowValue, nil
end

shared.SerenityRideAPet.CurrentGlobalEggCycleIndex = function()
    local index =
        shared.SerenityRideAPet.ReadGlobalEggCycle()

    return tonumber(index)
end

-- Compatibility name retained because existing ActiveEgg/restock observers call
-- this helper. Global EggCycle.Index is primary; per-egg Cycle is fallback only.
shared.SerenityRideAPet.SyncAutoHopNativeStock = function(
    reason,
    observedCycle,
    observedEggType
)
    if Config.AutoHopKGSatisfied ~= true then
        return false
    end

    local currentGlobal =
        shared.SerenityRideAPet.CurrentGlobalEggCycleIndex()

    local savedGlobal =
        tonumber(
            Config.AutoHopKGSatisfiedGlobalCycle
        )
        or 0

    local legacySavedCycle =
        tonumber(
            Config.AutoHopKGSatisfiedStockCycle
        )
        or 0

    if currentGlobal and currentGlobal > 0 then
        -- Migrate v87/v88 success state. Their normal ActiveEgg Cycle matched
        -- EggCycle.Index in live tests, so a matching legacy cycle is safe to
        -- adopt. If it differs, the global stock already advanced while the
        -- script was off/teleporting, so the old success must expire now.
        if savedGlobal <= 0 then
            if legacySavedCycle > 0
                and legacySavedCycle ~= currentGlobal then

                savedGlobal = legacySavedCycle
            else
                Config.AutoHopKGSatisfiedGlobalCycle =
                    currentGlobal
                saveConfig()

                log("")
                log("=== KG_HUNT_GLOBAL_CYCLE_BASELINE ===")
                log("Cycle=" .. tostring(currentGlobal))
                log("Reason=" .. tostring(reason or "baseline"))

                return false
            end
        end

        if savedGlobal == currentGlobal then
            return false
        end

        Config.AutoHopKGSatisfied = false
        Config.AutoHopKGSatisfiedSignature = ""
        Config.AutoHopKGSatisfiedEggType = ""
        Config.AutoHopKGSatisfiedKG = 0
        Config.AutoHopKGSatisfiedStockCycle = 0
        Config.AutoHopKGSatisfiedGlobalCycle = 0
        saveConfig()

        restockState.KGHuntRestockGeneration =
            (tonumber(
                restockState.KGHuntRestockGeneration
            ) or 0)
            + 1

        restockState.LastKGHuntRestockAt =
            os.clock()

        log("")
        log("=== KG_HUNT_GLOBAL_NEW_STOCK ===")
        log("SavedCycle=" .. tostring(savedGlobal))
        log("CurrentCycle=" .. tostring(currentGlobal))
        log("Reason=" .. tostring(reason or "global-cycle"))
        log("AutoHopRearmed=true")

        return true
    end

    -- Fallback only: if EggCycle is unavailable, retain the proven v85-v87
    -- type-local native Cycle behavior instead of disabling persistence.
    local trackedEggType =
        tostring(
            Config.AutoHopKGSatisfiedEggType
            or ""
        )

    if trackedEggType ~= ""
        and observedEggType ~= nil
        and tostring(observedEggType) ~= trackedEggType then

        return false
    end

    local currentCycle =
        tonumber(observedCycle)
        or shared.SerenityRideAPet.CurrentNativeStockCycle(
            trackedEggType ~= "" and trackedEggType or nil
        )

    if not currentCycle then
        return false
    end

    if legacySavedCycle <= 0 then
        Config.AutoHopKGSatisfiedStockCycle =
            currentCycle
        saveConfig()
        return false
    end

    if currentCycle <= legacySavedCycle then
        return false
    end

    Config.AutoHopKGSatisfied = false
    Config.AutoHopKGSatisfiedSignature = ""
    Config.AutoHopKGSatisfiedEggType = ""
    Config.AutoHopKGSatisfiedKG = 0
    Config.AutoHopKGSatisfiedStockCycle = 0
    Config.AutoHopKGSatisfiedGlobalCycle = 0
    saveConfig()

    restockState.KGHuntRestockGeneration =
        (tonumber(
            restockState.KGHuntRestockGeneration
        ) or 0)
        + 1

    restockState.LastKGHuntRestockAt =
        os.clock()

    log("")
    log("=== KG_HUNT_NATIVE_FALLBACK_NEW_STOCK ===")
    log("SavedCycle=" .. tostring(legacySavedCycle))
    log("CurrentCycle=" .. tostring(currentCycle))
    log("Reason=" .. tostring(reason or "native-fallback"))
    log("AutoHopRearmed=true")

    return true
end

shared.SerenityRideAPet.ObserveRestockNotification = function(textValue)
    local raw =
        tostring(textValue or "")

    if raw == "" then
        return false
    end

    local plain =
        string.lower(
            raw:gsub("<.->", "")
        )

    -- Only EGG-specific positive "stock changed NOW" language may unlock
    -- Auto Steal stock state. Generic shop messages such as
    -- "Restocked Gear Shop" must never count as an egg restock.
    local mentionsEgg =
        string.find(
            plain,
            "egg",
            1,
            true
        ) ~= nil

    local explicitEggSignal =
        string.find(
            plain,
            "new eggs",
            1,
            true
        )
        or string.find(
            plain,
            "eggs refreshed",
            1,
            true
        )
        or string.find(
            plain,
            "eggs have spawned",
            1,
            true
        )
        or string.find(
            plain,
            "eggs spawned",
            1,
            true
        )

    local eggRestocked =
        mentionsEgg
        and (
            string.find(
                plain,
                "restocked",
                1,
                true
            )
            or string.find(
                plain,
                "has restocked",
                1,
                true
            )
            or string.find(
                plain,
                "have restocked",
                1,
                true
            )
        )

    local positive =
        explicitEggSignal
        or eggRestocked

    if not positive then
        return false
    end

    local now =
        os.clock()

    if restockState.LastRestockNotice == plain
        and now
            - (tonumber(
                restockState.LastRestockNoticeAt
            ) or 0)
            < 1.5 then

        return true
    end

    restockState.LastRestockNotice =
        plain

    restockState.LastRestockNoticeAt =
        now

    -- v80.2.89: EggCycle.Index is primary. A live notification is only a
    -- fallback if the global cycle module is unavailable. This prevents stale
    -- or duplicate UI notices from reopening a hunt inside the same stock.
    if Config.AutoRejoinNoEgg == true
        and now
            - (tonumber(
                restockState.LastKGHuntRestockAt
            ) or 0) >= 4 then

        local globalIndex =
            shared.SerenityRideAPet.CurrentGlobalEggCycleIndex()

        local rearmed =
            shared.SerenityRideAPet.SyncAutoHopNativeStock(
                "game-restock-notification"
            )

        if not rearmed
            and not globalIndex
            and Config.AutoHopKGSatisfied == true then

            restockState.KGHuntRestockGeneration =
                (tonumber(
                    restockState.KGHuntRestockGeneration
                ) or 0)
                + 1

            restockState.LastKGHuntRestockAt =
                now

            Config.AutoHopKGSatisfied = false
            Config.AutoHopKGSatisfiedSignature = ""
            Config.AutoHopKGSatisfiedEggType = ""
            Config.AutoHopKGSatisfiedKG = 0
            Config.AutoHopKGSatisfiedStockCycle = 0
            Config.AutoHopKGSatisfiedGlobalCycle = 0
            saveConfig()

            log("")
            log("=== KG_HUNT_NOTIFICATION_FALLBACK_NEW_STOCK ===")
            log("Reason=game-restock-notification")
            log("AutoHopRearmed=true")
        end
    end

    return
        shared.SerenityRideAPet.SignalNewEggStock(
            "game restock notification: "
            .. raw
        )
end

if ActiveEggs then
    restockState.Connections[
        #restockState.Connections + 1
    ] =
        ActiveEggs.ChildAdded:Connect(
            function(active)
                task.spawn(function()
                    local eggType = ""

                    for _ = 1, 40 do
                        if active.Parent ~= ActiveEggs then
                            return
                        end

                        eggType =
                            activeEggType(active)

                        if eggType ~= "" then
                            break
                        end

                        task.wait(0.025)
                    end

                    if eggType == "" then
                        return
                    end

                    if active:GetAttribute("Area") ~= true
                        and active:GetAttribute("AdminSpawn") ~= true
                        and not shared.SerenityRideAPet
                            .IsVolcanicStockType(
                                eggType
                            ) then

                        shared.SerenityRideAPet.SyncAutoHopNativeStock(
                            "active-egg-cycle",
                            tonumber(
                                active:GetAttribute("Cycle")
                            ),
                            eggType
                        )
                    end

                    if shared.SerenityRideAPet
                        .IsVolcanicStockType(
                            eggType
                        ) then

                        restockState.ExhaustedActiveIds[
                            tostring(
                                active.Name
                            )
                        ] = nil

                        restockState.TypeLocks[
                            eggType
                        ] = nil

                        restockState.TypeFailures[
                            eggType
                        ] = nil

                        local retry =
                            shared.SerenityRideAPet
                                .VolcanicRetryRuntime

                        retry.RetryAt = 0
                        retry.LastActive = active
                        retry.LastReason = nil
                    end

                    local now =
                        os.clock()

                    if now
                        - (tonumber(
                            restockState.BurstStartedAt
                        ) or now)
                        > 3 then

                        restockState.BurstStartedAt =
                            now

                        restockState.BurstAdds = 0
                    end

                    restockState.BurstAdds =
                        (tonumber(
                            restockState.BurstAdds
                        ) or 0)
                        + 1

                    -- This is strong world-stock evidence, unlike a static
                    -- GUI label that happened to exist before execution.
                    if restockState.BurstAdds >= 8 then
                        restockState.BurstStartedAt =
                            now

                        restockState.BurstAdds = 0

                        shared.SerenityRideAPet.SignalNewEggStock(
                            "8+ new ActiveEggs in 3 seconds"
                        )

                        return
                    end

                    local lock =
                        restockState.TypeLocks[
                            eggType
                        ]

                    if lock then
                        -- A single new id is not enough evidence to reopen a
                        -- strict 3-failure lock. Keep waiting for the verified
                        -- restock banner or the multi-egg stock burst.
                        restockState.LockKnownIds[eggType] =
                            restockState.LockKnownIds[eggType]
                            or {}

                        restockState.LockKnownIds[eggType][
                            tostring(active.Name)
                        ] = true
                    end
                end)
            end
        )
end

-- Restock UI banners are handled by the single managed notification bus.
-- ActiveEggs.ChildAdded burst detection remains the authoritative fallback.

local function hasSpecificStealEggSelection()
    return
        #selectionAsArray(
            shared.SerenityRideAPet.ActiveStealSetting(
                "StealEggs",
                {}
            )
        ) > 0
end

-- v80.2.78:
-- Minimum K.G is the HARD gate whenever it is enabled.
--
--   1) Egg must meet Minimum K.G.
--   2) If Minimum Luck is enabled, the egg must meet Minimum Luck OR be in
--      Specific Eggs.
--   3) Specific Eggs never bypass Minimum K.G.
--   4) With Minimum Luck = Any and Minimum K.G enabled, every K.G-matching
--      egg remains eligible. With K.G disabled, Specific Eggs keeps its
--      normal name-filter behavior.
shared.SerenityRideAPet.AutoStealFilterAllowed =
    function(eggType, eggWeight, eggLuck)
        local specificEnabled =
            hasSpecificStealEggSelection()

        local minimumKG =
            shared.SerenityRideAPet.MinimumStealKG()

        local kgEnabled =
            minimumKG > 0

        local minimumLuck =
            stealMinimumLuck()

        local activeStealMinLuck =
            shared.SerenityRideAPet.ActiveStealSetting(
                "StealMinLuck",
                "Any"
            )

        local activeStealEggs =
            shared.SerenityRideAPet.ActiveStealSetting(
                "StealEggs",
                {}
            )

        local luckEnabled =
            tostring(
                activeStealMinLuck
                or "Any"
            ) ~= "Any"

        local selected =
            specificEnabled
            and selectionHas(
                activeStealEggs,
                eggType
            )

        local kgPass =
            not kgEnabled
            or (
                tonumber(eggWeight)
                or 0
            ) >= minimumKG

        local kgMatch =
            kgEnabled
            and kgPass

        local luckMatch =
            luckEnabled
            and (
                tonumber(eggLuck)
                or 0
            ) >= minimumLuck

        -- Minimum K.G is never bypassed by Luck or Specific Eggs.
        if not kgPass then
            return
                false,
                selected == true,
                false,
                luckMatch == true
        end

        -- With a real Minimum Luck threshold, Specific Eggs is the only
        -- alternate way through the Luck filter, but still after K.G passed.
        if luckEnabled then
            return
                luckMatch == true
                    or selected == true,
                selected == true,
                kgMatch == true,
                luckMatch == true
        end

        -- If K.G is disabled, preserve Specific Eggs as a real name filter.
        if specificEnabled
            and not kgEnabled then

            return
                selected == true,
                selected == true,
                false,
                false
        end

        -- Minimum Luck = Any: once the K.G hard gate passes, the egg is valid.
        return
            true,
            selected == true,
            kgMatch == true,
            false
    end

-- This reads the authoritative replicated server egg list first.
-- It does NOT decide from whatever happens to be nearest/rendered first.
local function serverEggCandidates()
    if not ActiveEggs then
        return {}
    end

    shared.SerenityRideAPet.SyncStealRestockState()

    local list = {}

    for _, active in ipairs(ActiveEggs:GetChildren()) do
        local eggType = tostring(active:GetAttribute("Egg") or "")
        local privateTo = active:GetAttribute("PrivateTo")
        local position = active:GetAttribute("Position")
        local dropReady,
            dropRemaining,
            dropEndsAt =
            shared.SerenityRideAPet.ActiveEggDropReady(
                active
            )

        local isVolcanic =
            shared.SerenityRideAPet
                .IsVolcanicStockType(
                    eggType
                )

        if eggType ~= ""
            and shared.SerenityRideAPet.ActiveEggPrivateAllowed(active)
            and typeof(position) == "Vector3"
            and (
                isVolcanic
                or not isGhostEgg(
                    active
                )
            )
            and not shared.SerenityRideAPet.IsNativeEggClaimed(active)
            and not shared.SerenityRideAPet.IsEggRestockBlocked(eggType, active)
            and (
                isVolcanic
                or not shared.SerenityRideAPet
                    .IsActiveEggExhausted(
                        active
                    )
            ) then

            local meta = eggMeta[eggType] or {}
            local eggLuck = tonumber(meta.luck) or 0

            local eggWeight,
                eggWeightText,
                rawWeight =
                    shared.SerenityRideAPet.ActiveEggKG(
                        active
                    )

            eggWeight =
                tonumber(eggWeight)
                or 0

            local allowedByTargetRules,
                selectedByName,
                kgMatch,
                luckMatch =
                shared.SerenityRideAPet
                    .AutoStealFilterAllowed(
                        eggType,
                        eggWeight,
                        eggLuck
                    )

            if allowedByTargetRules then

                list[#list + 1] = {
                    active = active,
                    eggType = eggType,
                    position = position,
                    eggLuck = eggLuck,
                    eggWeight = eggWeight,
                    eggWeightText = eggWeightText,
                    rawWeight = rawWeight,
                    selectedByName = selectedByName == true,
                    kgMatch = kgMatch == true,
                    luckMatch = luckMatch == true,
                    dropReady = dropReady == true,
                    dropRemaining = dropRemaining,
                    dropEndsAt = dropEndsAt,
                    rarity = tostring(meta.rarity or "?"),
                    appearChance = tonumber(meta.appearChance),
                    distance = (position - HRP.Position).Magnitude,
                }
            end
        end
    end

    local lowFirst =
        tostring(
            shared.SerenityRideAPet.ActiveStealSetting(
                "StealPriority",
                "Highest to Lowest"
            )
        ) == "Lowest to Highest"

    local kgHuntRuntime =
        shared.SerenityRideAPet.KGHuntRuntime

    local prioritizeKGTargets =
        Config.AutoRejoinNoEgg == true
        and shared.SerenityRideAPet.MinimumStealKG() > 0
        and (
            not kgHuntRuntime
            or kgHuntRuntime.GoalSatisfied ~= true
        )

    table.sort(list, function(a, b)
        -- During an active K.G server hunt, qualifying K.G eggs go first so
        -- selected lower-K.G targets cannot consume the whole opportunity
        -- window before the hunted egg is collected. Outside that hunt,
        -- preserve the user's normal Steal Priority exactly.
        if prioritizeKGTargets
            and a.kgMatch ~= b.kgMatch then

            return a.kgMatch == true
        end

        -- Preserve the existing Egg Luck priority rule.
        if a.eggLuck ~= b.eggLuck then
            if lowFirst then
                return a.eggLuck < b.eggLuck
            end

            return a.eggLuck > b.eggLuck
        end

        -- Same-Luck tie breaker: rarer spawn first for Highest,
        -- more common spawn first for Lowest.
        if a.appearChance
            and b.appearChance
            and a.appearChance ~= b.appearChance then

            if lowFirst then
                return a.appearChance > b.appearChance
            end

            return a.appearChance < b.appearChance
        end

        if a.distance ~= b.distance then
            return a.distance < b.distance
        end

        return a.eggType < b.eggType
    end)

    return list
end

-- K.G-hop diagnostic helper for a stock-locked target.
-- Diagnostic helper kept aligned with the current K.G + Luck/Specific target model.
shared.SerenityRideAPet.HasBlockedCurrentRejoinTarget = function()
    if not ActiveEggs then
        return false
    end

    shared.SerenityRideAPet.SyncStealRestockState()

    local minimumKG =
        shared.SerenityRideAPet.MinimumStealKG()

    for _, active in ipairs(
        ActiveEggs:GetChildren()
    ) do
        local eggType =
            tostring(
                active:GetAttribute("Egg")
                or ""
            )

        if eggType ~= ""
            and not shared.SerenityRideAPet.IsNativeEggClaimed(active)
            and shared.SerenityRideAPet.IsEggRestockBlocked(
                eggType,
                active
            ) then

            local position =
                active:GetAttribute("Position")

            if shared.SerenityRideAPet.ActiveEggPrivateAllowed(active)
                and typeof(position) == "Vector3"
                and not isGhostEgg(active) then

                local eggKG =
                    shared.SerenityRideAPet.ActiveEggKG(
                        active
                    )
                    or 0

                if eggKG >= minimumKG then
                    local meta =
                        eggMeta[eggType]
                        or {}

                    return
                        true,
                        eggType,
                        tonumber(meta.luck) or 0,
                        eggKG
                end
            end
        end
    end

    return false
end

-- v80.2.84: Native claim recovery for Auto Hop.
-- If this account already claimed a NORMAL current-stock egg and that exact
-- replicated egg still satisfies the active K.G + Luck/Specific filters, the
-- hunt is already complete. This is intentionally separate from Auto Steal: a
-- claimed egg remains excluded from steal candidates, but it must not cause
-- pointless server hopping for the same stock.
local lastClaimedRejoinScanAt = 0

local function claimedCurrentRejoinTarget()
    if not ActiveEggs then
        return nil
    end

    local now =
        os.clock()

    -- Native claim recovery is only a safety check; keep it low-frequency so
    -- large ActiveEgg lists do not become a new hot loop.
    if now - lastClaimedRejoinScanAt < 0.75 then
        return nil
    end

    lastClaimedRejoinScanAt =
        now

    for _, active in ipairs(
        ActiveEggs:GetChildren()
    ) do
        local eggType =
            tostring(
                active:GetAttribute("Egg")
                or ""
            )

        local normalStock =
            eggType ~= ""
            and active:GetAttribute("Area") ~= true
            and active:GetAttribute("AdminSpawn") ~= true
            and not shared.SerenityRideAPet.IsVolcanicStockType(
                eggType
            )

        local nativeClaimed =
            normalStock
            and shared.SerenityRideAPet.IsNativeEggClaimed(
                active
            )

        -- Use the exact rule mirrored from the game's HasClaimed():
        -- an ActiveEgg is already consumed when its Cycle is at or below the
        -- account's CollectedEggCycles value. Strict equality was too narrow
        -- across servers and made Auto Hop continue after a real claim.
        if normalStock
            and nativeClaimed then

            local position =
                active:GetAttribute("Position")

            if shared.SerenityRideAPet.ActiveEggPrivateAllowed(active)
                and typeof(position) == "Vector3" then

                local eggWeight =
                    shared.SerenityRideAPet.ActiveEggKG(
                        active
                    )
                    or 0

                local meta =
                    eggMeta[eggType]
                    or {}

                local eggLuck =
                    tonumber(meta.luck)
                    or 0

                local allowed =
                    shared.SerenityRideAPet.AutoStealFilterAllowed(
                        eggType,
                        eggWeight,
                        eggLuck
                    )

                if allowed then
                    return {
                        active = active,
                        eggType = eggType,
                        position = position,
                        eggLuck = eggLuck,
                        eggWeight = tonumber(eggWeight) or 0,
                        NativeClaimRecovery = true,
                    }
                end
            end
        end
    end

    return nil
end

local function serverHasRejoinTargetEgg()
    if not ActiveEggs then
        return false
    end

    shared.SerenityRideAPet.SyncStealRestockState()

    for _, active in ipairs(
        ActiveEggs:GetChildren()
    ) do
        local eggType =
            tostring(
                active:GetAttribute("Egg")
                or ""
            )

        local position =
            active:GetAttribute("Position")

        local isVolcanic =
            shared.SerenityRideAPet.IsVolcanicStockType(
                eggType
            )

        -- Auto Hop must use the SAME eligibility rule as Auto Steal:
        -- Minimum K.G is the hard gate, then Minimum Luck OR Specific Eggs.
        -- DropEndsAt is intentionally not required here: a qualifying falling
        -- egg keeps the server while Auto Steal waits for native readiness.
        if eggType ~= ""
            and shared.SerenityRideAPet.ActiveEggPrivateAllowed(active)
            and typeof(position) == "Vector3"
            and (
                isVolcanic
                or not isGhostEgg(active)
            )
            and not shared.SerenityRideAPet.IsNativeEggClaimed(active)
            and not shared.SerenityRideAPet.IsEggRestockBlocked(
                eggType,
                active
            )
            and (
                isVolcanic
                or not shared.SerenityRideAPet.IsActiveEggExhausted(
                    active
                )
            ) then

            local eggWeight =
                shared.SerenityRideAPet.ActiveEggKG(
                    active
                )
                or 0

            local meta =
                eggMeta[eggType]
                or {}

            local eggLuck =
                tonumber(meta.luck)
                or 0

            local allowed =
                shared.SerenityRideAPet.AutoStealFilterAllowed(
                    eggType,
                    eggWeight,
                    eggLuck
                )

            if allowed then
                return
                    true,
                    eggType,
                    eggLuck,
                    eggWeight
            end
        end
    end

    return false
end

local function renderedPickupForServerEgg(serverEgg)
    if not serverEgg then
        return nil
    end

    local rendered = Workspace:FindFirstChild("RenderedEggs")

    if not rendered then
        return nil
    end

    local bestPrompt = nil
    local bestModel = nil
    local bestDistance = nil
    local bestTypeMatch = false

    for _, prompt in ipairs(rendered:GetDescendants()) do
        if prompt:IsA("ProximityPrompt")
            and prompt.Name == "Pickup"
            and prompt.Enabled then

            local model = renderedModelForPrompt(prompt)

            if model then
                local ok, pivot = pcall(function()
                    return model:GetPivot()
                end)

                if ok then
                    local horizontalDistance =
                        vectorXZDistance(
                            pivot.Position,
                            serverEgg.position
                        )

                    local verticalDistance =
                        math.abs(
                            pivot.Position.Y
                            - serverEgg.position.Y
                        )

                    local d =
                        (
                            pivot.Position
                            - serverEgg.position
                        ).Magnitude

                    -- Type matching is preferred, while the replicated
                    -- server position now includes a vertical sanity check.
                    -- This prevents a ground egg at the same X/Z from being
                    -- selected when the real rare egg is high above the map.
                    local typeMatch =
                        tostring(model.Name) == serverEgg.eggType
                        or tostring(prompt.ObjectText or "") == serverEgg.eggType
                        or string.find(
                            string.lower(model.Name),
                            string.lower(serverEgg.eggType),
                            1,
                            true
                        ) ~= nil

                    if horizontalDistance <= 14
                        and verticalDistance <= 30 then

                        local better =
                            bestDistance == nil
                            or (
                                typeMatch
                                and not bestTypeMatch
                            )
                            or (
                                typeMatch == bestTypeMatch
                                and d < bestDistance
                            )

                        if better then
                            bestPrompt = prompt
                            bestModel = model
                            bestDistance = d
                            bestTypeMatch = typeMatch
                        end
                    end
                end
            end
        end
    end

    if bestPrompt then
        return
            bestPrompt,
            bestModel,
            bestDistance,
            bestTypeMatch
    end

    return nil
end

local function moveNearServerEggPosition(serverEgg, label)
    if not serverEgg
        or typeof(serverEgg.position) ~= "Vector3" then

        return false, "server egg position missing"
    end

    local pos = serverEgg.position
    local approachLabel =
        label or "TopServerEggApproach"

    -- New updates can put the rarest eggs far above the normal map.
    -- Always stream the ACTUAL 3D server position before moving there.
    prestreamDestination(
        pos,
        approachLabel .. ".HighEgg"
    )

    local rootPos =
        HRP.Position

    local verticalDelta =
        pos.Y - rootPos.Y

    local horizontal =
        Vector3.new(
            rootPos.X - pos.X,
            0,
            rootPos.Z - pos.Z
        )

    local direction

    if horizontal.Magnitude < 0.1 then
        direction =
            Vector3.new(1, 0, 0)
    else
        direction =
            horizontal.Unit
    end

    -- Stay close to the egg even when it is hundreds of studs above us.
    -- The target Y always follows the server egg's real Y; no ground-level cap.
    local approachDistance =
        math.clamp(
            math.abs(verticalDelta) >= 60
                and 2.25
                or 3.25,
            1.75,
            3.25
        )

    local targetPos =
        Vector3.new(
            pos.X,
            pos.Y + 0.75,
            pos.Z
        )
        + direction * approachDistance

    local targetCF =
        CFrame.lookAt(
            targetPos,
            pos
        )

    log("")
    log("=== STEAL_TOP_SERVER_EGG_APPROACH ===")
    log("EggType=" .. tostring(serverEgg.eggType))
    log("EggLuck=" .. tostring(serverEgg.eggLuck))
    log("ActiveEggName=" .. tostring(serverEgg.active and serverEgg.active.Name))
    log("ServerPosition=" .. tostring(pos))
    log("ServerVerticalDelta=" .. tostring(verticalDelta))
    log("HighEggAdaptive=true")
    log("WholeStealNoclip=false")
    log("Reason=TOP_RANKED_PROMPT_NOT_MAPPED_YET")

    return
        shared.SerenityRideAPet
            .AutoStealTravel(
                targetCF,
                shared.SerenityRideAPet
                    .AutoStealTweenSpeed(),
                approachLabel
            )
end

local function resolveTopServerEggPickup(serverEgg)
    if not serverEgg then
        return nil, "no server egg"
    end

    -- Fast path: already rendered/mapped.
    local prompt, model, matchDist, typeMatch =
        renderedPickupForServerEgg(serverEgg)

    if prompt then
        local key = activeEggGhostKey(serverEgg.active)
        if key then
            ghostEggs[key] = nil
        end

        return {
            prompt = prompt,
            model = model,
            active = serverEgg.active,
            matchDist = matchDist,
            typeMatch = typeMatch,
            eggType = serverEgg.eggType,
            rarity = serverEgg.rarity,
            eggLuck = serverEgg.eggLuck,
            eggWeight = serverEgg.eggWeight,
            eggWeightText = serverEgg.eggWeightText,
            rawWeight = serverEgg.rawWeight,
            appearChance = serverEgg.appearChance,
            distance = serverEgg.distance,
        }
    end

    -- IMPORTANT:
    -- Never skip the #1 server egg and choose a lower one.
    -- Go to the #1 ActiveEgg's authoritative server position first.
    local beforeApproach = HRP.CFrame

    local moved, moveErr =
        moveNearServerEggPosition(
            serverEgg,
            "TopServerEggApproach"
        )

    if not moved then
        return nil, "top target approach failed: " .. tostring(moveErr)
    end

    task.wait(math.max(0.08, ARRIVAL_SERVER_SETTLE))

    local deadline = os.clock() + 1.25

    repeat
        -- The ActiveEgg may have been taken while we were travelling.
        if not serverEgg.active
            or serverEgg.active.Parent == nil then

            fastWalkIntoOwnGarden(
                HRP.Position,
                beforeApproach,
                "TopEggRacedReturn"
            )

            return nil, "top server egg raced/disappeared"
        end

        prompt, model, matchDist, typeMatch =
            renderedPickupForServerEgg(serverEgg)

        if prompt then
            local key = activeEggGhostKey(serverEgg.active)
            if key then
                ghostEggs[key] = nil
            end

            return {
                prompt = prompt,
                model = model,
                active = serverEgg.active,
                matchDist = matchDist,
                typeMatch = typeMatch,
                eggType = serverEgg.eggType,
                rarity = serverEgg.rarity,
                eggLuck = serverEgg.eggLuck,
                eggWeight = serverEgg.eggWeight,
                eggWeightText = serverEgg.eggWeightText,
                rawWeight = serverEgg.rawWeight,
                appearChance = serverEgg.appearChance,
                distance = serverEgg.distance,
            }
        end

        task.wait(0.04)
    until os.clock() >= deadline

    -- Do NOT bounce home after one far/streaming miss.
    -- The caller records this as one strict failure. Attempts 2 and 3 happen
    -- from this same target area, giving RenderedEggs time to stream in.
    return
        nil,
        "Pickup prompt not rendered after far-target approach"
end

local function rankedAutoStealCandidates()
    local ranked =
        serverEggCandidates()

    if #ranked > 0 then
        return ranked
    end

    -- Rebirth fallback is intentionally ONLY an idle fallback.
    -- It never overrides a normal Auto Steal target.
    if Config.AutoRebirth == true
        and type(
            shared.SerenityRideAPet
                .FindBestActiveRebirthRequirementEgg
        ) == "function" then

        local requirementEgg =
            shared.SerenityRideAPet
                .FindBestActiveRebirthRequirementEgg()

        if requirementEgg then
            return {
                requirementEgg,
            }
        end
    end

    return ranked
end

local function pickupCandidates()
    local ranked =
        rankedAutoStealCandidates()

    if #ranked == 0 then
        return {}, "no eligible real server egg", nil
    end

    local top =
        ranked[1]

    local resolved, reason =
        resolveTopServerEggPickup(
            top
        )

    if resolved then
        return {resolved}, nil, top
    end

    -- Exactly one top-ranked resolution attempt per movement cycle.
    -- The caller records this as one of the strict 3 failures.
    return {}, reason or "top target unresolved", top
end


-- ============================================================
-- v80.2.92 — VOLCANIC EGG SPECIAL STEAL ROUTE
--
-- Automatic only when the currently selected Auto Steal target is Volcanic.
--
-- Current flow mirrors Chilli's proven acquisition shape:
--   saved/live VolcanoEntrance CFrame -> temporary-noclip outside/inside door
--   crossing -> direct movement to live ActiveEgg.Position -> native EggPickup
--   retries until Basket count increases -> reverse through the same door ->
--   existing Serenity return/claim validation.
--
-- The older 20-point helpers remain dormant below for rollback safety only.
--
-- Normal eggs keep the existing Serenity Auto Steal flow unchanged
-- unless Volcanic Mutation (In Steal) is explicitly enabled.
-- ============================================================
do
    local RECORDED_VOLCANIC_SPAWN =
        Vector3.new(-5329.445, 40910.207, -3580.874)

    -- Live-proven gate positions from the successful standalone Volcanic route.
    -- These are fallbacks only: live streamed parts remain preferred whenever
    -- Roblox has replicated them.
    local RECORDED_VOLCANO_ENTRANCE =
        Vector3.new(-4939.836, 41284.703, -3679.983)

    local RECORDED_VOLCANO_VALIDATE =
        Vector3.new(-4966.714, 41282.770, -3656.444)

    local VOLCANO_GATE_STREAM_WAIT = 0.35

    local ROUTE = {
        Vector3.new(-4968.817, 41274.875, -3650.483), -- fast 1
        Vector3.new(-5015.256, 41268.262, -3585.959), -- fast 2
        Vector3.new(-5084.901, 41250.551, -3521.911), -- fast 3
        Vector3.new(-5103.837, 41206.434, -3520.312), -- fast 4
        Vector3.new(-5115.151, 41156.199, -3527.161), -- fast 5
        Vector3.new(-5129.698, 41156.125, -3549.776), -- fast 6
        Vector3.new(-5259.950, 41137.113, -3586.386), -- fast 7
        Vector3.new(-5271.978, 41060.832, -3584.665), -- fast 8
        Vector3.new(-5241.083, 41027.492, -3647.432), -- fast 9
        Vector3.new(-5175.505, 41026.547, -3620.963), -- fast 10
        Vector3.new(-5057.869, 41038.984, -3462.167), -- fast 11
        Vector3.new(-4998.018, 41040.367, -3419.063), -- fast 12
        Vector3.new(-4948.131, 41038.496, -3426.743), -- fast 13
        Vector3.new(-4900.488, 41006.031, -3443.658), -- fast 14
        Vector3.new(-4940.540, 40955.504, -3580.424), -- fast 15
        Vector3.new(-4947.684, 40954.512, -3588.867), -- fast 16
        Vector3.new(-5065.422, 40914.902, -3673.455), -- fast 17
        Vector3.new(-5125.308, 40911.535, -3673.845), -- fast 18
        Vector3.new(-5216.876, 40897.660, -3658.387), -- fast 19
        Vector3.new(-5322.317, 40902.105, -3587.887), -- fast 20
    }

    local SKY_RISE_SPEED = 750
    local SKY_CRUISE_SPEED = 1600
    local SKY_DESCEND_SPEED = 700
    local ENTRANCE_SPEED = 170
    local VALIDATE_SPEED = 110

    -- Live-proven 3.00x interior scale. Outside approach, entrance,
    -- validation, pickup approach and door-exit speeds stay conservative.
    local ROUTE_SPEED = 1800
    local ROUTE_TIGHT_SPEED = 1200
    local ROUTE_FINAL_SPEED = 750

    local EXIT_ROUTE_SPEED = 720
    local EXIT_TIGHT_SPEED = 520
    local EXIT_GATE_SPEED = 220

    local STEAL_APPROACH_SPEED = 2000
    local RETURN_NOCLIP_SPEED = 4000
    local RETURN_SEGMENT_DISTANCE = 1500

    local VALIDATION_TIMEOUT = 4.0
    local VALIDATION_RETRIES = 2
    local EXIT_CONFIRM_TIMEOUT = 2.5
    local PICKUP_ACK_TIMEOUT = 1.15
    local PICKUP_RETRIES = 2

    local STUCK_TOLERANCE = 12

    local function isVolcanicEggType(name)
        return
            string.find(
                string.lower(tostring(name or "")),
                "volcanic",
                1,
                true
            ) ~= nil
    end

    shared.SerenityRideAPet.IsVolcanicEggType =
        isVolcanicEggType

    local function runtimeAlive()
        return
            shared.SerenityRideAPet
            and shared.SerenityRideAPet.StealActionRuntime
            and shared.SerenityRideAPet.StealActionRuntime.Busy == true
    end

    local function heartbeat()
        if shared.SerenityRideAPet.MovementRuntime then
            shared.SerenityRideAPet.MovementRuntime.Heartbeat =
                os.clock()
        end
    end

    local function refreshCharacter()
        shared.SerenityRideAPet.RefreshRuntimeCharacterRefs(0)
        return Character, HRP, Humanoid
    end

    local function zeroVelocity(root)
        if not root then
            return
        end

        pcall(function()
            root.AssemblyLinearVelocity =
                Vector3.zero

            root.AssemblyAngularVelocity =
                Vector3.zero
        end)
    end

    local function worldRefs()
        local volcano =
            Workspace:FindFirstChild("Volcano")
            or Workspace:FindFirstChild(
                "Volcano",
                true
            )

        local entrance =
            volcano
            and (
                volcano:FindFirstChild(
                    "VolcanoEntrance"
                )
                or volcano:FindFirstChild(
                    "VolcanoEntrance",
                    true
                )
            )
            or Workspace:FindFirstChild(
                "VolcanoEntrance",
                true
            )

        local validate =
            volcano
            and (
                volcano:FindFirstChild(
                    "VolcanoValidate"
                )
                or volcano:FindFirstChild(
                    "VolcanoValidate",
                    true
                )
            )
            or Workspace:FindFirstChild(
                "VolcanoValidate",
                true
            )

        local eggSpawns =
            Workspace:FindFirstChild("EggSpawns")
            or Workspace:FindFirstChild(
                "EggSpawns",
                true
            )

        local spawn =
            eggSpawns
            and (
                eggSpawns:FindFirstChild(
                    "Volcanic"
                )
                or eggSpawns:FindFirstChild(
                    "Volcanic",
                    true
                )
            )

        return
            entrance,
            validate,
            spawn
    end

    local function liveGateParts()
        local entrance, validate =
            worldRefs()

        if entrance
            and entrance:IsA("BasePart")
            and validate
            and validate:IsA("BasePart") then

            return entrance, validate
        end

        return nil, nil
    end

    local function fallbackGateRef(position)
        return {
            Position = position,
        }
    end

    local function resolveVolcanoGateRefs(
        label,
        waitSeconds
    )
        local entrance, validate =
            liveGateParts()

        if entrance and validate then
            log(
                tostring(label)
                .. ".GateSource=LIVE"
            )

            return entrance, validate, true
        end

        local midpoint =
            (
                RECORDED_VOLCANO_ENTRANCE
                + RECORDED_VOLCANO_VALIDATE
            ) * 0.5

        local queued =
            shared.SerenityRideAPet
                .QueueStreamRequest(
                    midpoint,
                    4
                )

        log("")
        log(
            "=== VOLCANIC_GATE_STREAM_RECOVERY ==="
        )
        log(
            "Label="
            .. tostring(label)
        )
        log(
            "StreamingEnabled="
            .. tostring(
                Workspace.StreamingEnabled
            )
        )
        log(
            "StreamQueued="
            .. tostring(queued)
        )
        log(
            "EntranceLiveBefore=false"
        )
        log(
            "ValidateLiveBefore=false"
        )

        local held = false

        shared.SerenityRideAPet
            .RefreshRuntimeCharacterRefs(0)

        if HRP
            and HRP.Parent
            and type(
                shared.SerenityRideAPet
                    .StartStealHoverHold
            ) == "function" then

            held =
                shared.SerenityRideAPet
                    .StartStealHoverHold(
                        HRP.CFrame,
                        tostring(label)
                            .. ".StreamWait",
                        false
                    ) == true
        end

        local deadline =
            os.clock()
            + math.max(
                0,
                tonumber(waitSeconds)
                    or VOLCANO_GATE_STREAM_WAIT
            )

        repeat
            heartbeat()

            entrance, validate =
                liveGateParts()

            if entrance and validate then
                break
            end

            task.wait(0.05)
        until
            os.clock() >= deadline
            or not runtimeAlive()

        if held
            and type(
                shared.SerenityRideAPet
                    .StopStealHoverHold
            ) == "function" then

            shared.SerenityRideAPet
                .StopStealHoverHold(
                    tostring(label)
                    .. "-stream-finished"
                )
        end

        if entrance and validate then
            log(
                tostring(label)
                .. ".GateSource=STREAMED_LIVE"
            )

            return entrance, validate, true
        end

        log(
            tostring(label)
            .. ".GateSource=RECORDED_FALLBACK"
        )
        log(
            tostring(label)
            .. ".FallbackEntrance="
            .. tostring(
                RECORDED_VOLCANO_ENTRANCE
            )
        )
        log(
            tostring(label)
            .. ".FallbackValidate="
            .. tostring(
                RECORDED_VOLCANO_VALIDATE
            )
        )

        return
            fallbackGateRef(
                RECORDED_VOLCANO_ENTRANCE
            ),
            fallbackGateRef(
                RECORDED_VOLCANO_VALIDATE
            ),
            false
    end

    local function currentVolcanicSpawn()
        local _, _, spawn =
            worldRefs()

        if spawn
            and spawn:IsA("BasePart") then

            return spawn.Position
        end

        return RECORDED_VOLCANIC_SPAWN
    end

    local function routeShift()
        return
            currentVolcanicSpawn()
            - RECORDED_VOLCANIC_SPAWN
    end

    local function routePoint(index)
        return
            ROUTE[index]
            + routeShift()
    end

    local function nearestRouteIndex(position)
        local bestIndex = 1
        local bestDistance = math.huge

        for i = 1, #ROUTE do
            local point =
                routePoint(i)

            local distance =
                (point - position).Magnitude

            if distance < bestDistance then
                bestDistance = distance
                bestIndex = i
            end
        end

        return bestIndex, bestDistance
    end

    local function tweenToPosition(
        targetPosition,
        speed,
        label
    )
        heartbeat()

        if not runtimeAlive() then
            return false, "steal action no longer busy"
        end

        local _, root =
            refreshCharacter()

        if not root
            or not root.Parent then

            return false, "HumanoidRootPart missing"
        end

        local distance =
            (root.Position - targetPosition).Magnitude

        if distance <= 1.25 then
            return true
        end

        local duration =
            math.clamp(
                distance / math.max(speed, 1),
                0.025,
                6
            )

        local horizontal =
            Vector3.new(
                targetPosition.X - root.Position.X,
                0,
                targetPosition.Z - root.Position.Z
            )

        local targetCF

        if horizontal.Magnitude > 0.20 then
            targetCF =
                CFrame.lookAt(
                    targetPosition,
                    targetPosition + horizontal.Unit
                )
        else
            targetCF =
                CFrame.new(targetPosition)
                * root.CFrame.Rotation
        end

        log(
            "Volcanic."
            .. tostring(label)
            .. ".From="
            .. tostring(root.Position)
        )

        log(
            "Volcanic."
            .. tostring(label)
            .. ".To="
            .. tostring(targetPosition)
        )

        log(
            "Volcanic."
            .. tostring(label)
            .. ".Speed="
            .. tostring(speed)
        )

        zeroVelocity(root)

        local tween =
            TweenService:Create(
                root,
                TweenInfo.new(
                    duration,
                    Enum.EasingStyle.Linear
                ),
                {
                    CFrame = targetCF,
                }
            )

        local done = false
        local state = nil

        local connection =
            tween.Completed:Connect(function(s)
                done = true
                state = s
            end)

        tween:Play()

        local deadline =
            os.clock()
            + duration
            + 0.85

        while runtimeAlive()
            and not done
            and os.clock() < deadline do

            heartbeat()
            task.wait(0.02)
        end

        pcall(function()
            connection:Disconnect()
        end)

        if not runtimeAlive() then
            pcall(function()
                tween:Cancel()
            end)

            return false, "steal action stopped"
        end

        zeroVelocity(root)

        local errorDistance =
            (root.Position - targetPosition).Magnitude

        log(
            "Volcanic."
            .. tostring(label)
            .. ".PlaybackState="
            .. tostring(state)
        )

        log(
            "Volcanic."
            .. tostring(label)
            .. ".ErrorDistance="
            .. tostring(errorDistance)
        )

        if errorDistance > STUCK_TOLERANCE then
            return
                false,
                "physical collision/stuck"
        end

        return true
    end

    local function segmentedTween(
        targetPosition,
        speed,
        label,
        segmentDistance
    )
        local _, root =
            refreshCharacter()

        if not root then
            return false, "HumanoidRootPart missing"
        end

        local startPosition =
            root.Position

        local total =
            targetPosition
            - startPosition

        local distance =
            total.Magnitude

        local maxSegment =
            tonumber(segmentDistance)
            or 780

        local count =
            math.max(
                1,
                math.ceil(
                    distance / maxSegment
                )
            )

        for i = 1, count do
            if not runtimeAlive() then
                return false, "steal action stopped"
            end

            local point =
                startPosition:Lerp(
                    targetPosition,
                    i / count
                )

            local ok, why =
                tweenToPosition(
                    point,
                    speed,
                    tostring(label)
                    .. "."
                    .. tostring(i)
                    .. "/"
                    .. tostring(count)
                )

            if not ok then
                return false, why
            end
        end

        return true
    end

    local function firstPhysicalRaycast(
        origin,
        direction
    )
        local character =
            LP.Character

        local exclude = {}

        if character then
            exclude[#exclude + 1] =
                character
        end

        for _ = 1, 16 do
            local params =
                RaycastParams.new()

            params.FilterType =
                Enum.RaycastFilterType.Exclude

            params.FilterDescendantsInstances =
                exclude

            params.IgnoreWater = false

            local hit =
                Workspace:Raycast(
                    origin,
                    direction,
                    params
                )

            if not hit then
                return nil
            end

            local instance =
                hit.Instance

            if instance
                and instance:IsA("BasePart")
                and (
                    instance.CanCollide == false
                    or string.lower(instance.Name)
                        == "rainblock"
                ) then

                exclude[#exclude + 1] =
                    instance
            else
                return hit
            end
        end

        return nil
    end

    local function segmentClear(
        fromPosition,
        toPosition
    )
        local delta =
            toPosition - fromPosition

        if delta.Magnitude <= 1 then
            return true
        end

        for _, offset in ipairs({
            Vector3.new(0, 1, 0),
            Vector3.new(0, 3, 0),
        }) do

            local hit =
                firstPhysicalRaycast(
                    fromPosition + offset,
                    delta
                )

            if hit then
                local remaining =
                    (toPosition - hit.Position).Magnitude

                if remaining > 4 then
                    return false, hit
                end
            end
        end

        return true
    end

    local function findSkyEscape(
        root,
        entrance
    )
        local cruiseY =
            math.max(
                root.Position.Y,
                entrance.Position.Y
            ) + 330

        local direct =
            Vector3.new(
                root.Position.X,
                cruiseY,
                root.Position.Z
            )

        if segmentClear(
            root.Position,
            direct
        ) then

            return root.Position, direct
        end

        local radii = {
            18,
            32,
            50,
            75,
            105,
            145,
            200,
            280,
            420,
            600,
        }

        local directions = {}

        for i = 0, 15 do
            local angle =
                math.rad(i * 22.5)

            directions[#directions + 1] =
                Vector3.new(
                    math.cos(angle),
                    0,
                    math.sin(angle)
                )
        end

        for _, radius in ipairs(radii) do
            for _, direction in ipairs(directions) do
                local side =
                    root.Position
                    + direction * radius

                if segmentClear(
                    root.Position,
                    side
                ) then

                    local up =
                        Vector3.new(
                            side.X,
                            cruiseY,
                            side.Z
                        )

                    if segmentClear(
                        side,
                        up
                    ) then

                        return side, up
                    end
                end
            end
        end

        return nil, nil
    end

    local function waitValidation()
        local deadline =
            os.clock()
            + VALIDATION_TIMEOUT

        repeat
            heartbeat()

            if LP:GetAttribute(
                "VolcanoValidated"
            ) == true then

                return true
            end

            task.wait(0.05)
        until
            os.clock() >= deadline
            or not runtimeAlive()

        return
            LP:GetAttribute(
                "VolcanoValidated"
            ) == true
    end

    -- v80.2.92 — Chilli-style Volcanic door geometry.
    -- Keep a complete CFrame (position + orientation), so the special route
    -- does not depend on VolcanoValidate or on VolcanoEntrance being streamed.
    local chilliDoorCFrame =
        CFrame.new(
            -4939.84, 41284.7, -3679.98,
            0.746841, 0.03653, -0.663999,
            0.066451, 0.989393, 0.129173,
            0.661675, -0.140595, 0.736491
        )

    local function chilliVolcanoDoorPoints()
        local volcano =
            Workspace:FindFirstChild("Volcano")

        local entrance =
            volcano
            and volcano:FindFirstChild("VolcanoEntrance")

        if entrance
            and entrance:IsA("BasePart") then

            chilliDoorCFrame = entrance.CFrame
            log("Volcanic.ChilliDoorSource=LIVE")
        else
            log("Volcanic.ChilliDoorSource=RECORDED")
        end

        local look =
            chilliDoorCFrame.LookVector

        local horizontal =
            Vector3.new(
                look.X,
                0,
                look.Z
            )

        if horizontal.Magnitude < 0.01 then
            return nil, nil
        end

        local unit = horizontal.Unit

        return
            chilliDoorCFrame.Position
                + unit * 30,
            chilliDoorCFrame.Position
                - unit * 40
    end

    -- Exact movement shape used by Chilli: Heartbeat-stepped CFrame motion
    -- with temporary character noclip and zeroed assembly velocity.
    local function chilliMoveLine(
        targetPosition,
        speed,
        tolerance,
        label
    )
        if typeof(targetPosition) ~= "Vector3" then
            return false, "target position missing"
        end

        local _, root =
            refreshCharacter()

        if not root then
            return false, "HumanoidRootPart missing"
        end

        tolerance =
            tonumber(tolerance)
            or 3

        if (
            root.Position
            - targetPosition
        ).Magnitude <= tolerance then

            return true
        end

        local stopNoclip =
            beginTemporaryCharacterNoclip(
                label or "Volcanic.ChilliMove"
            )

        local startPosition =
            root.Position

        local duration =
            math.max(
                0.05,
                (
                    targetPosition
                    - startPosition
                ).Magnitude
                / math.max(
                    tonumber(speed) or 60,
                    1
                )
            )

        local elapsed = 0
        local moved = false

        while elapsed < duration
            and runtimeAlive() do

            local dt =
                RunService.Heartbeat:Wait()

            elapsed += dt
            heartbeat()

            _, root =
                refreshCharacter()

            if not root then
                break
            end

            local point =
                startPosition:Lerp(
                    targetPosition,
                    math.min(
                        1,
                        elapsed / duration
                    )
                )

            pcall(function()
                local rotation =
                    root.CFrame.Rotation

                root.CFrame =
                    CFrame.new(point)
                    * rotation

                root.AssemblyLinearVelocity =
                    Vector3.zero

                root.AssemblyAngularVelocity =
                    Vector3.zero
            end)
        end

        pcall(stopNoclip)

        _, root =
            refreshCharacter()

        if root then
            zeroVelocity(root)

            moved =
                (
                    root.Position
                    - targetPosition
                ).Magnitude
                <= tolerance + 1
        end

        log(
            "Volcanic."
            .. tostring(label or "ChilliMove")
            .. ".Reached="
            .. tostring(moved)
        )

        return
            moved,
            moved
                and nil
                or "Chilli-style movement did not reach target"
    end

    -- Chilli's long-range FlyTo uses a high midpoint before the final point.
    -- Keep that behavior only for the approach to the Volcano door.
    local function chilliFlyToDoor(
        targetPosition,
        label
    )
        local _, root =
            refreshCharacter()

        if not root then
            return false, "HumanoidRootPart missing"
        end

        local startPosition =
            root.Position

        local horizontal =
            Vector3.new(
                targetPosition.X
                    - startPosition.X,
                0,
                targetPosition.Z
                    - startPosition.Z
            )

        if horizontal.Magnitude < 80
            and math.abs(
                targetPosition.Y
                - startPosition.Y
            ) < 30 then

            return
                chilliMoveLine(
                    targetPosition,
                    1000,
                    4,
                    label
                )
        end

        local cruiseY =
            math.max(
                startPosition.Y,
                targetPosition.Y
            ) + 250

        local midpoint =
            Vector3.new(
                (
                    startPosition.X
                    + targetPosition.X
                ) / 2,
                cruiseY,
                (
                    startPosition.Z
                    + targetPosition.Z
                ) / 2
            )

        local ok, why =
            chilliMoveLine(
                midpoint,
                1000,
                3,
                tostring(label)
                    .. ".Cruise"
            )

        if not ok then
            return false, why
        end

        return
            chilliMoveLine(
                targetPosition,
                1000,
                4,
                label
            )
    end

    local function enterVolcanoCollisionOn()
        -- Match Chilli: only enter through the door when the game's own
        -- InVolcano/VolcanoValidated state is not already satisfied.
        if LP:GetAttribute("InVolcano") == true
            and LP:GetAttribute("VolcanoValidated") == true then

            log("Volcanic.ChilliEntry.AlreadyInside=true")
            return true
        end

        local outside,
            inside =
            chilliVolcanoDoorPoints()

        if not outside or not inside then
            return false, "Volcano door CFrame invalid"
        end

        local ok, why =
            chilliFlyToDoor(
                outside,
                "ChilliEntry.Outside"
            )

        if not ok then
            return false, why
        end

        ok, why =
            chilliMoveLine(
                inside,
                40,
                4,
                "ChilliEntry.CrossDoor"
            )

        if not ok then
            return false, why
        end

        log(
            "Volcanic.ChilliEntry.InVolcano="
            .. tostring(
                LP:GetAttribute("InVolcano")
            )
        )
        log(
            "Volcanic.ChilliEntry.VolcanoValidated="
            .. tostring(
                LP:GetAttribute("VolcanoValidated")
            )
        )

        -- Chilli does not require a VolcanoValidate instance or wait for a
        -- validation attribute before continuing toward the live ActiveEgg.
        return true
    end

    local function routeSpeed(point)
        local distance =
            (
                point
                - currentVolcanicSpawn()
            ).Magnitude

        if distance <= 50 then
            return ROUTE_FINAL_SPEED
        elseif distance <= 130 then
            return ROUTE_TIGHT_SPEED
        end

        return ROUTE_SPEED
    end

    local function followInteriorToEgg(
        serverEgg
    )
        local active =
            serverEgg
            and serverEgg.active

        if not active
            or active.Parent == nil then

            return false,
                "Volcanic ActiveEgg disappeared"
        end

        local targetPosition =
            active:GetAttribute("Position")

        if typeof(targetPosition) ~= "Vector3" then
            targetPosition =
                serverEgg.position
        end

        if typeof(targetPosition) ~= "Vector3" then
            targetPosition =
                currentVolcanicSpawn()
        end

        targetPosition =
            targetPosition
            + Vector3.new(0, 3, 0)

        log(
            "Volcanic.ChilliTargetPosition="
            .. tostring(targetPosition)
        )

        local ok, why =
            chilliMoveLine(
                targetPosition,
                250,
                6,
                "ChilliInterior.DirectToEgg"
            )

        if not ok then
            return false, why
        end

        local _, root =
            refreshCharacter()

        if root
            and (
                root.Position
                - targetPosition
            ).Magnitude <= 8 then

            return true
        end

        return false,
            "Chilli-style direct approach ended outside egg range"
    end

    local function findVolcanicPrompt(
        serverEgg
    )
        local prompt, model, matchDistance =
            renderedPickupForServerEgg(
                serverEgg
            )

        if prompt then
            return
                prompt,
                model,
                matchDistance
        end

        local rendered =
            Workspace:FindFirstChild(
                "RenderedEggs"
            )

        if not rendered then
            return nil
        end

        local serverPosition =
            serverEgg
            and serverEgg.position
            or currentVolcanicSpawn()

        local bestPrompt = nil
        local bestDistance = nil

        for _, object in ipairs(
            rendered:GetDescendants()
        ) do
            if object:IsA("ProximityPrompt")
                and object.Name == "Pickup" then

                local position =
                    promptPosition(object)

                if position then
                    local distance =
                        (
                            position
                            - serverPosition
                        ).Magnitude

                    local volcanicNamed =
                        isVolcanicEggType(
                            object.Parent
                            and object.Parent.Name
                        )

                    local top =
                        object

                    while top.Parent
                        and top.Parent ~= rendered do

                        top = top.Parent
                    end

                    volcanicNamed =
                        volcanicNamed
                        or isVolcanicEggType(
                            top and top.Name
                        )

                    if volcanicNamed
                        or distance <= 40 then

                        if not bestDistance
                            or distance < bestDistance then

                            bestPrompt =
                                object

                            bestDistance =
                                distance
                        end
                    end
                end
            end
        end

        return
            bestPrompt,
            nil,
            bestDistance
    end

    local function waitPickupAck(
        active,
        timeout
    )
        local deadline =
            os.clock()
            + timeout

        repeat
            heartbeat()

            if not active
                or active.Parent == nil then

                return true
            end

            task.wait(0.025)
        until
            os.clock() >= deadline
            or not runtimeAlive()

        return
            active
            and active.Parent == nil
    end

    local function stealVolcanicAtPrompt(
        serverEgg
    )
        local active =
            serverEgg
            and serverEgg.active

        if not active
            or active.Parent == nil then

            return false,
                "Volcanic ActiveEgg disappeared"
        end

        local basket =
            LP:FindFirstChild("Basket")

        if not basket then
            return false, "Basket missing"
        end

        local beforeCount =
            #basket:GetChildren()

        local eggPickup =
            GameRemotes
            and GameRemotes:FindFirstChild(
                "EggPickup"
            )

        if not eggPickup
            or not eggPickup:IsA("RemoteEvent") then

            return false, "EggPickup remote missing"
        end

        log("Volcanic.PickupMethod=CHILLI_NATIVE_EGGPICKUP")
        log(
            "Volcanic.Pickup.BasketBefore="
            .. tostring(beforeCount)
        )

        local firstDeadline =
            os.clock() + 1.2

        local finalDeadline =
            firstDeadline + 1.5

        local nextFireAt = 0

        while #basket:GetChildren()
            == beforeCount
            and runtimeAlive() do

            local now =
                os.clock()

            if now >= nextFireAt
                and active.Parent ~= nil then

                nextFireAt =
                    now + 0.10

                pcall(function()
                    eggPickup:FireServer(
                        active.Name
                    )
                end)
            end

            if now < firstDeadline then
                RunService.Heartbeat:Wait()
                heartbeat()
                continue
            end

            -- Match Chilli: if ActiveEgg vanished first, allow replication
            -- extra time for the Basket child to appear before declaring fail.
            if active.Parent == nil
                and now < finalDeadline then

                RunService.Heartbeat:Wait()
                heartbeat()
                continue
            end

            break
        end

        local afterCount =
            #basket:GetChildren()

        local success =
            afterCount > beforeCount

        log(
            "Volcanic.Pickup.BasketAfter="
            .. tostring(afterCount)
        )
        log(
            "Volcanic.Pickup.Acknowledged="
            .. tostring(success)
        )

        return
            success,
            success
                and "Basket count increased"
                or "Basket count did not increase"
    end

    local function exitRouteSpeed(point)
        -- The standalone bidirectional FAST_ROUTE test was proven at the
        -- same 3.00x speed profile in both directions. Door crossing below
        -- still uses EXIT_GATE_SPEED and is intentionally unchanged.
        return routeSpeed(point)
    end

    local function reverseInteriorToEntrance()
        local _, root =
            refreshCharacter()

        if not root then
            return false, "HumanoidRootPart missing"
        end

        local index, nearestDistance =
            nearestRouteIndex(
                root.Position
            )

        log(
            "Volcanic.Exit.StartIndex="
            .. tostring(index)
        )

        log(
            "Volcanic.Exit.StartDistance="
            .. tostring(nearestDistance)
        )

        if index < 2 then
            index = #ROUTE
        end

        for i = index, 1, -1 do
            if not runtimeAlive() then
                return false, "steal action stopped"
            end

            local point =
                routePoint(i)

            local ok, why =
                tweenToPosition(
                    point,
                    exitRouteSpeed(point),
                    "Exit.Route."
                    .. tostring(i)
                )

            if not ok then
                return false, why
            end
        end

        return true
    end

    local function crossVolcanoDoorOutward()
        local entrance,
            validate,
            liveGateRefs =
            resolveVolcanoGateRefs(
                "Volcanic.ExitGate",
                0.75
            )

        local inward =
            Vector3.new(
                validate.Position.X
                    - entrance.Position.X,
                0,
                validate.Position.Z
                    - entrance.Position.Z
            )

        if inward.Magnitude < 1 then
            return false, "bad exit direction"
        end

        inward = inward.Unit

        local outward =
            -inward

        log(
            "Volcanic.Exit.UsingLiveGates="
            .. tostring(liveGateRefs == true)
        )

        local stages = {
            {
                validate.Position
                    + outward * 4
                    + Vector3.new(0, 2.5, 0),
                "Exit.CrossValidate",
            },
            {
                entrance.Position
                    + outward * 5
                    + Vector3.new(0, 3, 0),
                "Exit.CrossEntrance",
            },
            {
                entrance.Position
                    + outward * 38
                    + Vector3.new(0, 4, 0),
                "Exit.Outside",
            },
            {
                entrance.Position
                    + outward * 85
                    + Vector3.new(0, 5, 0),
                "Exit.ClearBoundary",
            },
        }

        for _, stage in ipairs(stages) do
            local ok, why =
                tweenToPosition(
                    stage[1],
                    EXIT_GATE_SPEED,
                    stage[2]
                )

            if not ok then
                return false, why
            end

            task.wait(0.10)
        end

        local deadline =
            os.clock()
            + EXIT_CONFIRM_TIMEOUT

        repeat
            heartbeat()

            if LP:GetAttribute(
                "InVolcano"
            ) == false then

                log(
                    "Volcanic.Exit.Confirmed=true"
                )

                log(
                    "Volcanic.Exit.LeftVia="
                    .. tostring(
                        LP:GetAttribute(
                            "VolcanoLeftVia"
                        )
                    )
                )

                return true
            end

            task.wait(0.05)
        until
            os.clock() >= deadline
            or not runtimeAlive()

        -- The proven route is already physically outside at this point.
        log(
            "Volcanic.Exit.AttributeLate="
            .. tostring(
                LP:GetAttribute(
                    "InVolcano"
                )
            )
        )

        return true
    end

    local function exitVolcanoCollisionOn()
        local outside,
            inside =
            chilliVolcanoDoorPoints()

        if not outside or not inside then
            return false, "Volcano door CFrame invalid"
        end

        local ok, why =
            chilliMoveLine(
                inside,
                250,
                4,
                "ChilliExit.InsideDoor"
            )

        if not ok then
            return false, why
        end

        ok, why =
            chilliMoveLine(
                outside,
                40,
                4,
                "ChilliExit.CrossDoor"
            )

        if not ok then
            return false, why
        end

        log(
            "Volcanic.ChilliExit.InVolcano="
            .. tostring(
                LP:GetAttribute("InVolcano")
            )
        )

        return true
    end

    local function fastNoclipReturn(
        targetCF
    )
        -- v80.2.92: post-exit home return keeps Serenity's existing temporary
        -- noclip return. The dedicated Volcanic acquisition itself now uses
        -- the scoped Chilli-style noclip helpers above.
        local stopReturnNoclip =
            beginTemporaryCharacterNoclip(
                "Volcanic.Return"
            )

        local ok, why =
            segmentedTween(
                targetCF.Position,
                RETURN_NOCLIP_SPEED,
                "Return.FastNoclip",
                RETURN_SEGMENT_DISTANCE
            )

        if not ok then
            pcall(stopReturnNoclip)
            return false, why
        end

        local _, root =
            refreshCharacter()

        local errorDistance =
            root
            and (
                root.Position
                - targetCF.Position
            ).Magnitude
            or math.huge

        log(
            "Volcanic.Return.BaseError="
            .. tostring(errorDistance)
        )

        task.wait(0.45)
        pcall(stopReturnNoclip)

        if errorDistance <= 15 then
            return true, nil
        end

        return
            false,
            "base return error "
            .. tostring(errorDistance)
    end

    -- ============================================================
    -- v80.2.53 — VOLCANIC MUTATION DEFAULT ON + LONG-RANGE TRANSFER
    --
    -- Based on the live-validated V18 lifecycle:
    --   carried Basket egg -> native DROP IN VOLCANO callback ONCE
    --   -> wait VolcanoDipResult / VolcanoUntil / VolcanoDipped
    --   -> DO NOT manually collect/re-pick
    --   -> wait until VolcanoUntil finishes / egg returns
    --   -> ALWAYS return home for normal garden claim.
    --
    -- This is intentionally separate from the Volcanic Egg special steal
    -- route. The toggle can apply the mutation attempt to EVERY stolen egg.
    -- ============================================================

    shared.SerenityRideAPet.VolcanoMutationData = nil

    pcall(function()
        shared.SerenityRideAPet.VolcanoMutationData =
            require(
                ReplicatedStorage
                    :WaitForChild("GameData")
                    :WaitForChild("Volcano")
            )
    end)

    shared.SerenityRideAPet.CaptureVolcanoMutationBasketIds =
        function()
            local ids = {}
            local basket =
                LP:FindFirstChild("Basket")

            if basket then
                for _, entry in ipairs(
                    basket:GetChildren()
                ) do
                    ids[entry.Name] = true
                end
            end

            return ids
        end

    shared.SerenityRideAPet.VolcanoMutationEntryState = function(entry)
        if not entry then
            return "<nil>"
        end

        local now =
            Workspace:GetServerTimeNow()

        local untilAt =
            tonumber(
                entry:GetAttribute(
                    "VolcanoUntil"
                )
            )

        return
            "id="
            .. tostring(entry.Name)
            .. " egg="
            .. tostring(
                entry:GetAttribute("Egg")
            )
            .. " weight="
            .. tostring(
                entry:GetAttribute("Weight")
            )
            .. " mutation="
            .. tostring(
                entry:GetAttribute(
                    "Mutation"
                )
            )
            .. " dipped="
            .. tostring(
                entry:GetAttribute(
                    "VolcanoDipped"
                )
            )
            .. " volcanoRemaining="
            .. tostring(
                untilAt
                and string.format(
                    "%.2f",
                    untilAt - now
                )
                or "nil"
            )
    end

    shared.SerenityRideAPet.FindMutationBasketEntry = function(
        serverEgg,
        beforeIds,
        timeout
    )
        local basket =
            LP:FindFirstChild("Basket")

        if not basket then
            return nil
        end

        local wantedEgg =
            tostring(
                serverEgg
                and serverEgg.eggType
                or ""
            )

        local wantedWeight =
            tonumber(
                serverEgg
                and serverEgg.eggWeight
            )

        local function choose()
            local fallback = nil
            local onlyNew = nil
            local newCount = 0

            for _, entry in ipairs(
                basket:GetChildren()
            ) do
                local isNew =
                    type(beforeIds) ~= "table"
                    or beforeIds[
                        entry.Name
                    ] ~= true

                if isNew then
                    newCount += 1
                    onlyNew = entry
                end

                local entryEgg =
                    tostring(
                        entry:GetAttribute("Egg")
                        or ""
                    )

                local entryWeight =
                    tonumber(
                        entry:GetAttribute(
                            "Weight"
                        )
                    )

                -- A newly-created Basket child can replicate one frame before
                -- its Egg/Weight attributes. Do not lose the whole mutation
                -- cycle just because those attributes arrived slightly late.
                local nameMatches =
                    wantedEgg == ""
                    or entryEgg == ""
                    or entryEgg == wantedEgg

                local weightMatches =
                    wantedWeight == nil
                    or entryWeight == nil
                    or math.abs(
                        wantedWeight
                        - entryWeight
                    ) <= 0.03

                if nameMatches
                    and weightMatches then

                    if isNew then
                        return entry
                    end

                    fallback =
                        fallback or entry
                end
            end

            -- Strong fallback: Auto Steal just completed and exactly one new
            -- Basket ID appeared. That ID is the stolen egg even if its
            -- attributes are still replicating.
            if type(beforeIds) == "table"
                and newCount == 1 then

                return onlyNew
            end

            return fallback
        end

        local deadline =
            os.clock()
            + (tonumber(timeout) or 4.5)

        repeat
            local entry = choose()

            if entry then
                return entry
            end

            heartbeat()
            task.wait(0.03)
        until os.clock() >= deadline

        return choose()
    end

    shared.SerenityRideAPet.VolcanoNetRemote = function(name)
        local packages =
            ReplicatedStorage:FindFirstChild(
                "packages"
            )

        local net =
            packages
            and packages:FindFirstChild(
                "Net"
            )

        if not net then
            return nil
        end

        local direct =
            net:FindFirstChild(
                "RE/" .. tostring(name)
            )

        if direct
            and direct:IsA(
                "RemoteEvent"
            ) then

            return direct
        end

        for _, descendant in ipairs(
            net:GetDescendants()
        ) do
            if descendant:IsA(
                "RemoteEvent"
            )
                and descendant.Name
                    == "RE/"
                        .. tostring(name) then

                return descendant
            end
        end

        return nil
    end

    shared.SerenityRideAPet.VolcanoDropButton = function()
        local playerGui =
            LP:FindFirstChildOfClass(
                "PlayerGui"
            )

        local main =
            playerGui
            and playerGui:FindFirstChild(
                "Main"
            )

        local actions =
            main
            and main:FindFirstChild(
                "ActionsHolder"
            )

        local button =
            actions
            and actions:FindFirstChild(
                "DropEggVolcanoButton"
            )

        return
            button
            and button:IsA("GuiButton")
            and button
            or nil
    end

    shared.SerenityRideAPet.InvokeNativeVolcanoMutationDrop = function(
        button
    )
        local getConnections =
            envfn("getconnections")

        if button
            and getConnections then

            local ok, connections =
                pcall(
                    getConnections,
                    button.Activated
                )

            if ok
                and type(connections)
                    == "table" then

                for _, connection in ipairs(
                    connections
                ) do
                    local callback =
                        connection.Function

                    if type(callback)
                        == "function" then

                        local callOk,
                            callErr =
                                pcall(
                                    callback
                                )

                        if callOk then
                            return
                                true,
                                "native_button_callback"
                        end

                        log(
                            "VolcanicMutation.NativeCallbackError="
                            .. tostring(callErr)
                        )
                    elseif type(
                        connection.Fire
                    ) == "function" then

                        local callOk =
                            pcall(function()
                                connection:Fire()
                            end)

                        if callOk then
                            return
                                true,
                                "native_button_connection"
                        end
                    end
                end
            end
        end

        local remote =
            shared.SerenityRideAPet.VolcanoNetRemote(
                "VolcanoDip"
            )

        if not remote then
            return
                false,
                "VolcanoDip remote missing"
        end

        local ok, err =
            pcall(function()
                remote:FireServer()
            end)

        return
            ok,
            ok
                and "exact_VolcanoDip_fallback"
                or tostring(err)
    end

    shared.SerenityRideAPet.RecordedVolcanoTopPosition =
        shared.SerenityRideAPet.RecordedVolcanoTopPosition
        or Vector3.new(
            -5102.8427734375,
            41405.62890625,
            -3489.114013671875
        )

    shared.SerenityRideAPet.ResolveVolcanoTop =
        function(waitSeconds)
            local function currentTop()
                local volcano =
                    Workspace:FindFirstChild(
                        "Volcano"
                    )

                local direct =
                    volcano
                    and volcano:FindFirstChild(
                        "VolcanoTop"
                    )

                if direct
                    and direct:IsA(
                        "BasePart"
                    ) then

                    return direct
                end

                local okTags,
                    tagged =
                    pcall(function()
                        return game
                            :GetService(
                                "CollectionService"
                            )
                            :GetTagged(
                                "VolcanoTop"
                            )
                    end)

                if okTags
                    and type(tagged) == "table" then

                    for _, candidate in ipairs(
                        tagged
                    ) do
                        if candidate
                            and candidate:IsA(
                                "BasePart"
                            )
                            and candidate:IsDescendantOf(
                                Workspace
                            ) then

                            return candidate
                        end
                    end
                end

                return nil
            end

            local top =
                currentTop()

            if top then
                return top
            end

            local recorded =
                shared.SerenityRideAPet
                    .RecordedVolcanoTopPosition

            log(
                "VolcanicMutation.VolcanoTopStreamRequest=true"
            )

            shared.SerenityRideAPet
                .QueueStreamRequest(
                    recorded,
                    math.max(
                        3,
                        tonumber(waitSeconds)
                            or 3
                    )
                )

            local deadline =
                os.clock()
                + (
                    tonumber(waitSeconds)
                    or 3.5
                )

            repeat
                top =
                    currentTop()

                if top then
                    log(
                        "VolcanicMutation.VolcanoTopResolvedAfterStream=true"
                    )

                    return top
                end

                heartbeat()
                task.wait(0.05)
            until os.clock()
                >= deadline

            return currentTop()
        end

    shared.SerenityRideAPet.MoveCarriedEggToVolcanoHover = function()
        local top =
            shared.SerenityRideAPet
                .ResolveVolcanoTop(
                    3.5
                )

        if not top
            or not top:IsA(
                "BasePart"
            ) then

            return
                false,
                "VolcanoTop missing after stream recovery"
        end

        local _, root =
            refreshCharacter()

        if not root then
            return
                false,
                "HumanoidRootPart missing"
        end

        local hoverPosition =
            top.Position
            + Vector3.new(
                0,
                70,
                0
            )

        local travelSpeed =
            shared.SerenityRideAPet
                .AutoStealTweenSpeed()

        log(
            "VolcanicMutation.TransferMode="
            .. (
                Config.InstantSteal == true
                and "INSTANT_TELEPORT"
                or "TWEEN"
            )
        )

        log(
            "VolcanicMutation.TransferDistance="
            .. tostring(
                (
                    root.Position
                    - hoverPosition
                ).Magnitude
            )
        )

        shared.SerenityRideAPet
            .QueueStreamRequest(
                hoverPosition,
                3
            )

        for attempt = 1, 5 do
            _, root =
                refreshCharacter()

            if not root then
                return
                    false,
                    "root missing during Volcano transfer"
            end

            local moved,
                moveWhy =
                shared.SerenityRideAPet
                    .AutoStealTravel(
                        CFrame.new(
                            hoverPosition
                        ),
                        travelSpeed,
                        "VolcanicMutation.Transfer"
                    )

            if not moved then
                return false,
                    "Volcano transfer failed: "
                    .. tostring(
                        moveWhy
                    )
            end

            shared.SerenityRideAPet.StartStealHoverHold(
                CFrame.new(hoverPosition),
                "VolcanicMutation.Hover",
                true
            )

            log(
                "VolcanicMutation.TransferAttempt="
                .. tostring(
                    attempt
                )
            )

            local readyDeadline =
                os.clock() + 2.5

            repeat
                local button =
                    shared.SerenityRideAPet
                        .VolcanoDropButton()

                local over =
                    false

                pcall(function()
                    over =
                        type(
                            shared.SerenityRideAPet
                                .VolcanoMutationData
                        ) == "table"
                        and type(
                            shared.SerenityRideAPet
                                .VolcanoMutationData
                                .IsOver
                        ) == "function"
                        and shared.SerenityRideAPet
                            .VolcanoMutationData
                            .IsOver(
                                top,
                                root.Position
                            ) == true
                end)

                if over
                    and button
                    and button.Visible
                        == true then

                    local settleStart =
                        os.clock()

                    local settleSeconds =
                        Config.InstantSteal == true
                        and 0.90
                        or 0.20

                    repeat
                        if not root.Parent then
                            break
                        end

                        root.AssemblyLinearVelocity =
                            Vector3.zero

                        root.AssemblyAngularVelocity =
                            Vector3.zero

                        -- Only instant mode needs the old repeated CFrame
                        -- replication hold. Tween mode is already physically
                        -- resident at the hover point.
                        if Config.InstantSteal
                            == true then

                            root.CFrame =
                                CFrame.new(
                                    hoverPosition
                                )
                        end

                        heartbeat()
                        task.wait(0.03)
                    until os.clock()
                        - settleStart
                        >= settleSeconds

                    button =
                        shared.SerenityRideAPet
                            .VolcanoDropButton()

                    over = false

                    pcall(function()
                        over =
                            type(
                                shared.SerenityRideAPet
                                    .VolcanoMutationData
                            ) == "table"
                            and type(
                                shared.SerenityRideAPet
                                    .VolcanoMutationData
                                    .IsOver
                            ) == "function"
                            and shared.SerenityRideAPet
                                .VolcanoMutationData
                                .IsOver(
                                    top,
                                    root.Position
                                ) == true
                    end)

                    if over
                        and button
                        and button.Visible
                            == true then

                        log(
                            "VolcanicMutation.ServerSettleSeconds="
                            .. tostring(
                                os.clock()
                                - settleStart
                            )
                        )

                        log(
                            "VolcanicMutation.TransferReady=true"
                        )

                        log(
                            "VolcanicMutation.TransferArrivalError="
                            .. tostring(
                                (
                                    root.Position
                                    - hoverPosition
                                ).Magnitude
                            )
                        )

                        return true,
                            button
                    end
                end

                heartbeat()
                task.wait(0.03)
            until os.clock()
                >= readyDeadline

            shared.SerenityRideAPet
                .QueueStreamRequest(
                    hoverPosition,
                    2
                )

            task.wait(0.10)
        end

        return false,
            "native Volcano drop state did not become ready after 5 transfer attempts"
    end

    shared.SerenityRideAPet.RunVolcanicMutationInSteal =
        function(
            serverEgg,
            beforeIds,
            baseCF
        )
            baseCF =
                baseCF
                or ownGardenReferenceCFrame()

            local entry =
                shared.SerenityRideAPet.FindMutationBasketEntry(
                    serverEgg,
                    beforeIds,
                    8
                )

            if not entry then
                log(
                    "VolcanicMutation.Fail=BasketEntryMissing"
                )

                return
                    false,
                    false,
                    "carried Basket egg not found"
            end

            local previousMutation =
                entry:GetAttribute(
                    "Mutation"
                )

            local resultRemote =
                shared.SerenityRideAPet.VolcanoNetRemote(
                    "VolcanoDipResult"
                )

            local cancelRemote =
                shared.SerenityRideAPet.VolcanoNetRemote(
                    "VolcanoDipCancelled"
                )

            local resultPayload =
                nil

            local cancelPayload =
                nil

            local resultConnection =
                resultRemote
                and resultRemote
                    .OnClientEvent
                    :Connect(
                        function(payload)
                            resultPayload =
                                payload

                            log(
                                "VolcanicMutation.ResultReceived=true"
                            )
                        end
                    )

            local cancelConnection =
                cancelRemote
                and cancelRemote
                    .OnClientEvent
                    :Connect(
                        function(payload)
                            cancelPayload =
                                payload

                            log(
                                "VolcanicMutation.CancelReceived=true"
                            )
                        end
                    )

            local accepted =
                false

            local acceptReason =
                nil

            for attempt = 1, 8 do
                -- Late acknowledgement from an earlier attempt wins
                -- immediately. Never fire another dip over an already
                -- accepted lifecycle.
                local untilAt =
                    tonumber(
                        entry:GetAttribute(
                            "VolcanoUntil"
                        )
                    )

                if resultPayload
                    ~= nil then

                    accepted = true
                    acceptReason =
                        "VolcanoDipResult late"

                    break
                end

                if untilAt
                    and Workspace
                        :GetServerTimeNow()
                        < untilAt then

                    accepted = true
                    acceptReason =
                        "VolcanoUntil late"

                    break
                end

                if entry:GetAttribute(
                    "VolcanoDipped"
                ) == true then

                    accepted = true
                    acceptReason =
                        "VolcanoDipped late"

                    break
                end

                log(
                    "VolcanicMutation.Attempt="
                    .. tostring(attempt)
                    .. "/8"
                )

                local moved,
                    buttonOrWhy =
                        shared.SerenityRideAPet.MoveCarriedEggToVolcanoHover()

                if not moved then
                    log(
                        "VolcanicMutation.RetryReason="
                        .. tostring(
                            buttonOrWhy
                        )
                    )

                    heartbeat()
                    task.wait(0.20)
                    continue
                end

                cancelPayload =
                    nil

                local callOk,
                    callMethod =
                        shared.SerenityRideAPet.InvokeNativeVolcanoMutationDrop(
                            buttonOrWhy
                        )

                log(
                    "VolcanicMutation.DropCall="
                    .. tostring(callOk)
                )

                log(
                    "VolcanicMutation.DropMethod="
                    .. tostring(
                        callMethod
                    )
                )

                if not callOk then
                    task.wait(0.15)
                    continue
                end

                local deadline =
                    os.clock() + 1.25

                repeat
                    untilAt =
                        tonumber(
                            entry:GetAttribute(
                                "VolcanoUntil"
                            )
                        )

                    if resultPayload
                        ~= nil then

                        accepted = true
                        acceptReason =
                            "VolcanoDipResult"

                        break
                    end

                    if untilAt
                        and Workspace
                            :GetServerTimeNow()
                            < untilAt then

                        accepted = true
                        acceptReason =
                            "VolcanoUntil"

                        break
                    end

                    if entry:GetAttribute(
                        "VolcanoDipped"
                    ) == true then

                        accepted = true
                        acceptReason =
                            "VolcanoDipped"

                        break
                    end

                    if cancelPayload
                        ~= nil then

                        break
                    end

                    heartbeat()
                    task.wait(0.03)
                until os.clock()
                    >= deadline

                if accepted then
                    break
                end

                log(
                    "VolcanicMutation.Retry=true"
                )

                task.wait(0.20)
            end

            if not accepted then
                if resultConnection then
                    resultConnection:Disconnect()
                end

                if cancelConnection then
                    cancelConnection:Disconnect()
                end

                log(
                    "VolcanicMutation.Fail=NotAcceptedAfter8Attempts"
                )

                -- IMPORTANT:
                -- Do NOT send the egg home if mutation never started.
                -- Leave it away from the garden instead of silently claiming
                -- an unmutated egg.
                return
                    false,
                    false,
                    "Volcano mutation not accepted after 8 attempts; home blocked"
            end

            log(
                "VolcanicMutation.Accepted=true"
            )

            log(
                "VolcanicMutation.AcceptReason="
                .. tostring(
                    acceptReason
                )
            )

            -- Wait for the real Volcano lifecycle to finish.
            local completed =
                false

            local completionReason =
                nil

            local completionDeadline =
                os.clock() + 45

            repeat
                local now =
                    Workspace:GetServerTimeNow()

                local untilAt =
                    tonumber(
                        entry:GetAttribute(
                            "VolcanoUntil"
                        )
                    )

                local dipped =
                    entry:GetAttribute(
                        "VolcanoDipped"
                    ) == true

                if untilAt
                    and now
                        >= untilAt + 0.10
                    and (
                        dipped
                        or resultPayload
                            ~= nil
                    ) then

                    completed = true
                    completionReason =
                        "VolcanoUntil expired"

                    break
                end

                local arriveAt =
                    type(
                        resultPayload
                    ) == "table"
                    and tonumber(
                        resultPayload
                            .ArriveAt
                    )
                    or nil

                if not untilAt
                    and arriveAt
                    and now
                        >= arriveAt + 0.10 then

                    completed = true
                    completionReason =
                        "Result.ArriveAt passed"

                    break
                end

                heartbeat()
                task.wait(0.05)
            until os.clock()
                >= completionDeadline

            if resultConnection then
                resultConnection:Disconnect()
            end

            if cancelConnection then
                cancelConnection:Disconnect()
            end

            if not completed then
                log(
                    "VolcanicMutation.Fail=CompletionUnconfirmed"
                )

                -- Never leave while a possibly-active Volcano lifecycle is
                -- unresolved.
                return
                    false,
                    true,
                    "Volcano lifecycle completion not confirmed; home blocked"
            end

            log(
                "VolcanicMutation.CompletionConfirmed=true"
            )

            log(
                "VolcanicMutation.CompletionReason="
                .. tostring(
                    completionReason
                )
            )

            local currentMutation =
                entry:GetAttribute(
                    "Mutation"
                )

            local expectedMutation =
                tostring(
                    type(
                        shared.SerenityRideAPet.VolcanoMutationData
                    ) == "table"
                    and shared.SerenityRideAPet.VolcanoMutationData.MutationName
                    or "Magma"
                )

            local payloadSuccess =
                type(resultPayload) == "table"
                and resultPayload.Success == true

            local payloadMutation =
                type(resultPayload) == "table"
                and resultPayload.Mutation
                or nil

            -- If a native result payload exists, it is authoritative.
            -- Weather mutations such as Shocked must NOT be misreported as a
            -- successful Volcano/Magma roll.
            local succeeded

            if type(resultPayload) == "table" then
                succeeded =
                    payloadSuccess
            else
                succeeded =
                    currentMutation == expectedMutation
                    and currentMutation ~= previousMutation
            end

            log(
                "VolcanicMutation.ResultSuccess="
                .. tostring(payloadSuccess)
            )

            log(
                "VolcanicMutation.ResultMutation="
                .. tostring(payloadMutation)
            )

            log(
                "VolcanicMutation.CurrentMutation="
                .. tostring(currentMutation)
            )

            log(
                "VolcanicMutation.Success="
                .. tostring(succeeded)
            )

            -- Home movement follows the user's Auto Steal mode:
            -- Tween by default, direct teleport only when Instant Steal is ON.
            local _, currentRoot =
                refreshCharacter()

            local homeOk,
                homeWhy =
                    fastWalkIntoOwnGarden(
                        currentRoot
                            and currentRoot.Position
                            or baseCF.Position,
                        baseCF,
                        "VolcanicMutation.Home"
                    )

            log(
                "VolcanicMutation.Home="
                .. tostring(homeOk)
            )

            if not homeOk then
                return
                    false,
                    true,
                    "home teleport failed: "
                    .. tostring(
                        homeWhy
                    )
            end

            return
                true,
                true,
                succeeded
                    and (
                        "mutation success: "
                        .. tostring(
                            payloadMutation
                            or expectedMutation
                        )
                    )
                    or "mutation roll finished without Magma"
        end

    local function bestEffortExitAndReturn(
        baseCF
    )
        -- If the character is inside the Volcano, leave through the dedicated
        -- Chilli-style door route first. Outside, use Serenity's existing fast
        -- temporary-noclip home return.
        if LP:GetAttribute(
            "InVolcano"
        ) == true
            or LP:GetAttribute(
                "VolcanoValidated"
            ) == true then

            pcall(function()
                exitVolcanoCollisionOn()
            end)
        end

        pcall(function()
            fastNoclipReturn(
                baseCF
            )
        end)
    end

    shared.SerenityRideAPet.PickupVolcanicSpecial =
        function(serverEgg)
            if type(serverEgg) ~= "table"
                or not isVolcanicEggType(
                    serverEgg.eggType
                ) then

                return
                    false,
                    "not a Volcanic target"
            end

            local active =
                serverEgg.active

            if not active
                or active.Parent == nil then

                return
                    false,
                    "Volcanic ActiveEgg disappeared"
            end

            local dropReady,
                dropRemaining =
                shared.SerenityRideAPet
                    .ActiveEggDropReady(
                        active
                    )

            if not dropReady then
                return
                    false,
                    "Volcanic drop not ready; remaining="
                    .. tostring(dropRemaining)
            end

            local eggType =
                tostring(
                    serverEgg.eggType
                )

            local baseCF =
                ownGardenReferenceCFrame()

            local eggToolCountBefore =
                #eggTools()

            local useVolcanicMutation =
                shared.SerenityRideAPet.ActiveStealSetting(
                    "VolcanicMutationInSteal",
                    false
                ) == true

            local mutationBasketBefore =
                useVolcanicMutation
                and (
                    type(
                        shared.SerenityRideAPet
                            .CaptureVolcanoMutationBasketIds
                    ) == "function"
                    and shared.SerenityRideAPet
                        .CaptureVolcanoMutationBasketIds()
                    or {}
                )
                or nil

            local matchingBefore = 0

            for _, tool in ipairs(
                eggTools()
            ) do
                local base =
                    baseEggName(
                        tool.Name
                    )

                if base == eggType
                    or string.find(
                        tool.Name,
                        eggType,
                        1,
                        true
                    ) then

                    matchingBefore += 1
                end
            end

            log("")
            log("=== AUTO_STEAL_VOLCANIC_SPECIAL ===")
            log(
                "Volcanic.ActiveEggName="
                .. tostring(active.Name)
            )
            log(
                "Volcanic.EggType="
                .. eggType
            )
            log(
                "Volcanic.EntryNoclip=true"
            )
            log(
                "Volcanic.ExitNoclip=true"
            )
            log(
                "Volcanic.PickupNoclip=true"
            )
            log(
                "Volcanic.ReturnNoclip=true"
            )

            local entered, enterWhy =
                enterVolcanoCollisionOn()

            if not entered then
                -- Entry can fail while the player is still completely outside
                -- the Volcano (for example under a roof / blocked sky escape).
                -- Do NOT force another long return tween in that state; release
                -- the steal lane so manual movement works during retry backoff.
                if LP:GetAttribute("InVolcano") == true
                    or LP:GetAttribute("VolcanoValidated") == true then

                    bestEffortExitAndReturn(
                        baseCF
                    )
                end

                return false, enterWhy
            end

            if active.Parent == nil then
                bestEffortExitAndReturn(
                    baseCF
                )

                return
                    false,
                    "Volcanic target disappeared during entry"
            end

            local routed, routeWhy =
                followInteriorToEgg(
                    serverEgg
                )

            if not routed then
                bestEffortExitAndReturn(
                    baseCF
                )

                return false, routeWhy
            end

            if active.Parent == nil then
                bestEffortExitAndReturn(
                    baseCF
                )

                return
                    false,
                    "Volcanic target disappeared before pickup"
            end

            local stolen, stealWhy =
                stealVolcanicAtPrompt(
                    serverEgg
                )

            local exited, exitWhy =
                exitVolcanoCollisionOn()

            if not exited then
                bestEffortExitAndReturn(
                    baseCF
                )

                return
                    false,
                    "Volcanic exit failed: "
                    .. tostring(exitWhy)
            end

            local returned, returnWhy

            if stolen
                and useVolcanicMutation then

                local mutationAccepted

                returned, mutationAccepted, returnWhy =
                    shared.SerenityRideAPet
                        .RunVolcanicMutationInSteal(
                            serverEgg,
                            mutationBasketBefore,
                            baseCF
                        )

                log(
                    "Volcanic.MutationAccepted="
                    .. tostring(
                        mutationAccepted
                    )
                )
            else
                returned, returnWhy =
                    fastNoclipReturn(
                        baseCF
                    )
            end

            if not returned then
                return
                    false,
                    "Volcanic base return failed: "
                    .. tostring(returnWhy)
            end

            if not stolen then
                return
                    false,
                    "Volcanic pickup failed: "
                    .. tostring(stealWhy)
            end

            log(
                "Volcanic.WaitingForGardenClaimSeconds="
                .. tostring(
                    POST_GARDEN_CLAIM_WAIT
                )
            )

            local deadline =
                os.clock()
                + POST_GARDEN_CLAIM_WAIT

            local eggToolCountAfter =
                eggToolCountBefore

            local matchingAfter =
                matchingBefore

            repeat
                local all =
                    eggTools()

                eggToolCountAfter =
                    #all

                matchingAfter = 0

                for _, tool in ipairs(all) do
                    local base =
                        baseEggName(
                            tool.Name
                        )

                    if base == eggType
                        or string.find(
                            tool.Name,
                            eggType,
                            1,
                            true
                        ) then

                        matchingAfter += 1
                    end
                end

                if eggToolCountAfter
                        > eggToolCountBefore
                    or matchingAfter
                        > matchingBefore then

                    break
                end

                heartbeat()
                task.wait(0.05)
            until os.clock() >= deadline

            local confirmed =
                active.Parent == nil
                and (
                    eggToolCountAfter
                        > eggToolCountBefore
                    or matchingAfter
                        > matchingBefore
                )

            log(
                "Volcanic.ActiveEggRemoved="
                .. tostring(
                    active.Parent == nil
                )
            )

            log(
                "Volcanic.GardenClaimConfirmed="
                .. tostring(confirmed)
            )

            if not confirmed then
                return
                    false,
                    "Volcanic steal registered but new carried egg was not confirmed"
            end

            shared.SerenityRideAPet
                .RecordStealRestockSuccess(
                    eggType,
                    active
                )

            shared.SerenityRideAPet
                .RefreshRuntimeCharacterRefs(0)

            local equipped =
                Character
                and Character
                    :FindFirstChildOfClass(
                        "Tool"
                    )

            if equipped
                and (
                    hasTag(
                        equipped,
                        "Egg"
                    )
                    or baseEggName(
                        equipped.Name
                    ) == eggType
                    or string.find(
                        equipped.Name,
                        eggType,
                        1,
                        true
                    ) ~= nil
                ) then

                pcall(function()
                    Humanoid:UnequipTools()
                end)

                task.wait(0.03)
            end

            task.spawn(function()
                shared.SerenityRideAPet
                    .SendStealWebhook(
                        serverEgg,
                        false
                    )
            end)

            log(
                "Volcanic.SpecialStealComplete=true"
            )

            return true, eggType
        end
end


-- ============================================================
-- CONFIRMED STEAL DISCORD WEBHOOK
-- ============================================================

shared.SerenityRideAPet.GetHttpRequest = function()
    local globalEnv =
        (type(getgenv) == "function" and getgenv())
        or _G

    for _, name in ipairs({
        "request",
        "http_request",
        "httprequest",
    }) do
        local fn =
            rawget(globalEnv, name)
            or rawget(_G, name)

        if type(fn) == "function" then
            return fn
        end
    end

    local synTable =
        rawget(globalEnv, "syn")
        or rawget(_G, "syn")

    if type(synTable) == "table"
        and type(synTable.request) == "function" then

        return synTable.request
    end

    return nil
end

shared.SerenityRideAPet.IsDiscordWebhookURL = function(url)
    url =
        string.lower(
            tostring(url or "")
        )

    return
        string.match(
            url,
            "^https://discord%.com/api/webhooks/"
        ) ~= nil
        or string.match(
            url,
            "^https://discordapp%.com/api/webhooks/"
        ) ~= nil
end

shared.SerenityRideAPet.WebhookEggAllowed = function(
    eggType,
    kg,
    rarity
)
    if Config.WebhookEnabled ~= true then
        return false, "disabled"
    end

    local selected =
        selectionAsArray(
            Config.WebhookEggs
        )

    if #selected > 0
        and not selectionHas(
            Config.WebhookEggs,
            eggType
        ) then

        return false, "egg filtered"
    end

    local selectedRarities =
        selectionAsArray(
            Config.WebhookRarities
        )

    if #selectedRarities > 0
        and not selectionHas(
            Config.WebhookRarities,
            tostring(rarity or "")
        ) then

        return false, "rarity filtered"
    end

    local minimumKG =
        shared.SerenityRideAPet.ParseCompactNumber(
            Config.WebhookMinKG
        )
        or 0

    if (tonumber(kg) or 0) < minimumKG then
        return false, "below webhook minimum K.G"
    end

    return true
end

shared.SerenityRideAPet.FormatWebhookLuck = function(value)
    local n =
        tonumber(value)

    if not n then
        return tostring(value or "?")
    end

    for _, row in ipairs({
        {1e15, "Q"},
        {1e12, "T"},
        {1e9, "B"},
        {1e6, "M"},
        {1e3, "K"},
    }) do
        if n >= row[1] then
            local amount =
                n / row[1]

            if math.abs(
                amount - math.floor(amount)
            ) < 0.001 then

                return
                    tostring(math.floor(amount))
                    .. row[2]
            end

            return
                string.format("%.2f", amount)
                :gsub("0+$", "")
                :gsub("%.$", "")
                .. row[2]
        end
    end

    return tostring(n)
end

shared.SerenityRideAPet.WebhookRarityColor = function(rarity)
    local name =
        string.lower(
            tostring(rarity or "")
        )

    local colors = {
        common = 9807270,
        rare = 3447003,
        epic = 10181046,
        legendary = 15844367,
        mythic = 15158332,
        divine = 16766720,
        ethereal = 5793266,
    }

    return
        colors[name]
        or 5793266
end

shared.SerenityRideAPet.SendStealWebhook = function(
    target,
    isTest
)
    if type(target) ~= "table" then
        return false, "missing target"
    end

    local url =
        tostring(
            Config.WebhookURL
            or ""
        )

    if not shared.SerenityRideAPet.IsDiscordWebhookURL(
        url
    ) then

        return false, "invalid Discord webhook URL"
    end

    local kg =
        tonumber(
            target.eggWeight
        )
        or 0

    if isTest ~= true then
        local allowed, why =
            shared.SerenityRideAPet.WebhookEggAllowed(
                tostring(
                    target.eggType
                    or "?"
                ),
                kg,
                tostring(
                    target.rarity
                    or "Unknown"
                )
            )

        if not allowed then
            return false, why
        end
    end

    local requestFn =
        shared.SerenityRideAPet.GetHttpRequest()

    if type(requestFn) ~= "function" then
        return false, "HTTP request unavailable"
    end

    local kgText =
        tostring(
            target.eggWeightText
            or (
                shared.SerenityRideAPet.CleanEggKGText(
                    nil,
                    kg
                )
                .. " KG"
            )
        )

    if not string.find(
        string.lower(kgText),
        "kg",
        1,
        true
    ) then
        kgText =
            kgText
            .. " KG"
    end

    local payload = {
        username = "Serenity Hub",
        embeds = {
            {
                color =
                    shared.SerenityRideAPet.WebhookRarityColor(
                        target.rarity
                    ),
                title =
                    isTest == true
                    and "Webhook Test"
                    or "Egg Stolen",
                description =
                    isTest == true
                    and "Serenity Hub webhook is connected."
                    or "A matching egg was successfully claimed.",
                fields = {
                    {
                        name = "Egg",
                        value = tostring(
                            target.eggType
                            or "Test Egg"
                        ),
                        inline = true,
                    },
                    {
                        name = "K.G",
                        value = kgText,
                        inline = true,
                    },
                    {
                        name = "Egg Luck",
                        value =
                            shared.SerenityRideAPet.FormatWebhookLuck(
                                target.eggLuck
                            ),
                        inline = true,
                    },
                    {
                        name = "Rarity",
                        value = tostring(
                            target.rarity
                            or "Unknown"
                        ),
                        inline = true,
                    },
                },
                footer = {
                    text =
                        isTest == true
                        and "Serenity Hub • Ride A Pet"
                        or "https://discord.gg/ccsvkN7Pp • Serenity Hub • Ride A Pet",
                },
                timestamp =
                    os.date(
                        "!%Y-%m-%dT%H:%M:%SZ"
                    ),
            },
        },
    }

    local ok, response =
        pcall(
            requestFn,
            {
                Url = url,
                Method = "POST",
                Headers = {
                    ["Content-Type"] =
                        "application/json",
                },
                Body =
                    HttpService:JSONEncode(
                        payload
                    ),
            }
        )

    if not ok then
        return false, tostring(response)
    end

    if type(response) == "table" then
        local status =
            tonumber(
                response.StatusCode
                or response.Status
            )

        if status
            and (
                status < 200
                or status >= 300
            ) then

            return
                false,
                "HTTP "
                .. tostring(status)
        end
    end

    return true
end

shared.SerenityRideAPet.SendMutationWebhook = function(data)
    if Config.MutationWebhookEnabled ~= true then
        return false, "disabled"
    end

    if type(data) ~= "table" then
        return false, "missing mutation data"
    end

    local url =
        tostring(
            Config.WebhookURL
            or ""
        )

    if not shared.SerenityRideAPet.IsDiscordWebhookURL(
        url
    ) then

        return false, "invalid Discord webhook URL"
    end

    local requestFn =
        shared.SerenityRideAPet.GetHttpRequest()

    if type(requestFn) ~= "function" then
        return false, "HTTP request unavailable"
    end

    local weatherText =
        tostring(
            data.weather
            or "Unknown"
        )

    if weatherText == "" then
        weatherText = "Unknown"
    end

    local payload = {
        username = "Serenity Hub",
        embeds = {
            {
                color = 10181046,
                title = "Pet Mutated",
                description =
                    "A placed pet gained a new mutation.",
                fields = {
                    {
                        name = "Pet",
                        value = tostring(
                            data.petName
                            or "Unknown"
                        ),
                        inline = true,
                    },
                    {
                        name = "Mutation",
                        value = tostring(
                            data.mutation
                            or "Weather Mutation"
                        ),
                        inline = true,
                    },
                    {
                        name = "Weather",
                        value = weatherText,
                        inline = true,
                    },
                },
                footer = {
                    text =
                        "https://discord.gg/ccsvkN7Pp • Serenity Hub • Ride A Pet",
                },
                timestamp =
                    os.date(
                        "!%Y-%m-%dT%H:%M:%SZ"
                    ),
            },
        },
    }

    local ok, response =
        pcall(
            requestFn,
            {
                Url = url,
                Method = "POST",
                Headers = {
                    ["Content-Type"] =
                        "application/json",
                },
                Body =
                    HttpService:JSONEncode(
                        payload
                    ),
            }
        )

    if not ok then
        return false, tostring(response)
    end

    if type(response) == "table" then
        local status =
            tonumber(
                response.StatusCode
                or response.Status
            )

        if status
            and (
                status < 200
                or status >= 300
            ) then

            return
                false,
                "HTTP "
                .. tostring(status)
        end
    end

    return true
end

shared.SerenityRideAPet.SendWebhookTest = function()
    return
        shared.SerenityRideAPet.SendStealWebhook(
            {
                eggType = "Test Egg",
                eggWeight = 117933,
                eggWeightText = "117,933 KG",
                eggLuck = 1000000000,
                rarity = "Test",
            },
            true
        )
end

local function pickupRarestAvailable(lockedCandidate)
    -- v80.2.86:
    -- The movement lane already selected the top target before Steal starts.
    -- Keep that exact target for the whole transaction so UI/filter changes
    -- cannot make the script switch eggs halfway through an active steal.
    local selectedTop =
        type(lockedCandidate) == "table"
        and lockedCandidate.active
        and lockedCandidate.active.Parent ~= nil
        and lockedCandidate
        or nil

    if not selectedTop then
        local rankedNow =
            rankedAutoStealCandidates()

        selectedTop =
            rankedNow[1]
    end

    -- Volcanic Egg keeps its proven special steal route.
    -- Optional Volcanic Mutation (In Steal) is applied AFTER any successful
    -- steal and ALWAYS converges back home, whether the mutation roll succeeds
    -- or fails.

    if selectedTop
        and selectedTop.dropReady ~= true then

        return false,
            "top target waiting for DropEndsAt"
    end

    if selectedTop
        and type(
            shared.SerenityRideAPet
                .IsVolcanicEggType
        ) == "function"
        and shared.SerenityRideAPet
            .IsVolcanicEggType(
                selectedTop.eggType
            ) then

        -- Volcanic is the current rarest/top-ranked target.
        -- Never skip it and steal a lower egg just because the previous
        -- special-route attempt failed. Wait a short bounded cooldown, then
        -- retry this same top target while it still exists.
        if not shared.SerenityRideAPet
            .VolcanicRetryReady(
                selectedTop.active
            ) then

            return false,
                "Volcanic top target retry cooldown"
        end

        local ok, result =
            shared.SerenityRideAPet
                .PickupVolcanicSpecial(
                    selectedTop
                )

        if not ok then
            shared.SerenityRideAPet
                .RecordStealRestockFailure(
                    selectedTop.eggType,
                    result
                        or "Volcanic special steal failed",
                    selectedTop.active
                        and selectedTop.active.Name
                )

            return
                false,
                result
                    or "Volcanic special steal failed"
        end

        shared.SerenityRideAPet
            .MarkKGHuntGoalSatisfied(
                selectedTop
            )

        return true, result
    end

    local list = {}
    local resolveReason = nil
    local unresolvedTop = selectedTop

    if selectedTop then
        local resolved, reason =
            resolveTopServerEggPickup(
                selectedTop
            )

        if resolved then
            list[1] = resolved
        else
            resolveReason =
                reason
                or "top target unresolved"
        end
    else
        list,
            resolveReason,
            unresolvedTop =
            pickupCandidates()
    end

    if #list == 0 then
        if unresolvedTop then
            log("")
            log("=== STEAL_TOP_TARGET_UNRESOLVED ===")
            log("EggType=" .. tostring(unresolvedTop.eggType))
            log("EggLuck=" .. tostring(unresolvedTop.eggLuck))
            log("Reason=" .. tostring(resolveReason))

            -- v80.2.63:
            -- A server ActiveEgg whose rendered prompt did not appear is a
            -- mapping/streaming miss, not proof that the whole egg TYPE is
            -- exhausted. Ghost only this exact ActiveEgg for a few seconds.
            -- This avoids wasting three ~1.25s retries and avoids incorrectly
            -- stock-locking rare eggs such as Blackhole.
            markGhostEgg(
                unresolvedTop,
                resolveReason
                    or "top target unresolved"
            )

            log(
                "ResolutionPolicy=GHOST_EXACT_ACTIVE_ID"
            )
        end

        return false, resolveReason or "no eligible server egg"
    end

    local target = list[1]

    log("")
    log("=== AUTO_STEAL_TARGET ===")
    log("EggType=" .. target.eggType)
    log("Rarity=" .. tostring(target.rarity))
    log("EggLuck=" .. tostring(target.eggLuck))
    log("AppearChance=" .. tostring(target.appearChance))
    log(
        "SelectionPolicy="
        .. tostring(
            shared.SerenityRideAPet.ActiveStealSetting(
                "StealPriority",
                "Highest to Lowest"
            )
        )
    )
    log("ActiveEggName=" .. target.active.Name)
    log("ActiveMatchXZDistance=" .. tostring(target.matchDist))
    log("DistanceBeforeMovement=" .. tostring(target.distance))
    log("Prompt=" .. target.prompt:GetFullName())

    local active = target.active
    local eggType = target.eggType
    local newTool = nil

    local useVolcanicMutation =
        shared.SerenityRideAPet.ActiveStealSetting(
            "VolcanicMutationInSteal",
            false
        ) == true

    local mutationBasketBefore =
        useVolcanicMutation
        and (
            type(
                shared.SerenityRideAPet
                    .CaptureVolcanoMutationBasketIds
            ) == "function"
            and shared.SerenityRideAPet
                .CaptureVolcanoMutationBasketIds()
            or {}
        )
        or nil

    local eggToolCountBefore = #eggTools()
    local matchingCountBefore = 0

    for _, tool in ipairs(eggTools()) do
        local base = baseEggName(tool.Name)
        if base == eggType or string.find(tool.Name, eggType, 1, true) then
            matchingCountBefore += 1
        end
    end

    log("CarriedEggCountBeforeSteal=" .. tostring(eggToolCountBefore))
    log("MatchingTypeCountBeforeSteal=" .. tostring(matchingCountBefore))

    local watchers = {}

    local function watch(root)
        if not root then return end

        watchers[#watchers+1] = root.ChildAdded:Connect(function(x)
            if not x:IsA("Tool") then return end

            task.defer(function()
                for _ = 1, 40 do
                    if x.Parent == nil then return end

                    if hasTag(x, "Egg") then
                        local base = baseEggName(x.Name)
                        if base == eggType or string.find(x.Name, eggType, 1, true) then
                            newTool = x
                            return
                        end
                    end

                    task.wait(0.02)
                end
            end)
        end)
    end

    for _, root in ipairs(roots()) do watch(root) end

    local ok,
        pickupWhy,
        countableStockFailure =
        triggerPrompt(
        target.prompt,
        function()
            -- For stolen remote eggs, ActiveEgg removal means the steal
            -- registered.
            return active.Parent == nil
        end,
        0.75,
        "FreshPickup",
        useVolcanicMutation,
        active and active.Name
    )

    for _, c in ipairs(watchers) do
        c:Disconnect()
    end

    if not ok then
        local stealRuntime =
            shared.SerenityRideAPet.StealActionRuntime

        if stealRuntime
            and stealRuntime.AbortRequested == true then

            emergencyReturnHomeAfterStuckSteal(
                "StuckStealPromptReturn"
            )

            return
                false,
                tostring(
                    stealRuntime.AbortReason
                    or pickupWhy
                    or "stuck steal aborted"
                )
        end

        local locked =
            false

        if countableStockFailure == true then
            locked =
                shared.SerenityRideAPet
                    .RecordStealRestockFailure(
                        eggType,
                        tostring(
                            pickupWhy
                            or "pickup was not acknowledged by server"
                        ),
                        active and active.Name
                    )
        else
            log("")
            log("=== STOCK_GUARD_SKIP ===")
            log("EggType=" .. tostring(eggType))
            log(
                "Reason="
                .. tostring(
                    pickupWhy
                    or "non-stock pickup failure"
                )
            )
            log("Counted=false")
        end

        if locked then
            returnHomeAfterStrictStealFailure(
                "PickupStrict3Return"
            )
        end

        return
            false,
            tostring(
                pickupWhy
                or "pickup trigger failed"
            )
    end

    if useVolcanicMutation then
        local mutationHomeOk,
            mutationAccepted,
            mutationReason =
                shared.SerenityRideAPet
                    .RunVolcanicMutationInSteal(
                        target,
                        mutationBasketBefore,
                        ownGardenReferenceCFrame()
                    )

        log(
            "VolcanicMutationInSteal.HomeOk="
            .. tostring(
                mutationHomeOk
            )
        )

        log(
            "VolcanicMutationInSteal.Accepted="
            .. tostring(
                mutationAccepted
            )
        )

        log(
            "VolcanicMutationInSteal.Reason="
            .. tostring(
                mutationReason
            )
        )

        if not mutationHomeOk then
            return
                false,
                mutationReason
                    or "Volcanic mutation home return failed"
        end
    end

    log("ActiveEggRemovedAfterSteal=" .. tostring(active.Parent == nil))
    log("NowInsideOwnGarden=true")
    log("WaitingForGardenClaimSeconds=" .. tostring(POST_GARDEN_CLAIM_WAIT))

    local claimDeadline = os.clock() + POST_GARDEN_CLAIM_WAIT
    local matchingCountAfter = matchingCountBefore
    local eggToolCountAfter = eggToolCountBefore

    repeat
        local all = eggTools()
        eggToolCountAfter = #all
        matchingCountAfter = 0

        for _, tool in ipairs(all) do
            local base = baseEggName(tool.Name)
            if base == eggType or string.find(tool.Name, eggType, 1, true) then
                matchingCountAfter += 1
            end
        end

        if newTool
            or eggToolCountAfter > eggToolCountBefore
            or matchingCountAfter > matchingCountBefore then
            break
        end

        task.wait(0.05)
    until os.clock() >= claimDeadline

    local confirmed =
        active.Parent == nil
        and (
            newTool ~= nil
            or eggToolCountAfter > eggToolCountBefore
            or matchingCountAfter > matchingCountBefore
        )

    log("ActiveEggRemoved=" .. tostring(active.Parent == nil))
    log("NewEggToolObserved=" .. tostring(newTool ~= nil))
    log("CarriedEggCountAfterSteal=" .. tostring(eggToolCountAfter))
    log("MatchingTypeCountAfterSteal=" .. tostring(matchingCountAfter))
    log("CollectedEggs=" .. collectedString())
    log("GardenClaimConfirmed=" .. tostring(confirmed))
    log("PickupValidated=" .. tostring(confirmed))

    if confirmed
        and shared.SerenityRideAPet
            .UnresolvedBasketRuntime then

        shared.SerenityRideAPet
            .UnresolvedBasketRuntime
            .LastConfirmedClaimAt =
            os.clock()
    end

    if not confirmed then
        log("")
        log("=== STOCK_GUARD_SKIP ===")
        log("EggType=" .. tostring(eggType))
        log("Reason=new carried egg was not confirmed")
        log("Counted=false")
        log("Classification=DELIVERY_OR_REPLICATION_NOT_STOCK")

        return
            false,
            "steal registered but new carried egg was not confirmed"
    end

    shared.SerenityRideAPet.RecordStealRestockSuccess(
        eggType,
        active
    )

    shared.SerenityRideAPet
        .MarkKGHuntGoalSatisfied(
            target
        )

    -- After a confirmed steal, leave the character with the Egg unequipped.
    -- Because all direct workers are paused during Steal, this cannot race
    -- against Place/Feed equipping another Tool.
    shared.SerenityRideAPet.RefreshRuntimeCharacterRefs(0)

    local equippedAfterSteal =
        Character
        and Character:FindFirstChildOfClass("Tool")

    if equippedAfterSteal
        and (
            hasTag(equippedAfterSteal, "Egg")
            or baseEggName(equippedAfterSteal.Name) == eggType
            or string.find(
                equippedAfterSteal.Name,
                eggType,
                1,
                true
            ) ~= nil
        ) then

        pcall(function()
            Humanoid:UnequipTools()
        end)

        task.wait(0.03)
    end

    -- Network delivery never blocks Steal/Sell movement.
    task.spawn(function()
        shared.SerenityRideAPet.SendStealWebhook(
            target,
            false
        )
    end)

    return true, eggType
end


-- ============================================================
-- LOW-LAG FEATURE HELPERS — NATIVE SHOP / HATCH LUCK / DISMOUNT
-- ============================================================

local lastHatchLuckAction = 0

-- Only actions that EQUIP a Tool need this lock.
-- It does not block Hatch, Hatch Luck, Shop Auto-Buy, or Steal movement.
local equipmentActionBusy = false
local equipmentActionOwner = nil

shared.SerenityRideAPet.EquipmentLockRuntime =
    shared.SerenityRideAPet.EquipmentLockRuntime
    or {
        Since = 0,
    }

local function tryAcquireEquipment(owner)
    if equipmentActionBusy then
        return false
    end

    equipmentActionBusy = true
    equipmentActionOwner = owner

    shared.SerenityRideAPet
        .EquipmentLockRuntime
        .Since =
            os.clock()

    return true
end

local function releaseEquipment(owner)
    if equipmentActionOwner == owner then
        equipmentActionBusy = false
        equipmentActionOwner = nil

        shared.SerenityRideAPet
            .EquipmentLockRuntime
            .Since =
                0
    end
end

shared.SerenityRideAPet.RecoverStaleEquipmentLock = function(maxAge)
    if not equipmentActionBusy then
        return false
    end

    local since =
        tonumber(
            shared.SerenityRideAPet
                .EquipmentLockRuntime
                .Since
        )
        or 0

    local age =
        os.clock() - since

    if since > 0
        and age < (tonumber(maxAge) or 20) then

        return false
    end

    log("")
    log("=== EQUIPMENT_LOCK_RECOVERED ===")
    log("OldOwner=" .. tostring(equipmentActionOwner))

    equipmentActionBusy = false
    equipmentActionOwner = nil

    shared.SerenityRideAPet
        .EquipmentLockRuntime
        .Since =
            0

    return true
end

-- ============================================================
-- AUTO STEAL ACTION PRIORITY
--
-- During a REAL steal transaction, direct API workers pause until Steal has
-- completely finished moving, picking up, returning, and validating.
-- ============================================================

shared.SerenityRideAPet.StealActionRuntime =
    shared.SerenityRideAPet.StealActionRuntime
    or {
        Busy = false,
        Since = 0,
        NoclipCleanup = nil,
        SettingsSnapshot = nil,
        AbortRequested = false,
        AbortReason = nil,
        EmergencyReturn = false,
        Serial = 0,
    }

-- Legacy cleanup slot retained for compatibility. v80.2.90 uses scoped
-- temporary noclip only for stationary hover-holds and return-home travel.
shared.SerenityRideAPet.StealActionRuntime.NoclipCleanup =
    shared.SerenityRideAPet.StealActionRuntime.NoclipCleanup

shared.SerenityRideAPet.StealStuckRuntime =
    shared.SerenityRideAPet.StealStuckRuntime
    or {
        TargetId = nil,
        LastPosition = nil,
        LastProgressAt = 0,
        LastFallbackAt = 0,
    }

shared.SerenityRideAPet.ResetStealStuckRuntime = function()
    local runtime =
        shared.SerenityRideAPet.StealStuckRuntime

    runtime.TargetId = nil
    runtime.LastPosition = nil
    runtime.LastProgressAt = 0

    return true
end

shared.SerenityRideAPet.IsStealActionBusy = function()
    local runtime =
        shared.SerenityRideAPet.StealActionRuntime

    return runtime
        and runtime.Busy == true
end

shared.SerenityRideAPet.UnresolvedBasketRuntime =
    shared.SerenityRideAPet.UnresolvedBasketRuntime
    or {
        LastLogAt = 0,
        LastCount = 0,
        LastWaitLogAt = 0,
        Recovering = false,
        LastRecoverAt = 0,
        LastConfirmedClaimAt = 0,
    }

shared.SerenityRideAPet.GetUnresolvedBasketEggs = function()
    local basket =
        LP:FindFirstChild("Basket")

    if not basket then
        return {}
    end

    local result = {}

    for _, entry in ipairs(
        basket:GetChildren()
    ) do
        result[#result + 1] = entry
    end

    table.sort(
        result,
        function(a, b)
            return tostring(a.Name)
                < tostring(b.Name)
        end
    )

    return result
end

shared.SerenityRideAPet.HasUnresolvedBasketEgg = function()
    local entries =
        shared.SerenityRideAPet.GetUnresolvedBasketEggs()

    return #entries > 0, entries
end

shared.SerenityRideAPet.UnresolvedBasketRuntime.Recovering =
    shared.SerenityRideAPet.UnresolvedBasketRuntime.Recovering
    == true

shared.SerenityRideAPet.UnresolvedBasketRuntime.LastRecoverAt =
    tonumber(
        shared.SerenityRideAPet
            .UnresolvedBasketRuntime
            .LastRecoverAt
    )
    or 0

shared.SerenityRideAPet.TryRecoverUnresolvedBasketEgg =
    function()
        local runtime =
            shared.SerenityRideAPet
                .UnresolvedBasketRuntime

        if runtime.Recovering == true then
            return false,
                "basket recovery already running"
        end

        local now =
            os.clock()

        -- A just-completed steal can leave its Basket entry replicated for a
        -- fraction of a second after the new Egg Tool has already arrived.
        -- Give normal garden claim/removal time to finish before recovery.
        if now
            - (
                tonumber(
                    runtime.LastConfirmedClaimAt
                )
                or 0
            ) < 1.75 then

            return false,
                "basket claim grace"
        end

        if now
            - (
                tonumber(
                    runtime.LastRecoverAt
                )
                or 0
            ) < 1 then

            return false,
                "basket recovery cooldown"
        end

        local entries =
            shared.SerenityRideAPet
                .GetUnresolvedBasketEggs()

        if #entries ~= 1 then
            return false,
                #entries == 0
                and "basket already clear"
                or "multiple basket entries; recovery not attempted"
        end

        local entry =
            entries[1]

        runtime.Recovering = true
        runtime.LastRecoverAt =
            now

        local stealRuntime =
            shared.SerenityRideAPet
                .StealActionRuntime

        if stealRuntime then
            stealRuntime.Busy = true
            stealRuntime.Since =
                os.clock()
        end

        if type(
            shared.SerenityRideAPet
                .PauseNativeAutoBuyForSteal
        ) == "function" then

            shared.SerenityRideAPet
                .PauseNativeAutoBuyForSteal()
        end

        local function releaseRecoveryLane()
            runtime.Recovering = false

            if stealRuntime then
                stealRuntime.Busy = false
                stealRuntime.Since = 0
            end

            if type(
                shared.SerenityRideAPet
                    .ResumeNativeAutoBuyAfterSteal
            ) == "function" then

                shared.SerenityRideAPet
                    .ResumeNativeAutoBuyAfterSteal()
            end
        end

        local function waitForBasketClear(seconds)
            local deadline =
                os.clock()
                + (
                    tonumber(seconds)
                    or 3
                )

            repeat
                if not entry.Parent
                    or #shared.SerenityRideAPet
                        .GetUnresolvedBasketEggs()
                        == 0 then

                    return true
                end

                if shared.SerenityRideAPet
                    .MovementRuntime then

                    shared.SerenityRideAPet
                        .MovementRuntime
                        .Heartbeat =
                        os.clock()
                end

                task.wait(0.05)
            until os.clock()
                >= deadline

            return
                not entry.Parent
                or #shared.SerenityRideAPet
                    .GetUnresolvedBasketEggs()
                    == 0
        end

        local dipped =
            entry:GetAttribute(
                "VolcanoDipped"
            ) == true

        local untilAt =
            tonumber(
                entry:GetAttribute(
                    "VolcanoUntil"
                )
            )

        -- Critical v80.2.69 fix:
        -- If a finished steal already came home with VolcanoDipped=true and
        -- VolcanoUntil is gone, DO NOT launch a second 45-second Volcano
        -- lifecycle. This is the exact stall seen in the v80.2.68 log.
        if dipped
            and untilAt == nil then

            local baseCF =
                ownGardenReferenceCFrame()

            shared.SerenityRideAPet.RefreshRuntimeCharacterRefs(0)

            local root =
                HRP

            if baseCF and root then
                pcall(function()
                    fastWalkIntoOwnGarden(
                        root.Position,
                        baseCF,
                        "BasketRecovery.AlreadyDippedHome"
                    )
                end)
            end

            local cleared =
                waitForBasketClear(
                    3.25
                )

            releaseRecoveryLane()

            if cleared then
                return true,
                    "already-dipped basket cleared"
            end

            return false,
                "already-dipped basket still awaiting garden claim"
        end

        if shared.SerenityRideAPet.ActiveStealSetting(
            "VolcanicMutationInSteal",
            false
        ) ~= true then

            releaseRecoveryLane()

            return false,
                "Volcanic Mutation in Steal disabled"
        end

        if type(
            shared.SerenityRideAPet
                .RunVolcanicMutationInSteal
        ) ~= "function" then

            releaseRecoveryLane()

            return false,
                "mutation recovery API unavailable"
        end

        local fakeServerEgg = {
            eggType =
                tostring(
                    entry:GetAttribute(
                        "Egg"
                    )
                    or ""
                ),
            eggWeight =
                tonumber(
                    entry:GetAttribute(
                        "Weight"
                    )
                ),
        }

        local baseCF =
            ownGardenReferenceCFrame()

        local callOk,
            homeOk,
            accepted,
            reason =
            xpcall(
                function()
                    return
                        shared.SerenityRideAPet
                            .RunVolcanicMutationInSteal(
                                fakeServerEgg,
                                {},
                                baseCF
                            )
                end,
                debug.traceback
            )

        if not callOk then
            releaseRecoveryLane()

            return false,
                tostring(homeOk)
        end

        if homeOk
            and waitForBasketClear(4) then

            releaseRecoveryLane()

            return true,
                "basket cleared"
        end

        releaseRecoveryLane()

        return false,
            reason
            or "basket recovery not confirmed"
    end

shared.SerenityRideAPet.LogUnresolvedBasketLock = function(entries)
    entries =
        type(entries) == "table"
        and entries
        or shared.SerenityRideAPet.GetUnresolvedBasketEggs()

    local runtime =
        shared.SerenityRideAPet.UnresolvedBasketRuntime

    local now = os.clock()
    local count = #entries

    if count == 0 then
        runtime.LastCount = 0
        return
    end

    if runtime.LastCount == count
        and now - (tonumber(runtime.LastLogAt) or 0) < 1 then

        return
    end

    runtime.LastCount = count
    runtime.LastLogAt = now

    log("")
    log("=== AUTO_STEAL_BASKET_LOCK ===")
    log("BasketCount=" .. tostring(count))
    log("Action=BLOCK_NEW_STEAL_UNTIL_BASKET_CLEARS")

    for i, entry in ipairs(entries) do
        log(
            "BasketEntry#"
            .. tostring(i)
            .. ".Id="
            .. tostring(entry.Name)
        )
        log(
            "BasketEntry#"
            .. tostring(i)
            .. ".Egg="
            .. tostring(
                entry:GetAttribute("Egg")
            )
        )
        log(
            "BasketEntry#"
            .. tostring(i)
            .. ".Weight="
            .. tostring(
                entry:GetAttribute("Weight")
            )
        )
        log(
            "BasketEntry#"
            .. tostring(i)
            .. ".VolcanoDipped="
            .. tostring(
                entry:GetAttribute("VolcanoDipped")
            )
        )
        log(
            "BasketEntry#"
            .. tostring(i)
            .. ".Delivering="
            .. tostring(
                entry:GetAttribute("Delivering")
            )
        )
    end
end

-- Every direct/API automation enters this gate before it performs game work.
-- This closes the old check-then-act race where Steal could begin between a
-- worker's Busy check and its RemoteEvent call.
shared.SerenityRideAPet.DirectActionRuntime =
    shared.SerenityRideAPet.DirectActionRuntime
    or {
        ActiveCount = 0,
        Owners = {},
    }

shared.SerenityRideAPet.BeginDirectAction = function(owner)
    if shared.SerenityRideAPet.IsStealActionBusy() then
        return false, "steal action busy"
    end

    local runtime =
        shared.SerenityRideAPet.DirectActionRuntime

    owner = tostring(owner or "DIRECT")

    runtime.ActiveCount =
        math.max(
            0,
            tonumber(runtime.ActiveCount) or 0
        ) + 1

    runtime.Owners[owner] =
        (tonumber(runtime.Owners[owner]) or 0)
        + 1

    return true
end

shared.SerenityRideAPet.EndDirectAction = function(owner)
    local runtime =
        shared.SerenityRideAPet.DirectActionRuntime

    if not runtime then
        return true
    end

    owner = tostring(owner or "DIRECT")

    local count =
        math.max(
            0,
            (tonumber(runtime.Owners[owner]) or 0) - 1
        )

    if count == 0 then
        runtime.Owners[owner] = nil
    else
        runtime.Owners[owner] = count
    end

    runtime.ActiveCount =
        math.max(
            0,
            (tonumber(runtime.ActiveCount) or 0) - 1
        )

    return true
end

shared.SerenityRideAPet.RunDirectAction = function(owner, callback)
    local ready, reason =
        shared.SerenityRideAPet.BeginDirectAction(owner)

    if not ready then
        return false, false, reason
    end

    local packed =
        table.pack(
            xpcall(
                callback,
                debug.traceback
            )
        )

    shared.SerenityRideAPet.EndDirectAction(owner)

    if not packed[1] then
        error(packed[2], 0)
    end

    return
        true,
        table.unpack(
            packed,
            2,
            packed.n
        )
end

shared.SerenityRideAPet.UpdateStealStuckWatch = function(candidate)
    local runtime =
        shared.SerenityRideAPet.StealStuckRuntime

    local root =
        LP.Character
        and LP.Character:FindFirstChild(
            "HumanoidRootPart"
        )

    if not root
        or type(candidate) ~= "table"
        or not candidate.active then

        shared.SerenityRideAPet.ResetStealStuckRuntime()
        return false
    end

    -- The dedicated Volcanic route is intentionally much longer than the
    -- normal steal path and already has bounded movement/pickup timeouts.
    -- Do not misclassify that expected route duration as a 10-second stall.
    if type(shared.SerenityRideAPet.IsVolcanicEggType) == "function"
        and shared.SerenityRideAPet.IsVolcanicEggType(candidate.eggType) then

        shared.SerenityRideAPet.ResetStealStuckRuntime()
        return false
    end

    local targetId =
        tostring(
            candidate.active.Name
            or ""
        )

    local now =
        os.clock()

    if runtime.TargetId ~= targetId
        or typeof(runtime.LastPosition) ~= "Vector3" then

        runtime.TargetId = targetId
        runtime.LastPosition = root.Position
        runtime.LastProgressAt = now
        return false
    end

    local moved =
        (
            root.Position
            - runtime.LastPosition
        ).Magnitude

    if moved >= 3 then
        runtime.LastPosition = root.Position
        runtime.LastProgressAt = now
        return false
    end

    local stalledFor =
        now
        - (
            tonumber(runtime.LastProgressAt)
            or now
        )

    if stalledFor < 10 then
        return false
    end

    if now
        - (
            tonumber(runtime.LastFallbackAt)
            or 0
        ) < 4 then

        return true
    end

    runtime.LastFallbackAt = now

    log("")
    log("=== STEAL_STUCK_10S ===")
    log("TargetId=" .. targetId)
    log("StalledFor=" .. tostring(stalledFor))
    log("Action=RETURN_HOME")

    return true
end

shared.SerenityRideAPet.BeginStealAction = function(candidate)
    if type(
        shared.SerenityRideAPet.StopStealHoverHold
    ) == "function" then

        shared.SerenityRideAPet.StopStealHoverHold(
            "begin-steal-cleanup"
        )
    end

    local runtime =
        shared.SerenityRideAPet.StealActionRuntime

    if runtime.Busy == true then
        return false,
            "steal action already busy"
    end

    local basketBlocked, basketEntries =
        shared.SerenityRideAPet.HasUnresolvedBasketEgg()

    if basketBlocked then
        shared.SerenityRideAPet.LogUnresolvedBasketLock(
            basketEntries
        )

        return false,
            "unresolved carried Basket egg"
    end

    -- Quietly wait out a failed Volcanic pickup cooldown before taking
    -- ownership of the steal lane. This prevents repeated VOLCANIC_STEAL_MODE
    -- blocks and transaction churn while the same ActiveEgg is cooling down.
    if type(candidate) == "table"
        and candidate.active
        and type(shared.SerenityRideAPet.IsVolcanicEggType) == "function"
        and shared.SerenityRideAPet.IsVolcanicEggType(candidate.eggType)
        and not shared.SerenityRideAPet.VolcanicRetryReady(candidate.active) then

        return false,
            "volcanic retry cooldown"
    end

    runtime.Busy = true
    runtime.Since = os.clock()
    runtime.Serial =
        (tonumber(runtime.Serial) or 0)
        + 1
    runtime.AbortRequested = false
    runtime.AbortReason = nil
    runtime.EmergencyReturn = false

    -- Freeze all settings that can change which egg/movement path the CURRENT
    -- steal uses. UI changes still save immediately, but apply to the NEXT
    -- steal instead of mutating a transaction already in progress.
    runtime.SettingsSnapshot = {
        InstantSteal =
            Config.InstantSteal == true,
        GardenReturnTweenSpeed =
            math.clamp(
                tonumber(
                    Config.GardenReturnTweenSpeed
                )
                    or EGG_TWEEN_SPEED,
                250,
                4000
            ),
        StealMinKG =
            tostring(
                Config.StealMinKG
                or "0"
            ),
        StealMinLuck =
            tostring(
                Config.StealMinLuck
                or "Any"
            ),
        StealEggs =
            selectionAsArray(
                Config.StealEggs
            ),
        StealPriority =
            tostring(
                Config.StealPriority
                or "Highest to Lowest"
            ),
        VolcanicMutationInSteal =
            Config.VolcanicMutationInSteal
                == true,
    }

    -- Stop native server-side shop buying before movement begins too.
    if type(
        shared.SerenityRideAPet.PauseNativeAutoBuyForSteal
    ) == "function" then

        shared.SerenityRideAPet.PauseNativeAutoBuyForSteal()
    end

    -- Wait for anything that had already entered the direct-action gate before
    -- Steal claimed exclusivity. New work cannot enter once Busy=true.
    local deadline =
        os.clock() + 2

    while (
        equipmentActionBusy
        or (
            shared.SerenityRideAPet.DirectActionRuntime
            and (
                tonumber(
                    shared.SerenityRideAPet
                        .DirectActionRuntime
                        .ActiveCount
                ) or 0
            ) > 0
        )
    ) and os.clock() < deadline do

        if shared.SerenityRideAPet.MovementRuntime then
            shared.SerenityRideAPet.MovementRuntime.Heartbeat =
                os.clock()
        end

        task.wait(0.03)
    end

    local directBusy =
        shared.SerenityRideAPet.DirectActionRuntime
        and (
            tonumber(
                shared.SerenityRideAPet
                    .DirectActionRuntime
                    .ActiveCount
            ) or 0
        ) > 0

    if equipmentActionBusy or directBusy then
        runtime.Busy = false
        runtime.Since = 0
        runtime.SettingsSnapshot = nil
        runtime.AbortRequested = false
        runtime.AbortReason = nil
        runtime.EmergencyReturn = false

        if type(
            shared.SerenityRideAPet.ResumeNativeAutoBuyAfterSteal
        ) == "function" then

            shared.SerenityRideAPet.ResumeNativeAutoBuyAfterSteal()
        end

        return false, "direct action still busy"
    end

    -- Never enter the egg pickup while a previous Food/Egg Tool is still held.
    shared.SerenityRideAPet.RefreshRuntimeCharacterRefs(0)

    if Humanoid
        and Humanoid.Parent then

        pcall(function()
            Humanoid:UnequipTools()
        end)

        task.wait(0.03)
    end

    -- v80.2.92:
    -- Normal steal/mutation hover behavior is unchanged. The dedicated
    -- Volcanic Egg acquisition alone now uses the Chilli-style scoped noclip
    -- door/interior movement copied for this live test.
    if runtime.NoclipCleanup then
        pcall(runtime.NoclipCleanup)
        runtime.NoclipCleanup = nil
    end

    local volcanicSpecial =
        type(candidate) == "table"
        and type(
            shared.SerenityRideAPet
                .IsVolcanicEggType
        ) == "function"
        and shared.SerenityRideAPet
            .IsVolcanicEggType(
                candidate.eggType
            )

    runtime.VolcanicSpecial =
        volcanicSpecial == true

    log("StealAction.WholeRouteNoclip=false")

    if volcanicSpecial then
        log("")
        log("=== VOLCANIC_STEAL_MODE ===")
        log("WholeStealNoclip=false")
        log("VolcanicAcquireMode=CHILLI_STYLE")
        log("EntryTemporaryNoclip=true")
        log("InsideTemporaryNoclip=true")
        log("ExitTemporaryNoclip=true")
        log("PickupRemote=EggPickup")
        log("PostExitReturnNoclip=true")
    end

    return true
end

shared.SerenityRideAPet.EndStealAction = function()
    local runtime =
        shared.SerenityRideAPet.StealActionRuntime

    if type(
        shared.SerenityRideAPet.StopStealHoverHold
    ) == "function" then

        shared.SerenityRideAPet.StopStealHoverHold(
            "end-steal"
        )
    end

    -- Mark Steal complete first, then restore the character's collision state.
    runtime.Busy = false
    runtime.Since = 0
    runtime.VolcanicSpecial = false
    runtime.SettingsSnapshot = nil
    runtime.AbortRequested = false
    runtime.AbortReason = nil
    runtime.EmergencyReturn = false

    local stopStealNoclip =
        runtime.NoclipCleanup

    runtime.NoclipCleanup = nil

    if stopStealNoclip then
        pcall(stopStealNoclip)
    end

    if type(
        shared.SerenityRideAPet.ResumeNativeAutoBuyAfterSteal
    ) == "function" then

        shared.SerenityRideAPet.ResumeNativeAutoBuyAfterSteal()
    end

    return true
end

local PetDismountRemote =
    GameRemotes:FindFirstChild("PetDismount")

local PlotRemotes =
    GameRemotes:FindFirstChild("Plot")

local UpgradesRemote =
    PlotRemotes and PlotRemotes:FindFirstChild("Upgrades")

local HatchLuckData = nil

pcall(function()
    HatchLuckData =
        require(
            ReplicatedStorage
                :WaitForChild("GameData")
                :WaitForChild("HatchLuck")
        )
end)

local function cashValue()
    local saved = LP:FindFirstChild("SavedData")
    local cash = saved and saved:FindFirstChild("Cash")
    return cash and tonumber(cash.Value) or 0
end

local function isCurrentlyRiding()
    return
        LP:GetAttribute("IsRiding") == true
        or LP:GetAttribute("IsPassenger") == true
end

local function ensureDismounted()
    if LP:GetAttribute("IsRiding") ~= true
        and LP:GetAttribute("IsPassenger") ~= true then

        return true
    end

    if not PetDismountRemote
        or not PetDismountRemote:IsA("RemoteEvent") then

        return false
    end

    local ok = pcall(function()
        PetDismountRemote:FireServer()
    end)

    if not ok then
        return false
    end

    local deadline = os.clock() + 3

    repeat
        if LP:GetAttribute("IsRiding") ~= true
            and LP:GetAttribute("IsPassenger") ~= true then

            return true
        end

        task.wait(0.05)
    until os.clock() >= deadline

    return
        LP:GetAttribute("IsRiding") ~= true
        and LP:GetAttribute("IsPassenger") ~= true
end

-- Use the game's own persistent Auto-Buy toggles.
-- No polling worker is needed after the state is applied.
local AutobuyRemote =
    GameRemotes:FindFirstChild("Autobuy")

local FOOD_AUTO_BUY_ITEMS, GEAR_AUTO_BUY_ITEMS =
    (function()
        local foodFallback = {
            "Grass",
            "Bone",
            "Meat",
            "Magic Apple",
            "Dragonfruit",
        }

        local gearFallback = {
            "Advanced Radar",
            "Jewel Radar",
            "Royal Radar",
            "Magic Radar",
            "Angelic Radar",
            "Eternal Radar",
        }

        local function categoryNames(category, fallback)
            local result = {}
            local seen = {}

            if type(category) == "table" then
                for key, value in pairs(category) do
                    local name = nil

                    if type(key) == "string" then
                        name = key
                    elseif type(value) == "string" then
                        name = value
                    elseif type(value) == "table" then
                        name =
                            value.Name
                            or value.ItemName
                            or value.Item
                            or value.Id
                    end

                    if name ~= nil then
                        name = tostring(name)

                        if name ~= "" and not seen[name] then
                            seen[name] = true
                            result[#result + 1] = name
                        end
                    end
                end
            end

            if #result == 0 then
                for _, name in ipairs(fallback) do
                    result[#result + 1] = name
                end
            end

            table.sort(result)
            return result
        end

        local shop = nil
        pcall(function()
            shop =
                require(
                    ReplicatedStorage
                        :WaitForChild("GameData")
                        :WaitForChild("Shop")
                )
        end)

        if type(shop) ~= "table" then
            return foodFallback, gearFallback
        end

        return
            categoryNames(shop.Food, foodFallback),
            categoryNames(shop.Gears, gearFallback)
    end)()

local nativeAutoBuyApplied = {}

local function desiredNativeAutoBuy(category, itemName)
    if category == "Food" then
        return Config.AutoShopFood == true
            and selectionHas(Config.ShopFoodAutoBuyItems, itemName)
    end

    if category == "Gears" then
        return Config.AutoShopGears == true
            and selectionHas(Config.ShopGearAutoBuyItems, itemName)
    end

    return false
end

local function applyNativeAutoBuy(category, itemName, enabled)
    if not AutobuyRemote
        or not AutobuyRemote:IsA("RemoteEvent") then

        return false
    end

    local key = category .. "/" .. itemName

    if nativeAutoBuyApplied[key] == enabled then
        return true
    end

    local ok = pcall(function()
        AutobuyRemote:FireServer(
            category,
            itemName,
            enabled == true
        )
    end)

    if ok then
        nativeAutoBuyApplied[key] = enabled == true

        log(
            "NativeAutoBuy."
            .. key
            .. "="
            .. tostring(enabled == true)
        )
    else
        log(
            "NativeAutoBuy."
            .. key
            .. "=REQUEST_FAILED"
        )
    end

    return ok
end

local function syncNativeAutoBuy(force)
    if shared.SerenityRideAPet.IsStealActionBusy() then
        return false, "steal action busy"
    end

    if force then
        nativeAutoBuyApplied = {}
    end

    for _, itemName in ipairs(FOOD_AUTO_BUY_ITEMS) do
        applyNativeAutoBuy(
            "Food",
            itemName,
            desiredNativeAutoBuy("Food", itemName)
        )
    end

    for _, itemName in ipairs(GEAR_AUTO_BUY_ITEMS) do
        applyNativeAutoBuy(
            "Gears",
            itemName,
            desiredNativeAutoBuy("Gears", itemName)
        )
    end

    return true
end

shared.SerenityRideAPet.PauseNativeAutoBuyForSteal = function()
    for _, itemName in ipairs(FOOD_AUTO_BUY_ITEMS) do
        applyNativeAutoBuy(
            "Food",
            itemName,
            false
        )
    end

    for _, itemName in ipairs(GEAR_AUTO_BUY_ITEMS) do
        applyNativeAutoBuy(
            "Gears",
            itemName,
            false
        )
    end

    return true
end

shared.SerenityRideAPet.ResumeNativeAutoBuyAfterSteal = function()
    return syncNativeAutoBuy(false)
end


-- ============================================================
-- LOW-LAG AUTO SELL
-- Full Workspace scan happens ONCE, lazily, when Auto Sell first runs.
-- After that the cache is maintained by DescendantAdded/Removing.
-- ============================================================

local PickupPetRemote =
    GameRemotes:FindFirstChild("PickupPet")

local PlacePetRemote =
    GameRemotes:FindFirstChild("PlacePet")

local PetsData = nil

pcall(function()
    PetsData =
        require(
            ReplicatedStorage
                :WaitForChild("GameData")
                :WaitForChild("Pets")
        )
end)


local PetRenderer = nil

pcall(function()
    PetRenderer =
        require(
            LP
                :WaitForChild("PlayerScripts")
                :WaitForChild("Game")
                :WaitForChild("Pets")
                :WaitForChild("PetRenderer")
        )
end)

-- ============================================================
-- AUTO REBIRTH — exact game conditions
-- Recon proves:
--   max rebirths = GameData.Rebirths.Cap
--   exact cost = GameData.Rebirths.GetCost(currentRebirths)
--   required pet = General.RebirthRequirements[currentRebirths + 1]
--   request = ReplicatedStorage.Remotes.Game.Rebirth:FireServer()
-- Server remains authoritative; success is confirmed by SavedData.Rebirths.
-- ============================================================
do
    local state =
        shared.SerenityRideAPet.RebirthRuntime
        or {
            LastAction = 0,
        }

    shared.SerenityRideAPet.RebirthRuntime =
        state

    state.Remote =
        GameRemotes:FindFirstChild("Rebirth")

    state.Data = nil
    state.General = nil

    pcall(function()
        state.Data =
            require(
                ReplicatedStorage
                    :WaitForChild("GameData")
                    :WaitForChild("Rebirths")
            )
    end)

    pcall(function()
        state.General =
            require(
                ReplicatedStorage
                    :WaitForChild("GameData")
                    :WaitForChild("General")
            )
    end)

    state.Eggs = nil

    pcall(function()
        state.Eggs =
            require(
                ReplicatedStorage
                    :WaitForChild("GameData")
                    :WaitForChild("Eggs")
            )
    end)

    state.PendingServerPet =
        state.PendingServerPet

    state.PendingServerPetAt =
        tonumber(
            state.PendingServerPetAt
        )
        or 0

    state.LastRequirementLogAt =
        tonumber(
            state.LastRequirementLogAt
        )
        or 0

    state.ChanceCache =
        state.ChanceCache
        or {
            RequiredPet = nil,
            UpgradeCount = nil,
            EventMultiplier = nil,
            PlayerMultiplier = nil,
            Values = {},
            BuiltAt = 0,
        }

    state.OwnershipCache =
        state.OwnershipCache
        or {
            Pet = nil,
            Result = false,
            CheckedAt = 0,
        }

    state.CarriedCandidateCache =
        state.CarriedCandidateCache
        or {
            Pet = nil,
            Candidate = nil,
            CheckedAt = 0,
        }

    state.PlacedCandidateCache =
        state.PlacedCandidateCache
        or {
            Pet = nil,
            Candidate = nil,
            CheckedAt = 0,
        }

    state.ActiveCandidateCache =
        state.ActiveCandidateCache
        or {
            Pet = nil,
            Candidate = nil,
            CheckedAt = 0,
            ActiveCount = -1,
            OwnedChance = -1,
        }

    shared.SerenityRideAPet.OwnsRequiredRebirthPet =
        function(requiredPet)
            requiredPet =
                tostring(requiredPet or "")

            if requiredPet == "" then
                return true
            end

            if type(PetRenderer) == "table"
                and type(PetRenderer.GetAll) == "function" then

                local ok, rendered =
                    pcall(function()
                        return PetRenderer.GetAll()
                    end)

                if ok and type(rendered) == "table" then
                    for _, data in pairs(rendered) do
                        local model =
                            type(data) == "table"
                            and data.Model
                            or nil

                        if type(data) == "table"
                            and tonumber(data.OwnerUserId) == LP.UserId
                            and model
                            and model.Parent
                            and model.Name == requiredPet then

                            return true
                        end
                    end
                end
            end

            local function scanTools(parent)
                if not parent then
                    return false
                end

                for _, tool in ipairs(parent:GetChildren()) do
                    if tool:IsA("Tool")
                        and tool:GetAttribute("PetKey") then

                        local name =
                            string.match(
                                tool.Name,
                                "^(.-) %["
                            )
                            or tool.Name

                        if name == requiredPet then
                            return true
                        end
                    end
                end

                return false
            end

            if scanTools(
                LP:FindFirstChildOfClass("Backpack")
            ) or scanTools(LP.Character) then
                return true
            end

            local char = LP.Character
            local root =
                char
                and char:FindFirstChild(
                    "HumanoidRootPart"
                )

            local joint =
                root
                and root:FindFirstChild(
                    "PetMountJoint"
                )

            local part1 =
                joint
                and joint.Part1

            local model =
                part1
                and part1.Parent

            return model ~= nil
                and model:GetAttribute("PetName")
                    == requiredPet
        end

    shared.SerenityRideAPet.RebirthRequirementEggName =
        function(instance)
            if not instance then
                return nil
            end

            local attr =
                instance:GetAttribute("EggName")
                or instance:GetAttribute("EggType")

            if attr
                and type(state.Eggs) == "table"
                and state.Eggs[tostring(attr)] then

                return tostring(attr)
            end

            local direct =
                baseEggName(instance.Name)

            if type(state.Eggs) == "table"
                and state.Eggs[direct] then

                return direct
            end

            if type(state.Eggs) == "table" then
                local lowName =
                    string.lower(
                        tostring(instance.Name)
                    )

                for eggName in pairs(state.Eggs) do
                    if string.find(
                        lowName,
                        string.lower(
                            tostring(eggName)
                        ),
                        1,
                        true
                    ) then

                        return eggName
                    end
                end
            end

            return nil
        end

    shared.SerenityRideAPet.GetRebirthRequirementChanceMap =
        function(requiredPet)
            requiredPet =
                tostring(
                    requiredPet
                    or ""
                )

            if requiredPet == ""
                or type(state.Eggs) ~= "table"
                or type(HatchLuckData) ~= "table"
                or type(
                    HatchLuckData.GetBoostedOdds
                ) ~= "function"
                or type(
                    HatchLuckData.GetMultiplierFor
                ) ~= "function" then

                return {}
            end

            local saved =
                LP:FindFirstChild(
                    "SavedData"
                )

            local upgrades =
                saved
                and saved:FindFirstChild(
                    "HatchUpgrades"
                )

            local upgradeCount =
                upgrades
                and tonumber(
                    upgrades.Value
                )
                or 0

            local cache =
                state.ChanceCache

            local now =
                os.clock()

            -- No repeated HatchLuck pool rebuilds. During a stable requirement
            -- this returns the same table directly for 15 seconds.
            if cache.RequiredPet == requiredPet
                and cache.UpgradeCount == upgradeCount
                and type(cache.Values) == "table"
                and now
                    - (
                        tonumber(
                            cache.BuiltAt
                        )
                        or 0
                    ) < 15 then

                return cache.Values
            end

            local eventMultiplier = 1

            if type(
                HatchLuckData.EventMultiplier
            ) == "function" then

                local okEvent,
                    value =
                    pcall(
                        HatchLuckData.EventMultiplier
                    )

                if okEvent then
                    eventMultiplier =
                        tonumber(value)
                        or 1
                end
            end

            -- If only the 15-second verification window expired and the
            -- actual inputs are unchanged, keep the existing odds table.
            if cache.RequiredPet == requiredPet
                and cache.UpgradeCount == upgradeCount
                and cache.EventMultiplier == eventMultiplier
                and type(cache.Values) == "table" then

                cache.BuiltAt = now

                return cache.Values
            end

            local okMultiplier,
                playerMultiplier =
                pcall(
                    HatchLuckData.GetMultiplierFor,
                    LP,
                    upgradeCount
                )

            if not okMultiplier then
                return {}
            end

            playerMultiplier =
                tonumber(
                    playerMultiplier
                )
                or 1

            local values = {}

            for eggName, cfg in pairs(
                state.Eggs
            ) do
                if type(cfg) == "table"
                    and cfg.Premium ~= true
                    and tonumber(
                        cfg.Luck
                    ) then

                    local okOdds,
                        odds,
                        total =
                        pcall(
                            HatchLuckData.GetBoostedOdds,
                            tonumber(
                                cfg.Luck
                            )
                                * playerMultiplier,
                            eventMultiplier,
                            cfg
                        )

                    local chance = 0

                    if okOdds
                        and type(odds)
                            == "table"
                        and tonumber(total)
                        and tonumber(total) > 0 then

                        for _, row in ipairs(
                            odds
                        ) do
                            if type(row) == "table"
                                and row.PetName
                                    == requiredPet then

                                chance =
                                    tonumber(
                                        row.Chance
                                    )
                                    or 0

                                break
                            end
                        end
                    end

                    values[eggName] =
                        chance
                end
            end

            cache.RequiredPet =
                requiredPet

            cache.UpgradeCount =
                upgradeCount

            cache.EventMultiplier =
                eventMultiplier

            cache.PlayerMultiplier =
                playerMultiplier

            cache.Values =
                values

            cache.BuiltAt =
                now

            -- All candidate caches depend on the odds table.
            state.CarriedCandidateCache.CheckedAt = 0
            state.PlacedCandidateCache.CheckedAt = 0
            state.ActiveCandidateCache.CheckedAt = 0

            return values
        end

    shared.SerenityRideAPet.RebirthRequirementChance =
        function(
            eggName,
            requiredPet
        )
            local values =
                shared.SerenityRideAPet
                    .GetRebirthRequirementChanceMap(
                        requiredPet
                    )

            return
                tonumber(
                    values[
                        tostring(
                            eggName
                            or ""
                        )
                    ]
                )
                or 0
        end

    shared.SerenityRideAPet.CurrentRebirthRequiredPet =
        function()
            if type(state.General)
                ~= "table" then

                return nil
            end

            local saved =
                LP:FindFirstChild(
                    "SavedData"
                )

            local rebirths =
                saved
                and saved:FindFirstChild(
                    "Rebirths"
                )

            if not rebirths then
                return nil
            end

            local current =
                tonumber(
                    rebirths.Value
                )
                or 0

            local requirements =
                state.General
                    .RebirthRequirements

            return
                type(requirements)
                    == "table"
                and requirements[
                    current + 1
                ]
                or nil,
                current
        end

    shared.SerenityRideAPet.OwnsRebirthPetCached =
        function(requiredPet)
            local cache =
                state.OwnershipCache

            local now =
                os.clock()

            if cache.Pet == requiredPet
                and now
                    - (
                        tonumber(
                            cache.CheckedAt
                        )
                        or 0
                    ) < 1 then

                return cache.Result
                    == true
            end

            local result =
                shared.SerenityRideAPet
                    .OwnsRequiredRebirthPet(
                        requiredPet
                    )

            cache.Pet =
                requiredPet

            cache.Result =
                result == true

            cache.CheckedAt =
                now

            return cache.Result
        end

    shared.SerenityRideAPet.FindBestRebirthRequirementEggTool =
        function(requiredPet)
            local cache =
                state.CarriedCandidateCache

            local now =
                os.clock()

            if cache.Pet == requiredPet
                and now
                    - (
                        tonumber(
                            cache.CheckedAt
                        )
                        or 0
                    ) < 2 then

                local candidate =
                    cache.Candidate

                if not candidate
                    or (
                        candidate.Tool
                        and candidate.Tool.Parent
                    ) then

                    return candidate
                end
            end

            local best = nil

            for _, tool in ipairs(
                eggTools()
            ) do
                local eggName =
                    baseEggName(
                        tool.Name
                    )

                local chance =
                    shared.SerenityRideAPet
                        .RebirthRequirementChance(
                            eggName,
                            requiredPet
                        )

                if chance > 0 then
                    local cfg =
                        type(state.Eggs) == "table"
                        and state.Eggs[
                            eggName
                        ]
                        or nil

                    local growth =
                        type(cfg) == "table"
                        and tonumber(
                            cfg.GrowthTime
                        )
                        or math.huge

                    if not best
                        or chance > best.Chance
                        or (
                            chance
                                == best.Chance
                            and growth
                                < best.GrowthTime
                        ) then

                        best = {
                            Tool = tool,
                            EggName = eggName,
                            Chance = chance,
                            GrowthTime = growth,
                        }
                    end
                end
            end

            cache.Pet =
                requiredPet

            cache.Candidate =
                best

            cache.CheckedAt =
                now

            return best
        end

    shared.SerenityRideAPet.FindPlacedRebirthRequirementEgg =
        function(requiredPet)
            local cache =
                state.PlacedCandidateCache

            local now =
                os.clock()

            if cache.Pet == requiredPet
                and now
                    - (
                        tonumber(
                            cache.CheckedAt
                        )
                        or 0
                    ) < 1 then

                local candidate =
                    cache.Candidate

                if candidate
                    and candidate.Egg
                    and candidate.Egg.Parent then

                    local prompt =
                        candidate.Egg
                            :FindFirstChild(
                                "Hatch",
                                true
                            )

                    candidate.Ready =
                        prompt
                        and prompt:IsA(
                            "ProximityPrompt"
                        )
                        and prompt.Enabled
                        or false
                end

                if not candidate
                    or (
                        candidate.Egg
                        and candidate.Egg.Parent
                    ) then

                    return candidate
                end
            end

            local plot =
                ownPlot()

            local folder =
                plot
                and plot:FindFirstChild(
                    "Eggs"
                )

            if not folder then
                cache.Pet =
                    requiredPet
                cache.Candidate =
                    nil
                cache.CheckedAt =
                    now

                return nil
            end

            local best = nil

            for _, egg in ipairs(
                folder:GetChildren()
            ) do
                if egg:IsA("Model") then
                    local owner =
                        tonumber(
                            egg:GetAttribute(
                                "OwnerUserId"
                            )
                        )

                    if owner == nil
                        or owner == LP.UserId then

                        local eggName =
                            shared.SerenityRideAPet
                                .RebirthRequirementEggName(
                                    egg
                                )

                        local chance =
                            eggName
                            and shared.SerenityRideAPet
                                .RebirthRequirementChance(
                                    eggName,
                                    requiredPet
                                )
                            or 0

                        if chance > 0 then
                            local prompt =
                                egg:FindFirstChild(
                                    "Hatch",
                                    true
                                )

                            local ready =
                                prompt
                                and prompt:IsA(
                                    "ProximityPrompt"
                                )
                                and prompt.Enabled
                                or false

                            if not best
                                or chance
                                    > best.Chance
                                or (
                                    chance
                                        == best.Chance
                                    and ready
                                    and not best.Ready
                                ) then

                                best = {
                                    Egg = egg,
                                    EggName =
                                        eggName,
                                    Chance =
                                        chance,
                                    Ready =
                                        ready,
                                }
                            end
                        end
                    end
                end
            end

            cache.Pet =
                requiredPet

            cache.Candidate =
                best

            cache.CheckedAt =
                now

            return best
        end

    shared.SerenityRideAPet.BestOwnedRebirthRequirementChance =
        function(requiredPet)
            local placed =
                shared.SerenityRideAPet
                    .FindPlacedRebirthRequirementEgg(
                        requiredPet
                    )

            local carried =
                shared.SerenityRideAPet
                    .FindBestRebirthRequirementEggTool(
                        requiredPet
                    )

            local chance = 0

            if placed then
                chance =
                    math.max(
                        chance,
                        tonumber(
                            placed.Chance
                        )
                        or 0
                    )
            end

            if carried then
                chance =
                    math.max(
                        chance,
                        tonumber(
                            carried.Chance
                        )
                        or 0
                    )
            end

            return chance,
                placed,
                carried
        end

    shared.SerenityRideAPet.FindBestActiveRebirthRequirementEgg =
        function()
            if Config.AutoRebirth ~= true
                or not ActiveEggs then

                return nil
            end

            local requiredPet =
                shared.SerenityRideAPet
                    .CurrentRebirthRequiredPet()

            if not requiredPet
                or shared.SerenityRideAPet
                    .OwnsRebirthPetCached(
                        requiredPet
                    ) then

                return nil
            end

            local ownedChance =
                shared.SerenityRideAPet
                    .BestOwnedRebirthRequirementChance(
                        requiredPet
                    )

            local children =
                ActiveEggs:GetChildren()

            local cache =
                state.ActiveCandidateCache

            local now =
                os.clock()

            if cache.Pet == requiredPet
                and cache.ActiveCount
                    == #children
                and math.abs(
                    (
                        tonumber(
                            cache.OwnedChance
                        )
                        or 0
                    )
                    - (
                        tonumber(
                            ownedChance
                        )
                        or 0
                    )
                ) < 1e-12
                and now
                    - (
                        tonumber(
                            cache.CheckedAt
                        )
                        or 0
                    ) < 0.75 then

                local candidate =
                    cache.Candidate

                if not candidate
                    or (
                        candidate.active
                        and candidate.active.Parent
                    ) then

                    return candidate
                end
            end

            local values =
                shared.SerenityRideAPet
                    .GetRebirthRequirementChanceMap(
                        requiredPet
                    )

            local best = nil

            for _, active in ipairs(
                children
            ) do
                local eggType =
                    tostring(
                        active:GetAttribute(
                            "Egg"
                        )
                        or ""
                    )

                local chance =
                    tonumber(
                        values[
                            eggType
                        ]
                    )
                    or 0

                local privateTo =
                    active:GetAttribute(
                        "PrivateTo"
                    )

                local position =
                    active:GetAttribute(
                        "Position"
                    )

                if chance > ownedChance
                    and eggType ~= ""
                    and shared.SerenityRideAPet
                        .ActiveEggPrivateAllowed(
                            active
                        )
                    and shared.SerenityRideAPet
                        .ActiveEggDropReady(
                            active
                        ) == true
                    and typeof(position)
                        == "Vector3"
                    and not isGhostEgg(
                        active
                    )
                    and not shared.SerenityRideAPet
                        .IsNativeEggClaimed(
                            active
                        )
                    and not shared.SerenityRideAPet
                        .IsEggRestockBlocked(
                            eggType,
                            active
                        )
                    and not shared.SerenityRideAPet
                        .IsActiveEggExhausted(
                            active
                        ) then

                    local meta =
                        eggMeta[
                            eggType
                        ]
                        or {}

                    local eggWeight,
                        eggWeightText,
                        rawWeight =
                        shared.SerenityRideAPet
                            .ActiveEggKG(
                                active
                            )

                    local candidate = {
                        active =
                            active,
                        eggType =
                            eggType,
                        position =
                            position,
                        eggLuck =
                            tonumber(
                                meta.luck
                            )
                            or 0,
                        eggWeight =
                            tonumber(
                                eggWeight
                            )
                            or 0,
                        eggWeightText =
                            eggWeightText,
                        rawWeight =
                            rawWeight,
                        rarity =
                            tostring(
                                meta.rarity
                                or "?"
                            ),
                        appearChance =
                            tonumber(
                                meta.appearChance
                            ),
                        distance =
                            (
                                position
                                - HRP.Position
                            ).Magnitude,
                        requirementPet =
                            requiredPet,
                        requirementChance =
                            chance,
                        rebirthRequirementFallback =
                            true,
                    }

                    if not best
                        or chance
                            > best.requirementChance
                        or (
                            chance
                                == best.requirementChance
                            and candidate.eggLuck
                                > best.eggLuck
                        )
                        or (
                            chance
                                == best.requirementChance
                            and candidate.eggLuck
                                == best.eggLuck
                            and candidate.distance
                                < best.distance
                        ) then

                        best =
                            candidate
                    end
                end
            end

            cache.Pet =
                requiredPet

            cache.Candidate =
                best

            cache.CheckedAt =
                now

            cache.ActiveCount =
                #children

            cache.OwnedChance =
                ownedChance

            return best
        end

    shared.SerenityRideAPet.PlaceRebirthRequirementEgg =
        function(candidate, requiredPet)
            if type(candidate) ~= "table"
                or not candidate.Tool
                or not candidate.Tool.Parent then

                return false,
                    "requirement egg tool missing"
            end

            local tool =
                candidate.Tool

            local plot =
                ownPlot()

            local folder =
                plot
                and plot:FindFirstChild(
                    "Eggs"
                )

            if not plot
                or not folder then

                return false,
                    "own Plot.Eggs missing"
            end

            local canPlace,
                placeReason =
                shared.SerenityRideAPet
                    .CanAttemptEggPlacement(
                        folder
                    )

            if not canPlace then
                return false,
                    "requirement "
                    .. tostring(
                        placeReason
                    )
            end

            local _, _, rawWeight =
                shared.SerenityRideAPet
                    .ToolEggKG(
                        tool
                    )

            if tool.Parent ~= Character then
                local currentCharacter =
                    LP.Character
                    or LP.CharacterAdded:Wait()

                local humanoid =
                    currentCharacter
                        :FindFirstChildOfClass(
                            "Humanoid"
                        )

                if not humanoid then
                    return false,
                        "humanoid missing"
                end

                pcall(function()
                    humanoid:UnequipTools()
                end)

                task.wait(0.03)

                local equipOk =
                    pcall(function()
                        humanoid:EquipTool(
                            tool
                        )
                    end)

                if not equipOk then
                    return false,
                        "requirement egg equip failed"
                end

                local equipDeadline =
                    os.clock() + 1.5

                repeat
                    if tool.Parent
                        == currentCharacter then

                        break
                    end

                    task.wait(0.03)
                until os.clock()
                    >= equipDeadline

                if tool.Parent
                    ~= currentCharacter then

                    return false,
                        "requirement egg did not equip"
                end
            end

            if tool:GetAttribute(
                "EggSaveHooked"
            ) ~= true then

                local hookDeadline =
                    os.clock() + 1.25

                repeat
                    if tool:GetAttribute(
                        "EggSaveHooked"
                    ) == true then

                        break
                    end

                    task.wait(0.03)
                until os.clock()
                    >= hookDeadline
            end

            local position =
                nextPlantPosition(
                    plot,
                    folder
                )

            if typeof(position)
                ~= "Vector3" then

                return false,
                    "requirement plot position unavailable"
            end

            local before = {}
            local beforeCount =
                #folder:GetChildren()

            for _, child in ipairs(
                folder:GetChildren()
            ) do
                before[child] = true
            end

            local fireOk,
                fireErr =
                pcall(function()
                    EggPlacedRemote:FireServer({
                        PlantPosition =
                            position,
                    })
                end)

            if not fireOk then
                return false,
                    "EggPlaced request failed: "
                    .. tostring(fireErr)
            end

            local placed = nil
            local deadline =
                os.clock() + 1.5

            repeat
                for _, child in ipairs(
                    folder:GetChildren()
                ) do
                    if not before[child]
                        and child:IsA(
                            "Model"
                        ) then

                        placed = child
                        break
                    end
                end

                if placed then
                    break
                end

                task.wait(0.03)
            until os.clock()
                >= deadline

            local consumed =
                tool.Parent == nil

            if not placed
                and not consumed then

                shared.SerenityRideAPet
                    .MarkEggPlacementRejected(
                        folder,
                        beforeCount
                    )

                return false,
                    "requirement plot full or placement rejected"
            end

            -- Important: never use an OLD placed egg of the same type as
            -- confirmation for this request. That caused repeated placement
            -- attempts when the plot was already full.
            if placed
                and rawWeight ~= nil then

                shared.SerenityRideAPet
                    .RememberPlacedEggWeight(
                        placed,
                        rawWeight
                    )
            end

            state.CarriedCandidateCache.CheckedAt = 0
            state.PlacedCandidateCache.CheckedAt = 0
            state.ActiveCandidateCache.CheckedAt = 0

            return true, {
                Action =
                    "RequirementEggPlaced",
                RequiredPet =
                    requiredPet,
                EggName =
                    candidate.EggName,
                Chance =
                    candidate.Chance,
                EggKey =
                    placed
                    and placed:GetAttribute(
                        "EggKey"
                    )
                    or nil,
                ReplicationPending =
                    placed == nil
                    and consumed,
            }
        end

    shared.SerenityRideAPet.HatchRebirthRequirementEgg =
        function(candidate, requiredPet)
            if type(candidate) ~= "table"
                or not candidate.Egg
                or not candidate.Egg.Parent then

                return false,
                    "requirement placed egg missing"
            end

            local egg =
                candidate.Egg

            local eggKey =
                egg:GetAttribute(
                    "EggKey"
                )

            if eggKey == nil then
                return false,
                    "requirement EggKey missing"
            end

            eggKey =
                tostring(eggKey)

            local resultSeen =
                false

            local resultPayload =
                nil

            local conn =
                HatchRemote.OnClientEvent
                    :Connect(
                        function(payload)
                            if type(payload)
                                == "table"
                                and tostring(
                                    payload.EggKey
                                ) == eggKey then

                                resultSeen =
                                    true

                                resultPayload =
                                    payload
                            end
                        end
                    )

            local fireOk,
                fireErr =
                pcall(function()
                    HatchRemote:FireServer({
                        EggKey = eggKey,
                    })
                end)

            if not fireOk then
                conn:Disconnect()

                return false,
                    "requirement hatch request failed: "
                    .. tostring(fireErr)
            end

            local deadline =
                os.clock() + 3

            repeat
                if resultSeen then
                    break
                end

                task.wait(0.03)
            until os.clock()
                >= deadline

            conn:Disconnect()

            if not resultSeen then
                return false,
                    "requirement hatch result missing"
            end

            local petName =
                resultPayload
                and resultPayload.PetName
                or nil

            log("")
            log(
                "=== AUTO_REBIRTH_REQUIREMENT_HATCH ==="
            )
            log(
                "RequiredPet="
                .. tostring(requiredPet)
            )
            log(
                "HatchedEgg="
                .. tostring(
                    candidate.EggName
                )
            )
            log(
                "HatchedPet="
                .. tostring(petName)
            )
            log(
                "TargetMatched="
                .. tostring(
                    petName == requiredPet
                )
            )

            if petName == requiredPet then
                state.PendingServerPet =
                    requiredPet

                state.PendingServerPetAt =
                    os.clock()

                state.OwnershipCache.CheckedAt = 0
            end

            state.CarriedCandidateCache.CheckedAt = 0
            state.PlacedCandidateCache.CheckedAt = 0
            state.ActiveCandidateCache.CheckedAt = 0

            return true, {
                Action =
                    "RequirementEggHatched",
                RequiredPet =
                    requiredPet,
                EggName =
                    candidate.EggName,
                PetName =
                    petName,
                Matched =
                    petName == requiredPet,
            }
        end

    shared.SerenityRideAPet.TryAutoRebirth =
        function()
            if Config.AutoRebirth ~= true then
                return false, "disabled"
            end

            if shared.SerenityRideAPet.IsStealActionBusy() then
                return false, "steal action busy"
            end

            if not state.Remote
                or not state.Remote:IsA("RemoteEvent")
                or type(state.Data) ~= "table"
                or type(state.General) ~= "table"
                or type(state.Eggs) ~= "table"
                or type(HatchLuckData) ~= "table" then

                return false,
                    "rebirth requirement API unavailable"
            end

            local saved =
                LP:FindFirstChild("SavedData")

            local cash =
                saved
                and saved:FindFirstChild("Cash")

            local rebirths =
                saved
                and saved:FindFirstChild("Rebirths")

            if not cash
                or not rebirths then

                return false,
                    "rebirth saved data missing"
            end

            local current =
                tonumber(rebirths.Value)
                or 0

            local cap =
                tonumber(state.Data.Cap)

            if cap
                and current >= cap then

                return false,
                    "rebirth cap reached"
            end

            local requirements =
                state.General.RebirthRequirements

            local nextIndex =
                current + 1

            local requiredPet =
                type(requirements) == "table"
                and requirements[nextIndex]
                or nil

            if not requiredPet then
                return false,
                    "required pet data missing"
            end

            local cost = nil

            if type(
                state.Data.GetCost
            ) == "function" then

                local okCost,
                    exactCost =
                    pcall(
                        state.Data.GetCost,
                        current
                    )

                if okCost then
                    cost =
                        tonumber(exactCost)
                end
            end

            if cost == nil then
                local initialCost =
                    tonumber(
                        state.Data.InitialCost
                    )

                local multiplier =
                    tonumber(
                        state.Data.CostMultiplier
                    )

                if not initialCost
                    or not multiplier then

                    return false,
                        "rebirth cost data missing"
                end

                cost =
                    math.floor(
                        initialCost
                        * multiplier ^ current
                    )
            end

            local localOwns =
                shared.SerenityRideAPet
                    .OwnsRebirthPetCached(
                        requiredPet
                    )

            local serverConfirmed =
                state.PendingServerPet
                    == requiredPet
                and os.clock()
                    - (
                        tonumber(
                            state.PendingServerPetAt
                        )
                        or 0
                    ) <= 5

            local requirementReady =
                localOwns
                or serverConfirmed

            if not requirementReady then
                local placed =
                    shared.SerenityRideAPet
                        .FindPlacedRebirthRequirementEgg(
                            requiredPet
                        )

                local carried =
                    shared.SerenityRideAPet
                        .FindBestRebirthRequirementEggTool(
                            requiredPet
                        )

                -- Never let a nearly-zero-chance placed egg block a much
                -- better carried requirement egg.
                if carried
                    and (
                        not placed
                        or (
                            tonumber(
                                carried.Chance
                            )
                            or 0
                        ) > (
                            tonumber(
                                placed.Chance
                            )
                            or 0
                        )
                    ) then

                    return
                        shared.SerenityRideAPet
                            .PlaceRebirthRequirementEgg(
                                carried,
                                requiredPet
                            )
                end

                if placed then
                    if placed.Ready then
                        return
                            shared.SerenityRideAPet
                                .HatchRebirthRequirementEgg(
                                    placed,
                                    requiredPet
                                )
                    end

                    return false,
                        "waiting for best requirement egg hatch readiness"
                end

                if carried then
                    return
                        shared.SerenityRideAPet
                            .PlaceRebirthRequirementEgg(
                                carried,
                                requiredPet
                            )
                end

                return false,
                    "required pet missing; waiting for idle Auto Steal requirement fallback"
            end

            if serverConfirmed
                and not localOwns
                and os.clock()
                    - (
                        tonumber(
                            state.PendingServerPetAt
                        )
                        or 0
                    ) < 0.30 then

                return false,
                    "waiting for required pet replication"
            end

            if (tonumber(cash.Value) or 0)
                < cost then

                return false,
                    "required pet ready; insufficient cash"
            end

            if os.clock()
                - (
                    tonumber(state.LastAction)
                    or 0
                ) < 0.85 then

                return false,
                    "rebirth cooldown"
            end

            state.LastAction =
                os.clock()

            log("")
            log(
                "=== AUTO_REBIRTH_REQUIREMENTS_READY ==="
            )
            log(
                "CurrentRebirth="
                .. tostring(current)
            )
            log(
                "RequiredPet="
                .. tostring(requiredPet)
            )
            log(
                "RequiredPetLocalOwned="
                .. tostring(localOwns)
            )
            log(
                "RequiredPetServerConfirmed="
                .. tostring(serverConfirmed)
            )
            log(
                "RequiredCash="
                .. tostring(cost)
            )
            log(
                "CurrentCash="
                .. tostring(cash.Value)
            )

            local ok =
                pcall(function()
                    state.Remote:FireServer()
                end)

            if not ok then
                return false,
                    "rebirth request failed"
            end

            local deadline =
                os.clock() + 1.75

            repeat
                if (tonumber(rebirths.Value) or current)
                    > current then

                    state.PendingServerPet =
                        nil

                    state.PendingServerPetAt =
                        0

                    if Config.AutoEquipBest == true
                        and shared.SerenityRideAPet
                            .AutoEquipBestState then

                        shared.SerenityRideAPet
                            .AutoEquipBestState
                            .Pending =
                            true
                    end

                    return true, {
                        Action = "Rebirth",
                        Rebirths =
                            tonumber(
                                rebirths.Value
                            )
                            or current + 1,
                        Cost = cost,
                        RequiredPet =
                            requiredPet,
                    }
                end

                task.wait(0.05)
            until os.clock()
                >= deadline

            return false,
                "rebirth not confirmed"
        end

end

local lastSellAction = 0
local protectedPetKeys = {}
local cachedRichie = nil

local function currentMountedPetKey()
    if LP:GetAttribute("IsRiding") ~= true then
        return nil
    end

    local joint = HRP and HRP:FindFirstChild("PetMountJoint")
    local part1 = joint and joint.Part1
    local model = part1 and part1.Parent
    local key = model and model:GetAttribute("PetKey")

    return key and tostring(key) or nil
end

local function rememberCurrentPet()
    local key = currentMountedPetKey()

    if key then
        protectedPetKeys[key] = true
    end

    return key
end

do
    local runtime =
        shared.SerenityRideAPet.BaseMaintenanceRuntime
        or {
            LastMotionAt = os.clock(),
            LastPosition = nil,
            ReturnRequested = false,
            LastReturnAt = 0,
            LastReason = nil,
        }

    shared.SerenityRideAPet.BaseMaintenanceRuntime =
        runtime

    shared.SerenityRideAPet.BaseMaintenanceEnabled = function()
        -- Auto Place was live-proven to work from anywhere in V1.
        -- Auto Hatch V5 and Auto Feed are intentionally base-gated and may
        -- request one idle return when the player stays outside the base.
        return Config.AutoHatch == true
            or Config.AutoFeed == true
    end

    shared.SerenityRideAPet.IsInsideOwnBase = function()
        if not HRP or HRP.Parent == nil then
            return false
        end

        local _, base =
            findOwnGardenBaseplate()

        if not base then
            return false
        end

        local localPos =
            base.CFrame:PointToObjectSpace(
                HRP.Position
            )

        local margin = 4

        return math.abs(localPos.X)
                <= base.Size.X * 0.5 + margin
            and math.abs(localPos.Z)
                <= base.Size.Z * 0.5 + margin
            and math.abs(localPos.Y)
                <= math.max(
                    40,
                    base.Size.Y * 0.5 + 35
                )
    end

    shared.SerenityRideAPet.BaseAutomationCanWorkHere = function()
        return shared.SerenityRideAPet.IsInsideOwnBase()
    end

    shared.SerenityRideAPet.ReturnToBaseForMaintenance = function()
        if shared.SerenityRideAPet.IsStealActionBusy() then
            return false, "steal action busy"
        end

        if not shared.SerenityRideAPet.BaseMaintenanceEnabled() then
            runtime.ReturnRequested = false
            return false, "no base automation enabled"
        end

        if shared.SerenityRideAPet.IsInsideOwnBase() then
            runtime.ReturnRequested = false
            runtime.LastMotionAt = os.clock()
            return true, "already inside base"
        end

        if isCurrentlyRiding() then
            rememberCurrentPet()

            if not ensureDismounted() then
                return false, "dismount failed"
            end
        end

        local target =
            ownGardenReferenceCFrame()

        shared.SerenityRideAPet.QueueStreamRequest(
            target.Position,
            1.2
        )

        pcall(function()
            HRP.AssemblyLinearVelocity =
                Vector3.zero

            HRP.AssemblyAngularVelocity =
                Vector3.zero

            HRP.CFrame =
                target
        end)

        task.wait(0.08)

        local inside =
            shared.SerenityRideAPet.IsInsideOwnBase()

        if inside then
            runtime.ReturnRequested = false
            runtime.LastReturnAt = os.clock()
            runtime.LastMotionAt = os.clock()
            runtime.LastPosition = HRP.Position
            runtime.LastReason = "idle-base-maintenance"
            return true, "returned to base"
        end

        return false, "base return not confirmed"
    end
end

local function petRarity(model)
    local cfg =
        type(PetsData) == "table"
        and model
        and PetsData[model.Name]
        or nil

    return tostring(
        (type(cfg) == "table" and cfg.Rarity)
        or (model and model:GetAttribute("Rarity"))
        or ""
    )
end

shared.SerenityRideAPet.PetPerSecondValue = function(pet, tool)
    local key =
        type(pet) == "table"
        and tostring(pet.key or "")
        or ""

    local cache =
        key ~= ""
        and shared.SerenityRideAPet.SellRateCache[key]
        or nil

    if type(cache) == "table"
        and os.clock() - (tonumber(cache.at) or 0) < 2 then

        if cache.value == false then
            return nil
        end

        return tonumber(cache.value)
    end

    local function parseValue(value)
        if typeof(value) == "Instance"
            and value:IsA("ValueBase") then

            value = (value :: any).Value
        end

        if type(value) == "number" then
            if value >= 0 and value < math.huge then
                return value
            end

            return nil
        end

        local raw = tostring(value or "")

        if raw == "" then
            return nil
        end

        local cleaned =
            string.lower(raw)
            :gsub("%$", "")
            :gsub("/%s*s", "")
            :gsub("per%s*second", "")
            :gsub("%s+", "")

        return shared.SerenityRideAPet.ParseCompactNumber(cleaned)
    end

    local names = {
        "PerSecond",
        "MoneyPerSecond",
        "IncomePerSecond",
        "CashPerSecond",
        "EarningsPerSecond",
        "IncomeRate",
        "CashRate",
        "Income",
        "Earnings",
    }

    local function tableRate(tbl)
        if type(tbl) ~= "table" then
            return nil
        end

        for _, name in ipairs(names) do
            local value = parseValue(tbl[name])

            if value ~= nil then
                return value
            end
        end

        for field, raw in pairs(tbl) do
            local lower = string.lower(tostring(field))

            if (
                string.find(lower, "persecond", 1, true)
                or string.find(lower, "per_second", 1, true)
                or string.find(lower, "income", 1, true)
                or string.find(lower, "earning", 1, true)
            )
                and not string.find(lower, "multiplier", 1, true)
                and not string.find(lower, "boost", 1, true)
                and not string.find(lower, "bonus", 1, true) then

                local value = parseValue(raw)

                if value ~= nil then
                    return value
                end
            end
        end

        return nil
    end

    local function instanceRate(inst)
        if typeof(inst) ~= "Instance" then
            return nil
        end

        for _, name in ipairs(names) do
            local value = parseValue(inst:GetAttribute(name))

            if value ~= nil then
                return value
            end
        end

        for field, raw in pairs(inst:GetAttributes()) do
            local lower = string.lower(tostring(field))

            if (
                string.find(lower, "persecond", 1, true)
                or string.find(lower, "per_second", 1, true)
                or string.find(lower, "income", 1, true)
                or string.find(lower, "earning", 1, true)
            )
                and not string.find(lower, "multiplier", 1, true)
                and not string.find(lower, "boost", 1, true)
                and not string.find(lower, "bonus", 1, true) then

                local value = parseValue(raw)

                if value ~= nil then
                    return value
                end
            end
        end

        local data = inst:FindFirstChild("Data")

        if data then
            for _, name in ipairs(names) do
                local value = parseValue(data:FindFirstChild(name))

                if value ~= nil then
                    return value
                end
            end
        end

        -- Exact live in-world stat, e.g. "$36,450/s".
        -- Scan only this pet model/tool, never Workspace.
        for _, descendant in ipairs(inst:GetDescendants()) do
            if descendant:IsA("TextLabel")
                or descendant:IsA("TextButton") then

                local shown = tostring(descendant.Text or "")

                if string.find(string.lower(shown), "/s", 1, true) then
                    local value = parseValue(shown)

                    if value ~= nil then
                        return value
                    end
                end
            end
        end

        return nil
    end

    local value = instanceRate(tool)

    if value == nil
        and tool
        and type(PetsData) == "table" then

        local petName = tostring(
            tool:GetAttribute("PetName")
            or tool.Name
        )

        value = tableRate(
            PetsData[petName]
            or PetsData[tool.Name]
        )
    end

    if value == nil and type(pet) == "table" then
        value = tableRate(pet.entry)

        if value == nil then
            value = instanceRate(pet.model)
        end

        if value == nil
            and pet.model
            and type(PetsData) == "table" then

            value = tableRate(PetsData[pet.model.Name])
        end
    end

    if key ~= "" then
        shared.SerenityRideAPet.SellRateCache[key] = {
            value = value ~= nil and value or false,
            at = os.clock(),
        }
    end

    return value
end

local function petIsProtected(model, petKey, tool)
    local key = tostring(
        petKey
        or (model and model:GetAttribute("PetKey"))
        or (tool and tool:GetAttribute("PetKey"))
        or ""
    )

    if key == "" then
        return true
    end

    if protectedPetKeys[key] then
        return true
    end

    if Config.AutoSellProtectCurrentPet then
        local mounted = currentMountedPetKey()

        if mounted and mounted == key then
            return true
        end
    end

    local function flagged(inst, names)
        if typeof(inst) ~= "Instance" then
            return false
        end

        for _, name in ipairs(names) do
            if inst:GetAttribute(name) == true then
                return true
            end
        end

        return false
    end

    if Config.AutoSellProtectFavorites then
        if flagged(model, {"Favorite", "Favorited", "IsFavorite"})
            or flagged(tool, {"Favorite", "Favorited", "IsFavorite"}) then
            return true
        end
    end

    if Config.AutoSellProtectLocked then
        if flagged(model, {"Locked", "IsLocked"})
            or flagged(tool, {"Locked", "IsLocked"}) then
            return true
        end
    end

    return false
end

local SELL_RARITY_ORDER =
    (function()
        local fallback = {
            Common = 1,
            Uncommon = 2,
            Rare = 3,
            Epic = 4,
            Legendary = 5,
            Mythic = 6,
            Mythical = 6,
            Divine = 7,
            Ethereal = 8,
        }

        local raritySet = {}

        if type(PetsData) == "table" then
            for _, data in pairs(PetsData) do
                if type(data) == "table"
                    and type(data.Rarity) == "string"
                    and data.Rarity ~= "" then

                    raritySet[data.Rarity] = true
                end
            end
        end

        local multipliers = nil

        pcall(function()
            local general =
                require(
                    ReplicatedStorage
                        :WaitForChild("GameData")
                        :WaitForChild("General")
                )

            if type(general) == "table"
                and type(general.RarityLevelRequirementMultiplier) == "table" then

                multipliers =
                    general.RarityLevelRequirementMultiplier
            end
        end)

        local names = {}
        for rarity in pairs(raritySet) do
            names[#names + 1] = rarity
        end

        if #names == 0 then
            return fallback
        end

        table.sort(names, function(a, b)
            local av =
                type(multipliers) == "table"
                and tonumber(multipliers[a])
                or nil

            local bv =
                type(multipliers) == "table"
                and tonumber(multipliers[b])
                or nil

            -- General uses larger requirement multipliers for lower/common
            -- rarities (recon example: Common 70 ... Ethereal 7).
            if av and bv and av ~= bv then
                return av > bv
            end

            local af = fallback[a]
            local bf = fallback[b]

            if af and bf and af ~= bf then
                return af < bf
            elseif af ~= nil then
                return true
            elseif bf ~= nil then
                return false
            end

            return a < b
        end)

        local result = {}
        for index, rarity in ipairs(names) do
            result[rarity] = index
        end

        -- Preserve aliases that may exist on tools even if absent from PetsData.
        if result.Mythic and not result.Mythical then
            result.Mythical = result.Mythic
        elseif result.Mythical and not result.Mythic then
            result.Mythic = result.Mythical
        end

        return result
    end)()

local function selectedSellRarityCount()
    return #selectionAsArray(Config.AutoSellRarities)
end

local function rendererOwnedPets()
    local result = {}

    if type(PetRenderer) ~= "table"
        or type(PetRenderer.GetAll) ~= "function" then

        return result, "PetRenderer unavailable"
    end

    local ok, all =
        pcall(function()
            return PetRenderer.GetAll()
        end)

    if not ok or type(all) ~= "table" then
        return result, "PetRenderer.GetAll failed"
    end

    for _, entry in pairs(all) do
        if type(entry) == "table" then
            local ownerId =
                tonumber(entry.OwnerUserId)

            local petKey =
                entry.PetKey

            local model =
                entry.Model

            if ownerId == LP.UserId
                and petKey ~= nil
                and typeof(model) == "Instance"
                and model:IsA("Model")
                and model.Parent then

                local key = tostring(petKey)

                if key ~= ""
                    and not string.match(key, "^TUTORIAL_") then

                    result[#result + 1] = {
                        entry = entry,
                        model = model,
                        key = key,
                    }
                end
            end
        end
    end

    return result, nil
end


shared.SerenityRideAPet.FeedRuntime =
    shared.SerenityRideAPet.FeedRuntime
    or {
        MaxAgeKeys = {},
        Rejects = {},
        ActiveAttempt = nil,
        LastAttempt = nil,
    }

shared.SerenityRideAPet.RecordFeedNotification = function(textValue)
    local raw =
        tostring(textValue or "")

    local lower =
        string.lower(raw)

    local marker =
        " is already max age"

    local at =
        string.find(
            lower,
            marker,
            1,
            true
        )

    if not at then
        return false
    end

    local petName =
        raw:sub(1, at - 1)
            :gsub("^%s+", "")
            :gsub("%s+$", "")

    local runtime =
        shared.SerenityRideAPet.FeedRuntime

    local attempt =
        runtime.ActiveAttempt

    if not attempt then
        local last =
            runtime.LastAttempt

        if last
            and os.clock()
                - (tonumber(last.At) or 0)
                <= 2.5 then

            attempt = last
        end
    end

    if attempt
        and string.lower(
            tostring(attempt.Name or "")
        ) == string.lower(petName) then

        local key =
            tostring(attempt.Key or "")

        if key ~= "" then
            runtime.MaxAgeKeys[key] = {
                Model = attempt.Model,
                Name = attempt.Name,
                At = os.clock(),
            }

            runtime.Rejects[key] = nil

            if runtime.ActiveAttempt
                and tostring(
                    runtime.ActiveAttempt.Key
                ) == key then

                runtime.ActiveAttempt.MaxAge = true
            end
        end
    end

    return true
end

shared.SerenityRideAPet.IsFeedPetBlocked = function(pet)
    if type(pet) ~= "table" then
        return true
    end

    local runtime =
        shared.SerenityRideAPet.FeedRuntime

    local key =
        tostring(pet.key or "")

    if key == "" then
        return true
    end

    local lock =
        runtime.MaxAgeKeys[key]

    if lock then
        if lock.Model == pet.model
            and pet.model
            and pet.model.Parent then

            return true
        end

        -- Same key but a replaced/re-rendered pet: let it be tested again.
        runtime.MaxAgeKeys[key] = nil
    end

    local reject =
        runtime.Rejects[key]

    if reject then
        if os.clock()
            < (tonumber(reject.Until) or 0) then

            return true
        end

        runtime.Rejects[key] = nil
    end

    return false
end

local FeedPetRemote =
    GameRemotes:FindFirstChild("FeedPet")

local PetFedRemote =
    GameRemotes:FindFirstChild("PetFed")

local FEED_MIN_GAP = 0.32
local lastFeedAcceptedAt = nil
local feedRoundRobinIndex = 0

local function serverNow()
    local ok, value = pcall(function()
        return Workspace:GetServerTimeNow()
    end)

    return ok and tonumber(value) or os.clock()
end

local function foodAmount(tool)
    if not tool then
        return nil
    end

    local data = tool:FindFirstChild("Data")
    local amount = data and data:FindFirstChild("Amount")

    if amount and amount:IsA("ValueBase") then
        return tonumber((amount :: any).Value)
    end

    return nil
end

local function findToolByExactName(name)
    local char = LP.Character

    if char then
        for _, child in ipairs(char:GetChildren()) do
            if child:IsA("Tool")
                and child.Name == name then

                return child
            end
        end
    end

    local backpack =
        LP:FindFirstChildOfClass("Backpack")

    if backpack then
        for _, child in ipairs(backpack:GetChildren()) do
            if child:IsA("Tool")
                and child.Name == name then

                return child
            end
        end
    end

    return nil
end

local function selectedFeedFoodTool()
    for _, foodName in ipairs(selectionAsArray(Config.AutoFeedFoods)) do
        local tool = findToolByExactName(foodName)

        if tool then
            local amount = foodAmount(tool)

            if amount == nil or amount > 0 then
                return tool
            end
        end
    end

    return nil
end

local function equipFeedTool(tool)
    local char =
        LP.Character or LP.CharacterAdded:Wait()

    if tool.Parent == char then
        return true
    end

    local humanoid =
        char:FindFirstChildOfClass("Humanoid")

    if not humanoid then
        return false
    end

    humanoid:EquipTool(tool)

    local deadline = os.clock() + 0.8

    repeat
        if tool.Parent == char then
            return true
        end
        task.wait()
    until os.clock() >= deadline

    return tool.Parent == char
end

local function feedTargets()
    local pets = rendererOwnedPets()
    local targets = {}

    if type(pets) ~= "table" then
        return targets
    end

    local allPlaced =
        tostring(Config.AutoFeedTargetMode)
        == "All Placed Pets"

    for _, pet in ipairs(pets) do
        if (
            allPlaced
            or selectionHas(Config.AutoFeedPetKeys, pet.key)
        ) and not shared.SerenityRideAPet.IsFeedPetBlocked(pet) then

            targets[#targets + 1] = pet
        end
    end

    table.sort(targets, function(a, b)
        local an =
            tostring(
                a.model:GetAttribute("PetName")
                or a.model.Name
            )

        local bn =
            tostring(
                b.model:GetAttribute("PetName")
                or b.model.Name
            )

        if an ~= bn then
            return an < bn
        end

        return tostring(a.key) < tostring(b.key)
    end)

    return targets
end

local function autoFeedOne()
    if not FeedPetRemote
        or not FeedPetRemote:IsA("RemoteEvent")
        or not PetFedRemote
        or not PetFedRemote:IsA("RemoteEvent") then

        return false, "feed remotes unavailable"
    end

    if #selectionAsArray(Config.AutoFeedFoods) == 0 then
        return false, "no food selected"
    end

    local targets = feedTargets()

    if #targets == 0 then
        return false, "no feed targets"
    end

    feedRoundRobinIndex =
        (feedRoundRobinIndex % #targets) + 1

    local pet = targets[feedRoundRobinIndex]
    local food = selectedFeedFoodTool()

    if not food then
        return false, "selected food unavailable"
    end

    if not equipFeedTool(food) then
        return false, "food equip failed"
    end

    if lastFeedAcceptedAt then
        while serverNow() < lastFeedAcceptedAt + FEED_MIN_GAP do
            task.wait()
        end
    end

    local petKey = tostring(pet.key)
    local acceptedAt = nil

    local petName =
        tostring(
            pet.model:GetAttribute("PetName")
            or pet.model.Name
        )

    local feedRuntime =
        shared.SerenityRideAPet.FeedRuntime

    local attempt = {
        Key = petKey,
        Name = petName,
        Model = pet.model,
        At = os.clock(),
        MaxAge = false,
    }

    feedRuntime.ActiveAttempt = attempt
    feedRuntime.LastAttempt = attempt

    local connection =
        PetFedRemote.OnClientEvent:Connect(function(payload)
            if type(payload) == "table"
                and tostring(payload.PetKey) == petKey then

                acceptedAt = serverNow()
            end
        end)

    local firedAt = serverNow()

    local ok = pcall(function()
        FeedPetRemote:FireServer(
            pet.key,
            food.Name
        )
    end)

    if not ok then
        connection:Disconnect()

        if feedRuntime.ActiveAttempt == attempt then
            feedRuntime.ActiveAttempt = nil
        end

        return false, "feed request failed"
    end

    local deadline = firedAt + 0.9

    repeat
        if acceptedAt then
            break
        end
        task.wait()
    until serverNow() >= deadline

    connection:Disconnect()

    if feedRuntime.ActiveAttempt == attempt then
        feedRuntime.ActiveAttempt = nil
    end

    local maxLock =
        feedRuntime.MaxAgeKeys[petKey]

    if attempt.MaxAge == true
        or (
            maxLock
            and maxLock.Model == pet.model
        ) then

        feedRuntime.Rejects[petKey] = nil
        return false, "pet already max age"
    end

    if not acceptedAt then
        local previous =
            feedRuntime.Rejects[petKey]

        local count =
            (previous
                and tonumber(previous.Count)
                or 0)
            + 1

        local cooldown =
            count >= 3
            and 120
            or (
                count == 2
                and 30
                or 3
            )

        feedRuntime.Rejects[petKey] = {
            Count = count,
            Until = os.clock() + cooldown,
        }

        return false, "feed not acknowledged"
    end

    feedRuntime.Rejects[petKey] = nil
    lastFeedAcceptedAt = acceptedAt

    return true, petKey
end

local FeedPetOptionToKey = {}
local FeedPetKeyToOption = {}
local DynamicFeedPetOptions = {}

local function rebuildFeedPetOptions()
    table.clear(FeedPetOptionToKey)
    table.clear(FeedPetKeyToOption)
    table.clear(DynamicFeedPetOptions)

    local pets = rendererOwnedPets()
    if type(pets) ~= "table" then
        return
    end

    local duplicateCount = {}

    for _, pet in ipairs(pets) do
        local model = pet.model
        local petName =
            tostring(
                model:GetAttribute("PetName")
                or model.Name
            )

        local age =
            model:GetAttribute("Age")

        if age == nil and type(pet.entry) == "table" then
            age = pet.entry.CurrentAge
        end

        local baseLabel =
            petName
            .. " (Age "
            .. tostring(age or "?")
            .. ")"

        duplicateCount[baseLabel] =
            (duplicateCount[baseLabel] or 0) + 1

        local label = baseLabel

        if duplicateCount[baseLabel] > 1 then
            label =
                baseLabel
                .. " #"
                .. tostring(duplicateCount[baseLabel])
        end

        local key = tostring(pet.key)

        FeedPetOptionToKey[label] = key
        FeedPetKeyToOption[key] = label
        DynamicFeedPetOptions[#DynamicFeedPetOptions + 1] = label
    end

    table.sort(DynamicFeedPetOptions)
end

local function savedFeedPetLabels()
    local labels = {}

    for _, key in ipairs(selectionAsArray(Config.AutoFeedPetKeys)) do
        local label = FeedPetKeyToOption[tostring(key)]
        if label then
            labels[#labels + 1] = label
        end
    end

    table.sort(labels)
    return labels
end

local function feedLabelsToKeys(value)
    local keys = {}

    for _, label in ipairs(selectionAsArray(value)) do
        local key = FeedPetOptionToKey[tostring(label)]
        if key then
            keys[#keys + 1] = key
        end
    end

    table.sort(keys)
    return keys
end

shared.SerenityRideAPet.RefreshFeedGarden = function(target)
    rebuildFeedPetOptions()

    local kept = {}

    for _, key in ipairs(selectionAsArray(Config.AutoFeedPetKeys)) do
        if FeedPetKeyToOption[tostring(key)] then
            kept[#kept + 1] = tostring(key)
        end
    end

    Config.AutoFeedPetKeys = kept
    saveConfig()

    local controls = nil

    if target then
        controls =
            target.Controls
            or (
                target.Adapter
                and target.Adapter.Controls
            )
            or (
                target.Window
                and target.Window.Controls
            )
    end

    local control =
        controls
        and controls["Pets.AutoFeed.Pets"]

    if control then
        -- Serenity V3 Select/MultiSelect uses :Refresh(options, preserve).
        if type(control.Refresh) == "function" then
            pcall(function()
                control:Refresh(
                    DynamicFeedPetOptions,
                    true
                )
            end)
        elseif type(control.SetOptions) == "function" then
            -- Compatibility fallback for older adapters.
            pcall(function()
                control:SetOptions(
                    DynamicFeedPetOptions,
                    true
                )
            end)
        end
    end

    return #DynamicFeedPetOptions
end

local function sellCandidate()
    local selectedRarityCount = selectedSellRarityCount()
    local maximumPerSecond = shared.SerenityRideAPet.MaximumSellPerSecond()

    if selectedRarityCount == 0 then
        return nil, "no sell rarities selected", {
            owned = 0,
            selectedRarities = 0,
            matchingRarity = 0,
            protected = 0,
            eligible = 0,
        }
    end

    local renderedOwned, rendererErr = rendererOwnedPets()
    if rendererErr then
        renderedOwned = {}
    end

    local gardenKeys = {}
    for _, pet in ipairs(renderedOwned) do
        gardenKeys[tostring(pet.key)] = true
    end

    local candidates = {}
    local matchingRarity = 0
    local protected = 0
    local rateFiltered = 0
    local rateUnknown = 0
    local inventoryOwned = 0
    local rarityBreakdown = {}

    -- Sell UNEQUIPPED pet Tools first. Garden pets stay protected by default.
    for _, tool in ipairs(Backpack:GetChildren()) do
        if tool:IsA("Tool") then
            local key = tool:GetAttribute("PetKey")

            if key ~= nil
                and tostring(key) ~= ""
                and not string.match(tostring(key), "^TUTORIAL_") then

                key = tostring(key)

                if not gardenKeys[key] then
                    inventoryOwned += 1

                    local petName = tostring(
                        tool:GetAttribute("PetName")
                        or tool.Name
                    )

                    local cfg =
                        type(PetsData) == "table"
                        and (PetsData[petName] or PetsData[tool.Name])
                        or nil

                    local rarity = tostring(
                        (type(cfg) == "table" and cfg.Rarity)
                        or tool:GetAttribute("Rarity")
                        or ""
                    )

                    rarityBreakdown[rarity] =
                        (rarityBreakdown[rarity] or 0) + 1

                    if selectionHas(Config.AutoSellRarities, rarity) then
                        matchingRarity += 1

                        if petIsProtected(nil, key, tool) then
                            protected += 1
                        else
                            local view = {
                                key = key,
                                entry = nil,
                                model = nil,
                            }

                            local perSecond =
                                shared.SerenityRideAPet.PetPerSecondValue(view, tool)

                            local passesRate = true

                            if maximumPerSecond > 0 then
                                if perSecond == nil then
                                    passesRate = false
                                    rateUnknown += 1
                                elseif perSecond > maximumPerSecond then
                                    passesRate = false
                                    rateFiltered += 1
                                end
                            end

                            if passesRate then
                                local score = 0
                                if type(cfg) == "table" then
                                    score = tonumber(
                                        cfg.Value
                                        or cfg.Cost
                                        or cfg.Price
                                        or cfg.SellPrice
                                        or cfg.Income
                                        or cfg.Multiplier
                                        or 0
                                    ) or 0
                                end

                                candidates[#candidates + 1] = {
                                    source = "inventory",
                                    tool = tool,
                                    entry = nil,
                                    model = nil,
                                    key = key,
                                    name = petName,
                                    rarity = rarity,
                                    rarityRank = SELL_RARITY_ORDER[rarity] or 999,
                                    score = score,
                                    perSecond = perSecond,
                                    position = nil,
                                }
                            end
                        end
                    end
                end
            end
        end
    end

    -- Compatibility path: only sell placed garden pets if protection is explicitly OFF.
    if Config.AutoSellProtectGardenPets == false then
        for _, pet in ipairs(renderedOwned) do
            local model = pet.model
            local rarity = petRarity(model)

            rarityBreakdown[rarity] =
                (rarityBreakdown[rarity] or 0) + 1

            if selectionHas(Config.AutoSellRarities, rarity) then
                matchingRarity += 1

                if petIsProtected(model, pet.key, nil) then
                    protected += 1
                else
                    local perSecond =
                        shared.SerenityRideAPet.PetPerSecondValue(pet)

                    local passesRate = true
                    if maximumPerSecond > 0 then
                        if perSecond == nil then
                            passesRate = false
                            rateUnknown += 1
                        elseif perSecond > maximumPerSecond then
                            passesRate = false
                            rateFiltered += 1
                        end
                    end

                    if passesRate then
                        local ok, pivot = pcall(function()
                            return model:GetPivot()
                        end)

                        if ok then
                            local cfg =
                                type(PetsData) == "table"
                                and PetsData[model.Name]
                                or nil

                            local score = 0
                            if type(cfg) == "table" then
                                score = tonumber(
                                    cfg.Value
                                    or cfg.Cost
                                    or cfg.Price
                                    or cfg.SellPrice
                                    or cfg.Income
                                    or cfg.Multiplier
                                    or 0
                                ) or 0
                            end

                            candidates[#candidates + 1] = {
                                source = "garden",
                                tool = nil,
                                entry = pet.entry,
                                model = model,
                                key = pet.key,
                                name = model.Name,
                                rarity = rarity,
                                rarityRank = SELL_RARITY_ORDER[rarity] or 999,
                                score = score,
                                perSecond = perSecond,
                                position = pivot.Position,
                            }
                        end
                    end
                end
            end
        end
    end

    table.sort(candidates, function(a, b)
        if a.source ~= b.source then
            return a.source == "inventory"
        end

        if a.rarityRank ~= b.rarityRank then
            return a.rarityRank < b.rarityRank
        end

        if a.perSecond ~= b.perSecond then
            if a.perSecond == nil then
                return false
            elseif b.perSecond == nil then
                return true
            end
            return a.perSecond < b.perSecond
        end

        if a.score ~= b.score then
            return a.score < b.score
        end

        if a.name ~= b.name then
            return a.name < b.name
        end

        return a.key < b.key
    end)

    local stats = {
        owned = inventoryOwned + #renderedOwned,
        inventoryOwned = inventoryOwned,
        gardenOwned = #renderedOwned,
        selectedRarities = selectedRarityCount,
        matchingRarity = matchingRarity,
        protected = protected,
        rateFiltered = rateFiltered,
        rateUnknown = rateUnknown,
        eligible = #candidates,
        rarityBreakdown = rarityBreakdown,
    }

    if candidates[1] then
        return candidates[1], nil, stats
    end

    if inventoryOwned == 0
        and Config.AutoSellProtectGardenPets ~= false then
        return nil, "no unequipped inventory pets to sell", stats
    end

    if matchingRarity == 0 then
        return nil, "owned pets exist but none match selected rarity", stats
    end

    if protected >= matchingRarity then
        return nil, "all matching pets are protected", stats
    end

    return nil, "matching pets exist but none are sellable", stats
end

local function findPetToolByKey(key)
    for _, root in ipairs({Character, Backpack}) do
        if root then
            for _, child in ipairs(root:GetChildren()) do
                if child:IsA("Tool")
                    and tostring(child:GetAttribute("PetKey"))
                        == tostring(key) then

                    return child
                end
            end
        end
    end

    return nil
end

-- ============================================================
-- WEATHER PET SWAP
--
-- Weather names are user-entered instead of hardcoded. Ride A Pet builds may
-- expose the active weather through replicated values/attributes or a weather
-- UI label; this resolver uses those live sources without polling all UI text.
--
-- When a configured weather begins:
--   1) snapshot current placed pets + positions,
--   2) pick up non-selected placed pets,
--   3) place the selected pets into the available farm slots.
-- When the weather ends, the previous layout is restored if enabled.
--
-- v80.2.60:
-- This entire subsystem is intentionally compiled in its OWN function scope.
-- The old `do ... end` block still consumed locals from the already-near-limit
-- production chunk, which is why different executors reported failures such as
-- WeatherPetKeyToOption exceeding Luau's 200-local-register ceiling.
-- ============================================================

function shared.SerenityRideAPet.InitWeatherSubsystem()
    local Feature =
        shared.SerenityRideAPet.WeatherFeature
        or {}

    shared.SerenityRideAPet.WeatherFeature =
        Feature

    local WeatherPetOptionToKey = {}
local WeatherPetKeyToOption = {}
local DynamicWeatherPetOptions = {}

    Feature.PetOptions = DynamicWeatherPetOptions

    Feature.MutationFieldNames = {
        "WeatherMutation",
        "Mutation",
        "SpawnMutation",
        "HatchedMutation",
        "HatchMutation",
        "WeatherTrait",
        "Trait",
        "Mutations",
        "Traits",
    }

    Feature.PetMutationInfo = function(pet, tool)
        local names = {}
        local seen = {}

        local function addName(value, fallbackName)
            if typeof(value) == "Instance"
                and value:IsA("ValueBase") then
                value = (value :: any).Value
            end

            if type(value) == "boolean" then
                if value == true and fallbackName then
                    local lower = string.lower(tostring(fallbackName))
                    if not seen[lower] then
                        seen[lower] = true
                        names[#names + 1] = tostring(fallbackName)
                    end
                end
                return
            end

            if type(value) == "table" then
                for k, v in pairs(value) do
                    if type(v) == "string" or type(v) == "number" then
                        addName(v, k)
                    elseif v == true then
                        addName(k, k)
                    elseif type(v) == "table" then
                        addName(v, k)
                    end
                end
                return
            end

            local raw = tostring(value or "")
                :gsub("^%s+", "")
                :gsub("%s+$", "")

            if raw == ""
                or raw == "0"
                or string.lower(raw) == "none"
                or string.lower(raw) == "nil"
                or string.lower(raw) == "normal"
                or string.lower(raw) == "default"
                or string.lower(raw) == "base"
                or string.lower(raw) == "false" then
                return
            end

            local lower = string.lower(raw)

            if not seen[lower] then
                seen[lower] = true
                names[#names + 1] = raw
            end
        end

        local function inspectTable(tbl)
            if type(tbl) ~= "table" then
                return
            end

            for _, field in ipairs(Feature.MutationFieldNames) do
                addName(tbl[field], field)
            end

            for field, value in pairs(tbl) do
                local lower = string.lower(tostring(field))

                if (
                    string.find(lower, "mutation", 1, true)
                    or string.find(lower, "trait", 1, true)
                )
                    and not string.find(lower, "multiplier", 1, true)
                    and not string.find(lower, "chance", 1, true)
                    and not string.find(lower, "boost", 1, true)
                    and not string.find(lower, "rate", 1, true) then

                    addName(value, field)
                end
            end
        end

        local function inspectInstance(inst)
            if typeof(inst) ~= "Instance" then
                return
            end

            for _, field in ipairs(Feature.MutationFieldNames) do
                addName(inst:GetAttribute(field), field)
            end

            for field, value in pairs(inst:GetAttributes()) do
                local lower = string.lower(tostring(field))

                if (
                    string.find(lower, "mutation", 1, true)
                    or string.find(lower, "trait", 1, true)
                )
                    and not string.find(lower, "multiplier", 1, true)
                    and not string.find(lower, "chance", 1, true)
                    and not string.find(lower, "boost", 1, true)
                    and not string.find(lower, "rate", 1, true) then

                    addName(value, field)
                end
            end

            local data = inst:FindFirstChild("Data")

            if data then
                for _, field in ipairs(Feature.MutationFieldNames) do
                    local child = data:FindFirstChild(field)

                    if child and child:IsA("ValueBase") then
                        addName((child :: any).Value, field)
                    end

                    addName(data:GetAttribute(field), field)
                end
            end

            for _, holderName in ipairs({
                "MutationHitbox",
                "SpawnMutationHitbox",
            }) do
                local holder = inst:FindFirstChild(holderName)

                if holder then
                    local activeEffect = false

                    for _, effect in ipairs(holder:GetDescendants()) do
                        if (
                            effect:IsA("ParticleEmitter")
                            or effect:IsA("Beam")
                            or effect:IsA("Trail")
                            or effect:IsA("PointLight")
                            or effect:IsA("SpotLight")
                            or effect:IsA("SurfaceLight")
                        ) and effect.Enabled == true then
                            activeEffect = true
                            break
                        end
                    end

                    if activeEffect then
                        addName(holderName, holderName)
                    end
                end
            end
        end

        if type(pet) == "table" then
            inspectTable(pet.entry)
            inspectInstance(pet.model)
        end

        inspectInstance(tool)

        table.sort(names)

        return {
            HasMutation = #names > 0,
            Names = names,
            Text = #names > 0
                and table.concat(names, ", ")
                or "None",
        }
    end

    Feature.OwnedPetCandidates = function()
        local byKey = {}

        for _, pet in ipairs(rendererOwnedPets()) do
            local key = tostring(pet.key)
            local model = pet.model

            local name = tostring(
                model:GetAttribute("PetName")
                or model.Name
            )

            local age = model:GetAttribute("Age")

            if age == nil and type(pet.entry) == "table" then
                age = pet.entry.CurrentAge
            end

            local rarity = petRarity(model)
            local mutation =
                Feature.PetMutationInfo(pet, nil)

            byKey[key] = {
                Key = key,
                Name = name,
                Age = tonumber(age) or 0,
                Source = "Garden",
                Pet = pet,
                Tool = nil,
                Rarity = rarity,
                RarityRank = SELL_RARITY_ORDER[rarity] or 0,
                PerSecond =
                    shared.SerenityRideAPet.PetPerSecondValue(
                        pet,
                        nil
                    ),
                Mutation = mutation,
            }
        end

        for _, root in ipairs({
            LP:FindFirstChildOfClass("Backpack"),
            LP.Character,
        }) do
            if root then
                for _, tool in ipairs(root:GetChildren()) do
                    if tool:IsA("Tool")
                        and tool:GetAttribute("PetKey") ~= nil then

                        local key =
                            tostring(
                                tool:GetAttribute("PetKey")
                            )

                        if key ~= ""
                            and not string.match(
                                key,
                                "^TUTORIAL_"
                            )
                            and not byKey[key] then

                            local name =
                                tostring(
                                    tool:GetAttribute("PetName")
                                    or tool.Name
                                )

                            local age =
                                tool:GetAttribute("Age")

                            local toolData =
                                tool:FindFirstChild("Data")

                            if age == nil and toolData then
                                local ageValue =
                                    toolData:FindFirstChild("Age")

                                if ageValue
                                    and ageValue:IsA("ValueBase") then

                                    age = (ageValue :: any).Value
                                else
                                    age =
                                        toolData:GetAttribute("Age")
                                end
                            end

                            local cfg =
                                type(PetsData) == "table"
                                and (
                                    PetsData[name]
                                    or PetsData[tool.Name]
                                )
                                or nil

                            local rarity =
                                tostring(
                                    (type(cfg) == "table" and cfg.Rarity)
                                    or tool:GetAttribute("Rarity")
                                    or ""
                                )

                            local view = {
                                key = key,
                                entry = nil,
                                model = nil,
                            }

                            byKey[key] = {
                                Key = key,
                                Name = name,
                                Age = tonumber(age) or 0,
                                Source = "Inventory",
                                Pet = view,
                                Tool = tool,
                                Rarity = rarity,
                                RarityRank =
                                    SELL_RARITY_ORDER[rarity] or 0,
                                PerSecond =
                                    shared.SerenityRideAPet.PetPerSecondValue(
                                        view,
                                        tool
                                    ),
                                Mutation =
                                    Feature.PetMutationInfo(
                                        nil,
                                        tool
                                    ),
                            }
                        end
                    end
                end
            end
        end

        local rows = {}

        for _, row in pairs(byKey) do
            rows[#rows + 1] = row
        end

        return rows
    end

local function weatherPetNameAndAgeFromTool(tool)
    local name =
        tostring(
            tool:GetAttribute("PetName")
            or tool.Name
        )

    local age =
        tool:GetAttribute("Age")

    local data =
        tool:FindFirstChild("Data")

    if age == nil and data then
        local ageValue =
            data:FindFirstChild("Age")

        if ageValue and ageValue:IsA("ValueBase") then
            age = (ageValue :: any).Value
        else
            age = data:GetAttribute("Age")
        end
    end

    return name, age
end

local function rebuildWeatherPetOptions()
    table.clear(WeatherPetOptionToKey)
    table.clear(WeatherPetKeyToOption)
    table.clear(DynamicWeatherPetOptions)

    local byKey = {}

    for _, pet in ipairs(rendererOwnedPets()) do
        local key =
            tostring(pet.key)

        local model =
            pet.model

        local name =
            tostring(
                model:GetAttribute("PetName")
                or model.Name
            )

        local age =
            model:GetAttribute("Age")

        if age == nil
            and type(pet.entry) == "table" then

            age = pet.entry.CurrentAge
        end

        byKey[key] = {
            Key = key,
            Name = name,
            Age = age,
            Source = "Garden",
            Pet = pet,
            Tool = nil,
        }
    end

    for _, root in ipairs({
        LP:FindFirstChildOfClass("Backpack"),
        LP.Character,
    }) do
        if root then
            for _, tool in ipairs(root:GetChildren()) do
                if tool:IsA("Tool")
                    and tool:GetAttribute("PetKey") ~= nil then

                    local key =
                        tostring(
                            tool:GetAttribute("PetKey")
                        )

                    if key ~= ""
                        and not string.match(
                            key,
                            "^TUTORIAL_"
                        ) then

                        local name, age =
                            weatherPetNameAndAgeFromTool(
                                tool
                            )

                        if not byKey[key] then
                            byKey[key] = {
                                Key = key,
                                Name = name,
                                Age = age,
                                Source = "Inventory",
                                Pet = nil,
                                Tool = tool,
                            }
                        end
                    end
                end
            end
        end
    end

    local duplicateCount = {}

    local rows = {}

    for _, pet in pairs(byKey) do
        rows[#rows + 1] = pet
    end

    table.sort(rows, function(a, b)
        if a.Name ~= b.Name then
            return a.Name < b.Name
        end

        return a.Key < b.Key
    end)

    for _, pet in ipairs(rows) do
        local mutation =
            Feature.PetMutationInfo(
                pet.Pet,
                pet.Tool
            )

        local mutationText =
            mutation
            and mutation.Text
            or "None"

        local base =
            tostring(pet.Name)
            .. " (Age "
            .. tostring(pet.Age or "?")
            .. ")"
            .. " [Mutation: "
            .. tostring(mutationText)
            .. "]"

        duplicateCount[base] =
            (duplicateCount[base] or 0)
            + 1

        local label =
            base
            .. " ["
            .. tostring(pet.Source)
            .. "]"

        if duplicateCount[base] > 1 then
            label =
                label
                .. " #"
                .. tostring(duplicateCount[base])
        end

        WeatherPetOptionToKey[label] =
            pet.Key

        WeatherPetKeyToOption[pet.Key] =
            label

        DynamicWeatherPetOptions[
            #DynamicWeatherPetOptions + 1
        ] = label
    end
end

local function savedWeatherPetLabels()
    local labels = {}

    for _, key in ipairs(
        selectionAsArray(
            Config.WeatherPetKeys
        )
    ) do
        local label =
            WeatherPetKeyToOption[
                tostring(key)
            ]

        if label then
            labels[#labels + 1] =
                label
        end
    end

    table.sort(labels)
    return labels
end

local function weatherPetLabelsToKeys(value)
    local keys = {}

    for _, label in ipairs(
        selectionAsArray(value)
    ) do
        local key =
            WeatherPetOptionToKey[
                tostring(label)
            ]

        if key then
            keys[#keys + 1] =
                tostring(key)
        end
    end

    table.sort(keys)
    return keys
end

Feature.SavedPetLabels =
    savedWeatherPetLabels

Feature.LabelsToKeys =
    weatherPetLabelsToKeys

Feature.RebuildPetOptions =
    rebuildWeatherPetOptions

Feature.ResolveAutomaticPetKeys = function(slotCount)
    local candidates =
        Feature.OwnedPetCandidates()

    table.sort(candidates, function(a, b)
        local aMutated =
            a.Mutation
            and a.Mutation.HasMutation == true

        local bMutated =
            b.Mutation
            and b.Mutation.HasMutation == true

        if aMutated ~= bMutated then
            return aMutated == false
        end

        local aRate = tonumber(a.PerSecond)
        local bRate = tonumber(b.PerSecond)

        if aRate ~= bRate then
            if aRate == nil then
                return false
            elseif bRate == nil then
                return true
            end

            return aRate > bRate
        end

        if tonumber(a.RarityRank) ~= tonumber(b.RarityRank) then
            return (tonumber(a.RarityRank) or 0)
                > (tonumber(b.RarityRank) or 0)
        end

        if tonumber(a.Age) ~= tonumber(b.Age) then
            return (tonumber(a.Age) or 0)
                > (tonumber(b.Age) or 0)
        end

        return tostring(a.Key) < tostring(b.Key)
    end)

    local count =
        math.max(
            0,
            math.floor(
                tonumber(slotCount) or 0
            )
        )

    if count <= 0 then
        count =
            math.min(
                #candidates,
                math.max(
                    1,
                    #rendererOwnedPets()
                )
            )
    end

    local keys = {}

    for i = 1, math.min(count, #candidates) do
        keys[#keys + 1] =
            tostring(candidates[i].Key)
    end

    return keys, candidates
end

Feature.ResolveSelectedPetKeys = function(snapshot)
    if Config.WeatherAutoHighestNoMutation == true then
        return Feature.ResolveAutomaticPetKeys(
            type(snapshot) == "table"
            and #snapshot
            or 0
        )
    end

    return selectionAsArray(
        Config.WeatherPetKeys
    )
end

shared.SerenityRideAPet.RefreshWeatherPets = function(target)
    rebuildWeatherPetOptions()

    local kept = {}

    for _, key in ipairs(
        selectionAsArray(
            Config.WeatherPetKeys
        )
    ) do
        key = tostring(key)

        if WeatherPetKeyToOption[key] then
            kept[#kept + 1] = key
        end
    end

    Config.WeatherPetKeys = kept
    saveConfig()

    local controls = nil

    if target then
        controls =
            target.Controls
            or (
                target.Adapter
                and target.Adapter.Controls
            )
            or (
                target.Window
                and target.Window.Controls
            )
    end

    local control =
        controls
        and controls[
            "Pets.WeatherPetSwap.Pets"
        ]

    if control
        and type(control.Refresh) == "function" then

        pcall(function()
            control:Refresh(
                DynamicWeatherPetOptions,
                true
            )
        end)
    end

    return #DynamicWeatherPetOptions
end

shared.SerenityRideAPet.WeatherRuntime =
    shared.SerenityRideAPet.WeatherRuntime
    or {
        Sources = {},
        LastDiscovery = 0,
        Current = "Unknown",
        Active = false,
        Snapshot = nil,
        LastActionAt = 0,
        LastEnsureAt = 0,
    }

local WEATHER_VARIANT_OPTIONS = {}
local WEATHER_VARIANT_SET = {}

local function addWeatherVariant(name)
    name = tostring(name or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then return end
    local lower = string.lower(name)
    if WEATHER_VARIANT_SET[lower] then return end
    WEATHER_VARIANT_SET[lower] = name
    WEATHER_VARIANT_OPTIONS[#WEATHER_VARIANT_OPTIONS + 1] = name
end

-- Exact source discovered by recon: GameData.Weather.Data contains the
-- storm variants used by the game's weather command. Mutation labels such as
-- Volted/Shocked/Rage/Void are NOT weather variant names.
do
    local ok, data = pcall(function()
        local gameData = ReplicatedStorage:FindFirstChild("GameData")
        local module = gameData and gameData:FindFirstChild("Weather")
        if not module or not module:IsA("ModuleScript") then return nil end
        return require(module)
    end)

    if ok and type(data) == "table" and type(data.Data) == "table" then
        for name in pairs(data.Data) do
            addWeatherVariant(name)
        end
    end

    if #WEATHER_VARIANT_OPTIONS == 0 then
        for _, name in ipairs({
            "Thunder", "Volt", "Dreadful", "Gigantuar", "Raging", "Eternal",
        }) do
            addWeatherVariant(name)
        end
    end

    table.sort(WEATHER_VARIANT_OPTIONS)
end

Feature.Options = WEATHER_VARIANT_OPTIONS
Feature.OptionSet = WEATHER_VARIANT_SET

if type(Config.WeatherVariants) ~= "table" then
    Config.WeatherVariants = {}
end

if #selectionAsArray(Config.WeatherVariants) == 0 then
    local legacy =
        tostring(
            Config.WeatherPetNames
            or ""
        )
        :gsub("^%s+", "")
        :gsub("%s+$", "")

    if string.lower(legacy) == "volted" then
        legacy = "Volt"
    end

    local canonical =
        legacy ~= ""
        and WEATHER_VARIANT_SET[
            string.lower(legacy)
        ]
        or nil

    if canonical then
        Config.WeatherVariants = {
            canonical,
        }
    end
end

if tostring(Config.WeatherPetMode) ~= "Manual"
    and tostring(Config.WeatherPetMode) ~= "Automatic" then

    Config.WeatherPetMode = "Manual"
end

if Config.WeatherPetMode == "Automatic" then
    Config.WeatherAutoHighestNoMutation = true
end

saveConfig()

-- Migrate the one unambiguous v2.35 mistake.
if string.lower(tostring(Config.WeatherPetNames or "")) == "volted" then
    Config.WeatherPetNames = "Volt"
    saveConfig()
end

-- Keep only actual storm variants in the v2.37 multi-selection.
do
    local cleaned = {}

    for _, selected in ipairs(
        selectionAsArray(
            Config.WeatherVariants
        )
    ) do
        local canonical =
            WEATHER_VARIANT_SET[
                string.lower(
                    tostring(selected)
                )
            ]

        if canonical then
            cleaned[#cleaned + 1] =
                canonical
        end
    end

    Config.WeatherVariants =
        cleaned

    saveConfig()
end

shared.SerenityRideAPet.WeatherRuntime =
    shared.SerenityRideAPet.WeatherRuntime
    or {
        Active = false,
        Snapshot = nil,
        LastActionAt = 0,
        LastEnsureAt = 0,
        ActiveVariants = {},
        Connections = {},
        SuspendAutoEquipBest = false,
        Transitioning = false,
    }

do
    local runtime = shared.SerenityRideAPet.WeatherRuntime
    for _, connection in ipairs(runtime.Connections or {}) do
        pcall(function() connection:Disconnect() end)
    end
    runtime.Connections = {}
    runtime.ActiveVariants = {}

end

local function canonicalWeatherVariant(value)
    if type(value) ~= "string" then return nil end
    local raw = value:gsub("^%s+", ""):gsub("%s+$", "")
    if raw == "" then return nil end
    return WEATHER_VARIANT_SET[string.lower(raw)]
end

local function extractWeatherVariants(value, output, visited, depth)
    output = output or {}
    visited = visited or {}
    depth = tonumber(depth) or 0
    if depth > 7 then return output end

    if type(value) == "string" then
        local exact = canonicalWeatherVariant(value)
        if exact then
            output[exact] = true
            return output
        end

        local trimmed = value:gsub("^%s+", ""):gsub("%s+$", "")
        if string.sub(trimmed,1,1) == "{" or string.sub(trimmed,1,1) == "[" then
            local ok, decoded = pcall(function() return HttpService:JSONDecode(trimmed) end)
            if ok then extractWeatherVariants(decoded, output, visited, depth + 1) end
        end
        return output
    end

    if type(value) ~= "table" or visited[value] then return output end
    visited[value] = true

    for key, nested in pairs(value) do
        if type(key) == "string" then
            local exactKey = canonicalWeatherVariant(key)
            if exactKey then output[exactKey] = true end
        end
        extractWeatherVariants(nested, output, visited, depth + 1)
    end
    return output
end

local function weatherServerData()
    return ReplicatedStorage:FindFirstChild("ServerData")
end

local function syncActiveWeatherAttribute()
    local data = weatherServerData()
    if not data then return false end
    local raw = data:GetAttribute("ActiveWeathers")
    if raw == nil then return false end
    shared.SerenityRideAPet.WeatherRuntime.ActiveVariants = extractWeatherVariants(raw, {})
    return true
end

local function rememberWeatherConnection(connection)
    local runtime = shared.SerenityRideAPet.WeatherRuntime
    runtime.Connections[#runtime.Connections + 1] = connection
    return connection
end

syncActiveWeatherAttribute()

do
    local data = weatherServerData()
    if data then
        rememberWeatherConnection(data:GetAttributeChangedSignal("ActiveWeathers"):Connect(function()
            syncActiveWeatherAttribute()
        end))
    end

    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local gameRemotes = remotes and remotes:FindFirstChild("Game")
    local addWeather = gameRemotes and gameRemotes:FindFirstChild("AddWeather")
    local clearWeather = gameRemotes and gameRemotes:FindFirstChild("ClearWeather")

    if addWeather and addWeather:IsA("RemoteEvent") then
        rememberWeatherConnection(addWeather.OnClientEvent:Connect(function(...)
            local runtime = shared.SerenityRideAPet.WeatherRuntime
            local found = {}
            for i=1,select("#", ...) do
                extractWeatherVariants(select(i,...), found)
            end
            for variant in pairs(found) do runtime.ActiveVariants[variant] = true end
        end))
    end

    if clearWeather and clearWeather:IsA("RemoteEvent") then
        rememberWeatherConnection(clearWeather.OnClientEvent:Connect(function(...)
            local runtime = shared.SerenityRideAPet.WeatherRuntime
            local found = {}
            for i=1,select("#", ...) do
                extractWeatherVariants(select(i,...), found)
            end
            local any = false
            for variant in pairs(found) do
                any = true
                runtime.ActiveVariants[variant] = nil
            end
            if not any then table.clear(runtime.ActiveVariants) end
        end))
    end

end

shared.SerenityRideAPet.GetCurrentWeathers = function()
    local result = {}
    for variant in pairs(shared.SerenityRideAPet.WeatherRuntime.ActiveVariants or {}) do
        local exact = canonicalWeatherVariant(tostring(variant))
        if exact then result[#result + 1] = exact end
    end
    table.sort(result)
    return result
end

shared.SerenityRideAPet.GetCurrentWeather = function()
    return shared.SerenityRideAPet.GetCurrentWeathers()[1]
end

shared.SerenityRideAPet.DiscoverWeatherSources = function(_)
    syncActiveWeatherAttribute()
    return shared.SerenityRideAPet.GetCurrentWeathers()
end

local function configuredWeatherNames()
    local result = {}

    for _, selected in ipairs(
        selectionAsArray(
            Config.WeatherVariants
        )
    ) do
        local canonical =
            canonicalWeatherVariant(
                tostring(selected)
            )

        if canonical then
            result[#result + 1] =
                canonical
        end
    end

    return result
end

shared.SerenityRideAPet.WeatherMatches = function(current)
    local wanted = configuredWeatherNames()
    if #wanted == 0 then return false end
    local active = type(current) == "table" and current or (current ~= nil and {current} or shared.SerenityRideAPet.GetCurrentWeathers())
    local activeSet = {}
    for _, value in ipairs(active) do
        local exact = canonicalWeatherVariant(tostring(value))
        if exact then activeSet[string.lower(exact)] = true end
    end
    for _, wantedName in ipairs(wanted) do
        if activeSet[string.lower(wantedName)] then return true end
    end
    return false
end

local function currentGardenPetLayout()
    local layout = {}

    for _, pet in ipairs(
        rendererOwnedPets()
    ) do
        local ok, pivot =
            pcall(function()
                return pet.model:GetPivot()
            end)

        if ok then
            layout[#layout + 1] = {
                Key = tostring(pet.key),
                Position = pivot.Position,
                Name =
                    tostring(
                        pet.model:GetAttribute(
                            "PetName"
                        )
                        or pet.model.Name
                    ),
            }
        end
    end

    return layout
end

local function weatherFallbackPetPositions(count)
    local result = {}
    local plot = ownPlot()
    local base =
        ownPlotBaseplate(plot)

    if not base then
        return result
    end

    local spacing = 7
    local columns =
        math.max(
            1,
            math.ceil(
                math.sqrt(
                    math.max(
                        1,
                        count
                    )
                )
            )
        )

    for i = 1, count do
        local row =
            math.floor(
                (i - 1) / columns
            )

        local col =
            (i - 1) % columns

        local x =
            (col - (columns - 1) / 2)
            * spacing

        local z =
            (row - (columns - 1) / 2)
            * spacing

        result[#result + 1] =
            base.CFrame:PointToWorldSpace(
                Vector3.new(
                    x,
                    base.Size.Y / 2,
                    z
                )
            )
    end

    return result
end

local function gardenHasPetKey(key)
    key = tostring(key)

    for _, pet in ipairs(
        rendererOwnedPets()
    ) do
        if tostring(pet.key) == key then
            return true, pet
        end
    end

    return false, nil
end

local function waitPetGardenState(key, expected, timeout)
    local deadline =
        os.clock()
        + (tonumber(timeout) or 2)

    repeat
        local exists =
            gardenHasPetKey(key)

        if exists == expected then
            return true
        end

        task.wait(0.05)
    until os.clock() >= deadline

    return false
end

local function pickupGardenPetKey(key)
    if not PickupPetRemote then
        return false
    end

    if not gardenHasPetKey(key) then
        return true
    end

    local ok =
        pcall(function()
            PickupPetRemote:FireServer(
                tostring(key)
            )
        end)

    if not ok then
        return false
    end

    return waitPetGardenState(
        key,
        false,
        2.5
    )
end

local function placeWeatherPetKey(key, position)
    if not PlacePetRemote
        or typeof(position) ~= "Vector3" then

        return false
    end

    if gardenHasPetKey(key) then
        return true
    end

    if not findPetToolByKey(key) then
        return false
    end

    local ok =
        pcall(function()
            PlacePetRemote:FireServer(
                tostring(key),
                position
            )
        end)

    if not ok then
        return false
    end

    return waitPetGardenState(
        key,
        true,
        2.5
    )
end

shared.SerenityRideAPet.WeatherPetOverrideLocked = function()
    local runtime =
        shared.SerenityRideAPet.WeatherRuntime

    return runtime
        and (
            runtime.Active == true
            or runtime.Transitioning == true
            or runtime.SuspendAutoEquipBest == true
        )
end

shared.SerenityRideAPet.ApplyWeatherPetLayout = function()
    local runtime =
        shared.SerenityRideAPet.WeatherRuntime

    runtime.Transitioning = true
    runtime.SuspendAutoEquipBest = true

    if runtime.Snapshot == nil then
        runtime.Snapshot =
            currentGardenPetLayout()
    end

    local selected =
        Feature.ResolveSelectedPetKeys(
            runtime.Snapshot
        )

    if #selected == 0 then
        runtime.Transitioning = false
        runtime.SuspendAutoEquipBest = false

        return false,
            Config.WeatherAutoHighestNoMutation == true
            and "no owned pets available"
            or "no weather pets selected"
    end

    runtime.LastSelectedKeys =
        selected

    local wanted = {}

    for _, key in ipairs(selected) do
        wanted[tostring(key)] = true
    end

    local current =
        currentGardenPetLayout()

    -- Free slots first.
    for _, pet in ipairs(current) do
        if not wanted[
            tostring(pet.Key)
        ] then
            pickupGardenPetKey(
                pet.Key
            )
        end
    end

    local positions = {}

    for _, pet in ipairs(
        runtime.Snapshot
        or {}
    ) do
        positions[#positions + 1] =
            pet.Position
    end

    if #positions < #selected then
        local fallback =
            weatherFallbackPetPositions(
                #selected
            )

        for _, position in ipairs(
            fallback
        ) do
            positions[#positions + 1] =
                position
        end
    end

    local occupiedPositions = {}

    for _, pet in ipairs(
        currentGardenPetLayout()
    ) do
        local ok, rendered =
            gardenHasPetKey(
                pet.Key
            )

        if ok
            and rendered
            and rendered.model then

            local pivotOk, pivot =
                pcall(function()
                    return rendered.model:GetPivot()
                end)

            if pivotOk then
                occupiedPositions[
                    #occupiedPositions + 1
                ] = pivot.Position
            end
        end
    end

    local function choosePosition()
        for _, position in ipairs(
            positions
        ) do
            local clear = true

            for _, occupied in ipairs(
                occupiedPositions
            ) do
                if (
                    Vector3.new(
                        occupied.X - position.X,
                        0,
                        occupied.Z - position.Z
                    )
                ).Magnitude < 4 then
                    clear = false
                    break
                end
            end

            if clear then
                occupiedPositions[
                    #occupiedPositions + 1
                ] = position

                return position
            end
        end

        return positions[1]
    end

    local placed = 0

    for _, key in ipairs(selected) do
        key = tostring(key)

        if gardenHasPetKey(key) then
            placed += 1
        else
            local position =
                choosePosition()

            if position
                and placeWeatherPetKey(
                    key,
                    position
                ) then

                placed += 1
            end
        end
    end

    runtime.Active = true
    runtime.Transitioning = false
    runtime.SuspendAutoEquipBest = true
    runtime.LastActionAt =
        os.clock()

    return placed > 0, placed
end

shared.SerenityRideAPet.RestoreWeatherPetLayout = function()
    local runtime =
        shared.SerenityRideAPet.WeatherRuntime

    runtime.Transitioning = true
    runtime.SuspendAutoEquipBest = true

    local snapshot =
        runtime.Snapshot

    if type(snapshot) ~= "table" then
        runtime.Active = false
        runtime.Transitioning = false
        runtime.SuspendAutoEquipBest = false

        return true, 0
    end

    local original = {}

    for _, pet in ipairs(snapshot) do
        original[tostring(pet.Key)] =
            pet
    end

    for _, pet in ipairs(
        currentGardenPetLayout()
    ) do
        if not original[
            tostring(pet.Key)
        ] then

            pickupGardenPetKey(
                pet.Key
            )
        end
    end

    local restored = 0

    for _, pet in ipairs(snapshot) do
        if gardenHasPetKey(pet.Key)
            or placeWeatherPetKey(
                pet.Key,
                pet.Position
            ) then

            restored += 1
        end
    end

    runtime.Active = false
    runtime.Snapshot = nil
    runtime.Transitioning = false
    runtime.SuspendAutoEquipBest = false
    runtime.LastActionAt =
        os.clock()

    local equipState =
        shared.SerenityRideAPet.AutoEquipBestState

    if Config.AutoEquipBest == true
        and equipState then

        equipState.Pending = true
        equipState.LastSignature = nil
    end

    return true, restored
end

shared.SerenityRideAPet.WeatherPetLayoutActive = function()
    return shared.SerenityRideAPet.WeatherPetOverrideLocked()
end

Feature.MutationWebhookRuntime =
    Feature.MutationWebhookRuntime
    or {
        Generation = 0,
        Baseline = {},
        Pending = {},
        LastNotifiedAt = {},
    }

do
    local mutationRuntime =
        Feature.MutationWebhookRuntime

    mutationRuntime.Generation =
        (tonumber(
            mutationRuntime.Generation
        ) or 0)
        + 1

    mutationRuntime.Baseline = {}
    mutationRuntime.Pending = {}
    mutationRuntime.LastNotifiedAt = {}

    local generation =
        mutationRuntime.Generation

    task.spawn(function()
        local function cleanMutationText(info)
            if type(info) ~= "table"
                or info.HasMutation ~= true then

                return ""
            end

            local names = {}
            local seen = {}

            for _, rawName in ipairs(
                type(info.Names) == "table"
                and info.Names
                or {}
            ) do
                local name =
                    tostring(rawName or "")
                    :gsub("^%s+", "")
                    :gsub("%s+$", "")

                local lower =
                    string.lower(name)

                if name ~= ""
                    and lower ~= "mutationhitbox"
                    and lower ~= "spawnmutationhitbox"
                    and not seen[lower] then

                    seen[lower] = true
                    names[#names + 1] =
                        name
                end
            end

            table.sort(names)

            if #names > 0 then
                return
                    table.concat(
                        names,
                        ", "
                    )
            end

            return "Weather Mutation"
        end

        while mutationRuntime.Generation
            == generation do

            if Config.MutationWebhookEnabled
                ~= true then

                -- Do absolutely no OwnedPetCandidates/PetRenderer inventory
                -- scan while the webhook feature is off.
                if next(
                    mutationRuntime.Baseline
                ) ~= nil then

                    table.clear(
                        mutationRuntime.Baseline
                    )

                    table.clear(
                        mutationRuntime.Pending
                    )
                end

                task.wait(1.50)
                continue
            end

            local present = {}

            local ok, candidates =
                pcall(
                    Feature.OwnedPetCandidates
                )

            if ok
                and type(candidates)
                    == "table" then

                for _, pet in ipairs(
                    candidates
                ) do
                    if pet.Source
                        == "Garden" then

                        local key =
                            tostring(
                                pet.Key
                                or ""
                            )

                        if key ~= "" then
                            present[key] = true

                            local mutationText =
                                cleanMutationText(
                                    pet.Mutation
                                )

                            local previous =
                                mutationRuntime.Baseline[
                                    key
                                ]

                            if previous == nil then
                                mutationRuntime.Baseline[
                                    key
                                ] =
                                    mutationText

                            elseif mutationText
                                == previous then

                                mutationRuntime.Pending[
                                    key
                                ] = nil

                            elseif mutationText == "" then
                                mutationRuntime.Baseline[
                                    key
                                ] = ""

                                mutationRuntime.Pending[
                                    key
                                ] = nil

                            else
                                local pending =
                                    mutationRuntime.Pending[
                                        key
                                    ]

                                if not pending
                                    or pending.Text
                                        ~= mutationText then

                                    mutationRuntime.Pending[
                                        key
                                    ] = {
                                        Text =
                                            mutationText,
                                        Since =
                                            os.clock(),
                                    }

                                elseif os.clock()
                                    - (
                                        tonumber(
                                            pending.Since
                                        )
                                        or os.clock()
                                    )
                                    >= 0.70 then

                                    mutationRuntime.Baseline[
                                        key
                                    ] =
                                        mutationText

                                    mutationRuntime.Pending[
                                        key
                                    ] = nil

                                    local lastNotify =
                                        tonumber(
                                            mutationRuntime.LastNotifiedAt[
                                                key
                                            ]
                                        )
                                        or 0

                                    if Config.MutationWebhookEnabled
                                        == true
                                        and os.clock()
                                            - lastNotify
                                            >= 3 then

                                        mutationRuntime.LastNotifiedAt[
                                            key
                                        ] =
                                            os.clock()

                                        local weather =
                                            shared.SerenityRideAPet.GetCurrentWeathers()

                                        local data = {
                                            petName =
                                                tostring(
                                                    pet.Name
                                                    or "Unknown"
                                                ),
                                            mutation =
                                                mutationText,
                                            weather =
                                                #weather > 0
                                                and table.concat(
                                                    weather,
                                                    ", "
                                                )
                                                or "Unknown",
                                        }

                                        task.spawn(
                                            function()
                                                shared.SerenityRideAPet.SendMutationWebhook(
                                                    data
                                                )
                                            end
                                        )
                                    end
                                end
                            end
                        end
                    end
                end
            end

            for key in pairs(
                mutationRuntime.Baseline
            ) do
                if not present[key] then
                    mutationRuntime.Baseline[
                        key
                    ] = nil

                    mutationRuntime.Pending[
                        key
                    ] = nil
                end
            end

            task.wait(0.75)
        end
    end)
end

rebuildWeatherPetOptions()
end

-- Initialize once after definition. All Weather subsystem locals now belong to
-- InitWeatherSubsystem's independent Luau register frame.
shared.SerenityRideAPet.InitWeatherSubsystem()



shared.SerenityRideAPet.PlaceBestState =
    shared.SerenityRideAPet.PlaceBestState
    or {
        MaxSeen = 0,
        Calibrated = false,
        LastAttemptAt = 0,
        LastAttemptCount = nil,
    }

shared.SerenityRideAPet.TriggerNativePlaceBest = function()
    local playerGui = LP:FindFirstChildOfClass("PlayerGui")
    local main = playerGui and playerGui:FindFirstChild("Main")
    local tracker = main and main:FindFirstChild("PetsTracker")
    local placeBest = tracker and tracker:FindFirstChild("PlaceBest")

    if not placeBest then
        return false
    end

    local button =
        placeBest:IsA("GuiButton")
        and placeBest
        or placeBest:FindFirstChildWhichIsA("GuiButton", true)

    if not button then
        return false
    end

    local fireSignal = envfn("firesignal")
    if fireSignal then
        local ok = pcall(fireSignal, button.Activated)
        if ok then
            return true
        end
    end

    local getConnections = envfn("getconnections")
    if getConnections then
        local ok, connections = pcall(getConnections, button.Activated)
        if ok and type(connections) == "table" then
            for _, connection in ipairs(connections) do
                if type(connection.Fire) == "function" then
                    if pcall(function() connection:Fire() end) then
                        return true
                    end
                elseif type(connection.Function) == "function" then
                    if pcall(connection.Function) then
                        return true
                    end
                end
            end
        end
    end

    return false
end

shared.SerenityRideAPet.AutoPlaceBestAfterSell = function()
    if shared.SerenityRideAPet.WeatherPetOverrideLocked
        and shared.SerenityRideAPet.WeatherPetOverrideLocked() then

        return false, "weather pet override active"
    end

    local state = shared.SerenityRideAPet.PlaceBestState
    local pets = rendererOwnedPets()
    local count = type(pets) == "table" and #pets or 0

    state.MaxSeen = math.max(tonumber(state.MaxSeen) or 0, count)

    local needsAttempt =
        state.Calibrated ~= true
        or count < (tonumber(state.MaxSeen) or 0)

    if not needsAttempt then
        return false, "garden already full"
    end

    if state.LastAttemptCount == count
        and os.clock() - (tonumber(state.LastAttemptAt) or 0) < 3 then
        return false, "recent Place Best attempt"
    end

    state.LastAttemptCount = count
    state.LastAttemptAt = os.clock()

    local triggered = shared.SerenityRideAPet.TriggerNativePlaceBest()
    if not triggered then
        return false, "Place Best unavailable"
    end

    task.delay(0.8, function()
        local after = rendererOwnedPets()
        local afterCount = type(after) == "table" and #after or count
        state.MaxSeen = math.max(tonumber(state.MaxSeen) or 0, afterCount)
        state.Calibrated = true
    end)

    return true
end

shared.SerenityRideAPet.AutoEquipBestState =
    shared.SerenityRideAPet.AutoEquipBestState
    or {
        LastSignature = nil,
        LastAttemptAt = 0,
        Pending = true,
        LastFallbackCheckAt = 0,
    }

shared.SerenityRideAPet.PetLayoutSignature = function()
    local rows = {}

    for _, pet in ipairs(rendererOwnedPets()) do
        rows[#rows + 1] =
            "G:"
            .. tostring(pet.key)
    end

    for _, tool in ipairs(Backpack:GetChildren()) do
        if tool:IsA("Tool")
            and tool:GetAttribute("PetKey") ~= nil then

            rows[#rows + 1] =
                "B:"
                .. tostring(tool:GetAttribute("PetKey"))
        end
    end

    table.sort(rows)
    return table.concat(rows, "|")
end

shared.SerenityRideAPet.RequestAutoEquipBest = function(force)
    local state = shared.SerenityRideAPet.AutoEquipBestState

    if shared.SerenityRideAPet.WeatherPetOverrideLocked
        and shared.SerenityRideAPet.WeatherPetOverrideLocked() then

        state.Pending = true
        return false, "weather pet override active"
    end

    if Config.AutoEquipBest ~= true and force ~= true then
        return false, "disabled"
    end

    if shared.SerenityRideAPet.IsStealActionBusy() then
        state.Pending = true
        return false, "steal action busy"
    end

    if equipmentActionBusy then
        state.Pending = true
        return false, "equipment busy"
    end

    local signature =
        shared.SerenityRideAPet.PetLayoutSignature()

    if force ~= true
        and state.Pending ~= true
        and signature == state.LastSignature then

        return false, "unchanged"
    end

    if os.clock() - (tonumber(state.LastAttemptAt) or 0) < 0.80 then
        state.Pending = true
        return false, "cooldown"
    end

    state.LastAttemptAt = os.clock()
    state.Pending = false

    local triggered =
        shared.SerenityRideAPet.TriggerNativePlaceBest()

    if not triggered then
        state.Pending = true
        return false, "Place Best unavailable"
    end

    task.delay(0.85, function()
        state.LastSignature =
            shared.SerenityRideAPet.PetLayoutSignature()
    end)

    return true
end

local function getRichie()
    if cachedRichie and cachedRichie.Parent then
        return cachedRichie
    end

    -- Exact world path validated in earlier Auto Sell builds.
    local stalls =
        Workspace:FindFirstChild("Stalls")

    local sellStall =
        stalls and stalls:FindFirstChild("Sell")

    local worldRichie =
        sellStall and sellStall:FindFirstChild("Richie")

    if worldRichie then
        cachedRichie = worldRichie
        return worldRichie
    end

    -- Normal dialogue registry fallback.
    local DialogueFolder =
        ReplicatedStorage:FindFirstChild("Dialogue")

    local DialogueRemotes =
        DialogueFolder
        and DialogueFolder:FindFirstChild("Remotes")

    local RequestDialogues =
        DialogueRemotes
        and DialogueRemotes:FindFirstChild("RequestDialogues")

    if RequestDialogues then
        local ok, registered =
            pcall(function()
                return RequestDialogues:InvokeServer()
            end)

        if ok and type(registered) == "table" then
            for _, model in ipairs(registered) do
                if typeof(model) == "Instance"
                    and string.lower(model.Name) == "richie" then

                    cachedRichie = model
                    return model
                end
            end
        end
    end

    -- Bounded fallback: only inspect the Sell stall descendants.
    if sellStall then
        for _, obj in ipairs(sellStall:GetDescendants()) do
            if obj:IsA("Model")
                and string.lower(obj.Name) == "richie" then

                cachedRichie = obj
                return obj
            end
        end
    end

    return nil
end

shared.SerenityRideAPet.RichieSellContext = function()
    local richie = getRichie()

    if not richie or not richie.Parent then
        cachedRichie = nil
        return nil
    end

    local primary =
        richie.PrimaryPart
        or richie:FindFirstChild("HumanoidRootPart")
        or richie:FindFirstChildWhichIsA("BasePart")

    if not primary then
        cachedRichie = nil
        return nil
    end

    -- Prompt is optional HERE. It can stream/enable only after we move near.
    local prompt =
        primary:FindFirstChildOfClass("ProximityPrompt")
        or richie:FindFirstChildWhichIsA(
            "ProximityPrompt",
            true
        )

    return richie, primary, prompt
end

local function autoSellOne()
    local sellInterval =
        math.max(
            1,
            tonumber(Config.SellIntervalSeconds) or 8
        )

    if os.clock() - lastSellAction < sellInterval then
        return false, "sell cooldown"
    end

    local sellRuntime =
        shared.SerenityRideAPet.SellRuntime

    if os.clock()
        - (tonumber(sellRuntime.LastAttempt) or 0)
        < 0.65 then

        return false, "sell retry cooldown"
    end

    -- First confirm there is really something eligible to sell.
    -- Auto Sell being enabled by itself must never kick the user off a ride.
    local selected, selectReason, sellStats =
        sellCandidate()

    if not selected then
        if sellStats
            and os.clock()
                - (tonumber(
                    sellRuntime.LastNoCandidateLog
                ) or 0)
                >= 5 then

            sellRuntime.LastNoCandidateLog =
                os.clock()

            log("AutoSellRendererOwned=" .. tostring(sellStats.owned))
            log("AutoSellSelectedRarities=" .. tostring(sellStats.selectedRarities))
            log("AutoSellMatchingRarity=" .. tostring(sellStats.matchingRarity))
            log("AutoSellProtected=" .. tostring(sellStats.protected))
            log("AutoSellEligible=" .. tostring(sellStats.eligible))

            if type(sellStats.rarityBreakdown) == "table" then
                local parts = {}

                for rarity, count in pairs(sellStats.rarityBreakdown) do
                    parts[#parts + 1] =
                        tostring(rarity) .. ":" .. tostring(count)
                end

                table.sort(parts)
                log("AutoSellRendererRarities=" .. table.concat(parts, ","))
            end
        end

        return false, selectReason or "no eligible pet"
    end

    log("")
    log("=== AUTO_SELL_CANDIDATE ===")
    log("PetName=" .. tostring(selected.name))
    log("PetKey=" .. tostring(selected.key))
    log("PetRarity=" .. tostring(selected.rarity))
    log("PetSource=" .. tostring(selected.source))

    local DialogueFolder =
        ReplicatedStorage:FindFirstChild("Dialogue")

    local DialogueRemotes =
        DialogueFolder
        and DialogueFolder:FindFirstChild("Remotes")

    local DialogueSelect =
        DialogueRemotes
        and DialogueRemotes:FindFirstChild("DialogueSelect")

    local richie, primary, prompt =
        shared.SerenityRideAPet.RichieSellContext()

    if not DialogueSelect
        or not richie
        or not primary then

        cachedRichie = nil
        return false, "Richie/dialogue unavailable"
    end

    -- A real sale is now ready. Only this actual Sell action may interrupt
    -- the current ride.
    if isCurrentlyRiding() then
        rememberCurrentPet()

        if not ensureDismounted() then
            return false, "dismount failed"
        end
    end

    -- Failed interactions retry quickly. Only a CONFIRMED sale consumes
    -- SellIntervalSeconds.
    sellRuntime.LastAttempt = os.clock()

    local originalCF = HRP.CFrame
    local petTool = nil

    if selected.source == "inventory" then
        petTool =
            selected.tool
            and selected.tool.Parent
            and selected.tool
            or findPetToolByKey(selected.key)

        if not petTool then
            return false, "inventory pet tool disappeared"
        end
    else
        if not PickupPetRemote or not PlacePetRemote then
            return false, "pet remotes unavailable"
        end

        local pickupOk = pcall(function()
            PickupPetRemote:FireServer(selected.key)
        end)

        if not pickupOk then
            return false, "PickupPet request failed"
        end

        local pickupDeadline = os.clock() + 2.5
        repeat
            petTool = findPetToolByKey(selected.key)
            if petTool then
                break
            end
            task.wait(0.04)
        until os.clock() >= pickupDeadline

        if not petTool then
            return false, "pet tool not observed"
        end
    end

    Humanoid:UnequipTools()
    task.wait(0.05)
    Humanoid:EquipTool(petTool)
    task.wait(0.10)

    if petTool.Parent ~= Character then
        if selected.source == "garden" and PlacePetRemote then
            pcall(function()
                PlacePetRemote:FireServer(
                    selected.key,
                    selected.position
                )
            end)
        end

        return false, "pet tool equip failed"
    end

    local approachPos =
        primary.Position
        - primary.CFrame.LookVector * 4

    local approachCF =
        CFrame.lookAt(
            Vector3.new(
                approachPos.X,
                originalCF.Position.Y,
                approachPos.Z
            ),
            primary.Position
        )

    tweenTravel(
        approachCF,
        1800,
        "AutoSell.ApproachRichie"
    )

    task.wait(0.25)

    -- Re-resolve the prompt AFTER arrival. This fixes the regression where
    -- Auto Sell refused to move because Richie's prompt was not yet streamed
    -- or enabled while the player was still far away.
    local promptDeadline = os.clock() + 2.0

    repeat
        if not richie.Parent then
            break
        end

        primary =
            richie.PrimaryPart
            or richie:FindFirstChild("HumanoidRootPart")
            or richie:FindFirstChildWhichIsA("BasePart")

        prompt =
            primary
            and (
                primary:FindFirstChildOfClass("ProximityPrompt")
                or richie:FindFirstChildWhichIsA(
                    "ProximityPrompt",
                    true
                )
            )

        if prompt and prompt.Parent then
            break
        end

        task.wait(0.05)
    until os.clock() >= promptDeadline

    local sold = false

    for attempt = 1, 2 do
        if petTool.Parent == nil then
            sold = true
            break
        end

        local promptOk = false

        if prompt and prompt.Parent then
            if fireproximityprompt_f then
                promptOk =
                    pcall(function()
                        fireproximityprompt_f(prompt)
                    end)
            else
                promptOk =
                    pcall(function()
                        prompt:InputHoldBegin()
                        task.wait(
                            math.max(
                                0.05,
                                tonumber(prompt.HoldDuration) or 0
                            )
                        )
                        prompt:InputHoldEnd()
                    end)
            end
        end

        -- DialogueSelect is the validated sell choice. Send it while near
        -- Richie even if the executor could not synthesize the prompt input.
        task.wait(promptOk and 0.28 or 0.12)

        pcall(function()
            DialogueSelect:FireServer(
                richie,
                "I would like to sell this"
            )
        end)

        local soldDeadline =
            os.clock() + (attempt == 1 and 1.75 or 2.25)

        repeat
            if petTool.Parent == nil then
                sold = true
                break
            end

            if selected.source == "garden" then
                if not selected.model or selected.model.Parent == nil then
                    sold = true
                    break
                end

                local stillExists = false
                for _, currentPet in ipairs(rendererOwnedPets()) do
                    if tostring(currentPet.key) == tostring(selected.key) then
                        stillExists = true
                        break
                    end
                end

                if not stillExists then
                    sold = true
                    break
                end
            else
                if not findPetToolByKey(selected.key) then
                    sold = true
                    break
                end
            end

            task.wait(0.04)
        until os.clock() >= soldDeadline

        if sold then
            break
        end

        task.wait(0.18)
    end

    tweenTravel(
        originalCF,
        2200,
        "AutoSell.Return"
    )

    HRP.CFrame = originalCF

    if not sold then
        Humanoid:UnequipTools()

        if selected.source == "garden" and PlacePetRemote then
            pcall(function()
                PlacePetRemote:FireServer(
                    selected.key,
                    selected.position
                )
            end)
        end

        cachedRichie = nil
        return false, "sale not confirmed"
    end

    lastSellAction = os.clock()

    shared.SerenityRideAPet.SellRateCache[
        tostring(selected.key)
    ] = nil

    task.defer(function()
        if Config.AutoEquipBest == true then
            shared.SerenityRideAPet.AutoEquipBestState.Pending = true
        else
            shared.SerenityRideAPet.AutoPlaceBestAfterSell()
        end
    end)

    return true, selected.name
end

shared.SerenityRideAPet.AutoHatchLuckMax = function()
    if not UpgradesRemote
        or type(HatchLuckData) ~= "table" then

        return false, "hatch luck unavailable"
    end

    if os.clock() - lastHatchLuckAction
        < math.max(
            0.75,
            tonumber(Config.HatchLuckIntervalSeconds) or 1
        ) then

        return false, "hatch luck cooldown"
    end

    local saved =
        LP:FindFirstChild("SavedData")

    local upgrades =
        saved and saved:FindFirstChild("HatchUpgrades")

    local usedFree =
        saved and saved:FindFirstChild("UsedFreeHatchUpgrades")

    local free =
        saved and saved:FindFirstChild("FreeHatchUpgrades")

    if not upgrades then
        return false, "HatchUpgrades missing"
    end

    local current =
        tonumber(upgrades.Value) or 0

    local freeCount =
        free and tonumber(free.Value) or 0

    local usedFreeCount =
        usedFree and tonumber(usedFree.Value) or 0

    local affordablePaid = 0

    -- Mirror the game's own Max button calculation when available.
    if type(HatchLuckData.GetMaxAffordable) == "function" then
        local paidAfterFree =
            HatchLuckData.GetPaidUpgrades
            and HatchLuckData.GetPaidUpgrades(
                current + freeCount,
                usedFreeCount + freeCount
            )
            or (current + freeCount)

        local okAffordable, count =
            pcall(
                HatchLuckData.GetMaxAffordable,
                paidAfterFree,
                cashValue()
            )

        if okAffordable then
            affordablePaid =
                math.max(0, tonumber(count) or 0)
        end
    else
        local paidCount =
            HatchLuckData.GetPaidUpgrades
            and HatchLuckData.GetPaidUpgrades(
                current,
                usedFreeCount
            )
            or current

        local price =
            HatchLuckData.GetPrice
            and tonumber(
                HatchLuckData.GetPrice(paidCount)
            )
            or nil

        if price and cashValue() >= price then
            affordablePaid = 1
        end
    end

    if freeCount <= 0
        and affordablePaid <= 0 then

        return false, "nothing affordable"
    end

    lastHatchLuckAction = os.clock()

    -- The native Max request can create its own game toast. Keep the purchase
    -- behavior, but hide that transient visual while still allowing our
    -- notification observers to process any important text underneath.
    shared.SerenityRideAPet.SilenceHatchLuckNotificationWindow(
        2.5
    )

    -- Exact native BuyMax call used by the game's own Hatch Luck UI.
    local ok = pcall(function()
        UpgradesRemote:FireServer("Max")
    end)

    if not ok then
        return false, "max upgrade request failed"
    end

    local expected =
        math.max(1, freeCount + affordablePaid)

    local deadline =
        os.clock() + 2.0

    repeat
        local now =
            tonumber(upgrades.Value) or current

        if now > current then
            return
                true,
                now - current,
                expected
        end

        task.wait(0.04)
    until os.clock() >= deadline

    return false, "max upgrade not confirmed"
end


-- Compatibility alias for any older internal/external caller.
shared.SerenityRideAPet.AutoHatchLuckOne =
    shared.SerenityRideAPet.AutoHatchLuckMax


function shared.SerenityRideAPet.InitUIAndFeedSetup()
    rebuildFeedPetOptions()

-- Feed selector is intentionally limited to the five actual pet foods.
local DynamicFeedFoods = {
    "Grass",
    "Bone",
    "Meat",
    "Magic Apple",
    "Dragonfruit",
}

-- Clean older saved selections that contained non-pet consumables.
do
    local allowed = {}
    local cleaned = {}

    for _, name in ipairs(DynamicFeedFoods) do
        allowed[name] = true
    end

    for _, name in ipairs(selectionAsArray(Config.AutoFeedFoods)) do
        name = tostring(name)

        if allowed[name] then
            cleaned[#cleaned + 1] = name
        end
    end

    table.sort(cleaned)

    local current = selectionAsArray(Config.AutoFeedFoods)
    table.sort(current)

    if HttpService:JSONEncode(cleaned)
        ~= HttpService:JSONEncode(current) then

        Config.AutoFeedFoods = cleaned
        saveConfig()
    end
end

-- SERENITY HUB V3 UI
-- Official shared V3 renderer for the Ride A Pet release.
-- ============================================================

local function normalizedSelection(value)
    return selectionAsArray(value)
end

local function uiSet(key, value)
    saveSimpleSetting(key, value)

    if value == true
        and (
            key == "AutoSteal"
            or key == "AutoSell"
        ) then

        local wake =
            shared
            and shared.SerenityRideAPet
            and shared.SerenityRideAPet.EnsureMovementLaneWorker

        if type(wake) == "function" then
            -- Wake only if the movement owner is dead/stale. A toggle must
            -- never task.cancel() a healthy steal/mutation/return transaction.
            task.defer(
                wake,
                "toggle:" .. tostring(key),
                false
            )
        end
    end
end

local function uiSetNumber(key, value, minimum)
    local n = tonumber(value)

    if not n then
        return
    end

    n = math.max(minimum or 0, math.floor(n))
    saveSimpleSetting(key, n)
end

local serenityEnv = getgenv and getgenv() or _G

serenityEnv.__SERENITY_RAP_AUTO_EXECUTE_ENABLED =
    Config.AutoExecuteOnTeleport == true


-- Remove temporary v62 custom UI if this is a same-session upgrade.
if serenityEnv.__SERENITY_RAP_UI then
    pcall(function()
        serenityEnv.__SERENITY_RAP_UI:Destroy()
    end)
    serenityEnv.__SERENITY_RAP_UI = nil
end

-- Destroy a previous official Ride A Pet UI on re-execution.
local oldApp = serenityEnv.__SERENITY_RAP_APP
if oldApp then
    pcall(function()
        if oldApp.Runtime and type(oldApp.Runtime.Destroy) == "function" then
            oldApp.Runtime:Destroy()
        elseif type(oldApp.Destroy) == "function" then
            oldApp:Destroy()
        end
    end)
    serenityEnv.__SERENITY_RAP_APP = nil
end

local SerenityUI = nil
local uiLoadOk = false
local uiLoadErr = nil

do
    local urls = {
        "https://raw.githubusercontent.com/MUshihara/SerenityNewUi/d15348e090db8c3bef34784a9d6d87ea3473ae70/tests/rideapet-m423/ui.lua",
        "https://raw.githubusercontent.com/MUshihara/SerenityNewUi/d15348e090db8c3bef34784a9d6d87ea3473ae70/tests/rideapet-m423/ui.lua",
    }

    for attempt = 1, 4 do
        local url =
            urls[
                ((attempt - 1) % #urls) + 1
            ]

        local okHttp, source =
            pcall(function()
                return game:HttpGet(
                    url,
                    true
                )
            end)

        if okHttp
            and type(source) == "string"
            and source ~= "" then

            local fn, compileErr =
                loadstring(
                    source,
                    "@Serenity/RideAPet/UI"
                )

            if fn then
                local okRun, result =
                    pcall(fn)

                if okRun
                    and result ~= nil then

                    SerenityUI = result
                    uiLoadOk = true
                    uiLoadErr = nil
                    break
                end

                uiLoadErr = result
            else
                uiLoadErr = compileErr
            end
        else
            uiLoadErr = source
        end

        task.wait(
            math.min(
                2,
                0.35 * attempt
            )
        )
    end
end

if not uiLoadOk then
    warn(
        "[SERENITY HUB] Ride A Pet UI failed to load: "
        .. tostring(uiLoadErr)
    )

    log("SerenityUI.LoadFailed=" .. tostring(uiLoadErr))
else
    local filterModes = {
        "All Eggs",
        "Selected Rarities",
        "Specific Eggs",
        "Rarity + Egg",
    }

    local priorities = {
        "Highest to Lowest",
        "Lowest to Highest",
    }

    local petRaritySet = {}

    if type(PetsData) == "table" then
        for _, data in pairs(PetsData) do
            if type(data) == "table"
                and type(data.Rarity) == "string"
                and data.Rarity ~= "" then

                petRaritySet[data.Rarity] = true
            end
        end
    end

    local DynamicPetRarities = {}

    for rarity in pairs(petRaritySet) do
        DynamicPetRarities[#DynamicPetRarities + 1] = rarity
    end

    table.sort(DynamicPetRarities, function(a, b)
        local ar = SELL_RARITY_ORDER[a] or 999
        local br = SELL_RARITY_ORDER[b] or 999

        if ar ~= br then
            return ar < br
        end

        return a < b
    end)


    -- ============================================================
    -- ESP + ANTI-AFK
    -- Event-driven object tracking; only distance labels update.
    -- No whole-Workspace polling.
    -- ============================================================

    local espEnv = getgenv and getgenv() or _G

    -- Clean up a previous ESP copy before creating a new one.
    if type(espEnv.__SERENITY_RAP_ESP_CONNECTIONS) == "table" then
        for _, connection in ipairs(espEnv.__SERENITY_RAP_ESP_CONNECTIONS) do
            pcall(function()
                connection:Disconnect()
            end)
        end
    end

    if type(espEnv.__SERENITY_RAP_ESP_CLEANUP) == "function" then
        pcall(espEnv.__SERENITY_RAP_ESP_CLEANUP)
    end

    espEnv.__RAP_espConnections = {}
    espEnv.__SERENITY_RAP_ESP_CONNECTIONS = espEnv.__RAP_espConnections

    espEnv.__RAP_eggEspObjects = {}
    espEnv.__RAP_placedEggEspObjects = {}
    espEnv.__RAP_playerEspObjects = {}

    espEnv.__RAP_EGG_ESP_HIGHLIGHT = "__SERENITY_RAP_EGG_ESP_HIGHLIGHT"
    espEnv.__RAP_EGG_ESP_BOX = "__SERENITY_RAP_EGG_ESP_BOX"
    espEnv.__RAP_EGG_ESP_BILLBOARD = "__SERENITY_RAP_EGG_ESP_BILLBOARD"
    espEnv.__RAP_EGG_MUTATION_ESP_BILLBOARD = "__SERENITY_RAP_EGG_MUTATION_ESP_BILLBOARD"
    espEnv.__RAP_PLACED_EGG_ESP_HIGHLIGHT = "__SERENITY_RAP_PLACED_EGG_ESP_HIGHLIGHT"
    espEnv.__RAP_PLACED_EGG_ESP_BOX = "__SERENITY_RAP_PLACED_EGG_ESP_BOX"
    espEnv.__RAP_PLACED_EGG_ESP_BILLBOARD = "__SERENITY_RAP_PLACED_EGG_ESP_BILLBOARD"
    espEnv.__RAP_PLAYER_ESP_HIGHLIGHT = "__SERENITY_RAP_PLAYER_ESP_HIGHLIGHT"
    espEnv.__RAP_PLAYER_ESP_BOX = "__SERENITY_RAP_PLAYER_ESP_BOX"
    espEnv.__RAP_PLAYER_ESP_BILLBOARD = "__SERENITY_RAP_PLAYER_ESP_BILLBOARD"

    espEnv.__RAP_rememberConnection = function(connection)
        if connection then
            espEnv.__RAP_espConnections[#espEnv.__RAP_espConnections + 1] = connection
        end
        return connection
    end

    espEnv.__RAP_currentLocalRoot = function()
        local char = LP.Character
        return char and char:FindFirstChild("HumanoidRootPart")
    end

    espEnv.__RAP_modelAdornee = function(model)
        if not model or not model.Parent then
            return nil
        end

        if model:IsA("BasePart") then
            return model
        end

        if model:IsA("Model") then
            return model.PrimaryPart
                or model:FindFirstChild("HumanoidRootPart")
                or model:FindFirstChild("Head")
                or model:FindFirstChildWhichIsA("BasePart", true)
        end

        return nil
    end

    espEnv.__RAP_clearNamedChild = function(parent, name)
        if not parent then
            return
        end

        local existing = parent:FindFirstChild(name)
        if existing then
            pcall(function()
                existing:Destroy()
            end)
        end
    end

    espEnv.__RAP_createEspVisual = function(model, adornee, highlightName, boxName, billboardName, outlineColor)
        if not model or not adornee then
            return nil
        end

        espEnv.__RAP_clearNamedChild(model, highlightName)
        espEnv.__RAP_clearNamedChild(adornee, boxName)
        espEnv.__RAP_clearNamedChild(adornee, billboardName)

        local highlight = Instance.new("Highlight")
        highlight.Name = highlightName
        highlight.Adornee = model
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.FillTransparency = 0.88
        highlight.OutlineTransparency = 0
        highlight.FillColor = outlineColor
        highlight.OutlineColor = outlineColor
        highlight.Parent = model

        local box = Instance.new("BoxHandleAdornment")
        box.Name = boxName
        box.Adornee = adornee
        box.AlwaysOnTop = true
        box.ZIndex = 9
        box.Color3 = outlineColor
        box.Transparency = 0.72

        if model:IsA("Model") then
            local okBounds, boundsCF, boundsSize = pcall(function()
                local cf, size = model:GetBoundingBox()
                return cf, size
            end)

            if okBounds and typeof(boundsCF) == "CFrame" and typeof(boundsSize) == "Vector3" then
                box.CFrame = adornee.CFrame:ToObjectSpace(boundsCF)
                box.Size = boundsSize + Vector3.new(0.25, 0.25, 0.25)
            else
                box.Size = adornee.Size + Vector3.new(0.25, 0.25, 0.25)
            end
        else
            box.Size = adornee.Size + Vector3.new(0.25, 0.25, 0.25)
        end

        box.Parent = adornee

        local billboard = Instance.new("BillboardGui")
        billboard.Name = billboardName
        billboard.Adornee = adornee
        billboard.AlwaysOnTop = true
        billboard.LightInfluence = 0
        billboard.MaxDistance = 100000
        billboard.Size = UDim2.fromOffset(220, 42)
        billboard.StudsOffset = Vector3.new(0, 4.25, 0)
        billboard.Parent = adornee

        local label = Instance.new("TextLabel")
        label.Name = "Label"
        -- Text only: no black ESP name plate.
        label.BackgroundTransparency = 1
        label.BorderSizePixel = 0
        label.Size = UDim2.fromScale(1, 1)
        label.Font = Enum.Font.GothamBold
        label.TextColor3 = Color3.new(1, 1, 1)
        label.TextSize = 14
        label.TextStrokeColor3 = Color3.new(0, 0, 0)
        label.TextStrokeTransparency = 0.15
        label.TextWrapped = false
        label.Parent = billboard

        return {
            Model = model,
            Adornee = adornee,
            Highlight = highlight,
            Box = box,
            Billboard = billboard,
            Label = label,
        }
    end

    espEnv.__RAP_createLabelOnlyEsp = function(
        model,
        adornee,
        billboardName
    )
        if not model
            or not adornee then

            return nil
        end

        espEnv.__RAP_clearNamedChild(
            adornee,
            billboardName
        )

        local billboard =
            Instance.new(
                "BillboardGui"
            )

        billboard.Name =
            billboardName

        billboard.Adornee =
            adornee

        billboard.AlwaysOnTop =
            true

        billboard.LightInfluence =
            0

        billboard.MaxDistance =
            100000

        billboard.Size =
            UDim2.fromOffset(
                220,
                42
            )

        billboard.StudsOffset =
            Vector3.new(
                0,
                4.25,
                0
            )

        billboard.Parent =
            adornee

        local label =
            Instance.new(
                "TextLabel"
            )

        label.Name =
            "Label"

        label.BackgroundTransparency =
            1

        label.BorderSizePixel =
            0

        label.Size =
            UDim2.fromScale(
                1,
                1
            )

        label.Font =
            Enum.Font.GothamBold

        label.TextColor3 =
            Color3.new(
                1,
                1,
                1
            )

        label.TextSize =
            14

        label.TextStrokeColor3 =
            Color3.new(
                0,
                0,
                0
            )

        label.TextStrokeTransparency =
            0.15

        label.TextWrapped =
            false

        label.Parent =
            billboard

        return {
            Model = model,
            Adornee = adornee,
            Highlight = nil,
            Box = nil,
            Billboard = billboard,
            Label = label,
        }
    end

    espEnv.__RAP_destroyEspRecord = function(record)
        if not record then
            return
        end

        pcall(function()
            if record.Highlight then
                record.Highlight:Destroy()
            end
        end)

        pcall(function()
            if record.Box then
                record.Box:Destroy()
            end
        end)

        pcall(function()
            if record.Billboard then
                record.Billboard:Destroy()
            end
        end)
    end

    espEnv.__RAP_clearEggEsp = function()
        for model, record in pairs(espEnv.__RAP_eggEspObjects) do
            espEnv.__RAP_destroyEspRecord(record)
            espEnv.__RAP_eggEspObjects[model] = nil
        end
    end

    espEnv.__RAP_clearPlacedEggEsp = function()
        for model, record in pairs(
            espEnv.__RAP_placedEggEspObjects
        ) do
            espEnv.__RAP_destroyEspRecord(record)
            espEnv.__RAP_placedEggEspObjects[model] = nil
        end
    end

    espEnv.__RAP_clearPlayerEsp = function()
        for player, record in pairs(espEnv.__RAP_playerEspObjects) do
            espEnv.__RAP_destroyEspRecord(record)
            espEnv.__RAP_playerEspObjects[player] = nil
        end
    end

    espEnv.__RAP_eggDisplayName = function(model)
        if not model then
            return "Egg"
        end

        local attributeName = model:GetAttribute("Egg")
            or model:GetAttribute("EggName")
            or model:GetAttribute("Type")

        if type(attributeName) == "string" and attributeName ~= "" then
            return attributeName
        end

        return tostring(model.Name)
    end

    espEnv.__RAP_normalizeEggName = function(value)
        return string.lower(tostring(value or "")):gsub("[^%w]", "")
    end

    espEnv.__RAP_matchActiveEggForModel = function(model)
        if not ActiveEggs
            or not model
            or not model.Parent then

            return nil
        end

        local okPivot, pivot =
            pcall(function()
                return model:GetPivot()
            end)

        if not okPivot
            or not pivot then

            return nil
        end

        local wanted =
            espEnv.__RAP_normalizeEggName(
                espEnv.__RAP_eggDisplayName(
                    model
                )
            )

        local best = nil
        local bestDistance = math.huge
        local bestNameMatch = false

        for _, active in ipairs(
            ActiveEggs:GetChildren()
        ) do
            local position =
                active:GetAttribute(
                    "Position"
                )

            if typeof(position) == "Vector3" then
                local distance =
                    vectorXZDistance(
                        pivot.Position,
                        position
                    )

                if distance <= 16 then
                    local activeName =
                        espEnv.__RAP_normalizeEggName(
                            active:GetAttribute("Egg")
                        )

                    local nameMatch =
                        wanted ~= ""
                        and activeName == wanted

                    if best == nil
                        or (nameMatch and not bestNameMatch)
                        or (
                            nameMatch == bestNameMatch
                            and distance < bestDistance
                        ) then

                        best = active
                        bestDistance = distance
                        bestNameMatch = nameMatch
                    end
                end
            end
        end

        return best
    end

    espEnv.__RAP_eggMutationText = function(model, record)
        if not model then
            return nil
        end

        local direct =
            model:GetAttribute(
                "Mutation"
            )

        local active =
            record
            and record.ActiveEgg
            or nil

        if not active
            or active.Parent == nil then

            local now = os.clock()

            if not record
                or now >= (tonumber(record.NextActiveResolveAt) or 0) then

                active =
                    espEnv.__RAP_matchActiveEggForModel(
                        model
                    )

                if record then
                    record.ActiveEgg = active
                    record.NextActiveResolveAt =
                        now + 0.75
                end
            end
        end

        local mutation =
            direct

        if (mutation == nil or tostring(mutation) == "")
            and active
            and active.Parent then

            mutation =
                active:GetAttribute(
                    "Mutation"
                )
        end

        local textValue =
            tostring(
                mutation
                or ""
            )

        local lower =
            string.lower(textValue)

        if textValue == ""
            or lower == "none"
            or lower == "nil"
            or lower == "normal" then

            return nil
        end

        return textValue
    end

    espEnv.__RAP_renderedEggLuck = function(model)
        local displayName = espEnv.__RAP_eggDisplayName(model)
        local direct = eggMeta[displayName]

        if direct then
            return tonumber(direct.luck) or 0
        end

        local wanted = espEnv.__RAP_normalizeEggName(displayName)
        for eggName, meta in pairs(eggMeta) do
            if espEnv.__RAP_normalizeEggName(eggName) == wanted then
                return tonumber(meta.luck) or 0
            end
        end

        -- Position fallback for rendered names that differ from GameData names.
        if ActiveEggs and model and model.Parent then
            local okPivot, pivot = pcall(function()
                return model:GetPivot()
            end)

            if okPivot and pivot then
                local bestDistance = math.huge
                local bestLuck = nil

                for _, active in ipairs(ActiveEggs:GetChildren()) do
                    local pos = active:GetAttribute("Position")
                    local eggType = tostring(active:GetAttribute("Egg") or "")

                    if typeof(pos) == "Vector3" and eggType ~= "" then
                        local d = vectorXZDistance(pivot.Position, pos)
                        if d <= 14 and d < bestDistance then
                            bestDistance = d
                            bestLuck = tonumber((eggMeta[eggType] or {}).luck) or 0
                        end
                    end
                end

                if bestLuck ~= nil then
                    return bestLuck
                end
            end
        end

        return 0
    end

    espEnv.__RAP_renderedEggWeight = function(model)
        if not model then
            return 0, nil
        end

        local directRaw =
            tonumber(
                model:GetAttribute("Weight")
            )

        if directRaw then
            local value, formatted =
                shared.SerenityRideAPet.ResolveEggKG(
                    directRaw
                )

            if value ~= nil then
                return value, formatted
            end
        end

        if ActiveEggs and model.Parent then
            local okPivot, pivot =
                pcall(function()
                    return model:GetPivot()
                end)

            if okPivot and pivot then
                local bestDistance =
                    math.huge

                local bestRaw =
                    nil

                for _, active in ipairs(
                    ActiveEggs:GetChildren()
                ) do
                    local pos =
                        active:GetAttribute(
                            "Position"
                        )

                    if typeof(pos) == "Vector3" then
                        local d =
                            vectorXZDistance(
                                pivot.Position,
                                pos
                            )

                        if d <= 14
                            and d < bestDistance then

                            bestDistance = d

                            bestRaw =
                                tonumber(
                                    active:GetAttribute(
                                        "Weight"
                                    )
                                )
                        end
                    end
                end

                if bestRaw ~= nil then
                    local value, formatted =
                        shared.SerenityRideAPet.ResolveEggKG(
                            bestRaw
                        )

                    if value ~= nil then
                        return value, formatted
                    end
                end
            end
        end

        return 0, nil
    end

    espEnv.__RAP_renderedEggKGText = function(model)
        local value, formatted =
            espEnv.__RAP_renderedEggWeight(
                model
            )

        return
            shared.SerenityRideAPet.CleanEggKGText(
                formatted,
                value
            )
    end

    espEnv.__RAP_parseDisplayedKG = function(textValue)
        local rawText =
            tostring(
                textValue
                or ""
            )

        if rawText == "" then
            return nil, nil
        end

        local clean =
            rawText
            :gsub("<.->", "")
            :gsub(",", "")
            :gsub("_", "")

        local numberText =
            clean:match(
                "([%d%.]+%s*[kKmMbBtTqQ]?)%s*[Kk]%.?[Gg]"
            )

        if not numberText then
            return nil, nil
        end

        local numeric =
            shared.SerenityRideAPet.ParseCompactNumber(
                numberText
            )

        if numeric == nil then
            return nil, nil
        end

        local originalNumber =
            rawText:match(
                "([%d%.,]+%s*[kKmMbBtTqQ]?)%s*[Kk]%.?[Gg]"
            )
            or numberText

        return numeric, originalNumber
    end

    espEnv.__RAP_isSerenityEspDescendant = function(instance)
        local current =
            instance

        while current do
            local name =
                tostring(
                    current.Name
                )

            if string.find(
                name,
                "__SERENITY_RAP_",
                1,
                true
            ) then
                return true
            end

            current =
                current.Parent
        end

        return false
    end

    espEnv.__RAP_placedEggWeight = function(model)
        if not model then
            return 0, nil
        end

        -- 1) Exact raw weight remembered before Auto Place consumed the Tool.
        local remembered =
            shared.SerenityRideAPet.GetRememberedPlacedEggWeight(
                model
            )

        if remembered ~= nil then
            local value,
                formatted =
                shared.SerenityRideAPet.ResolveEggKG(
                    remembered
                )

            if value ~= nil then
                return value,
                    formatted
            end
        end

        -- 2) Common server/model attribute names.
        local raw = nil

        local attributeNames = {
            "Weight",
            "EggWeight",
            "RawWeight",
            "BaseWeight",
        }

        for _, name in ipairs(
            attributeNames
        ) do
            raw =
                tonumber(
                    model:GetAttribute(
                        name
                    )
                )

            if raw ~= nil then
                break
            end
        end

        -- 3) Search the full placed model tree for Weight values/attributes.
        if raw == nil then
            for _, child in ipairs(
                model:GetDescendants()
            ) do
                if child:IsA(
                    "ValueBase"
                ) then

                    local lowerName =
                        string.lower(
                            tostring(
                                child.Name
                            )
                        )

                    if lowerName == "weight"
                        or lowerName == "eggweight"
                        or lowerName == "rawweight"
                        or lowerName == "baseweight" then

                        raw =
                            tonumber(
                                (child :: any).Value
                            )

                        if raw ~= nil then
                            break
                        end
                    end
                end

                if raw == nil then
                    for _, name in ipairs(
                        attributeNames
                    ) do
                        raw =
                            tonumber(
                                child:GetAttribute(
                                    name
                                )
                            )

                        if raw ~= nil then
                            break
                        end
                    end
                end

                if raw ~= nil then
                    break
                end
            end
        end

        if raw ~= nil then
            shared.SerenityRideAPet.RememberPlacedEggWeight(
                model,
                raw
            )

            local value,
                formatted =
                shared.SerenityRideAPet.ResolveEggKG(
                    raw
                )

            if value ~= nil then
                return value,
                    formatted
            end
        end

        -- 4) Some placed-egg renderers expose only the already-formatted KG
        --    in native GUI text. Reuse it instead of inventing 0 K.G.
        for _, child in ipairs(
            model:GetDescendants()
        ) do
            if (
                child:IsA("TextLabel")
                or child:IsA("TextButton")
                or child:IsA("TextBox")
            )
                and not espEnv.__RAP_isSerenityEspDescendant(
                    child
                ) then

                local value,
                    displayed =
                    espEnv.__RAP_parseDisplayedKG(
                        child.Text
                    )

                if value ~= nil then
                    return value,
                        tostring(displayed)
                        .. " KG"
                end
            end
        end

        return 0, nil
    end

    espEnv.__RAP_placedEggKGText = function(model)
        local value,
            formatted =
            espEnv.__RAP_placedEggWeight(
                model
            )

        if formatted == nil
            and (
                value == nil
                or tonumber(value) == 0
            ) then

            return "?"
        end

        return
            shared.SerenityRideAPet.CleanEggKGText(
                formatted,
                value
            )
    end

    espEnv.__RAP_formatKG = function(value)
        local n = tonumber(value) or 0
        local abs = math.abs(n)

        if abs >= 1e15 then
            return string.format("%.2fQ", n / 1e15):gsub("%.00Q$", "Q")
        elseif abs >= 1e12 then
            return string.format("%.2fT", n / 1e12):gsub("%.00T$", "T")
        elseif abs >= 1e9 then
            return string.format("%.2fB", n / 1e9):gsub("%.00B$", "B")
        elseif abs >= 1e6 then
            return string.format("%.2fM", n / 1e6):gsub("%.00M$", "M")
        elseif abs >= 1e3 then
            return string.format("%.2fK", n / 1e3):gsub("%.00K$", "K")
        end

        if math.floor(n) == n then
            return tostring(math.floor(n))
        end

        return string.format("%.2f", n):gsub("0+$", ""):gsub("%.$", "")
    end

    espEnv.__RAP_eggPassesEspLuck = function(model)
        return espEnv.__RAP_renderedEggLuck(model) >= eggEspMinimumLuck()
    end

    espEnv.__RAP_addEggEsp = function(model)
        if (
            Config.EggESP ~= true
            and Config.EggMutationESP ~= true
        )
            or not model
            or not model.Parent
            or espEnv.__RAP_eggEspObjects[model]
            or not espEnv.__RAP_eggPassesEspLuck(model) then

            return
        end

        local adornee = espEnv.__RAP_modelAdornee(model)
        if not adornee then
            return
        end

        local record

        if Config.EggESP == true then
            record = espEnv.__RAP_createEspVisual(
                model,
                adornee,
                espEnv.__RAP_EGG_ESP_HIGHLIGHT,
                espEnv.__RAP_EGG_ESP_BOX,
                espEnv.__RAP_EGG_ESP_BILLBOARD,
                Color3.fromRGB(255, 201, 74)
            )
        else
            record = espEnv.__RAP_createLabelOnlyEsp(
                model,
                adornee,
                espEnv.__RAP_EGG_MUTATION_ESP_BILLBOARD
            )

            if record then
                record.MutationOnly = true
            end
        end

        if record then
            record.ActiveEgg =
                espEnv.__RAP_matchActiveEggForModel(
                    model
                )

            record.NextActiveResolveAt =
                os.clock() + 0.75

            if record.MutationOnly
                and record.Billboard then

                record.Billboard.Enabled =
                    espEnv.__RAP_eggMutationText(
                        model,
                        record
                    ) ~= nil
            end

            espEnv.__RAP_eggEspObjects[model] = record
        end
    end

    espEnv.__RAP_removeEggEsp = function(model)
        local record = espEnv.__RAP_eggEspObjects[model]
        if record then
            espEnv.__RAP_destroyEspRecord(record)
            espEnv.__RAP_eggEspObjects[model] = nil
        end
    end

    espEnv.__RAP_renderedEggsConnectionAdd = nil
    espEnv.__RAP_renderedEggsConnectionRemove = nil
    espEnv.__RAP_currentRenderedEggsFolder = nil

    espEnv.__RAP_disconnectRenderedEggFolder = function()
        if espEnv.__RAP_renderedEggsConnectionAdd then
            pcall(function()
                espEnv.__RAP_renderedEggsConnectionAdd:Disconnect()
            end)
            espEnv.__RAP_renderedEggsConnectionAdd = nil
        end

        if espEnv.__RAP_renderedEggsConnectionRemove then
            pcall(function()
                espEnv.__RAP_renderedEggsConnectionRemove:Disconnect()
            end)
            espEnv.__RAP_renderedEggsConnectionRemove = nil
        end

        espEnv.__RAP_currentRenderedEggsFolder = nil
    end

    espEnv.__RAP_bindRenderedEggFolder = function(folder)
        if folder == espEnv.__RAP_currentRenderedEggsFolder then
            return
        end

        espEnv.__RAP_disconnectRenderedEggFolder()
        espEnv.__RAP_clearEggEsp()

        if not folder then
            return
        end

        espEnv.__RAP_currentRenderedEggsFolder = folder

        if Config.EggESP == true
            or Config.EggMutationESP == true then

            for _, child in ipairs(folder:GetChildren()) do
                espEnv.__RAP_addEggEsp(child)
            end
        end

        espEnv.__RAP_renderedEggsConnectionAdd = folder.ChildAdded:Connect(function(child)
            task.defer(function()
                espEnv.__RAP_addEggEsp(child)
            end)
        end)

        espEnv.__RAP_renderedEggsConnectionRemove = folder.ChildRemoved:Connect(function(child)
            espEnv.__RAP_removeEggEsp(child)
        end)
    end

    espEnv.__RAP_refreshEggEsp = function()
        if Config.EggESP ~= true
            and Config.EggMutationESP ~= true then

            espEnv.__RAP_clearEggEsp()
            return
        end

        local folder = Workspace:FindFirstChild("RenderedEggs")
        espEnv.__RAP_bindRenderedEggFolder(folder)

        if folder then
            for _, child in ipairs(folder:GetChildren()) do
                espEnv.__RAP_addEggEsp(child)
            end
        end
    end

    espEnv.__RAP_removePlacedEggEsp = function(model)
        local record =
            espEnv.__RAP_placedEggEspObjects[
                model
            ]

        if record then
            espEnv.__RAP_destroyEspRecord(record)

            espEnv.__RAP_placedEggEspObjects[
                model
            ] = nil
        end
    end

    espEnv.__RAP_addPlacedEggEsp = function(model)
        if Config.PlacedEggESP ~= true
            or not model
            or not model.Parent
            or not model:IsA("Model")
            or espEnv.__RAP_placedEggEspObjects[model] then

            return
        end

        local adornee =
            espEnv.__RAP_modelAdornee(
                model
            )

        if not adornee then
            return
        end

        local record =
            espEnv.__RAP_createLabelOnlyEsp(
                model,
                adornee,
                espEnv.__RAP_PLACED_EGG_ESP_BILLBOARD
            )

        if record then
            espEnv.__RAP_placedEggEspObjects[
                model
            ] = record

            record.Label.Text =
                espEnv.__RAP_eggDisplayName(
                    model
                )
                .. " | "
                .. espEnv.__RAP_placedEggKGText(
                    model
                )
                .. " K.G"
        end
    end

    espEnv.__RAP_placedEggsConnectionAdd = nil
    espEnv.__RAP_placedEggsConnectionRemove = nil
    espEnv.__RAP_currentPlacedEggsFolder = nil

    espEnv.__RAP_disconnectPlacedEggFolder = function()
        if espEnv.__RAP_placedEggsConnectionAdd then
            pcall(function()
                espEnv.__RAP_placedEggsConnectionAdd:Disconnect()
            end)

            espEnv.__RAP_placedEggsConnectionAdd = nil
        end

        if espEnv.__RAP_placedEggsConnectionRemove then
            pcall(function()
                espEnv.__RAP_placedEggsConnectionRemove:Disconnect()
            end)

            espEnv.__RAP_placedEggsConnectionRemove = nil
        end

        espEnv.__RAP_currentPlacedEggsFolder = nil
    end

    espEnv.__RAP_bindPlacedEggFolder = function(folder)
        if folder
            == espEnv.__RAP_currentPlacedEggsFolder then

            return
        end

        espEnv.__RAP_disconnectPlacedEggFolder()
        espEnv.__RAP_clearPlacedEggEsp()

        if not folder then
            return
        end

        espEnv.__RAP_currentPlacedEggsFolder =
            folder

        if Config.PlacedEggESP == true then
            for _, child in ipairs(
                folder:GetChildren()
            ) do
                espEnv.__RAP_addPlacedEggEsp(
                    child
                )
            end
        end

        espEnv.__RAP_placedEggsConnectionAdd =
            folder.ChildAdded:Connect(
                function(child)
                    task.defer(function()
                        espEnv.__RAP_addPlacedEggEsp(
                            child
                        )
                    end)
                end
            )

        espEnv.__RAP_placedEggsConnectionRemove =
            folder.ChildRemoved:Connect(
                function(child)
                    espEnv.__RAP_removePlacedEggEsp(
                        child
                    )
                end
            )
    end

    espEnv.__RAP_refreshPlacedEggEsp = function()
        if Config.PlacedEggESP ~= true then
            espEnv.__RAP_clearPlacedEggEsp()
            return
        end

        local plot =
            ownPlot()

        local folder =
            plot
            and plot:FindFirstChild(
                "Eggs"
            )

        espEnv.__RAP_bindPlacedEggFolder(
            folder
        )

        if folder then
            for _, child in ipairs(
                folder:GetChildren()
            ) do
                espEnv.__RAP_addPlacedEggEsp(
                    child
                )
            end
        end
    end

    espEnv.__RAP_removePlayerEsp = function(player)
        local record = espEnv.__RAP_playerEspObjects[player]
        if record then
            espEnv.__RAP_destroyEspRecord(record)
            espEnv.__RAP_playerEspObjects[player] = nil
        end
    end

    espEnv.__RAP_addPlayerEsp = function(player)
        if Config.PlayerESP ~= true
            or not player
            or player == LP then

            return
        end

        espEnv.__RAP_removePlayerEsp(player)

        local character = player.Character
        if not character then
            return
        end

        local adornee = espEnv.__RAP_modelAdornee(character)
        if not adornee then
            return
        end

        local record = espEnv.__RAP_createEspVisual(
            character,
            adornee,
            espEnv.__RAP_PLAYER_ESP_HIGHLIGHT,
            espEnv.__RAP_PLAYER_ESP_BOX,
            espEnv.__RAP_PLAYER_ESP_BILLBOARD,
            Color3.fromRGB(82, 179, 255)
        )

        if record then
            record.Player = player
            espEnv.__RAP_playerEspObjects[player] = record
        end
    end

    espEnv.__RAP_refreshPlayerEsp = function()
        if Config.PlayerESP ~= true then
            espEnv.__RAP_clearPlayerEsp()
            return
        end

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LP then
                espEnv.__RAP_addPlayerEsp(player)
            end
        end
    end

    espEnv.__RAP_setEggEspEnabled = function(enabled)
        uiSet("EggESP", enabled == true)
        espEnv.__RAP_clearEggEsp()
        espEnv.__RAP_refreshEggEsp()
    end

    espEnv.__RAP_setEggMutationEspEnabled = function(enabled)
        uiSet(
            "EggMutationESP",
            enabled == true
        )

        espEnv.__RAP_clearEggEsp()
        espEnv.__RAP_refreshEggEsp()
    end

    espEnv.__RAP_setPlacedEggEspEnabled = function(enabled)
        uiSet(
            "PlacedEggESP",
            enabled == true
        )

        espEnv.__RAP_refreshPlacedEggEsp()
    end

    espEnv.__RAP_setPlayerEspEnabled = function(enabled)
        uiSet("PlayerESP", enabled == true)
        espEnv.__RAP_refreshPlayerEsp()
    end

    -- Anti-AFK is a utility, not an automation worker, so it is ON by default.
    --
    -- v80.2.55 RIDE A PET COMPATIBILITY RULE:
    -- NEVER acquire Roblox idle-simulation services or fall back to them here.
    -- Live isolation proved that merely acquiring that service can cause
    -- stolen eggs to be returned.
    --
    -- Use the validated executor-native mousemoverel pulse instead:
    -- +1px -> 0.03s -> -1px every 60 seconds.
    local antiAfkEnv =
        (type(getgenv) == "function" and getgenv())
        or _G

    local function resolveAntiAfkFunction(name)
        local direct =
            rawget(
                antiAfkEnv,
                name
            )

        if type(direct) == "function" then
            return direct
        end

        direct =
            rawget(
                _G,
                name
            )

        if type(direct) == "function" then
            return direct
        end

        local ok, fenv =
            pcall(function()
                return
                    getfenv
                    and getfenv()
            end)

        if ok
            and type(fenv) == "table"
            and type(fenv[name]) == "function" then

            return fenv[name]
        end

        return nil
    end

    local mousemoverel_f =
        resolveAntiAfkFunction(
            "mousemoverel"
        )

    local oldAntiAfk =
        antiAfkEnv.__SERENITY_RAP_SAFE_ANTI_AFK

    if type(oldAntiAfk) == "table" then
        oldAntiAfk.Alive = false
    end

    if espEnv.__SERENITY_RAP_ANTI_AFK_CONNECTION then
        pcall(function()
            espEnv.__SERENITY_RAP_ANTI_AFK_CONNECTION:Disconnect()
        end)

        espEnv.__SERENITY_RAP_ANTI_AFK_CONNECTION =
            nil
    end

    local antiAfkRuntime = {
        Alive = true,
        Mode =
            type(mousemoverel_f) == "function"
            and "mousemoverel"
            or "unsupported_no_fallback",
    }

    antiAfkEnv.__SERENITY_RAP_SAFE_ANTI_AFK =
        antiAfkRuntime

    task.spawn(function()
        -- Keep the same validated cadence from AA1 / loader-safe Anti-AFK.
        task.wait(60)

        while antiAfkRuntime.Alive do
            if Config.AntiAFK == true
                and type(mousemoverel_f) == "function" then

                pcall(
                    mousemoverel_f,
                    1,
                    0
                )

                task.wait(0.03)

                pcall(
                    mousemoverel_f,
                    -1,
                    0
                )
            end

            task.wait(60)
        end
    end)

    espEnv.__RAP_rememberConnection(
        Players.PlayerAdded:Connect(function(player)
            espEnv.__RAP_rememberConnection(
                player.CharacterAdded:Connect(function()
                    task.wait(0.20)
                    espEnv.__RAP_addPlayerEsp(player)
                end)
            )

            task.defer(function()
                espEnv.__RAP_addPlayerEsp(player)
            end)
        end)
    )

    espEnv.__RAP_rememberConnection(
        Players.PlayerRemoving:Connect(function(player)
            espEnv.__RAP_removePlayerEsp(player)
        end)
    )

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP then
            espEnv.__RAP_rememberConnection(
                player.CharacterAdded:Connect(function()
                    task.wait(0.20)
                    espEnv.__RAP_addPlayerEsp(player)
                end)
            )
        end
    end

    espEnv.__RAP_rememberConnection(
        Workspace.ChildAdded:Connect(function(child)
            if child.Name == "RenderedEggs" then
                task.defer(function()
                    espEnv.__RAP_bindRenderedEggFolder(child)
                    espEnv.__RAP_refreshEggEsp()
                end)
            end
        end)
    )

    espEnv.__RAP_rememberConnection(
        Workspace.ChildRemoved:Connect(function(child)
            if child == espEnv.__RAP_currentRenderedEggsFolder then
                espEnv.__RAP_disconnectRenderedEggFolder()
                espEnv.__RAP_clearEggEsp()
            end
        end)
    )

    espEnv.__RAP_bindRenderedEggFolder(Workspace:FindFirstChild("RenderedEggs"))
    espEnv.__RAP_refreshEggEsp()
    espEnv.__RAP_refreshPlacedEggEsp()
    espEnv.__RAP_refreshPlayerEsp()

    espEnv.__SERENITY_RAP_ESP_GENERATION =
        (tonumber(espEnv.__SERENITY_RAP_ESP_GENERATION) or 0) + 1

    local espGeneration = espEnv.__SERENITY_RAP_ESP_GENERATION

    task.spawn(function()
        while espEnv.__SERENITY_RAP_ESP_GENERATION == espGeneration do
            local root = espEnv.__RAP_currentLocalRoot()

            if root then
                if Config.EggESP == true
                    or Config.EggMutationESP == true then

                    for model, record in pairs(espEnv.__RAP_eggEspObjects) do
                        if not model.Parent
                            or not record.Adornee
                            or not record.Adornee.Parent
                            or not espEnv.__RAP_eggPassesEspLuck(model) then

                            espEnv.__RAP_removeEggEsp(model)
                        else
                            local distance =
                                (root.Position - record.Adornee.Position).Magnitude

                            local mutation =
                                Config.EggMutationESP == true
                                and espEnv.__RAP_eggMutationText(
                                    model,
                                    record
                                )
                                or nil

                            if record.MutationOnly then
                                if record.Billboard then
                                    record.Billboard.Enabled =
                                        mutation ~= nil
                                end

                                if mutation then
                                    record.Label.Text =
                                        espEnv.__RAP_eggDisplayName(model)
                                        .. " | Mutation: "
                                        .. tostring(mutation)
                                        .. " | "
                                        .. tostring(math.floor(distance + 0.5))
                                        .. " studs"
                                end
                            else
                                record.Label.Text =
                                    espEnv.__RAP_eggDisplayName(model)
                                    .. " | "
                                    .. espEnv.__RAP_renderedEggKGText(
                                        model
                                    )
                                    .. " K.G"
                                    .. (
                                        mutation
                                        and (
                                            " | Mutation: "
                                            .. tostring(mutation)
                                        )
                                        or ""
                                    )
                                    .. " | "
                                    .. tostring(math.floor(distance + 0.5))
                                    .. " studs"
                            end
                        end
                    end
                end

                if Config.PlacedEggESP == true then
                    -- Placed egg name/weight are static. ChildAdded/Removed
                    -- already owns creation/removal, so the hot ESP loop only
                    -- cleans stale records. No repeated K.G descendant scan.
                    for model, record in pairs(
                        espEnv.__RAP_placedEggEspObjects
                    ) do
                        if not model.Parent
                            or not record.Adornee
                            or not record.Adornee.Parent then

                            espEnv.__RAP_removePlacedEggEsp(
                                model
                            )
                        end
                    end
                end

                if Config.PlayerESP == true then
                    for player, record in pairs(espEnv.__RAP_playerEspObjects) do
                        local targetRoot =
                            player.Character
                            and player.Character:FindFirstChild("HumanoidRootPart")

                        if not player.Parent
                            or not record.Adornee
                            or not record.Adornee.Parent
                            or not targetRoot then

                            espEnv.__RAP_removePlayerEsp(player)
                        else
                            local distance =
                                (root.Position - targetRoot.Position).Magnitude

                            local displayName =
                                tostring(player.DisplayName or player.Name)

                            if displayName ~= tostring(player.Name) then
                                displayName =
                                    displayName
                                    .. " (@"
                                    .. tostring(player.Name)
                                    .. ")"
                            end

                            record.Label.Text =
                                displayName
                                .. " | "
                                .. tostring(math.floor(distance + 0.5))
                                .. " studs"
                        end
                    end
                end
            end

            task.wait(
                (
                    Config.EggESP == true
                    or Config.EggMutationESP == true
                    or Config.PlayerESP == true
                )
                and 0.15
                or 1.0
            )
        end
    end)

    espEnv.__SERENITY_RAP_ESP_CLEANUP = function()
        espEnv.__RAP_clearEggEsp()
        espEnv.__RAP_clearPlacedEggEsp()
        espEnv.__RAP_clearPlayerEsp()
        espEnv.__RAP_disconnectRenderedEggFolder()
        espEnv.__RAP_disconnectPlacedEggFolder()
    end

    -- Visible UI strings stay canonical English here.
    -- Serenity V3 localizes display text from the shared 10-language dictionary
    -- while callbacks/config values remain unchanged.
    local manifest = {
        SerenityAPIVersion = 3,
        ConfigPath = "SerenityHub/RideAPet_M423Test_UI_Config.json",
        GameName = "Ride A Pet",
        DesktopWidth = 920,
        DesktopHeight = 570,
        Pages = {
            {
                Id = "Dashboard",
                Title = "Dashboard",
                Icon = "layout-dashboard",
                Description = "Ride A Pet automation status.",
                Features = {
                    {
                        Id = "Status",
                        Title = "Ride A Pet",
                        Description = "Ride A Pet automation features.",
                        Accent = "pink",
                        Controls = {
                            {
                                Id = "Core",
                                Type = "Paragraph",
                                Title = "Automation Features",
                                Text = "Movement cycle: Steal first, then Sell. During an active Auto Steal, Hatch, Place, Feed, Hatch Luck, Rebirth and Equip Best pause and automatically resume after the steal is fully finished.",
                            },
                            {
                                Id = "Prediction",
                                Type = "Paragraph",
                                Title = "Egg Information",
                                Text = "Egg rarity, Luck and spawn data are available before hatch. The exact pet result is revealed by the server only when the egg hatches.",
                            },
                        },
                    },
                },
            },

            {
                Id = "Eggs",
                Title = "Eggs",
                Icon = "egg",
                Description = "Steal, place and hatch eggs.",
                Features = {
                    {
                        Id = "Steal",
                        Title = "Auto Steal",
                        Description = "Uses current server eggs, Egg Luck and the game\'s real formatted K.G value.",
                        Accent = "pink",
                        Controls = {
                            {
                                Id = "Enabled",
                                Type = "Switch",
                                Title = "Auto Steal Eggs",
                                Description = "Minimum K.G is always required when enabled. After K.G passes, Minimum Luck or Specific Eggs can qualify the egg.",
                                Default = Config.AutoSteal == true,
                                Changed = function(v)
                                    uiSet("AutoSteal", v == true)
                                end,
                            },
                            {
                                Id = "InstantSteal",
                                Type = "Switch",
                                Title = "Instant Steal",
                                Description = "Directly teleports during normal Auto Steal. OFF uses Tween Speed and is the default. The special Volcanic Egg route keeps its collision-safe path.",
                                Default = Config.InstantSteal == true,
                                Changed = function(v)
                                    uiSet(
                                        "InstantSteal",
                                        v == true
                                    )
                                end,
                            },
                            {
                                Id = "ReturnTweenSpeed",
                                Type = "Slider",
                                Title = "Auto Steal Tween Speed",
                                Description = "Used when Instant Steal is OFF. Controls normal Auto Steal travel, Volcano transfer, and garden return. Safety range: 250-4000.",
                                Min = 250,
                                Max = 4000,
                                Step = 1,
                                Default = math.clamp(
                                    tonumber(
                                        Config.GardenReturnTweenSpeed
                                    )
                                    or 2000,
                                    250,
                                    4000
                                ),
                                Changed = function(v)
                                    local speed =
                                        math.floor(
                                            math.clamp(
                                                tonumber(v)
                                                or 2000,
                                                250,
                                                4000
                                            )
                                            + 0.5
                                        )

                                    uiSet(
                                        "GardenReturnTweenSpeed",
                                        tostring(
                                            speed
                                        )
                                    )
                                end,
                            },
                            {
                                Id = "MinimumLuck",
                                Type = "Select",
                                Title = "Minimum Egg Luck",
                                Description = "Optional. Any disables the Luck filter.",
                                Options = {
                                    "Any",
                                    "1M",
                                    "10M",
                                    "100M",
                                    "1B",
                                    "5B",
                                    "10B",
                                    "100B",
                                    "1T",
                                    "10T",
                                    "100T",
                                },
                                Default = tostring(Config.StealMinLuck or "Any"),
                                Changed = function(v)
                                    uiSet("StealMinLuck", tostring(v))
                                end,
                            },
                            {
                                Id = "MinimumKG",
                                Type = "Input",
                                Title = "Minimum Egg K.G",
                                Description = "Hard requirement for every target when above 0. Example: 50k = 50,000 K.G.",
                                Default = tostring(Config.StealMinKG or "0"),
                                Placeholder = "Ex. 50k or 50000 K.G",
                                Changed = function(v)
                                    if shared.SerenityRideAPet.ParseCompactNumber(v) ~= nil then
                                        uiSet("StealMinKG", tostring(v))
                                    end
                                end,
                            },
                            {
                                Id = "MinimumKGGuide",
                                Type = "Paragraph",
                                Title = "Guide",
                                Text = "K.G must match first. Then Minimum Luck or Specific Eggs. Use 0 to disable K.G.",
                            },
                            {
                                Id = "SpecificEggs",
                                Type = "MultiSelect",
                                Title = "Specific Eggs",
                                Description = "Selected eggs can bypass Minimum Luck, but never Minimum K.G.",
                                Options = DynamicEggNames,
                                Default = normalizedSelection(Config.StealEggs),
                                EmptyMeansAll = true,
                                Changed = function(v)
                                    uiSet("StealEggs", normalizedSelection(v))
                                end,
                            },
                            {
                                Id = "Priority",
                                Type = "Select",
                                Title = "Steal Priority",
                                Description = "Highest to Lowest uses the highest Egg Luck currently in the server.",
                                Options = priorities,
                                Default = Config.StealPriority,
                                Changed = function(v)
                                    uiSet("StealPriority", tostring(v))
                                end,
                            },
                            {
                                Id = "AutoRejoinNoEgg",
                                Type = "Switch",
                                Title = "Auto Hop No K.G Match",
                                Description = "Hops if no valid K.G match. Minimum K.G = 0 disables hopping. A successful or natively claimed matching stock egg stays complete until that stock actually advances.",
                                Default = Config.AutoRejoinNoEgg == true,
                                Changed = function(v, window, adapter)
                                    local enabled =
                                        v == true

                                    uiSet(
                                        "AutoRejoinNoEgg",
                                        enabled
                                    )

                                    if enabled then
                                        local changed =
                                            shared.SerenityRideAPet.DisableHopUnsafeOptimizations(
                                                adapter
                                            )

                                        if changed
                                            and window
                                            and type(window.Notify) == "function" then

                                            window:Notify(
                                                "Reduce Lag and Remove Other Gardens were disabled for Server Hop stability"
                                            )
                                        end
                                    else
                                        shared.SerenityRideAPet.RefreshOptimizations()
                                    end
                                end,
                            },
                            {
                                Id = "AutoHopKGGuide",
                                Type = "Paragraph",
                                Title = "Guide",
                                Text = "Minimum K.G = 0 disables hopping. Otherwise a successful/native claimed match stays complete through rejoin for the current global egg-stock Index. A new global stock re-arms the hunt.",
                            },
                            {
                                Id = "RejoinIntervalSeconds",
                                Type = "Input",
                                Title = "Rejoin Interval (Seconds)",
                                Description = "Wait this long while no valid egg matches K.G plus Minimum Luck/Specific Eggs. A qualifying falling egg keeps the server.",
                                Default = tostring(
                                    Config.RejoinIntervalSeconds
                                    or "5"
                                ),
                                Placeholder = "5",
                                Changed = function(v)
                                    local seconds =
                                        tonumber(
                                            tostring(v or "")
                                        )

                                    if seconds ~= nil then
                                        seconds =
                                            math.clamp(
                                                seconds,
                                                0,
                                                3600
                                            )

                                        uiSet(
                                            "RejoinIntervalSeconds",
                                            tostring(seconds)
                                        )
                                    end
                                end,
                            },
                            {
                                Id = "HopServerNow",
                                Type = "Action",
                                Title = "Hop Server Now",
                                Description = "Join a different non-full public server. If Auto Steal is currently working, the hop waits until the steal and return are fully finished.",
                                Icon = "refresh-cw",
                                Callback = function(window, adapter)
                                    local fn =
                                        shared.SerenityRideAPet.RequestServerHopNow

                                    if type(fn) ~= "function" then
                                        if window
                                            and type(window.Notify) == "function" then

                                            window:Notify(
                                                "Server hop is still initializing"
                                            )
                                        end

                                        return
                                    end

                                    local ok, reason =
                                        fn()

                                    if window
                                        and type(window.Notify) == "function" then

                                        window:Notify(
                                            ok
                                            and "Server hop queued"
                                            or (
                                                "Server hop / "
                                                .. tostring(reason)
                                            )
                                        )
                                    end
                                end,
                            },
                            {
                                Id = "VolcanicMutationInSteal",
                                Type = "Switch",
                                Title = "Volcanic Mutation (In Steal)",
                                Description = "When enabled, normal stolen eggs teleport instantly to VolcanoTop, retry the native mutation until accepted, wait for the real Volcano result/return, then teleport home. The special Volcanic Egg route still uses its proven tween path.",
                                Default =
                                    Config.VolcanicMutationInSteal
                                        == true,
                                Changed = function(v)
                                    uiSet(
                                        "VolcanicMutationInSteal",
                                        v == true
                                    )
                                end,
                            },
                        },
                    },

                    {
                        Id = "Place",
                        Title = "Auto Place",
                        Description = "Place carried eggs into your own garden from anywhere on the map, with dynamic full detection.",
                        Accent = "cyan",
                        Controls = {
                            {
                                Id = "Enabled",
                                Type = "Switch",
                                Title = "Auto Place Eggs",
                                Description = "Place one eligible carried egg at a valid position in your garden even while your character is somewhere else.",
                                Default = Config.AutoPlace == true,
                                Changed = function(v)
                                    uiSet("AutoPlace", v == true)

                                    if v == true then
                                        local plot = ownPlot()
                                        local folder =
                                            plot and plot:FindFirstChild("Eggs")

                                        bindPlaceCapacityFolder(folder)
                                    end
                                end,
                            },
                            {
                                Id = "MinimumKG",
                                Type = "Input",
                                Title = "Minimum Egg K.G",
                                Description = "Only Auto Place carried eggs at or above this real displayed K.G. Supports 50k, 1.5m, commas and decimals. 0 disables the filter.",
                                Default = tostring(Config.PlaceMinKG or "0"),
                                Placeholder = "Ex. 50k or 50000 K.G",
                                Changed = function(v)
                                    if shared.SerenityRideAPet.ParseCompactNumber(v) ~= nil then
                                        uiSet("PlaceMinKG", tostring(v))
                                    end
                                end,
                            },
                            {
                                Id = "FilterMode",
                                Type = "Select",
                                Title = "Filter Mode",
                                Description = "Choose which carried eggs are allowed.",
                                Options = filterModes,
                                Default = Config.PlaceFilterMode,
                                Changed = function(v)
                                    uiSet("PlaceFilterMode", tostring(v))
                                end,
                            },
                            {
                                Id = "Rarities",
                                Type = "MultiSelect",
                                Title = "Rarities",
                                Description = "Eligible rarities for placement.",
                                Options = DynamicRarityNames,
                                Default = normalizedSelection(Config.PlaceRarities),
                                EmptyMeansAll = false,
                                Changed = function(v)
                                    uiSet("PlaceRarities", normalizedSelection(v))
                                end,
                            },
                            {
                                Id = "SpecificEggs",
                                Type = "MultiSelect",
                                Title = "Specific Eggs",
                                Description = "Eligible exact egg names for placement.",
                                Options = DynamicEggNames,
                                Default = normalizedSelection(Config.PlaceEggs),
                                EmptyMeansAll = false,
                                Changed = function(v)
                                    uiSet("PlaceEggs", normalizedSelection(v))
                                end,
                            },
                            {
                                Id = "Priority",
                                Type = "Select",
                                Title = "Place Priority",
                                Description = "Highest to Lowest or Lowest to Highest.",
                                Options = priorities,
                                Default = Config.PlacePriority,
                                Changed = function(v)
                                    uiSet("PlacePriority", tostring(v))
                                end,
                            },
                        },
                    },

                    {
                        Id = "Hatch",
                        Title = "Auto Hatch",
                        Description = "Detect fully-grown owned eggs anywhere in your base, move close, then hatch through the native readiness check.",
                        Accent = "green",
                        Controls = {
                            {
                                Id = "Enabled",
                                Type = "Switch",
                                Title = "Auto Hatch Ready Eggs",
                                Description = "Uses native growth data first, tweens close to the exact egg, then hatches once when the game reports it ready.",
                                Default = Config.AutoHatch == true,
                                Changed = function(v)
                                    uiSet("AutoHatch", v == true)
                                end,
                            },
                        },
                    },
                    {
                        Id = "BaseMaintenance",
                        Title = "Base Maintenance",
                        Description = "Keep only the remaining base-dependent automation reliable without constantly moving the player.",
                        Accent = "blue",
                        Controls = {
                            {
                                Id = "IdleReturn",
                                Type = "Switch",
                                Title = "Return to Base When Idle",
                                Description = "If Auto Feed or Auto Hatch needs the base and you stay outside while stationary, request one return home. Auto Place works from anywhere. Real claimable Auto Steal targets always have priority.",
                                Default = Config.BaseMaintenanceIdleReturn ~= false,
                                Changed = function(v)
                                    uiSet(
                                        "BaseMaintenanceIdleReturn",
                                        v == true
                                    )
                                end,
                            },
                            {
                                Id = "IdleSeconds",
                                Type = "Input",
                                Title = "Outside Base Idle Seconds",
                                Description = "How long you must stay stationary outside your base before the maintenance return. Default: 60 seconds.",
                                Default = tostring(
                                    Config.BaseMaintenanceIdleSeconds
                                    or "60"
                                ),
                                Placeholder = "60",
                                Changed = function(v)
                                    local seconds =
                                        tonumber(
                                            tostring(v or "")
                                        )

                                    if seconds ~= nil then
                                        uiSet(
                                            "BaseMaintenanceIdleSeconds",
                                            tostring(
                                                math.clamp(
                                                    seconds,
                                                    3,
                                                    300
                                                )
                                            )
                                        )
                                    end
                                end,
                            },
                        },
                    },
                },
            },

            {
                Id = "Webhook",
                Title = "Webhook",
                Icon = "send",
                Description = "Discord notifications for confirmed Ride A Pet events.",
                Features = {
                    {
                        Id = "StealNotifications",
                        Title = "Steal Notifications",
                        Description = "Send Discord notifications only after confirmed successful egg steals.",
                        Accent = "purple",
                        Controls = {
                            {
                                Id = "Enabled",
                                Type = "Switch",
                                Title = "Steal Webhook",
                                Description = "Send filtered confirmed steals to your Discord webhook.",
                                Default = Config.WebhookEnabled == true,
                                Changed = function(v)
                                    uiSet(
                                        "WebhookEnabled",
                                        v == true
                                    )
                                end,
                            },
                            {
                                Id = "URL",
                                Type = "Input",
                                Title = "Discord Webhook URL",
                                Description = "Stored only in your local Ride A Pet config.",
                                Default = tostring(
                                    Config.WebhookURL
                                    or ""
                                ),
                                Placeholder = "https://discord.com/api/webhooks/...",
                                Changed = function(v)
                                    uiSet(
                                        "WebhookURL",
                                        tostring(v or "")
                                    )
                                end,
                            },
                            {
                                Id = "Eggs",
                                Type = "MultiSelect",
                                Title = "Webhook Eggs",
                                Description = "Choose which stolen egg types notify you. Empty means all eggs.",
                                Options = DynamicEggNames,
                                Default =
                                    normalizedSelection(
                                        Config.WebhookEggs
                                    ),
                                EmptyMeansAll = true,
                                Changed = function(v)
                                    uiSet(
                                        "WebhookEggs",
                                        normalizedSelection(v)
                                    )
                                end,
                            },
                            {
                                Id = "Rarities",
                                Type = "MultiSelect",
                                Title = "Webhook Rarities",
                                Description = "Choose which rarities notify you. Empty means all rarities.",
                                Options = DynamicRarityNames,
                                Default =
                                    normalizedSelection(
                                        Config.WebhookRarities
                                    ),
                                EmptyMeansAll = true,
                                Changed = function(v)
                                    uiSet(
                                        "WebhookRarities",
                                        normalizedSelection(v)
                                    )
                                end,
                            },
                            {
                                Id = "MinimumKG",
                                Type = "Input",
                                Title = "Webhook Minimum K.G",
                                Description = "Optional notification-only K.G filter. 50k and 50000 both mean 50,000 K.G. Use 0 for any.",
                                Default = tostring(
                                    Config.WebhookMinKG
                                    or "0"
                                ),
                                Placeholder = "0",
                                Changed = function(v)
                                    if shared.SerenityRideAPet.ParseCompactNumber(
                                        v
                                    ) ~= nil then

                                        uiSet(
                                            "WebhookMinKG",
                                            tostring(v)
                                        )
                                    end
                                end,
                            },
                            {
                                Id = "Test",
                                Type = "Action",
                                Title = "Test Webhook",
                                Description = "Send a test embed without stealing an egg. The test never includes the Serenity Discord invite.",
                                Icon = "send",
                                Callback = function(window, adapter)
                                    local ok, reason =
                                        shared.SerenityRideAPet.SendWebhookTest()

                                    log("")
                                    log("=== WEBHOOK_TEST ===")
                                    log("Success=" .. tostring(ok))
                                    log("Reason=" .. tostring(reason))

                                    if window
                                        and type(window.Notify) == "function" then

                                        window:Notify(
                                            ok
                                            and "Webhook test sent"
                                            or (
                                                "Webhook test failed / "
                                                .. tostring(reason)
                                            )
                                        )
                                    end
                                end,
                            },
                        },
                    },
                    {
                        Id = "MutationNotifications",
                        Title = "Mutation Notifications",
                        Description = "Notify when one of your placed pets gains a new mutation.",
                        Accent = "purple",
                        Controls = {
                            {
                                Id = "Enabled",
                                Type = "Switch",
                                Title = "Mutation Webhook",
                                Description = "Send a webhook after a new pet mutation is detected.",
                                Default = Config.MutationWebhookEnabled == true,
                                Changed = function(v)
                                    uiSet(
                                        "MutationWebhookEnabled",
                                        v == true
                                    )
                                end,
                            },
                        },
                    },
                },
            },

            {
                Id = "Shop",
                Title = "Shop",
                Icon = "shopping-cart",
                Description = "Use Ride A Pet's own native Auto-Buy.",
                Features = {
                    {
                        Id = "Food",
                        Title = "Food Auto-Buy",
                        Description = "Mirrors the original in-game Auto-Buy switches.",
                        Accent = "green",
                        Controls = {
                            {
                                Id = "Enabled",
                                Type = "Switch",
                                Title = "Enable Food Auto-Buy",
                                Description = "Enable native Auto-Buy for the selected food.",
                                Default = Config.AutoShopFood == true,
                                Changed = function(v)
                                    uiSet("AutoShopFood", v == true)
                                    nativeAutoBuyApplied = {}
                                    task.defer(syncNativeAutoBuy, true)
                                end,
                            },
                            {
                                Id = "Items",
                                Type = "MultiSelect",
                                Title = "Food",
                                Description = "Choose food items whose original Auto-Buy switch should be enabled.",
                                Options = FOOD_AUTO_BUY_ITEMS,
                                Default = normalizedSelection(Config.ShopFoodAutoBuyItems),
                                EmptyMeansAll = false,
                                Changed = function(v)
                                    uiSet("ShopFoodAutoBuyItems", normalizedSelection(v))
                                    nativeAutoBuyApplied = {}
                                    task.defer(syncNativeAutoBuy, true)
                                end,
                            },
                        },
                    },

                    {
                        Id = "Gears",
                        Title = "Gear Auto-Buy",
                        Description = "Uses the Auto-Buy already present in the gear shop.",
                        Accent = "blue",
                        Controls = {
                            {
                                Id = "Enabled",
                                Type = "Switch",
                                Title = "Enable Gear Auto-Buy",
                                Description = "Enable native Auto-Buy for selected gears.",
                                Default = Config.AutoShopGears == true,
                                Changed = function(v)
                                    uiSet("AutoShopGears", v == true)
                                    nativeAutoBuyApplied = {}
                                    task.defer(syncNativeAutoBuy, true)
                                end,
                            },
                            {
                                Id = "Items",
                                Type = "MultiSelect",
                                Title = "Gears",
                                Description = "Choose gears whose original Auto-Buy switch should be enabled.",
                                Options = GEAR_AUTO_BUY_ITEMS,
                                Default = normalizedSelection(Config.ShopGearAutoBuyItems),
                                EmptyMeansAll = false,
                                Changed = function(v)
                                    uiSet("ShopGearAutoBuyItems", normalizedSelection(v))
                                    nativeAutoBuyApplied = {}
                                    task.defer(syncNativeAutoBuy, true)
                                end,
                            },
                        },
                    },
                },
            },

            {
                Id = "Pets",
                Title = "Pets",
                Icon = "paw-print",
                Description = "Feed and sell pets.",
                Features = {
                    {
                        Id = "EquipBest",
                        Title = "Auto Equip Best",
                        Description = "Uses the game's Place Best and only runs again when your pet inventory or garden changes.",
                        Accent = "purple",
                        Controls = {
                            {
                                Id = "Enabled",
                                Type = "Switch",
                                Title = "Auto Equip Best",
                                Description = "Keep the best available pets placed without repeatedly pressing Place Best when nothing changed.",
                                Default = Config.AutoEquipBest == true,
                                Changed = function(v)
                                    uiSet("AutoEquipBest", v == true)

                                    if v == true then
                                        shared.SerenityRideAPet.AutoEquipBestState.Pending = true
                                        shared.SerenityRideAPet.AutoEquipBestState.LastSignature = nil
                                    end
                                end,
                            },
                            {
                                Id = "EquipNow",
                                Type = "Action",
                                Title = "Equip Best Now",
                                Description = "Run the game's Place Best once now.",
                                Icon = "sparkles",
                                Callback = function(window, adapter)
                                    local ran, ok, reason =
                                        shared.SerenityRideAPet.RunDirectAction(
                                            "EQUIP_BEST_MANUAL",
                                            function()
                                                return shared.SerenityRideAPet.RequestAutoEquipBest(
                                                    true
                                                )
                                            end
                                        )

                                    if not ran then
                                        ok = false
                                        reason = "steal action busy"
                                    end

                                    if window
                                        and type(window.Notify) == "function" then

                                        window:Notify(
                                            ok
                                            and "Place Best triggered"
                                            or (
                                                "Place Best / "
                                                .. tostring(reason)
                                            )
                                        )
                                    end
                                end,
                            },
                        },
                    },
                    {
                        Id = "AutoSell",
                        Title = "Auto Sell Pets",
                        Description = "Sells eligible pets through Richie. Your current ride is only dismounted when a real sale is ready to begin.",
                        Accent = "pink",
                        Controls = {
                            {
                                Id = "Enabled",
                                Type = "Switch",
                                Title = "Auto Sell Pets",
                                Description = "Sell one eligible pet at a time through Richie.",
                                Default = Config.AutoSell == true,
                                Changed = function(v)
                                    uiSet("AutoSell", v == true)

                                    if v == true then
                                        log("AutoSellEnabled=true")
                                    end
                                end,
                            },
                            {
                                Id = "Rarities",
                                Type = "MultiSelect",
                                Title = "Sell Rarities",
                                Description = "Only these rarities can be sold. Empty selection sells nothing.",
                                Options = DynamicPetRarities,
                                Default = normalizedSelection(Config.AutoSellRarities),
                                EmptyMeansAll = false,
                                Changed = function(v)
                                    uiSet(
                                        "AutoSellRarities",
                                        normalizedSelection(v)
                                    )
                                end,
                            },
                            {
                                Id = "MaximumPerSecond",
                                Type = "Input",
                                Title = "Maximum $/s to Sell",
                                Description = "Only sell pets earning this amount per second or less. 0 disables the $/s filter.",
                                Default = tostring(Config.AutoSellMaxPerSecond or "0"),
                                Placeholder = "Ex. 50k or 50000",
                                Changed = function(v)
                                    if shared.SerenityRideAPet.ParseCompactNumber(v) ~= nil then
                                        uiSet("AutoSellMaxPerSecond", tostring(v))
                                        shared.SerenityRideAPet.SellRateCache = {}
                                    end
                                end,
                            },
                            {
                                Id = "MaximumPerSecondGuide",
                                Type = "Paragraph",
                                Title = "Guide",
                                Text = "Example: 50k means pets earning $50K/s or less may be sold. Pets above $50K/s are protected. 50k and 50000 are both accepted. Use 0 to disable the filter.",
                            },
                            {
                                Id = "GardenProtection",
                                Type = "Switch",
                                Title = "Protect Garden Pets",
                                Description = "Never sell pets currently placed/equipped in your garden. Auto Sell uses unequipped inventory pets first.",
                                Default = Config.AutoSellProtectGardenPets ~= false,
                                Changed = function(v)
                                    uiSet(
                                        "AutoSellProtectGardenPets",
                                        v == true
                                    )
                                end,
                            },
                            {
                                Id = "FavoriteProtection",
                                Type = "Switch",
                                Title = "Protect Favorite Pets",
                                Description = "Never sell favorited pets.",
                                Default = Config.AutoSellProtectFavorites == true,
                                Changed = function(v)
                                    uiSet(
                                        "AutoSellProtectFavorites",
                                        v == true
                                    )
                                end,
                            },
                            {
                                Id = "LockedProtection",
                                Type = "Switch",
                                Title = "Protect Locked Pets",
                                Description = "Never sell locked pets.",
                                Default = Config.AutoSellProtectLocked == true,
                                Changed = function(v)
                                    uiSet(
                                        "AutoSellProtectLocked",
                                        v == true
                                    )
                                end,
                            },
                            {
                                Id = "CurrentProtection",
                                Type = "Switch",
                                Title = "Protect Current Pet",
                                Description = "Protect the pet currently being ridden/used.",
                                Default = Config.AutoSellProtectCurrentPet == true,
                                Changed = function(v)
                                    uiSet(
                                        "AutoSellProtectCurrentPet",
                                        v == true
                                    )
                                end,
                            },
                            {
                                Id = "Interval",
                                Type = "Input",
                                Title = "Sell Interval",
                                Description = "Seconds between confirmed sales. Minimum 1.",
                                Default = tostring(Config.SellIntervalSeconds or 8),
                                Numeric = true,
                                Integer = true,
                                Min = 1,
                                Changed = function(v)
                                    uiSetNumber(
                                        "SellIntervalSeconds",
                                        v,
                                        1
                                    )
                                end,
                            },
                        },
                    },
                    {
                        Id = "AutoFeed",
                        Title = "Auto Feed Pets",
                        Description = "Direct feeding with automatic food equip and fast server-confirmed spacing.",
                        Accent = "blue",
                        Controls = {
                            {
                                Id = "Enabled",
                                Type = "Switch",
                                Title = "Auto Feed Pets",
                                Description = "Automatically feed placed pets using selected food.",
                                Default = Config.AutoFeed == true,
                                Changed = function(v)
                                    uiSet("AutoFeed", v == true)
                                end,
                            },
                            {
                                Id = "Foods",
                                Type = "MultiSelect",
                                Title = "Foods",
                                Description = "Choose foods to use. If one is empty, Auto Feed switches to another selected food.",
                                Options = DynamicFeedFoods,
                                Default = normalizedSelection(Config.AutoFeedFoods),
                                EmptyMeansAll = false,
                                Changed = function(v)
                                    uiSet(
                                        "AutoFeedFoods",
                                        normalizedSelection(v)
                                    )
                                end,
                            },
                            {
                                Id = "Targets",
                                Type = "Select",
                                Title = "Feed Targets",
                                Description = "Feed all placed pets or only selected placed pets.",
                                Options = {
                                    "All Placed Pets",
                                    "Selected Pets",
                                },
                                Default = tostring(
                                    Config.AutoFeedTargetMode
                                    or "All Placed Pets"
                                ),
                                Changed = function(v)
                                    uiSet(
                                        "AutoFeedTargetMode",
                                        tostring(v)
                                    )

                                    if tostring(v) == "Selected Pets" then
                                        task.defer(function()
                                            local app =
                                                serenityEnv.__SERENITY_RAP_APP

                                            if app then
                                                shared.SerenityRideAPet.RefreshFeedGarden(
                                                    app.Adapter
                                                    or app
                                                )
                                            end
                                        end)
                                    end
                                end,
                            },
                            {
                                Id = "RefreshGarden",
                                Type = "Action",
                                Title = "Refresh Garden",
                                Description = "Refresh the current placed pets used by Selected Pets.",
                                Icon = "refresh-cw",
                                Callback = function(window, adapter)
                                    local count =
                                        shared.SerenityRideAPet.RefreshFeedGarden(
                                            adapter
                                        )

                                    if window
                                        and type(window.Notify) == "function" then

                                        window:Notify(
                                            "Garden refreshed / "
                                            .. tostring(count)
                                            .. " / placed pet(s)"
                                        )
                                    end
                                end,
                            },
                            {
                                Id = "Pets",
                                Type = "MultiSelect",
                                Title = "Selected Pets",
                                Description = "Displayed as Pet Name (Age X). Used when Feed Targets is Selected Pets.",
                                Options = DynamicFeedPetOptions,
                                Default = savedFeedPetLabels(),
                                EmptyMeansAll = false,
                                Changed = function(v)
                                    uiSet(
                                        "AutoFeedPetKeys",
                                        feedLabelsToKeys(v)
                                    )
                                end,
                            },
                        },
                    },
                    {
                        Id = "WeatherPetSwap",
                        Title = "Weather Pet Swap",
                        Description = "Temporarily change the pets placed on your farm when a specific weather is active.",
                        Accent = "purple",
                        Controls = {
                            {
                                Id = "Enabled",
                                Type = "Switch",
                                Title = "Auto Change Farm Pets by Weather",
                                Description = "Swaps farm pets during selected weather. Steal stays priority.",
                                Default = Config.AutoWeatherPetSwap == true,
                                Changed = function(v)
                                    uiSet(
                                        "AutoWeatherPetSwap",
                                        v == true
                                    )

                                    if v ~= true
                                        and shared.SerenityRideAPet.WeatherPetLayoutActive
                                        and shared.SerenityRideAPet.WeatherPetLayoutActive()
                                        and Config.WeatherRestorePrevious == true then

                                        task.defer(function()
                                            shared.SerenityRideAPet.RunDirectAction(
                                                "WEATHER_PETS",
                                                shared.SerenityRideAPet.RestoreWeatherPetLayout
                                            )
                                        end)
                                    end
                                end,
                            },
                            {
                                Id = "WeatherVariants",
                                Type = "MultiSelect",
                                Title = "Specific Weather",
                                Description = "Choose any actual storm variants you want: Dreadful, Eternal, Volt, Raging, Thunder, Gigantuar, and future variants exposed by the game.",
                                Options = shared.SerenityRideAPet.WeatherFeature.Options,
                                Default = normalizedSelection(
                                    Config.WeatherVariants
                                ),
                                EmptyMeansAll = false,
                                Changed = function(v)
                                    uiSet(
                                        "WeatherVariants",
                                        normalizedSelection(v)
                                    )
                                end,
                            },
                            {
                                Id = "AutoHighestNoMutation",
                                Type = "Switch",
                                Title = "Auto Swap Highest Pet (No Mutation)",
                                Description = "ON: highest $/s mutation-free pets. OFF: selected pets below.",
                                Default = Config.WeatherAutoHighestNoMutation == true,
                                Changed = function(v)
                                    uiSet(
                                        "WeatherAutoHighestNoMutation",
                                        v == true
                                    )
                                end,
                            },
                            {
                                Id = "AutoHighestNoMutationGuide",
                                Type = "Paragraph",
                                Title = "Guide",
                                Text = "ON: highest $/s mutation-free pets. OFF: selected pets below.",
                            },
                            {
                                Id = "DetectWeather",
                                Type = "Action",
                                Title = "Detect Current Weather",
                                Description = "Show the actual active server weather variant(s) Serenity can see.",
                                Icon = "search",
                                Callback = function(window, adapter)
                                    shared.SerenityRideAPet.DiscoverWeatherSources(
                                        true
                                    )

                                    local current =
                                        shared.SerenityRideAPet.GetCurrentWeathers()

                                    local textValue =
                                        #current > 0
                                        and table.concat(
                                            current,
                                            ", "
                                        )
                                        or "Unknown"

                                    if window
                                        and type(window.Notify) == "function" then

                                        window:Notify(
                                            "Current weather / "
                                            .. tostring(textValue)
                                        )
                                    end
                                end,
                            },
                            {
                                Id = "RefreshPets",
                                Type = "Action",
                                Title = "Refresh Pet List",
                                Description = "Refresh all owned garden and inventory pets available for the weather swap.",
                                Icon = "refresh-cw",
                                Callback = function(window, adapter)
                                    local count =
                                        shared.SerenityRideAPet.RefreshWeatherPets(
                                            adapter
                                        )

                                    if window
                                        and type(window.Notify) == "function" then

                                        window:Notify(
                                            "Weather pet list refreshed / "
                                            .. tostring(count)
                                            .. " / pet(s)"
                                        )
                                    end
                                end,
                            },
                            {
                                Id = "Pets",
                                Type = "MultiSelect",
                                Title = "Selected Pets",
                                Description = "Used when Auto Swap Highest Pet is OFF.",
                                Options = shared.SerenityRideAPet.WeatherFeature.PetOptions,
                                Default = shared.SerenityRideAPet.WeatherFeature.SavedPetLabels(),
                                EmptyMeansAll = false,
                                Changed = function(v)
                                    uiSet(
                                        "WeatherPetKeys",
                                        shared.SerenityRideAPet.WeatherFeature.LabelsToKeys(v)
                                    )
                                end,
                            },
                            {
                                Id = "RestorePrevious",
                                Type = "Switch",
                                Title = "Restore Previous Pets After Weather",
                                Description = "Restores your old farm pets when weather ends.",
                                Default = Config.WeatherRestorePrevious ~= false,
                                Changed = function(v)
                                    uiSet(
                                        "WeatherRestorePrevious",
                                        v == true
                                    )
                                end,
                            },
                        },
                    },
                },
            },

            {
                Id = "ESP",
                Title = "ESP",
                Icon = "eye",
                Description = "World egg, mutation, placed egg, and player visual overlays.",
                Features = {
                    {
                        Id = "VisualESP",
                        Title = "ESP",
                        Description = "Lightweight local-only ESP for world eggs, mutations, your placed eggs, and players.",
                        Accent = "blue",
                        Controls = {
                            {
                                Id = "EggESP",
                                Type = "Switch",
                                Title = "Egg ESP",
                                Description = "Show a box plus egg name and distance.",
                                Default = Config.EggESP == true,
                                Changed = function(v)
                                    espEnv.__RAP_setEggEspEnabled(v == true)
                                end,
                            },
                            {
                                Id = "EggMutationESP",
                                Type = "Switch",
                                Title = "Egg Mutation ESP",
                                Description = "Show world eggs that have a replicated Mutation. If Egg ESP is also ON, mutation is appended to the existing label.",
                                Default = Config.EggMutationESP == true,
                                Changed = function(v)
                                    espEnv.__RAP_setEggMutationEspEnabled(
                                        v == true
                                    )
                                end,
                            },
                            {
                                Id = "PlacedEggESP",
                                Type = "Switch",
                                Title = "Placed Egg ESP",
                                Description = "Show clean text-only egg name + real K.G for eggs already placed in your own garden. No hitbox or highlight.",
                                Default = Config.PlacedEggESP == true,
                                Changed = function(v)
                                    espEnv.__RAP_setPlacedEggEspEnabled(
                                        v == true
                                    )
                                end,
                            },
                            {
                                Id = "EggESPMinLuck",
                                Type = "Select",
                                Title = "ESP Minimum Egg Luck",
                                Description = "Only show eggs at or above this Egg Luck.",
                                Options = {
                                    "1M",
                                    "10M",
                                    "100M",
                                    "1B",
                                    "10B",
                                    "100B",
                                    "1T",
                                    "10T",
                                    "100T",
                                },
                                Default = tostring(Config.EggESPMinLuck or "1M"),
                                Changed = function(v)
                                    uiSet("EggESPMinLuck", tostring(v))
                                    espEnv.__RAP_refreshEggEsp()
                                end,
                            },
                            {
                                Id = "PlayerESP",
                                Type = "Switch",
                                Title = "Player ESP",
                                Description = "Highlight other players and show name + distance.",
                                Default = Config.PlayerESP == true,
                                Changed = function(v)
                                    espEnv.__RAP_setPlayerEspEnabled(v == true)
                                end,
                            },
                        },
                    },
                },
            },

            {
                Id = "Misc",
                Title = "Misc",
                Icon = "menu",
                Description = "Other utilities and saved configuration.",
                Features = {
                    {
                        Id = "Others",
                        Title = "Others",
                        Description = "Other utility settings.",
                        Accent = "purple",
                        Controls = {
                            {
                                Id = "AntiAFK",
                                Type = "Switch",
                                Title = "Anti-AFK",
                                Description = "Prevent idle disconnects using Ride A Pet-safe mouse movement only.",
                                Default = Config.AntiAFK == true,
                                Changed = function(v)
                                    uiSet("AntiAFK", v == true)
                                end,
                            },
                            {
                                Id = "AutoExecuteOnTeleport",
                                Type = "Switch",
                                Title = "Auto Execute After Teleport / Reconnect",
                                Description = "Queue the deployed Serenity GitHub loader for the next teleport or reconnect. Works independently from Auto Hop No K.G Match.",
                                Default = Config.AutoExecuteOnTeleport == true,
                                Changed = function(v)
                                    uiSet(
                                        "AutoExecuteOnTeleport",
                                        v == true
                                    )

                                    serenityEnv.__SERENITY_RAP_AUTO_EXECUTE_ENABLED =
                                        v == true

                                    local session =
                                        shared.SerenityRideAPet.SessionRuntime

                                    if v == true
                                        and session
                                        and session.LoaderQueued ~= true then

                                        session.LoaderQueued = false
                                    end

                                    if type(
                                        shared.SerenityRideAPet.RefreshSessionProtection
                                    ) == "function" then
                                        shared.SerenityRideAPet.RefreshSessionProtection()
                                    end
                                end,
                            },
                            {
                                Id = "AutoReconnectOnDisconnect",
                                Type = "Switch",
                                Title = "Auto Reconnect When Disconnected",
                                Description = "Automatically rejoin Ride A Pet when Roblox shows a disconnect/error prompt. Anti-AFK still handles normal idle prevention.",
                                Default = Config.AutoReconnectOnDisconnect == true,
                                Changed = function(v, window, adapter)
                                    local enabled =
                                        v == true

                                    uiSet(
                                        "AutoReconnectOnDisconnect",
                                        enabled
                                    )

                                    if enabled then
                                        shared.SerenityRideAPet
                                            .DisableHopUnsafeOptimizations(
                                                adapter
                                            )
                                    else
                                        shared.SerenityRideAPet
                                            .RefreshOptimizations()
                                    end

                                    if type(
                                        shared.SerenityRideAPet.RefreshSessionProtection
                                    ) == "function" then
                                        shared.SerenityRideAPet.RefreshSessionProtection()
                                    end
                                end,
                            },
                            {
                                Id = "AutoReconnectDelaySeconds",
                                Type = "Input",
                                Title = "Auto Reconnect Delay (Seconds)",
                                Description = "Small delay before reconnecting after a disconnect prompt. Default is 3 seconds.",
                                Default = tostring(
                                    Config.AutoReconnectDelaySeconds
                                    or "3"
                                ),
                                Placeholder = "3",
                                Changed = function(v)
                                    local seconds =
                                        tonumber(
                                            tostring(v or "")
                                        )

                                    if seconds ~= nil then
                                        seconds =
                                            math.clamp(
                                                seconds,
                                                1,
                                                30
                                            )

                                        uiSet(
                                            "AutoReconnectDelaySeconds",
                                            tostring(seconds)
                                        )
                                    end
                                end,
                            },
                        },
                    },
                    {
                        Id = "Movement",
                        Title = "Movement",
                        Description = "Manual local movement controls. Sliders only; no speed typing required.",
                        Accent = "blue",
                        Controls = {
                            {
                                Id = "Noclip",
                                Type = "Switch",
                                Title = "Noclip",
                                Description = "Manual-only noclip toggle. Auto Steal and Volcano automation never use noclip.",
                                Default = Config.PlayerNoclip == true,
                                Changed = function(v)
                                    local enabled = v == true
                                    uiSet("PlayerNoclip", enabled)
                                    if type(shared.SerenityRideAPet.SetPlayerNoclip) == "function" then shared.SerenityRideAPet.SetPlayerNoclip(enabled) end
                                end,
                            },
                            {
                                Id = "SpeedHack",
                                Type = "Switch",
                                Title = "Speed Hack",
                                Description = "OFF restores the original WalkSpeed. ON uses the slider below.",
                                Default = Config.SpeedHackEnabled == true,
                                Changed = function(v)
                                    local enabled = v == true
                                    uiSet("SpeedHackEnabled", enabled)
                                    if type(shared.SerenityRideAPet.SetSpeedHack) == "function" then shared.SerenityRideAPet.SetSpeedHack(enabled) end
                                end,
                            },
                            {
                                Id = "WalkSpeed",
                                Type = "Slider",
                                Title = "Speed",
                                Description = "Default 16. Maximum 5000.",
                                Min = 16,
                                Max = 5000,
                                Step = 1,
                                Default = math.floor(math.clamp(tonumber(Config.SpeedHackSpeed) or 16, 16, 5000) + 0.5),
                                Changed = function(v)
                                    local speed = math.floor(math.clamp(tonumber(v) or 16, 16, 5000) + 0.5)
                                    uiSet("SpeedHackSpeed", speed)
                                    if type(shared.SerenityRideAPet.SetSpeedHackSpeed) == "function" then shared.SerenityRideAPet.SetSpeedHackSpeed(speed) end
                                end,
                            },
                            {
                                Id = "Fly",
                                Type = "Switch",
                                Title = "Fly",
                                Description = "Manual fly toggle. Fly pauses its force automatically while Serenity is moving for Steal/Sell.",
                                Default = Config.FlyEnabled == true,
                                Changed = function(v)
                                    local enabled = v == true
                                    uiSet("FlyEnabled", enabled)
                                    if type(shared.SerenityRideAPet.SetFly) == "function" then shared.SerenityRideAPet.SetFly(enabled) end
                                end,
                            },
                            {
                                Id = "FlySpeed",
                                Type = "Slider",
                                Title = "Fly Speed",
                                Description = "Maximum 5000. Move normally; Space/E goes up and Ctrl/Shift/Q goes down.",
                                Min = 1,
                                Max = 5000,
                                Step = 1,
                                Default = math.floor(math.clamp(tonumber(Config.FlySpeed) or 70, 1, 5000) + 0.5),
                                Changed = function(v)
                                    local speed = math.floor(math.clamp(tonumber(v) or 70, 1, 5000) + 0.5)
                                    uiSet("FlySpeed", speed)
                                    if type(shared.SerenityRideAPet.SetFlySpeed) == "function" then shared.SerenityRideAPet.SetFlySpeed(speed) end
                                end,
                            },
                        },
                    },
                    {
                        Id = "Optimization",
                        Title = "Optimization",
                        Description = "Client-side performance options. All changes are reversible.",
                        Accent = "green",
                        Controls = {
                            {
                                Id = "ReduceLag",
                                Type = "Switch",
                                Title = "Reduce Lag",
                                Description = "Disable particles, trails, beams, shadows, post-processing and expensive terrain effects.",
                                Default = Config.ReduceLag == true,
                                Changed = function(v, window, adapter)
                                    local ok, reason =
                                        shared.SerenityRideAPet.SetOptimization(
                                            "ReduceLag",
                                            v == true
                                        )

                                    if not ok
                                        and v == true
                                        and adapter then

                                        pcall(function()
                                            adapter:SetLive(
                                                "Misc.Optimization.ReduceLag",
                                                false
                                            )
                                        end)

                                        if adapter.Config
                                            and type(adapter.Config.Set) == "function" then

                                            pcall(function()
                                                adapter.Config:Set(
                                                    "Misc.Optimization.ReduceLag",
                                                    false,
                                                    true
                                                )

                                                if type(adapter.Config.SaveNow) == "function" then
                                                    adapter.Config:SaveNow()
                                                end
                                            end)
                                        end

                                        if window
                                            and type(window.Notify) == "function" then

                                            window:Notify(
                                                tostring(reason)
                                            )
                                        end
                                    end
                                end,
                            },
                            {
                                Id = "Disable3D",
                                Type = "Switch",
                                Title = "Disable 3D Rendering",
                                Description = "Turn off the 3D world renderer while keeping the interface visible. Disable this toggle to restore 3D.",
                                Default = Config.Disable3DRendering == true,
                                Changed = function(v)
                                    shared.SerenityRideAPet.SetOptimization(
                                        "Disable3DRendering",
                                        v == true
                                    )
                                end,
                            },
                            {
                                Id = "BlackScreen",
                                Type = "Switch",
                                Title = "Black Screen",
                                Description = "Turn off 3D rendering and cover the world with a true black background while keeping UI layers visible.",
                                Default = Config.BlackScreen == true,
                                Changed = function(v)
                                    shared.SerenityRideAPet.SetOptimization(
                                        "BlackScreen",
                                        v == true
                                    )
                                end,
                            },
                            {
                                Id = "RemoveOtherGardens",
                                Type = "Switch",
                                Title = "Remove Other Players' Gardens",
                                Description = "Locally hide and disable other players' garden visuals/effects while keeping your own garden untouched.",
                                Default = Config.RemoveOtherGardens == true,
                                Changed = function(v, window, adapter)
                                    local ok, reason =
                                        shared.SerenityRideAPet.SetOptimization(
                                            "RemoveOtherGardens",
                                            v == true
                                        )

                                    if not ok
                                        and v == true
                                        and adapter then

                                        pcall(function()
                                            adapter:SetLive(
                                                "Misc.Optimization.RemoveOtherGardens",
                                                false
                                            )
                                        end)

                                        if adapter.Config
                                            and type(adapter.Config.Set) == "function" then

                                            pcall(function()
                                                adapter.Config:Set(
                                                    "Misc.Optimization.RemoveOtherGardens",
                                                    false,
                                                    true
                                                )

                                                if type(adapter.Config.SaveNow) == "function" then
                                                    adapter.Config:SaveNow()
                                                end
                                            end)
                                        end

                                        if window
                                            and type(window.Notify) == "function" then

                                            window:Notify(
                                                tostring(reason)
                                            )
                                        end
                                    end
                                end,
                            },
                        },
                    },
                    {
                        Id = "SavedConfig",
                        Title = "Saved Config",
                        Description = "Save or reset Ride A Pet settings.",
                        Accent = "blue",
                        Controls = {
                            {
                                Id = "Save",
                                Type = "Action",
                                Title = "Save Settings",
                                Description = "Save the current Ride A Pet settings now.",
                                Icon = "save",
                                Callback = function(window, adapter)
                                    local gameOk, gameErr =
                                        saveConfig()

                                    local uiOk = true

                                    if adapter
                                        and adapter.Config
                                        and type(adapter.Config.SaveNow) == "function" then

                                        local callOk, innerOk =
                                            pcall(function()
                                                return adapter.Config:SaveNow()
                                            end)

                                        uiOk =
                                            callOk
                                            and innerOk ~= false
                                    end

                                    if window
                                        and type(window.Notify) == "function" then

                                        if gameOk and uiOk then
                                            window:Notify(
                                                "Ride A Pet settings saved"
                                            )
                                        else
                                            window:Notify(
                                                "Save failed / "
                                                .. tostring(
                                                    gameErr
                                                    or "UI config save failed"
                                                )
                                            )
                                        end
                                    end
                                end,
                            },
                            {
                                Id = "Reset",
                                Type = "Action",
                                Title = "Reset Saved Config",
                                Description = "Restore Ride A Pet defaults. Anti-AFK returns ON; automations return OFF.",
                                Icon = "rotate-cw",
                                Callback = function(window, adapter)
                                    Config =
                                        deepCopy(DEFAULT_CONFIG)

                                    local gameOk, gameErr =
                                        saveConfig()

                                    shared.SerenityRideAPet.Config =
                                        Config

                                    -- Clear Serenity V3's persisted game-control
                                    -- state too. Keeping Data empty is important:
                                    -- Config:Destroy() saves this object again.
                                    if adapter
                                        and adapter.Config then

                                        adapter.Config.Data = {
                                            __ConfigVersion =
                                                adapter.Config.SchemaVersion
                                                or 1,
                                        }

                                        if type(adapter.Config.SaveNow) == "function" then
                                            pcall(function()
                                                adapter.Config:SaveNow()
                                            end)
                                        end
                                    end

                                    -- Apply important runtime defaults now.
                                    espEnv.__RAP_clearEggEsp()
                                    espEnv.__RAP_clearPlayerEsp()

                                    nativeAutoBuyApplied = {}
                                    task.defer(
                                        syncNativeAutoBuy,
                                        true
                                    )

                                    shared.SerenityRideAPet.RefreshOptimizations()

                                    if type(shared.SerenityRideAPet.RefreshPlayerMovementSettings) == "function" then
                                        shared.SerenityRideAPet.RefreshPlayerMovementSettings()
                                    end

                                    shared.SerenityRideAPet.EndStealAction()

                                    if shared.SerenityRideAPet.EnsureMovementLaneWorker then
                                        pcall(
                                            shared.SerenityRideAPet.EnsureMovementLaneWorker,
                                            "config-reset",
                                            true
                                        )
                                    end

                                    if window
                                        and type(window.Notify) == "function" then

                                        window:Notify(
                                            gameOk
                                            and "Saved config reset · re-execute once to refresh all controls"
                                            or (
                                                "Reset failed / "
                                                .. tostring(gameErr)
                                            )
                                        )
                                    end
                                end,
                            },
                        },
                    },
                },
            },

            {
                Id = "Upgrades",
                Title = "Upgrades",
                Icon = "trending-up",
                Description = "Automatic game upgrades.",
                Features = {
                    {
                        Id = "HatchLuck",
                        Title = "Hatch Luck Upgrade",
                        Description = "Automatically use the game's native Max Hatch Luck purchase for all currently free or affordable upgrades.",
                        Accent = "purple",
                        Controls = {
                            {
                                Id = "Enabled",
                                Type = "Switch",
                                Title = "Auto Hatch Luck Upgrade",
                                Description = "Uses the game's native Max purchase, buying every currently free or affordable Hatch Luck upgrade in one request.",
                                Default = Config.AutoHatchLuck == true,
                                Changed = function(v)
                                    uiSet("AutoHatchLuck", v == true)
                                end,
                            },
                        },
                    },
                    {
                        Id = "Rebirth",
                        Title = "Auto Rebirth Requirements",
                        Description = "Automatically obtain the next required pet from your owned non-premium eggs, then rebirth when the exact cash and pet requirements are ready.",
                        Accent = "purple",
                        Controls = {
                            {
                                Id = "Enabled",
                                Type = "Switch",
                                Title = "Auto Rebirth Requirements",
                                Description = "Find the next required pet, use the highest-chance owned egg, and when normal Auto Steal has no target, let idle Auto Steal acquire a better world egg for that requirement. Normal Auto Steal priority is never overridden.",
                                Default = Config.AutoRebirth == true,
                                Changed = function(v)
                                    uiSet("AutoRebirth", v == true)
                                end,
                            },
                        },
                    },
                },
            },
        },
    }

    local buildOk, appOrErr = pcall(function()
        return SerenityUI.Build(manifest)
    end)

    if buildOk and appOrErr then
        serenityEnv.__SERENITY_RAP_APP = appOrErr

        -- v80.2.96 mobile manual-pickup compatibility.
        -- Ride A Pet creates its own custom Prompt BillboardGui under
        -- PlayerGui.ProximityPrompts. On some mobile executor/device states,
        -- the visible Pickup prompt can exist without a working touch handler.
        -- Bridge the ACTUAL generated TextButton back to the real
        -- ProximityPrompt InputHoldBegin/InputHoldEnd path. This remains a
        -- user-initiated native prompt interaction; no EggPickup remote is
        -- fired here and Auto Steal/Volcanic behavior is untouched.
        do
            local oldCleanup =
                serenityEnv.__SERENITY_RAP_MOBILE_PICKUP_CLEANUP

            if type(oldCleanup) == "function" then
                pcall(oldCleanup)
            end

            serenityEnv.__SERENITY_RAP_MOBILE_PICKUP_CLEANUP = nil

            local inputService =
                game:GetService("UserInputService")

            if inputService.TouchEnabled == true then
                local players =
                    game:GetService("Players")

                local promptService =
                    game:GetService("ProximityPromptService")

                local playerGui =
                    players.LocalPlayer
                    and players.LocalPlayer:FindFirstChild("PlayerGui")

                local connections = {}
                local bridgedButtons =
                    setmetatable({}, { __mode = "k" })
                local bridgeBusy =
                    setmetatable({}, { __mode = "k" })

                local function stealBusy()
                    local runtime =
                        shared
                        and shared.SerenityRideAPet
                        and shared.SerenityRideAPet.StealActionRuntime

                    return
                        type(runtime) == "table"
                        and runtime.Busy == true
                end

                local function isPickupPrompt(prompt)
                    return
                        prompt
                        and prompt:IsA("ProximityPrompt")
                        and prompt.Name == "Pickup"
                        and prompt.Enabled == true
                end

                local function keepPickupClickable(prompt)
                    if not isPickupPrompt(prompt) then
                        return
                    end

                    pcall(function()
                        prompt.ClickablePrompt = true
                    end)
                end

                local function nativeTap(prompt)
                    if stealBusy()
                        or not isPickupPrompt(prompt)
                        or bridgeBusy[prompt] == true then

                        return
                    end

                    bridgeBusy[prompt] = true

                    local hold =
                        math.max(
                            0,
                            tonumber(prompt.HoldDuration) or 0
                        )

                    local began =
                        pcall(function()
                            prompt:InputHoldBegin()
                        end)

                    if not began then
                        bridgeBusy[prompt] = nil
                        return
                    end

                    task.delay(
                        hold + 0.04,
                        function()
                            pcall(function()
                                prompt:InputHoldEnd()
                            end)

                            bridgeBusy[prompt] = nil
                        end
                    )
                end

                local function bridgeButton(prompt, button, billboard)
                    if not button
                        or not button:IsA("GuiButton")
                        or bridgedButtons[button] then

                        return false
                    end

                    bridgedButtons[button] = true

                    pcall(function()
                        button.Active = true
                        button.Visible = true
                    end)

                    pcall(function()
                        button.Interactable = true
                    end)

                    if billboard then
                        pcall(function()
                            billboard.Active = true
                        end)
                    end

                    connections[#connections + 1] =
                        button.Activated:Connect(
                            function()
                                nativeTap(prompt)
                            end
                        )

                    return true
                end

                local function findAndBridgeGeneratedButton(prompt)
                    if not playerGui
                        or not isPickupPrompt(prompt) then

                        return
                    end

                    keepPickupClickable(prompt)

                    task.spawn(function()
                        local deadline =
                            os.clock() + 1.25

                        repeat
                            if not prompt.Parent
                                or prompt.Enabled ~= true then

                                return
                            end

                            local folder =
                                playerGui:FindFirstChild("ProximityPrompts")

                            if folder then
                                for _, gui in ipairs(folder:GetChildren()) do
                                    if gui:IsA("BillboardGui")
                                        and gui.Adornee == prompt.Parent then

                                        local button =
                                            gui:FindFirstChild("TextButton", true)

                                        if bridgeButton(
                                            prompt,
                                            button,
                                            gui
                                        ) then
                                            return
                                        end
                                    end
                                end
                            end

                            task.wait(0.03)
                        until os.clock() >= deadline
                    end)
                end

                -- Keep the source template clickable so future rendered eggs
                -- inherit the safest native prompt setting as well.
                pcall(function()
                    local assets =
                        ReplicatedStorage:FindFirstChild("Assets")

                    local prompts =
                        assets
                        and assets:FindFirstChild("Prompts")

                    local pickupTemplate =
                        prompts
                        and prompts:FindFirstChild("Pickup")

                    if pickupTemplate
                        and pickupTemplate:IsA("ProximityPrompt") then

                        pickupTemplate.ClickablePrompt = true
                    end
                end)

                local renderedEggs =
                    Workspace:FindFirstChild("RenderedEggs")

                if renderedEggs then
                    for _, object in ipairs(renderedEggs:GetDescendants()) do
                        if object:IsA("ProximityPrompt")
                            and object.Name == "Pickup" then

                            keepPickupClickable(object)
                        end
                    end

                    connections[#connections + 1] =
                        renderedEggs.DescendantAdded:Connect(
                            function(object)
                                if object:IsA("ProximityPrompt")
                                    and object.Name == "Pickup" then

                                    keepPickupClickable(object)
                                end
                            end
                        )
                end

                connections[#connections + 1] =
                    promptService.PromptShown:Connect(
                        function(prompt)
                            if isPickupPrompt(prompt) then
                                findAndBridgeGeneratedButton(prompt)
                            end
                        end
                    )

                serenityEnv.__SERENITY_RAP_MOBILE_PICKUP_CLEANUP =
                    function()
                        for _, connection in ipairs(connections) do
                            pcall(function()
                                connection:Disconnect()
                            end)
                        end

                        table.clear(connections)
                        table.clear(bridgedButtons)
                        table.clear(bridgeBusy)
                    end
            end
        end

        if Config.AutoRejoinNoEgg == true
            or Config.AutoReconnectOnDisconnect == true then

            shared.SerenityRideAPet.DisableHopUnsafeOptimizations(
                appOrErr.Adapter
            )
        end

        -- Replace Serenity's generic shared release note with this game's
        -- actual production release information.
        task.defer(function()
            local window = appOrErr.Window
            local screen = window and window.Screen

            if not screen then
                return
            end

            local releaseTitle =
                "Ride A Pet · Serenity Hub"

            local releaseText =
                "Volcanic readiness + safe hop: Auto Steal waits for native DropEndsAt before moving, blocked entry retries release player movement, Auto Hop re-checks targets immediately before teleport, Auto Hop/Reconnect share one teleport lock, and Egg Mutation ESP is available."

            for _, object in ipairs(screen:GetDescendants()) do
                if object:IsA("TextLabel")
                    or object:IsA("TextButton")
                    or object:IsA("TextBox") then

                    local text = tostring(object.Text or "")

                    if text == "UI 3.2.0 · September 7, 2026" then
                        object.Text = releaseTitle
                    elseif text == "Shared V3 release: feedback, movable launcher, saved UI preferences and mobile layout." then
                        object.Text = releaseText
                    elseif text == "UI Playground" then
                        object.Text = "Ride A Pet"
                    end
                end
            end
        end)
    else
        warn(
            "[SERENITY HUB] Ride A Pet UI build failed: "
            .. tostring(appOrErr)
        )

        log("SerenityUI.BuildFailed=" .. tostring(appOrErr))
    end
end

end

-- v80.2.61:
-- All late UI/feed locals above now live in an independent register frame.
shared.SerenityRideAPet.InitUIAndFeedSetup()


-- ============================================================
-- BEGIN — INDEPENDENT CONTINUOUS AUTOMATION
-- ============================================================

function shared.SerenityRideAPet.InitContinuousAutomationRuntime()
if game.PlaceId ~= EXPECTED_PLACE or game.GameId ~= EXPECTED_UNIVERSE then
    log("RESULT=ABORT_WRONG_GAME")
    finalize()
    return
end

if not HRP or not Humanoid or not fireproximityprompt_f or not ActiveEggs then
    log("RESULT=ABORT_MISSING_RUNTIME_CAPABILITY")
    finalize()
    return
end

log("ConfigFile=" .. tostring(CONFIG_FILE))
log("ConfigLoad=" .. tostring(configLoadInfo))
log("FirstRunAutomationDefaultsOff=true")
log("AntiAFKDefaultEnabled=true")
log("EggESPMinLuck=" .. tostring(Config.EggESPMinLuck))
log("AutoRejoinNoEgg=" .. tostring(Config.AutoRejoinNoEgg))
log("EggMutationESP=" .. tostring(Config.EggMutationESP))
log("RejoinIntervalSeconds=" .. tostring(Config.RejoinIntervalSeconds))
log("VolcanicSpecialSteal=true")
log("VolcanicAutomationNoclip=false")
log("PlayerNoclip=" .. tostring(Config.PlayerNoclip))
log("SpeedHackEnabled=" .. tostring(Config.SpeedHackEnabled))
log("SpeedHackSpeed=" .. tostring(Config.SpeedHackSpeed))
log("FlyEnabled=" .. tostring(Config.FlyEnabled))
log("FlySpeed=" .. tostring(Config.FlySpeed))
log("RejoinUsesStealMinLuck=true")
log("RejoinUsesStealMinKG=" .. tostring(Config.StealMinKG))
log("RejoinUsesSpecificEggs=true")
log("AutoSaveSettings=true")
log("UI=ORIGINAL_SERENITY_V3")
log("ShopMode=NATIVE_GAME_AUTOBUY")
log("StealMinLuck=" .. tostring(Config.StealMinLuck))
log("StealPriority=" .. tostring(Config.StealPriority))
log("PlaceFilterMode=" .. tostring(Config.PlaceFilterMode))
log("PlacePriority=" .. tostring(Config.PlacePriority))
log("AutoHatch=" .. tostring(Config.AutoHatch))
log("AutoPlace=" .. tostring(Config.AutoPlace))
log("AutoPlaceAnywhere=true")
log("PlacedEggESP=" .. tostring(Config.PlacedEggESP))
log("PlacedEggESPTextOnly=true")
log("PlacedEggESPWeightCache=true")
log("AutoStealBasketLock=true")
log("AutoStealBasketRecovery=true")
log("VolcanoTopStreamRecovery=true")
log("VolcanicSpecialBasketSnapshotFix=true")
log("NativeEggCycleClaims=true")
log("AutoHatchV5=true")
log("VolcanicFastRoutePoints=20")
log("VolcanicFastRouteScale=3.00x")
log("ToggleTransactionSafeWake=true")
log("PlaceMinKG=" .. tostring(Config.PlaceMinKG))
log("AutoWeatherPetSwap=" .. tostring(Config.AutoWeatherPetSwap))
log("WeatherVariants=" .. table.concat(selectionAsArray(Config.WeatherVariants), ","))
log("WeatherAutoHighestNoMutation=" .. tostring(Config.WeatherAutoHighestNoMutation))
log("MutationWebhookEnabled=" .. tostring(Config.MutationWebhookEnabled))
log("BaseMaintenanceIdleReturn=" .. tostring(Config.BaseMaintenanceIdleReturn))
log("BaseMaintenanceIdleSeconds=" .. tostring(Config.BaseMaintenanceIdleSeconds))
log("AutoSteal=" .. tostring(Config.AutoSteal))
log("InstantSteal=" .. tostring(Config.InstantSteal))
log("AutoStealTweenSpeed=" .. tostring(Config.GardenReturnTweenSpeed))
log(
    "VolcanicMutationInSteal="
    .. tostring(
        Config.VolcanicMutationInSteal
    )
)
log("AutoSell=" .. tostring(Config.AutoSell))
log("AutoHatchLuck=" .. tostring(Config.AutoHatchLuck))
log("AutoRebirthRequirements=" .. tostring(Config.AutoRebirth))
log("StealSpecificEggCount=" .. tostring(#selectionAsArray(Config.StealEggs)))


-- Re-execution-safe generation token. Running a newer copy automatically
-- causes the previous automation loop to stop without leaving duplicate workers.
local env = getgenv and getgenv() or _G
env.__SERENITY_RAP_AUTO_GENERATION =
    (tonumber(env.__SERENITY_RAP_AUTO_GENERATION) or 0) + 1

local generation = env.__SERENITY_RAP_AUTO_GENERATION

-- Apply native shop Auto-Buy once. UI changes update it directly too.
task.defer(syncNativeAutoBuy, true)

shared.SerenityRideAPet.DirectWorkerErrors =
    shared.SerenityRideAPet.DirectWorkerErrors
    or {}

-- ============================================================
-- DIRECT API WORKER 1: HATCH V5
-- Base-only. Growth detection itself is distance-independent. Once a fully
-- grown own egg exists, this worker moves close to that egg, verifies native
-- HatchInteraction.Ready(), and fires exactly one Hatch request.
-- ============================================================
task.spawn(function()
    local workerGeneration = generation

    while env.__SERENITY_RAP_AUTO_GENERATION == workerGeneration do
        local okWorker, workerErr =
            xpcall(function()
                if shared.SerenityRideAPet.IsStealActionBusy() then
                    task.wait(0.05)
                elseif equipmentActionBusy then
                    -- Auto Sell / Feed / Place owns the equipped-tool lane.
                    -- V5 also moves locally, so do not start over that action.
                    task.wait(0.05)
                elseif Config.AutoHatch then
                    if not shared.SerenityRideAPet.BaseAutomationCanWorkHere() then
                        task.wait(0.22)
                    else
                    local hatchable = hatchCandidatesForOwnPlot()

                    if #hatchable > 0 then
                        local candidate = hatchable[1]

                        log("")
                        log("=== API_HATCH_V5 ===")
                        log("ReadyEggCount=" .. tostring(#hatchable))
                        log("TargetEgg=" .. tostring(
                            candidate.egg and candidate.egg.Name
                        ))

                        local ran, ok, reason =
                            shared.SerenityRideAPet.RunDirectAction(
                                "HATCH",
                                function()
                                    return directHatchCandidate(
                                        candidate,
                                        "ApiHatch"
                                    )
                                end
                            )

                        if ran then
                            log("ApiHatchResult=" .. tostring(ok))
                            log("ApiHatchReason=" .. tostring(reason))

                            task.wait(ok and 0.08 or 0.16)
                        else
                            task.wait(0.05)
                        end
                    else
                        task.wait(0.16)
                    end
                    end
                else
                    task.wait(0.30)
                end
            end, debug.traceback)

        if not okWorker then
            shared.SerenityRideAPet.DirectWorkerErrors.Hatch =
                tostring(workerErr)

            task.wait(0.50)
        end
    end
end)

-- ============================================================
-- DIRECT API WORKER 2: PLACE
-- ANYWHERE-SAFE.
-- Live V1 proof confirmed EggPlaced + PlantPosition works while the player
-- is physically outside the garden with no teleport/tween/noclip.
-- Plot capacity is inferred dynamically from one failed placement and
-- unblocked immediately when a placed egg is removed.
-- ============================================================
task.spawn(function()
    local workerGeneration = generation

    while env.__SERENITY_RAP_AUTO_GENERATION == workerGeneration do
        local okWorker, workerErr =
            xpcall(function()
                if shared.SerenityRideAPet.IsStealActionBusy() then
                    task.wait(0.05)
                elseif Config.AutoPlace then
                    local placeCandidatesNow =
                        placeEggCandidates()

                    if isCurrentlyRiding() then
                        -- Auto Place equips an Egg Tool. Preserve the user's
                        -- current ride; physical garden location is irrelevant.
                        task.wait(0.18)
                    elseif #placeCandidatesNow > 0 then
                        local ran, ok =
                            shared.SerenityRideAPet.RunDirectAction(
                                "PLACE",
                                function()
                                    if not tryAcquireEquipment("PLACE") then
                                        return false
                                    end

                                    local placed =
                                        directPlaceCarriedEgg(
                                            "ApiPlace"
                                        )

                                    releaseEquipment("PLACE")
                                    return placed
                                end
                            )

                        if ran then
                            task.wait(
                                ok and 0.08 or 0.16
                            )
                        else
                            task.wait(0.05)
                        end
                    else
                        task.wait(0.18)
                    end
                else
                    task.wait(0.30)
                end
            end, debug.traceback)

        if not okWorker then
            shared.SerenityRideAPet.DirectWorkerErrors.Place =
                tostring(workerErr)

            if equipmentActionOwner == "PLACE" then
                releaseEquipment("PLACE")
            end

            task.wait(0.50)
        end
    end
end)

-- ============================================================
-- DIRECT API WORKER 3: HATCH LUCK
-- No teleport. Buys every currently free/affordable Hatch Luck upgrade in one pass.
-- ============================================================
task.spawn(function()
    local workerGeneration = generation

    while env.__SERENITY_RAP_AUTO_GENERATION == workerGeneration do
        local okWorker, workerErr =
            xpcall(function()
                if shared.SerenityRideAPet.IsStealActionBusy() then
                    task.wait(0.05)
                elseif Config.AutoHatchLuck then
                    local ran, upgraded, info =
                        shared.SerenityRideAPet.RunDirectAction(
                            "HATCH_LUCK",
                            shared.SerenityRideAPet.AutoHatchLuckMax
                        )

                    if ran and upgraded then
                        log("")
                        log("=== API_HATCH_LUCK ===")
                        log("UpgradeResult=true")
                        log("UpgradesBought=" .. tostring(info))
                    end

                    task.wait(0.20)
                else
                    task.wait(0.35)
                end
            end, debug.traceback)

        if not okWorker then
            shared.SerenityRideAPet.DirectWorkerErrors.HatchLuck =
                tostring(workerErr)

            task.wait(0.50)
        end
    end
end)

-- ============================================================
-- DIRECT API WORKER 4: AUTO REBIRTH REQUIREMENTS
-- No movement / no teleport.
-- Acquires the required pet from owned non-premium eggs using the game's
-- real HatchLuck pool/odds, then uses the native Rebirth remote.
-- Pauses while Auto Steal owns the action lane.
-- ============================================================
task.spawn(function()
    local workerGeneration = generation

    while env.__SERENITY_RAP_AUTO_GENERATION == workerGeneration do
        local okWorker, workerErr =
            xpcall(function()
                if shared.SerenityRideAPet.IsStealActionBusy() then
                    task.wait(0.05)
                elseif Config.AutoRebirth then
                    local ran, rebirthed, info =
                        shared.SerenityRideAPet.RunDirectAction(
                            "REBIRTH",
                            shared.SerenityRideAPet.TryAutoRebirth
                        )

                    if ran and rebirthed then
                        local action =
                            type(info) == "table"
                            and info.Action
                            or "Unknown"

                        log("")
                        log("=== API_REBIRTH_REQUIREMENTS ===")
                        log(
                            "Action="
                            .. tostring(action)
                        )

                        if action == "Rebirth" then
                            log("RebirthResult=true")
                            log(
                                "RebirthCount="
                                .. tostring(
                                    info
                                    and info.Rebirths
                                    or "?"
                                )
                            )
                        elseif action == "RequirementEggPlaced" then
                            log(
                                "RequirementEgg="
                                .. tostring(
                                    info.EggName
                                )
                            )
                            log(
                                "RequiredPet="
                                .. tostring(
                                    info.RequiredPet
                                )
                            )
                        elseif action == "RequirementEggHatched" then
                            log(
                                "HatchedPet="
                                .. tostring(
                                    info.PetName
                                )
                            )
                            log(
                                "TargetMatched="
                                .. tostring(
                                    info.Matched
                                )
                            )
                        end
                    end

                    task.wait(ran and rebirthed and 0.25 or 0.80)
                else
                    task.wait(0.60)
                end
            end, debug.traceback)

        if not okWorker then
            shared.SerenityRideAPet.DirectWorkerErrors.Rebirth =
                tostring(workerErr)

            task.wait(0.50)
        end
    end
end)

-- ============================================================
-- DIRECT API WORKER 5: AUTO FEED
-- Base-only. Uses FeedPet + PetFed acknowledgement.
-- Only shares the equipped Tool slot with Place / Sell.
-- ============================================================
task.spawn(function()
    local workerGeneration = generation

    while env.__SERENITY_RAP_AUTO_GENERATION == workerGeneration do
        local okWorker, workerErr =
            xpcall(function()
                if shared.SerenityRideAPet.IsStealActionBusy() then
                    task.wait(0.05)
                elseif Config.AutoFeed then
                    if not shared.SerenityRideAPet.BaseAutomationCanWorkHere() then
                        task.wait(0.22)
                    elseif isCurrentlyRiding() then
                        -- Feeding equips a Food Tool. Do not disturb the current ride.
                        task.wait(0.18)
                    else
                        local ran, fed =
                            shared.SerenityRideAPet.RunDirectAction(
                                "FEED",
                                function()
                                    if not tryAcquireEquipment("FEED") then
                                        return false
                                    end

                                    local result =
                                        autoFeedOne()

                                    releaseEquipment("FEED")
                                    return result
                                end
                            )

                        if ran then
                            task.wait(fed and 0.03 or 0.18)
                        else
                            task.wait(0.05)
                        end
                    end
                else
                    task.wait(0.30)
                end
            end, debug.traceback)

        if not okWorker then
            shared.SerenityRideAPet.DirectWorkerErrors.Feed =
                tostring(workerErr)

            if equipmentActionOwner == "FEED" then
                releaseEquipment("FEED")
            end

            task.wait(0.50)
        end
    end
end)

-- ============================================================
-- WEATHER PET SWAP WORKER
-- Direct/API only. Auto Steal owns priority via RunDirectAction.
-- ============================================================
task.spawn(function()
    local workerGeneration = generation
    local lastEnabled = Config.AutoWeatherPetSwap == true

    while env.__SERENITY_RAP_AUTO_GENERATION == workerGeneration do
        local runtime =
            shared.SerenityRideAPet.WeatherRuntime

        local enabled =
            Config.AutoWeatherPetSwap == true

        if enabled then
            local current =
                shared.SerenityRideAPet.GetCurrentWeathers()

            local matched =
                shared.SerenityRideAPet.WeatherMatches(
                    current
                )

            if matched then
                runtime.SuspendAutoEquipBest = true

                if not runtime.Active
                    or os.clock()
                        - (tonumber(runtime.LastEnsureAt) or 0)
                        >= 4 then

                    runtime.LastEnsureAt =
                        os.clock()

                    shared.SerenityRideAPet.RunDirectAction(
                        "WEATHER_PETS",
                        shared.SerenityRideAPet.ApplyWeatherPetLayout
                    )
                end
            elseif runtime.Active then
                if Config.WeatherRestorePrevious == true then
                    shared.SerenityRideAPet.RunDirectAction(
                        "WEATHER_PETS",
                        shared.SerenityRideAPet.RestoreWeatherPetLayout
                    )
                else
                    runtime.Active = false
                    runtime.Snapshot = nil
                    runtime.Transitioning = false
                    runtime.SuspendAutoEquipBest = false

                    local equipState =
                        shared.SerenityRideAPet.AutoEquipBestState

                    if Config.AutoEquipBest == true
                        and equipState then

                        equipState.Pending = true
                        equipState.LastSignature = nil
                    end
                end
            end

            task.wait(0.75)
        else
            if lastEnabled
                and runtime.Active
                and Config.WeatherRestorePrevious == true then

                shared.SerenityRideAPet.RunDirectAction(
                    "WEATHER_PETS",
                    shared.SerenityRideAPet.RestoreWeatherPetLayout
                )
            end

            task.wait(1.0)
        end

        lastEnabled = enabled
    end
end)

-- ============================================================
-- DIRECT MAINTENANCE: AUTO EQUIP BEST
-- Uses the game's own Place Best control. It only runs when the pet layout
-- changes, or when explicitly queued after a sale/new inventory change.
-- ============================================================
task.spawn(function()
    local workerGeneration = generation

    while env.__SERENITY_RAP_AUTO_GENERATION == workerGeneration do
        local okWorker, workerErr =
            xpcall(function()
                if shared.SerenityRideAPet.IsStealActionBusy() then
                    task.wait(0.05)
                elseif shared.SerenityRideAPet.WeatherPetOverrideLocked
                    and shared.SerenityRideAPet.WeatherPetOverrideLocked() then

                    shared.SerenityRideAPet.AutoEquipBestState.Pending = true
                    task.wait(0.45)
                elseif Config.AutoEquipBest then
                    local state =
                        shared.SerenityRideAPet.AutoEquipBestState

                    if state.Pending == true then
                        shared.SerenityRideAPet.RunDirectAction(
                            "EQUIP_BEST",
                            function()
                                return shared.SerenityRideAPet.RequestAutoEquipBest(
                                    false
                                )
                            end
                        )

                        task.wait(0.35)
                    elseif os.clock()
                        - (
                            tonumber(
                                state.LastFallbackCheckAt
                            )
                            or 0
                        ) >= 5 then

                        state.LastFallbackCheckAt =
                            os.clock()

                        local signature =
                            shared.SerenityRideAPet.PetLayoutSignature()

                        if signature
                            ~= state.LastSignature then

                            state.Pending =
                                true
                        end

                        task.wait(0.75)
                    else
                        task.wait(0.75)
                    end
                else
                    task.wait(0.60)
                end
            end, debug.traceback)

        if not okWorker then
            shared.SerenityRideAPet.DirectWorkerErrors.AutoEquipBest =
                tostring(workerErr)

            task.wait(0.50)
        end
    end
end)

-- ============================================================
-- AUTO REJOIN WHEN NO MATCHING EGG
-- Runs ONLY after the movement lane has completely finished its cycle.
-- This guarantees an in-progress steal reaches its garden-claim validation
-- before any rejoin can be requested.
-- ============================================================

local movementLaneBusy = false

shared.SerenityRideAPet.IsMovementLaneBusy = function()
    return movementLaneBusy == true
end

do
    local runtime =
        shared.SerenityRideAPet.BaseMaintenanceRuntime

    runtime.LastMotionAt =
        os.clock()

    runtime.LastPosition =
        HRP
        and HRP.Position
        or nil

    task.spawn(function()
        local workerGeneration =
            generation

        while env.__SERENITY_RAP_AUTO_GENERATION
            == workerGeneration do

            if shared.SerenityRideAPet.RefreshRuntimeCharacterRefs(0) then
                local now =
                    os.clock()

                local inside =
                    shared.SerenityRideAPet.IsInsideOwnBase()

                if inside then
                    runtime.ReturnRequested =
                        false

                    runtime.LastMotionAt =
                        now

                    runtime.LastPosition =
                        HRP.Position
                elseif not shared.SerenityRideAPet.BaseMaintenanceEnabled()
                    or Config.BaseMaintenanceIdleReturn == false then

                    runtime.ReturnRequested =
                        false

                    runtime.LastMotionAt =
                        now

                    runtime.LastPosition =
                        HRP.Position
                else
                    local previous =
                        runtime.LastPosition

                    local moved =
                        typeof(previous) ~= "Vector3"
                        or (
                            HRP.Position - previous
                        ).Magnitude >= 1.5
                        or (
                            Humanoid
                            and Humanoid.MoveDirection.Magnitude > 0.05
                        )

                    runtime.LastPosition =
                        HRP.Position

                    if moved
                        or shared.SerenityRideAPet.IsStealActionBusy() then

                        runtime.LastMotionAt =
                            now

                        runtime.ReturnRequested =
                            false
                    else
                        local idleSeconds =
                            math.clamp(
                                tonumber(
                                    Config.BaseMaintenanceIdleSeconds
                                )
                                or 60,
                                3,
                                300
                            )

                        if now
                            - (
                                tonumber(
                                    runtime.LastMotionAt
                                )
                                or now
                            )
                            >= idleSeconds then

                            runtime.ReturnRequested =
                                true
                        end
                    end
                end
            end

            task.wait(0.50)
        end
    end)
end
local sessionStartedAt = os.clock()
local noRejoinTargetSince = nil
local rejoinRequested = false
local REJOIN_INITIAL_GRACE_SECONDS = 6
local REJOIN_NO_TARGET_CONFIRM_SECONDS = 1.25

shared.SerenityRideAPet.RejoinRuntime =
    shared.SerenityRideAPet.RejoinRuntime
    or {
        LastFilterSignature = nil,
        AttemptSerial = 0,
        CurrentAttempt = nil,
        FailedServers = {},
        ManualHopPending = false,
        ManualHopRequestedAt = 0,
        LastHopError = nil,
        LastHopAt = 0,
    }

-- Auto Hop completion is keyed to the target filters, not the server JobId.
-- This lets a successful hunt survive a manual rejoin while still re-arming
-- immediately if Minimum K.G / Minimum Luck / Specific Eggs changes.
shared.SerenityRideAPet.KGHuntFilterSignature =
    function()
        local selected =
            selectionAsArray(
                shared.SerenityRideAPet.ActiveStealSetting(
                    "StealEggs",
                    {}
                )
            )

        return
            tostring(
                shared.SerenityRideAPet.MinimumStealKG()
            )
            .. "|"
            .. tostring(
                shared.SerenityRideAPet.ActiveStealSetting(
                    "StealMinLuck",
                    "Any"
                )
            )
            .. "|"
            .. table.concat(
                selected,
                ","
            )
    end

shared.SerenityRideAPet.PersistedKGHuntSatisfied =
    function()
        return
            Config.AutoHopKGSatisfied == true
            and tostring(
                Config.AutoHopKGSatisfiedSignature
                or ""
            ) == shared.SerenityRideAPet.KGHuntFilterSignature()
    end

-- Re-evaluate an already-confirmed steal when the user changes filters.
-- Do not throw away a valid success merely because Minimum K.G changed. If
-- the exact saved egg + K.G still passes the new filter set and native stock
-- has not advanced, keep the hunt completed and only refresh its signature.
shared.SerenityRideAPet.PersistedKGHuntStillQualifies =
    function()
        if Config.AutoHopKGSatisfied ~= true then
            return false
        end

        local eggType =
            tostring(
                Config.AutoHopKGSatisfiedEggType
                or ""
            )

        local eggKG =
            tonumber(
                Config.AutoHopKGSatisfiedKG
            )
            or 0

        if eggType == "" then
            return false
        end

        local currentGlobal =
            shared.SerenityRideAPet.CurrentGlobalEggCycleIndex()

        local savedGlobal =
            tonumber(
                Config.AutoHopKGSatisfiedGlobalCycle
            )
            or 0

        local legacySavedCycle =
            tonumber(
                Config.AutoHopKGSatisfiedStockCycle
            )
            or 0

        if currentGlobal and currentGlobal > 0 then
            if savedGlobal > 0
                and currentGlobal ~= savedGlobal then

                return false
            end

            if savedGlobal <= 0
                and legacySavedCycle > 0
                and currentGlobal ~= legacySavedCycle then

                return false
            end
        else
            local currentCycle =
                shared.SerenityRideAPet.CurrentNativeStockCycle(
                    eggType
                )

            if legacySavedCycle > 0
                and currentCycle
                and currentCycle > legacySavedCycle then

                return false
            end
        end

        local meta =
            eggMeta[eggType]
            or {}

        local allowed =
            shared.SerenityRideAPet.AutoStealFilterAllowed(
                eggType,
                eggKG,
                tonumber(meta.luck) or 0
            )

        return allowed == true
    end

shared.SerenityRideAPet.RefreshPersistedKGHuntSignature =
    function()
        if not shared.SerenityRideAPet
            .PersistedKGHuntStillQualifies() then

            return false
        end

        Config.AutoHopKGSatisfiedSignature =
            shared.SerenityRideAPet.KGHuntFilterSignature()

        saveConfig()
        return true
    end

shared.SerenityRideAPet.ClearPersistedKGHunt =
    function()
        local changed =
            Config.AutoHopKGSatisfied == true
            or tostring(
                Config.AutoHopKGSatisfiedSignature
                or ""
            ) ~= ""
            or tostring(
                Config.AutoHopKGSatisfiedEggType
                or ""
            ) ~= ""
            or (tonumber(
                Config.AutoHopKGSatisfiedKG
            ) or 0) ~= 0
            or (tonumber(
                Config.AutoHopKGSatisfiedStockCycle
            ) or 0) ~= 0
            or (tonumber(
                Config.AutoHopKGSatisfiedGlobalCycle
            ) or 0) ~= 0

        Config.AutoHopKGSatisfied = false
        Config.AutoHopKGSatisfiedSignature = ""
        Config.AutoHopKGSatisfiedEggType = ""
        Config.AutoHopKGSatisfiedKG = 0
        Config.AutoHopKGSatisfiedStockCycle = 0
        Config.AutoHopKGSatisfiedGlobalCycle = 0

        if changed then
            saveConfig()
        end

        return changed
    end

-- Never let an old completed hunt become valid again if the user changed
-- filters while Serenity was not running.
if Config.AutoHopKGSatisfied == true
    and tostring(
        Config.AutoHopKGSatisfiedSignature
        or ""
    ) ~= shared.SerenityRideAPet.KGHuntFilterSignature() then

    if not shared.SerenityRideAPet
        .RefreshPersistedKGHuntSignature() then

        shared.SerenityRideAPet.ClearPersistedKGHunt()
    end
end

-- Validate any saved completion against the current GLOBAL EggCycle.Index
-- before hydrating runtime state. This catches restocks that happened while
-- Serenity was off or while the client was teleporting. Legacy per-egg Cycle
-- is used only to migrate older v87/v88 saved state.
if Config.AutoHopKGSatisfied == true then
    shared.SerenityRideAPet.SyncAutoHopNativeStock(
        "script-start-global-cycle"
    )
end

-- Session runtime hydrates from the hidden persistent success latch. A new
-- JobId alone no longer means "hunt again" after the requested egg was won.
shared.SerenityRideAPet.KGHuntRuntime = {
    JobId =
        tostring(
            game.JobId
            or ""
        ),
    GoalSatisfied =
        shared.SerenityRideAPet.PersistedKGHuntSatisfied(),
    EnabledLast =
        Config.AutoRejoinNoEgg == true,
    LastKGSignature =
        shared.SerenityRideAPet.KGHuntFilterSignature(),
    LastConfirmedRestockGeneration =
        tonumber(
            restockState.KGHuntRestockGeneration
        )
        or 0,
    ConfirmedEggType =
        tostring(
            Config.AutoHopKGSatisfiedEggType
            or ""
        ),
    ConfirmedKG =
        tonumber(
            Config.AutoHopKGSatisfiedKG
        ),
    ConfirmedActiveId = nil,
    LastResetReason = "script-start",
    LastResetAt = os.clock(),
    SatisfiedAt = 0,
}

if shared.SerenityRideAPet.KGHuntRuntime.GoalSatisfied == true then
    shared.SerenityRideAPet.KGHuntRuntime.LastResetReason =
        "script-start-persisted"
    shared.SerenityRideAPet.KGHuntRuntime.SatisfiedAt =
        os.clock()
end

shared.SerenityRideAPet.ResetKGHuntRuntime =
    function(reason, restorePersistent)
        local runtime =
            shared.SerenityRideAPet
                .KGHuntRuntime

        local signature =
            shared.SerenityRideAPet
                .KGHuntFilterSignature()

        local restored =
            restorePersistent == true
            and Config.AutoHopKGSatisfied == true
            and tostring(
                Config.AutoHopKGSatisfiedSignature
                or ""
            ) == signature

        runtime.JobId =
            tostring(
                game.JobId
                or ""
            )

        runtime.GoalSatisfied =
            restored

        runtime.EnabledLast =
            Config.AutoRejoinNoEgg
            == true

        runtime.LastKGSignature =
            signature

        runtime.LastConfirmedRestockGeneration =
            tonumber(
                restockState.KGHuntRestockGeneration
            )
            or 0

        runtime.ConfirmedEggType =
            nil

        runtime.ConfirmedKG =
            nil

        runtime.ConfirmedActiveId =
            nil

        runtime.LastResetReason =
            tostring(
                reason
                or "reset"
            )

        runtime.LastResetAt =
            os.clock()

        runtime.SatisfiedAt =
            0

        if restored then
            runtime.ConfirmedEggType =
                tostring(
                    Config.AutoHopKGSatisfiedEggType
                    or ""
                )

            runtime.ConfirmedKG =
                tonumber(
                    Config.AutoHopKGSatisfiedKG
                )

            runtime.LastResetReason =
                "persisted-success:"
                .. tostring(
                    reason
                    or "restore"
                )

            runtime.SatisfiedAt =
                os.clock()
        end

        noRejoinTargetSince =
            nil

        return runtime
    end

shared.SerenityRideAPet.MarkKGHuntGoalSatisfied =
    function(candidate)
        if type(candidate) ~= "table" then
            return false
        end

        local eggKG =
            tonumber(
                candidate.eggWeight
            )
            or 0

        local minimumKG =
            shared.SerenityRideAPet
                .MinimumStealKG()

        if eggKG < minimumKG then
            return false
        end

        local runtime =
            shared.SerenityRideAPet
                .KGHuntRuntime

        local currentJob =
            tostring(
                game.JobId
                or ""
            )

        if tostring(runtime.JobId or "")
            ~= currentJob then

            shared.SerenityRideAPet
                .ResetKGHuntRuntime(
                    "new-job-before-confirmed-steal"
                )

            runtime =
                shared.SerenityRideAPet
                    .KGHuntRuntime
        end

        runtime.GoalSatisfied =
            true

        runtime.EnabledLast =
            Config.AutoRejoinNoEgg
            == true

        runtime.LastKGSignature =
            shared.SerenityRideAPet
                .KGHuntFilterSignature()

        runtime.LastConfirmedRestockGeneration =
            tonumber(
                restockState.KGHuntRestockGeneration
            )
            or 0

        runtime.ConfirmedEggType =
            tostring(
                candidate.eggType
                or ""
            )

        runtime.ConfirmedKG =
            eggKG

        runtime.ConfirmedActiveId =
            candidate.active
            and tostring(
                candidate.active.Name
            )
            or nil

        runtime.SatisfiedAt =
            os.clock()

        if Config.AutoRejoinNoEgg == true then
            Config.AutoHopKGSatisfied = true
            Config.AutoHopKGSatisfiedSignature =
                shared.SerenityRideAPet
                    .KGHuntFilterSignature()
            Config.AutoHopKGSatisfiedEggType =
                runtime.ConfirmedEggType
            Config.AutoHopKGSatisfiedKG =
                eggKG

            local targetCycle =
                candidate.active
                and tonumber(
                    candidate.active:GetAttribute(
                        "Cycle"
                    )
                )
                or nil

            local targetIsNormalStock =
                candidate.active
                and candidate.active:GetAttribute(
                    "Area"
                ) ~= true
                and candidate.active:GetAttribute(
                    "AdminSpawn"
                ) ~= true
                and not shared.SerenityRideAPet
                    .IsVolcanicStockType(
                        runtime.ConfirmedEggType
                    )

            Config.AutoHopKGSatisfiedStockCycle =
                tonumber(
                    targetIsNormalStock
                    and targetCycle
                    or shared.SerenityRideAPet
                        .CurrentNativeStockCycle(
                            runtime.ConfirmedEggType
                        )
                    or targetCycle
                )
                or 0

            Config.AutoHopKGSatisfiedGlobalCycle =
                tonumber(
                    shared.SerenityRideAPet
                        .CurrentGlobalEggCycleIndex()
                )
                or 0

            -- Normal stock ActiveEgg.Cycle matched EggCycle.Index in the v88
            -- live proof. If the module is temporarily unavailable, retain the
            -- legacy cycle as a migration-safe fallback.
            if Config.AutoHopKGSatisfiedGlobalCycle <= 0
                and targetIsNormalStock then

                Config.AutoHopKGSatisfiedGlobalCycle =
                    Config.AutoHopKGSatisfiedStockCycle
            end

            saveConfig()
        end

        noRejoinTargetSince =
            nil

        log("")
        log("=== KG_HUNT_SATISFIED ===")
        log(
            "EggType="
            .. tostring(
                runtime.ConfirmedEggType
            )
        )
        log(
            "EggKG="
            .. tostring(
                runtime.ConfirmedKG
            )
        )
        log(
            "MinimumKG="
            .. tostring(
                minimumKG
            )
        )
        log(
            "StockCycle="
            .. tostring(
                Config.AutoHopKGSatisfiedStockCycle
                or 0
            )
        )
        log(
            "GlobalCycle="
            .. tostring(
                Config.AutoHopKGSatisfiedGlobalCycle
                or 0
            )
        )
        log("AutoHopPaused=true")

        return true
    end

do
    local runtime =
        shared.SerenityRideAPet.RejoinRuntime

    runtime.AttemptSerial =
        tonumber(runtime.AttemptSerial) or 0

    runtime.FailedServers =
        type(runtime.FailedServers) == "table"
        and runtime.FailedServers
        or {}

    runtime.ManualHopPending =
        runtime.ManualHopPending == true

    runtime.ManualHopRequestedAt =
        tonumber(runtime.ManualHopRequestedAt) or 0

    runtime.LastHopAt =
        tonumber(runtime.LastHopAt) or 0
end

-- One teleport owner across Auto Hop, Manual Hop and Auto Reconnect.
-- This prevents overlapping Teleport/TeleportToPlaceInstance calls.
shared.SerenityRideAPet.TeleportRuntime =
    shared.SerenityRideAPet.TeleportRuntime
    or {
        Owner = nil,
        Since = 0,
        SourceJobId = "",
    }

do
    local teleportRuntime =
        shared.SerenityRideAPet.TeleportRuntime

    if tostring(teleportRuntime.SourceJobId or "")
        ~= tostring(game.JobId or "")
        or os.clock() - (tonumber(teleportRuntime.Since) or 0) > 30 then

        teleportRuntime.Owner = nil
        teleportRuntime.Since = 0
        teleportRuntime.SourceJobId =
            tostring(game.JobId or "")
    end
end

shared.SerenityRideAPet.AcquireTeleportLock = function(owner)
    local runtime =
        shared.SerenityRideAPet.TeleportRuntime

    local now =
        os.clock()

    local sameJob =
        tostring(runtime.SourceJobId or "")
        == tostring(game.JobId or "")

    local age =
        now - (tonumber(runtime.Since) or 0)

    if runtime.Owner ~= nil
        and sameJob
        and age <= 20 then

        return
            false,
            "teleport owned by "
            .. tostring(runtime.Owner)
    end

    runtime.Owner =
        tostring(owner or "UNKNOWN")

    runtime.Since =
        now

    runtime.SourceJobId =
        tostring(game.JobId or "")

    return true
end

shared.SerenityRideAPet.ReleaseTeleportLock = function(owner)
    local runtime =
        shared.SerenityRideAPet.TeleportRuntime

    if owner ~= nil
        and runtime.Owner ~= tostring(owner) then

        return false
    end

    runtime.Owner = nil
    runtime.Since = 0
    runtime.SourceJobId =
        tostring(game.JobId or "")

    return true
end

local function queueOnTeleportFunction()
    local q = envfn("queue_on_teleport") or envfn("queueonteleport")
    if q then
        return q
    end

    local globalEnv = getgenv and getgenv() or _G
    local synTable = rawget(globalEnv, "syn")
    if type(synTable) == "table" and type(synTable.queue_on_teleport) == "function" then
        return synTable.queue_on_teleport
    end

    local fluxusTable = rawget(globalEnv, "fluxus")
    if type(fluxusTable) == "table" and type(fluxusTable.queue_on_teleport) == "function" then
        return fluxusTable.queue_on_teleport
    end

    return nil
end

shared.SerenityRideAPet.SessionRuntime =
    shared.SerenityRideAPet.SessionRuntime
    or {
        Serial = 0,
        LoaderQueued = false,
        ReconnectRequested = false,
        LastReconnectAttempt = 0,
        DisconnectPromptSince = nil,
        StartedAt = os.clock(),
    }

shared.SerenityRideAPet.SessionRuntime.StartedAt =
    tonumber(
        shared.SerenityRideAPet.SessionRuntime.StartedAt
    )
    or os.clock()

shared.SerenityRideAPet.QueueLoaderForNextTeleport = function()
    if Config.AutoExecuteOnTeleport ~= true then
        return false, "disabled"
    end

    local runtime =
        shared.SerenityRideAPet.SessionRuntime

    -- queue_on_teleport normally APPENDS. Register one payload per current
    -- Roblox session only.
    if runtime.LoaderQueued == true then
        return true, "already queued"
    end

    local queue =
        queueOnTeleportFunction()

    if type(queue) ~= "function" then
        return false, "queue function unavailable"
    end

    local ok, queueResult =
        pcall(queue, [[
repeat task.wait() until game:IsLoaded()

local e =
    (type(getgenv) == "function" and getgenv())
    or _G

-- Auto Execute OFF remains authoritative even when this payload was queued
-- earlier in the previous server.
if e.__SERENITY_RAP_AUTO_EXECUTE_ENABLED == false then
    return
end

if type(isfile) == "function"
    and type(readfile) == "function"
    and isfile("SerenityHub/RideAPet_M423Test_Config.json") then

    local okSetting, enabled =
        pcall(function()
            local raw =
                readfile(
                    "SerenityHub/RideAPet_M423Test_Config.json"
                )

            local data =
                game:GetService("HttpService")
                    :JSONDecode(raw)

            if type(data) == "table"
                and data.AutoExecuteOnTeleport ~= nil then

                return data.AutoExecuteOnTeleport == true
            end

            return true
        end)

    if okSetting and enabled == false then
        return
    end
end

local job =
    tostring(game.JobId or "")

-- If multiple queued payloads survived, only the first one in this destination
-- may download the loader.
if job ~= ""
    and tostring(
        e.__SERENITY_RAP_QUEUED_BOOT_JOB
        or ""
    ) == job then

    return
end

e.__SERENITY_RAP_QUEUED_BOOT_JOB =
    job

-- Explicit source marker lets the Ride A Pet script distinguish this queued
-- execution from a normal manual execution.
e.__SERENITY_RAP_BOOT_SOURCE = {
    Kind = "queue",
    Job = job,
    At = os.clock(),
}

local loaderUrl =
    "https://raw.githubusercontent.com/MUshihara/SerenityNewUi/main/tests/rideapet-m423/loader.lua"

local lastError = nil

for attempt = 1, 4 do
    local okHttp, source =
        pcall(function()
            return game:HttpGet(
                loaderUrl,
                true
            )
        end)

    if okHttp
        and type(source) == "string"
        and source ~= "" then

        local fn, compileError =
            loadstring(source)

        if fn then
            local okRun, runError =
                pcall(fn)

            if okRun then
                return
            end

            lastError = runError
        else
            lastError = compileError
        end
    else
        lastError = source
    end

    task.wait(
        math.min(
            4,
            0.75 * attempt
        )
    )
end

-- Allow a later manual execute to recover normally if every queued download
-- attempt failed.
e.__SERENITY_RAP_BOOT_SOURCE = nil
e.__SERENITY_RAP_QUEUED_BOOT_JOB = nil

warn(
    "[SERENITY HUB] Auto Execute loader failed after retries: "
    .. tostring(lastError)
)
]])

    -- Some queue APIs return nil on success. Treat only an actual Lua error or
    -- explicit boolean false as failure.
    if ok and queueResult ~= false then
        runtime.LoaderQueued = true
        return true
    end

    runtime.LoaderQueued = false

    return false,
        ok
        and "queue function rejected payload"
        or tostring(queueResult)
end

shared.SerenityRideAPet.RefreshSessionProtection = function()
    local runtime =
        shared.SerenityRideAPet.SessionRuntime

    runtime.Serial =
        (tonumber(runtime.Serial) or 0)
        + 1

    local serial =
        runtime.Serial

    runtime.ReconnectRequested = false
    runtime.DisconnectPromptSince = nil

    -- Queue exactly once for the NEXT teleport/reconnect. We deliberately do
    -- not queue again on Started / WaitingForServer / InProgress.
    if Config.AutoExecuteOnTeleport == true then
        shared.SerenityRideAPet.QueueLoaderForNextTeleport()
    end

    if Config.AutoReconnectOnDisconnect == true then
        task.spawn(function()
            local CoreGui =
                game:GetService("CoreGui")

            local function visibleInHierarchy(gui)
                if not gui
                    or gui.Parent == nil then
                    return false
                end

                local current = gui

                while current
                    and current ~= CoreGui do

                    if current:IsA("GuiObject")
                        and current.Visible ~= true then

                        return false
                    end

                    if current:IsA("LayerCollector")
                        and current.Enabled ~= true then

                        return false
                    end

                    current = current.Parent
                end

                return true
            end

            while env.__SERENITY_RAP_AUTO_GENERATION == generation
                and runtime.Serial == serial do

                local promptGui =
                    CoreGui:FindFirstChild(
                        "RobloxPromptGui"
                    )

                local overlay =
                    promptGui
                    and promptGui:FindFirstChild(
                        "promptOverlay"
                    )

                local errorPrompt =
                    overlay
                    and overlay:FindFirstChild(
                        "ErrorPrompt"
                    )

                local promptVisible =
                    visibleInHierarchy(
                        errorPrompt
                    )

                -- Ignore transient/stale CoreGui objects. The prompt has to
                -- actually remain visible before reconnect is attempted.
                if promptVisible then
                    runtime.DisconnectPromptSince =
                        runtime.DisconnectPromptSince
                        or os.clock()
                else
                    runtime.DisconnectPromptSince =
                        nil
                end

                local visibleLongEnough =
                    runtime.DisconnectPromptSince ~= nil
                    and os.clock()
                        - runtime.DisconnectPromptSince
                        >= 1.25

                local startupGraceDone =
                    os.clock()
                        - (tonumber(runtime.StartedAt) or 0)
                        >= 8

                if visibleLongEnough
                    and startupGraceDone
                    and not runtime.ReconnectRequested then

                    local now =
                        os.clock()

                    if now
                        - (tonumber(
                            runtime.LastReconnectAttempt
                        ) or 0)
                        >= 15 then

                        runtime.ReconnectRequested = true

                        task.wait(
                            math.clamp(
                                tonumber(
                                    Config.AutoReconnectDelaySeconds
                                ) or 3,
                                1,
                                30
                            )
                        )

                        if env.__SERENITY_RAP_AUTO_GENERATION ~= generation
                            or runtime.Serial ~= serial
                            or Config.AutoReconnectOnDisconnect ~= true then

                            runtime.ReconnectRequested = false
                            break
                        end

                        local lockOk =
                            shared.SerenityRideAPet
                                .AcquireTeleportLock(
                                    "RECONNECT"
                                )

                        if not lockOk then
                            runtime.ReconnectRequested = false
                        else
                            runtime.LastReconnectAttempt =
                                os.clock()

                            -- This is idempotent now: it only queues if this
                            -- session has not already registered the loader.
                            if Config.AutoExecuteOnTeleport == true then
                                shared.SerenityRideAPet.QueueLoaderForNextTeleport()
                            end

                            local sourceJobId =
                                tostring(game.JobId or "")

                            local ok =
                                pcall(function()
                                    TeleportService:Teleport(
                                        game.PlaceId,
                                        LP
                                    )
                                end)

                            if not ok then
                                shared.SerenityRideAPet
                                    .ReleaseTeleportLock(
                                        "RECONNECT"
                                    )

                                runtime.ReconnectRequested = false
                                runtime.DisconnectPromptSince = nil
                            else
                                -- Only release if Roblox failed to leave this
                                -- server. The shared lock prevents Hop/Reconnect
                                -- from racing each other during this window.
                                task.delay(15, function()
                                    if runtime.Serial == serial
                                        and tostring(game.JobId or "")
                                            == sourceJobId then

                                        shared.SerenityRideAPet
                                            .ReleaseTeleportLock(
                                                "RECONNECT"
                                            )

                                        runtime.ReconnectRequested = false
                                        runtime.DisconnectPromptSince = nil
                                    end
                                end)
                            end
                        end
                    end
                end

                task.wait(0.5)
            end
        end)
    end

    return true
end

-- Register Auto Execute once. It is independent from no-egg server hopping.
shared.SerenityRideAPet.RefreshSessionProtection()

shared.SerenityRideAPet.TeleportGameplaySafe = function()
    if shared.SerenityRideAPet.IsStealActionBusy() then
        return false, "steal transaction active"
    end

    if equipmentActionBusy then
        return false, "equipment action active"
    end

    if shared.SerenityRideAPet.DirectActionRuntime
        and (
            tonumber(
                shared.SerenityRideAPet
                    .DirectActionRuntime
                    .ActiveCount
            ) or 0
        ) > 0 then

        return false, "direct action active"
    end

    if shared.SerenityRideAPet.HasUnresolvedBasketEgg() then
        return false, "unresolved Basket egg"
    end

    return true
end

local function requestSerenityRejoin(reason)
    local runtime =
        shared.SerenityRideAPet.RejoinRuntime

    if rejoinRequested then
        return false, "hop already in progress"
    end

    local gameplaySafe,
        gameplayWhy =
        shared.SerenityRideAPet
            .TeleportGameplaySafe()

    if not gameplaySafe then
        return false, gameplayWhy
    end

    local lockOk,
        lockWhy =
        shared.SerenityRideAPet
            .AcquireTeleportLock(
                "SERVER_HOP"
            )

    if not lockOk then
        return false, lockWhy
    end

    -- Clean expired failed-server locks.
    local now =
        os.clock()

    for serverId, expiresAt in pairs(runtime.FailedServers) do
        if tonumber(expiresAt) == nil
            or now >= tonumber(expiresAt) then

            runtime.FailedServers[serverId] = nil
        end
    end

    rejoinRequested = true

    runtime.AttemptSerial =
        (tonumber(runtime.AttemptSerial) or 0)
        + 1

    local attemptSerial =
        runtime.AttemptSerial

    local sourceJobId =
        tostring(game.JobId or "")

    local function releaseAttempt(message, failedServerId)
        if runtime.AttemptSerial ~= attemptSerial then
            return false
        end

        if failedServerId
            and failedServerId ~= "" then

            -- Avoid immediately retrying a destination Roblox just failed to
            -- enter. It becomes eligible again after three minutes.
            runtime.FailedServers[
                tostring(failedServerId)
            ] = os.clock() + 180
        end

        runtime.LastHopError =
            message
            and tostring(message)
            or nil

        runtime.CurrentAttempt = nil
        rejoinRequested = false

        shared.SerenityRideAPet
            .ReleaseTeleportLock(
                "SERVER_HOP"
            )

        return true
    end

    -- Find a DIFFERENT non-full public Ride A Pet server.
    local candidates = {}
    local cursor = nil

    for _ = 1, 3 do
        local url =
            "https://games.roblox.com/v1/games/"
            .. tostring(game.PlaceId)
            .. "/servers/Public?sortOrder=Asc&limit=100&excludeFullGames=true"

        if cursor and cursor ~= "" then
            url = url
                .. "&cursor="
                .. HttpService:UrlEncode(cursor)
        end

        local okPage, decoded =
            pcall(function()
                return HttpService:JSONDecode(
                    game:HttpGet(url, true)
                )
            end)

        if not okPage
            or type(decoded) ~= "table" then

            runtime.LastHopError =
                "server list request failed"

            break
        end

        if type(decoded.data) == "table" then
            for _, server in ipairs(decoded.data) do
                local serverId =
                    type(server) == "table"
                    and tostring(server.id or "")
                    or ""

                if serverId ~= ""
                    and serverId ~= sourceJobId
                    and runtime.FailedServers[serverId] == nil
                    and tonumber(server.playing)
                    and tonumber(server.maxPlayers)
                    and tonumber(server.playing)
                        < tonumber(server.maxPlayers) then

                    candidates[#candidates + 1] = {
                        id = serverId,
                        playing =
                            tonumber(server.playing)
                            or 0,
                        maxPlayers =
                            tonumber(server.maxPlayers)
                            or 0,
                    }
                end
            end
        end

        cursor =
            decoded.nextPageCursor

        if not cursor
            or cursor == ""
            or #candidates >= 30 then

            break
        end
    end

    if #candidates == 0 then
        releaseAttempt(
            runtime.LastHopError
            or "no alternate server found"
        )

        return false, runtime.LastHopError
            or "no alternate server found"
    end

    -- Lower-population servers first = less competition for eggs.
    table.sort(candidates, function(a, b)
        if a.playing == b.playing then
            return a.id < b.id
        end

        return a.playing < b.playing
    end)

    -- Pick among a few emptiest servers so everybody does not pile into one.
    local poolSize =
        math.min(
            #candidates,
            8
        )

    local chosen =
        candidates[
            math.random(
                1,
                poolSize
            )
        ]

    if not chosen
        or not chosen.id then

        releaseAttempt(
            "server selection failed"
        )

        return false, "server selection failed"
    end

    -- v80.2.77: server discovery can take long enough for a K.G target to
    -- appear. Auto Hop MUST re-check immediately before teleporting.
    if tostring(reason) == "auto-no-matching-kg-egg" then
        local stillSafe,
            stillSafeWhy =
            shared.SerenityRideAPet
                .TeleportGameplaySafe()

        local appeared =
            serverHasRejoinTargetEgg()

        -- A stock-locked target is intentionally not stealable in this
        -- server, so it must NOT cancel Auto Hop. Only a currently eligible,
        -- unclaimed target or an active gameplay transaction can stop the hop.
        if not stillSafe
            or appeared then

            noRejoinTargetSince = nil

            releaseAttempt(
                not stillSafe
                and tostring(stillSafeWhy)
                or "valid egg match appeared before teleport"
            )

            return false,
                not stillSafe
                and tostring(stillSafeWhy)
                or "valid egg match appeared before teleport"
        end
    end

    runtime.CurrentAttempt = {
        Serial = attemptSerial,
        Reason =
            tostring(reason or "auto"),
        SourceJobId = sourceJobId,
        DestinationJobId =
            tostring(chosen.id),
        RequestedAt = os.clock(),
        TeleportState = "REQUESTED",
    }

    runtime.LastHopAt =
        os.clock()

    -- Temporary state/failure listeners belong only to this one attempt.
    local failureConnection = nil
    local stateConnection = nil

    local function disconnectAttemptConnections()
        if failureConnection then
            failureConnection:Disconnect()
            failureConnection = nil
        end

        if stateConnection then
            stateConnection:Disconnect()
            stateConnection = nil
        end
    end

    failureConnection =
        TeleportService.TeleportInitFailed:Connect(
            function(player, result, errorMessage)
                if player ~= LP
                    or runtime.AttemptSerial ~= attemptSerial then

                    return
                end

                disconnectAttemptConnections()

                releaseAttempt(
                    "TeleportInitFailed: "
                    .. tostring(
                        errorMessage
                        or result
                        or "unknown"
                    ),
                    chosen.id
                )
            end
        )

    -- This listener does NOT queue Auto Execute. It only records progress for
    -- hop diagnostics/recovery.
    pcall(function()
        stateConnection =
            LP.OnTeleport:Connect(function(state)
                if runtime.AttemptSerial ~= attemptSerial
                    or not runtime.CurrentAttempt then

                    return
                end

                runtime.CurrentAttempt.TeleportState =
                    tostring(state)
            end)
    end)

    local ok, teleportErr =
        pcall(function()
            TeleportService:TeleportToPlaceInstance(
                game.PlaceId,
                chosen.id,
                LP
            )
        end)

    if not ok then
        disconnectAttemptConnections()

        releaseAttempt(
            "teleport call failed: "
            .. tostring(teleportErr),
            chosen.id
        )

        return false, "teleport call failed"
    end

    -- Roblox can accept TeleportToPlaceInstance yet never actually leave.
    -- If this exact client is still in the same JobId after 15 seconds,
    -- release the lock, avoid this destination temporarily, and let the next
    -- movement cycle retry another server automatically.
    task.delay(15, function()
        if env.__SERENITY_RAP_AUTO_GENERATION ~= generation
            or runtime.AttemptSerial ~= attemptSerial then

            disconnectAttemptConnections()
            return
        end

        if rejoinRequested
            and tostring(game.JobId or "") == sourceJobId then

            disconnectAttemptConnections()

            releaseAttempt(
                "hop watchdog timeout",
                chosen.id
            )

            -- Preserve an already-running no-target timer so Auto Hop can
            -- retry immediately on the next safe movement cycle.
            if noRejoinTargetSince == nil then
                noRejoinTargetSince =
                    os.clock()
                    - math.max(
                        REJOIN_NO_TARGET_CONFIRM_SECONDS,
                        tonumber(
                            Config.RejoinIntervalSeconds
                        ) or 5
                    )
            end
        else
            disconnectAttemptConnections()
        end
    end)

    return true, chosen.id
end

shared.SerenityRideAPet.RequestServerHopNow = function()
    local runtime =
        shared.SerenityRideAPet.RejoinRuntime

    if runtime.ManualHopPending then
        return false, "already queued"
    end

    if rejoinRequested then
        return false, "hop already in progress"
    end

    runtime.ManualHopPending = true
    runtime.ManualHopRequestedAt =
        os.clock()

    -- If the movement worker was stale/dead, make sure the queued manual hop
    -- still gets a chance to run.
    task.defer(function()
        local ensure =
            shared.SerenityRideAPet.EnsureMovementLaneWorker

        if type(ensure) == "function" then
            pcall(
                ensure,
                "manual-server-hop",
                false
            )
        end
    end)

    return true, "queued"
end

local function maybeAutoRejoinNoEgg()
    local rejoinRuntime =
        shared.SerenityRideAPet.RejoinRuntime

    local kgRuntime =
        shared.SerenityRideAPet.KGHuntRuntime

    if Config.AutoRejoinNoEgg ~= true then
        noRejoinTargetSince = nil

        if kgRuntime then
            kgRuntime.EnabledLast =
                false
        end

        return false
    end

    -- Auto Hop is specifically a K.G hunt. A Minimum K.G of 0 disables the
    -- hopping behavior while leaving Auto Steal's Luck/Specific filters alone.
    if shared.SerenityRideAPet.MinimumStealKG() <= 0 then
        noRejoinTargetSince = nil

        if kgRuntime then
            kgRuntime.EnabledLast =
                true
        end

        return false
    end

    if rejoinRequested then
        return false
    end

    local currentJob =
        tostring(
            game.JobId
            or ""
        )

    local currentFilterSignature =
        shared.SerenityRideAPet
            .KGHuntFilterSignature()

    -- Primary stock boundary check. This runs even if the client missed the
    -- restock banner, so a completed previous stock cannot pin Auto Hop after
    -- EggCycle.Index advances.
    shared.SerenityRideAPet.SyncAutoHopNativeStock(
        "auto-hop-global-cycle-check"
    )

    -- A manual rejoin/new JobId must preserve a confirmed success for the
    -- exact same filters. Auto Hop continues hunting across servers only when
    -- no qualifying egg has actually been obtained yet.
    if not kgRuntime
        or tostring(kgRuntime.JobId or "")
            ~= currentJob then

        shared.SerenityRideAPet
            .ResetKGHuntRuntime(
                "new-job",
                true
            )

        kgRuntime =
            shared.SerenityRideAPet
                .KGHuntRuntime
    elseif kgRuntime.EnabledLast
        ~= true then

        shared.SerenityRideAPet
            .ClearPersistedKGHunt()

        shared.SerenityRideAPet
            .ResetKGHuntRuntime(
                "auto-hop-toggled-on",
                false
            )

        kgRuntime =
            shared.SerenityRideAPet
                .KGHuntRuntime
    elseif tostring(
        kgRuntime.LastKGSignature
        or ""
    ) ~= currentFilterSignature then

        local keptSatisfied =
            shared.SerenityRideAPet
                .RefreshPersistedKGHuntSignature()

        if not keptSatisfied then
            shared.SerenityRideAPet
                .ClearPersistedKGHunt()
        end

        shared.SerenityRideAPet
            .ResetKGHuntRuntime(
                keptSatisfied
                    and "target-filters-changed-still-satisfied"
                    or "target-filters-changed",
                keptSatisfied
            )

        kgRuntime =
            shared.SerenityRideAPet
                .KGHuntRuntime
    elseif tonumber(
        kgRuntime.LastConfirmedRestockGeneration
    ) ~= (
        tonumber(
            restockState.KGHuntRestockGeneration
        )
        or 0
    ) then

        -- The global EggCycle.Index is the primary stock boundary. This
        -- generation branch handles that confirmed boundary (or the legacy
        -- notification fallback) without letting replication bursts re-arm.
        shared.SerenityRideAPet
            .ClearPersistedKGHunt()

        shared.SerenityRideAPet
            .ResetKGHuntRuntime(
                "new-stock",
                false
            )

        kgRuntime =
            shared.SerenityRideAPet
                .KGHuntRuntime
    end

    kgRuntime.EnabledLast =
        true

    kgRuntime.LastKGSignature =
        currentFilterSignature

    kgRuntime.LastConfirmedRestockGeneration =
        tonumber(
            restockState.KGHuntRestockGeneration
        )
        or 0

    rejoinRuntime.LastFilterSignature =
        currentFilterSignature

    -- v80.2.84: recover completion from the game's authoritative native
    -- EggType+Cycle claim state. This covers manual rejoin/re-execution and
    -- older v83 sessions whose saved latch was cleared by a K.G filter edit.
    if kgRuntime.GoalSatisfied ~= true then
        local claimedTarget =
            claimedCurrentRejoinTarget()

        if claimedTarget then
            shared.SerenityRideAPet
                .MarkKGHuntGoalSatisfied(
                    claimedTarget
                )

            kgRuntime =
                shared.SerenityRideAPet
                    .KGHuntRuntime
        end
    end

    -- Successfully GETTING a qualifying K.G egg completes this hunt.
    -- A native same-stock claim also proves completion; merely seeing an
    -- unclaimed egg never sets GoalSatisfied.
    if kgRuntime.GoalSatisfied
        == true then

        noRejoinTargetSince =
            nil

        return false
    end

    if movementLaneBusy
        or equipmentActionBusy then

        return false
    end

    local gameplaySafe =
        shared.SerenityRideAPet
            .TeleportGameplaySafe()

    if not gameplaySafe then
        return false
    end

    if os.clock()
        - sessionStartedAt
        < REJOIN_INITIAL_GRACE_SECONDS then

        return false
    end

    -- Full ActiveEggs snapshot scan every cycle. This catches eggs that were
    -- already replicated before Serenity auto-executed after a teleport.
    local found =
        serverHasRejoinTargetEgg()

    if found then
        noRejoinTargetSince =
            nil

        return false
    end

    -- Nothing at/above the configured K.G threshold is currently stealable.
    -- Use the idle movement lane for Sell first.
    if Config.AutoSell then
        local sellable =
            sellCandidate()

        if sellable then
            local richie =
                shared.SerenityRideAPet
                    .RichieSellContext()

            if richie then
                noRejoinTargetSince =
                    nil

                return false
            end
        end
    end

    if noRejoinTargetSince
        == nil then

        noRejoinTargetSince =
            os.clock()

        return false
    end

    local noTargetAge =
        os.clock()
        - noRejoinTargetSince

    local configuredInterval =
        math.max(
            REJOIN_NO_TARGET_CONFIRM_SECONDS,
            math.clamp(
                tonumber(
                    Config.RejoinIntervalSeconds
                )
                or 5,
                0,
                3600
            )
        )

    if noTargetAge
        < configuredInterval then

        return false
    end

    -- Re-check immediately before requesting a destination. The request
    -- function performs one more final live check before teleport.
    if serverHasRejoinTargetEgg() then
        noRejoinTargetSince =
            nil

        return false
    end

    local started =
        requestSerenityRejoin(
            "auto-no-matching-kg-egg"
        )

    return started
end

-- Independent hop-lock watchdog.
-- The per-attempt watchdog is primary; this prevents a stale rejoinRequested
-- flag from surviving indefinitely after mobile suspend/resume.
task.spawn(function()
    local workerGeneration = generation

    while env.__SERENITY_RAP_AUTO_GENERATION == workerGeneration do
        local runtime =
            shared.SerenityRideAPet.RejoinRuntime

        local attempt =
            runtime
            and runtime.CurrentAttempt

        local requestedAt =
            attempt
            and tonumber(
                attempt.RequestedAt
            )
            or nil

        if rejoinRequested
            and attempt
            and requestedAt
            and os.clock() - requestedAt > 20
            and tostring(game.JobId or "")
                == tostring(attempt.SourceJobId or "") then

            local failedId =
                tostring(
                    attempt.DestinationJobId
                    or ""
                )

            if failedId ~= "" then
                runtime.FailedServers[failedId] =
                    os.clock() + 180
            end

            runtime.LastHopError =
                "stale hop lock recovered"

            runtime.CurrentAttempt = nil
            runtime.AttemptSerial =
                (tonumber(runtime.AttemptSerial) or 0)
                + 1

            rejoinRequested = false
        end

        task.wait(1)
    end
end)

-- ============================================================
-- MOVEMENT LANE
--
-- IMPORTANT:
-- Keep this whole loop inside its OWN function scope.
-- The main runtime is large and v80.1.7 hit Luau's ~200 local-register
-- ceiling at `local ranked = serverEggCandidates()`.
--
-- Moving the movement lane into a separate function gives it an independent
-- local-register frame without removing any feature.
--
-- ONLY two features belong here:
--   1. STEAL
--   2. SELL
--
-- Steal always runs first. Sell gets its turn immediately after the steal
-- attempt. Direct/API workers are blocked while Steal owns exclusivity.
-- ============================================================

shared.SerenityRideAPet.MovementRuntime =
    shared.SerenityRideAPet.MovementRuntime
    or {}

shared.SerenityRideAPet.MovementRuntime.Serial =
    (tonumber(
        shared.SerenityRideAPet.MovementRuntime.Serial
    ) or 0)
    + 1

shared.SerenityRideAPet.MovementRuntime.Heartbeat = os.clock()
shared.SerenityRideAPet.MovementRuntime.LastCompletedCycle = os.clock()
shared.SerenityRideAPet.MovementRuntime.LastCycleStarted = os.clock()
shared.SerenityRideAPet.MovementRuntime.LastError = nil
shared.SerenityRideAPet.MovementRuntime.Thread = nil
shared.SerenityRideAPet.MovementRuntime.RecoveryCount =
    tonumber(
        shared.SerenityRideAPet.MovementRuntime.RecoveryCount
    ) or 0
shared.SerenityRideAPet.MovementRuntime.LastRestartAt =
    tonumber(
        shared.SerenityRideAPet.MovementRuntime.LastRestartAt
    ) or 0

shared.SerenityRideAPet.RunMovementCycle = function()
    movementLaneBusy = true
    shared.SerenityRideAPet.MovementRuntime.LastCycleStarted = os.clock()
    shared.SerenityRideAPet.MovementRuntime.Heartbeat = os.clock()

    if not shared.SerenityRideAPet.RefreshRuntimeCharacterRefs(0) then
        movementLaneBusy = false
        task.wait(0.20)
        return
    end

    if not Humanoid
        or Humanoid.Parent == nil
        or Humanoid.Health <= 0
        or not HRP
        or HRP.Parent == nil then

        movementLaneBusy = false
        task.wait(0.20)
        return
    end

    shared.SerenityRideAPet.RecoverStaleEquipmentLock(20)

    local movementDidWork = false
    local stealAttempted = false
    local stealWaitingForDrop = false

    -- MOVEMENT STEP 1: STEAL
    if Config.AutoSteal ~= true then
        shared.SerenityRideAPet.ResetStealStuckRuntime()
    end

    if Config.AutoSteal then
        local ranked = serverEggCandidates()
        shared.SerenityRideAPet.MovementRuntime.Heartbeat = os.clock()

        if #ranked > 0 then
            shared.SerenityRideAPet.MovementRuntime.LastStealCandidateSeen =
                os.clock()

            local topBefore =
                ranked[1]

            if topBefore.dropReady ~= true then
                -- Waiting for native DropEndsAt is not a movement stall.
                -- Do not start the 10-second fallback until the egg is actually
                -- ready and Serenity is trying to enter the steal transaction.
                shared.SerenityRideAPet.ResetStealStuckRuntime()
                stealWaitingForDrop = true

                shared.SerenityRideAPet.MovementRuntime.Heartbeat =
                    os.clock()

                task.wait(0.06)
            else
                local stuckForTenSeconds =
                    shared.SerenityRideAPet
                        .UpdateStealStuckWatch(
                            topBefore
                        )

                if stuckForTenSeconds then
                    pcall(
                        emergencyReturnHomeAfterStuckSteal,
                        "StuckSteal10SecondReturn"
                    )

                    shared.SerenityRideAPet.ResetStealStuckRuntime()
                    movementDidWork = true
                    task.wait(0.12)
                else
                    local stealLaneReady, stealLaneReason =
                    shared.SerenityRideAPet.BeginStealAction(
                        topBefore
                    )

                if stealLaneReady then
                    local canMove = ensureDismounted()
                    shared.SerenityRideAPet.MovementRuntime.Heartbeat = os.clock()

                    if canMove then
                        stealAttempted = true
                        shared.SerenityRideAPet.MovementRuntime.LastStealAttempt =
                            os.clock()

                        log("")
                        log("=== MOVEMENT_1_STEAL ===")
                        log("TopServerEgg=" .. tostring(topBefore.eggType))
                        log("TopServerEggLuck=" .. tostring(topBefore.eggLuck))
                        log("TopServerEggDistance=" .. tostring(topBefore.distance))

                        local stealCallOk, stealResult, stealReason =
                            xpcall(
                                function()
                                    return pickupRarestAvailable(topBefore)
                                end,
                                debug.traceback
                            )

                        local stealRuntime =
                            shared.SerenityRideAPet.StealActionRuntime

                        if stealRuntime
                            and stealRuntime.AbortRequested == true
                            and stealRuntime.EmergencyReturn ~= true then

                            pcall(
                                emergencyReturnHomeAfterStuckSteal,
                                "StuckStealCycleReturn"
                            )
                        end

                        -- Always resume direct workers, including on exceptions.
                        shared.SerenityRideAPet.EndStealAction()

                        if not stealCallOk then
                            error(stealResult, 0)
                        end

                        local ok = stealResult
                        local reason = stealReason

                        shared.SerenityRideAPet.MovementRuntime.Heartbeat = os.clock()

                        log("StealResult=" .. tostring(ok))
                        log("StealReason=" .. tostring(reason))

                        if ok then
                            movementDidWork = true
                            shared.SerenityRideAPet.ResetStealStuckRuntime()
                            shared.SerenityRideAPet.MovementRuntime.LastStealSuccess =
                                os.clock()
                        end

                        task.wait(ok and 0.04 or 0.08)
                    else
                        shared.SerenityRideAPet.EndStealAction()

                        log("StealState=WAITING_FOR_DISMOUNT")
                        task.wait(0.08)
                    end
                else
                    if tostring(stealLaneReason)
                        == "unresolved carried Basket egg" then

                        local basketRuntime =
                            shared.SerenityRideAPet
                                .UnresolvedBasketRuntime

                        local now =
                            os.clock()

                        if now
                            - (
                                tonumber(
                                    basketRuntime.LastWaitLogAt
                                )
                                or 0
                            ) >= 1 then

                            basketRuntime.LastWaitLogAt =
                                now

                            log(
                                "StealState=RECOVERING_CARRIED_EGG"
                                .. " Reason="
                                .. tostring(
                                    stealLaneReason
                                )
                            )
                        end

                        if basketRuntime.Recovering
                            ~= true then

                            local recovered,
                                recoverReason =
                                shared.SerenityRideAPet
                                    .TryRecoverUnresolvedBasketEgg()

                            if recovered then
                                log(
                                    "StealBasketRecovery=true"
                                )
                            elseif recoverReason
                                and recoverReason
                                    ~= "basket recovery cooldown"
                                and recoverReason
                                    ~= "basket recovery already running"
                                and recoverReason
                                    ~= "basket claim grace" then

                                log(
                                    "StealBasketRecoveryReason="
                                    .. tostring(
                                        recoverReason
                                    )
                                )
                            end
                        end
                    elseif tostring(stealLaneReason)
                        == "volcanic retry cooldown" then

                        -- Expected quiet state after a failed Volcanic pickup.
                        -- Do not write the same wait reason several times/sec.
                        task.wait(0.20)
                    elseif tostring(
                        stealLaneReason
                    ) ~= "steal action already busy" then

                        log(
                            "StealState=WAITING_FOR_DIRECT_ACTION"
                            .. " Reason="
                            .. tostring(stealLaneReason)
                        )
                    end

                    task.wait(0.06)
                end
                end
            end
        else
            shared.SerenityRideAPet.ResetStealStuckRuntime()
        end
    end

    -- MOVEMENT STEP 2: SELL
    -- Auto Hatch V5 now performs local movement. If any direct/API action has
    -- already entered its gate, let it finish before Richie movement begins.
    local directActionBusy =
        shared.SerenityRideAPet.DirectActionRuntime
        and (
            tonumber(
                shared.SerenityRideAPet
                    .DirectActionRuntime
                    .ActiveCount
            ) or 0
        ) > 0

    if Config.AutoSell
        and not directActionBusy
        and not stealWaitingForDrop then
        if tryAcquireEquipment("SELL") then
            local sold = false
            local sellInfo = nil

            local okSell, sellErr =
                xpcall(
                    function()
                        sold, sellInfo = autoSellOne()
                    end,
                    debug.traceback
                )

            releaseEquipment("SELL")

            if not okSell then
                error(sellErr, 0)
            end

            shared.SerenityRideAPet.MovementRuntime.Heartbeat = os.clock()

            if sold then
                log("")
                log("=== MOVEMENT_2_SELL ===")
                log("SellResult=CONFIRMED")
                log("SoldPet=" .. tostring(sellInfo))
                movementDidWork = true
                task.wait(0.08)
            else
                task.wait(0.05)
            end
        else
            task.wait(0.04)
        end
    end

    -- MOVEMENT STEP 3: BASE MAINTENANCE
    local baseRuntime =
        shared.SerenityRideAPet.BaseMaintenanceRuntime

    if baseRuntime
        and baseRuntime.ReturnRequested == true
        and Config.BaseMaintenanceIdleReturn ~= false then

        local stealStillWaiting = false

        if Config.AutoSteal == true then
            local currentStealTargets =
                serverEggCandidates()

            stealStillWaiting =
                #currentStealTargets > 0
        end

        if not stealStillWaiting
            and not shared.SerenityRideAPet.IsStealActionBusy() then

            local returned =
                shared.SerenityRideAPet.ReturnToBaseForMaintenance()

            if returned then
                movementDidWork = true
            end
        end
    end

    movementLaneBusy = false

    local rejoinStarted = false
    local rejoinRuntime =
        shared.SerenityRideAPet.RejoinRuntime

    if rejoinRuntime.ManualHopPending == true then
        local started =
            requestSerenityRejoin(
                "manual"
            )

        if started then
            rejoinRuntime.ManualHopPending = false
            rejoinRuntime.ManualHopRequestedAt = 0
            rejoinStarted = true
        end
    else
        rejoinStarted =
            maybeAutoRejoinNoEgg()
    end

    shared.SerenityRideAPet.MovementRuntime.Heartbeat = os.clock()

    if rejoinStarted then
        -- Short wait only. The per-attempt 15-second watchdog owns failure
        -- recovery, so the movement worker itself never sleeps for the entire
        -- watchdog period.
        task.wait(2)
    end

    if movementDidWork then
        task.wait(0.03)
    elseif stealAttempted then
        task.wait(0.06)
    else
        task.wait(0.16)
    end
end

shared.SerenityRideAPet.RunMovementLane = function(serial)
    local cycle = 0

    while env.__SERENITY_RAP_AUTO_GENERATION == generation
        and shared.SerenityRideAPet.MovementRuntime.Serial == serial do

        cycle += 1
        shared.SerenityRideAPet.MovementRuntime.Heartbeat = os.clock()

        local ok, err =
            xpcall(
                shared.SerenityRideAPet.RunMovementCycle,
                debug.traceback
            )

        movementLaneBusy = false
        shared.SerenityRideAPet.MovementRuntime.Heartbeat = os.clock()

        if ok then
            shared.SerenityRideAPet.MovementRuntime.LastCompletedCycle = os.clock()
            shared.SerenityRideAPet.MovementRuntime.LastError = nil
        else
            shared.SerenityRideAPet.MovementRuntime.LastError = tostring(err)

            log("")
            log("=== MOVEMENT_LANE_RECOVERED_ERROR ===")
            log("Cycle=" .. tostring(cycle))
            log("Error=" .. tostring(err))

            if equipmentActionOwner == "SELL" then
                releaseEquipment("SELL")
            end

            shared.SerenityRideAPet.RecoverStaleEquipmentLock(0)
            shared.SerenityRideAPet.EndStealAction()
            shared.SerenityRideAPet.RefreshRuntimeCharacterRefs(2)
            task.wait(0.35)
        end
    end

    movementLaneBusy = false
end

shared.SerenityRideAPet.EnsureMovementLaneWorker = function(reason, force)
    if env.__SERENITY_RAP_AUTO_GENERATION ~= generation then
        return false
    end

    -- Prevent a persistent external/game error from causing a rapid restart
    -- storm. UI toggles use non-forced wakeups and never cancel a healthy
    -- transaction. CharacterAdded/watchdog recovery may still force restart.
    if string.find(
        tostring(reason or ""),
        "watchdog:",
        1,
        true
    ) then
        local sinceRestart =
            os.clock()
            - (tonumber(
                shared.SerenityRideAPet.MovementRuntime.LastRestartAt
            ) or 0)

        if sinceRestart < 4 then
            return false
        end
    end

    local thread = shared.SerenityRideAPet.MovementRuntime.Thread
    local alive = false

    if thread then
        local okStatus, status = pcall(coroutine.status, thread)
        alive = okStatus and status ~= "dead"
    end

    local stale =
        os.clock()
        - (tonumber(shared.SerenityRideAPet.MovementRuntime.Heartbeat) or 0)
        > 30

    if force ~= true
        and alive
        and not stale then

        return true
    end

    -- Clean up artifacts owned by a stale/cancelled movement worker before a
    -- replacement starts. This is especially important after mobile suspend.
    local activeTween = shared.SerenityRideAPet.ActiveMovementTween
    if activeTween then
        pcall(function()
            activeTween:Cancel()
        end)
        shared.SerenityRideAPet.ActiveMovementTween = nil
    end

    local cleanupNoclip = shared.SerenityRideAPet.ActiveNoclipCleanup
    if type(cleanupNoclip) == "function" then
        pcall(cleanupNoclip)
        shared.SerenityRideAPet.ActiveNoclipCleanup = nil
    end

    if thread and alive then
        pcall(task.cancel, thread)
    end

    movementLaneBusy = false

    if equipmentActionOwner == "SELL" then
        releaseEquipment("SELL")
    end

    shared.SerenityRideAPet.RecoverStaleEquipmentLock(0)
    shared.SerenityRideAPet.EndStealAction()
    shared.SerenityRideAPet.RefreshRuntimeCharacterRefs(2)

    shared.SerenityRideAPet.MovementRuntime.Serial =
        (tonumber(shared.SerenityRideAPet.MovementRuntime.Serial) or 0)
        + 1

    local serial = shared.SerenityRideAPet.MovementRuntime.Serial

    shared.SerenityRideAPet.MovementRuntime.Heartbeat = os.clock()
    shared.SerenityRideAPet.MovementRuntime.LastRestartAt = os.clock()
    shared.SerenityRideAPet.MovementRuntime.LastRestartReason =
        tostring(reason or "ensure")

    log(
        "MovementWorker.Restart="
        .. tostring(reason or "ensure")
    )
    shared.SerenityRideAPet.MovementRuntime.RecoveryCount =
        (tonumber(
            shared.SerenityRideAPet.MovementRuntime.RecoveryCount
        ) or 0)
        + 1

    shared.SerenityRideAPet.MovementRuntime.Thread =
        task.spawn(
            shared.SerenityRideAPet.RunMovementLane,
            serial
        )

    log("")
    log("=== MOVEMENT_LANE_STARTED ===")
    log("Reason=" .. tostring(shared.SerenityRideAPet.MovementRuntime.LastRestartReason))

    return true
end

-- Establish the single movement owner before the watchdog starts.
-- This avoids a startup race where both "watchdog:worker-dead" and "initial"
-- can restart the lane at nearly the same instant.
shared.SerenityRideAPet.EnsureMovementLaneWorker(
    "initial",
    true
)

-- Self-healing watchdog for long mobile/desktop sessions. It deliberately
-- supervises only the movement owner (Steal/Sell), leaving direct API workers
-- independent and preserving 2.5 gameplay behavior.
task.spawn(function()
    local workerGeneration = generation

    while env.__SERENITY_RAP_AUTO_GENERATION == workerGeneration do
        local characterChanged =
            Character ~= LP.Character
            or not HRP
            or HRP.Parent == nil
            or not Humanoid
            or Humanoid.Parent == nil

        if characterChanged then
            local refreshed =
                shared.SerenityRideAPet.RefreshRuntimeCharacterRefs(2)

            if refreshed then
                shared.SerenityRideAPet.EnsureMovementLaneWorker(
                    "watchdog:character-refresh",
                    true
                )
            end
        end

        shared.SerenityRideAPet.RecoverStaleEquipmentLock(20)

        local thread = shared.SerenityRideAPet.MovementRuntime.Thread
        local alive = false

        if thread then
            local okStatus, status = pcall(coroutine.status, thread)
            alive = okStatus and status ~= "dead"
        end

        local heartbeatAge =
            os.clock()
            - (tonumber(shared.SerenityRideAPet.MovementRuntime.Heartbeat) or 0)

        local completedCycleAge =
            os.clock()
            - (tonumber(
                shared.SerenityRideAPet.MovementRuntime.LastCompletedCycle
            ) or 0)

        if not alive then
            shared.SerenityRideAPet.EnsureMovementLaneWorker(
                "watchdog:worker-dead",
                true
            )
        elseif heartbeatAge > 30 then
            shared.SerenityRideAPet.EnsureMovementLaneWorker(
                "watchdog:heartbeat-stale",
                true
            )
        elseif completedCycleAge > 75
            and not shared.SerenityRideAPet
                .IsStealActionBusy() then

            -- Never spawn a second movement lane over a legitimate long
            -- Volcano/mutation lifecycle. Basket recovery handles unresolved
            -- carried eggs after the active steal actually releases ownership.
            shared.SerenityRideAPet.EnsureMovementLaneWorker(
                "watchdog:cycle-stale",
                true
            )
        end

        task.wait(2)
    end
end)

log("")
log("=== AUTOMATION_RUNTIME_ACTIVE ===")
log("Generation=" .. tostring(generation))
log("MovementWatchdog=true")
log("CharacterRefresh=true")
log("ToggleForceRestart=false")
log("RecoveryCleansTweenOnly=true")
log("ManagedCharacterAddedConnection=true")
log("BoundedTweenCompletion=true")
log("AutomationNoclipWorkers=false")
log("CycleProgressWatchdog=true")
log("DirectWorkersErrorProtected=true")

shared.SerenityRideAPet.GetStabilityState = function()
    local notification =
        shared.SerenityRideAPet.NotificationRuntime
        or {}

    local streaming =
        shared.SerenityRideAPet.StreamingRuntime
        or {}

    local capacity =
        shared.SerenityRideAPet.PlaceCapacityState
        or {}

    local watchedCount = 0

    for _ in pairs(
        notification.Watched or {}
    ) do
        watchedCount += 1
    end

    return {
        Version = VERSION,
        NotificationRootConnections =
            #(notification.Connections or {}),
        NotificationWatchedText =
            watchedCount,
        NotificationRelevantHits =
            tonumber(notification.RelevantHits) or 0,
        CapacityConnections =
            #(capacity.FolderConnections or {}),
        StreamingBusy =
            streaming.Busy == true,
        MovementHeartbeatAge =
            os.clock()
            - (
                tonumber(
                    shared.SerenityRideAPet
                        .MovementRuntime
                        .Heartbeat
                )
                or os.clock()
            ),
        MovementRecoveryCount =
            tonumber(
                shared.SerenityRideAPet
                    .MovementRuntime
                    .RecoveryCount
            )
            or 0,
    }
end

-- v80.2.99 production: temporary performance sampler removed.

end

-- v80.2.61:
-- Runtime workers/watchdog/movement lane compile in their own register frame.
shared.SerenityRideAPet.InitContinuousAutomationRuntime()
