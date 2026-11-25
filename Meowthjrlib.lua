-- Meowthjrlib: a tile GUI library for Roblox. One file, no dependencies. See README.md.

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")

local C = {
	Window = Color3.fromHex("181716"),
	Fade = Color3.fromHex("131211"),
	Panel = Color3.fromHex("211F1E"),
	Tile = Color3.fromHex("2B2927"),
	Menu = Color3.fromHex("353331"),
	Field = Color3.fromHex("100F0E"),
	Socket = Color3.fromHex("403D3A"),
	Track = Color3.fromHex("474440"),
	Knob = Color3.fromHex("DCD9D5"),
	Text = Color3.fromHex("F7F5F2"),
	Muted = Color3.fromHex("ABA7A1"),
	Ink = Color3.fromHex("14120F"),
	Shade = Color3.fromHex("040404"),
	Danger = Color3.fromHex("FF8A8A"),
}
local DEFAULT_ACCENT = Color3.fromHex("E8E5E0")
local function hexes(...)
	local out = {}
	for i, h in { ... } do
		out[i] = Color3.fromHex(h)
	end
	return out
end
local PRESETS = hexes("E8E5E0", "E3C07E", "FF9F4F", "FF6F7D", "F48CD8", "B792FF", "52D9A4", "C2E35B")
-- Ruby, emerald, amethyst, amber, orchid, peridot: one per category when "By category" is on.
local JEWELS = hexes("FF6F7D", "52D9A4", "B792FF", "FF9F4F", "F48CD8", "C2E35B")
-- Earlier versions saved their default accent as if it had been picked.
local OLD_DEFAULTS = { ["2f62d9"] = true, ["8fb4ff"] = true, ["f4c04f"] = true }

-- All bundled with Roblox, so nothing has to download.
local SANS = "rbxasset://fonts/families/BuilderSans.json"
local ICONS = "rbxasset://LuaPackages/Packages/_Index/BuilderIcons/BuilderIcons/BuilderIcons.json"
local F = {
	body = Font.new(SANS, Enum.FontWeight.Regular),
	medium = Font.new(SANS, Enum.FontWeight.Medium),
	bold = Font.new(SANS, Enum.FontWeight.Bold),
	head = Font.new("rbxasset://fonts/families/BuilderExtended.json", Enum.FontWeight.Bold),
	icon = Font.new(ICONS, Enum.FontWeight.Regular),
	iconFill = Font.new(ICONS, Enum.FontWeight.Bold),
}

-- Icons picked from a word in the name when the script doesn't give one.
local GUESS = {
	movement = "person-running", sprint = "person-running", run = "person-running", walk = "person-walking", jump = "person-jumping",
	glide = "paper-airplane", camera = "photo-camera", zoom = "magnifying-glass-plus", look = "eye", visual = "eye", visuals = "eye",
	view = "eye", night = "moon-with-stars", light = "sun", lighting = "sun", brightness = "sun", screen = "computer-monitor",
	hud = "computer-monitor", clock = "clock", time = "clock", timer = "bell-clock", fps = "speedometer", speed = "speedometer",
	ping = "wifi-signal-good", note = "three-ring-note", notes = "three-ring-note", chat = "two-speech-bubbles", list = "list-bulleted",
	tools = "hammer-code", tool = "hammer-code", utility = "hammer-code", world = "globe-simplified", player = "person", players = "two-people",
	misc = "three-small-squares", other = "three-small-squares", demo = "lab-beaker", music = "music-note", sound = "speaker",
	crosshair = "crosshairs", position = "location-pin", coordinates = "location-pin", inventory = "backpack", combat = "sword",
	settings = "gear", options = "two-sliders-horizontal", color = "paint-brush", theme = "paint-brush", sample = "cube",
	weather = "cloud", keys = "keyboard", friends = "two-people", profile = "bookmark", building = "cube",
}

local WIDTH, HEIGHT, SIDE = 772, 512, 190
local TILE_H, GAP = 110, 12
local MIN_W, MIN_H = 600, 400

local Lib = {}
local UI, Category, Module, Option = {}, {}, {}, {}
UI.__index, Category.__index, Module.__index, Option.__index = UI, Category, Module, Option

---------------------------------------------------------------- helpers

local function make(class, props, parent)
	local o = Instance.new(class)
	if o:IsA("GuiObject") then
		o.BorderSizePixel = 0
	end
	if class == "TextLabel" or class == "TextButton" or class == "TextBox" then
		o.FontFace, o.TextSize, o.TextColor3 = F.body, 15, C.Text
		o.Text = ""
	end
	if class == "TextButton" then
		o.AutoButtonColor = false
	end
	for k, v in props do
		o[k] = v
	end
	o.Parent = parent
	return o
end

local function corner(o, r)
	make("UICorner", { CornerRadius = UDim.new(0, r) }, o)
	return o
end

-- The hairline every raised surface gets.
local function line(o)
	return make("UIStroke", { Color = C.Text, Transparency = 0.92, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, o)
end

local function pad(o, x, y)
	make("UIPadding", {
		PaddingLeft = UDim.new(0, x), PaddingRight = UDim.new(0, x),
		PaddingTop = UDim.new(0, y), PaddingBottom = UDim.new(0, y),
	}, o)
	return o
end

local function list(o, gap, dir)
	return make("UIListLayout", {
		Padding = UDim.new(0, gap), SortOrder = Enum.SortOrder.LayoutOrder, FillDirection = dir or Enum.FillDirection.Vertical,
	}, o)
end

local function label(parent, text, props)
	local l = make("TextLabel", {
		BackgroundTransparency = 1, Text = text, Size = UDim2.fromScale(1, 1),
		TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
	}, parent)
	for k, v in props or {} do
		l[k] = v
	end
	return l
end

-- name is a Builder Icons name, an image ID or an rbxasset URL.
local function icon(parent, name, size, props)
	local o
	if tonumber(name) or name:match("^rbx") then
		o = make("ImageLabel", { BackgroundTransparency = 1, Image = tonumber(name) and "rbxassetid://" .. name or name, ScaleType = Enum.ScaleType.Fit }, parent)
	else
		o = make("TextLabel", { BackgroundTransparency = 1, FontFace = F.icon, Text = name, TextSize = size }, parent)
	end
	o.Size = UDim2.fromOffset(size, size)
	for k, v in props or {} do
		if k == "TextColor3" and o:IsA("ImageLabel") then
			k = "ImageColor3"
		end
		o[k] = v
	end
	return o
end

local function guessIcon(name, fallback)
	for word in name:lower():gmatch("%a+") do
		if GUESS[word] then
			return GUESS[word]
		end
	end
	return fallback
end

local function tbl(v)
	return type(v) == "table" and v or {}
end

local function isPress(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

local function keyCode(name)
	local ok, code = pcall(function()
		return Enum.KeyCode[name]
	end)
	return ok and code ~= Enum.KeyCode.Unknown and code or nil
end

-- A bind is a key or mouse button, with modifiers in front: "F", "LeftControl+F", "MouseButton3".
local MOD_ORDER = { "LeftControl", "LeftShift", "LeftAlt" }
local MODS = { LeftControl = "Ctrl", LeftShift = "Shift", LeftAlt = "Alt" }
local MOUSE = { MouseButton2 = "Mouse 2", MouseButton3 = "Mouse 3" }

local function validBind(s)
	if type(s) ~= "string" then
		return false
	end
	local parts = s:split("+")
	local last = table.remove(parts)
	for _, p in parts do
		if not MODS[p] then
			return false
		end
	end
	return last ~= "Escape" and last ~= "Backspace" and (MOUSE[last] ~= nil or keyCode(last) ~= nil)
end

local function prettyBind(s)
	local out = {}
	for i, p in s:split("+") do
		out[i] = MODS[p] or MOUSE[p] or p
	end
	return table.concat(out, "+")
end

local function inputName(i)
	if i.UserInputType == Enum.UserInputType.Keyboard then
		return i.KeyCode.Name
	end
	return MOUSE[i.UserInputType.Name] and i.UserInputType.Name or nil
end

local function withMods(name)
	local out = ""
	for _, m in MOD_ORDER do
		if m ~= name and UIS:IsKeyDown(Enum.KeyCode[m]) then
			out ..= m .. "+"
		end
	end
	return out .. name
end

local function contrast(a, b)
	local function lum(c)
		local function f(v)
			return v <= 0.03928 and v / 12.92 or ((v + 0.055) / 1.055) ^ 2.4
		end
		return 0.2126 * f(c.R) + 0.7152 * f(c.G) + 0.0722 * f(c.B) + 0.05
	end
	local x, y = lum(a), lum(b)
	return math.max(x, y) / math.min(x, y)
end

-- The accent has to light up against the dark surfaces: black, for example, becomes silver.
local function visible(c)
	while contrast(c, C.Tile) < 6.5 do
		c = c:Lerp(Color3.new(1, 1, 1), 0.06)
	end
	return c
end

local function inkOn(c)
	return contrast(C.Ink, c) >= contrast(C.Text, c) and C.Ink or C.Text
end

local function toColor(v)
	if typeof(v) == "Color3" then
		return v
	end
	if type(v) == "string" then
		local ok, c = pcall(Color3.fromHex, v)
		return ok and c or nil
	end
	return nil
end

local function cleanName(s)
	s = tostring(s):gsub("[^%w %-_]", ""):gsub("^[%s_]+", ""):gsub("%s+$", ""):sub(1, 24)
	return s
end

---------------------------------------------------------------- storage

-- Saves to the executor's workspace folder, or to memory where the file functions don't exist.
local function makeStore(title)
	local folder = "Meowthjrlib/" .. cleanName(title)
	if not (writefile and readfile and isfile and delfile and listfiles and makefolder and isfolder) then
		local mem = {}
		return {
			Disk = false,
			read = function(f) return mem[f] end,
			write = function(f, s) mem[f] = s return true end,
			delete = function(f) mem[f] = nil end,
			list = function()
				local out = {}
				for f in mem do
					table.insert(out, f)
				end
				return out
			end,
		}
	end
	local function path(f)
		return folder .. "/" .. f
	end
	pcall(function()
		for _, f in { "Meowthjrlib", folder } do
			if not isfolder(f) then
				makefolder(f)
			end
		end
	end)
	return {
		Disk = true,
		read = function(f)
			local ok, s = pcall(function()
				return isfile(path(f)) and readfile(path(f)) or nil
			end)
			return ok and s or nil
		end,
		write = function(f, s) return (pcall(writefile, path(f), s)) end,
		delete = function(f) pcall(delfile, path(f)) end,
		list = function()
			local ok, files = pcall(listfiles, folder)
			local out = {}
			for _, p in ok and files or {} do
				table.insert(out, p:match("([^/\\]+)$"))
			end
			return out
		end,
	}
end

---------------------------------------------------------------- UI: motion and input

function UI:_tween(o, time_, props, style, dir)
	if self.ReducedMotion then
		time_ = 0
	end
	local t = TweenService:Create(o, TweenInfo.new(time_, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

function UI:_on(signal, fn)
	table.insert(self._conns, signal:Connect(fn))
end

-- Fades a surface in while the pointer is over b.
function UI:_hover(b, surface, rest, over)
	surface.BackgroundTransparency = rest
	b.MouseEnter:Connect(function()
		self:_tween(surface, 0.12, { BackgroundTransparency = over })
	end)
	b.MouseLeave:Connect(function()
		self:_tween(surface, 0.24, { BackgroundTransparency = rest })
	end)
end

-- One global drag at a time: sliders, the window and widgets all use this.
function UI:_drag(input, onMove, onDone)
	self._dragging = { input = input, move = onMove, done = onDone }
	if self._pageList then
		self._pageList.ScrollingEnabled = false
	end
end

-- Runs fn now, or when the current drag ends if doing it now would disturb that drag.
function UI:_settle(id, fn)
	if self._dragging then
		self._afterDrag[id] = fn
	else
		fn()
	end
end

function UI:_endDrag()
	local d = self._dragging
	self._dragging = nil
	local after = self._afterDrag
	self._afterDrag = {}
	for _, fn in after do
		fn()
	end
	if self._pageList then
		self._pageList.ScrollingEnabled = true
	end
	if d and d.done then
		d.done()
	end
end

-- A quiet button: no surface until you point at it.
function UI:_ghost(parent, props, onClick)
	local b = corner(make("TextButton", { BackgroundColor3 = C.Text, FontFace = F.medium }, parent), 8)
	for k, v in props do
		b[k] = v
	end
	self:_hover(b, b, 1, 0.93)
	b.Activated:Connect(onClick)
	return b
end

-- rest, if given, returns the icon's resting color.
function UI:_iconButton(parent, name, tip, props, onClick, rest)
	local b = self:_ghost(parent, { Size = UDim2.fromOffset(34, 34) }, onClick)
	for k, v in props or {} do
		b[k] = v
	end
	local i = icon(b, name, 20, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), TextColor3 = C.Muted })
	b.MouseEnter:Connect(function()
		local c = rest and rest() or C.Muted
		self:_tween(i, 0.12, { TextColor3 = c == C.Muted and C.Text or c })
	end)
	b.MouseLeave:Connect(function()
		self:_tween(i, 0.24, { TextColor3 = rest and rest() or C.Muted })
	end)
	self:_tip(b, tip)
	return b, i
end

-- First click asks, second click within 3 seconds does it.
local function confirm(b, arm, disarm, fn)
	local armed = false
	b.Activated:Connect(function()
		if armed then
			armed = false
			fn()
			return
		end
		armed = true
		arm()
		task.delay(3, function()
			if armed and b.Parent then
				armed = false
				disarm()
			end
		end)
	end)
end

function UI:_hideTip()
	self._tipFor = nil
	self._tipLabel.Visible = false
end

function UI:_tip(b, text)
	if not text then
		return
	end
	b.MouseEnter:Connect(function()
		self._tipFor = b
		task.delay(0.45, function()
			if self._tipFor == b and not self.Dead and b:IsDescendantOf(self.Gui) then
				self._tipLabel.Text = text
				self._tipLabel.Visible = true
				self._tipScale.Scale = 0.9
				self:_tween(self._tipScale, 0.18, { Scale = 1 })
			end
		end)
	end)
	local function hide()
		if self._tipFor == b then
			self:_hideTip()
		end
	end
	b.MouseLeave:Connect(hide)
	b.Destroying:Connect(hide)
end

---------------------------------------------------------------- surfaces

local WHITE, BLACK = Color3.new(1, 1, 1), Color3.new()

-- Shading that works over any color: lit from the top left, deeper at the bottom right.
local function shade(o, depth)
	return make("UIGradient", { Rotation = 60, Color = ColorSequence.new(WHITE, Color3.new(1 - depth, 1 - depth, 1 - depth)) }, o)
end

local function gloss(parent, radius)
	local g = corner(make("Frame", { BackgroundColor3 = WHITE, Size = UDim2.fromScale(1, 0.55), ZIndex = 2 }, parent), radius)
	make("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(0, 1) }, g)
	g.BackgroundTransparency = 0.96
	return g
end

-- A soft glow: stacked rounded frames behind a surface. Returns a painter(color or nil, time).
local function halo(ui, parent, radius, layers, step, alpha)
	local box = make("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 0 }, parent)
	local rings = {}
	for i = 1, layers do
		rings[i] = corner(make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1,
			Size = UDim2.new(1, i * step * 2, 1, i * step * 2),
		}, box), radius + i * step)
	end
	return function(color, time_)
		for _, r in rings do
			if color then
				r.BackgroundColor3 = color
			end
			ui:_tween(r, time_ or 0.35, { BackgroundTransparency = color and alpha or 1 })
		end
	end
end

-- Round light made of stacked discs; Roblox has no radial gradient.
local function orb(parent, color, radius, alpha)
	local box = make("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(radius * 2, radius * 2) }, parent)
	local discs = {}
	-- Few enough discs that each is a visible step; fainter ones round to a color cast.
	for i = 1, 9 do
		local d = make("Frame", {
			BackgroundColor3 = color, BackgroundTransparency = alpha, AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(i / 9, i / 9),
		}, box)
		make("UICorner", { CornerRadius = UDim.new(1, 0) }, d)
		discs[i] = d
	end
	return box, discs
end

-- A big ghosted icon cropped inside its surface.
local function ghost(parent, name, size, inset)
	local clip = make("Frame", { BackgroundTransparency = 1, ClipsDescendants = true, Position = UDim2.fromOffset(1, 1), Size = UDim2.new(1, -2, 1, -2), ZIndex = 1 }, parent)
	local g = icon(clip, name, size, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -inset, 0.5, 8), Rotation = -14 })
	if g:IsA("TextLabel") then
		g.FontFace = F.iconFill
	end
	return g
end

local function fadeProp(o)
	return o:IsA("ImageLabel") and "ImageTransparency" or "TextTransparency"
end

local function colorProp(o)
	return o:IsA("ImageLabel") and "ImageColor3" or "TextColor3"
end

-- Floods b with color from a point, or drains it back. done() runs when it settles.
function UI:_flood(b, radius, depth, color, on, at, done)
	local size = b.AbsoluteSize / self:_scaleNow()
	at = at or size / 2
	local reach = 2 * Vector2.new(math.max(at.X, size.X - at.X), math.max(at.Y, size.Y - at.Y)).Magnitude
	local layer = corner(make("CanvasGroup", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 0 }, b), radius)
	shade(layer, depth)
	local disc = make("Frame", { BackgroundColor3 = color, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(at.X, at.Y) }, layer)
	make("UICorner", { CornerRadius = UDim.new(1, 0) }, disc)
	disc.Size = UDim2.fromOffset(on and 0 or reach, on and 0 or reach)
	local t = self:_tween(disc, on and 0.55 or 0.36, { Size = UDim2.fromOffset(on and reach or 0, on and reach or 0) })
	t.Completed:Connect(function()
		done(layer)
	end)
	return layer
