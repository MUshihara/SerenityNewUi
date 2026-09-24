-- PHONK ONLY. Run official Serenity first, then this manual integration test.
if game.PlaceId~=104809044319701 and game.GameId~=10544327471 then
    warn('[Serenity test] This test only runs in +1 Phonk Evolution.');return
end
local env=(getgenv and getgenv()) or _G
env.__SERENITY_COMMUNITY_LOAD=(env.__SERENITY_COMMUNITY_LOAD or 0)+1
local generation=env.__SERENITY_COMMUNITY_LOAD
local prior=env.__SERENITY_PHONK_COMMUNITY_TEST
if prior and prior.Stop then prior:Stop() end
local BASE='https://raw.githubusercontent.com/MUshihara/SerenityNewUi/main/tests/phonk-community-v2/'
local function get(name)
    local source=game:HttpGet(BASE..name..'?test='..os.time(),true)
    if generation~=env.__SERENITY_COMMUNITY_LOAD then return nil end
    local fn,err=loadstring(source,'@SerenityCommunityV2/'..name)
    if not fn then error(err)end
    return fn()
end
local ok,result=pcall(function()
    local core=get('core.lua');if not core then return end
    local bridge=get('bridge.lua');if not bridge then return end
    local start=get('client.lua');if not start then return end
    return start(core,bridge)
end)
if not ok then
    if generation==env.__SERENITY_COMMUNITY_LOAD then
        local current=env.__SERENITY_PHONK_COMMUNITY_TEST
        if current and current.Stop then current:Stop()end
    end
    warn('[Serenity test] '..tostring(result))
end
return ok and result or nil
