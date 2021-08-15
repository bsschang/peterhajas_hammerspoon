
-- Key: window ID
-- Value: table:
--   Keys: 'space', 'shownUnitFrame'
windowMap = { }

-- Key: space number (1-indexed)
-- Value: table:
--   Keys: 'focusedWindowID'
spaceMap = { }

-- The current space, 1-indexed
currentSpace = 1

-- Our menu item
workspaceMenuItem = hs.menubar.new()

function spacesDebug()
    print('Current space: ' .. currentSpace)
    print('windowMap:')
    dbg(windowMap)

    print('spaceMap:')
    dbg(spaceMap)
end

local function spaceForWindowID(windowID)
    local windowInfo = windowMap[windowID] or { ['space'] = currentSpace }
    return windowInfo['space']
end

local function sendWindowAway(windowID)
    if windowMap[windowID] == nil then return end
    if windowMap[windowID]['shownUnitFrame'] ~= nil then return end

    local window = hs.window(windowID)
    if window == nil then return end

    local screen = window:screen()
    local unitFrame = window:frame()
    local scaleFactor = screen:frame()

    unitFrame.x = unitFrame.x / scaleFactor.w
    unitFrame.y = unitFrame.y / scaleFactor.h
    unitFrame.w = unitFrame.w / scaleFactor.w
    unitFrame.h = unitFrame.h / scaleFactor.h

    windowMap[windowID]['shownUnitFrame'] = unitFrame

    local newFrame = window:frame()
    newFrame.x = 10000
    newFrame.y = 10000
    window:setFrame(newFrame)
end

local function bringWindowBack(windowID)
    if windowMap[windowID] == nil then return end
    if windowMap[windowID]['shownUnitFrame'] == nil then return end

    local window = hs.window(windowID)
    if window == nil then return end

    local screen = window:screen()
    local windowFrame = windowMap[windowID]['shownUnitFrame']
    local scaleFactor = screen:frame()

    windowFrame.x = windowFrame.x * scaleFactor.w
    windowFrame.y = windowFrame.y * scaleFactor.h
    windowFrame.w = windowFrame.w * scaleFactor.w
    windowFrame.h = windowFrame.h * scaleFactor.h

    window:setFrame(windowFrame)
    windowMap[windowID]['shownUnitFrame'] = nil
end

local function update()
    local populatedSpaces = { }
    
    -- Update windows
    local someWindowInCurrentSpace = nil
    for windowID, windowInfo in pairs(windowMap) do
        local space = windowInfo['space']
        populatedSpaces[space] = true
        if space ~= currentSpace then
            sendWindowAway(windowID)
        else
            bringWindowBack(windowID)
            someWindowInCurrentSpace = window
        end
    end

    -- Update menu item
    local menuItemText = hs.styledtext.new('')
    for spaceNumber, spaceInfo in pairs(spaceMap) do
        local textForSpaceNumber = ' ' .. tostring(spaceNumber) .. ' '
        if spaceNumber == currentSpace then
            -- If we're in this space, then add it
            menuItemText = menuItemText .. hs.styledtext.new(textForSpaceNumber, { ['color'] = tintColor })
        else
            -- Only add if there are windows in this space
            if populatedSpaces[spaceNumber] ~= nil then
                menuItemText = menuItemText .. hs.styledtext.new(textForSpaceNumber)
            end
        end
        dbg(menuItemText)
    end
    workspaceMenuItem:setTitle(menuItemText)

    -- Update focus (disabled - see below)
    local spaceInfo = spaceMap[currentSpace] or { }
    local windowIDToFocus = spaceInfo['focusedWindowID']
    if windowIDToFocus ~= nil then
        local windowToFocus = hs.window(windowID)
        if windowToFocus ~= nil then
            windowToFocus:focus()
        end
    end
end

local function switchToSpace(space)
    if space ~= currentSpace then
        currentSpace = space
        update()
    else
        hs.sound.getByName("Tink"):play()
    end
end

local function moveWindowToSpace(window, space)
    if windowMap[window:id()] == nil then
        windowMap[window:id()] = { }
    end
    windowMap[window:id()]['space'] = space
    update()
end

local function windowCreated(window)
    windowMap[window:id()] = { }
    windowMap[window:id()]['space'] = currentSpace
end

local function windowDestroyed(window)
    windowMap[window:id()] = nil
end

local function windowFocused(window)
    -- plh-evil: this needs some fixes, so it is disabled below
    -- what needs to change::
    -- - if a window is moving spaces, we need to remove it from our focused
    --   window tracking, and find the next window to focus for our space

    -- Switch to that space, or mark this window as focused for this space
    local windowSpace = spaceForWindowID(window:id())
    if windowSpace == nil then return end

    if windowSpace ~= currentSpace then
        switchToSpace(windowSpace)
    else
        spaceMap[currentSpace] = { }
        spaceMap[currentSpace]['focusedWindowID'] = window:id()
    end
end

for k,i in pairs({1,2,3,4,5,6,7,8,9,0}) do
    spaceMap[i] = { }

    hs.hotkey.bind({"alt"}, tostring(i), function()
        switchToSpace(i)
    end)
    hs.hotkey.bind({"alt", "shift"}, tostring(i), function()
        moveWindowToSpace(hs.window.frontmostWindow(), i)
    end)
end

workspaceWindowFilter = hs.window.filter.copy(hs.window.filter.default)
:rejectApp('Hammerspoon')
:subscribe({hs.window.filter.windowCreated, hs.window.filter.windowDestroyed, hs.window.filter.windowFocused}, function(window, appName, event)
    if event == hs.window.filter.windowCreated then
        windowCreated(window)
    elseif event == hs.window.filter.windowDestroyed then
        windowDestroyed(window)
    elseif event == hs.window.filter.windowFocused then
        -- windowFocused(window)
    end
end, true)

update()