end

-- A glint of light crossing a gem.
function UI:_glint(b, radius)
	if self.ReducedMotion or not self.Open then
		return
	end
	local layer = corner(make("CanvasGroup", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 4 }, b), radius)
	local bar = make("Frame", { BackgroundColor3 = WHITE, AnchorPoint = Vector2.new(0.5, 0.5), Rotation = 22, Size = UDim2.new(0, 54, 2.4, 0), Position = UDim2.new(0, -70, 0.5, 0) }, layer)
	make("UIGradient", { Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.5), NumberSequenceKeypoint.new(1, 1),
	}) }, bar)
	self:_tween(bar, 0.85, { Position = UDim2.new(1, 70, 0.5, 0) }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut).Completed:Connect(function()
		layer:Destroy()
	end)
end

-- The color a module wears, and the text color that reads on it.
function Module:_tint()
	local ui = self.UI
	local c = ui.Jewels and not self.Hidden and ui._cats[self.Category].Color or ui.Accent
	return c, inkOn(c)
end

---------------------------------------------------------------- options

local HAS_VALUE = { Toggle = true, Slider = true, Dropdown = true, TextBox = true, Color = true, Key = true, Range = true }

local coerce = {}
function coerce.Toggle(_, v)
	if type(v) == "boolean" then
		return v
	end
	return nil
end
function coerce.Slider(o, v)
	if type(v) ~= "number" or v ~= v then
		return nil
	end
	v = math.clamp(v, o.Min, o.Max)
	v = o.Min + math.round((v - o.Min) / o.Step) * o.Step
	v = math.clamp(v, o.Min, o.Max)
	return tonumber(string.format("%.4f", v))
end
function coerce.Range(o, v)
	if type(v) ~= "table" then
		return nil
	end
	local a, b = coerce.Slider(o, v[1]), coerce.Slider(o, v[2])
	if not a or not b then
		return nil
	end
	return { math.min(a, b), math.max(a, b) }
end
function coerce.Dropdown(o, v)
	if not o.Multi then
		return table.find(o.Choices, v) and v or nil
	end
	if type(v) ~= "table" then
		return nil
	end
	local out = {}
	for _, c in o.Choices do
		if table.find(v, c) then
			table.insert(out, c)
		end
	end
	return out
end
function coerce.TextBox(o, v)
	return type(v) == "string" and v:sub(1, o.Max) or nil
end
function coerce.Key(_, v)
	return validBind(v) and v or nil
end
function coerce.Color(_, v)
	return toColor(v)
end

local function same(a, b)
	if type(a) == "table" and type(b) == "table" then
		return table.concat(a, "\0") == table.concat(b, "\0")
	end
	return a == b
end

function Option:_changed()
	local m = self.Module
	if self._paint then
		self._paint()
	end
	if self.Callback then
		task.spawn(self.Callback, self.Value, self.Alpha)
	end
	if m.UI._page == m then
		m.UI:_refreshRows()
	end
	m.UI:_save()
end

function Option:Set(v, force)
	v = coerce[self.Kind](self, v)
	if v == nil or (same(v, self.Value) and not force) then
		return
	end
	self._want = nil
	self.Value = v
	self:_changed()
end

-- Opacity of a Color made with alpha: 1 is solid, 0 is invisible.
function Option:SetAlpha(a)
	if self.Alpha and type(a) == "number" and a == a then
		self.Alpha = math.clamp(math.round(a * 100) / 100, 0, 1)
		self:_changed()
	end
end

-- Replaces a dropdown's choices. The current or saved choice is kept if it's in the new list.
function Option:SetChoices(choices)
	assert(self.Kind == "Dropdown", "SetChoices is for dropdowns")
	self.Choices = table.clone(choices)
	local want = self._want
	if want == nil then
		want = self.Value
	end
	local v = coerce.Dropdown(self, want)
	if v == nil and not self.Multi then
		v = self.Choices[1]
		-- Remember a choice that isn't here right now, so it comes back when it is.
		self._want = want
	else
		self._want = self.Multi and type(want) == "table" and #v < #want and want or nil
	end
	local changed = not same(v, self.Value)
	self.Value = v
	if self._rebuild then
		self._rebuild()
	end
	if changed then
		self:_changed()
	end
end

-- Binds a key to a Toggle or Button.
function Option:SetKey(key)
	if (self.Kind ~= "Toggle" and self.Kind ~= "Button") or (key ~= nil and not validBind(key)) then
		return
	end
	self.Key = key
	if self._paint then
		self._paint()
	end
	self.Module.UI:_save()
end

function Option:_press()
	if self.Kind == "Toggle" then
		self:Set(not self.Value)
	elseif self.Callback then
		task.spawn(self.Callback)
	end
end

function Option:Reset()
	if self.Alpha then
		self.Alpha = self.DefaultAlpha
		self:Set(self.Default, true)
		return
	end
	self:Set(self.Default)
end

function Option:_shown()
	local f = self.ShowIf
	if f == nil then
		return true
	end
	if type(f) == "table" then
		return f.Value and f.Value ~= "" or false
	end
	local ok, v = pcall(f)
	return not ok or v and true or false
end

function Option:_dump()
	if self._want ~= nil then
		return self._want
	end
	local v = typeof(self.Value) == "Color3" and self.Value:ToHex() or self.Value
	return self.Alpha and { v, self.Alpha } or v
end

-- Applies a saved value, falling back to the default when it isn't valid.
function Option:_load(v, force)
	self._want = nil
	if self.Alpha then
		self.Alpha = self.DefaultAlpha
		if type(v) == "table" then
			self.Alpha = type(v[2]) == "number" and math.clamp(v[2], 0, 1) or self.DefaultAlpha
			v = v[1]
		end
		force = true
	end
	local good = v ~= nil and coerce[self.Kind](self, v) or nil
	if v ~= nil and good == nil and self.Kind ~= "Toggle" or type(v) == "table" and self.Kind == "Dropdown" and self.Multi and good and #good < #v then
		local keep = self.Kind == "Dropdown" and v or nil
		self:Set(good == nil and self.Default or good, force)
		self._want = keep
		return
	end
	if v == nil or coerce[self.Kind](self, v) == nil then
		v = self.Default
	end
	self:Set(v, force)
end

function Module:_option(kind, name, opts, cb)
	if type(opts) == "function" then
		opts, cb = {}, opts
	end
	opts = opts or {}
	assert(type(name) == "string", kind .. " needs a name")
	assert(not self._byName[name], "Duplicate option '" .. name .. "' in " .. self.Name)
	local o = setmetatable({ Kind = kind, Name = name, Module = self, Callback = cb, Tip = opts.tip, Icon = opts.icon, Presets = opts.presets, ShowIf = opts.showIf }, Option)
	if kind == "Toggle" or kind == "Button" then
		assert(opts.key == nil or validBind(opts.key), "Unknown key '" .. tostring(opts.key) .. "'")
		o.Key, o.DefaultKey = opts.key, opts.key
	elseif kind == "Color" and opts.alpha ~= nil then
		o.Alpha = type(opts.alpha) == "number" and math.clamp(opts.alpha, 0, 1) or 1
		o.DefaultAlpha = o.Alpha
	end
	if kind == "Slider" or kind == "Range" then
		o.Min, o.Max, o.Step, o.Suffix = opts.min or 0, opts.max or 100, opts.step or 1, opts.suffix or ""
		assert(o.Max > o.Min and o.Step > 0, kind .. " '" .. name .. "' needs max > min and step > 0")
	elseif kind == "TextBox" then
		o.Max, o.Lines, o.Placeholder = opts.max or 500, opts.lines or 1, opts.placeholder or "Type here"
	elseif kind == "Dropdown" then
		o.Choices, o.Multi = {}, opts.multi == true
		for i, c in ipairs(opts) do
			o.Choices[i] = c
		end
	end
	if HAS_VALUE[kind] then
		local fallback = { Toggle = false, Slider = o.Min, Dropdown = o.Multi and {} or (o.Choices and o.Choices[1]), TextBox = "", Color = DEFAULT_ACCENT, Range = { o.Min, o.Max } }
		local d = opts.default
		if d == nil then
			d = fallback[kind]
		end
		o.Default = coerce[kind](o, d)
		assert(o.Default ~= nil or (kind == "Dropdown" and #o.Choices == 0), "Bad default for '" .. name .. "'")
		o.Value = o.Default
	end
	self._byName[name] = o
	table.insert(self.Options, o)
	-- Options added after Start pick up their saved value straight away.
	if self.UI._started and HAS_VALUE[kind] then
		o:_load(tbl(tbl(tbl(self.UI._data.modules)[self.Id]).opts)[name], true)
	end
	return o
end

for _, kind in { "Toggle", "Slider", "Dropdown", "TextBox", "Color", "Button", "Range" } do
	Module[kind] = function(self, name, opts, cb)
		return self:_option(kind, name, opts, cb)
	end
end

function Module:Label(text, opts)
	local o = self:_option("Label", "label" .. #self.Options, opts)
	o.Text, o.Rich = text, opts and opts.rich == true
	function o.SetText(_, t)
		o.Text = t
		if o._paint then
			o._paint()
		end
	end
	return o
end

-- Starts a new titled group of settings.
function Module:Section(text)
	local o = self:_option("Section", "section" .. #self.Options)
	o.Text = text
	return o
end

-- o:Update(0..1, "text") moves the bar.
function Module:Progress(name, opts)
	local o = self:_option("Progress", name, opts)
	o.Value, o.Text = 0, ""
	function o.Update(_, x, text)
		o.Value = type(x) == "number" and x == x and math.clamp(x, 0, 1) or 0
		o.Text = text or math.round(o.Value * 100) .. "%"
		if o._paint then
			o._paint()
		end
	end
	return o
end

function Module:Image(id, height, opts)
	local o = self:_option("Image", "image" .. #self.Options, opts)
	o.Image, o.Height = tonumber(id) and "rbxassetid://" .. id or id, height or 140
	return o
end

---------------------------------------------------------------- option rows

local ROW = 48

-- A rounded group that rows sit in, separated by hairlines.
local function panel(parent)
	local p = corner(make("Frame", { BackgroundColor3 = C.Panel, Size = UDim2.fromScale(1, 0), AutomaticSize = Enum.AutomaticSize.Y }, parent), 12)
	shade(p, 0.12)
	line(p)
	list(p, 0)
	return p
end

local function divider(b)
	make("Frame", { BackgroundColor3 = C.Text, BackgroundTransparency = 0.94, Position = UDim2.fromOffset(16, 0), Size = UDim2.new(1, -32, 0, 1) }, b)
end

-- room is the width the control on the right needs, so the hint can use the rest.
local function baseRow(ui, parent, name, tip, height, room)
	height = height or ROW
	if tip then
		height += 16
	end
	local first = parent:FindFirstChildWhichIsA("GuiObject") == nil
	local b = make("TextButton", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, height) }, parent)
	if not first then
		divider(b)
	end
	local glow = corner(make("Frame", { BackgroundColor3 = C.Text, BackgroundTransparency = 1, Position = UDim2.fromOffset(4, 4), Size = UDim2.new(1, -8, 1, -8) }, b), 8)
	ui:_hover(b, glow, 1, 0.965)
	label(b, name, { FontFace = F.medium, TextSize = 16, Position = UDim2.fromOffset(16, tip and 9 or 0), Size = UDim2.new(0.6, -16, 0, tip and 18 or ROW) })
	if tip then
		label(b, tip, { TextColor3 = C.Muted, TextSize = 13, Position = UDim2.fromOffset(16, 29), Size = UDim2.new(1, -16 - (room or 80), 0, 16) })
	end
	return b, height
end

local function resettable(b, o)
	b.MouseButton2Click:Connect(function()
		o:Reset()
	end)
end

-- colors() returns the pill and knob colors for when it is on.
local function switch(ui, parent, props, colors)
	local pill = corner(make("Frame", { Size = UDim2.fromOffset(40, 24), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -16, 0.5, 0) }, parent), 12)
	for k, v in props or {} do
		pill[k] = v
	end
	local knob = corner(make("Frame", { Size = UDim2.fromOffset(18, 18), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0) }, pill), 9)
	local shown
	return function(on)
		if on == nil then
			shown = nil
			return
		end
		local lit, dot = colors()
		local t = shown == nil and 0 or 0.28
		if shown ~= nil and shown ~= on and not ui.ReducedMotion then
			-- The knob stretches as it travels, then settles.
			knob.Size = UDim2.fromOffset(24, 18)
		end
		shown = on
		ui:_tween(pill, t, { BackgroundColor3 = on and lit or C.Track })
		ui:_tween(knob, t, {
			Position = UDim2.new(0, on and 19 or 3, 0.5, 0), Size = UDim2.fromOffset(18, 18),
			BackgroundColor3 = on and dot or C.Knob,
		})
	end, pill
end

local function keycap(parent, props)
	local cap = corner(make("TextLabel", {
		BackgroundColor3 = C.Field, FontFace = F.medium, TextSize = 13, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 24),
	}, parent), 6)
	make("UISizeConstraint", { MinSize = Vector2.new(10, 0) }, cap)
	pad(cap, 8, 0)
	local stroke = line(cap)
	for k, v in props or {} do
		cap[k] = v
	end
	return cap, stroke
end

local function segments(ui, parent, choices, props, pick)
	local n = #choices
	local box = corner(make("Frame", { BackgroundColor3 = C.Field, Size = UDim2.fromOffset(76 * n, 32), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -16, 0.5, 0) }, parent), 8)
	for k, v in props or {} do
		box[k] = v
	end
	local thumb = corner(make("Frame", { BackgroundColor3 = C.Tile, Size = UDim2.new(1 / n, -6, 1, -6), Position = UDim2.fromOffset(3, 3) }, box), 6)
	line(thumb)
	local buttons = {}
	for i, c in choices do
		local b = make("TextButton", { BackgroundTransparency = 1, Text = c, TextSize = 14, FontFace = F.medium, Position = UDim2.fromScale((i - 1) / n, 0), Size = UDim2.fromScale(1 / n, 1), ZIndex = 2 }, box)
		b.Activated:Connect(function()
			pick(c)
		end)
		buttons[i] = b
	end
	return function(value)
		for i, c in choices do
			ui:_tween(buttons[i], 0.2, { TextColor3 = c == value and C.Text or C.Muted })
			if c == value then
				ui:_tween(thumb, 0.26, { Position = UDim2.new((i - 1) / n, 3, 0, 3) })
			end
		end
	end
end

-- Pressing anywhere on `hit` drags. set() receives x and y as 0..1 of `ref`.
local function dragArea(ui, hit, ref, set, onHold)
	hit.InputBegan:Connect(function(i)
		if not isPress(i) then
			return
		end
		local function move(pos)
			local at, size = ref.AbsolutePosition, ref.AbsoluteSize
			set(math.clamp((pos.X - at.X) / math.max(1, size.X), 0, 1), math.clamp((pos.Y - at.Y) / math.max(1, size.Y), 0, 1))
		end
		if onHold then
			onHold(true)
		end
		move(i.Position)
		ui:_drag(i, move, onHold and function()
			onHold(false)
		end)
	end)
end

-- A row with a drawer under it that slides open.
-- Returns the row, the drawer, and a function that changes the drawer's height.
local function drawer(ui, parent, name, tip, contentHeight)
	local first = parent:FindFirstChildWhichIsA("GuiObject") == nil
	local box = make("Frame", { BackgroundTransparency = 1, ClipsDescendants = true }, parent)
	local b, h = baseRow(ui, box, name, tip, nil, 180)
	box.Size = UDim2.new(1, 0, 0, h)
	if not first then
		divider(box)
	end
	local inner = make("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(16, h), Size = UDim2.new(1, -32, 0, contentHeight) }, box)
	local arrow = icon(b, "chevron-small-down", 18, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), TextColor3 = C.Muted })
	local open = false
	b.Activated:Connect(function()
		open = not open
		ui:_tween(box, 0.3, { Size = UDim2.new(1, 0, 0, open and h + contentHeight + 14 or h) })
		ui:_tween(arrow, 0.3, { Rotation = open and 180 or 0 })
	end)
	return b, inner, function(height)
		contentHeight = height
		inner.Size = UDim2.new(1, -32, 0, height)
		if open then
			ui:_tween(box, 0.2, { Size = UDim2.new(1, 0, 0, h + height + 14) })
		end
	end
end

local render = {}

-- The small key button on a Toggle or Button row. Returns its painter.
local function bindChip(ui, b, o, right)
	if o.Module.Hidden then
		return function() end
	end
	local chip = corner(make("TextButton", {
		BackgroundColor3 = C.Field, FontFace = F.medium, TextSize = 13, AutomaticSize = Enum.AutomaticSize.X,
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -right, 0.5, 0), Size = UDim2.fromOffset(0, 26), ZIndex = 3,
	}, b), 6)
	pad(chip, 8, 0)
	ui:_tip(chip, "Click, then press a key. Backspace clears it.")
	chip.Activated:Connect(function()
		ui:_listen(o)
	end)
	return function()
		local live = ui._listening == o
		local c, ink = o.Module:_tint()
		chip.Text = live and "Press a key" or o.Key and prettyBind(o.Key) or "Set key"
		chip.TextColor3 = live and ink or o.Key and C.Text or C.Muted
		chip.BackgroundColor3 = live and c or C.Field
		chip.BackgroundTransparency = (live or o.Key) and 0 or 1
	end
end

function render.Toggle(ui, o, parent)
	local b = baseRow(ui, parent, o.Name, o.Tip, nil, 150)
	local chip = bindChip(ui, b, o, 66)
	local paint = switch(ui, b, nil, function()
		return o.Module:_tint()
	end)
	o._paint = function()
		paint(o.Value)
		chip()
	end
	b.Activated:Connect(function()
		o:Set(not o.Value)
	end)
	resettable(b, o)
