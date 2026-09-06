local Mobile = {}

function Mobile.Mount(root, deps, options)
    -- Mobile will reuse the same semantic controls,
    -- but compose them as touch-friendly single-column sections.
    --
    -- Never duplicate game callbacks here.
    return {
        Root = root,
        Options = options,
    }
end

return Mobile
