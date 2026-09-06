return function(runtime,options)
    local Assets={}
    local names={Community='community-v1.png',Updates='updates-v1.png'}
    local custom=getcustomasset or getsynasset
    local function validPNG(bytes) return type(bytes)=='string' and #bytes<12000000 and bytes:sub(1,8)=='\137PNG\13\10\26\10' end
    function Assets:Load(kind,label)
        local override=options[kind..'Image']
        if type(override)=='string' and override:match('^rbxassetid://%d+$') then label.Image=override; return end
        if type(custom)~='function' or type(writefile)~='function' or type(isfile)~='function' or type(readfile)~='function' then return end
        task.spawn(function()
            local ok,asset=pcall(function()
                local folder='SerenityConcept02'
                if type(makefolder)=='function' then pcall(makefolder,folder) end
                local path=folder..'/'..names[kind]
                local bytes
                if isfile(path) then bytes=readfile(path) end
                if not validPNG(bytes) then
                    bytes=game:HttpGet(options.AssetBase..names[kind])
                    assert(validPNG(bytes),'Invalid banner response')
                    writefile(path,bytes)
                end
                return custom(path)
            end)
            if ok and type(asset)=='string' and not runtime.Destroyed and label.Parent then label.Image=asset end
        end)
    end
    return Assets
end
