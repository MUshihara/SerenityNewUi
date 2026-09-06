local Desktop = {}

function Desktop.Mount(root, deps, options)
    -- This file becomes the composition layer:
    -- window shell
    -- topbar
    -- sidebar
    -- content area
    -- footer
    -- command palette host
    -- popup/toast/modal layers
    --
    -- It should consume semantic pages/features/controls,
    -- never game mechanics.
    return {
        Root = root,
        Options = options,
    }
end

return Desktop
