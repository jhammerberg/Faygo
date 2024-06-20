local faygo = require("Faygo")
local gui = faygo.initGUI() -- Initialize the GUI, no monitor arguments defaults to the terminal

-- If we wanted to, we can do another init with a different object and attach it to a monitor and address it at the same time
-- Like this:
local monitor_peripheral = peripheral.find("monitor")
if monitor_peripheral ~= nil then
    Mon = faygo.initGUI(monitor_peripheral) 
end

Mon:setBackground(colors.black)
Mon:clr()
gui:setBackground(colors.black)
gui:clr()

gui:newButton(colors.green, 10, 70, 90, 90, "Kill Monitor GUI", function()
    gui:setBackground(colors.green)
    gui:drawTextCenter(colors.white, 50, 80, "You clicked this button!")
    Mon:killGUI()
    os.sleep(0.5)
    gui:drawTextCenter(colors.green, 50, 80, "You clicked this button!")
    gui:drawTextCenter(colors.blue, 50, 80, "Kill Monitor GUI")
end)

gui:newButton(colors.green, 10, 10, 90, 30, "Kill All GUIs", function()
    gui:setBackground(colors.green)
    gui:drawTextCenter(colors.white, 50, 20, "You clicked this button!")
    faygo.cleanUp()
end)

THE_Button = Mon:newButton(colors.green, 10, 70, 90, 90, "Kill Terminal GUI", function()
    Mon:setBackground(colors.green)
    Mon:drawTextCenter(colors.white, 50, 80, "You clicked this button!")
    gui:killGUI()
    os.sleep(0.5)
    Mon:drawTextCenter(colors.green, 50, 80, "You clicked this button!")
    Mon:drawTextCenter(colors.blue, 50, 80, "Kill Terminal GUI")
end)

Mon:newButton(colors.green, 10, 10, 90, 30, "Kill The Other Button", function()
    Mon:setBackground(colors.green)
    Mon:drawTextCenter(colors.white, 50, 20, "You clicked this button!")
    Mon:killButton(THE_Button)
    os.sleep(0.5)
    Mon:drawTextCenter(colors.green, 50, 20, "You clicked this button!")
    Mon:drawTextCenter(colors.blue, 50, 20, "Kill The Other Button")
end)

local function main()
    while true do
        -- Imagine this has other program logic
        os.sleep(1)
    end
end

faygo.run(main)