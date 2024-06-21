-- Objective 1: Create a universal GUI drawing API that works on with terminals and monitors
-- Objective 2: Create a button API that can be used to create buttons on the GUI
-- Objective 3: Create a text input API that can be used to create text inputs on the GUI

local Faygo = {}
local GUI_object = {} -- A 'constructor' for the GUI object, technically a table with a metatable that is actually returned...
local Active_GUIS = {} -- A table to store all the active GUIs, used for event handling
local threadAlive = false -- A variable to keep track of the event listener thread
---

-- For the sake of easier GUI drawing, functions that take position arguments will be on a scale from 1 to 100 instead of whatever width the monitor is
-- Most functions will immediately translate these 1-100 values to the actual pixel values on the GUI, sorry if it's confusing
-- This function translates the 1-100 scale to the actual width of the monitor
function GUI_object:translateX(x)
    return math.floor(((x / 100) * self.width))
end

function GUI_object:translateY(y)
    -- Additionally, the position for the cursor on the Y axis has 0 at the top, so we need to invert the Y axis
    y = 100 - y
    -- Also, the Y axis is 1-indexed, so we need to subtract, I mean add cause it's inverted, 1 from the Y value
    return math.floor(((y / 100) * self.height) + 1)
end

function GUI_object:translatePos(x, y)
    return self:translateX(x), self:translateY(y)
end

-- Translate an arbitrary 1 to 100 number to a normal one in pixel, like a radius for a circle
function GUI_object:translateArb(r)
    return math.floor((r / 100) * ((self.width + self.height) / 2))
end

-- setBackground() - Set the background color of the GUI
function GUI_object:setBackground(color)
    self.backgroundColor = color
    self.GUI.setBackgroundColor(color)
end

-- setForeground() - Set the foreground color of the GUI
function GUI_object:setForeground(color)
    self.GUI.setTextColor(color)
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

-- drawRect() - Draw a rectangle on the GUI
function GUI_object:drawRect(color, startX, startY, endX, endY)
    local startX, startY = self:translatePos(startX, startY)
    local endX, endY = self:translatePos(endX, endY)
    self.GUI.setBackgroundColor(color)
    for y = endY, startY do
        self.GUI.setCursorPos(startX, y)
        for x = startX, endX do
            self.GUI.write(" ")
        end
    end
end

-- drawCircle() - Draw a circle on the GUI
function GUI_object:drawCircle(color, x, y, radius)
    local midx, midy = self:translatePos(x, y)
    local radius = self:translateArb(radius)
    self.GUI.setBackgroundColor(color)
    for y=-radius, radius do
        for x=-radius, radius do
            if x*x + (1.5*y)*(1.5*y) < radius*radius then -- Correct for vertical pixels being taller than horizontal pixels
                self.GUI.setCursorPos(midx + x, midy + y)
                self.GUI.setBackgroundColor(color)
                self.GUI.write(" ")
            end
        end
    end
end

-- drawRectRound() - Draw a rectangle with rounded corners on the GUI
function GUI_object:drawRectRound(color, startX, startY, endX, endY)
    -- Draw the rectangle
    self:drawRect(color, startX, startY, endX, endY)
    local startX, startY = self:translatePos(startX, startY)
    local endX, endY = self:translatePos(endX, endY)
    -- Switch to the background color and draw the corners
    self.GUI.setBackgroundColor(self.backgroundColor)
    self.GUI.setCursorPos(startX, endY)
    self.GUI.write(" ")
    self.GUI.setCursorPos(endX, endY)
    self.GUI.write(" ")
    self.GUI.setCursorPos(startX, startY)
    self.GUI.write(" ")
    self.GUI.setCursorPos(endX, startY)
    self.GUI.write(" ")
end

-- drawLine() - Draw a line on the GUI
function GUI_object:drawLine(color, startX, startY, endX, endY)
    local startX, startY = self:translatePos(startX, startY)
    local endX, endY = self:translatePos(endX, endY)
    self.GUI.setBackgroundColor(color)
    self.GUI.setCursorPos(startX, startY)
    self.GUI.write(" ")
    local dx = math.abs(endX - startX)
    local dy = math.abs(endY - startY)
    local sx = startX < endX and 1 or -1
    local sy = startY < endY and 1 or -1
    local err = dx - dy
    while not (startX == endX and startY == endY) do
        local e2 = err + err
        if e2 > -dy then
            err = err - dy
            startX = startX + sx
        end
        if e2 < dx then
            err = err + dx
            startY = startY + sy
        end
        self.GUI.setCursorPos(startX, startY)
        self.GUI.write(" ")
    end