end

function render.Slider(ui, o, parent)
	local b, h = baseRow(ui, parent, o.Name, o.Tip, 62, 16)
	local box = corner(make("TextBox", {
		BackgroundColor3 = C.Field, BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -9, 0, o.Tip and 5 or 11),
		Size = UDim2.fromOffset(76, 26), FontFace = F.medium, TextColor3 = C.Text, TextXAlignment = Enum.TextXAlignment.Right, ClearTextOnFocus = true, ZIndex = 2,
	}, b), 6)
	pad(box, 7, 0)
	ui:_hover(box, box, 1, 0)
	local track = corner(make("Frame", { BackgroundColor3 = C.Track, Position = UDim2.new(0, 16, 0, h - 18), Size = UDim2.new(1, -32, 0, 6) }, b), 3)
	local fill = corner(make("Frame", { Size = UDim2.fromScale(0, 1) }, track), 3)
	make("UIGradient", { Color = ColorSequence.new(Color3.new(0.62, 0.62, 0.62), WHITE) }, fill)
	local knob = make("Frame", { BackgroundColor3 = C.Text, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(12, 12) }, track)
	make("UICorner", { CornerRadius = UDim.new(1, 0) }, knob)
	local ring = make("UIStroke", { Thickness = 3 }, knob)
	local held, over = false, false
	local function grow()
		local d = held and 16 or over and 14 or 12
		ui:_tween(knob, 0.18, { Size = UDim2.fromOffset(d, d) })
	end
	b.MouseEnter:Connect(function()
		over = true
		grow()
	end)
	b.MouseLeave:Connect(function()
		over = false
		grow()
	end)
	dragArea(ui, b, track, function(x)
		o:Set(o.Min + x * (o.Max - o.Min))
	end, function(v)
		held = v
		grow()
	end)
	local shown = false
	o._paint = function()
		local x = (o.Value - o.Min) / (o.Max - o.Min)
		box.Text = string.format("%g", o.Value) .. o.Suffix
		local c = o.Module:_tint()
		fill.BackgroundColor3, ring.Color = c, c
		local t = shown and 0.1 or 0
		shown = true
		ui:_tween(fill, t, { Size = UDim2.fromScale(x, 1) })
		ui:_tween(knob, t, { Position = UDim2.fromScale(x, 0.5) })
	end
	box.FocusLost:Connect(function()
		o:Set(tonumber((box.Text:gsub("[^%d%.%-]", ""))))
		o._paint()
	end)
	resettable(b, o)
end

function render.Dropdown(ui, o, parent)
	local b, inner, resize = drawer(ui, parent, o.Name, o.Tip, 0)
	local value = label(b, "", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -40, 0, 0), Size = UDim2.new(0.5, -40, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = C.Muted,
	})
	local search = ui:_field(inner, { Size = UDim2.new(1, 0, 0, 34), PlaceholderText = "Search choices", Visible = false })
	pad(search, 10, 0)
	local rows = make("ScrollingFrame", {
		BackgroundTransparency = 1, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3, ScrollBarImageColor3 = C.Muted, ScrollingDirection = Enum.ScrollingDirection.Y,
	}, inner)
	list(rows, 0)
	local paints, items = {}, {}
	local function filter()
		local q, n = search.Text:lower(), 0
		for _, it in items do
			it.row.Visible = q == "" or it.text:find(q, 1, true) ~= nil
			n += it.row.Visible and 1 or 0
		end
		local top = search.Visible and 42 or 0
		local h = math.min(n, 6) * 38
		rows.Position, rows.Size = UDim2.fromOffset(0, top), UDim2.new(1, 0, 0, h)
		resize(top + h)
	end
	o._rebuild = function()
		for _, it in items do
			it.row:Destroy()
		end
		paints, items = {}, {}
		search.Visible = #o.Choices > 8
		if not search.Visible then
			search.Text = ""
		end
		for _, choice in o.Choices do
			local row = corner(make("TextButton", { BackgroundColor3 = C.Text, BackgroundTransparency = 1, Size = UDim2.new(1, -6, 0, 38) }, rows), 8)
			ui:_hover(row, row, 1, 0.95)
			local text = label(row, tostring(choice), { Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -48, 1, 0) })
			local check = icon(row, "check-large", 18, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0) })
			local scale = make("UIScale", {}, check)
			table.insert(items, { row = row, text = tostring(choice):lower() })
			table.insert(paints, function()
				local on = o.Value == choice or (o.Multi and table.find(o.Value, choice) ~= nil)
				check.TextColor3 = o.Module:_tint()
				text.FontFace = on and F.medium or F.body
				ui:_tween(text, 0.16, { TextColor3 = on and C.Text or C.Muted })
				ui:_tween(check, 0.16, { TextTransparency = on and 0 or 1 })
				ui:_tween(scale, 0.26, { Scale = on and 1 or 0.4 }, Enum.EasingStyle.Back)
			end)
			row.Activated:Connect(function()
				if not o.Multi then
					o:Set(choice)
					return
				end
				local new = table.clone(o.Value)
				local at = table.find(new, choice)
				if at then
					table.remove(new, at)
				else
					table.insert(new, choice)
				end
				o:Set(new)
			end)
		end
		filter()
		if o._paint then
			o._paint()
		end
	end
	search:GetPropertyChangedSignal("Text"):Connect(filter)
	o._paint = function()
		if o.Multi then
			value.Text = #o.Value == 0 and "None" or table.concat(o.Value, ", ")
		else
			value.Text = o.Value == nil and "None" or tostring(o.Value)
		end
		for _, p in paints do
			p()
		end
	end
	o._rebuild()
	resettable(b, o)
end

function render.Range(ui, o, parent)
	local b, h = baseRow(ui, parent, o.Name, o.Tip, 62, 16)
	local value = label(b, "", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, o.Tip and 5 or 11), Size = UDim2.fromOffset(140, 26),
		FontFace = F.medium, TextXAlignment = Enum.TextXAlignment.Right,
	})
	local track = corner(make("Frame", { BackgroundColor3 = C.Track, Position = UDim2.new(0, 16, 0, h - 18), Size = UDim2.new(1, -32, 0, 6) }, b), 3)
	local fill = corner(make("Frame", {}, track), 3)
	local knobs, rings = {}, {}
	for i = 1, 2 do
		knobs[i] = make("Frame", { BackgroundColor3 = C.Text, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(12, 12) }, track)
		make("UICorner", { CornerRadius = UDim.new(1, 0) }, knobs[i])
		rings[i] = make("UIStroke", { Thickness = 3 }, knobs[i])
	end
	local function at(i)
		return (o.Value[i] - o.Min) / (o.Max - o.Min)
	end
	local grabbed
	dragArea(ui, b, track, function(x)
		if not grabbed then
			local mid = (at(1) + at(2)) / 2
			grabbed = x == mid and 2 or x < mid and 1 or 2
		end
		local v = o.Min + x * (o.Max - o.Min)
		-- The ends stop at each other instead of swapping.
		if grabbed == 1 then
			o:Set({ math.min(v, o.Value[2]), o.Value[2] })
		else
			o:Set({ o.Value[1], math.max(v, o.Value[1]) })
		end
	end, function()
		grabbed = nil
	end)
	o._paint = function()
		local c = o.Module:_tint()
		value.Text = string.format("%g – %g", o.Value[1], o.Value[2]) .. o.Suffix
		fill.BackgroundColor3 = c
		ui:_tween(fill, 0.1, { Position = UDim2.fromScale(at(1), 0), Size = UDim2.fromScale(at(2) - at(1), 1) })
		for i = 1, 2 do
			rings[i].Color = c
			ui:_tween(knobs[i], 0.1, { Position = UDim2.fromScale(at(i), 0.5) })
		end
	end
	resettable(b, o)
end

function render.Progress(ui, o, parent)
	local b, h = baseRow(ui, parent, o.Name, o.Tip, 62, 16)
	local value = label(b, "", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, o.Tip and 5 or 11), Size = UDim2.fromOffset(160, 26),
		TextColor3 = C.Muted, TextXAlignment = Enum.TextXAlignment.Right,
	})
	local track = corner(make("Frame", { BackgroundColor3 = C.Track, Position = UDim2.new(0, 16, 0, h - 18), Size = UDim2.new(1, -32, 0, 6) }, b), 3)
	local fill = corner(make("Frame", { Size = UDim2.fromScale(0, 1) }, track), 3)
	o._paint = function()
		value.Text = o.Text
		fill.BackgroundColor3 = o.Module:_tint()
		ui:_tween(fill, 0.3, { Size = UDim2.fromScale(o.Value, 1) })
	end
end

function render.Image(_, o, parent)
	local holder = make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, o.Height + 24) }, parent)
	corner(make("ImageLabel", { BackgroundTransparency = 1, Image = o.Image, ScaleType = Enum.ScaleType.Fit, Position = UDim2.fromOffset(16, 12), Size = UDim2.new(1, -32, 1, -24) }, holder), 8)
end

function UI:_field(parent, props)
	local box = corner(make("TextBox", {
		BackgroundColor3 = C.Field, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, TextSize = 15,
		PlaceholderColor3 = C.Muted, TextTruncate = Enum.TextTruncate.AtEnd, ClipsDescendants = true,
	}, parent), 8)
	for k, v in props or {} do
		box[k] = v
	end
	local stroke = line(box)
	box.Focused:Connect(function()
		self:_tween(stroke, 0.16, { Color = self.Accent, Transparency = 0.2 })
	end)
	box.FocusLost:Connect(function()
		self:_tween(stroke, 0.2, { Color = C.Text, Transparency = 0.92 })
	end)
	return box
end

function render.TextBox(ui, o, parent)
	local many = o.Lines > 1
	local tall = many and o.Lines * 18 + 16 or 0
	local b, h = baseRow(ui, parent, o.Name, o.Tip, nil, many and 16 or 220)
	local box
	if many then
		b.Size = UDim2.new(1, 0, 0, h + tall + 10)
		box = ui:_field(b, {
			Position = UDim2.fromOffset(16, h - 4), Size = UDim2.new(1, -32, 0, tall), MultiLine = true, TextWrapped = true,
			TextYAlignment = Enum.TextYAlignment.Top, TextTruncate = Enum.TextTruncate.None,
		})
		pad(box, 10, 8)
	else
		box = ui:_field(b, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -16, 0.5, 0), Size = UDim2.fromOffset(190, 32) })
		pad(box, 10, 0)
	end
	box.PlaceholderText = o.Placeholder
	o._paint = function()
		box.Text = o.Value
	end
	box.FocusLost:Connect(function()
		o:Set(box.Text)
		if o._paint then
			o._paint()
		end
	end)
	b.Activated:Connect(function()
		box:CaptureFocus()
	end)
	resettable(b, o)
end

local RAINBOW = {}
for i = 0, 6 do
	RAINBOW[i + 1] = ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i % 6 / 6, 1, 1))
end

function render.Color(ui, o, parent)
	local extra = o.Presets and 48 or 0
	local b, inner = drawer(ui, parent, o.Name, o.Tip, 158 + extra + (o.Alpha and 26 or 0))
	local swatch = corner(make("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -42, 0.5, 0), Size = UDim2.fromOffset(34, 20) }, b), 6)
	line(swatch)
	local hex = make("TextBox", {
		BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -86, 0.5, 0), Size = UDim2.fromOffset(76, 28),
		TextColor3 = C.Muted, TextXAlignment = Enum.TextXAlignment.Right, ClearTextOnFocus = false, ZIndex = 2,
	}, b)
	hex.FocusLost:Connect(function()
		o:Set((hex.Text:gsub("[^%x]", "")))
		o._paint()
	end)

	if o.Presets then
		local row = make("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 2), Size = UDim2.new(1, 0, 0, 28) }, inner)
		list(row, 10, Enum.FillDirection.Horizontal)
		for _, p in o.Presets do
			local dot = corner(make("TextButton", { BackgroundColor3 = p, Size = UDim2.fromOffset(28, 28) }, row), 14)
			local scale = make("UIScale", {}, dot)
			dot.MouseEnter:Connect(function()
				ui:_tween(scale, 0.16, { Scale = 1.12 })
			end)
			dot.MouseLeave:Connect(function()
				ui:_tween(scale, 0.16, { Scale = 1 })
			end)
			dot.Activated:Connect(function()
				o:Set(p)
			end)
		end
	end

	-- Hue as the base color, white washing in from the left and black rising from the bottom.
	local area = corner(make("TextButton", { Position = UDim2.fromOffset(0, extra), Size = UDim2.new(1, 0, 0, 124) }, inner), 8)
	for _, shade in { { Color3.new(1, 1, 1), 0, 0 }, { Color3.new(), 90, 1 } } do
		local f = corner(make("Frame", { BackgroundColor3 = shade[1], Size = UDim2.fromScale(1, 1) }, area), 8)
		make("UIGradient", { Rotation = shade[2], Transparency = NumberSequence.new(shade[3], 1 - shade[3]) }, f)
	end
	local strip = corner(make("TextButton", { BackgroundColor3 = Color3.new(1, 1, 1), Position = UDim2.fromOffset(0, extra + 138), Size = UDim2.new(1, 0, 0, 12) }, inner), 6)
	make("UIGradient", { Color = ColorSequence.new(RAINBOW) }, strip)
	local function ring(parent_)
		local r = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(18, 18), ZIndex = 3 }, parent_)
		make("UICorner", { CornerRadius = UDim.new(1, 0) }, r)
		make("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 3 }, r)
		return r
	end
	local dotArea, dotHue = ring(area), ring(strip)
	local fade, dotFade
	if o.Alpha then
		fade = corner(make("TextButton", { BackgroundColor3 = WHITE, Position = UDim2.fromOffset(0, extra + 164), Size = UDim2.new(1, 0, 0, 12) }, inner), 6)
		line(fade)
		make("UIGradient", { Transparency = NumberSequence.new(1, 0) }, fade)
		dotFade = ring(fade)
		dragArea(ui, fade, fade, function(x)
			o:SetAlpha(x)
		end)
	end

	-- Kept outside the color so hue survives while saturation or brightness is 0.
	local hsv, last = { o.Value:ToHSV() }, o.Value
	local function push()
		last = Color3.fromHSV(hsv[1], hsv[2], hsv[3])
		o:Set(last, true)
	end
	dragArea(ui, area, area, function(x, y)
		hsv[2], hsv[3] = x, 1 - y
		push()
	end)
	dragArea(ui, strip, strip, function(x)
		hsv[1] = x
		push()
	end)
	o._paint = function()
		if o.Value ~= last then
			hsv, last = { o.Value:ToHSV() }, o.Value
		end
		local pure = Color3.fromHSV(hsv[1], 1, 1)
		swatch.BackgroundColor3, dotArea.BackgroundColor3 = o.Value, o.Value
		area.BackgroundColor3, dotHue.BackgroundColor3 = pure, pure
		dotArea.Position = UDim2.fromScale(hsv[2], 1 - hsv[3])
		dotHue.Position = UDim2.fromScale(hsv[1], 0.5)
		hex.Text = "#" .. o.Value:ToHex():upper()
		if fade then
			fade.BackgroundColor3, dotFade.BackgroundColor3 = o.Value, o.Value
			dotFade.Position = UDim2.fromScale(o.Alpha, 0.5)
			swatch.BackgroundTransparency = 1 - o.Alpha
		end
	end
	resettable(b, o)
end

function render.Key(ui, o, parent)
	local b = baseRow(ui, parent, o.Name, o.Tip, nil, 130)
	local cap = keycap(b, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -16, 0.5, 0), Size = UDim2.fromOffset(0, 28), TextSize = 14 })
	o._paint = function()
		local live = ui._listening == o
		local c, ink = o.Module:_tint()
		cap.Text = live and "Press a key" or prettyBind(o.Value)
		ui:_tween(cap, 0.2, { BackgroundColor3 = live and c or C.Field, TextColor3 = live and ink or C.Text })
	end
	-- No right-click reset: right-click can be the key being set.
	b.Activated:Connect(function()
		ui:_listen(o)
	end)
end

function render.Button(ui, o, parent)
	local b = baseRow(ui, parent, o.Name, o.Tip, nil, 130)
	local chip = bindChip(ui, b, o, 42)
	o._paint = chip
	local arrow = icon(b, o.Icon or "chevron-small-right", 18, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), TextColor3 = C.Muted })
	b.Activated:Connect(function()
		arrow.Position, arrow[colorProp(arrow)] = UDim2.new(1, -8, 0.5, 0), (o.Module:_tint())
		ui:_tween(arrow, 0.45, { Position = UDim2.new(1, -14, 0.5, 0), [colorProp(arrow)] = C.Muted }, Enum.EasingStyle.Back)
		if o.Callback then
			task.spawn(o.Callback)
		end
	end)
end

