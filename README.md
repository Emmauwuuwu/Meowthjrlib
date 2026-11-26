# Meowthjrlib

Made by meowthjr with Claude.

A GUI library for Roblox in one file, `Meowthjrlib.lua`. Fonts and icons are the ones bundled with Roblox, so nothing downloads. Interface only: no game features, and nothing that hides it from a game.

```lua
local Lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Emmauwuuwu/Meowthjrlib/main/Meowthjrlib.lua"))()
-- or, with the file in your workspace folder: loadstring(readfile("Meowthjrlib.lua"))()
local ui = Lib.new("My hub", { key = "RightShift", theme = "Midnight" })

local tools = ui:Category("Tools")
local timer = tools:Module("Timer", { key = "T", tip = "Shown on hover" }, function(on) end)
timer:Slider("Minutes", { min = 1, max = 60, default = 5, step = 1, suffix = " min" }, function(v) end)

ui:Start() -- last: loads the saved profile and opens the window
```

`showcase.lua` has one of everything; `example.lua` is a short start.

## Module options

`module:Kind(name, options, callback)`. Every kind takes `tip`, shown under its name, and `id`, which it saves under instead of its name, so you can rename it in your script without losing what people set. The result has `.Value`, `:Set(v)` and `:Reset()`.

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
| `Keybind` | `default`, `changed`. A key the user picks; the callback runs when it's pressed. `:IsDown()` says whether it's held |
| `PlayerDropdown` | like Dropdown, `includeSelf`. Keeps itself up to date as people join and leave |
| `CopyText(name, text)` | read-only text with a copy button. `:SetText(text)` |

Any kind takes `showIf` (hidden while false) and `enabledIf` (greyed out while false, with `reason` shown on hover): another option, or a function returning true or false. `:SetDisabled(true, reason)` greys one out from code.

Every setting has `:SetName(text)`, `:SetTip(text)` and `:Destroy()`. Its value keeps saving under the name it was made with.

`toggle:AddColor(name, options, callback)` puts a color swatch on the toggle's own row; clicking it opens the picker under the row.

Keys are Roblox key names, `MouseButton2`, `MouseButton3`, or a combination: `"LeftControl+F"` (also `LeftShift`, `LeftAlt`).

## The rest

- `category:Module(name, {default, key, icon, tip, toggle, id}, callback)`: `toggle = false`, or `category:Group(name)`, makes a box with no on/off switch. `icon` is a Builder Icons name such as `"sword"` or `"person-running"`, or an image ID. Without one, Meowthjrlib guesses from the name ("Clock" gets a clock) or uses the category's icon.
- `ui:Category(name, {icon, color})`: `color` is used only when Settings > Color style is "By category"; otherwise everything wears the accent
- `local main = category:Tab("Main")`, then `main:Module(...)`: a category with two or more tabs gets a strip to switch between them. Modules made on the category itself go on the first tab.
- `module:Loop(function(dt) end)`: runs every frame while the module is on.
- `module:Connect(signal, function() end)`: connected while the module is on, disconnected when it's off or unloaded.
- `module:Get("Speed")` or `module.Values.Speed`: a setting's value by name. `module.Values.Speed = 5` sets it.
- `module:Set(on)`, `module:SetKey("F")`, `module.On`, `module:SetName(text)`, `module:SetTip(text)`, `module:Destroy()`
- `module:Widget(function() return "text" end)`: on-screen text while the module is on
- `category:ActiveList()`, `category:KeyList()`, `category:Watermark()`, `category:KeyViewer()`: ready-made widgets. Roblox doesn't report side mouse buttons: have your mouse software send F13 and F14, then turn on Side buttons
- `ui:Dialog(title, text, {"Cancel", "OK"}, function(choice) end)`
- `Lib.new(title, {key, theme, accent, logo, intro})`: themes are Graphite, Mono, Obsidian, Midnight, Forest, Wine, Ocean and Light, or a table of colors. `accent` overrides the theme's accent. `logo` is an image ID for the corner of the window. `intro = "Loading..."` shows a short loading card before it opens.
- `ui:AddTheme(name, {Window, Fade, Panel, Tile, Menu, Field, Socket, Track, Knob, Text, Muted, accent})`: adds it to the Theme list. Missing colors come from Graphite; no two may be the same.
- `ui:SetMinimized(bool)`: folds the window to its header bar, like the − button. `ui:SetTheme(name)`, `ui:Notify(title, text, seconds, icon, color)`, `ui:SetAccent(color)`, `ui:SetOpen(bool)`, `ui:SetProfile(name)`, `ui:Export()`, `ui:Import(text)`
- `ui:Destroy()`: saves, calls every active module's callback with `false`, removes everything
- `ui:OnUnload(function() end)`: runs when the window is unloaded, after every module is off. Disconnect your own connections and remove your own parts there.

Misspelled option names (`defualt`, `mx`) and slider defaults outside min to max print a warning in the console. If you forget `ui:Start()`, the window starts itself after 3 seconds and says so.

Option callbacks run once at `Start` with their starting value. A module's callback runs at `Start` only if it starts on.

Callbacks are safe: if one errors, the rest of the window keeps working, a notification says which module and setting it came from, and the error with its traceback goes to the console. Each place reports at most once every 5 seconds.

Profiles save to `Meowthjrlib/<title>/` in the executor's workspace folder. Without file functions they last until you leave. A damaged profile is kept as `<name>.bad`.

## Using it

- Each category is a page of module boxes in two columns, every setting already showing. Click a box's title or switch to turn it on, right-click the title to favorite.
- The key chip on a box sets its key: click, then press a key. Right-click it to switch between Toggle and Hold.
- Right-click a setting to reset it. Click a slider's number to type one.
- − folds the window to its header bar, so it stays on screen and can still be dragged. Click it again to unfold. × hides the window.
- Drag the bottom-right corner to resize; right-click it to reset. Size and position are saved.
- Toggles and buttons have their own Set key.
- Ctrl+F searches modules and their settings.
- With a controller, Select opens the window (set another in Settings). Move with the D-pad, A presses, LB and RB move the selected slider.
- Settings has the open key, the gamepad open key, a theme, transparency (see the game through the window), the color style (one color by default, or a gem per category), the accent color, window size, dim, blur and reduced motion. Blur is off by default: it adds a `BlurEffect` to the camera, which the game can see.
- Edit layout: drag widgets, which snap to the edges and centre. Right-click resets one.

## Check

`loadstring(readfile("selfcheck.lua"))()(Lib)` uses memory storage, so it won't touch saved profiles.

## License

MIT, see `LICENSE`.
