local Status = {}

function Status.new(parent, deps, props)
    local tokens = deps.Tokens
    props = props or {}

    local row = Instance.new("Frame")
    row.Name = props.Id or "Status"
    row.Size = UDim2.new(1, 0, 0, tokens.Size.Status)
    row.Parent = parent
    deps.Material.Control(row, tokens)

    deps.Typography.Label(row, "Control", tokens, props.Title or "Status", UDim2.fromOffset(14, 6), UDim2.new(1, -130, 0, 18), tokens.Color.Text)
    deps.Typography.Label(row, "Description", tokens, props.Description or "", UDim2.fromOffset(14, 25), UDim2.new(1, -130, 0, 15), tokens.Color.TextDim)

    local color = props.Color or tokens.Color.TextMuted
    local chip = Instance.new("TextLabel")
    chip.AnchorPoint = Vector2.new(1, 0.5)
    chip.Position = UDim2.new(1, -13, 0.5, 0)
    chip.Size = UDim2.fromOffset(92, 26)
    chip.BackgroundColor3 = tokens.Color.Inset
    chip.BackgroundTransparency = 0.06
    chip.BorderSizePixel = 0
    chip.Text = props.Text or "READY"
    chip.TextColor3 = color
    chip.Parent = row
    deps.Typography.Apply(chip, "Status", tokens, color)

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 7)
    c.Parent = chip
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Transparency = 0.62
    s.Parent = chip

    local api = {Frame = row, Chip = chip}
    function api:Set(text, newColor)
        chip.Text = text
        if newColor then
            chip.TextColor3 = newColor
            s.Color = newColor
        end
    end
    return api
end

return Status