function render.Label(_, o, parent)
	local holder = make("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 0), AutomaticSize = Enum.AutomaticSize.Y }, parent)
	pad(holder, 16, 14)
	local l = label(holder, "", {
		Size = UDim2.fromScale(1, 0), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true, TextSize = 14,
		TextTruncate = Enum.TextTruncate.None, TextColor3 = C.Muted,
	})
	l.RichText = o.Rich
	o._paint = function()
		l.Text = o.Text
	end
end

---------------------------------------------------------------- modules

function Module:Set(on, force)
	on = on == true
	if on == self.On and not force then
		return
	end
	self.On = on
	self:_repaint()
	if self._widget then
		self:_paintWidget()
	end
	if self.Callback then
		task.spawn(self.Callback, on)
	end
	if self.UI._started and not self.UI._loading and self.UI.NotifyToggles then
		self.UI:Notify(self.Name, on and "On" or "Off", 1.5, self.Icon, (self:_tint()))
	end
	if not self.UI._loading then
		self.UI:_paintHeader()
	end
	self.UI:_save()
end

function Module:Toggle_()
	self:Set(not self.On)
end

function Module:SetKey(name)
	if name ~= nil and not validBind(name) then
		return
	end
	self.Key = name
	self:_repaint()
	self.UI:_save()
end

function Module:SetFavorite(v)
	self.Favorite = v
	self:_repaint()
	self.UI:_filter()
	self.UI:_save()
end

function Module:_repaint()
	if self._paintCard then
		self._paintCard()
	end
	if self._paintPage then
		self._paintPage()
	end
end

-- Puts a draggable label on screen while the module is on. fn returns its text.
function Module:Widget(fn)
	assert(type(fn) == "function", "Widget needs a function that returns text")
	local ui = self.UI
	self._widgetFn = fn
	-- A label, not a button, so it never eats game clicks outside Edit layout.
	local w = corner(make("TextLabel", {
		AutomaticSize = Enum.AutomaticSize.XY, BackgroundColor3 = C.Window, BackgroundTransparency = 0.12, FontFace = F.medium,
		LineHeight = 1.15, TextXAlignment = Enum.TextXAlignment.Left, Visible = false, Active = false,
	}, ui._hud), 9)
	make("UIPadding", { PaddingLeft = UDim.new(0, 36), PaddingRight = UDim.new(0, 13), PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8) }, w)
	self._widgetIcon = icon(w, self.Icon, 18, { Position = UDim2.fromOffset(-25, 0) })
	if self._widgetIcon:IsA("TextLabel") then
		self._widgetIcon.FontFace = F.iconFill
	end
	return self:_setWidget(w)
end

