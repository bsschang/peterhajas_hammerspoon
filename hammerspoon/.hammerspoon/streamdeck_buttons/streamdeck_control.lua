require "streamdeck_buttons.button_images"
function streamdeckControl()
    return {
        ['name'] = 'StreamDeck Control',
        ['image'] = streamdeck_imageFromText('􀦴'),
        ['children'] = {
            {
                ['image'] = streamdeck_imageFromText('􀆫'),
                ['pressUp'] = function(deck) 
                    
                end
            }
        }
    }
end