-- Objective 1: Create a universal GUI drawing API that works on with terminals and monitors
-- Objective 2: Create a button API that can be used to create buttons on the GUI
-- Objective 3: Create a text input API that can be used to create text inputs on the GUI

local Faygo = {}
local GUI_object = {} -- A 'constructor' for the GUI object, technically a table with a metatable that is actually returned...
local button_object = {}
local Active_GUIS = {} -- A table to store all the active GUIs, used for event handling
local threadAlive = false -- A variable to keep track of the event listener thread
---

-- translatePoint() - Translate a point to have 0, 0 be at the bottom left
function GUI_object:translatePoint(point) -- We also invert the Y axis
    return { x = point.x + 1, y = (self.absHeight + 1) - point.y}
end

-- untranslatePoint() - this is a dumb name, but useful when you want to convert a point back to our coordinate system
function GUI_object:untranslatePoint(point)
    return { x = point.x - 1, y = (self.absHeight - (point.y - 1))}
end

-- getAbsPoint(x, y) - Get the absolute position of a point on the GUI
function GUI_object:getAbsPoint(relativeX, relativeY)
    local scalerX = (relativeX/100)
    local scalerY = (relativeY/100)
    return { x = self.absWidth * scalerX, y = self.absHeight * scalerY }
end

function GUI_object:getMidPoint(startPoint, endPoint)
    local startPoint = self:translatePoint(startPoint)
    local endPoint = self:translatePoint(endPoint)
    return { x = (startPoint.x + endPoint.x) / 2, y = (startPoint.y + endPoint.y) / 2 }
end

-- setBackground(color) - Set the background color of the GUI
function GUI_object:setBackground(color)
    self.backgroundColor = color
    self.GUI.setBackgroundColor(color)
end

-- setBackgroundColor() - Alias for setBackground()
function GUI_object:setBackgroundColor(color)
    self:setBackground(color)
end

-- setForeground() - Set the foreground color of the GUI
function GUI_object:setForeground(color)
    self.foregroundColor = color
    self.GUI.setTextColor(color)
end

-- setForegroundColor() - Alias for setForeground()
function GUI_object:setForegroundColor(color)
    self:setForeground(color)
end

-- clearScreen() - Clear the screen of the GUI
function GUI_object:clearScreen()
    self.GUI.clear()
end

function GUI_object:clr() -- Alias
    self:clearScreen()
end

-- hideCursor() - Hide the cursor on the GUI
function GUI_object:hideCursor()
    self.GUI.setCursorPos(0,0)
end

-- drawRectFilled(backgroundColor, startPoint, endPoint) - Draw a solid rectangle on the GUI
function GUI_object:drawRectFilled(backgroundColor, startPoint, endPoint)
    -- Save the current background color so we can reset it after we draw the rectangle
    local oldBackgroundColor = self.backgroundColor
    local startPoint = self:translatePoint(startPoint)
    local endPoint = self:translatePoint(endPoint)
    self:setBackgroundColor(backgroundColor)
    for y = endPoint.y, startPoint.y do
        self.GUI.setCursorPos(startPoint.x, y)
        for x = startPoint.x, endPoint.x do
            self.GUI.write(" ")
        end
    end

    self:setBackgroundColor(oldBackgroundColor)
end

-- drawCircle(color, centerPoint, radius) - Draw a solid circle on the GUI
function GUI_object:drawCircleFilled(backgroundColor, centerPoint, radius)
    -- Save the current background color so we can reset it after we draw the circle
    local oldBackgroundColor = self.backgroundColor
    local centerPoint = self:translatePoint(centerPoint)
    local radius = self:translatePoint(radius)
    self:setBackgroundColor(backgroundColor)
    for y=-radius, radius do
        for x=-radius, radius do
            if x*x + (1.5*y)*(1.5*y) < radius*radius then -- Correct for vertical pixels being taller than horizontal pixels
                self.GUI.setCursorPos(centerPoint.x + x, centerPoint.y + y)
                self.GUI.write(" ")
            end
        end
    end
    self:setBackgroundColor(oldBackgroundColor)
end