-- Makes w draggable in Edit layout and ties it to this module.
function Module:_setWidget(w)
	local ui = self.UI
	self._widgetHome = Vector2.new(0.02, 0.15 + (#ui._widgets % 9) * 0.09)
	local stroke = line(w)
	local scale = make("UIScale", {}, w)
	self._widget, self._widgetScale, self._widgetStroke = w, scale, stroke
	self:_placeWidget(self._widgetHome)
	w.InputBegan:Connect(function(i)
		if not ui._editing then
			return
		end
		if i.UserInputType == Enum.UserInputType.MouseButton2 then
			self:_placeWidget(self._widgetHome)
			ui:_save()
		end
		if not isPress(i) then
			return
		end
		local from, start = self._widgetPos, i.Position
		ui:_tween(scale, 0.12, { Scale = 1.05 })
		ui:_drag(i, function(pos)
			self:_placeWidget(ui:_snap(w, from + Vector2.new(pos.X - start.X, pos.Y - start.Y) / ui._hud.AbsoluteSize))
		end, function()
			ui:_showGuides(nil, nil)
			ui:_tween(scale, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
			ui:_save()
		end)
	end)
	table.insert(ui._widgets, self)
	if ui._started then
		local p = tbl(tbl(tbl(ui._data.modules)[self.Id]).pos)
		if type(p[1]) == "number" and type(p[2]) == "number" then
			self:_placeWidget(Vector2.new(p[1], p[2]))
		end
		self:_paintWidget()
	end
	return self
end

-- Positions are a fraction of the screen, so a layout survives a resolution change.
function Module:_placeWidget(p)
	local screen = self.UI._hud.AbsoluteSize
	-- Before the first layout the screen size is 0, and clamping would throw the saved position away.
	local room = screen.X < 10 and Vector2.one or Vector2.one - self._widget.AbsoluteSize / screen
	p = Vector2.new(math.clamp(p.X, 0, math.max(0, room.X)), math.clamp(p.Y, 0, math.max(0, room.Y)))
	self._widgetPos = p
	self._widget.Position = UDim2.fromScale(p.X, p.Y)
end

function Module:_updateWidget()
	if not self._widgetFn then
		self._widget.Visible = self.On
		return
	end
	local ok, text = pcall(self._widgetFn)
	text = ok and tostring(text) or "Error"
	if text == "" and self.UI._editing then
		text = self.Name
	end
	self._widget.Text = text
	self._widget.Visible = self.On and text ~= ""
end

function Module:_paintWidget()
	local was = self._widget.Visible
	self:_updateWidget()
	if self._widget.Visible and not was then
		self._widgetScale.Scale = 0.8
		self.UI:_tween(self._widgetScale, 0.28, { Scale = 1 }, Enum.EasingStyle.Back)
	end
	local editing = self.UI._editing
	local c = self:_tint()
	self._widgetStroke.Color = c
	if self._widgetIcon then
		self._widgetIcon[colorProp(self._widgetIcon)] = c
	else
		self._widgetRepaint()
	end
	self.UI:_tween(self._widgetStroke, 0.2, { Transparency = editing and 0 or self._widgetIcon and 0.65 or 1, Thickness = editing and 2 or 1 })
end

function Category:Module(name, opts, cb)
	if type(opts) == "function" then
		opts, cb = {}, opts
	end
	opts = opts or {}
	local ui = self.UI
	local id = self.Name .. "/" .. name
	assert(not ui._byId[id], "Duplicate module '" .. id .. "'")
	assert(opts.key == nil or validBind(opts.key), "Unknown key '" .. tostring(opts.key) .. "'")
	local m = setmetatable({
		Name = name, Id = id, Category = self.Name, UI = ui, Callback = cb, Options = {}, _byName = {},
		On = false, Default = opts.default == true, Key = opts.key, DefaultKey = opts.key,
		KeyMode = "Toggle", Favorite = false, Icon = opts.icon or guessIcon(name, self.Icon), Tip = opts.tip, Hidden = self.Hidden,
	}, Module)
	ui._byId[id] = m
	table.insert(ui.Modules, m)
	m._order = #ui.Modules
	if not m.Hidden then
		ui:_buildCard(m)
	end
	if ui._started then
		ui:_loadModule(m, true)
		ui:_filter()
	end
	return m
end

-- A widget listing every key and what it does.
function Category:KeyList(name)
	return self:Module(name or "Key list", { icon = "keyboard", tip = "Shows every key you've set" }):Widget(function()
		local out = {}
		self.UI:_binds(function(x, isOption)
			if x.Key then
				local on = isOption and (x.Kind == "Toggle" and x.Value) or not isOption and x.On
				table.insert(out, prettyBind(x.Key) .. "   " .. x.Name .. (on and "   On" or ""))
			end
		end)
		return table.concat(out, "\n")
	end)
end

-- WASD, Space and the mouse buttons on screen, lighting up as they're pressed.
function Category:KeyViewer(name)
	local ui = self.UI
	local m = self:Module(name or "Key viewer", { icon = "keyboard", tip = "Shows the keys you press" })
	local box = corner(make("Frame", { BackgroundTransparency = 1, Visible = false, Active = false }, ui._hud), 9)
	local caps = {}
	local relayout = function() end
	local function changed()
		relayout()
	end

	m:Section("Keys")
	local space = m:Toggle("Space", { default = true }, changed)
	local mouse = m:Toggle("Mouse buttons", { default = true }, changed)
	local cps = m:Toggle("Clicks per second", { default = true, showIf = mouse }, changed)
	local side = m:Toggle("Side buttons", { tip = "Your mouse software must send the keys below" }, changed)
	local backKey = m:_option("Key", "Back button sends", { default = "F13", showIf = side })
	local forwardKey = m:_option("Key", "Forward button sends", { default = "F14", showIf = side })
	-- Only watched, so the same key may also run a module.
	backKey.Shared, forwardKey.Shared = true, true
	m:Section("Look")
	local size = m:Slider("Size", { min = 60, max = 180, step = 5, default = 100, suffix = "%" }, changed)
	local solid = m:Slider("Background", { min = 0, max = 100, step = 5, default = 80, suffix = "%" }, changed)
	local own = m:Toggle("Own color", {}, changed)
	local pick = m:Color("Pressed color", { default = DEFAULT_ACCENT, showIf = own, presets = PRESETS }, changed)

	local function tint()
		if own.Value then
			return pick.Value, inkOn(pick.Value)
		end
		return m:_tint()
	end
	local function paint(cap, time_)
		local c, ink = tint()
		local t = time_ or (cap.down and 0.05 or 0.22)
		ui:_tween(cap.frame, t, { BackgroundColor3 = cap.down and c or C.Window, BackgroundTransparency = cap.down and 0.05 or 1 - solid.Value / 100 })
		ui:_tween(cap.text, t, { TextColor3 = cap.down and ink or C.Text })
		ui:_tween(cap.sub, t, { TextColor3 = cap.down and ink or C.Muted })
		ui:_tween(cap.scale, cap.down and 0.05 or 0.25, { Scale = cap.down and 0.93 or 1 }, cap.down and Enum.EasingStyle.Quint or Enum.EasingStyle.Back)
		if cap.bar then
			ui:_tween(cap.bar, t, { BackgroundColor3 = cap.down and ink or C.Text })
		end
	end
	local function add(id, text, x, y, w, h, held, shown)
		local f = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5) }, box)
		local cap = {
			id = id, frame = f, round = make("UICorner", {}, f), x = x, y = y, w = w, h = h, held = held, shown = shown,
			down = false, clicks = {}, scale = make("UIScale", {}, f),
			text = label(f, text, { FontFace = F.bold, TextXAlignment = Enum.TextXAlignment.Center }),
			sub = label(f, "", { TextXAlignment = Enum.TextXAlignment.Center, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 0.92), Size = UDim2.fromScale(1, 0.34) }),
		}
		line(f).Transparency = 0.86
		if id == "Space" then
			cap.bar = corner(make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.4, 0.12) }, f), 2)
		end
		table.insert(caps, cap)
	end
	-- Keys don't light up while you type in chat or a text box.
	local function key(code)
		return function()
			return not UIS:GetFocusedTextBox() and UIS:IsKeyDown(code)
		end
	end
	local function button(kind)
		return function()
			return UIS:IsMouseButtonPressed(kind)
		end
	end
	-- A bind may name a mouse button or a combination; its last part is what gets watched.
	local function bound(o)
		return function()
			local last = o.Value:match("[^%+]+$")
			return MOUSE[last] and button(Enum.UserInputType[last])() or not MOUSE[last] and key(Enum.KeyCode[last])()
		end
	end
	local function always()
		return true
	end
	local function ifOn(o)
		return function()
			return o.Value
		end
	end
	-- Units: one key is 1 wide, and rows sit under each other.
	add("W", "W", 1, 1, 1, 1, key(Enum.KeyCode.W), always)
	add("A", "A", 0, 2, 1, 1, key(Enum.KeyCode.A), always)
	add("S", "S", 1, 2, 1, 1, key(Enum.KeyCode.S), always)
	add("D", "D", 2, 2, 1, 1, key(Enum.KeyCode.D), always)
	add("LMB", "LMB", 0, 3, 1.5, 1, button(Enum.UserInputType.MouseButton1), ifOn(mouse))
	add("RMB", "RMB", 1.5, 3, 1.5, 1, button(Enum.UserInputType.MouseButton2), ifOn(mouse))
	add("Back", "Back", 0, 4, 1.5, 0.75, bound(backKey), ifOn(side))
	add("Forward", "Fwd", 1.5, 4, 1.5, 0.75, bound(forwardKey), ifOn(side))
	add("Space", "", 0, 5, 3, 0.6, key(Enum.KeyCode.Space), ifOn(space))

	relayout = function()
		local unit, gap = 46 * size.Value / 100, 5 * size.Value / 100
		local y, row, rowHeight = 0, nil, 0
		for _, cap in caps do
			cap.frame.Visible = cap.shown()
			if cap.frame.Visible then
				if cap.y ~= row then
					y += row and rowHeight + gap or 0
					row, rowHeight = cap.y, cap.h * unit
				end
				local w = cap.w * unit + (cap.w - 1) * gap
				cap.frame.Size = UDim2.fromOffset(w, rowHeight)
				cap.frame.Position = UDim2.fromOffset(cap.x * (unit + gap) + w / 2, y + rowHeight / 2)
				cap.round.CornerRadius = UDim.new(0, math.round(unit * 0.2))
				cap.sub.Visible = cps.Value and (cap.id == "LMB" or cap.id == "RMB")
				cap.text.Position = UDim2.fromScale(0, cap.sub.Visible and 0.06 or 0)
				cap.text.Size = UDim2.fromScale(1, cap.sub.Visible and 0.56 or 1)
				cap.text.TextSize, cap.sub.TextSize = math.round(unit * (#cap.text.Text > 1 and 0.32 or 0.4)), math.round(unit * 0.25)
				paint(cap, 0)
			end
		end
		box.Size = UDim2.fromOffset(3 * unit + 2 * gap, y + rowHeight)
	end
	relayout()
	m._widgetRepaint = relayout
	m._widgetTick = function()
		local now = os.clock()
		for _, cap in caps do
			if cap.frame.Visible then
				local down = cap.held()
				if down ~= cap.down then
					cap.down = down
					if down then
						table.insert(cap.clicks, now)
					end
					paint(cap)
				end
				while cap.clicks[1] and now - cap.clicks[1] > 1 do
					table.remove(cap.clicks, 1)
				end
				if cap.sub.Visible then
					cap.sub.Text = #cap.clicks .. " cps"
				end
			end
		end
	end
	return m:_setWidget(box)
end

-- A widget with the window's title, frame rate and ping.
function Category:Watermark(name)
	return self:Module(name or "Watermark", { icon = "circle-i", tip = "Shows FPS and ping" }):Widget(function()
		return string.format("%s   %d fps   %d ms", self.UI.Title, math.round(self.UI._fps), math.round(Players.LocalPlayer:GetNetworkPing() * 1000))
	end)
end

-- A ready-made widget listing every module that is on.
function Category:ActiveList(name)
	local m
	m = self:Module(name or "Active list", { tip = "Shows every module that is on" }):Widget(function()
		local on = {}
		for _, x in self.UI.Modules do
			if x.On and x ~= m and not x.Hidden then
				table.insert(on, x.Name)
			end
		end
		return table.concat(on, "\n")
	end)
	return m
end

---------------------------------------------------------------- profiles

function UI:_loadModule(m, force)
	local s = tbl(tbl(self._data.modules)[m.Id])
	local opts = tbl(s.opts)
	for _, o in m.Options do
		if HAS_VALUE[o.Kind] then
			o:_load(opts[o.Name], force)
		end
		if o.Kind == "Toggle" or o.Kind == "Button" then
			local k = tbl(s.optKeys)[o.Name]
			o.Key = k ~= false and (validBind(k) and k or o.DefaultKey) or nil
		end
	end
	if s.key == false then
		m.Key = nil
	else
		m.Key = validBind(s.key) and s.key or m.DefaultKey
	end
	m.KeyMode = s.mode == "Hold" and "Hold" or "Toggle"
	m.Favorite = s.fav == true
	if m._widget then
		local p = tbl(s.pos)
		m:_placeWidget(type(p[1]) == "number" and type(p[2]) == "number" and Vector2.new(p[1], p[2]) or m._widgetHome)
	end
	local on = m.Default
	if type(s.on) == "boolean" then
		on = s.on
	end
	-- Nothing to turn off on the first load, so only call back for modules that start on.
	m:Set(on, force and on)
	m:_repaint()
end

function UI:_apply(force)
	self._loading = true
	local w = tbl(self._data.window)
	local good = true
	for i = 1, 4 do
		good = good and type(w[i]) == "number" and math.abs(w[i]) < 1e5
	end
	self._rootPos = good and Vector2.new(w[1], w[2]) or Vector2.zero
	self._size = good and Vector2.new(math.max(w[3], MIN_W), math.max(w[4], MIN_H)) or Vector2.new(WIDTH, HEIGHT)
	self:_layout()
	for _, m in self.Modules do
		self:_loadModule(m, force)
	end
	self._loading = false
	self:_filter()
	if self._page then
		self:_openPage(self._page, true)
	end
end

function UI:_read(name)
	local raw = self._store.read(name .. ".json")
	if not raw then
		return {}
	end
	local ok, d = pcall(HttpService.JSONDecode, HttpService, raw)
	if ok and type(d) == "table" then
		local opts = tbl(tbl(tbl(d.modules)["_/Settings"]).opts)
		if OLD_DEFAULTS[opts.Accent] then
			opts.Accent = nil
		end
		return d
	end
	self._store.write(name .. ".bad", raw)
	self:Notify("Profile damaged", "Kept a copy as " .. name .. ".bad and loaded defaults", 6, "triangle-exclamation")
	return {}
end

function UI:_snapshot()
	local d = self._data
	d.modules = tbl(d.modules)
	d.window = { self._rootPos.X, self._rootPos.Y, self._size.X, self._size.Y }
	for _, m in self.Modules do
		local s = tbl(d.modules[m.Id])
		s.on, s.key, s.mode, s.fav, s.opts = m.On, m.Key or false, m.KeyMode, m.Favorite, tbl(s.opts)
		for _, o in m.Options do
			if HAS_VALUE[o.Kind] then
				s.opts[o.Name] = o:_dump()
			end
			if not m.Hidden and (o.Kind == "Toggle" or o.Kind == "Button") then
				s.optKeys = tbl(s.optKeys)
				s.optKeys[o.Name] = o.Key or false
			end
		end
		if m._widget then
			s.pos = { m._widgetPos.X, m._widgetPos.Y }
		end
		d.modules[m.Id] = s
	end
	return HttpService:JSONEncode(d)
end

function UI:SaveNow()
	local ok = self._store.write(self.Profile .. ".json", self:_snapshot()) and self._store.write("_active.txt", self.Profile)
	if not ok and not self._saveWarned then
		self._saveWarned = true
		self:Notify("Not saved", "Couldn't write the profile file", 6, "triangle-exclamation")
	end
	return ok
end

function UI:_save()
	if not self._started or self._loading or self._saveQueued or self.Dead then
		return
	end
	self._saveQueued = true
	task.delay(1, function()
		self._saveQueued = false
		if not self.Dead then
			self:SaveNow()
		end
	end)
end

function UI:Profiles()
	local out, seen = {}, {}
	local files = self._store.list()
	table.insert(files, self.Profile .. ".json")
	for _, f in files do
		local n = f:match("^(.+)%.json$")
		if n and not seen[n] then
			seen[n] = true
			table.insert(out, n)
		end
	end
	table.sort(out)
	return out
end

-- Switches to a profile. A name that doesn't exist yet starts as a copy of the current one.
function UI:SetProfile(name)
	name = cleanName(name)
	if name == "" or name == self.Profile then
		return
	end
	-- If the current profile can't be saved, switching would lose its changes.
	if not self:SaveNow() then
		return
	end
	local exists = self._store.read(name .. ".json") ~= nil
	self.Profile = name
	if exists then
		self._data = self:_read(name)
		self:_apply(false)
	end
	self:SaveNow()
	self:_paintProfiles()
	self:Notify("Profile switched", name, 2, "bookmark")
end

function UI:DeleteProfile(name)
	if name ~= self.Profile then
		self._store.delete(name .. ".json")
		self:_paintProfiles()
	end
end

function UI:Export()
	return self:_snapshot()
end

-- Imports into a new profile so nothing existing is overwritten.
function UI:Import(json)
	local ok, d = pcall(HttpService.JSONDecode, HttpService, json)
	if not ok or type(d) ~= "table" or type(d.modules) ~= "table" then
		self:Notify("Import failed", "That text isn't a copied profile", 4, "triangle-exclamation")
		return false
	end
	local n, name = 1, "Imported"
	while name == self.Profile or self._store.read(name .. ".json") do
		n += 1
		name = "Imported " .. n
	end
	self._store.write(name .. ".json", json)
	self:SetProfile(name)
	return self.Profile == name
end

---------------------------------------------------------------- tiles

function UI:_buildCard(m)
	local cell = make("Frame", { BackgroundTransparency = 1, Name = m.Id }, self._grid)
	local scale = make("UIScale", {}, make("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1) }, cell))
	local body = scale.Parent
	local glow = halo(self, body, 14, 3, 2, 0.955)
	local b = corner(make("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.Tile }, body), 14)
	shade(b, 0.26)
	local stroke = line(b)
	local shine = gloss(b, 14)
	local big = ghost(b, m.Icon, 104, 26)
	local badge = corner(make("Frame", { Position = UDim2.fromOffset(12, 12), Size = UDim2.fromOffset(38, 38), ZIndex = 2 }, b), 11)
	local ic = icon(badge, m.Icon, 24, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
	local name = label(b, m.Name, { FontFace = F.bold, TextSize = 16, Position = UDim2.new(0, 14, 1, -46), Size = UDim2.new(1, -28, 0, 20), ZIndex = 2 })
	local state = label(b, "", { TextSize = 14, Position = UDim2.new(0, 14, 1, -27), Size = UDim2.fromOffset(60, 16), ZIndex = 2 })
	local cap = keycap(b, { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -12, 1, -11), Size = UDim2.fromOffset(0, 20), TextSize = 12, ZIndex = 2 })
	local star = icon(b, "star", 16, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -46, 0, 16), FontFace = F.iconFill, ZIndex = 2 })
	local opts = corner(make("TextButton", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 8), Size = UDim2.fromOffset(32, 32), ZIndex = 3 }, b), 9)
	local optsIcon = icon(opts, "three-dots-horizontal", 20, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
	self:_hover(opts, opts, 1, 0.84)
	self:_tip(opts, "Options")
	self:_tip(b, m.Tip)

	-- the module's stone in the header meter
	local stone = corner(make("TextButton", { BackgroundColor3 = C.Socket, Size = UDim2.fromOffset(16, 16), LayoutOrder = m._order }, self._meter), 5)
	shade(stone, 0.3)
	local stoneScale = make("UIScale", {}, stone)
	self:_tip(stone, m.Name)
	stone.Activated:Connect(function()
		m:Toggle_()
	end)

	local over, shown, flood = false, nil, nil
	local function rest()
		local c = m.On and m:_tint() or C.Tile
		return over and c:Lerp(WHITE, m.On and 0.16 or 0.08) or c
	end
	local function paint(at)
		local c, ink = m:_tint()
		local quiet = self.Jewels and c or C.Knob
		local changed = shown ~= nil and shown ~= m.On
		local moved = changed and self.Open and not self.ReducedMotion and b.AbsoluteSize.X > 10
		shown = m.On
		if flood then
			flood:Destroy()
			flood = nil
		end
		-- Behind the flood on the way in, ahead of it on the way out, so dark text never sits on the dark tile.
		local slow = moved and m.On
		local function tint(o, color)
			self:_tween(o, slow and 0.26 or 0.12, { [colorProp(o)] = color }, Enum.EasingStyle.Sine, slow and Enum.EasingDirection.InOut or Enum.EasingDirection.Out)
		end
		tint(name, m.On and ink or C.Text)
		tint(state, m.On and ink or C.Muted)
		tint(optsIcon, m.On and ink or C.Muted)
		tint(star, m.On and ink or c)
		if ic:IsA("TextLabel") then
			ic.FontFace = m.On and F.iconFill or F.icon
			tint(ic, m.On and ink or quiet)
		end
		badge.BackgroundColor3 = m.On and ink or quiet
		self:_tween(badge, 0.25, { BackgroundTransparency = m.On and 0.88 or self.Jewels and 0.86 or 0.93 })
		big[colorProp(big)] = m.On and ink or quiet
		self:_tween(big, 0.4, { [fadeProp(big)] = m.On and 0.9 or 0.955, Rotation = m.On and -6 or -14 })
		self:_tween(shine, 0.4, { BackgroundTransparency = m.On and 0.72 or 0.96 })
		opts.BackgroundColor3 = m.On and ink or C.Text
		cap.BackgroundColor3, cap.TextColor3 = m.On and ink or C.Field, m.On and ink or C.Muted
		cap.BackgroundTransparency = m.On and 0.84 or 0
		state.Text = m.On and "On" or "Off"
		cap.Text, cap.Visible = m.Key and prettyBind(m.Key) or "", m.Key ~= nil
		star.Visible = m.Favorite
		stroke.Color = m.On and c:Lerp(WHITE, 0.55) or C.Text
		self:_tween(stroke, 0.3, { Transparency = m.On and 0.25 or 0.91 })
		glow(m.On and c or nil, 0.45)
		self:_tween(stone, 0.25, { BackgroundColor3 = m.On and c or C.Socket })
		if changed and m.On then
			stoneScale.Scale = 0.3
			self:_tween(stoneScale, 0.5, { Scale = 1 }, Enum.EasingStyle.Back)
		end
		if not moved then
			self:_tween(b, changed and 0.16 or 0, { BackgroundColor3 = rest() })
			return
		end
		b.BackgroundColor3 = C.Tile
		local on = m.On
		flood = self:_flood(b, 14, 0.26, c, on, at, function(layer)
			if flood == layer then
				flood = nil
				b.BackgroundColor3 = rest()
				layer:Destroy()
				if on then
					self:_glint(b, 14)
				end
			end
		end)
	end

	local function hover(v)
		over = v
		if not flood then
			self:_tween(b, v and 0.12 or 0.26, { BackgroundColor3 = rest() })
		end
		self:_tween(scale, 0.28, { Scale = v and 1.025 or 1 })
		self:_tween(big, 0.5, { Position = UDim2.new(1, v and -34 or -26, 0.5, v and 4 or 8) })
	end
	b.MouseEnter:Connect(function()
		hover(true)
	end)
	b.MouseLeave:Connect(function()
		hover(false)
	end)
	b.InputBegan:Connect(function(i)
		if isPress(i) then
			self:_tween(scale, 0.1, { Scale = 0.95 })
		end
	end)
	b.InputEnded:Connect(function(i)
		if isPress(i) then
			self:_tween(scale, 0.45, { Scale = over and 1.025 or 1 }, Enum.EasingStyle.Back)
		end
	end)
	b.Activated:Connect(function(i)
		local p = i and Vector2.new(i.Position.X, i.Position.Y) or Vector2.zero
		local at = (p - b.AbsolutePosition) / self:_scaleNow()
		local size = b.AbsoluteSize / self:_scaleNow()
		if at.X > 0 and at.Y > 0 and at.X < size.X and at.Y < size.Y then
			m._clickAt = at
		end
		m:Toggle_()
	end)
	b.MouseButton2Click:Connect(function()
		m:SetFavorite(not m.Favorite)
	end)
	opts.Activated:Connect(function()
		self:_openPage(m)
	end)
	m._cell, m._cardScale, m._card = cell, scale, b
	m._paintCard = function()
		paint(m._clickAt)
		m._clickAt = nil
	end
	m._paintCard()
end

function UI:_matches(m)
	-- A search looks everywhere, whichever category is open.
	if self._query == "" then
		if self._filterName == "Favorites" then
			return m.Favorite
		end
		return self._filterName == "All" or m.Category == self._filterName
	end
	if m.Name:lower():find(self._query, 1, true) then
		return true
	end
	for _, o in m.Options do
		if o.Kind ~= "Label" and o.Name:lower():find(self._query, 1, true) then
			return true
		end
	end
	return false
end

function UI:_filter(animate)
	local shown = 0
	for _, m in self.Modules do
		if m._cell then
			local ok = self:_matches(m)
			m._cell.Visible = ok
			m._cell.LayoutOrder = m._order - (m.Favorite and 10000 or 0)
			if ok then
				shown += 1
				if animate then
					m._cardScale.Scale = 0.8
					self:_tween(m._cardScale, 0.3 + math.min(shown, 9) * 0.045, { Scale = 1 }, Enum.EasingStyle.Back)
				end
			end
		end
	end
	self._shown = shown
	self._empty.Visible = shown == 0
	self._emptyIcon.Text = self._query ~= "" and "magnifying-glass" or self._filterName == "Favorites" and "star" or "squares-grid-plus"
	self._emptyText.Text = self._query ~= "" and "Nothing matches. Try another word."
		or self._filterName == "Favorites" and "Right-click a tile to keep it here."
		or "No modules here yet."
	self:_paintHeader()
end

function UI:_paintHeader()
	local on, of, total, all = {}, {}, 0, 0
	for _, m in self.Modules do
		if not m.Hidden then
			all += 1
			of[m.Category] = (of[m.Category] or 0) + 1
			if m.Favorite then
				of.Favorites = (of.Favorites or 0) + 1
			end
			if m.On then
				total += 1
				on[m.Category] = (on[m.Category] or 0) + 1
				if m.Favorite then
					on.Favorites = (on.Favorites or 0) + 1
				end
			end
		end
	end
	on.All, of.All = total, all
	for _, n in self._nav do
		n.count.Text = on[n.name] and on[n.name] > 0 and tostring(on[n.name]) or ""
	end
	if self._query ~= "" then
		self._title.Text, self._subtitle.Text = "Search", (self._shown or 0) .. " found"
	else
		self._title.Text = self._filterName == "All" and (self._compact and "All" or "All modules") or self._filterName
		self._subtitle.Text = (on[self._filterName] or 0) .. " of " .. (of[self._filterName] or 0) .. " on"
	end
end

function UI:_navColor(n)
	return self.Jewels and n.cat and n.cat.Color or self.Accent
end

function UI:_paintNav(time_)
	for _, n in self._nav do
		local active = n.name == self._filterName
		local c = self:_navColor(n)
		if active then
			self:_tween(self._navGlow, time_ or 0.34, { Position = UDim2.fromOffset(0, n.y), BackgroundColor3 = c })
			self:_tween(self._navBar, time_ or 0.34, { Position = UDim2.fromOffset(0, n.y + 10), BackgroundColor3 = c })
		end
		n.text.FontFace = active and F.bold or F.medium
		self:_tween(n.text, 0.2, { TextColor3 = active and C.Text or C.Muted })
		n.badge.BackgroundColor3 = (active or self.Jewels) and c or C.Text
		self:_tween(n.badge, 0.24, { BackgroundTransparency = active and 0 or self.Jewels and 0.87 or 0.94 })
		self:_tween(n.count, 0.2, { TextColor3 = active and C.Text or C.Muted })
		if n.icon:IsA("TextLabel") then
			n.icon.FontFace = active and F.iconFill or F.icon
			self:_tween(n.icon, 0.2, { TextColor3 = active and inkOn(c) or self.Jewels and c or C.Muted })
		end
	end
end

function UI:_setFilter(name)
	self._filterName = name
	if self._query ~= "" then
		self._search.Text = ""
		self._query = ""
	end
	self:_paintNav()
	self:_closePage()
	if self._compact and self._sideOpen then
		self._sideOpen = false
		self:_layout()
	end
	self._grid.CanvasPosition = Vector2.zero
	self:_filter(true)
end

function UI:_addNav(name, text, iconName, cat)
	local y = #self._nav * 42 + (#self._nav >= 2 and 12 or 0)
	local b = corner(make("TextButton", { BackgroundColor3 = C.Text, Position = UDim2.fromOffset(0, y), Size = UDim2.new(1, 0, 0, 40), ZIndex = 2 }, self._navList), 10)
	self:_hover(b, b, 1, 0.965)
	local badge = corner(make("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 9, 0.5, 0), Size = UDim2.fromOffset(28, 28) }, b), 8)
	shade(badge, 0.22)
	local n = {
		name = name, y = y, cat = cat, badge = badge,
		icon = icon(badge, iconName, 18, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) }),
		text = label(b, text, { Position = UDim2.fromOffset(47, 0), Size = UDim2.new(1, -78, 1, 0), TextColor3 = C.Muted }),
		count = label(b, "", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 0), Size = UDim2.new(0, 24, 1, 0), FontFace = F.medium, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = C.Muted }),
	}
	b.Activated:Connect(function()
		self:_setFilter(name)
	end)
	table.insert(self._nav, n)
	self._navList.CanvasSize = UDim2.fromOffset(0, y + 40)
	self:_paintNav(0)
end

function UI:Category(name, opts)
	assert(type(name) == "string" and name ~= "All" and name ~= "Favorites", "Bad category name")
	local c = self._cats[name]
	if not c then
		local iconName = opts and opts.icon or guessIcon(name, "folder")
		c = setmetatable({ Name = name, UI = self, Icon = iconName, Hidden = name == "_" }, Category)
		self._cats[name] = c
		if not c.Hidden then
			self._catCount += 1
			c.Color = visible(toColor(opts and opts.color) or JEWELS[(self._catCount - 1) % #JEWELS + 1])
			self:_addNav(name, name, iconName, c)
		end
	end
	return c
end

---------------------------------------------------------------- options page

function UI:_clearPage()
	if self._page then
		self._page._paintPage = nil
		for _, o in self._page.Options do
			o._paint, o._row, o._rebuild = nil, nil, nil
		end
	end
	self._groups = {}
	self._listening = nil
	self._page = nil
	for _, c in self._pageList:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
end

-- The text color on the options banner while its module is on.
function UI:_heroFg()
	local m = self._page
	if m and m.On and not m.Hidden then
		return (select(2, m:_tint()))
	end
	return nil
end

function UI:_paintHero(m, quiet)
	local c, ink = m:_tint()
	local lit = m.On and not m.Hidden
	local moved = not quiet and self._heroShown ~= nil and self._heroShown ~= lit and not self.ReducedMotion
	self._heroShown = lit
	if self._heroFlood then
		self._heroFlood:Destroy()
		self._heroFlood = nil
	end
	local function tint(o, color)
		self:_tween(o, not moved and 0 or lit and 0.26 or 0.12, { [colorProp(o)] = color }, Enum.EasingStyle.Sine, lit and Enum.EasingDirection.InOut or Enum.EasingDirection.Out)
	end
	tint(self._pageTitle, lit and ink or C.Text)
	tint(self._pageSub, lit and ink or C.Muted)
	tint(self._backIcon, lit and ink or C.Muted)
	tint(self._heroIcon, lit and ink or c)
	tint(self._pageStarIcon, lit and ink or m.Favorite and c or C.Muted)
	if self._pageStarIcon:IsA("TextLabel") then
		self._pageStarIcon.FontFace = m.Favorite and F.iconFill or F.icon
	end
	self._heroBadge.BackgroundColor3 = lit and ink or c
	self._heroBig[colorProp(self._heroBig)] = lit and ink or c
	self:_tween(self._heroBig, 0.4, { [fadeProp(self._heroBig)] = lit and 0.88 or 0.92 })
	self:_tween(self._heroShine, 0.4, { BackgroundTransparency = lit and 0.76 or 0.96 })
	self._heroStroke.Color = lit and c:Lerp(WHITE, 0.55) or c
	self:_tween(self._heroStroke, 0.3, { Transparency = lit and 0.3 or 0.72 })
	self._heroGlow(lit and c or nil, 0.45)
	if not moved then
		self._hero.BackgroundColor3 = lit and c or C.Tile
		return
	end
	self._hero.BackgroundColor3 = C.Tile
	local at = self._heroAt
	self._heroAt = nil
	self._heroFlood = self:_flood(self._hero, 16, 0.26, c, lit, at, function(layer)
		if self._heroFlood == layer then
			self._heroFlood = nil
			self._hero.BackgroundColor3 = lit and c or C.Tile
			layer:Destroy()
			if lit then
				self:_glint(self._hero, 16)
			end
		end
	end)
end

-- Shows and hides rows by their showIf, and whole groups that end up empty.
function UI:_refreshRows()
	for _, g in self._groups do
		local any = false
		for _, o in g.options do
			local shown = o:_shown()
			any = any or shown
			if o._row then
				o._row.Visible = shown
			end
		end
		g.panel.Visible = any
		if g.title then
			g.title.Visible = any
		end
	end
end

function UI:_openPage(m, still)
	self:_hideTip()
	self:_toggleProfiles(false)
	local scroll = still and self._pageList.CanvasPosition or Vector2.zero
	self:_clearPage()
	self._page = m
	self._pageTitle.Text = m.Name
	self._pageSub.Text = m.Hidden and "For this profile" or m.Tip or m.Category
	self._pageSwitchHit.Visible = not m.Hidden
	self._pageStar.Visible = not m.Hidden
	self._heroIcon:Destroy()
	self._heroIcon = icon(self._heroBadge, m.Icon, 26, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
	self._heroBig.Parent:Destroy()
	self._heroBig = ghost(self._hero, m.Icon, 150, 150)

	local group
	local title
	for _, o in m.Options do
		if o.Kind == "Section" then
			title = label(self._pageList, o.Text, { FontFace = F.bold, TextSize = 15, TextColor3 = C.Muted, Size = UDim2.new(1, 0, 0, 22) })
			group = nil
		else
			if not group then
				group = { panel = panel(self._pageList), title = title, options = {} }
				title = nil
				table.insert(self._groups, group)
			end
			local before = #group.panel:GetChildren()
			render[o.Kind](self, o, group.panel)
			o._row = group.panel:GetChildren()[before + 1]
			table.insert(group.options, o)
			if o._paint then
				o._paint()
			end
		end
	end
	self:_refreshRows()

	local keyPaint
	if not m.Hidden then
		local keys = panel(self._pageList)
		local keyRow = baseRow(self, keys, "Key", "Click, then press a key. Backspace clears it.", nil, 120)
		local cap, capStroke = keycap(keyRow, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -16, 0.5, 0), Size = UDim2.fromOffset(0, 28), TextSize = 14 })
		keyRow.Activated:Connect(function()
			self:_listen(m)
		end)
		local modeRow = baseRow(self, keys, "Key mode", "Hold keeps it on only while the key is down.", nil, 184)
		local modePaint = segments(self, modeRow, { "Toggle", "Hold" }, nil, function(v)
			m.KeyMode = v
			m._paintPage()
			self:_save()
		end)
		keyPaint = function()
			local live = self._listening == m
			local c, ink = m:_tint()
			cap.Text = live and "Press a key" or m.Key and prettyBind(m.Key) or "None"
			self:_tween(cap, 0.2, { BackgroundColor3 = live and c or C.Field, TextColor3 = live and ink or C.Text })
			capStroke.Transparency = live and 1 or 0.88
			modePaint(m.KeyMode)
		end
	end

	local reset = self:_ghost(self._pageList, { Size = UDim2.fromOffset(176, 36) }, function() end)
	local resetIcon = icon(reset, "arrow-spin-counter-clockwise", 18, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 0.5, 0), TextColor3 = C.Muted })
	local resetText = label(reset, "Reset to defaults", { Position = UDim2.fromOffset(38, 0), Size = UDim2.new(1, -44, 1, 0), TextColor3 = C.Muted })
	local function resetPaint(text, color)
		resetText.Text = text
		self:_tween(resetText, 0.16, { TextColor3 = color })
		self:_tween(resetIcon, 0.16, { TextColor3 = color })
	end
	confirm(reset, function()
		resetPaint("Click again", C.Danger)
	end, function()
		resetPaint("Reset to defaults", C.Muted)
	end, function()
		for _, o in m.Options do
			if HAS_VALUE[o.Kind] then
				o:Reset()
			end
			if not m.Hidden then
				o:SetKey(o.DefaultKey)
			end
		end
		if not m.Hidden then
			m.KeyMode = "Toggle"
			m:SetKey(m.DefaultKey)
			if m._widget then
				m:_placeWidget(m._widgetHome)
			end
		end
		self:_openPage(m, true)
	end)

	local first = true
	m._paintPage = function()
		self:_paintHero(m, first)
		first = false
		self._pageSwitch(m.On)
		if keyPaint then
			keyPaint()
		end
	end
	self._pageSwitch(nil)
	m._paintPage()
	self._pageList.CanvasPosition = scroll
	if not still then
		self:_tween(self._pageView, 0.45, { Position = UDim2.fromScale(0, 0) })
		self:_tween(self._gridView, 0.45, { Position = UDim2.fromScale(-1, 0) })
	end
