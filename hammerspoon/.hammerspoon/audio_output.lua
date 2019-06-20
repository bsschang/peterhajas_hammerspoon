-- Audio Output {{{

local lastSeenName = ""

hs.audiodevice.watcher.setCallback(function(kind)
    if kind == "dOut" or kind == "sOut" then
        local name = hs.audiodevice.current()['name']
        if name ~= lastSeenName then
            lastSeenName = name
            local volume = hs.audiodevice.current()['volume']
            local alertText = "🔉 " .. name .. " " .. volume
            hs.alert(alertText)
        end
    end
end)

hs.audiodevice.watcher.start()

-- }}}