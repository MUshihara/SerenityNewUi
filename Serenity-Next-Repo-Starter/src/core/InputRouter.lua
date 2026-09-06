local UserInputService = game:GetService("UserInputService")

local InputRouter = {}
InputRouter.__index = InputRouter

function InputRouter.new(runtime)
    local self = setmetatable({}, InputRouter)
    self.Runtime = runtime
    self.Shortcuts = {}

    runtime:TrackConnection(UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end

        for _, shortcut in ipairs(self.Shortcuts) do
            if shortcut.Match(input, UserInputService) then
                shortcut.Callback()
                break
            end
        end
    end))

    return self
end

function InputRouter:AddShortcut(match, callback)
    table.insert(self.Shortcuts, {
        Match = match,
        Callback = callback,
    })
end

return InputRouter
