require "streamdeck_buttons.button_images"

local function urlButton(url, button)
    local out = button
    out['pressUp'] =  function()
        hs.urlevent.openURL(url)
        performAfter = performAfter or function() end
        hs.timer.doAfter(0.2, function()
            performAfter()
        end)
    end
    return out
end

local weatherButton = urlButton('https://wttr.in', {
    ['imageProvider'] = function()
        local output = hs.execute('curl -s "wttr.in?format=1" | sed "s/+//" | sed "s/F//" | grep -v "Unknow"')
        return streamdeck_imageFromText(output, {['fontSize'] = 40 })
    end
})

local pinboardButton = urlButton('https://pinboard.in/add/', {
    ['image'] = streamdeck_imageFromText('􀎧', {['backgroundColor'] = hs.drawing.color.blue}),
    ['pressUp'] = function()
        hs.eventtap.keyStroke({"cmd"}, "v")
    end
})