-- drawRectRound(backgroundColor, startPoint, endPoint) - Draw a rectangle with rounded corners on the GUI
function GUI_object:drawRectRound(backgroundColor, startPoint, endPoint)
    -- Save the current background color so we can reset it after we draw the rectangle
    local oldBackgroundColor = self.backgroundColor
    -- Draw the rectangle
    self:drawRect(backgroundColor, startPoint, endPoint)
    local startPoint = self:translatePoint(startPoint)
    local endPoint = self:translatePoint(endPoint)
    -- Switch to the background color and draw the corners
    self.GUI.setBackgroundColor(self.backgroundColor) -- Might not be necessary since it should switch back after the drawRect() call
    self.GUI.setCursorPos(startPoint.x, endPoint.y)
    self.GUI.write(" ")
    self.GUI.setCursorPos(endPoint.x, endPoint.y)
    self.GUI.write(" ")
    self.GUI.setCursorPos(startPoint.x, startPoint.y)
    self.GUI.write(" ")
    self.GUI.setCursorPos(endPoint.x, startPoint.y)
    self.GUI.write(" ")
    self:setBackgroundColor(oldBackgroundColor)
end

-- drawLineText() - Draws a line using a specific character
function GUI_object:drawLineText(backgroundColor, foregroundColor, char, startPoint, endPoint)
    -- Save the current background color so we can reset it after we draw the line
    local oldBackgroundColor = self.backgroundColor
    local oldForegroundColor = self.foregroundColor
    local startPoint = self:translatePoint(startPoint)
    local endPoint = self:translatePoint(endPoint)
    self:setBackgroundColor(backgroundColor)
    self:setForegroundColor(foregroundColor)
    self.GUI.setCursorPos(startPoint.x, startPoint.y)
    self.GUI.write(" ")
    local dx = math.abs(endPoint.x - startPoint.x)
    local dy = math.abs(endPoint.y - startPoint.y)
    local sx = startPoint.x < endPoint.x and 1 or -1
    local sy = startPoint.y < endPoint.y and 1 or -1
    local err = dx - dy
    while not (startPoint.x == endPoint.x and startPoint.y == endPoint.y) do
        local e2 = err + err
        if e2 > -dy then
            err = err - dy
            startPoint.x = startPoint.x + sx
        end
        if e2 < dx then
            err = err + dx
            startPoint.y = startPoint.y + sy
        end
        self.GUI.setCursorPos(startPoint.x, startPoint.y)
        self.GUI.write(char)
    end
    self:setBackgroundColor(oldBackgroundColor)
    self:setForegroundColor(oldForegroundColor)
end

-- drawLine(backgroundColor, startPoint, endPoint) - Draw a line on the GUI
function GUI_object:drawLine(backgroundColor, startPoint, endPoint)
    self:drawLineText(backgroundColor, " ", startPoint, endPoint)
end

-- drawText() - Draw text on the GUI
function GUI_object:drawText(foregroundColor, backgroundColor, point, text)
    -- Save the current colors so we can reset it afterwards
    local oldBackgroundColor = self.backgroundColor
    local oldForegroundColor = self.foregroundColor
    local point = self:translatePoint(point)
    self:setBackgroundColor(backgroundColor)
    self:setForegroundColor(foregroundColor)
    self.GUI.setCursorPos(point.x, point.y)
    self.GUI.write(text)
    self:setBackgroundColor(oldBackgroundColor)
    self:setForegroundColor(oldForegroundColor)
end

