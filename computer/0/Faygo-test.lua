local faygo = require("Faygo")
local gui = faygo.init() -- Initialize the GUI, no monitor arguments defaults to the terminal

-- If we wanted to, we can do another init with a different object and attach it to a monitor and address it at the same time
-- Like this:
local monitor_peripheral = peripheral.find("monitor")
if monitor_peripheral ~= nil then
    local mon = faygo.init(monitor_peripheral) 
    mon:setBackground(colors.black)
    mon:clr()
end

gui:setBackground(colors.black)
gui:clr()
-- gui:drawRectRound(colors.red, 10, 10, 90, 90)

-- gui:drawCircle(colors.white, 75, 50, 37)
-- gui:drawCircle(colors.blue, 75, 50, 21)
-- gui:drawCircle(colors.black, 75, 50, 15)

gui:newButton(colors.green, 10, 70, 90, 90, "Click me!", function()
    gui:setBackground(colors.green)
    gui:drawTextCenter(colors.white, 50, 50, "You clicked this button!")
    os.sleep(2)
    gui:drawTextCenter(colors.green, 50, 50, "You clicked this button!")
    gui:drawTextCenter(colors.blue, 50, 50, "Click me!")
end)

gui:drawCircle(colors.white, 25, 50, 37)
gui:drawCircle(colors.blue, 25, 50, 21)
gui:drawCircle(colors.black, 25, 50, 15)

while true do
    os.sleep(1)
end