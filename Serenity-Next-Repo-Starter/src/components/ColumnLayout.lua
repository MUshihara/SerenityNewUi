local ColumnLayout = {}
ColumnLayout.__index = ColumnLayout

function ColumnLayout.new(parent, deps, props)
    props = props or {}
    local gap = props.Gap or 12

    local frame = Instance.new("Frame")
    frame.Name = props.Id or "ColumnLayout"
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.new(1, 0, 0, 0)
    frame.LayoutOrder = props.LayoutOrder or 1
    frame.Parent = parent

    local left = Instance.new("Frame")
    left.Name = "Left"
    left.BackgroundTransparency = 1
    left.Position = UDim2.fromOffset(0, 0)
    left.Size = UDim2.new(0.5, -(gap / 2), 0, 0)
    left.AutomaticSize = Enum.AutomaticSize.Y
    left.Parent = frame

    local right = Instance.new("Frame")
    right.Name = "Right"
    right.BackgroundTransparency = 1
    right.Position = UDim2.new(0.5, gap / 2, 0, 0)
    right.Size = UDim2.new(0.5, -(gap / 2), 0, 0)
    right.AutomaticSize = Enum.AutomaticSize.Y
    right.Parent = frame

    local leftList = Instance.new("UIListLayout")
    leftList.Padding = UDim.new(0, props.RowGap or 10)
    leftList.SortOrder = Enum.SortOrder.LayoutOrder
    leftList.Parent = left

    local rightList = Instance.new("UIListLayout")
    rightList.Padding = UDim.new(0, props.RowGap or 10)
    rightList.SortOrder = Enum.SortOrder.LayoutOrder
    rightList.Parent = right

    local self = setmetatable({
        Frame = frame,
        Left = left,
        Right = right,
        LeftList = leftList,
        RightList = rightList,
        Deps = deps,
    }, ColumnLayout)

    local function refresh()
        local leftH = leftList.AbsoluteContentSize.Y
        local rightH = rightList.AbsoluteContentSize.Y
        frame.Size = UDim2.new(1, 0, 0, math.max(leftH, rightH))
    end

    if deps.Runtime then
        deps.Runtime:TrackConnection(leftList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(refresh))
        deps.Runtime:TrackConnection(rightList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(refresh))
    else
        leftList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(refresh)
        rightList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(refresh)
    end

    task.defer(refresh)
    return self
end

return ColumnLayout