end

function UI:_closePage()
	if not self._page then
		return
	end
	self:_hideTip()
	self:_clearPage()
	self:_tween(self._pageView, 0.45, { Position = UDim2.fromScale(1, 0) })
	self:_tween(self._gridView, 0.45, { Position = UDim2.fromScale(0, 0) })
end

---------------------------------------------------------------- notifications

function UI:Notify(title, text, seconds, iconName, color)
	if self.Dead then
		return
	end
	local c = color or self.Accent
	local hasText = text ~= nil and text ~= ""
	local h = hasText and 68 or 54
	local holder = make("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(300, 0), LayoutOrder = math.floor(os.clock() * 1000) }, self._toasts)
	local card = corner(make("CanvasGroup", { BackgroundColor3 = C.Panel, Size = UDim2.new(1, 0, 0, h), Position = UDim2.fromScale(1.15, 0), GroupTransparency = 1 }, holder), 14)
	local edge = line(card)
	edge.Color, edge.Transparency = c, 0.6
	-- color washes in from the icon's side
	local wash = make("Frame", { BackgroundColor3 = c, Size = UDim2.fromScale(0.75, 1) }, card)
	make("UIGradient", { Transparency = NumberSequence.new(0.74, 1) }, wash)
	local big = ghost(card, iconName or "bell", 84, 28)
	big[fadeProp(big)] = 0.93
	local badge = corner(make("Frame", { BackgroundColor3 = c, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 13, 0.5, 0), Size = UDim2.fromOffset(38, 38), ZIndex = 2 }, card), 11)
	shade(badge, 0.26)
	local ic = icon(badge, iconName or "bell", 22, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), TextColor3 = inkOn(c) })
	if ic:IsA("TextLabel") then
		ic.FontFace = F.iconFill
	end
	label(card, tostring(title), { FontFace = F.bold, TextSize = 16, Position = UDim2.fromOffset(64, hasText and 14 or 0), Size = hasText and UDim2.new(1, -78, 0, 20) or UDim2.new(1, -78, 1, 0), ZIndex = 2 })
	if hasText then
		label(card, tostring(text), { TextColor3 = C.Muted, TextSize = 14, Position = UDim2.fromOffset(64, 35), Size = UDim2.new(1, -78, 0, 18), ZIndex = 2 })
	end
	local bar = make("Frame", { BackgroundColor3 = c, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 3), ZIndex = 2 }, card)
	self:_tween(holder, 0.3, { Size = UDim2.fromOffset(300, h) })
	self:_tween(card, 0.5, { Position = UDim2.fromScale(0, 0), GroupTransparency = 0 })
	seconds = seconds or 3
	TweenService:Create(bar, TweenInfo.new(seconds, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 3) }):Play()
	task.delay(seconds, function()
		if not holder.Parent then
			return
		end
		self:_tween(card, 0.26, { Position = UDim2.fromScale(1.15, 0), GroupTransparency = 1 }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		task.wait(self.ReducedMotion and 0 or 0.26)
		self:_tween(holder, 0.22, { Size = UDim2.fromOffset(300, 0) })
		task.wait(0.24)
		holder:Destroy()
	end)
end

---------------------------------------------------------------- dialogs

-- Asks a question over everything. buttons is a list of names; the last is the main one.
-- callback(name, index) runs when one is clicked. Returns a function that closes it.
function UI:Dialog(title, text, buttons, callback)
	if self.Dead then
		return function() end
	end
	buttons = buttons or { "OK" }
	local back = make("TextButton", { Modal = true, BackgroundColor3 = C.Shade, BackgroundTransparency = 1, Position = UDim2.fromOffset(0, -100), Size = UDim2.new(1, 0, 1, 200), ZIndex = 30 }, self.Gui)
	local card = corner(make("TextButton", { BackgroundColor3 = C.Panel, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(340, 0), AutomaticSize = Enum.AutomaticSize.Y }, back), 16)
	line(card).Transparency = 0.8
	pad(card, 20, 18)
	list(card, 10)
	local scale = make("UIScale", { Scale = self:_scaleNow() * 0.85 }, card)
	label(card, tostring(title), { FontFace = F.head, TextSize = 18, Size = UDim2.new(1, 0, 0, 24), LayoutOrder = 1 })
	label(card, tostring(text or ""), { TextColor3 = C.Muted, TextWrapped = true, TextTruncate = Enum.TextTruncate.None, Size = UDim2.fromScale(1, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2 })
	local row = make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40), LayoutOrder = 3 }, card)
	local l = list(row, 8, Enum.FillDirection.Horizontal)
	l.HorizontalAlignment, l.VerticalAlignment = Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Bottom
	local done = false
	local function close()
		if done then
			return
		end
		done = true
		self:_tween(scale, 0.14, { Scale = 0.01 }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		self:_tween(back, 0.16, { BackgroundTransparency = 1 }).Completed:Connect(function()
			back:Destroy()
		end)
	end
	for i, name in buttons do
		local main = i == #buttons
		local b = corner(make("TextButton", {
			Text = tostring(name), FontFace = F.bold, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 36), LayoutOrder = i,
			BackgroundColor3 = main and self.Accent or C.Tile, TextColor3 = main and self.Ink or C.Text,
		}, row), 10)
		pad(b, 16, 0)
		b.MouseEnter:Connect(function()
			self:_tween(b, 0.12, { BackgroundTransparency = 0.15 })
		end)
		b.MouseLeave:Connect(function()
			self:_tween(b, 0.2, { BackgroundTransparency = 0 })
		end)
		b.Activated:Connect(function()
			if done then
				return
			end
			close()
			if callback then
				task.spawn(callback, name, i)
			end
		end)
	end
	self:_tween(back, 0.2, { BackgroundTransparency = 0.4 })
	self:_tween(scale, 0.3, { Scale = self:_scaleNow() }, Enum.EasingStyle.Back)
	return close
end

---------------------------------------------------------------- window

function UI:_scaleNow()
	return (self._fit or 1) * (self.Scale or 1)
end

function UI:_paintDim()
	local on = self.Open and self.Dim
	self:_tween(self._dim, 0.35, { BackgroundTransparency = on and 0.45 or 1 })
	local wantBlur = self.Open and self.Blur
	if wantBlur and not self._blur then
		self._blur = make("BlurEffect", { Size = 0 }, workspace.CurrentCamera)
	end
	if self._blur then
		local t = self:_tween(self._blur, 0.35, { Size = wantBlur and 16 or 0 })
		if not wantBlur then
			local gone = self._blur
			self._blur = nil
			t.Completed:Connect(function()
				gone:Destroy()
			end)
		end
	end
end

-- The brand's four tiles light up one after another.
function UI:_playMark()
	for i, s in self._markScales do
		s.Scale = 0
		task.delay(self.ReducedMotion and 0 or 0.1 + i * 0.06, function()
			if not self.Dead then
				self:_tween(s, 0.45, { Scale = 1 }, Enum.EasingStyle.Back)
			end
		end)
	end
end

function UI:SetOpen(open)
	if self.Dead or not self._started then
		return
	end
	if self._editing then
		self:SetEditing(false)
		return
	end
	if open == self.Open then
		return
	end
	self.Open = open
	self:_paintDim()
	local w, h = self._w, self._h
	if open then
		self._frame.Visible = true
		self._frame.Size = UDim2.fromOffset(w, 0)
		self:_tween(self._frame, 0.48, { Size = UDim2.fromOffset(w, h) })
		self:_playMark()
		self:_filter(true)
	else
		self:_listen(nil)
		self:_hideTip()
		self:_toggleProfiles(false)
		self:_endDrag()
		local t = self:_tween(self._frame, 0.24, { Size = UDim2.fromOffset(w, 0) }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		t.Completed:Connect(function()
			if not self.Open and not self.Dead then
				self._frame.Visible = false
			end
		end)
	end
end

function UI:SetEditing(on)
	if on == self._editing then
		return
	end
	if on then
		self:SetOpen(false)
	end
	self._editing = on
	self._editBar.Visible = true
	self:_tween(self._editBar, 0.4, { Position = UDim2.new(0.5, 0, 1, on and -28 or 90) })
	for _, m in self._widgets do
		m._widget.Active = on
		m:_paintWidget()
	end
	if not on then
		self:_endDrag()
		self:_showGuides(nil, nil)
		self:SetOpen(true)
	end
end

function UI:_showGuides(x, y)
	self._guideX.Visible, self._guideY.Visible = x ~= nil, y ~= nil
	if x then
		self._guideX.Position = UDim2.fromScale(x, 0)
	end
	if y then
		self._guideY.Position = UDim2.fromScale(0, y)
	end
end

-- Snaps a widget to the screen centre and to a 12px margin. p is its top-left as a fraction.
function UI:_snap(w, p)
	local screen, size = self._hud.AbsoluteSize, w.AbsoluteSize
	local function axis(pos, full, len)
		for _, s in { { (full - len) / 2, full / 2 }, { 12, 12 }, { full - len - 12, full - 12 } } do
			if math.abs(pos - s[1]) < 8 then
				return s[1], s[2] / full
			end
		end
		return pos, nil
	end
	local x, gx = axis(p.X * screen.X, screen.X, size.X)
	local y, gy = axis(p.Y * screen.Y, screen.Y, size.Y)
	self:_showGuides(gx, gy)
	return Vector2.new(x / screen.X, y / screen.Y)
end

function UI:_layout()
	local vp = self.Gui.AbsoluteSize
	if vp.X < 10 then
		return
	end
	local fit = math.min((vp.X - 24) / WIDTH, (vp.Y - 24) / HEIGHT)
	if fit > 1 then
		-- Grow on big screens, so it doesn't look lost at 1080p and up.
		fit = math.clamp(math.min(vp.X / 1536, vp.Y / 816), 1, 1.5)
	end
	local compact = vp.X < WIDTH * 0.72
	self._fit = compact and math.clamp((vp.Y - 16) / 380, 0.7, 1) or math.max(fit, 0.6)
	self._compact = compact
	local scale = self:_scaleNow()
	self._w, self._h = math.min(compact and WIDTH or self._size.X, (vp.X - 16) / scale), math.min(compact and HEIGHT or self._size.Y, (vp.Y - 16) / scale)
	self._frameScale.Scale = scale
	self._stage.Size = UDim2.fromOffset(self._w, self._h)
	self._scene.Size = self._stage.Size
	self._sideShade.Visible = not compact
	if self.Open then
		self._frame.Size = UDim2.fromOffset(self._w, self._h)
	end
	self._side.Visible = not compact or self._sideOpen == true
	self._side.BackgroundTransparency = compact and 0 or 1
	self._main.Position = UDim2.fromOffset(compact and 0 or SIDE, 0)
	self._main.Size = UDim2.new(1, compact and 0 or -SIDE, 1, 0)
	self._menuBtn.Visible = compact
	self._head.Position = UDim2.fromOffset(compact and 56 or 22, 16)
	self._searchBox.Size = UDim2.fromOffset(compact and 112 or 190, 36)
	self._heroBadge.Visible = not compact
	for _, l in { self._pageTitle, self._pageSub } do
		l.Position = UDim2.new(0, compact and 50 or 112, 0.5, l == self._pageTitle and -24 or 3)
		l.Size = UDim2.new(1, compact and -174 or -236, 0, l == self._pageTitle and 26 or 18)
	end
	local cols = compact and 2 or math.clamp(math.floor((self._w - SIDE - 48) / 165), 2, 8)
	self._grip.Visible = not compact
	self._cells.CellSize = UDim2.new(1 / cols, -math.ceil(GAP * (cols - 1) / cols) - 1, 0, TILE_H)
	self:_moveWindow(self._rootPos or Vector2.zero)
	for _, m in self._widgets do
		m:_placeWidget(m._widgetPos)
	end
	self:_paintHeader()
end

-- Offset from the screen centre, kept far enough in that the window can always be grabbed.
function UI:_moveWindow(p)
	local limit = self.Gui.AbsoluteSize / 2 - Vector2.new(60, 40)
	p = Vector2.new(math.clamp(p.X, -math.max(0, limit.X), math.max(0, limit.X)), math.clamp(p.Y, -math.max(0, limit.Y), math.max(0, limit.Y)))
	self._rootPos = p
	self._frame.Position = UDim2.new(0.5, p.X, 0.5, p.Y)
end

function UI:_windowHandle(h)
	h.InputBegan:Connect(function(i)
		if isPress(i) then
			local from, start = self._rootPos, i.Position
			self:_drag(i, function(pos)
				self:_moveWindow(from + Vector2.new(pos.X - start.X, pos.Y - start.Y))
			end, function()
				self:_save()
			end)
		end
	end)
end

---------------------------------------------------------------- profile menu

function UI:_toggleProfiles(open)
	if open == nil then
		open = not self._profilesOpen
	end
	if open == self._profilesOpen then
		return
	end
	self._profilesOpen = open
	self._catcher.Visible = open
	local h = open and self._profilesHeight or 0
	if open then
		self._menu.Visible = true
	end
	self:_tween(self._profileArrow, 0.3, { Rotation = open and 180 or 0 })
	local t = self:_tween(self._menu, open and 0.36 or 0.2, { Size = UDim2.fromOffset(236, h) })
	t.Completed:Connect(function()
		if not self._profilesOpen and not self.Dead then
			self._menu.Visible = false
		end
	end)
end

function UI:_paintProfiles()
	self._profileName.Text = self.Profile
	for _, c in self._profiles:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	local names = self:Profiles()
	for _, name in names do
		local active = name == self.Profile
		local b = self:_ghost(self._profiles, { Size = UDim2.new(1, 0, 0, 36) }, function()
			self:SetProfile(name)
		end)
		local text = label(b, name, { FontFace = active and F.medium or F.body, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -56, 1, 0), TextColor3 = active and C.Text or C.Muted })
		if active then
			icon(b, "check-large", 18, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), TextColor3 = self.Accent })
		else
			local x, i = self:_iconButton(b, "trash-can", "Delete " .. name, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -3, 0.5, 0), Size = UDim2.fromOffset(30, 30) }, function() end)
			i.TextSize = 18
			confirm(x, function()
				text.Text, text.TextColor3 = "Delete " .. name .. "?", C.Danger
			end, function()
				text.Text, text.TextColor3 = name, C.Muted
			end, function()
				self:DeleteProfile(name)
			end)
		end
	end
	local listed = math.min(#names, 5) * 38
	self._profiles.Size = UDim2.new(1, -12, 0, listed)
	self._newField.Position = UDim2.fromOffset(6, listed + 10)
	self._profilesHeight = listed + 10 + 36 + 6
	if self._profilesOpen then
		self:_tween(self._menu, 0.24, { Size = UDim2.fromOffset(236, self._profilesHeight) })
	end
end

function UI:SetAccent(c)
	self.Accent = visible(c)
	self.Ink = inkOn(self.Accent)
	for _, m in self.Modules do
		m:_repaint()
		if m._widget then
			m:_paintWidget()
		end
	end
	self:_paintNav(0)
	-- Repaint open rows in place; rebuilding them would drop the drag that is changing the accent.
	if self._page then
		for _, o in self._page.Options do
			if o._paint then
				o._paint()
			end
		end
	end
	self:_paintChrome()
	self:_settle("accent", function()
		self:_paintProfiles()
	end)
end

-- Four tiles set in a square.
function UI:_mark(parent, size, props)
	local box = make("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(size, size) }, parent)
	for k, v in props do
		box[k] = v
	end
	local tile = math.floor(size * 0.46)
	local scales = {}
	self._markTiles = self._markTiles or {}
	for i = 0, 3 do
		local x, y = i % 2, i // 2
		local t = corner(make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(tile, tile), Position = UDim2.fromOffset(x == 0 and tile / 2 or size - tile / 2, y == 0 and tile / 2 or size - tile / 2),
		}, box), math.max(2, math.floor(tile * 0.32)))
		shade(t, 0.32)
		gloss(t, math.max(2, math.floor(tile * 0.32))).BackgroundTransparency = 0.6
		table.insert(self._markTiles, { tile = t, i = i + 1 })
		scales[i + 1] = make("UIScale", {}, t)
	end
	return scales
