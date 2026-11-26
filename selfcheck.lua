-- Returns a function: selfcheck(Lib). Uses memory storage, so it never touches saved profiles.
return function(Lib)
	local files = {}
	local function store()
		return {
			Disk = false,
			read = function(f) return files[f] end,
			write = function(f, s) files[f] = s return true end,
			delete = function(f) files[f] = nil end,
			list = function()
				local o = {}
				for f in files do table.insert(o, f) end
				return o
			end,
		}
	end
	local calls = {}
	local function build()
		calls = {}
		local ui = Lib.new("Self check", { store = store() })
		local m = ui:Category("A"):Module("One", { key = "P" }, function(on) table.insert(calls, on) end)
		local o = {
			t = m:Toggle("T", {}), s = m:Slider("S", { min = 0, max = 10, step = 0.5, default = 2 }),
			d = m:Dropdown("D", { "x", "y" }), mu = m:Dropdown("M", { "x", "y", "z", multi = true }),
			b = m:TextBox("B", {}), c = m:Color("C", { default = "112233" }),
		}
		m:Section("More")
		o.r = m:Range("R", { min = 0, max = 10, default = { 2, 6 } })
		o.a = m:Color("CA", { default = "00ff00", alpha = 0.5 })
		o.dyn = m:Dropdown("Dyn", {})
		o.hid = m:Toggle("Hid", { showIf = o.t })
		o.btn = m:Button("Btn", { key = "J" }, function() table.insert(calls, "btn") end)
		o.off = m:Toggle("Off", { default = true })
		o.many = m:TextBox("Many", { lines = 3 })
		o.prog = m:Progress("Prog")
		m:Image(1, 40)
		m:Label("<b>rich</b>", { rich = true })
		m:Label("note")
		m:Widget(function() return "w" end)
		o.kv = ui:Category("A"):KeyViewer()
		ui:Start({ closed = true })
		return ui, m, o
	end

	local ui, m, o = build()
	o.s:Set(99) assert(o.s.Value == 10, "clamp")
	o.s:Set(3.3) assert(o.s.Value == 3.5, "step")
	o.s:Set(0 / 0) o.s:Set("x") assert(o.s.Value == 3.5, "reject NaN and text")
	o.d:Set("nope") assert(o.d.Value == "x", "reject unknown choice")
	o.mu:Set({ "z", "bad", "x" }) assert(table.concat(o.mu.Value) == "xz", "multi filter and order")
	o.r:Set({ 9, 3 }) assert(o.r.Value[1] == 3 and o.r.Value[2] == 9, "range ordered")
	o.r:Set({ "x" }) assert(o.r.Value[2] == 9, "bad range refused")
	o.a:SetAlpha(7) assert(o.a.Alpha == 1, "alpha clamped") o.a:SetAlpha(0.25)
	assert(o.dyn.Value == nil, "empty dropdown")
	o.dyn:SetChoices({ "p", "q" }) assert(o.dyn.Value == "p", "first choice picked") o.dyn:Set("q")
	assert(not o.hid:_shown(), "hidden until T is on")
	o.off:Set(false) o.off:SetKey("LeftControl+MouseButton3") assert(o.off.Key, "combo key")
	o.off:SetKey("Nope+F") assert(o.off.Key == "LeftControl+MouseButton3", "bad combo refused")
	assert(ui:_fire("J", "J") and table.remove(calls) == "btn", "button key")
	assert(ui:_fire("LeftControl+MouseButton3", "MouseButton3") and o.off.Value, "toggle key") o.off:Set(false)
	assert(not ui:_fire("Y", "Y"), "unbound key")
	ui:_listen(o.btn) ui:_capture("LeftShift+G") assert(o.btn.Key == "LeftShift+G" and not ui._listening, "capture")
	ui:_listen(o.btn) ui:_capture(ui.Key) assert(o.btn.Key == "LeftShift+G", "open key protected")
	ui:_listen(o.btn) ui:_capture("Escape") assert(o.btn.Key == "LeftShift+G", "escape cancels")
	ui:_listen(m) ui:_capture("Backspace") assert(m.Key == nil, "backspace clears") m:SetKey("P")
	o.kv:Set(true) o.kv._widgetTick()
	local tall = o.kv._widget.Size.Y.Offset
	o.kv._byName["Side buttons"]:Set(true) assert(o.kv._widget.Size.Y.Offset > tall, "key viewer grows")
	o.kv._byName["Size"]:Set(180) assert(o.kv._widget.Size.X.Offset > 250, "key viewer size")
	ui:_listen(o.kv._byName["Back button sends"]) ui:_capture("P")
	assert(o.kv._byName["Back button sends"].Value == "P", "viewer keys can be shared")
	o.prog:Update(2) assert(o.prog.Value == 1, "progress clamped")
	ui:Dialog("Title", "Text", { "No", "Yes" })()
	o.b:Set("hey") o.c:Set("ff0000") o.t:Set(true)
	m:Set(true) m:Set(true) assert(#calls == 1 and calls[1] == true, "no duplicate callback")
	m:SetKey("K") m:SetKey("NotAKey") assert(m.Key == "K", "bad key ignored")
	for _, page in ui.Modules do ui:_openPage(page) end
	ui:_openPage(m)
	assert(o.hid._row.Visible, "row shown once T is on")
	o.t:Set(false) assert(not o.hid._row.Visible, "row hides live") o.t:Set(true)
	ui:SetAccent(Color3.new(0, 0, 0)) -- would vanish on the dark surfaces
	assert(ui.Accent.G > 0.35, "dark accent lightened")
	ui:SetAccent(Color3.new(1, 1, 0))
	assert(ui.Ink.G < 0.3, "dark text on a bright accent")
	ui:_closePage()
	assert(not pcall(function() ui:Category("A"):Module("One") end), "duplicate module")
	local ok = ui._settings._byName["Open key"]
	ok:Set("Insert") ok:Set("Escape") ok:Set("Nope") assert(ui.Key == "Insert", "open key validated")
	m:_placeWidget(Vector2.new(0.4, 0.3))
	ui:Destroy()
	assert(calls[#calls] == false, "destroy turns modules off")

	ui, m, o = build()
	assert(m.On and calls[1] == true and m.Key == "K", "module restored")
	assert(o.s.Value == 3.5 and o.b.Value == "hey" and o.t.Value and o.c.Value:ToHex() == "ff0000", "options restored")
	assert(table.concat(o.mu.Value) == "xz", "multi restored")
	assert(ui.Key == "Insert", "open key restored")
	assert(o.r.Value[1] == 3 and o.r.Value[2] == 9 and o.a.Alpha == 0.25, "range and alpha restored")
	assert(o.off.Value == false and o.off.Key == "LeftControl+MouseButton3" and o.btn.Key == "LeftShift+G", "option keys restored")
	o.dyn:SetChoices({ "p" }) assert(o.dyn.Value == "p", "fallback choice")
	o.dyn:SetChoices({ "p", "q" }) assert(o.dyn.Value == "q", "saved choice comes back")
	local late = m:Toggle("Off 2", { default = true }) late:Set(false) assert(late.Value == false, "late option")
	assert((m._widgetPos - Vector2.new(0.4, 0.3)).Magnitude < 0.01, "widget restored")

	ui:SetProfile("Second") o.s:Set(7) m:SetKey(nil)
	ui:SetProfile("Default") assert(o.s.Value == 3.5 and m.Key == "K", "profiles are separate")
	ui:SetProfile("Second") assert(o.s.Value == 7 and m.Key == nil, "cleared key stays cleared")
	ui:DeleteProfile("Second") assert(table.find(ui:Profiles(), "Second"), "active profile can't be deleted")
	assert(ui:Import(ui:Export()) and ui.Profile == "Imported", "import")
	assert(not ui:Import("{bad") and ui.Profile == "Imported", "bad import refused")
	files["Broken.json"] = "{oops"
	ui:SetProfile("Broken") assert(files["Broken.bad"] == "{oops" and o.s.Value == 2, "damaged profile backed up")
	ui:SetProfile("../../x") assert(ui.Profile == "x", "profile name sanitized")

	-- boxes without a switch, keybinds, disabled settings, runtime changes, toggle colors, tabs, themes
	local cat = ui:Category("B")
	local g = cat:Group("Plain")
	g:Set(true) assert(g.NoSwitch and not g.On, "group has no switch")
	local pressed = 0
	local kb = g:Keybind("Dash", { default = "Q" }, function() pressed += 1 end)
	assert(ui:_fire("Q", "Q") and pressed == 1, "keybind fires")
	ui:_listen(kb) ui:_capture("Backspace") assert(kb.Value == "" and kb.Key == nil, "keybind cleared")
	assert(not ui:_fire("Q", "Q"), "cleared keybind does nothing")
	ui:_listen(kb) ui:_capture("E") assert(kb.Key == "E" and not kb:IsDown(), "keybind set")
	local fly = g:Toggle("Fly")
	local speed = g:Slider("Speed", { enabledIf = fly, reason = "Turn on Fly" })
	assert(speed._lock and speed._row:GetAttribute("Locked"), "disabled until Fly is on")
	fly:Set(true) assert(not speed._lock, "enabled with Fly")
	speed:SetDisabled(true, "Busy") assert(speed._lock, "SetDisabled")
	speed:SetDisabled(false) assert(not speed._lock, "enabled again")
	fly:Set(false)
	speed:SetName("Fly speed") assert(speed._row.Parent == g._box and g._byName.Speed == speed and speed._lock, "renamed in place")
	local esp = g:Toggle("ESP")
	local col = esp:AddColor("ESP color", { default = "FF4040" })
	assert(col._swatch and col._swatch.Parent == esp._row, "swatch on the toggle row")
	esp:SetName("Boxes") assert(col._swatch and col._swatch.Parent == esp._row, "swatch survives a rename")
	col:Destroy() assert(not g._byName["ESP color"] and #esp._attached == 0, "attachment removed")
	local copy = g:CopyText("Code", "abc") copy:SetText("xyz") assert(copy.Text == "xyz", "copy text")
	local pl = g:PlayerDropdown("Target", { includeSelf = true })
	assert(table.find(pl.Choices, game:GetService("Players").LocalPlayer.Name), "player list")
	local seen = {}
	for _, x in g.Options do
		assert(not seen[x._row.LayoutOrder], "rows keep a unique order after a delete")
		seen[x._row.LayoutOrder] = true
	end
	g:SetName("Plain box") g:SetTip("No switch")
	local t1, t2 = cat:Tab("One"), cat:Tab("Two")
	local a1, a2 = t1:Module("In one"), t2:Module("In two")
	ui:_setFilter("B")
	assert(ui._tabBar.Visible and a1._cell.Visible and not a2._cell.Visible and g._cell.Visible, "tabs filter")
	cat.ActiveTab = "Two" ui:_filter() assert(a2._cell.Visible and not a1._cell.Visible, "other tab")
	a2:Destroy() assert(not ui._byId["B/In two"] and not a2._cell, "module destroyed")
	ui:AddTheme("Test", { Window = "101010", Tile = "202020", accent = "FF0000" })
	assert(table.find(ui._settings._byName.Theme.Choices, "Test"), "theme added")
	assert(not pcall(function() ui:AddTheme("Bad", { Window = "101010", Tile = "101010" }) end), "same colors refused")
	ui:SetTheme("Light") assert(ui.Theme == "Light" and g._box.BackgroundColor3:ToHex():upper() == "FCFBFA", "light theme")
	ui:SetTheme("Graphite") assert(g._box.BackgroundColor3:ToHex():upper() == "2B2927", "back to dark")
	local logo = Lib.new("Logo check", { store = store(), logo = 1, theme = { Window = "111111", Tile = "222222" } })
	assert(#logo._markTiles == 0 and logo.Theme == "Custom", "logo and custom theme")
	local unloaded = false
	logo:OnUnload(function() unloaded = true end)
	logo:Destroy()
	assert(unloaded, "OnUnload runs")
	local bad = g:Toggle("Bad", {}, function(v) if v then error("boom") end end)
	bad:Set(true) assert(ui._errAt[bad:_where()] and bad.Value, "callback error caught")

	local again = Lib.new("Self check", { store = store() })
	assert(ui.Dead, "rerun replaces the old window")
	again:Destroy()
	return "Meowthjrlib self-check passed"
end
