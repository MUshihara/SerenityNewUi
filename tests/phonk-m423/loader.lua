-- Manual Phonk-only M4.23 test; no changes to the official loader.
if game.PlaceId~=104809044319701 then
    warn("[Serenity] M4.23 test only supports +1 Phonk Evolution.")
    return
end
local env=(getgenv and getgenv()) or _G
if env.__SERENITY_PHONK_M423_LOADING then return end
env.__SERENITY_PHONK_M423_LOADING=true
local ok,result=pcall(function()
    local source=game:HttpGet("https://raw.githubusercontent.com/MUshihara/SerenityNewUi/fc04c5eb78736ab3853d9fd6a9aa5e1d3be8ab4f/tests/phonk-m423/game.luau")
    local run,err=loadstring(source,"@Serenity/PhonkM423Test")
    assert(run,err)
    return run()
end)
env.__SERENITY_PHONK_M423_LOADING=nil
if not ok then
    local runtime=env.__SERENITY_PHONK_M423_TEST
    if runtime then runtime:Destroy() end
    error("[Serenity Phonk test] "..tostring(result),0)
end
return result