end

function UI:_build(title)
	local gui = make("ScreenGui", { Name = "Meowthjrlib_" .. cleanName(title), ResetOnSpawn = false, DisplayOrder = 100, ZIndexBehavior = Enum.ZIndexBehavior.Sibling })
	self.Gui = gui
	if not pcall(function()
		gui.Parent = game:GetService("CoreGui")
	end) then
		gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	end

	self._dim = make("Frame", { BackgroundColor3 = C.Shade, BackgroundTransparency = 1, Position = UDim2.fromOffset(0, -100), Size = UDim2.new(1, 0, 1, 200) }, gui)
	self._hud = make("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, gui)
	self._guideX = make("Frame", { AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.new(0, 1, 1, 0), BackgroundColor3 = self.Accent, Visible = false }, self._hud)
	self._guideY = make("Frame", { AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = self.Accent, Visible = false }, self._hud)

	-- _frame unfolds; the stage inside keeps its full size and is revealed from the middle.
	local frame = make("Frame", { BackgroundTransparency = 1, Visible = false, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) }, gui)
	self._frame = frame
	self._frameScale = make("UIScale", {}, frame)
	for i = 1, 12 do
		corner(make("Frame", {
			BackgroundColor3 = C.Shade, BackgroundTransparency = 0.955, AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 12), Size = UDim2.new(1, i * 7, 1, i * 7),
		}, frame), 16 + i * 3)
	end
	-- Modal frees the mouse in games that lock it while the window is open.
	local root = corner(make("TextButton", { Modal = true, BackgroundColor3 = C.Window, Size = UDim2.fromScale(1, 1), ClipsDescendants = true }, frame), 18)
	make("UIGradient", { Rotation = 90, Color = ColorSequence.new(WHITE, Color3.new(0.78, 0.78, 0.78)) }, root)
	-- A gilded edge whose light slowly travels around the window.
	local edge = make("UIStroke", { Color = WHITE, Thickness = 1.6, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, root)
	self._edge = make("UIGradient", { Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(0.3, 0.75), NumberSequenceKeypoint.new(0.7, 0.8), NumberSequenceKeypoint.new(1, 0.25),
	}) }, edge)

	-- backdrop: drifting light and a mosaic, clipped to the window's round corners
	-- Opaque, because faint layers blended over transparency round to the wrong colors.
	local back = corner(make("CanvasGroup", { BackgroundColor3 = C.Window, Size = UDim2.fromScale(1, 1), ZIndex = 0 }, root), 18)
	make("UIGradient", { Rotation = 90, Color = ColorSequence.new(WHITE, Color3.new(0.78, 0.78, 0.78)) }, back)
	local scene = make("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) }, back)
	self._scene = scene
	self._orbs = {}
	for _, spec in { { self.Accent, 300, 0.985, 0.9, 0.02 }, { C.Knob, 320, 0.987, 0.08, 0.95 }, { C.Knob, 220, 0.99, 0.5, 0 } } do
		local box, discs = orb(scene, spec[1], spec[2], spec[3])
		box.Position = UDim2.fromScale(spec[4], spec[5])
		table.insert(self._orbs, { box = box, discs = discs, x = spec[4], y = spec[5] })
	end
	self._sideShade = make("Frame", { BackgroundColor3 = BLACK, BackgroundTransparency = 0.72, Size = UDim2.new(0, SIDE, 1, 0) }, scene)
	self._mosaic = {}
	local step = 17
	for col = 0, math.floor((WIDTH - SIDE) / step) - 1 do
		for row = 0, 7 do
			-- dense in the top right corner, gone before it reaches the title
			local alpha = 0.17 * (col / 34) ^ 1.6 * (1 - row / 8) ^ 1.3 * (0.5 + 0.5 * math.abs(math.sin(col * 12.9 + row * 78.2)))
			if alpha > 0.012 and col > 15 and row < 6 then
				local f = corner(make("Frame", {
					BackgroundColor3 = C.Text, BackgroundTransparency = 1 - alpha, AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.new(1, -(33 - col) * step - 2, 0, row * step + 2), Size = UDim2.fromOffset(step - 4, step - 4),
				}, scene), 3)
				table.insert(self._mosaic, { f = f, rest = 1 - alpha })
			end
		end
	end

	local stage = make("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) }, root)
	self._stage = stage

	-- main area: the tile view and the options view slide side by side
	local main = make("Frame", { BackgroundTransparency = 1, ClipsDescendants = true }, stage)
	self._main = main
	self:_windowHandle(make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 88), Active = true }, main))
	local gridView = make("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, main)
	self._gridView = gridView
	self._head = make("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(22, 16), Size = UDim2.new(1, -290, 0, 34) }, gridView)
	self._title = label(self._head, "", { FontFace = F.head, TextSize = 24 })
	self._meter = make("Frame", { BackgroundTransparency = 1, ClipsDescendants = true, Position = UDim2.fromOffset(22, 56), Size = UDim2.new(1, -140, 0, 20) }, gridView)
	list(self._meter, 6, Enum.FillDirection.Horizontal).VerticalAlignment = Enum.VerticalAlignment.Center
	self._subtitle = label(gridView, "", { TextColor3 = C.Muted, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -24, 0, 57), Size = UDim2.fromOffset(100, 18) })
	self._menuBtn = self:_iconButton(gridView, "sidebar", nil, { Position = UDim2.fromOffset(14, 16) }, function()
		self._sideOpen = not self._sideOpen
		self:_layout()
	end)
	local searchBox = self:_field(gridView, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -62, 0, 15), Size = UDim2.fromOffset(190, 36), PlaceholderText = "Search" })
	make("UIPadding", { PaddingLeft = UDim.new(0, 36), PaddingRight = UDim.new(0, 10) }, searchBox)
	icon(searchBox, "magnifying-glass", 18, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, -26, 0.5, 0), TextColor3 = C.Muted })
	self._search, self._searchBox = searchBox, searchBox
	self:_tip(searchBox, "Ctrl+F finds modules and settings")
	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		local q = searchBox.Text:lower()
		if q ~= self._query then
			self._query = q
			self:_closePage()
			self:_filter()
		end
	end)
	self._grid = make("ScrollingFrame", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 80), Size = UDim2.new(1, -20, 1, -80), CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 3, ScrollBarImageColor3 = C.Muted, ScrollBarImageTransparency = 0.5,
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}, gridView)
	self._cells = make("UIGridLayout", { CellPadding = UDim2.fromOffset(GAP, GAP), SortOrder = Enum.SortOrder.LayoutOrder }, self._grid)
	-- Room for the glow and the hover scale, which would otherwise be clipped at the edges.
	make("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 16), PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 22) }, self._grid)
	local fade = make("Frame", { BackgroundColor3 = C.Fade, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, -16, 0, 26), ZIndex = 4 }, gridView)
	make("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0.1) }, fade)
	self._empty = make("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 84), Size = UDim2.new(1, 0, 1, -110), Visible = false }, gridView)
	self._emptyIcon = icon(self._empty, "star", 56, { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 0.5, -6), TextColor3 = C.Track, FontFace = F.iconFill })
	self._emptyText = label(self._empty, "", { TextColor3 = C.Muted, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromScale(0, 0.5), Size = UDim2.new(1, 0, 0, 24) })

	-- options view: the module's gem as a banner, its settings under it
	local pageView = make("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Position = UDim2.fromScale(1, 0) }, main)
	self._pageView = pageView
	local heroBox = make("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(22, 16), Size = UDim2.new(1, -84, 0, 84) }, pageView)
	self._heroGlow = halo(self, heroBox, 16, 3, 2, 0.955)
	local hero = corner(make("Frame", { BackgroundColor3 = C.Tile, Size = UDim2.fromScale(1, 1), Active = true }, heroBox), 16)
	self._hero = hero
	self:_windowHandle(hero)
	shade(hero, 0.26)
	self._heroStroke = line(hero)
	self._heroShine = gloss(hero, 16)
	self._heroBig = ghost(hero, "gear", 150, 150)
	local _
	_, self._backIcon = self:_iconButton(hero, "chevron-large-left", "Back", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 8, 0.5, 0), Size = UDim2.fromOffset(36, 36), ZIndex = 3 }, function()
		self:_closePage()
	end, function()
		return self:_heroFg() or C.Muted
	end)
	self._heroBadge = corner(make("Frame", { BackgroundTransparency = 0.86, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 50, 0.5, 0), Size = UDim2.fromOffset(48, 48), ZIndex = 2 }, hero), 14)
	self._heroIcon = icon(self._heroBadge, "gear", 26, {})
	self._pageTitle = label(hero, "", { FontFace = F.head, TextSize = 21, Position = UDim2.new(0, 112, 0.5, -24), Size = UDim2.new(1, -236, 0, 26), ZIndex = 2 })
	self._pageSub = label(hero, "", { TextSize = 14, Position = UDim2.new(0, 112, 0.5, 3), Size = UDim2.new(1, -236, 0, 18), ZIndex = 2 })
	self._pageStar, self._pageStarIcon = self:_iconButton(hero, "star", "Favorite", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -72, 0.5, 0), ZIndex = 3 }, function()
		self._page:SetFavorite(not self._page.Favorite)
	end, function()
		return self:_heroFg() or self._page and self._page.Favorite and (self._page:_tint()) or C.Muted
	end)
	self._pageSwitchHit = make("TextButton", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -18, 0.5, 0), Size = UDim2.fromOffset(50, 36), ZIndex = 3 }, hero)
	-- On the lit banner the switch inverts, so it still stands out.
	self._pageSwitch = switch(self, self._pageSwitchHit, { Position = UDim2.new(1, 0, 0.5, 0) }, function()
		if not self._page then
			return C.Knob, C.Ink
		end
		local c, ink = self._page:_tint()
		return ink, c
	end)
	self._pageSwitchHit.Activated:Connect(function()
		self._heroAt = Vector2.new(hero.AbsoluteSize.X / self:_scaleNow() - 38, 42)
		self._page:Toggle_()
	end)
	self._pageList = make("ScrollingFrame", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(20, 112), Size = UDim2.new(1, -30, 1, -112), CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 3, ScrollBarImageColor3 = C.Muted, ScrollBarImageTransparency = 0.5, ScrollingDirection = Enum.ScrollingDirection.Y,
	}, pageView)
	list(self._pageList, 12)
	make("UIPadding", { PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 12), PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 22) }, self._pageList)
	local fade2 = fade:Clone()
	fade2.Parent = pageView
	-- The window grows from its centre, so the corner keeps up with the mouse at twice the distance.
	self._grip = make("TextButton", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 1), Position = UDim2.fromScale(1, 1), Size = UDim2.fromOffset(24, 24), ZIndex = 9 }, stage)
	for i = 1, 3 do
		corner(make("Frame", { BackgroundColor3 = C.Muted, BackgroundTransparency = 0.4, AnchorPoint = Vector2.new(0.5, 0.5), Rotation = -45, Position = UDim2.fromOffset(8 + i * 2, 8 + i * 2), Size = UDim2.fromOffset(16 - i * 4, 1) }, self._grip), 1)
	end
	self:_tip(self._grip, "Drag to resize, right-click to reset")
	self._grip.InputBegan:Connect(function(i)
		if not isPress(i) then
			return
		end
		local from, start = Vector2.new(self._w, self._h), i.Position
		self:_drag(i, function(pos)
			local d = Vector2.new(pos.X - start.X, pos.Y - start.Y) * 2 / self:_scaleNow()
			local room = (self.Gui.AbsoluteSize - Vector2.new(16, 16)) / self:_scaleNow()
			self._size = Vector2.new(math.clamp(from.X + d.X, MIN_W, math.max(MIN_W, room.X)), math.clamp(from.Y + d.Y, MIN_H, math.max(MIN_H, room.Y)))
			self:_layout()
		end, function()
			self:_save()
		end)
	end)
	self._grip.MouseButton2Click:Connect(function()
		self._size = Vector2.new(WIDTH, HEIGHT)
		self:_layout()
		self:_save()
	end)
	self:_iconButton(main, "x", nil, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 16), ZIndex = 5 }, function()
		self:SetOpen(false)
	end)

	-- sidebar
	local side = corner(make("Frame", { BackgroundColor3 = C.Window, BackgroundTransparency = 1, Size = UDim2.new(0, SIDE, 1, 0), Active = true, ZIndex = 6 }, stage), 18)
	self._side = side
	local rule = make("Frame", { BackgroundColor3 = C.Text, BackgroundTransparency = 0.9, Position = UDim2.new(1, -1, 0, 0), Size = UDim2.new(0, 1, 1, 0) }, side)
	make("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) }) }, rule)
	local brand = make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 80), Active = true }, side)
	self:_windowHandle(brand)
	self._markScales = self:_mark(brand, 32, { Position = UDim2.fromOffset(20, 24) })
	local word = label(brand, title, { FontFace = F.head, TextSize = 18, TextColor3 = WHITE, Position = UDim2.fromOffset(64, 24), Size = UDim2.new(1, -72, 0, 32) })
	self._wordShade = make("UIGradient", { Rotation = 90 }, word)
	self._navList = make("ScrollingFrame", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 82), Size = UDim2.new(1, -24, 1, -252), CanvasSize = UDim2.new(),
		ScrollBarThickness = 0, ScrollingDirection = Enum.ScrollingDirection.Y,
	}, side)
	self._navGlow = corner(make("Frame", { Size = UDim2.new(1, 0, 0, 40) }, self._navList), 10)
	make("UIGradient", { Transparency = NumberSequence.new(0.72, 0.95) }, self._navGlow)
	self._navBar = corner(make("Frame", { Size = UDim2.fromOffset(3, 20), ZIndex = 3 }, self._navList), 2)
	local function tool(y, iconName, text, fn)
		local b = self:_ghost(side, { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 12, 1, y), Size = UDim2.new(1, -24, 0, 36) }, fn)
		icon(b, iconName, 20, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 13, 0.5, 0), TextColor3 = C.Muted })
		label(b, text, { FontFace = F.medium, Position = UDim2.fromOffset(47, 0), Size = UDim2.new(1, -56, 1, 0), TextColor3 = C.Muted })
	end
	local function leaveSide()
		if self._compact and self._sideOpen then
			self._sideOpen = false
			self:_layout()
		end
	end
	tool(-120, "four-rectangles-mason-grid", "Edit layout", function()
		self:SetEditing(true)
	end)
	tool(-82, "gear", "Settings", function()
		leaveSide()
		self:_openPage(self._settings)
	end)
	local profile = corner(make("TextButton", { BackgroundColor3 = C.Tile, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 12, 1, -14), Size = UDim2.new(1, -24, 0, 58) }, side), 14)
	shade(profile, 0.24)
	line(profile)
	profile.MouseEnter:Connect(function()
		self:_tween(profile, 0.12, { BackgroundColor3 = C.Tile:Lerp(WHITE, 0.07) })
	end)
	profile.MouseLeave:Connect(function()
		self:_tween(profile, 0.24, { BackgroundColor3 = C.Tile })
	end)
	local avatar = make("ImageLabel", { BackgroundColor3 = C.Field, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 11, 0.5, 0), Size = UDim2.fromOffset(38, 38) }, profile)
	make("UICorner", { CornerRadius = UDim.new(1, 0) }, avatar)
	avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. Players.LocalPlayer.UserId .. "&w=150&h=150"
	self._avatarRing = make("UIStroke", { Color = self.Accent, Thickness = 2 }, avatar)
	label(profile, "Profile", { TextSize = 13, TextColor3 = C.Muted, Position = UDim2.fromOffset(60, 11), Size = UDim2.new(1, -88, 0, 16) })
	self._profileName = label(profile, "", { FontFace = F.bold, Position = UDim2.fromOffset(60, 28), Size = UDim2.new(1, -88, 0, 18) })
	self._profileArrow = icon(profile, "chevron-small-up", 18, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), TextColor3 = C.Muted })
	profile.Activated:Connect(function()
		self:_toggleProfiles()
	end)

	-- profile menu, over everything in the window
	self._catcher = make("TextButton", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false, ZIndex = 7 }, stage)
	self._catcher.Activated:Connect(function()
		self:_toggleProfiles(false)
	end)
	self._menu = corner(make("TextButton", { BackgroundColor3 = C.Menu, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 12, 1, -80), Size = UDim2.fromOffset(236, 0), ClipsDescendants = true, Visible = false, ZIndex = 8 }, stage), 14)
	line(self._menu).Transparency = 0.82
	self._profiles = make("ScrollingFrame", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(6, 6), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 2, ScrollingDirection = Enum.ScrollingDirection.Y,
	}, self._menu)
	list(self._profiles, 2)
	self._newField = self:_field(self._menu, { Size = UDim2.new(1, -12, 0, 36), PlaceholderText = "New profile name" })
	make("UIPadding", { PaddingLeft = UDim.new(0, 36), PaddingRight = UDim.new(0, 10) }, self._newField)
	icon(self._newField, "plus-large", 16, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, -26, 0.5, 0), TextColor3 = C.Muted })
	self._newField.FocusLost:Connect(function(enter)
		if enter then
			self:SetProfile(self._newField.Text)
		end
		self._newField.Text = ""
	end)

	-- layout editor bar
	self._editBar = corner(make("Frame", { BackgroundColor3 = C.Window, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 90), Size = UDim2.fromOffset(400, 58), Visible = false }, gui), 16)
	self._editEdge = line(self._editBar)
	icon(self._editBar, "hand-grip", 22, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 18, 0.5, 0), TextColor3 = C.Muted })
	label(self._editBar, "Drag to move, right-click to reset", { FontFace = F.medium, Position = UDim2.fromOffset(52, 0), Size = UDim2.new(1, -150, 1, 0) })
	self._doneBtn = corner(make("TextButton", { Text = "Done", FontFace = F.bold, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(88, 38) }, self._editBar), 11)
	local doneScale = make("UIScale", {}, self._doneBtn)
	self._doneBtn.MouseEnter:Connect(function()
		self:_tween(doneScale, 0.16, { Scale = 1.05 })
	end)
	self._doneBtn.MouseLeave:Connect(function()
		self:_tween(doneScale, 0.16, { Scale = 1 })
	end)
	self._doneBtn.Activated:Connect(function()
		self:SetEditing(false)
	end)

	self._openBtn = corner(make("TextButton", { BackgroundColor3 = C.Window, Visible = false, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 12), Size = UDim2.fromOffset(52, 52) }, gui), 16)
	self._openEdge = line(self._openBtn)
	self:_mark(self._openBtn, 28, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
	self._openBtn.Activated:Connect(function()
		self:SetOpen(not self.Open)
	end)

	self._toasts = make("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -18, 1, -18), Size = UDim2.new(0, 300, 1, -36) }, gui)
	list(self._toasts, 10).VerticalAlignment = Enum.VerticalAlignment.Bottom
	self._tipLabel = corner(make("TextLabel", { AutomaticSize = Enum.AutomaticSize.XY, BackgroundColor3 = C.Field, FontFace = F.medium, TextSize = 14, Visible = false, ZIndex = 20 }, gui), 9)
	pad(self._tipLabel, 10, 6)
	line(self._tipLabel).Transparency = 0.8
	self._tipScale = make("UIScale", {}, self._tipLabel)
	self:_paintChrome()
end

-- Everything outside the tiles that wears the accent.
function UI:_paintChrome()
	local a = self.Accent
	local j = self.Jewels
	self._edge.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, a), ColorSequenceKeypoint.new(0.35, j and JEWELS[3] or C.Track), ColorSequenceKeypoint.new(0.7, j and JEWELS[1] or C.Track), ColorSequenceKeypoint.new(1, a),
	})
	local mark = j and { a, JEWELS[1], JEWELS[3], JEWELS[2] } or { a, C.Track, C.Track, a:Lerp(C.Track, 0.55) }
	for _, t in self._markTiles do
		t.tile.BackgroundColor3 = mark[t.i]
	end
	self._wordShade.Color = ColorSequence.new(a:Lerp(WHITE, 0.75), a)
	local light = j and { a, JEWELS[3], JEWELS[1] } or { a, C.Knob, C.Knob }
	for i, o in self._orbs do
		for _, d in o.discs do
			d.BackgroundColor3 = light[i]
		end
	end
	self._avatarRing.Color = a
	self._doneBtn.BackgroundColor3, self._doneBtn.TextColor3 = a, self.Ink
	self._guideX.BackgroundColor3, self._guideY.BackgroundColor3 = a, a
	self._editEdge.Color, self._editEdge.Transparency = a, 0.5
	self._openEdge.Color, self._openEdge.Transparency = a, 0.4
