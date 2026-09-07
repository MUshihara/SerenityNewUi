-- SERENITY HUB // +1 PHONK EVOLUTION
-- OFFICIAL SERENITY V3 FINAL BUILD
-- All automation switches start DISABLED.
-- There is NO master start button: each switch works immediately.
-- Auto Wins = walking + noclip only while running.
-- Other movement features = teleport + fast rollback.
-- Paid / Robux paths are excluded.

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local EXPECTED_PLACE = 104809044319701
if game.PlaceId ~= EXPECTED_PLACE then
    return
end

local env = (getgenv and getgenv()) or _G

-- Final build is intentionally silent.
local function silent(...)
end

local print = silent
local warn = silent

-- Stop a previous Phonk runtime if it is still running.
do
    local old = env.SerenityPhonk
    if old and type(old.Destroy) == "function" then
        pcall(old.Destroy)
    elseif old and type(old.Stop) == "function" then
        pcall(old.Stop)
    end
    env.SerenityPhonk = nil
end

local GuiService = game:GetService("GuiService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LP = Players.LocalPlayer

pcall(function()
    GuiService:SetGameplayPausedNotificationEnabled(false)
end)

pcall(function()
    RunService:Set3dRenderingEnabled(true)
end)

-- ============================================================
-- GAME DATA / REMOTES
-- ============================================================

local ItemConfig = require(ReplicatedStorage:WaitForChild("ItemConfig"))
local PetConfig = require(ReplicatedStorage:WaitForChild("PetConfig"))
local TrailConfig = require(ReplicatedStorage:WaitForChild("TrailConfig"))
local CashPadConfig = require(ReplicatedStorage:WaitForChild("CashPadConfig"))
local GroupRewardConfig = require(ReplicatedStorage:WaitForChild("GroupRewardConfig"))

local Shared = ReplicatedStorage:WaitForChild("Shared")
local EnemyStageConfig = require(Shared:WaitForChild("EnemyStageConfig"))

local Main = ReplicatedStorage:WaitForChild("MainGameRemotes")
local Daily = ReplicatedStorage:WaitForChild("DailyTrailRemotes")
local Pets = ReplicatedStorage:WaitForChild("PetRemotes")
local Offline = ReplicatedStorage:WaitForChild("OfflineRewardRemotes")

local RequestXpClick = Main:WaitForChild("RequestXpClick")
local RequestEvolve = Main:WaitForChild("RequestEvolve")
local RequestRebirth = Main:WaitForChild("RequestRebirth")
local RequestEquipBodyTier = Main:FindFirstChild("RequestEquipBodyTier")
local RequestEquipItemTier = Main:FindFirstChild("RequestEquipItemTier")
local RequestGroupReward = Main:FindFirstChild("RequestGroupReward")
local RequestReviveAction = Main:WaitForChild("RequestReviveAction")
local ReviveState = Main:WaitForChild("ReviveState")

local GetDailyState = Daily:WaitForChild("GetState")
local RequestDailyReward = Daily:WaitForChild("RequestDailyReward")
local RequestTrailAction = Daily:WaitForChild("RequestTrailAction")

local PetRequest = Pets:WaitForChild("Request")
local OfflineGetOffer = Offline:WaitForChild("GetOffer")
local OfflineClaim = Offline:WaitForChild("Claim")

local Stages = Workspace:WaitForChild("Stages")
local WinPads = Workspace:WaitForChild("WinPads")
local ItemPads = Workspace:WaitForChild("ItemPads")


-- ============================================================
-- REVIVE POPUP REMOVAL / INSTANT RESPAWN
-- Built-in behavior for Serenity; no UI toggle.
-- Uses the same FREE "Respawn" action as the game's No/Close button.
-- Paid Revive/Revenge actions are never used.
-- ============================================================

local Frames = LP:WaitForChild("PlayerGui"):WaitForChild("Frames")
local ReviveFrame = Frames:WaitForChild("Revive")
local MenuControl = Frames:FindFirstChild("MenuControl")

local reviveRespawnBusy = false

local function forceCloseRevive()
    pcall(function()
        ReviveFrame.Visible = false
    end)

    if MenuControl then
        pcall(function()
            MenuControl:Fire("Close", "Revive")
        end)
    end
end

local function instantFreeRespawn()
    if reviveRespawnBusy then
        forceCloseRevive()
        return
    end

    reviveRespawnBusy = true
    forceCloseRevive()

    pcall(function()
        RequestReviveAction:FireServer("Respawn")
    end)

    task.delay(0.35, function()
        reviveRespawnBusy = false
        forceCloseRevive()
    end)
end

forceCloseRevive()

ReviveFrame:GetPropertyChangedSignal("Visible"):Connect(function()
    if ReviveFrame.Visible then
        forceCloseRevive()
    end
end)

ReviveState.OnClientEvent:Connect(function(action)
    if action == "Prompt" then
        task.defer(instantFreeRespawn)
    elseif action == "Resolved" then
        task.defer(forceCloseRevive)
    end
end)

-- ============================================================
-- RUNTIME STATE
-- EVERYTHING IS OFF BY DEFAULT
-- ============================================================

local State = {
    Alive = true,

    AutoClick = false,
    AutoWins = false,
    AutoTreadmill = false,

    AutoEvolve = false,
    AutoRebirth = false,
    AutoEquipBody = false,
    AutoEquipAura = false,
    AutoBuyAura = false,

    AutoHatch = false,
    AutoEquipPet = false,

    AutoBuyTrail = false,
    AutoEquipTrail = false,

    AutoDaily = false,
    AutoOffline = false,
    AutoGroup = false,

    VeryPotatoMode = false,
    Disable3D = false,

    AutoWinsNoclip = true,

    WalkSpeed = 500,
    ReachDistance = 8,
    ClickDelay = 0.10,
    TreadmillSeconds = 3,
    HatchDelay = 3,
    EggReserve = 0,
    AuraRetries = 4,
    CycleDelay = 0.20,
}

local function setBool(key, value)
    State[key] = value == true
    print("[SERENITY][PHONK]", key, "=", State[key])
end

local function setNumber(key, value, fallback)
    State[key] = tonumber(value) or fallback or State[key]
end

-- ============================================================
-- BASIC HELPERS
-- ============================================================

local function getChar()
    local char = LP.Character or LP.CharacterAdded:Wait()
    local root = char:WaitForChild("HumanoidRootPart")
    local hum = char:WaitForChild("Humanoid")
    return char, root, hum
end


-- ============================================================
-- BUILT-IN ANTI-RAGDOLL
-- Always active while Serenity runs. No toggle.
-- Keeps treadmill/egg/aura teleports from leaving the character
-- in FallingDown / Ragdoll / Physics / PlatformStand.
-- ============================================================

local antiRagdollConnections = {}

local function clearAntiRagdollConnections()
    for _, connection in ipairs(antiRagdollConnections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    table.clear(antiRagdollConnections)
end

local function stabilizeCharacter(hum, root)
    if not hum or not root or hum.Health <= 0 then
        return
    end

    pcall(function()
        hum.PlatformStand = false
    end)

    pcall(function()
        hum.Sit = false
    end)

    pcall(function()
        hum.AutoRotate = true
    end)

    pcall(function()
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    end)

    pcall(function()
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
    end)

    pcall(function()
        hum:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
    end)

    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero

    pcall(function()
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
    end)

    task.defer(function()
        if hum.Parent and hum.Health > 0 then
            pcall(function()
                hum.PlatformStand = false
                hum.Sit = false
                hum:ChangeState(Enum.HumanoidStateType.Running)
            end)
        end
    end)
end

local function bindAntiRagdoll(char)
    clearAntiRagdollConnections()

    local hum = char:WaitForChild("Humanoid", 8)
    local root = char:WaitForChild("HumanoidRootPart", 8)

    if not hum or not root then
        return
    end

    stabilizeCharacter(hum, root)

    antiRagdollConnections[#antiRagdollConnections + 1] =
        hum.StateChanged:Connect(function(_, newState)
            if hum.Health <= 0 then
                return
            end

            if newState == Enum.HumanoidStateType.FallingDown
                or newState == Enum.HumanoidStateType.Ragdoll
                or newState == Enum.HumanoidStateType.Physics
            then
                task.defer(function()
                    if hum.Parent and root.Parent and hum.Health > 0 then
                        stabilizeCharacter(hum, root)
                    end
                end)
            end
        end)

    antiRagdollConnections[#antiRagdollConnections + 1] =
        hum:GetPropertyChangedSignal("PlatformStand"):Connect(function()
            if hum.Health > 0 and hum.PlatformStand then
                task.defer(function()
                    if hum.Parent and root.Parent and hum.Health > 0 then
                        stabilizeCharacter(hum, root)
                    end
                end)
            end
        end)
end

task.defer(function()
    local char = LP.Character
    if char then
        bindAntiRagdoll(char)
    end
end)

LP.CharacterAdded:Connect(function(char)
    task.defer(function()
        bindAntiRagdoll(char)
    end)
end)

local function getWins()
    local leaderstats = LP:FindFirstChild("leaderstats")
    local v = leaderstats and leaderstats:FindFirstChild("Wins")

    if v and v:IsA("ValueBase") then
        return tonumber(v.Value) or 0
    end

    return tonumber(LP:GetAttribute("Wins")) or 0
end

local function highestOwnedAura()
    local best = 0

    for tier = 1, #ItemConfig.orderedItemNames do
        if LP:GetAttribute("OwnedItemTier" .. tier) == true then
            best = tier
        end
    end

    return best
end

-- ============================================================
-- TELEPORT SAFETY / VOID ROLLBACK
-- ============================================================

local lastSafeCFrame = nil

local function voidY()
    local value = Workspace.FallenPartsDestroyHeight

    if typeof(value) ~= "number"
        or value ~= value
        or math.abs(value) == math.huge
    then
        value = -500
    end

    return value + 20
end

local function isSafePosition(position)
    return position.Y > voidY()
end

local function rollbackNow()
    local _, root, hum = getChar()

    if not lastSafeCFrame then
        return false
    end

    hum:Move(Vector3.zero, false)
    stabilizeCharacter(hum, root)
    root.CFrame = lastSafeCFrame
    stabilizeCharacter(hum, root)

    return true
end

do
    local _, root = getChar()
    if isSafePosition(root.Position) then
        lastSafeCFrame = root.CFrame
    end
end

local function teleportTo(cf)
    local _, root, hum = getChar()

    local fallback =
        isSafePosition(root.Position)
        and root.CFrame
        or lastSafeCFrame

    if fallback then
        lastSafeCFrame = fallback
    end

    if Workspace.StreamingEnabled
        and (root.Position - cf.Position).Magnitude > 180
    then
        pcall(function()
            LP:RequestStreamAroundAsync(cf.Position)
        end)
    end

    for _ = 1, 3 do
        hum:Move(Vector3.zero, false)
        stabilizeCharacter(hum, root)

        root.CFrame = cf
        stabilizeCharacter(hum, root)

        task.wait(0.05)

        stabilizeCharacter(hum, root)

        local ok =
            root.Parent ~= nil
            and hum.Health > 0
            and isSafePosition(root.Position)
            and (root.Position - cf.Position).Magnitude <= 15

        if ok then
            stabilizeCharacter(hum, root)
            lastSafeCFrame = root.CFrame

            -- A second short stabilization catches delayed physics/ragdoll.
            task.defer(function()
                task.wait(0.08)

                if hum.Parent and root.Parent and hum.Health > 0 then
                    stabilizeCharacter(hum, root)
                end
            end)

            return true
        end

        if fallback then
            root.CFrame = fallback
        end

        task.wait(0.03)
    end

    if fallback then
        root.CFrame = fallback
    end

    return false
end

local function teleportToPart(part, y)
    y = y or 2

    return teleportTo(
        part.CFrame
        + Vector3.new(
            0,
            part.Size.Y * 0.5 + y,
            0
        )
    )
end

-- Fast void watchdog.
task.spawn(function()
    while State.Alive do
        local char = LP.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")

        if root and hum and hum.Health > 0 then
            if not isSafePosition(root.Position) then
                rollbackNow()
            elseif root.AssemblyLinearVelocity.Y > -80 then
                -- Continuously keep a recent safe fallback.
                lastSafeCFrame = root.CFrame
            end
        end

        task.wait(0.04)
    end
end)

-- ============================================================
-- MOVEMENT OWNERSHIP
-- Prevent teleport features from fighting Auto Wins movement.
-- ============================================================

local movementOwner = nil

local function acquireMovement(owner)
    if movementOwner ~= nil and movementOwner ~= owner then
        return false
    end

    movementOwner = owner
    return true
end

local function releaseMovement(owner)
    if movementOwner == owner then
        movementOwner = nil
    end
end

-- ============================================================
-- AUTO WINS SPEED STATE
-- Save the exact speed the player had before enabling Auto Wins.
-- Restore that exact value when Auto Wins is disabled.
-- ============================================================

local autoWinsOriginalSpeed = nil

local function currentHumanoid()
    local char = LP.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function captureAutoWinsOriginalSpeed()
    if autoWinsOriginalSpeed ~= nil then
        return
    end

    local hum = currentHumanoid()

    if hum then
        autoWinsOriginalSpeed = hum.WalkSpeed
    else
        autoWinsOriginalSpeed =
            tonumber(LP:GetAttribute("WalkSpeed"))
            or 16
    end
end

local function applyAutoWinsSpeed()
    if not State.AutoWins then
        return
    end

    local hum = currentHumanoid()

    if hum and hum.Health > 0 then
        hum.WalkSpeed = State.WalkSpeed
    end
end

local function restoreAutoWinsOriginalSpeed()
    local hum = currentHumanoid()

    if hum then
        local restore =
            autoWinsOriginalSpeed
            or tonumber(LP:GetAttribute("WalkSpeed"))
            or 16

        hum.WalkSpeed = restore
    end

    autoWinsOriginalSpeed = nil
end

LP.CharacterAdded:Connect(function(char)
    forceCloseRevive()

    local hum = char:WaitForChild("Humanoid", 8)

    if hum and State.AutoWins then
        task.defer(function()
            task.wait(0.25)

            if State.AutoWins
                and hum.Parent
                and hum.Health > 0
            then
                hum.WalkSpeed = State.WalkSpeed
            end
        end)
    end
end)

-- ============================================================
-- AUTO WINS NOCLIP
-- ============================================================

local noclipActive = false
local originalCollision = {}
local noclipConnection = nil

local function applyNoclip()
    if not noclipActive then
        return
    end

    local char = LP.Character
    if not char then
        return
    end

    for _, obj in ipairs(char:GetDescendants()) do
        if obj:IsA("BasePart") then
            if originalCollision[obj] == nil then
                originalCollision[obj] = obj.CanCollide
            end

            obj.CanCollide = false
        end
    end
end

local function setNoclip(enabled)
    if enabled and State.AutoWinsNoclip then
        if noclipActive then
            return
        end

        noclipActive = true
        table.clear(originalCollision)
        applyNoclip()

        noclipConnection = RunService.Stepped:Connect(applyNoclip)
        return
    end

    if not noclipActive then
        return
    end

    noclipActive = false

    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end

    for part, oldValue in pairs(originalCollision) do
        if part and part.Parent then
            part.CanCollide = oldValue
        end
    end

    table.clear(originalCollision)
end

-- ============================================================
-- AUTO CLICK
-- IMMEDIATE TOGGLE WORKER
-- ============================================================

task.spawn(function()
    while State.Alive do
        if State.AutoClick then
            local camera = Workspace.CurrentCamera
            local pos =
                camera and camera.ViewportSize / 2
                or Vector2.new(500, 300)

            pcall(
                RequestXpClick.FireServer,
                RequestXpClick,
                pos
            )

            task.wait(math.max(0.03, State.ClickDelay))
        else
            task.wait(0.05)
        end
    end
end)

-- ============================================================
-- AUTO WINS
-- VALIDATED MoveTo ROUTE + HIGH-SPEED LOOKAHEAD
-- ============================================================

local function highestNumericIndex(tbl)
    if type(tbl) ~= "table" then
        return nil
    end

    local highest = 0

    for key in pairs(tbl) do
        if type(key) == "number"
            and key % 1 == 0
            and key > highest
        then
            highest = key
        end
    end

    return highest > 0 and highest or nil
end

local function getLastStage()
    -- Read it from the game's own config instead of hardcoding "25".
    local candidates = {
        EnemyStageConfig.Stages,
        EnemyStageConfig.stages,
        EnemyStageConfig.StageConfigs,
        EnemyStageConfig.stageConfigs,
        EnemyStageConfig.Enemies,
        EnemyStageConfig.enemies,
        EnemyStageConfig,
    }

    for _, candidate in ipairs(candidates) do
        local count = highestNumericIndex(candidate)

        if count and count > 1 then
            return count
        end
    end

    -- Secondary structural fallback: use the highest numeric WinPad holder
    -- currently present. No coordinates or fixed final-stage number.
    local single = WinPads:FindFirstChild("Single")
    local highest = 0

    if single then
        for _, child in ipairs(single:GetChildren()) do
            local n = tonumber(child.Name)

            if n and n % 1 == 0 and n > highest then
                highest = n
            end
        end
    end

    return highest > 0 and highest or nil
end

local function cancelCharacterMovement()
    local _, root, hum = getChar()

    hum:Move(Vector3.zero, false)

    -- Cancel the previous MoveTo target by making the current position
    -- the new destination.
    hum:MoveTo(root.Position)

    root.AssemblyLinearVelocity = Vector3.new(
        0,
        root.AssemblyLinearVelocity.Y,
        0
    )
    root.AssemblyAngularVelocity = Vector3.zero
end

local function settleAfterReturn()
    local deadline = os.clock() + 0.75

    while State.AutoWins and os.clock() < deadline do
        cancelCharacterMovement()
        applyAutoWinsSpeed()
        task.wait(0.05)
    end

    cancelCharacterMovement()
    applyAutoWinsSpeed()
end


local function stagePosition(stage)
    local holder = Stages:FindFirstChild(tostring(stage))
    local hitbox =
        holder
        and holder:FindFirstChild("Hitbox", true)

    if hitbox and hitbox:IsA("BasePart") then
        return hitbox.Position
    end

    return nil
end

local function waitForStagePosition(stage, timeout)
    timeout = timeout or 8
    local deadline = os.clock() + timeout

    while State.Alive
        and State.AutoWins
        and os.clock() < deadline
    do
        local position = stagePosition(stage)

        if position then
            return position
        end

        -- Future stage folders can be streamed out.
        -- Request more world around the player's current route position.
        if Workspace.StreamingEnabled then
            local _, root = getChar()

            pcall(function()
                LP:RequestStreamAroundAsync(root.Position)
            end)
        end

        task.wait(0.15)
    end

    return nil
end

local function walkRoute(route)
    local char, root, hum = getChar()

    for index, target in ipairs(route) do
        if not State.Alive or not State.AutoWins then
            return false
        end

        cancelCharacterMovement()
        hum.WalkSpeed = State.WalkSpeed

        local previous =
            index > 1
            and route[index - 1]
            or root.Position

        local segment = Vector3.new(
            target.X - previous.X,
            0,
            target.Z - previous.Z
        )

        if segment.Magnitude <= 0.01 then
            continue
        end

        local direction = segment.Unit

        -- Small forward target avoids turning backward after a minor
        -- overshoot while still using Roblox's reliable MoveTo driver.
        local commandPosition =
            target + direction * 10

        hum:MoveTo(commandPosition)

        while State.Alive
            and State.AutoWins
            and char.Parent
            and hum.Health > 0
        do
            hum.WalkSpeed = State.WalkSpeed

            local flatDelta = Vector3.new(
                target.X - root.Position.X,
                0,
                target.Z - root.Position.Z
            )

            local distance = flatDelta.Magnitude

            local passed =
                Vector3.new(
                    root.Position.X - target.X,
                    0,
                    root.Position.Z - target.Z
                ):Dot(direction) >= 0

            local frameReach = math.clamp(
                State.WalkSpeed * 0.035,
                State.ReachDistance,
                20
            )

            if distance <= frameReach or passed then
                break
            end

            hum:MoveTo(commandPosition)
            task.wait(0.03)
        end

        cancelCharacterMovement()
        hum.WalkSpeed = State.WalkSpeed
        task.wait(0.03)
    end

    return State.AutoWins
end

local function waitForStageProgress(beforeProgress, timeout)
    timeout = timeout or 2.5
    local deadline = os.clock() + timeout

    while State.Alive
        and State.AutoWins
        and os.clock() < deadline
    do
        local current =
            tonumber(LP:GetAttribute("CurrentRunStage"))

        -- A real stage clear changes CurrentRunStage.
        if beforeProgress ~= nil
            and current ~= nil
            and current ~= beforeProgress
        then
            return true, current
        end

        task.wait(0.05)
    end

    -- If this game version temporarily stops replicating the attribute,
    -- don't invent success; tell the caller to use the reset fallback.
    return false, tonumber(LP:GetAttribute("CurrentRunStage"))
end

local function rootInsidePartXZ(root, part, margin)
    margin = margin or 1.5

    local localPos =
        part.CFrame:PointToObjectSpace(root.Position)

    return math.abs(localPos.X)
            <= part.Size.X * 0.5 + margin
        and math.abs(localPos.Z)
            <= part.Size.Z * 0.5 + margin
end

local function walkOntoPad(part, timeout, successCheck)
    if not (part and part:IsA("BasePart")) then
        return false
    end

    timeout = timeout or 6

    local char, root, hum = getChar()
    local deadline = os.clock() + timeout

    cancelCharacterMovement()

    while State.Alive
        and State.AutoWins
        and char.Parent
        and hum.Health > 0
        and os.clock() < deadline
    do
        if successCheck and successCheck() then
            cancelCharacterMovement()
            return true
        end

        hum.WalkSpeed = State.WalkSpeed
        hum:MoveTo(part.Position)

        if rootInsidePartXZ(root, part, 0.75) then
            local holdUntil = os.clock() + 0.35

            while State.AutoWins
                and os.clock() < holdUntil
            do
                if successCheck and successCheck() then
                    cancelCharacterMovement()
                    return true
                end

                hum.WalkSpeed = State.WalkSpeed
                hum:MoveTo(part.Position)
                task.wait(0.03)
            end

            if not successCheck then
                cancelCharacterMovement()
                return true
            end
        end

        task.wait(0.03)
    end

    cancelCharacterMovement()

    if successCheck and successCheck() then
        return true
    end

    return false
end

local function textSaysReturn(instance)
    return (
        instance:IsA("TextLabel")
        or instance:IsA("TextButton")
        or instance:IsA("TextBox")
    )
        and string.find(
            string.lower(tostring(instance.Text or "")),
            "return",
            1,
            true
        ) ~= nil
end

local function partFromReturnObject(obj)
    if obj:IsA("BasePart") then
        return obj
    end

    if obj:IsA("Model") then
        local preferred =
            obj:FindFirstChild("Button", true)
            or obj:FindFirstChild("Hitbox", true)
            or obj.PrimaryPart

        if preferred and preferred:IsA("BasePart") then
            return preferred
        end

        for _, descendant in ipairs(obj:GetDescendants()) do
            if descendant:IsA("BasePart") then
                return descendant
            end
        end
    end

    return nil
end

local function findReturnPad()
    local _, root = getChar()
    local candidates = {}

    local function add(part)
        if not part
            or not part:IsA("BasePart")
            or not isSafePosition(part.Position)
        then
            return
        end

        candidates[part] = true
    end

    -- 1) Object/model names containing "return".
    for _, obj in ipairs(Workspace:GetDescendants()) do
        local lowerName = string.lower(obj.Name)

        if string.find(lowerName, "return", 1, true) then
            add(partFromReturnObject(obj))

            local parent = obj.Parent
            if parent then
                add(partFromReturnObject(parent))
            end
        end
    end

    -- 2) UI labels saying "Return", even if the pad itself has a generic name.
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if textSaysReturn(obj) then
            local ancestor = obj.Parent

            while ancestor and ancestor ~= Workspace do
                local part = partFromReturnObject(ancestor)

                if part then
                    add(part)
                    break
                end

                ancestor = ancestor.Parent
            end
        end
    end

    local best = nil
    local bestDistance = math.huge

    for part in pairs(candidates) do
        local distance =
            (part.Position - root.Position).Magnitude

        if distance < bestDistance then
            best = part
            bestDistance = distance
        end
    end

    return best
end

local function waitForReturnPad(timeout)
    local deadline = os.clock() + (timeout or 8)

    while State.Alive
        and State.AutoWins
        and os.clock() < deadline
    do
        local pad = findReturnPad()

        if pad then
            return pad
        end

        if Workspace.StreamingEnabled then
            local _, root = getChar()

            pcall(function()
                LP:RequestStreamAroundAsync(root.Position)
            end)
        end

        task.wait(0.20)
    end

    return nil
end


local function resetCharacterForAutoWins(reason)
    if not State.AutoWins then
        return false
    end

    if reason ~= "successful run - clean respawn" then
        print(
            "[SERENITY][PHONK][AutoWins] RESET FALLBACK:",
            tostring(reason or "route failed")
        )
    end

    setNoclip(false)

    local oldCharacter = LP.Character
    local hum =
        oldCharacter
        and oldCharacter:FindFirstChildOfClass("Humanoid")

    if hum then
        hum.Health = 0
    elseif oldCharacter then
        pcall(function()
            oldCharacter:BreakJoints()
        end)
    end

    -- Never wait through the revive countdown.
    task.defer(function()
        task.wait(0.05)
        instantFreeRespawn()
    end)

    -- Wait for a fresh character before allowing another route.
    local deadline = os.clock() + 12
    local newCharacter = nil

    repeat
        task.wait(0.15)
        newCharacter = LP.Character
    until not State.AutoWins
        or os.clock() >= deadline
        or (
            newCharacter
            and newCharacter ~= oldCharacter
            and newCharacter:FindFirstChild("HumanoidRootPart")
            and newCharacter:FindFirstChildOfClass("Humanoid")
            and newCharacter:FindFirstChildOfClass("Humanoid").Health > 0
        )

    if not State.AutoWins then
        return false
    end

    if newCharacter
        and newCharacter ~= oldCharacter
        and newCharacter:FindFirstChild("HumanoidRootPart")
    then
        local root = newCharacter.HumanoidRootPart

        if isSafePosition(root.Position) then
            lastSafeCFrame = root.CFrame
        end

        if State.AutoWins then
            cancelCharacterMovement()
            applyAutoWinsSpeed()

            -- Give Roblox a short spawn setup window, then clear movement
            -- one more time before the next worker run starts.
            task.wait(0.25)

            if State.AutoWins then
                cancelCharacterMovement()
                applyAutoWinsSpeed()
            end
        end

        return true
    end

    return false
end

local function waitForRunReset(timeout)
    timeout = timeout or 4
    local deadline = os.clock() + timeout

    while State.AutoWins and os.clock() < deadline do
        local stage =
            tonumber(LP:GetAttribute("CurrentRunStage"))

        if stage ~= nil and stage <= 1 then
            return true
        end

        task.wait(0.10)
    end

    return false
end


local function autoWinsRun()
    if not State.AutoWins then
        setNoclip(false)
        return
    end

    if not acquireMovement("AutoWins") then
        return
    end

    setNoclip(true)

    local shouldReset = false
    local resetReason = nil

    local ok, err = xpcall(function()
        local lastStage = getLastStage()

        if not lastStage then
            shouldReset = true
            resetReason = "final stage unavailable"
            return
        end

        local beforeWins = getWins()

        -- Resolve each stage sequentially and DO NOT continue to
        -- the next stage until the game confirms progression changed.
        -- This catches a missed gate immediately instead of discovering it
        -- only after reaching the final Return area.
        for stage = 1, lastStage do
            if not State.AutoWins then
                return
            end

            local position =
                waitForStagePosition(stage, 10)

            if not position then
                shouldReset = true
                resetReason = "stage " .. tostring(stage) .. " not streamed"
                return
            end

            local beforeProgress =
                tonumber(LP:GetAttribute("CurrentRunStage"))

            if not walkRoute({position}) then
                if State.AutoWins then
                    shouldReset = true
                    resetReason = "route stopped at stage " .. tostring(stage)
                end
                return
            end

            local progressed =
                waitForStageProgress(beforeProgress, 0.75)

            if not progressed then
                shouldReset = true
                resetReason =
                    "stage "
                    .. tostring(stage)
                    .. " did not register"
                return
            end
        end

        local single = WinPads:FindFirstChild("Single")
        local finalHolder =
            single
            and single:FindFirstChild(tostring(lastStage))

        local winButton =
            finalHolder
            and (
                finalHolder:FindFirstChild("Button", true)
                or finalHolder:FindFirstChild("Hitbox", true)
            )

        if not (winButton and winButton:IsA("BasePart")) then
            local deadline = os.clock() + 8

            repeat
                task.wait(0.15)

                single = WinPads:FindFirstChild("Single")
                finalHolder =
                    single
                    and single:FindFirstChild(tostring(lastStage))

                winButton =
                    finalHolder
                    and (
                        finalHolder:FindFirstChild("Button", true)
                        or finalHolder:FindFirstChild("Hitbox", true)
                    )

            until not State.AutoWins
                or os.clock() >= deadline
                or (winButton and winButton:IsA("BasePart"))
        end

        if not (winButton and winButton:IsA("BasePart")) then
            shouldReset = true
            resetReason = "final Wins pad unavailable"
            return
        end

        -- Physically cross the final Wins pad.
        local won = walkOntoPad(
            winButton,
            7,
            function()
                return getWins() > beforeWins
            end
        )

        if not won then
            -- One slower second attempt.
            won = walkOntoPad(
                winButton,
                5,
                function()
                    return getWins() > beforeWins
                end
            )
        end

        if not won then
            -- Most likely a missed earlier gate.
            shouldReset = true
            resetReason = "final Wins pad did not register (possible missed gate)"
            return
        end

        -- The win was successfully claimed.
        -- Do NOT use the Return pad anymore.
        --
        -- The game's Return teleport can preserve the previous Humanoid
        -- MoveTo target for a few frames. On the next run that stale target
        -- is what caused the character to curve sideways into another
        -- stage's Return pad.
        --
        -- A clean character reset guarantees:
        --   * fresh Humanoid
        --   * no old MoveTo destination
        --   * no old horizontal velocity
        --   * fresh spawn position
        --   * selected Auto Wins speed gets reapplied after respawn
        if State.AutoWins then
            shouldReset = true
            resetReason = "successful run - clean respawn"
        end
    end, debug.traceback)

    setNoclip(false)
    releaseMovement("AutoWins")

    if not ok then
        warn("[SERENITY][PHONK][AutoWins]\n" .. tostring(err))
        shouldReset = State.AutoWins
        resetReason = "runtime error"
    end

    if shouldReset and State.AutoWins then
        resetCharacterForAutoWins(resetReason)
    end
end

-- ============================================================
-- PROGRESSION
-- ============================================================

local function progressionPass()
    if State.AutoEvolve
        and LP:GetAttribute("CanEvolve") == true
    then
        RequestEvolve:FireServer()
        task.wait(0.35)
    end

    if State.AutoRebirth
        and LP:GetAttribute("CanRebirth") == true
    then
        RequestRebirth:FireServer()
        task.wait(0.35)
    end

    if State.AutoEquipBody and RequestEquipBodyTier then
        local body = tonumber(LP:GetAttribute("BodyTier")) or 0
        local equipped =
            tonumber(LP:GetAttribute("EquippedBodyTier")) or 0

        if body > 0 and body ~= equipped then
            RequestEquipBodyTier:FireServer(body)
            task.wait(0.15)
        end
    end

    if State.AutoEquipAura and RequestEquipItemTier then
        local best = highestOwnedAura()
        local equipped =
            tonumber(LP:GetAttribute("EquippedItemTier")) or 0

        if best > 0 and best ~= equipped then
            RequestEquipItemTier:FireServer(best)
            task.wait(0.15)
        end
    end
end

-- ============================================================
-- AURA / PHONK BUY
-- ============================================================

local function auraConfirmed(tier)
    return LP:GetAttribute("OwnedItemTier" .. tier) == true
        or tonumber(LP:GetAttribute("EquippedItemTier")) == tier
end

local function triggerAuraPad(button)
    local _, root = getChar()

    if not teleportTo(
        button.CFrame + Vector3.new(0, 8, 0)
    ) then
        return false
    end

    if not teleportTo(
        button.CFrame + Vector3.new(0, 1.8, 0)
    ) then
        return false
    end

    if typeof(firetouchinterest) == "function" then
        pcall(firetouchinterest, root, button, 0)
        task.wait(0.06)
        pcall(firetouchinterest, root, button, 1)
    end

    return true
end

local function buyAuraPass()
    if not State.AutoBuyAura then
        return
    end

    if not acquireMovement("Aura") then
        return
    end

    local ok, err = xpcall(function()
        for tier = highestOwnedAura() + 1, #ItemConfig.orderedItemNames do
            if not State.AutoBuyAura then
                return
            end

            local name = ItemConfig.orderedItemNames[tier]
            local def = ItemConfig.definitionsByName[name]

            if not def or def.robuxOnly == true then
                return
            end

            local cost = tonumber(def.winCost) or 0
            if cost > getWins() then
                return
            end

            local holder = ItemPads:FindFirstChild(tostring(tier))
            local button = holder and holder:FindFirstChild("Button")

            if not (button and button:IsA("BasePart")) then
                return
            end

            local success = auraConfirmed(tier)

            for _ = 1, math.max(1, State.AuraRetries) do
                if success or not State.AutoBuyAura then
                    break
                end

                triggerAuraPad(button)

                local deadline = os.clock() + 5
                while State.AutoBuyAura and os.clock() < deadline do
                    if auraConfirmed(tier) then
                        success = true
                        break
                    end
                    task.wait(0.10)
                end
            end

            if not success then
                return
            end

            task.wait(0.35)
        end
    end, debug.traceback)

    releaseMovement("Aura")

    if not ok then
        warn("[SERENITY][PHONK][Aura]\n" .. tostring(err))
    end
end

-- ============================================================
-- TREADMILL
-- ============================================================

local function bestTreadmill()
    local folder = Workspace:FindFirstChild("Treadmills")
    if not folder then
        return nil
    end

    local rebirths = tonumber(LP:GetAttribute("Rebirths")) or 0
    local bestModel, bestDef = nil, nil

    for _, model in ipairs(folder:GetChildren()) do
        if model:IsA("Model") then
            local id = model:GetAttribute("CashPadId")
            local def = id and CashPadConfig.Pads[id] or nil

            if def then
                local gp = tonumber(def.GamepassId) or 0
                local req = tonumber(def.RequiredRebirths) or 0

                if gp <= 0 and req <= rebirths then
                    if not bestDef
                        or def.Multiplier > bestDef.Multiplier
                    then
                        bestModel = model
                        bestDef = def
                    end
                end
            end
        end
    end

    return bestModel
end

local function treadmillPass()
    if not State.AutoTreadmill then
        return
    end

    if not acquireMovement("Treadmill") then
        return
    end

    local ok, err = xpcall(function()
        local model = bestTreadmill()
        local hitbox = model and model:FindFirstChild("Hitbox")

        if not (hitbox and hitbox:IsA("BasePart")) then
            return
        end

        if not teleportToPart(hitbox, 1) then
            return
        end

        local deadline = os.clock() + State.TreadmillSeconds

        while State.AutoTreadmill
            and os.clock() < deadline
        do
            task.wait(0.10)
        end
    end, debug.traceback)

    releaseMovement("Treadmill")

    if not ok then
        warn("[SERENITY][PHONK][Treadmill]\n" .. tostring(err))
    end
end

-- ============================================================
-- SAFE EGG PROXIMITY + AUTO HATCH
-- ============================================================

local function safeEggPosition(stand)
    if not stand or not stand:IsA("Model") then
        return nil
    end

    local pivot = stand:GetPivot().Position
    local char = LP.Character

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = char and {char} or {}
    params.IgnoreWater = false

    local offsets = {
        Vector3.new(0, 0, 0),
        Vector3.new(3, 0, 0),
        Vector3.new(-3, 0, 0),
        Vector3.new(0, 0, 3),
        Vector3.new(0, 0, -3),
        Vector3.new(6, 0, 0),
        Vector3.new(-6, 0, 0),
        Vector3.new(0, 0, 6),
        Vector3.new(0, 0, -6),
    }

    local best, bestDist = nil, math.huge

    for _, offset in ipairs(offsets) do
        local sample = pivot + offset
        local result = Workspace:Raycast(
            sample + Vector3.new(0, 80, 0),
            Vector3.new(0, -180, 0),
            params
        )

        if result and result.Instance
            and result.Instance:IsA("BasePart")
        then
            local candidate =
                result.Position + Vector3.new(0, 3.25, 0)

            local dist = (candidate - pivot).Magnitude

            if isSafePosition(candidate)
                and dist <= 15
                and dist < bestDist
            then
                best = candidate
                bestDist = dist
            end
        end
    end

    return best
end

local lastHatch = 0

local function equipBestPet()
    if not State.AutoEquipPet then
        return
    end

    pcall(
        PetRequest.InvokeServer,
        PetRequest,
        "EquipBest",
        nil
    )
end

local function hatchPass()
    if not State.AutoHatch then
        equipBestPet()
        return
    end

    if os.clock() - lastHatch < State.HatchDelay then
        equipBestPet()
        return
    end

    if not acquireMovement("Hatch") then
        return
    end

    local okRun, err = xpcall(function()
        local petCount = tonumber(LP:GetAttribute("PetCount")) or 0
        local maxStorage =
            tonumber(LP:GetAttribute("MaxPetStorage"))
            or PetConfig.MaxStorage
            or 100

        if petCount >= maxStorage then
            return
        end

        local usableWins = math.max(
            0,
            getWins() - State.EggReserve
        )

        local bestEgg = nil

        for _, egg in ipairs(PetConfig.Eggs) do
            if egg.Currency == "Wins"
                and type(egg.Price) == "number"
                and egg.Price <= usableWins
            then
                if not bestEgg or egg.Price > bestEgg.Price then
                    bestEgg = egg
                end
            end
        end

        if not bestEgg then
            return
        end

        local stand = Workspace:FindFirstChild(bestEgg.StandName)

        if not (stand and stand:IsA("Model")) then
            return
        end

        for _ = 1, 5 do
            if not State.AutoHatch then
                return
            end

            local target = safeEggPosition(stand)

            if not target then
                task.wait(0.20)
                continue
            end

            if not teleportTo(CFrame.new(target)) then
                task.wait(0.20)
                continue
            end

            local _, root = getChar()
            local distance =
                (root.Position - stand:GetPivot().Position).Magnitude

            if distance > PetConfig.ProximityDistance then
                task.wait(0.20)
                continue
            end

            local ok, response = pcall(
                PetRequest.InvokeServer,
                PetRequest,
                "Hatch",
                {
                    EggId = bestEgg.Id,
                    Count = 1,
                    Auto = false,
                }
            )

            if ok
                and typeof(response) == "table"
                and response.Status == "Hatched"
            then
                lastHatch = os.clock()

                print(
                    "[SERENITY][Hatch] SUCCESS",
                    bestEgg.Id,
                    ("distance=%.2f"):format(distance)
                )
                break
            end

            task.wait(0.25)
        end
    end, debug.traceback)

    releaseMovement("Hatch")
    equipBestPet()

    if not okRun then
        warn("[SERENITY][PHONK][Hatch]\n" .. tostring(err))
    end
end

-- ============================================================
-- TRAILS
-- ============================================================

local function trailPass()
    if not State.AutoBuyTrail
        and not State.AutoEquipTrail
    then
        return
    end

    local ok, state = pcall(
        GetDailyState.InvokeServer,
        GetDailyState
    )

    if not ok or typeof(state) ~= "table" then
        return
    end

    local owned = state.OwnedTrails or {}
    local bestOwned = nil
    local bestBuy = nil

    for _, def in ipairs(TrailConfig.Definitions) do
        if owned[def.Name] == true then
            if not bestOwned
                or def.WinMultiplier > bestOwned.WinMultiplier
            then
                bestOwned = def
            end
        elseif State.AutoBuyTrail
            and not def.DailyOnly
            and type(def.WinsCost) == "number"
            and def.WinsCost <= getWins()
        then
            if not bestBuy
                or def.WinMultiplier > bestBuy.WinMultiplier
            then
                bestBuy = def
            end
        end
    end

    if State.AutoBuyTrail and bestBuy then
        RequestTrailAction:FireServer(bestBuy.Name, "Wins")
        task.wait(0.30)

        local ok2, newState = pcall(
            GetDailyState.InvokeServer,
            GetDailyState
        )

        if ok2 and typeof(newState) == "table" then
            state = newState
            owned = state.OwnedTrails or owned

            if owned[bestBuy.Name] == true then
                if not bestOwned
                    or bestBuy.WinMultiplier > bestOwned.WinMultiplier
                then
                    bestOwned = bestBuy
                end
            end
        end
    end

    if State.AutoEquipTrail
        and bestOwned
        and state.EquippedTrail ~= bestOwned.Name
    then
        RequestTrailAction:FireServer(
            bestOwned.Name,
            "Equip"
        )
    end
end

-- ============================================================
-- REWARDS
-- ============================================================

local lastRewardCheck = 0

local function rewardPass()
    if not State.AutoDaily
        and not State.AutoOffline
        and not State.AutoGroup
    then
        return
    end

    if os.clock() - lastRewardCheck < 20 then
        return
    end

    lastRewardCheck = os.clock()

    if State.AutoDaily then
        RequestDailyReward:FireServer()
        task.wait(0.15)
    end

    if State.AutoOffline then
        local ok, offer = pcall(
            OfflineGetOffer.InvokeServer,
            OfflineGetOffer
        )

        if ok
            and typeof(offer) == "table"
            and tonumber(offer.Aura)
            and offer.Aura > 0
        then
            pcall(
                OfflineClaim.InvokeServer,
                OfflineClaim
            )
        end
    end

    if State.AutoGroup
        and RequestGroupReward
        and LP:GetAttribute("ClaimedGroupReward") ~= true
    then
        local playtime =
            tonumber(LP:GetAttribute("PlaytimeSeconds")) or 0

        local required =
            tonumber(GroupRewardConfig.PlaytimeRequirementSeconds)
            or 0

        if playtime >= required then
            local ok, member = pcall(
                LP.IsInGroupAsync,
                LP,
                GroupRewardConfig.GroupId
            )

            if ok and member then
                RequestGroupReward:FireServer(false)
            end
        end
    end
end

-- ============================================================
-- INDEPENDENT FEATURE WORKERS
-- One feature failing can no longer kill every other feature.
-- ============================================================

local function protectedWorker(name, enabled, action, idleDelay, activeDelay)
    task.spawn(function()
        while State.Alive do
            if not enabled() then
                task.wait(idleDelay or 0.08)
                continue
            end

            local ok, err = xpcall(action, debug.traceback)

            if not ok then
                warn(
                    ("[SERENITY][PHONK][%s]\n%s")
                        :format(name, tostring(err))
                )
                task.wait(0.50)
            else
                task.wait(activeDelay or State.CycleDelay)
            end
        end
    end)
end

protectedWorker(
    "AutoWins",
    function()
        return State.AutoWins
    end,
    autoWinsRun,
    0.05,
    1.00
)

protectedWorker(
    "Progression",
    function()
        return State.AutoEvolve
            or State.AutoRebirth
            or State.AutoEquipBody
            or State.AutoEquipAura
    end,
    progressionPass,
    0.08,
    0.20
)

protectedWorker(
    "Aura",
    function()
        return State.AutoBuyAura
    end,
    buyAuraPass,
    0.08,
    0.25
)

protectedWorker(
    "Treadmill",
    function()
        return State.AutoTreadmill
    end,
    treadmillPass,
    0.08,
    0.20
)

protectedWorker(
    "Hatch",
    function()
        return State.AutoHatch or State.AutoEquipPet
    end,
    hatchPass,
    0.08,
    0.20
)

protectedWorker(
    "Trails",
    function()
        return State.AutoBuyTrail or State.AutoEquipTrail
    end,
    trailPass,
    0.08,
    0.35
)

protectedWorker(
    "Rewards",
    function()
        return State.AutoDaily
            or State.AutoOffline
            or State.AutoGroup
    end,
    rewardPass,
    0.15,
    1.0
)

-- ============================================================
-- PERFORMANCE / VERY POTATO MODE
-- Reversible while the script is running.
-- ============================================================

local potatoOriginals = {}
local potatoDescendantConnection = nil
local originalQualityLevel = nil

local function cacheProperty(instance, property)
    potatoOriginals[instance] = potatoOriginals[instance] or {}

    if potatoOriginals[instance][property] ~= nil then
        return
    end

    local ok, value = pcall(function()
        return instance[property]
    end)

    if ok then
        potatoOriginals[instance][property] = value
    end
end

local function potatoSet(instance, property, value)
    cacheProperty(instance, property)

    pcall(function()
        instance[property] = value
    end)
end

local function applyPotatoObject(obj)
    if obj:IsA("BasePart") then
        potatoSet(obj, "CastShadow", false)
        potatoSet(obj, "Reflectance", 0)

        pcall(function()
            potatoSet(obj, "Material", Enum.Material.SmoothPlastic)
        end)

        if obj:IsA("MeshPart") then
            pcall(function()
                potatoSet(
                    obj,
                    "RenderFidelity",
                    Enum.RenderFidelity.Performance
                )
            end)
        end

    elseif obj:IsA("Decal") or obj:IsA("Texture") then
        potatoSet(obj, "Transparency", 1)

    elseif obj:IsA("ParticleEmitter")
        or obj:IsA("Trail")
        or obj:IsA("Beam")
        or obj:IsA("Smoke")
        or obj:IsA("Fire")
        or obj:IsA("Sparkles")
    then
        potatoSet(obj, "Enabled", false)

    elseif obj:IsA("PointLight")
        or obj:IsA("SpotLight")
        or obj:IsA("SurfaceLight")
    then
        potatoSet(obj, "Enabled", false)

    elseif obj:IsA("BloomEffect")
        or obj:IsA("BlurEffect")
        or obj:IsA("ColorCorrectionEffect")
        or obj:IsA("DepthOfFieldEffect")
        or obj:IsA("SunRaysEffect")
    then
        potatoSet(obj, "Enabled", false)

    elseif obj:IsA("SpecialMesh") then
        pcall(function()
            potatoSet(obj, "TextureId", "")
        end)
    end
end

local function enableVeryPotato()
    if State.VeryPotatoMode then
        -- State is already set by UI before callback.
    end

    potatoSet(Lighting, "GlobalShadows", false)
    potatoSet(Lighting, "EnvironmentDiffuseScale", 0)
    potatoSet(Lighting, "EnvironmentSpecularScale", 0)
    potatoSet(Lighting, "ShadowSoftness", 0)

    local terrain = Workspace:FindFirstChildOfClass("Terrain")

    if terrain then
        potatoSet(terrain, "WaterWaveSize", 0)
        potatoSet(terrain, "WaterWaveSpeed", 0)
        potatoSet(terrain, "WaterReflectance", 0)
        potatoSet(terrain, "WaterTransparency", 1)

        pcall(function()
            potatoSet(terrain, "Decoration", false)
        end)
    end

    for _, obj in ipairs(Workspace:GetDescendants()) do
        applyPotatoObject(obj)
    end

    for _, obj in ipairs(Lighting:GetChildren()) do
        applyPotatoObject(obj)
    end

    if not potatoDescendantConnection then
        potatoDescendantConnection =
            Workspace.DescendantAdded:Connect(function(obj)
                if State.VeryPotatoMode then
                    task.defer(function()
                        if obj.Parent and State.VeryPotatoMode then
                            applyPotatoObject(obj)
                        end
                    end)
                end
            end)
    end

    pcall(function()
        local rendering = settings().Rendering

        if originalQualityLevel == nil then
            originalQualityLevel = rendering.QualityLevel
        end

        rendering.QualityLevel = Enum.QualityLevel.Level01
    end)

    print("[SERENITY][PERFORMANCE] Very Potato Mode ON")
end

local function disableVeryPotato()
    if potatoDescendantConnection then
        potatoDescendantConnection:Disconnect()
        potatoDescendantConnection = nil
    end

    for instance, properties in pairs(potatoOriginals) do
        if instance then
            for property, value in pairs(properties) do
                pcall(function()
                    instance[property] = value
                end)
            end
        end
    end

    table.clear(potatoOriginals)

    if originalQualityLevel ~= nil then
        pcall(function()
            settings().Rendering.QualityLevel = originalQualityLevel
        end)

        originalQualityLevel = nil
    end

    print("[SERENITY][PERFORMANCE] Very Potato Mode OFF")
end

local function setVeryPotato(enabled)
    State.VeryPotatoMode = enabled == true

    if State.VeryPotatoMode then
        enableVeryPotato()
    else
        disableVeryPotato()
    end
end

local function set3DDisabled(disabled)
    State.Disable3D = disabled == true

    pcall(function()
        RunService:Set3dRenderingEnabled(not State.Disable3D)
    end)

    print(
        "[SERENITY][PERFORMANCE] 3D Rendering",
        State.Disable3D and "OFF" or "ON"
    )
end

-- ============================================================
-- OFFICIAL SERENITY V3 UI MANIFEST
-- ============================================================

local Manifest = {
    SerenityAPIVersion = 3,
    ConfigVersion = 1,
    RuntimeKey = "__SERENITY_PHONK_EVOLUTION_V3",
    GameName = "+1 Phonk Evolution",
    DesktopWidth = 920,
    DesktopHeight = 570,

    Pages = {
        {
            Id = "Dashboard",
            Title = "Dashboard",
            Description = "Serenity Hub automation for +1 Phonk Evolution.",
            Features = {
                {
                    Id = "Overview",
                    Title = "Automation",
                    Description = "Final Serenity Hub automation status.",
                    Accent = "purple",
                    Controls = {
                        {
                            Type = "Paragraph",
                            Title = "Status",
                            Text = "Official Serenity Hub V3 UI. Every automation switch starts OFF. There is no master Start button: enabling a switch immediately activates that feature.",
                        },
                        {
                            Type = "Paragraph",
                            Title = "Movement",
                            Text = "Auto Wins defaults to 500 speed and uses the validated MoveTo route. After every successful win it performs a clean respawn. Serenity permanently hides the revive countdown and immediately uses the game's free Respawn action, so there is no 5-second wait. Disabling Auto Wins restores the exact WalkSpeed you had before enabling it.",
                        },
                    },
                },
            },
        },

        {
            Id = "Automation",
            Title = "Automation",
            Description = "Main farming and progression automation.",
            Features = {
                {
                    Id = "Farm",
                    Title = "Farm",
                    Description = "Primary farming features.",
                    Accent = "cyan",
                    Controls = {
                        {
                            Type = "Switch",
                            Id = "AutoClick",
                            Title = "Auto Click",
                            Description = "Continuously earn Aura.",
                            Default = false,
                            Changed = function(v)
                                setBool("AutoClick", v)
                            end,
                        },
                        {
                            Type = "Switch",
                            Id = "AutoWins",
                            Title = "Auto Wins",
                            Description = "Walk every configured stage and claim Wins. After success, respawn cleanly and start the next run from the beginning.",
                            Default = false,
                            Changed = function(v)
                                if v then
                                    captureAutoWinsOriginalSpeed()
                                    setBool("AutoWins", true)
                                    cancelCharacterMovement()
                                    applyAutoWinsSpeed()
                                else
                                    setBool("AutoWins", false)
                                    setNoclip(false)
                                    cancelCharacterMovement()
                                    restoreAutoWinsOriginalSpeed()
                                end
                            end,
                        },
                        {
                            Type = "Switch",
                            Id = "AutoTreadmill",
                            Title = "Auto Treadmill",
                            Description = "Teleport to the best unlocked free treadmill.",
                            Default = false,
                            Changed = function(v)
                                setBool("AutoTreadmill", v)
                            end,
                        },
                    },
                },

                {
                    Id = "Progression",
                    Title = "Progression",
                    Description = "Automatic progression actions.",
                    Accent = "green",
                    Controls = {
                        {
                            Type = "Switch",
                            Id = "AutoEvolve",
                            Title = "Auto Evolve",
                            Description = "Evolve whenever CanEvolve is ready.",
                            Default = false,
                            Changed = function(v)
                                setBool("AutoEvolve", v)
                            end,
                        },
                        {
                            Type = "Switch",
                            Id = "AutoRebirth",
                            Title = "Auto Rebirth",
                            Description = "Rebirth whenever CanRebirth is ready.",
                            Default = false,
                            Changed = function(v)
                                setBool("AutoRebirth", v)
                            end,
                        },
                        {
                            Type = "Switch",
                            Id = "EquipBody",
                            Title = "Equip Best Body",
                            Description = "Equip the latest unlocked evolution body.",
                            Default = false,
                            Changed = function(v)
                                setBool("AutoEquipBody", v)
                            end,
                        },
                        {
                            Type = "Switch",
                            Id = "EquipAura",
                            Title = "Equip Best Aura",
                            Description = "Equip the highest owned Phonk/Aura tier.",
                            Default = false,
                            Changed = function(v)
                                setBool("AutoEquipAura", v)
                            end,
                        },
                        {
                            Type = "Switch",
                            Id = "BuyAura",
                            Title = "Auto Buy Aura / Phonk",
                            Description = "Sequentially teleport to affordable Wins pads; stops before Robux-only tiers.",
                            Default = false,
                            Changed = function(v)
                                setBool("AutoBuyAura", v)
                            end,
                        },
                    },
                },
            },
        },

        {
            Id = "PetsTrails",
            Title = "Pets & Trails",
            Description = "Pet hatching, pet equip and trails.",
            Features = {
                {
                    Id = "Pets",
                    Title = "Pets",
                    Description = "Wins egg automation.",
                    Accent = "purple",
                    Controls = {
                        {
                            Type = "Switch",
                            Id = "AutoHatch",
                            Title = "Auto Hatch",
                            Description = "Teleport within the egg proximity zone and hatch the best affordable Wins egg.",
                            Default = false,
                            Changed = function(v)
                                setBool("AutoHatch", v)
                            end,
                        },
                        {
                            Type = "Switch",
                            Id = "EquipPet",
                            Title = "Equip Best Pet",
                            Description = "Use the game's normal EquipBest action.",
                            Default = false,
                            Changed = function(v)
                                setBool("AutoEquipPet", v)
                            end,
                        },
                        {
                            Type = "Slider",
                            Id = "HatchDelay",
                            Title = "Hatch Delay",
                            Description = "Delay between successful hatches.",
                            Min = 1,
                            Max = 15,
                            Default = 3,
                            Suffix = "s",
                            Changed = function(v)
                                setNumber("HatchDelay", v, 3)
                            end,
                        },
                        {
                            Type = "Slider",
                            Id = "EggReserve",
                            Title = "Wins Reserve",
                            Description = "Wins to keep instead of spending on eggs.",
                            Min = 0,
                            Max = 1000000000,
                            Default = 0,
                            Suffix = "",
                            Changed = function(v)
                                setNumber("EggReserve", v, 0)
                            end,
                        },
                    },
                },

                {
                    Id = "Trails",
                    Title = "Trails",
                    Description = "Wins multiplier trails.",
                    Accent = "yellow",
                    Controls = {
                        {
                            Type = "Switch",
                            Id = "BuyTrail",
                            Title = "Auto Buy Trail",
                            Description = "Buy the best affordable normal Wins trail.",
                            Default = false,
                            Changed = function(v)
                                setBool("AutoBuyTrail", v)
                            end,
                        },
                        {
                            Type = "Switch",
                            Id = "EquipTrail",
                            Title = "Equip Best Trail",
                            Description = "Equip the highest multiplier owned trail.",
                            Default = false,
                            Changed = function(v)
                                setBool("AutoEquipTrail", v)
                            end,
                        },
                    },
                },
            },
        },

        {
            Id = "Rewards",
            Title = "Rewards",
            Description = "Free server-validated rewards.",
            Features = {
                {
                    Id = "Claims",
                    Title = "Claims",
                    Description = "Automatic reward claiming.",
                    Accent = "green",
                    Controls = {
                        {
                            Type = "Switch",
                            Id = "Daily",
                            Title = "Daily Reward",
                            Description = "Claim when the server says the daily reward is ready.",
                            Default = false,
                            Changed = function(v)
                                setBool("AutoDaily", v)
                            end,
                        },
                        {
                            Type = "Switch",
                            Id = "Offline",
                            Title = "Offline Reward",
                            Description = "Claim the normal free offline Aura offer.",
                            Default = false,
                            Changed = function(v)
                                setBool("AutoOffline", v)
                            end,
                        },
                        {
                            Type = "Switch",
                            Id = "Group",
                            Title = "Group Reward",
                            Description = "Claim only if already a valid group member and playtime requirement is met.",
                            Default = false,
                            Changed = function(v)
                                setBool("AutoGroup", v)
                            end,
                        },
                    },
                },
            },
        },

        {
            Id = "Performance",
            Title = "Performance",
            Description = "Aggressive client-side FPS and GPU optimizations.",
            Features = {
                {
                    Id = "Potato",
                    Title = "FPS Improver",
                    Description = "Maximum visual reduction for lower CPU/GPU usage.",
                    Accent = "green",
                    Controls = {
                        {
                            Type = "Switch",
                            Id = "VeryPotato",
                            Title = "Very Potato Mode",
                            Description = "Disables particles, trails, beams, lights, shadows, textures, post effects, water effects and forces lowest render quality. Reversible when disabled.",
                            Default = false,
                            Changed = function(v)
                                setVeryPotato(v)
                            end,
                        },
                        {
                            Type = "Switch",
                            Id = "Disable3D",
                            Title = "Disable 3D Rendering",
                            Description = "Maximum GPU reduction. The game simulation and Serenity automation continue while the 3D world is not rendered.",
                            Default = false,
                            Changed = function(v)
                                set3DDisabled(v)
                            end,
                        },
                        {
                            Type = "Paragraph",
                            Title = "Anti-Ragdoll",
                            Text = "Built in permanently: Serenity suppresses FallingDown/Ragdoll/Physics during local teleports and automatically gets the character back up.",
                        },
                    },
                },
            },
        },

        {
            Id = "Settings",
            Title = "Settings",
            Description = "Automation timing and movement settings.",
            Features = {
                {
                    Id = "Movement",
                    Title = "Auto Wins Movement",
                    Description = "Forward-only high-speed route settings.",
                    Accent = "cyan",
                    Controls = {
                        {
                            Type = "Slider",
                            Id = "WalkSpeed",
                            Title = "Walk Speed",
                            Description = "Auto Wins movement speed.",
                            Min = 16,
                            Max = 500,
                            Default = 500,
                            Suffix = "",
                            Changed = function(v)
                                setNumber("WalkSpeed", v, 500)

                                if State.AutoWins then
                                    applyAutoWinsSpeed()
                                end
                            end,
                        },
                        {
                            Type = "Slider",
                            Id = "ReachDistance",
                            Title = "Reach Distance",
                            Description = "Distance used to mark each route waypoint reached.",
                            Min = 2,
                            Max = 20,
                            Default = 8,
                            Suffix = " studs",
                            Changed = function(v)
                                setNumber("ReachDistance", v, 8)
                            end,
                        },
                    },
                },

                {
                    Id = "Timing",
                    Title = "Timing",
                    Description = "Automation timing.",
                    Accent = "purple",
                    Controls = {
                        {
                            Type = "Slider",
                            Id = "ClickDelay",
                            Title = "Click Delay",
                            Description = "Delay between Auto Click calls.",
                            Min = 0.03,
                            Max = 1,
                            Default = 0.10,
                            Suffix = "s",
                            Changed = function(v)
                                setNumber("ClickDelay", v, 0.10)
                            end,
                        },
                        {
                            Type = "Slider",
                            Id = "TreadmillSeconds",
                            Title = "Treadmill Duration",
                            Description = "Seconds spent on the treadmill per cycle.",
                            Min = 1,
                            Max = 10,
                            Default = 3,
                            Suffix = "s",
                            Changed = function(v)
                                setNumber("TreadmillSeconds", v, 3)
                            end,
                        },
                        {
                            Type = "Slider",
                            Id = "AuraRetries",
                            Title = "Aura Pad Retries",
                            Description = "Retries for delayed Aura/Phonk pad registration.",
                            Min = 1,
                            Max = 8,
                            Default = 4,
                            Suffix = "",
                            Changed = function(v)
                                setNumber("AuraRetries", v, 4)
                            end,
                        },
                    },
                },
            },
        },
    },
}

-- ============================================================
-- FINAL SERENITY HUB V3 BUILD
-- ============================================================

-- Keep every automation control OFF at launch.
local sessionConfigPath =
    "SerenityConcept02/phonk-unused-session.json"

if type(isfile) == "function"
    and type(delfile) == "function"
then
    pcall(function()
        if isfile(sessionConfigPath) then
            delfile(sessionConfigPath)
        end
    end)
end

-- Silence Serenity's own startup architecture messages only while building.
local originalGlobalPrint = env.print
local originalGlobalWarn = env.warn

env.print = silent
env.warn = silent

local buildOk, buildResult = pcall(function()
    local SerenitySource = game:HttpGet(
        "https://raw.githubusercontent.com/MUshihara/SerenityNewUi/7965c5e110b6ba6ca9ece69f74cecba4caab5d0d/prototype/dist/SerenityPhonkUI.lua"
            .. "?phonk-final="
            .. tostring(os.time())
    )

    local Serenity = loadstring(
        SerenitySource,
        "@Serenity/dist/ui/serenity-v3.lua"
    )()

    return Serenity.Build(
        Manifest,
        {
            RuntimeKey = "__SERENITY_PHONK_EVOLUTION_V3",
            ConfigPath = sessionConfigPath,
        }
    )
end)

env.print = originalGlobalPrint
env.warn = originalGlobalWarn

if not buildOk then
    error(buildResult, 0)
end

local App = buildResult

App.Runtime:TrackCleanup(function()
    if State.VeryPotatoMode then
        State.VeryPotatoMode = false
        disableVeryPotato()
    end

    set3DDisabled(false)
    clearAntiRagdollConnections()

    cancelCharacterMovement()
    restoreAutoWinsOriginalSpeed()
    State.Alive = false

    for key, value in pairs(State) do
        if type(value) == "boolean" then
            State[key] = false
        end
    end

    setNoclip(false)
    movementOwner = nil
end)

env.SerenityPhonk = {
    App = App,
    State = State,

    Stop = function()
        State.AutoClick = false
        State.AutoWins = false
        State.AutoTreadmill = false
        State.AutoEvolve = false
        State.AutoRebirth = false
        State.AutoEquipBody = false
        State.AutoEquipAura = false
        State.AutoBuyAura = false
        State.AutoHatch = false
        State.AutoEquipPet = false
        State.AutoBuyTrail = false
        State.AutoEquipTrail = false
        State.AutoDaily = false
        State.AutoOffline = false
        State.AutoGroup = false

        if State.VeryPotatoMode then
            State.VeryPotatoMode = false
            disableVeryPotato()
        end

        set3DDisabled(false)
        setNoclip(false)
        cancelCharacterMovement()
        restoreAutoWinsOriginalSpeed()
    end,

    Destroy = function()
        App:Destroy()
    end,
}
