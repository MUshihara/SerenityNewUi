local Search = {}
Search.__index = Search

function Search.new()
    return setmetatable({
        Entries = {},
    }, Search)
end

function Search:Register(entry)
    entry.Search = string.lower(table.concat({
        entry.Title or "",
        entry.Path or "",
        entry.Keywords or "",
    }, " "))

    table.insert(self.Entries, entry)
end

function Search:Query(text, currentPage)
    text = string.lower(text or "")
    local result = {}

    for _, entry in ipairs(self.Entries) do
        if text == "" or string.find(entry.Search, text, 1, true) then
            table.insert(result, entry)
        end
    end

    table.sort(result, function(a, b)
        if a.Page == currentPage and b.Page ~= currentPage then
            return true
        elseif b.Page == currentPage and a.Page ~= currentPage then
            return false
        end
        return (a.Title or "") < (b.Title or "")
    end)

    return result
end

return Search
