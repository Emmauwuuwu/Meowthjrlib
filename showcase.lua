-- Meowthjrlib showcase: every feature in one script. Nothing here touches the game.
local Lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Emmauwuuwu/Meowthjrlib/main/Meowthjrlib.lua"))()
local Players = game:GetService("Players")

local ui = Lib.new("Showcase", { key = "RightShift", intro = "Loading the showcase" })

---------------------------------------------------------------- widgets
local screen = ui:Category("Screen", { icon = "computer-monitor", color = "52D9A4" })
screen:Watermark()
screen:KeyList()
screen:KeyViewer()
screen:ActiveList()
local clock = screen:Module("Clock", { default = true, tip = "A widget of your own" }):Widget(function()
	return os.date("%H:%M:%S")
end)

---------------------------------------------------------------- every setting
local basics = ui:Category("Basics", { icon = "three-sliders-horizontal", color = "FF9F4F" })

local inputs = basics:Module("Inputs", { icon = "keyboard", tip = "Toggles, sliders, text and buttons" }, function(on)
	print("Inputs is", on)
end)
inputs:Section("Switches and numbers")
inputs:Toggle("Toggle", { default = true, key = "J", tip = "Press J, or click Set key to change it" }, function(v) print("Toggle", v) end)
inputs:Slider("Slider", { min = 0, max = 10, step = 0.5, default = 4, suffix = " s", tip = "Click the number to type one" }, function(v) print("Slider", v) end)
inputs:Range("Range", { min = 0, max = 100, default = { 20, 60 }, suffix = "%" }, function(v) print("Range", v[1], v[2]) end)
inputs:Section("Text")
inputs:TextBox("One line", { placeholder = "Your text" }, function(v) print("Text", v) end)
inputs:TextBox("Several lines", { lines = 3, placeholder = "Notes" }, function(v) print("Notes", v) end)
inputs:Section("Buttons")
inputs:Button("Button", { icon = "play-small", key = "LeftControl+J", tip = "Ctrl+J works too" }, function()
	ui:Notify("Button", "You pressed it", 3, "check-large")
end)

local lists = basics:Module("Lists", { icon = "list-bulleted", tip = "Dropdowns" })
lists:Dropdown("Pick one", { "Smooth", "Instant", "Stepped", default = "Instant" }, function(v) print("Picked", v) end)
lists:Dropdown("Pick several", { "Red", "Green", "Yellow", multi = true, default = { "Red" } }, function(v) print("Picked", table.concat(v, ", ")) end)
lists:Dropdown("With search", { "Apple", "Banana", "Cherry", "Fig", "Grape", "Kiwi", "Lemon", "Mango", "Orange", "Pear" })
lists:PlayerDropdown("Players here", { tip = "Updates itself as people join and leave" }, function(v) print("Player", v) end)

local colors = basics:Module("Colors", { icon = "paint-brush", tip = "Solid and see-through" })
colors:Color("Color", { default = "E3C07E", presets = { Color3.fromHex("E3C07E"), Color3.fromHex("FF6F7D"), Color3.fromHex("52D9A4") } }, function(v) print("Color", v:ToHex()) end)
colors:Color("See-through", { default = "B792FF", alpha = 0.5 }, function(v, alpha) print("Color", v:ToHex(), alpha) end)

local display = basics:Module("Display", { icon = "image", tip = "Text, progress and images" })
display:Label("Labels can be <b>bold</b>, <i>italic</i> or <u>underlined</u>.", { rich = true })
local live = display:Label("This text changes while you watch.")
local bar = display:Progress("Progress", { tip = "Moves while this module is on" })
display:Image("rbxthumb://type=AvatarHeadShot&id=" .. Players.LocalPlayer.UserId .. "&w=150&h=150", 120)
-- Runs every frame while Display is on.
display:Loop(function()
	local x = os.clock() % 5 / 5
	bar:Update(x, math.round(x * 100) .. "% done")
	live:SetText("Updated at " .. os.date("%H:%M:%S"))
end)

