local SegmentedTabs = {}
SegmentedTabs.__index = SegmentedTabs

function SegmentedTabs.new(parent, deps, props)
    local tokens = deps.Tokens
    props = props or {}

    local root = Instance.new("Frame")
    root.BackgroundTransparency = 1
    root.Size = UDim2.new(1, 0, 0, tokens.Size.SegmentTabs)
    root.Parent = parent

    local holder = Instance.new("Frame")
    holder.BackgroundColor3 = tokens.Color.Inset
    holder.BackgroundTransparency = 0.38
    holder.BorderSizePixel = 0
    holder.Size = UDim2.new(0, 0, 1, 0)
    holder.AutomaticSize = Enum.AutomaticSize.X
    holder.Parent = root
    local hc = Instance.new("UICorner")
    hc.CornerRadius = UDim.new(0, 9)
    hc.Parent = holder
    local hs = Instance.new("UIStroke")
    hs.Color = tokens.Color.Stroke
    hs.Transparency = 0.88
    hs.Parent = holder

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.Padding = UDim.new(0, 3)
    layout.Parent = holder

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 3)
    padding.PaddingRight = UDim.new(0, 3)
    padding.PaddingTop = UDim.new(0, 3)
    padding.PaddingBottom = UDim.new(0, 3)
    padding.Parent = holder

    return setmetatable({
        Frame = root,
        Holder = holder,
        Tabs = {},
        Current = nil,
        Deps = deps,
        Accent = props.Accent or tokens.Color.Accent,
    }, SegmentedTabs)
end

function SegmentedTabs:Add(id, title, target)
    local tokens = self.Deps.Tokens
    local button = Instance.new("TextButton")
    button.Size = UDim2.fromOffset(math.max(74, #title * 7 + 24), tokens.Size.SegmentTabs - 6)
    button.BackgroundColor3 = tokens.Color.SurfaceSoft
    button.BackgroundTransparency = 1
    button.BorderSizePixel = 0
    button.Text = title
    button.TextColor3 = tokens.Color.TextMuted
    button.TextSize = tokens.Type.Value
    button.Font = self.Deps.Typography.Font.Medium
    button.AutoButtonColor = false
    button.Parent = self.Holder
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 7)
    c.Parent = button

    self.Tabs[id] = {Button = button, Target = target}
    target.Visible = false

    button.MouseButton1Click:Connect(function()
        self:Select(id)
    end)

    if not self.Current then
        self:Select(id)
    end

    return button
end

function SegmentedTabs:Select(id)
    if not self.Tabs[id] then return end
    self.Current = id
    local tokens = self.Deps.Tokens

    for tabId, entry in pairs(self.Tabs) do
        local selected = tabId == id
        entry.Target.Visible = selected
        entry.Button.BackgroundTransparency = selected and 0.10 or 1
        entry.Button.BackgroundColor3 = selected and self.Accent or tokens.Color.SurfaceSoft
        entry.Button.TextColor3 = selected and Color3.new(1, 1, 1) or tokens.Color.TextMuted
    end
end

return SegmentedTabs
