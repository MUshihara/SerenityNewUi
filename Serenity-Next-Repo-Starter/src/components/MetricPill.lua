local MetricPill = {}
MetricPill.__index = MetricPill

function MetricPill.new(parent, deps, props)
    local tokens = deps.Tokens
    props = props or {}

    local frame = Instance.new("Frame")
    frame.Size = UDim2.fromOffset(props.Width or 82, tokens.Size.MetricPill)
    frame.Parent = parent
    deps.Material.Pill(frame, tokens, props.Accent)

    local label = deps.Typography.Label(
        frame,
        "Metric",
        tokens,
        props.Text or "--",
        UDim2.fromOffset(9, 0),
        UDim2.new(1, -18, 1, 0),
        props.Color or tokens.Color.TextMuted
    )
    label.TextXAlignment = Enum.TextXAlignment.Center

    return setmetatable({Frame = frame, Label = label}, MetricPill)
end

function MetricPill:SetText(text)
    self.Label.Text = text
end

return MetricPill