end

-- Slow movement while the window is open: the edge, the light, the mosaic, the odd glint.
function UI:_ambient(dt)
	if not self.Open or self.ReducedMotion then
		return
	end
	local now = os.clock()
	self._edge.Rotation = now * 22 % 360
	for i, o in self._orbs do
		o.box.Position = UDim2.fromScale(o.x + math.sin(now * 0.23 + i * 2) * 0.05, o.y + math.cos(now * 0.19 + i) * 0.05)
	end
	self._twinkle += dt
	if self._twinkle > 0.28 and #self._mosaic > 0 then
		self._twinkle = 0
		local s = self._mosaic[math.random(#self._mosaic)]
		s.f.BackgroundColor3 = self.Jewels and JEWELS[math.random(#JEWELS)] or self.Accent
		self:_tween(s.f, 0.5, { BackgroundTransparency = 0.5 }, Enum.EasingStyle.Sine).Completed:Connect(function()
			if not self.Dead then
				self:_tween(s.f, 1.6, { BackgroundTransparency = s.rest }, Enum.EasingStyle.Sine)
			end
		end)
	end
	self._sinceGlint += dt
	if self._sinceGlint > 2.6 and not self._page then
		self._sinceGlint = 0
		local lit = {}
		for _, m in self.Modules do
			if m.On and m._cell and m._cell.Visible then
				table.insert(lit, m)
			end
		end
		if #lit > 0 then
			self:_glint(lit[math.random(#lit)]._card, 14)
		end
	end
end

function UI:_buildSettings()
	local s = self:Category("_"):Module("Settings", { icon = "gear" })
	self._settings = s
	s:Section("Window")
	s:_option("Key", "Open key", { default = self.Key, tip = "Shows or hides the window. Backspace resets it." }, function(v)
		self.Key = v
	end)
	s:Slider("Window size", { min = 70, max = 130, default = 100, step = 5, suffix = "%" }, function(v)
		self.Scale = v / 100
		self:_settle("layout", function()
			self:_layout()
		end)
	end)
	s:Toggle("Dim the game", { default = true }, function(v)
		self.Dim = v
		self:_paintDim()
	end)
	s:Toggle("Blur the game", { default = false, tip = "Adds a blur effect to your camera while open" }, function(v)
		self.Blur = v
		self:_paintDim()
	end)
	s:Toggle("Reduce motion", { default = GuiService.ReducedMotionEnabled }, function(v)
		self.ReducedMotion = v
	end)
	s:Toggle("Notify on toggle", { default = false }, function(v)
		self.NotifyToggles = v
	end)
	s:Section("Colors")
	s:Dropdown("Color style", { "One color", "By category", tip = "Everything wears the accent, or each category its own gem" }, function(v)
		self.Jewels = v == "By category"
		self:SetAccent(self.Accent)
	end)
	s:Color("Accent", { default = self.Accent, presets = PRESETS, tip = "Dark colors are brightened: black becomes silver" }, function(c)
		self:SetAccent(c)
	end)
	s:Section("Profile")
	s:Button("Copy profile", { icon = "two-stacked-squares", tip = "Puts this profile on your clipboard as text" }, function()
		if setclipboard then
			setclipboard(self:Export())
			self:Notify("Profile copied", nil, 2, "check-large")
		else
			self:Notify("Can't copy", "No clipboard access here", 3, "triangle-exclamation")
		end
	end)
	local import
	import = s:TextBox("Paste profile", { max = 200000, tip = "Press Enter to add it as a new profile" }, function(v)
		if v ~= "" and not self._loading then
			import.Value = ""
			self:Import(v)
			if import._paint then
				import._paint()
			end
		end
	end)
	s:Section("About")
	s:Button("Unload", { icon = "trash-can", tip = "Turns everything off and removes the window" }, function()
		self:Dialog("Unload?", "This turns every module off and removes the window. Your profile is saved.", { "Cancel", "Unload" }, function(choice)
			if choice == "Unload" then
				self:Destroy()
			end
		end)
	end)
	s:Label("Right-click a setting to reset it, or a tile to favorite it. Click a slider's number to type one.")
	s:Label("Meowthjrlib, made by meowthjr")
	if not self._store.Disk then
		s:Label("No file access here, so profiles last until you leave.")
	end
end

---------------------------------------------------------------- input and lifetime
-- Calls fn(target, isOption) for everything that can have a key.
function UI:_binds(fn)
	for _, m in self.Modules do
		if not m.Hidden then
			fn(m, false)
			for _, o in m.Options do
				if o.Kind == "Toggle" or o.Kind == "Button" then
					fn(o, true)
				end
			end
		end
	end
end

-- Waits for a key for target, or stops waiting if it already was. nil stops.
function UI:_listen(target)
	local was = self._listening
	self._pendingMod = nil
	self._listening = target ~= was and target or nil
	for _, t in { was or false, target or false } do
		if t then
			local paint = t._paint or t._paintPage
			if paint then
				paint()
			end
		end
	end
end

function UI:_capture(bind)
	local t = self._listening
	self._listening, self._pendingMod = nil, nil
	local last = bind:match("[^%+]+$")
	if last == "Backspace" then
		if t.Kind == "Key" then
			t:Reset()
		else
			t:SetKey(nil)
		end
	elseif last ~= "Escape" then
		local users = {}
		self:_binds(function(x)
			if x ~= t and x.Key == bind then
				table.insert(users, x.Name)
			end
		end)
		if t.Kind == "Key" and not t.Shared and #users > 0 then
			self:Notify("Key taken", users[1] .. " uses " .. prettyBind(bind), 3, "keyboard")
		elseif t.Kind ~= "Key" and bind == self.Key then
			self:Notify("Key taken", prettyBind(bind) .. " opens the window", 3, "keyboard")
		else
			if #users > 0 and t.Kind ~= "Key" then
				self:Notify("Shared key", users[1] .. " also uses " .. prettyBind(bind), 3, "keyboard")
			end
			if t.Kind == "Key" then
				t:Set(bind)
			else
				t:SetKey(bind)
			end
		end
	end
	local paint = t._paint or t._paintPage
	if paint then
		paint()
	end
end

-- Runs whatever is bound to bind. name is the key to watch for release.
function UI:_fire(bind, name)
	if bind == self.Key then
		self:SetOpen(not self.Open)
		return true
	end
	local hit = false
	self:_binds(function(x, isOption)
		if x.Key ~= bind then
			return
		end
		hit = true
		if isOption then
			x:_press()
		elseif x.KeyMode == "Hold" then
			self._held[name] = self._held[name] or {}
			table.insert(self._held[name], x)
			x:Set(true)
		else
			x:Toggle_()
		end
	end)
	return hit
end

function UI:_inputs()
	self:_on(UIS.InputChanged, function(i)
		local isMouse = i.UserInputType == Enum.UserInputType.MouseMovement
		if isMouse and self._tipLabel.Visible then
			local x = math.min(i.Position.X + 14, self.Gui.AbsoluteSize.X - self._tipLabel.AbsoluteSize.X - 6)
			self._tipLabel.Position = UDim2.fromOffset(x, i.Position.Y + 18)
		end
		local d = self._dragging
		if d and (i == d.input or (isMouse and d.input.UserInputType == Enum.UserInputType.MouseButton1)) then
			d.move(i.Position)
		end
	end)
	self:_on(UIS.InputEnded, function(i)
		local d = self._dragging
		if d and (i == d.input or i.UserInputType == d.input.UserInputType) then
			self:_endDrag()
		end
		local name = inputName(i)
		-- A modifier let go without another key is the key itself.
		if name and self._listening and self._pendingMod == name then
			self:_capture(name)
			return
		end
		-- Not gated on chat focus: a held key must always release.
		local held = name and self._held[name]
		if held then
			self._held[name] = nil
			for _, m in held do
				m:Set(false)
			end
		end
	end)
	-- Alt-tabbing away swallows the release event.
	self:_on(UIS.WindowFocusReleased, function()
		local held = self._held
		self._held = {}
		for _, modules in held do
			for _, m in modules do
				m:Set(false)
			end
		end
	end)
	self:_on(UIS.InputBegan, function(i, processed)
		local name = inputName(i)
		if not name or UIS:GetFocusedTextBox() then
			return
		end
		if self._listening then
			if MODS[name] then
				self._pendingMod = name
			else
				self:_capture(withMods(name))
			end
			return
		end
		if processed then
			return
		end
		-- A combination wins over the plain key; with no match, the plain key still works.
		local full = withMods(name)
		if self:_fire(full, name) then
			return
		end
		if name == "F" and self.Open and UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
			task.defer(self._search.CaptureFocus, self._search)
			return
		end
		if full ~= name then
			self:_fire(name, name)
		end
	end)
	local since = 0
	self:_on(RunService.Heartbeat, function(dt)
		self:_ambient(dt)
		for _, m in self._widgets do
			if m.On and m._widgetTick then
				m._widgetTick()
			end
		end
		self._fps += (1 / math.max(dt, 0.001) - self._fps) * 0.05
		since += dt
		if since < 0.25 then
			return
		end
		since = 0
		for _, m in self._widgets do
			if m.On then
				m:_updateWidget()
			end
		end
	end)
	self:_on(self.Gui:GetPropertyChangedSignal("AbsoluteSize"), function()
		self:_layout()
	end)
end

-- Call once after creating your modules: loads the saved profile and opens the window.
function UI:Start(opts)
	assert(not self._started, "Start was already called")
	opts = opts or {}
	local saved = cleanName(self._store.read("_active.txt") or "")
	self.Profile = saved ~= "" and saved or "Default"
	self._data = self:_read(self.Profile)
	self:_layout()
	self:_apply(true)
	self._started = true
	self:_paintProfiles()
	self._openBtn.Visible = UIS.TouchEnabled
	if opts.closed then
		self:Notify(self.Title, "Press " .. prettyBind(self.Key) .. " to open", 4, "keyboard")
	else
		self:SetOpen(true)
	end
	return self
end

-- Saves, turns every module off through its callback, and removes everything.
function UI:Destroy()
	if self.Dead then
		return
	end
	if self._started then
		self:SaveNow()
	end
	self.Dead = true
	for _, c in self._conns do
		c:Disconnect()
	end
	for _, m in self.Modules do
		if m.On and m.Callback then
			task.spawn(m.Callback, false)
		end
		m.On = false
	end
	self.Gui:Destroy()
	if self._blur then
		self._blur:Destroy()
	end
	if self._registry[self.Title] == self then
		self._registry[self.Title] = nil
	end
end

function Lib.new(title, opts)
	assert(type(title) == "string" and cleanName(title) ~= "", "Lib.new needs a title")
	opts = opts or {}
	assert(opts.key == nil or validBind(opts.key), "Unknown key '" .. tostring(opts.key) .. "'")
	-- Running the same script twice replaces the first window instead of stacking a second.
	local env = getgenv and getgenv() or _G
	env.MeowthjrlibWindows = env.MeowthjrlibWindows or {}
	local old = env.MeowthjrlibWindows[title]
	if old then
		old:Destroy()
	end
	local accent = visible(toColor(opts.accent) or DEFAULT_ACCENT)
	local self = setmetatable({
		Title = title, Key = opts.key or "RightShift", Accent = accent, Ink = inkOn(accent),
		Profile = "Default", Modules = {}, Open = false, Dead = false, Scale = 1, Dim = true, Blur = false, Jewels = false,
		ReducedMotion = GuiService.ReducedMotionEnabled, NotifyToggles = false,
		_conns = {}, _byId = {}, _cats = {}, _widgets = {}, _groups = {}, _nav = {}, _catCount = 0, _twinkle = 0, _sinceGlint = 0, _w = WIDTH, _h = HEIGHT, _profilesOpen = false, _profilesHeight = 0, _held = {}, _afterDrag = {}, _size = Vector2.new(WIDTH, HEIGHT), _fps = 60, _data = {},
		_filterName = "All", _query = "", _editing = false, _rootPos = Vector2.zero, _registry = env.MeowthjrlibWindows,
		_store = opts.store or makeStore(title),
	}, UI)
	self:_build(title)
	self:_addNav("All", "All modules", "four-squares-grid")
	self:_addNav("Favorites", "Favorites", "star")
	self:_buildSettings()
	self:_inputs()
	env.MeowthjrlibWindows[title] = self
	return self
end

return Lib
