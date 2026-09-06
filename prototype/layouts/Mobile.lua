-- Dedicated mobile geometry, informed by Serenity V14's 650x420 shell.
return function(view)
    local portrait=view.Y>view.X
    return {
        Width=portrait and math.min(420,view.X-24) or 650,
        Height=portrait and math.min(600,view.Y-24) or 420,
        Sidebar=portrait and 68 or 144,
        Header=52, Rail=portrait, Mobile=true,
    }
end
