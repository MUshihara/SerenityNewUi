-- Manual Ride a Pet M4.23 test; production is unchanged.
if game.PlaceId~=124216119978534 or game.GameId~=10035204815 then
    warn("[Serenity test] Open Ride a Pet first.")
    return
end
local env=(getgenv and getgenv()) or _G
if env.__SERENITY_RAP_M423_LOADING then return end
env.__SERENITY_RAP_M423_LOADING=true
local ok,result=pcall(function()
    local source=game:HttpGet("https://raw.githubusercontent.com/MUshihara/SerenityNewUi/6869dddd445d8bf67451935eadad84392e2d4535/tests/rideapet-m423/game.luau",true)
    local run,err=loadstring(source,"@Serenity/RideAPetM423Test")
    assert(run,err)
    return run()
end)
env.__SERENITY_RAP_M423_LOADING=nil
if not ok then error("[Serenity test] "..tostring(result),0) end
return result