local smart = basics:Module("Smart settings", { icon = "lightning-bolt", tip = "Settings that appear when needed" })
local extra = smart:Toggle("Show extra settings", { tip = "Turn on to reveal a group" })
local kind = smart:Dropdown("Shape", { "Circle", "Box" })
smart:Slider("Radius", { min = 1, max = 50, default = 10, showIf = function() return kind.Value == "Circle" end })
smart:Slider("Width", { min = 1, max = 50, default = 20, showIf = function() return kind.Value == "Box" end })
smart:Section("Extra")
smart:Toggle("Hidden toggle", { showIf = extra })
smart:Slider("Hidden slider", { showIf = extra })
smart:Section("Greyed out")
local fly = smart:Toggle("Fly", { tip = "Has a color on its row: click the swatch" })
fly:AddColor("Trail color", { default = "52D9A4" }, function(v) print("Trail", v:ToHex()) end)
smart:Slider("Fly speed", { min = 1, max = 100, default = 30, enabledIf = fly, reason = "Turn on Fly first" })

---------------------------------------------------------------- tabs, boxes without a switch
local more = ui:Category("More", { icon = "three-small-squares", color = "F48CD8" })
local main, extras = more:Tab("Main"), more:Tab("Extras")
local info = main:Group("Info", { tip = "A box with no switch" })
info:CopyText("Your user ID", Players.LocalPlayer.UserId)
info:Keybind("Wave key", { default = "G", tip = "Your script decides what the key does" }, function()
	ui:Notify("Key pressed", "The wave key", 2, "keyboard")
end)
local renamer = main:Module("Rename me", { tip = "Names and tips can change while it runs" })
local count = 0
renamer:Button("Rename this module", function()
	count += 1
	renamer:SetName("Renamed " .. count .. "x")
end)
extras:Module("On another tab", { tip = "Tabs split a big category" })

---------------------------------------------------------------- messages
local messages = ui:Category("Messages", { icon = "bell", color = "FF6F7D" })
local pop = messages:Module("Pop-ups", { icon = "bell", tip = "Notifications and dialogs" })
pop:Button("Notification", function() ui:Notify("Hello", "This is a notification", 4) end)
pop:Button("With icon and color", function() ui:Notify("Done", "Custom icon and color", 4, "check-large", Color3.fromHex("52D9A4")) end)
pop:Button("Question", function()
	ui:Dialog("Pick one", "A dialog can have any buttons.", { "Cancel", "Maybe", "Yes" }, function(choice)
		ui:Notify("You chose", choice, 3)
	end)
end)

---------------------------------------------------------------- keys
local keys = ui:Category("Keys", { icon = "keyboard", color = "B792FF" })
keys:Module("Toggle key", { key = "H", tip = "Press H" }, function(on) print("Toggle key", on) end)
keys:Module("Combination", { key = "LeftControl+H", tip = "Press Ctrl+H" }, function(on) print("Combination", on) end)
keys:Module("Mouse button", { key = "MouseButton3", tip = "Press the scroll wheel" }, function(on) print("Mouse button", on) end)
keys:Module("Hold key", { tip = "Open options, set a key, choose Hold" }, function(on) print("Hold key", on) end)

---------------------------------------------------------------- control from code
local code = ui:Category("Code", { icon = "code", color = "C2E35B" })
local c = code:Module("From code", { icon = "code", tip = "What your script can do itself" })
c:Button("Change the accent", function()
	ui:SetAccent(Color3.fromHSV(math.random(), 0.5, 1))
	ui:Notify("Accent", "Pick one in Settings to keep it", 3, "paint-brush")
end)
c:Button("Toggle the clock", function()
	clock:Set(not clock.On)
end)
c:Button("Close for 2 seconds", function()
	ui:SetOpen(false)
	task.wait(2)
	ui:SetOpen(true)
end)
c:Button("Switch to profile Showcase 2", { tip = "Made as a copy if it's new" }, function() ui:SetProfile("Showcase 2") end)
c:Button("Switch back to Default", function() ui:SetProfile("Default") end)
c:Button("Edit layout", { tip = "Drag the widgets around" }, function() ui:SetEditing(true) end)
c:Button("Light theme", function() ui:SetTheme("Light") end)
c:Button("Back to Graphite", function() ui:SetTheme("Graphite") end)
c:Button("Minimize", { tip = "Same as the minus button" }, function() ui:SetMinimized(true) end)
c:Button("Unload", { icon = "trash-can" }, function()
	ui:Dialog("Unload?", "Removes this window.", { "Cancel", "Unload" }, function(choice)
		if choice == "Unload" then
			ui:Destroy()
		end
	end)
end)

ui:Start()
ui:Notify("Welcome", "Right Shift opens and closes this window", 6, "hand-grip")
return ui
