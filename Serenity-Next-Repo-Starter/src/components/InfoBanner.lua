local InfoBanner = {}

function InfoBanner.new(parent, deps, props)
    local tokens = deps.Tokens
    props = props or {}
    local accent = props.Color or tokens.Color.Accent

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, tokens.Size.InfoBanner)
    frame.Parent = parent
    deps.Material.Banner(frame, tokens, accent)

    if props.Icon then
        local icon = deps.Icons.Create(frame, props.Icon, 18, accent)
        icon.Position = UDim2.fromOffset(14, 13)
    end

    local left = props.Icon and 42 or 14
    deps.Typography.Label(
        frame,
        "BannerTitle",
        tokens,
        props.Title or "Information",
        UDim2.fromOffset(left, 8),
        UDim2.new(1, -(left + 14), 0, 19),
        tokens.Color.Text
    )

    local body = deps.Typography.Label(
        frame,
        "BannerBody",
        tokens,
        props.Description or "",
        UDim2.fromOffset(left, 28),
        UDim2.new(1, -(left + 14), 0, 26),
        tokens.Color.TextMuted
    )
    body.TextWrapped = true
    body.TextYAlignment = Enum.TextYAlignment.Top

    return frame
end

return InfoBanner