-- drawTextCenter() - Draw text centrally around a point on the GUI
function GUI_object:drawTextCenter(foregroundColor, backgroundColor, point, text)
    local point = self:translatePoint(point)
    -- Offset the x and y by half the length of the text using absOffsetPos()
    local point = { x = (point.x + (-#text / 2)), y = (point.y) }
    -- Draw the text normally
    self:drawText(foregroundColor, backgroundColor, point, text)
end

-- Constructs a new button object and listens for it to be pressed and calls the callback
-- newButton(backgroundColor, foregroundColor, startX, endX, startY, endY, text, interactCallback) 
function GUI_object:newButton(foregroundColor, backgroundColor, startPoint, endPoint, text, interactCallback)
    local button = {}
    local midPoint = { x = (startPoint.x + endPoint.x) / 2, y = (startPoint.y + endPoint.y) / 2 }
    -- Draw the button (this should probably be redone)
    self:drawRectFilled(backgroundColor, startPoint, endPoint)
    -- Draw the text
    midPoint = self:untranslatePoint(midPoint) -- We need to convert the midpoint back to the GUI's coordinate system
    self:drawTextCenter(foregroundColor, backgroundColor, midPoint, text)
    -- Set the button's properties
    button.parent = self
    button.startPoint = startPoint
    button.endPoint = endPoint
    button.interactCallback = interactCallback
    button.text = text
    button.foregroundColor = foregroundColor
    button.backgroundColor = backgroundColor
    -- Add the methods to the button object
    setmetatable(button, {__index = button_object})
    -- Add the button to the GUI's list of buttons
    -- This effectively adds it to the event listener
    table.insert(self.buttons, button)
    -- Return the button object
    return button
end

-- killButton(button) - Deletes the button from the event listener, does not remove the button from the GUI
function button_object:kill()
    for _, gui in pairs(Active_GUIS) do
        for i, b in pairs(gui.buttons) do
            if b == self then
                -- Redraw the area the button was in to clear it
                gui:drawRectFilled(gui.backgroundColor, self.startPoint, self.endPoint)
                -- Remove the button from the GUI's list of buttons
                table.remove(gui.buttons, i)
            end
        end
    end
end

-- redraw(foregroundColor, backgroundColor, text) - Redraws the button, useful for when the button is pressed and you want to show it's been pressed
-- The arugments are optional, if none are provided it will redraw the button as it was when it was created
function button_object:redraw(foregroundColor, backgroundColor, text)
    local startPoint = self.startPoint
    local endPoint = self.endPoint
    if foregroundColor == nil then
        foregroundColor = self.foregroundColor
    end
    if backgroundColor == nil then
        backgroundColor = self.backgroundColor
    end
    if text == nil then
        text = self.text
    end
    self.parent:drawRectFilled(backgroundColor, startPoint, endPoint)
    local midPoint = { x = (startPoint.x + endPoint.x) / 2, y = (startPoint.y + endPoint.y) / 2 }
    midPoint = self.parent:untranslatePoint(midPoint)
    self.parent:drawTextCenter(foregroundColor, backgroundColor, midPoint, text)
end

-- kill() - Deletes the GUI from the event listener and clears the screen the GUI was on
function GUI_object:kill()
    self:clearScreen()
    for i, gui in pairs(Active_GUIS) do
        if gui == self then
            table.remove(Active_GUIS, i)
        end
    end
end

-- Faygo event check, pulls events from the event queue and checks if they are for any Faygo GUIs
function Faygo.checkEvents()
    local event, arg1, arg2, arg3, arg4, arg5 = os.pullEvent() 
    -- Pulling an event from the event effectively yields this coroutine until an event is pulled
    -- If Faygo is ran with a main function, this will be ran in parallel 
    -- which yields the main process every once in a while to check if there has been new events
    if event == "mouse_click" then -- If it's a mouse click, we know it must be a button on a terminal GUI
        local key, x, y = arg1, arg2, arg3
        -- Loop over all the GUIs and find the one that has a side property that is nil
        for _, gui in pairs(Active_GUIS) do
            if gui.side == nil then
                -- See if there is a button inside the GUI at the position that was clicked and call the callback
                for _, button in pairs(gui.buttons) do
                    local startPoint = gui:translatePoint(button.startPoint)
                    local endPoint = gui:translatePoint(button.endPoint)
                    if x >= startPoint.x and x <= endPoint.x and y >= endPoint.y and y <= startPoint.y then
                        button.interactCallback(button, key) -- We'll pass this to the callback cause why not
                    end
                end
            end
        end
    elseif event == "monitor_touch" then -- If it's a monitor touch, we know it must be a button on a monitor GUI
        local side, x, y = arg1, arg2, arg3
        -- Loop over all the GUIs and find the one that has a side property that matches the side of the monitor that was touched
        for _, gui in pairs(Active_GUIS) do
            if gui.side == side then
                -- See if there is a button inside the GUI at the position that was clicked and call the callback
                for _, button in pairs(gui.buttons) do
                    local startPoint = gui:translatePoint(button.startPoint)
                    local endPoint = gui:translatePoint(button.endPoint)
                    if x >= startPoint.x and x <= endPoint.x and y >= endPoint.y and y <= startPoint.y then
                        button.interactCallback(button)
                    end
                end
            end
        end
    end
end

-- Faygo thead loop, to be ran along side the main program loop or in place of it
local function startFaygoThread()
    while threadAlive == true do -- Currently just starts an event loop, but could be expanded to do more (maybe animations?)
        Faygo.checkEvents()
    end
end

-- Returns a new GUI object bound to a monitor or terminal
-- Faygo.newGUI([mon]) - optional argument for a monitor object, if none is provided it will default to the terminal
function Faygo.newGUI(mon)
    local GUI_return_value = {} 
    -- Classes in Lua are confusing since they don't really exist
    -- What's going on is that there's a "GUI_object" table that has a metatable of "GUI_return_value"
    -- When I want to add methods to the GUI_object, I add them to the GUI_return_value table.
    -- But "GUI_object" is the table that is defined by this API, 
    -- the "GUI_return_value" is the table that is returned when you create a new instance of the GUI
    -- and you can actually use methods on.

    -- This is slightly more complicated because the Faygo API itself IS a table, and because of the way you
    -- import it, "Faygo" is already the return object which is why I don't bother calling it the "Faygo_return_value"
    -- And since there's going to be a table inside this table which has a metatable, you use the ":" operator to call methods
    -- Instead of the "." operator, which is why you see "GUI_object:drawRect()" instead of "GUI_object.drawRect()"
    -- Not confusing at all...
    setmetatable(GUI_return_value, {__index = GUI_object})
    -- Get the monitor or terminal object for this instance of the GUI
    -- Don't confuse this with the GUI_object, which is the table that has the methods, this is the actual monitor or terminal object that the GUI is being drawn on.
    if mon == nil then
        GUI_return_value.GUI = term
        GUI_return_value.side = nil -- If it's a terminal, there's no side. Could be a bool but this saves variables and keeps things tidy
    else
        GUI_return_value.GUI = mon
        -- Get the side the monitor is on so we know where to look for events
        GUI_return_value.side = peripheral.getName(mon)
    end
    GUI_return_value.parent = nil -- We're creating a 'screen' GUI, so there's no parent (this would be implied, but we're making sure)
    local tempX, tempY = GUI_return_value.GUI.getSize() -- We do this so we can change the size of the GUI later
    GUI_return_value.absWidth, GUI_return_value.absHeight = (tempX-1), (tempY-1) -- We subtract one from the size because our system indexes at 0,0
    GUI_return_value.backgroundColor = colors.black
    GUI_return_value.foregroundColor = colors.white
    GUI_return_value.buttons = {} -- A table to store all the buttons on the GUI, it will be empty initially.
    table.insert(Active_GUIS, GUI_return_value)

    return GUI_return_value
end

-- Alias for newGUI()
-- initGUI([mon]) - optional argument for a monitor object, if none is provided it will default to the terminal
function Faygo.initGUI(mon)
    return Faygo.newScreen(mon)
end

-- IMPORTANT: This function should be called *instead* of calling your main function
-- Starts the event listener for the buttons, takes a main function as an argument so it can be ran with the parallel API.
-- Alternatively, not passing a main function will simply run the event listener and block the main thread
-- This is the closest thing to async you can get in CC Lua, since we can't use coroutines with the event API easily or safely.
-- Yet another option is to call the Faygo.checkEvents() function in your main loop
-- But that's not advised since it will block the rest of the loop and means that the polling rate for buttons depends on your main loop
function Faygo.run(main)
    if main == nil then -- If there's no main function, just run the event listener and block the main thread
        threadAlive = true
        startFaygoThread()
    else -- If there is a main function, run it in parallel with the event listener
        threadAlive = true
        parallel.waitForAny(main, startFaygoThread)
    end 
end

-- cleanUp() - Deletes all active buttons, all active GUIs, kills the event listener, and clears the screen
-- Sort of optional, since when the main program ends, the event listener will end as well, but this also clears all screens
-- !!! This will also terminate the main program !!! (assuming it's ran in parallel)
function Faygo.cleanUp()
    for _, gui in pairs(Active_GUIS) do
        gui:setBackground(colors.black)
        gui:clearScreen()
    end
    Active_GUIS = {}
    threadAlive = false
    term.setCursorPos(1,1)
end

return Faygo