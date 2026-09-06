local Icons = {}

-- Final build should map semantic names to actual Serenity/Lucide assets.
-- Do NOT use Unicode glyphs as a permanent icon system.

Icons.Map = {
    home = nil,
    automation = nil,
    progression = nil,
    shops = nil,
    configs = nil,
    settings = nil,
    search = nil,
    chevron_right = nil,
    chevron_down = nil,
    check = nil,
    lock = nil,
    warning = nil,
    error = nil,
    info = nil,
}

function Icons.Get(name)
    return Icons.Map[name]
end

return Icons
