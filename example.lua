-- Demo: every module here only changes text inside the GUI.
local Lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Emmauwuuwu/Meowthjrlib/main/Meowthjrlib.lua"))()

local ui = Lib.new("Meowthjrlib", { key = "RightShift" })

local screen = ui:Category("Screen")
screen:Module("Clock", { default = true, tip = "Shows the time" }):Widget(function()
	return os.date("%H:%M:%S")
end)
local frames = 60
game:GetService("RunService").RenderStepped:Connect(function(dt)
	frames += (1 / math.max(dt, 1 / 1000) - frames) * 0.05
end)
screen:Module("FPS", { tip = "Shows frames per second" }):Widget(function()
	return math.round(frames) .. " fps"
end)
local note = screen:Module("Note", { tip = "Pins your own text on screen" })
local text = note:TextBox("Text", { default = "Hello" })
note:Widget(function()
	return text.Value
end)
screen:ActiveList()
screen:KeyList()
screen:Watermark()
screen:KeyViewer()

local timer = ui:Category("Tools"):Module("Timer", { key = "T" })
local minutes = timer:Slider("Minutes", { min = 1, max = 60, default = 5, suffix = " min", tip = "Click the number to type one" })
timer:Button("Test alert", function()
	ui:Notify("Timer", minutes.Value .. " minutes set")
end)

local demo = ui:Category("Demo")
local all = demo:Module("All options", { tip = "One of each option type" })
all:Label("Right-click any row to reset it.")
all:Toggle("Toggle", { default = true }, function(v) print("Toggle", v) end)
all:Slider("Slider", { min = 0, max = 2, step = 0.1, default = 1 }, function(v) print("Slider", v) end)
all:Dropdown("Mode", { "Smooth", "Instant", "Stepped" }, function(v) print("Mode", v) end)
all:Dropdown("Parts", { "Head", "Body", "Feet", multi = true, default = { "Body" } }, function(v) print("Parts", table.concat(v, ", ")) end)
all:TextBox("Name", { default = "Player" }, function(v) print("Name", v) end)
all:Color("Color", { default = "B23A6F" }, function(v) print("Color", v:ToHex()) end)
all:Button("Say hi", function() ui:Notify("Hi", "That button works") end)
all:Section("More kinds")
local custom = all:Toggle("Custom range", { tip = "Shows another setting under it" })
all:Range("Range", { min = 0, max = 100, default = { 20, 60 }, showIf = custom }, function(v) print("Range", v[1], v[2]) end)
all:Color("See-through color", { default = "52D9A4", alpha = 0.5 }, function(v, alpha) print("Color", v:ToHex(), alpha) end)
local fruit = all:Dropdown("Fruit", { "Apple", "Banana", "Cherry", "Fig", "Grape", "Kiwi", "Lemon", "Mango", "Orange", "Pear" })
all:TextBox("Notes", { lines = 3, placeholder = "Several lines" })
local bar = all:Progress("Progress")
bar:Update(0.4)
all:Label("Labels can be <b>bold</b> or <i>italic</i>.", { rich = true })
all:Button("Ask something", { key = "LeftControl+J" }, function()
	ui:Dialog("Pick one", "Dialogs can have any buttons.", { "Cancel", "Sure" }, function(choice) print("Dialog", choice) end)
end)
all:Button("Change the fruit list", function() fruit:SetChoices({ "Apple", "Plum" }) end)
for i = 1, 4 do
	demo:Module("Sample " .. i)
end

ui:Start()
return ui
