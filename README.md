# Meowthjrlib

Made by meowthjr with Claude.

A tile GUI library for Roblox in one file, `Meowthjrlib.lua`. Fonts and icons are the ones bundled with Roblox, so nothing downloads. Interface only: no game features, and nothing that hides it from a game.

```lua
local Lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Emmauwuuwu/Meowthjrlib/main/Meowthjrlib.lua"))()
-- or, with the file in your workspace folder: loadstring(readfile("Meowthjrlib.lua"))()
local ui = Lib.new("My hub", { key = "RightShift", accent = "E8E5E0" })

local tools = ui:Category("Tools")
local timer = tools:Module("Timer", { key = "T", tip = "Shown on hover" }, function(on) end)
timer:Slider("Minutes", { min = 1, max = 60, default = 5, step = 1, suffix = " min" }, function(v) end)

ui:Start() -- last: loads the saved profile and opens the window
```

`example.lua` has one of everything.

## Module options

`module:Kind(name, options, callback)`. Every kind takes `tip`, shown under its name. The result has `.Value`, `:Set(v)` and `:Reset()`.

| Kind | Options |
|---|---|
| `Toggle` | `default`, `key` |
| `Slider` | `min`, `max`, `step`, `default`, `suffix` |
| `Range` | like Slider, `default = {low, high}`; the value is `{low, high}` |
| `Dropdown` | the choices as a list, `default`, `multi`. `:SetChoices(list)` replaces them; past 8 it gets a search box |
| `TextBox` | `default`, `max` (length), `lines`, `placeholder` |
| `Color` | `default` (Color3 or hex), `presets` (list of Color3), `alpha` (0 to 1; the callback gets `color, alpha`) |
| `Button` | `icon`, `key` |
| `Label(text, {rich = true})` | `:SetText(text)` |
| `Section(text)` | starts a titled group |
| `Progress(name)` | `:Update(0 to 1, text)` |
| `Image(id, height)` | |

Any kind takes `showIf`: another option (shown while it's on) or a function returning true or false.

Keys are Roblox key names, `MouseButton2`, `MouseButton3`, or a combination: `"LeftControl+F"` (also `LeftShift`, `LeftAlt`).

## The rest

- `category:Module(name, {default, key, icon, tip}, callback)`: `icon` is a Builder Icons name such as `"sword"` or `"person-running"`, or an image ID. Without one, Meowthjrlib guesses from the name ("Clock" gets a clock) or uses the category's icon.
- `ui:Category(name, {icon, color})`: `color` is used only when Settings > Color style is "By category"; otherwise everything wears the accent
- `module:Set(on)`, `module:SetKey("F")`, `module.On`
- `module:Widget(function() return "text" end)`: on-screen text while the module is on
- `category:ActiveList()`, `category:KeyList()`, `category:Watermark()`, `category:KeyViewer()`: ready-made widgets. Roblox doesn't report side mouse buttons: have your mouse software send F13 and F14, then turn on Side buttons
- `ui:Dialog(title, text, {"Cancel", "OK"}, function(choice) end)`
- `ui:Notify(title, text, seconds, icon, color)`, `ui:SetAccent(color)`, `ui:SetOpen(bool)`, `ui:SetProfile(name)`, `ui:Export()`, `ui:Import(text)`
- `ui:Destroy()`: saves, calls every active module's callback with `false`, removes everything

Option callbacks run once at `Start` with their starting value. A module's callback runs at `Start` only if it starts on.

Profiles save to `Meowthjrlib/<title>/` in the executor's workspace folder. Without file functions they last until you leave. A damaged profile is kept as `<name>.bad`.

## Using it

- Click a tile to toggle it, `⋯` for options, right-click to favorite.
- Right-click a setting to reset it. Click a slider's number to type one.
- Drag the bottom-right corner to resize; right-click it to reset. Size and position are saved.
- Toggles and buttons have their own Set key.
- Ctrl+F searches modules and their settings.
- The row of stones under the title is every module, lit when on. Click one to toggle it.
- Settings has the open key, the color style (one color by default, or a gem per category), the accent color, window size, dim, blur and reduced motion. Blur is off by default: it adds a `BlurEffect` to the camera, which the game can see.
- Edit layout: drag widgets, which snap to the edges and centre. Right-click resets one.

## Check

`loadstring(readfile("selfcheck.lua"))()(Lib)` uses memory storage, so it won't touch saved profiles.
