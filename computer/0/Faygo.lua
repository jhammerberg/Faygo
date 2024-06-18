local Faygo = {}
local GUI_object = {} -- A 'constructor' for the GUI object, technically a table with a metatable that is actually returned...

local shells = {}

-- eventListener() - Listens for events on the GUI
local function eventListener(startX, startY, endX, endY, callback, isTerm)
    if isTerm then
        while true do
            local event, key, x, y = os.pullEvent("mouse_click")
            if x >= startX and x <= endX and y >= endY and y <= startY then
                callback()
            end
        end
    else -- Monitor
        while true do
            local event, side, x, y = os.pullEvent("monitor_touch")
            if x >= startX and x <= endX and y >= endY and y <= startY then
                callback()
            end
        end
    end
end

local function eventLoop()
    while true do
        local event = {os.pullEvent()}
        
        for i = #shells, 1, -1 do
            local co = shells[i]
            
            if coroutine.status(co) == "dead" then
                table.remove(shells, i)
            else
                local ok, filter = coroutine.resume(co, unpack(event))
                
                if not ok then
                    print(filter)
                    table.remove(shells, i)
                elseif filter ~= nil and filter ~= event[1] then
                    table.insert(shells, table.remove(shells, i)) -- Move the coroutine to the end of the list
                end
            end
        end
    end
end

local function createShell(program)
    local co = coroutine.create(program)
    table.insert(shells, co)
end

-- Objective 1: Create a universal GUI drawing API that works on with terminals and monitors
-- Objective 2: Create a button API that can be used to create buttons on the GUI
-- Objective 3: Create a text input API that can be used to create text inputs on the GUI

-- For the sake of easier GUI drawing, functions that take position arguments will be on a scale from 1 to 100 instead of whatever width the monitor is
-- This function translates the 1-100 scale to the actual width of the monitor
function GUI_object:translateX(x)
    return math.floor(((x / 100) * self.width) + 1)
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
function GUI_object:translateRadius(r)
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
    local radius = self:translateRadius(radius)
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
function GUI_object:newButton(color, startX, startY, endX, endY, text, callback)
    local button = {}
    -- Draw the button
    self:drawRectRound(color, startX, startY, endX, endY)
    -- Translate coordinates
    local startX, startY = self:translatePos(startX, startY)
    local endX, endY = self:translatePos(endX, endY)
    -- Draw the text
    local textX = math.floor((endX - startX - #text) / 2) + startX
    local textY = math.floor((endY - startY) / 2) + startY
    self.GUI.setBackgroundColor(color)
    self.GUI.setTextColor(colors.blue)
    self.GUI.setCursorPos(textX, textY)
    self.GUI.write(text)
    -- Create the event listener
    -- Currently the event listener then takes over, meaning this is blocking
    createShell(eventListener(startX, startY, endX, endY, callback, self.isTerm))
    return button
end

-- killButton() - Kills a button object and event listener
function GUI_object:killButton(button)
    -- TODO: Implement this
end

-- GUI initialization, define if the GUI is being drawn on a terminal or a monitor
function Faygo.new(mon)
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
        GUI_return_value.isTerm = true
    else
        GUI_return_value.GUI = mon
        GUI_return_value.isTerm = false
    end

    GUI_return_value.width, GUI_return_value.height = GUI_return_value.GUI.getSize()
    GUI_return_value.backgroundColor = colors.black

    local eventLoopCo = coroutine.create(eventLoop)
    coroutine.resume(eventLoopCo)

    return GUI_return_value
end

-- init() - Initialize the GUI alias of initGUI()
function Faygo.init(mon)
    return Faygo.new(mon)
end

return Faygo