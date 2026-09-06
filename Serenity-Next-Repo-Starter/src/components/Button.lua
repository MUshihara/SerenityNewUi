local Button = {}
Button.__index = Button

function Button.new(parent, deps, props)
    local tokens = deps.Tokens
    props = props or {}

    local row = Instance.new("Frame")
    row.Name = props.Id or "Button"
    row.Size = UDim2.new(1, 0, 0, tokens.Size.Button)
    row.Parent = parent
    deps.Material.Control(row, tokens)

    deps.Typography.Label(row, "Control", tokens, props.Title or "Button", UDim2.fromOffset(14, 7), UDim2.new(1, -70, 0, 19), tokens.Color.Text)
    deps.Typography.Label(row, "Description", tokens, props.Description or "", UDim2.fromOffset(14, 27), UDim2.new(1, -70, 0, 16), tokens.Color.TextDim)

    local icon = deps.Icons.Create(row, props.Icon or "chevron_right", 16, props.Color or tokens.Color.TextMuted)
    icon.AnchorPoint = Vector2.new(1, 0.5)
    icon.Position = UDim2.new(1, -15, 0.5, 0)

    local hit = Instance.new("TextButton")
    hit.BackgroundTransparency = 1
    hit.Text = ""
    hit.AutoButtonColor = false
    hit.Size = UDim2.fromScale(1, 1)
    hit.Parent = row

    hit.MouseEnter:Connect(function() deps.Material.Hover(row, tokens, true) end)
    hit.MouseLeave:Connect(function() deps.Material.Hover(row, tokens, false) end)
    hit.MouseButton1Click:Connect(function()
        if props.Callback then props.Callback() end
    end)

    return setmetatable({Frame = row}, Button)
end

return Button