end

-- drawLineText() - Draws a line using a specific character
function GUI_object:drawLineText(color, char, startX, startY, endX, endY)
    local startX, startY = self:translatePos(startX, startY)
    local endX, endY = self:translatePos(endX, endY)
    self.GUI.setTextColour(color)
    self.GUI.setCursorPos(startX, startY)
    self.GUI.write(char)
    local dx = math.abs(endX - startX)
    local dy = math.abs(endY - startY)
    local sx = startX < endX and 1 or -1
    local sy = startY < endY and 1 or -1
    local err = dx - dy
    while not (startX == endX and startY == endY) do
        local e2 = err + err
        if e2 > -dy then
            err = err - dy
            startX = startX + sx
        end
        if e2 < dx then
            err = err + dx
            startY = startY + sy
        end
        self.GUI.setCursorPos(startX, startY)
        self.GUI.write(char)
    end
end

-- drawText() - Draw text on the GUI
function GUI_object:drawText(color, x, y, text)
    local x, y = self:translatePos(x, y)
    self.GUI.setBackgroundColor(self.backgroundColor)
    self.GUI.setTextColor(color)
    self.GUI.setCursorPos(x, y)
    self.GUI.write(text)
end

-- drawTextCenter() - Draw text centrally around a point on the GUI
function GUI_object:drawTextCenter(color, x, y, text)
    local x, y = self:translatePos(x, y)
    local textX = x - math.floor(#text / 2)
    self.GUI.setTextColor(color)
    self.GUI.setCursorPos(textX, y)
    self.GUI.write(text)
end

-- newButton() - Constructs a new button object and listens for it to be pressed and calls the callback
function GUI_object:newButton(color, textColor, startX, startY, endX, endY, text, callback)
    local button = {}
    -- Add the button to the GUI's list of buttons
    table.insert(self.buttons, button)
    -- Draw the button (this should probably be redone)
    self:setBackground(color)
    self:drawRect(color, startX, startY, endX, endY)
    -- Translate coordinates
    local startX, startY = self:translatePos(startX, startY)
    local endX, endY = self:translatePos(endX, endY)
    -- Draw the text
    local textX = math.floor((endX - startX - #text) / 2) + startX
    local textY = math.floor((endY - startY) / 2) + startY
    self.GUI.setTextColor(textColor)
    self.GUI.setCursorPos(textX, textY)
    self.GUI.write(text)
    -- Set the button's properties
    button.startX = startX
    button.startY = startY
    button.endX = endX
    button.endY = endY
    button.callback = callback
    -- Return the button object
    return button
    -- We don't handle the event listener here, that's done in the Faygo.checkEvents() function
end

-- killButton() - Deletes the button from the event listener, does not remove the button from the GUI
function GUI_object:killButton(button)
    for i, b in pairs(self.buttons) do
        if b == button then
            table.remove(self.buttons, i)
        end
    end
end

-- killGUI() - Deletes the GUI from the event listener and clears the screen the GUI was on
function GUI_object:killGUI()
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
                    if x >= button.startX and x <= button.endX and y >= button.endY and y <= button.startY then
                        button.callback(key) -- We'll pass this to the callback cause why not
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
                    if x >= button.startX and x <= button.endX and y >= button.endY and y <= button.startY then
                        button.callback()
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

-- GUI initialization, define if the GUI is being drawn on a terminal or a monitor
function Faygo.newGUI(mon)
    GUI_return_value = {} 
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

    GUI_return_value.width, GUI_return_value.height = GUI_return_value.GUI.getSize()
    GUI_return_value.backgroundColor = colors.black
    GUI_return_value.buttons = {} -- A table to store all the buttons on the GUI, it will be empty initially.
    table.insert(Active_GUIS, GUI_return_value)

    return GUI_return_value
end

-- init() - Initialize the GUI alias of initGUI()
function Faygo.initGUI(mon)
    return Faygo.newGUI(mon)
end

-- cleanUp() - Deletes all active buttons, all active GUIs, kills the event listener, and clears the screen
-- Sort of optional, since when the main program ends, the event listener will end as well, but this also clears all screens
-- !!! This will also terminate the main program !!!
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