-- Dev Explorer + Properties (Studio-only)
-- Put this LocalScript in StarterPlayerScripts 
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

-- Try Selection service (Studio-only)
local Selection do
	local ok, svc = pcall(function() return game:GetService("Selection") end)
	Selection = ok and svc or nil
end

-- =============== GUI ===============
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DevExplorerGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Basic theme
local COLORS = {
	bg = Color3.fromRGB(34, 34, 38),
	panel = Color3.fromRGB(40, 40, 44),
	label = Color3.fromRGB(230, 230, 235),
	text = Color3.fromRGB(240, 240, 240),
	field = Color3.fromRGB(50, 50, 55),
	accent = Color3.fromRGB(0, 170, 255),
	subtle = Color3.fromRGB(200, 200, 200),
}

-- Explorer panel
local explorerPanel = Instance.new("Frame")
explorerPanel.Name = "ExplorerPanel"
explorerPanel.Size = UDim2.new(0, 340, 1, 0)
explorerPanel.Position = UDim2.new(0, 0, 0, 0)
explorerPanel.BackgroundColor3 = COLORS.bg
explorerPanel.BorderSizePixel = 0
explorerPanel.Parent = screenGui

local explorerHeader = Instance.new("TextLabel")
explorerHeader.BackgroundTransparency = 1
explorerHeader.TextXAlignment = Enum.TextXAlignment.Left
explorerHeader.Font = Enum.Font.SourceSansSemibold
explorerHeader.TextSize = 18
explorerHeader.TextColor3 = COLORS.label
explorerHeader.Text = "Explorer (Studio-only)"
explorerHeader.Size = UDim2.new(1, -16, 0, 28)
explorerHeader.Position = UDim2.new(0, 12, 0, 6)
explorerHeader.Parent = explorerPanel

local explorerList = Instance.new("ScrollingFrame")
explorerList.Name = "ExplorerList"
explorerList.BackgroundTransparency = 1
explorerList.BorderSizePixel = 0
explorerList.Position = UDim2.new(0, 0, 0, 40)
explorerList.Size = UDim2.new(1, 0, 1, -40)
explorerList.CanvasSize = UDim2.new(0, 0, 0, 0)
explorerList.ScrollBarThickness = 6
explorerList.Parent = explorerPanel

local explorerLayout = Instance.new("UIListLayout")
explorerLayout.SortOrder = Enum.SortOrder.LayoutOrder
explorerLayout.Parent = explorerList

-- Properties panel
local propsPanel = Instance.new("Frame")
propsPanel.Name = "PropertiesPanel"
propsPanel.Size = UDim2.new(0, 360, 1, 0)
propsPanel.Position = UDim2.new(0, 350, 0, 0) -- 340 + 10 gutter
propsPanel.BackgroundColor3 = COLORS.panel
propsPanel.BorderSizePixel = 0
propsPanel.Parent = screenGui

local propsHeader = explorerHeader:Clone()
propsHeader.Text = "Properties"
propsHeader.Parent = propsPanel

local propsList = Instance.new("ScrollingFrame")
propsList.Name = "PropsList"
propsList.BackgroundTransparency = 1
propsList.BorderSizePixel = 0
propsList.Position = UDim2.new(0, 0, 0, 40)
propsList.Size = UDim2.new(1, 0, 1, -40)
propsList.CanvasSize = UDim2.new(0, 0, 0, 0)
propsList.ScrollBarThickness = 6
propsList.Parent = propsPanel

local propsLayout = Instance.new("UIListLayout")
propsLayout.SortOrder = Enum.SortOrder.LayoutOrder
propsLayout.Parent = propsList

-- Optional highlight fallback (if Selection is unavailable)
local highlight = Instance.new("Highlight")
highlight.Enabled = false
highlight.FillTransparency = 1
highlight.OutlineColor = COLORS.accent
highlight.Parent = workspace

local function findHighlightAdornee(inst)
	local x = inst
	while x do
		if x:IsA("BasePart") or x:IsA("Model") then return x end
		x = x.Parent
	end
	return nil
end

local function safeSelect(inst)
	if Selection then
		pcall(function() Selection:Set({inst}) end)
	end
	local adornee = findHighlightAdornee(inst)
	if adornee then
		highlight.Adornee = adornee
		highlight.Enabled = true
	else
		highlight.Enabled = false
	end
end

-- =============== Helpers ===============
local function isDescendantOf(a, b)
	local n = a
	while n do
		if n == b then return true end
		n = n.Parent
	end
	return false
end

local function pathString(inst)
	local names = {}
	local n = inst
	while n do
		table.insert(names, 1, n.Name)
		n = n.Parent
	end
	return table.concat(names, ".")
end

local function hasChildren(inst)
	local ok, kids = pcall(function() return inst:GetChildren() end)
	if not ok or not kids then return false end
	for _, ch in ipairs(kids) do
		if ch and ch.Parent == inst then
			return true
		end
	end
	return false
end

-- Type parsing/formatting for attributes
local function trim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end

local function splitCSV(s)
	local out = {}
	for token in s:gmatch("[^,]+") do
		table.insert(out, trim(token))
	end
	return out
end

local function parseColor3(s)
	-- Accept "#RRGGBB" or "r,g,b" (0-255 or 0-1)
	s = trim(s)
	if s:sub(1,1) == "#" and (#s == 7 or #s == 4) then
		local hex = s:sub(2)
		if #hex == 3 then
			local r = tonumber(hex:sub(1,1)..hex:sub(1,1),16)
			local g = tonumber(hex:sub(2,2)..hex:sub(2,2),16)
			local b = tonumber(hex:sub(3,3)..hex:sub(3,3),16)
			return Color3.fromRGB(r,g,b)
		else
			local r = tonumber(hex:sub(1,2),16)
			local g = tonumber(hex:sub(3,4),16)
			local b = tonumber(hex:sub(5,6),16)
			return Color3.fromRGB(r,g,b)
		end
	else
		local parts = splitCSV(s)
		if #parts == 3 then
			local r = tonumber(parts[1])
			local g = tonumber(parts[2])
			local b = tonumber(parts[3])
			if r and g and b then
				if (r > 1 or g > 1 or b > 1) then
					return Color3.fromRGB(math.clamp(math.floor(r+0.5),0,255),
						math.clamp(math.floor(g+0.5),0,255),
						math.clamp(math.floor(b+0.5),0,255))
				else
					return Color3.new(r,g,b)
				end
			end
		end
	end
	return nil
end

local function parseVector3(s)
	local parts = splitCSV(s)
	if #parts == 3 then
		local x = tonumber(parts[1])
		local y = tonumber(parts[2])
		local z = tonumber(parts[3])
		if x and y and z then
			return Vector3.new(x,y,z)
		end
	end
	return nil
end

local function toDisplayString(v)
	local t = typeof(v)
	if t == "Color3" then
		local r,g,b = math.floor(v.R*255+0.5), math.floor(v.G*255+0.5), math.floor(v.B*255+0.5)
		return string.format("%d,%d,%d", r,g,b)
	elseif t == "Vector3" then
		return string.format("%g,%g,%g", v.X, v.Y, v.Z)
	elseif t == "boolean" then
		return v and "true" or "false"
	else
		return tostring(v)
	end
end

local function inferAndCast(text)
	local s = trim(text)
	if s == "" then return "" end
	local lower = s:lower()
	if lower == "true" then return true end
	if lower == "false" then return false end
	local n = tonumber(s)
	if n ~= nil then return n end
	local c3 = parseColor3(s)
	if c3 then return c3 end
	local v3 = parseVector3(s)
	if v3 then return v3 end
	return s
end

-- =============== Explorer state ===============
local instanceToState = setmetatable({}, { __mode = "k" })
-- state = { instance, depth, expanded, row, children = {} }

local function makeExplorerRow(depth, name, className, hasKids)
	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, -10, 0, 22)

	local toggle = Instance.new("TextButton")
	toggle.Name = "Toggle"
	toggle.Size = UDim2.new(0, 20, 1, 0)
	toggle.Position = UDim2.new(0, 6 + depth * 14, 0, 0)
	toggle.BackgroundTransparency = 1
	toggle.TextXAlignment = Enum.TextXAlignment.Center
	toggle.Font = Enum.Font.SourceSansBold
	toggle.TextSize = 16
	toggle.TextColor3 = COLORS.subtle
	toggle.Text = hasKids and "›" or ""
	toggle.AutoButtonColor = true
	toggle.Parent = row

	local label = Instance.new("TextButton")
	label.Name = "Label"
	label.BackgroundTransparency = 1
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Font = Enum.Font.SourceSans
	label.TextSize = 16
	label.TextColor3 = COLORS.label
	label.AutoButtonColor = true
	label.Position = UDim2.new(0, 26 + depth * 14, 0, 0)
	label.Size = UDim2.new(1, -40 - depth * 14, 1, 0)
	label.Text = string.format("%s  [%s]", name, className)
	label.Parent = row

	return row, toggle, label
end

local function refreshCanvasSize()
	local abs = explorerLayout.AbsoluteContentSize
	explorerList.CanvasSize = UDim2.new(0, 0, 0, abs.Y + 20)
end
explorerLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(refreshCanvasSize)

local function refreshPropsCanvas()
	local abs = propsLayout.AbsoluteContentSize
	propsList.CanvasSize = UDim2.new(0, 0, 0, abs.Y + 10)
end
propsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(refreshPropsCanvas)

-- =============== Properties ===============
local currentSelection

local function clearProps()
	for _, child in ipairs(propsList:GetChildren()) do
		if child:IsA("GuiObject") then child:Destroy() end
	end
end

local function addRow(labelText, rightGui) -- rightGui is created by caller
	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, -12, 0, 26)

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Font = Enum.Font.SourceSans
	label.TextSize = 16
	label.TextColor3 = COLORS.label
	label.Text = labelText
	label.Size = UDim2.new(0.4, 0, 1, 0)
	label.Parent = row

	rightGui.Position = UDim2.new(0.42, 0, 0, 0)
	rightGui.Size = UDim2.new(0.58, 0, 1, 0)
	rightGui.Parent = row

	row.Parent = propsList
	return row
end

local function makeTextField(text, placeholder)
	local tb = Instance.new("TextBox")
	tb.BackgroundColor3 = COLORS.field
	tb.BorderSizePixel = 0
	tb.TextXAlignment = Enum.TextXAlignment.Left
	tb.Font = Enum.Font.SourceSans
	tb.TextSize = 16
	tb.TextColor3 = COLORS.text
	tb.Text = text or ""
	tb.PlaceholderText = placeholder or ""
	return tb
end

local function makeButton(text)
	local btn = Instance.new("TextButton")
	btn.BackgroundColor3 = COLORS.field
	btn.BorderSizePixel = 0
	btn.TextColor3 = COLORS.text
	btn.Font = Enum.Font.SourceSansSemibold
	btn.TextSize = 15
	btn.Text = text
	return btn
end

local function showProperties(inst)
	clearProps()
	if not inst then return end

	-- Basic
	do
		local nameField = makeTextField(inst.Name)
		nameField.FocusLost:Connect(function(enter)
			if enter and inst.Parent then
				pcall(function() inst.Name = nameField.Text end)
			end
		end)
		addRow("Name", nameField)
	end
	do
		local classLabel = Instance.new("TextLabel")
		classLabel.BackgroundTransparency = 1
		classLabel.TextXAlignment = Enum.TextXAlignment.Left
		classLabel.Font = Enum.Font.SourceSans
		classLabel.TextSize = 16
		classLabel.TextColor3 = COLORS.text
		classLabel.Text = inst.ClassName
		addRow("Class", classLabel)
	end
	do
		local parentBtn = makeButton(inst.Parent and inst.Parent.Name or "nil")
		parentBtn.MouseButton1Click:Connect(function()
			if inst.Parent then
				safeSelect(inst.Parent)
				currentSelection = inst.Parent
				showProperties(currentSelection)
			end
		end)
		addRow("Parent", parentBtn)
	end
	do
		local pathLabel = Instance.new("TextLabel")
		pathLabel.BackgroundTransparency = 1
		pathLabel.TextXAlignment = Enum.TextXAlignment.Left
		pathLabel.Font = Enum.Font.SourceSans
		pathLabel.TextSize = 14
		pathLabel.TextColor3 = COLORS.subtle
		pathLabel.Text = pathString(inst)
		local row = addRow("Path", pathLabel)
		row.Size = UDim2.new(1, -12, 0, 40)
		pathLabel.TextWrapped = true
	end

	-- Attributes header
	do
		local h = Instance.new("TextLabel")
		h.BackgroundTransparency = 1
		h.TextXAlignment = Enum.TextXAlignment.Left
		h.Font = Enum.Font.SourceSansSemibold
		h.TextSize = 16
		h.TextColor3 = COLORS.label
		h.Text = "Attributes"
		local row = addRow("", h)
		row.Size = UDim2.new(1, -12, 0, 20)
	end

	-- Existing attributes (sorted)
	local attrs = inst:GetAttributes()
	local names = {}
	for k in pairs(attrs) do table.insert(names, k) end
	table.sort(names, function(a,b) return a:lower() < b:lower() end)

	for _, attrName in ipairs(names) do
		local value = attrs[attrName]
		local t = typeof(value)

		local container = Instance.new("Frame")
		container.BackgroundTransparency = 1

		-- Value input
		local valueField = makeTextField(toDisplayString(value))
		valueField.Size = UDim2.new(0.65, -4, 1, 0)

		-- Remove button
		local removeBtn = makeButton("Remove")
		removeBtn.Size = UDim2.new(0.35, 0, 1, 0)
		removeBtn.Position = UDim2.new(0.65, 4, 0, 0)

		valueField.Parent = container
		removeBtn.Parent = container

		valueField.FocusLost:Connect(function(enter)
			if not enter then return end
			if not inst.Parent then return end
			local casted = inferAndCast(valueField.Text)
			pcall(function() inst:SetAttribute(attrName, casted) end)
			-- Re-render attribute rows to reflect normalized display
			showProperties(inst)
		end)

		removeBtn.MouseButton1Click:Connect(function()
			if not inst.Parent then return end
			pcall(function()
				if inst.RemoveAttribute then
					inst:RemoveAttribute(attrName)
				else
					inst:SetAttribute(attrName, nil)
				end
			end)
			showProperties(inst)
		end)

		addRow(attrName .. " (" .. t .. ")", container)
	end

	-- Add new attribute
	do
		local container = Instance.new("Frame")
		container.BackgroundTransparency = 1

		local nameField = makeTextField("", "name")
		nameField.Size = UDim2.new(0.35, -4, 1, 0)

		local valueField = makeTextField("", "value (number, true/false, r,g,b, x,y,z, #hex, or text)")
		valueField.Size = UDim2.new(0.45, -4, 1, 0)
		valueField.Position = UDim2.new(0.35, 4, 0, 0)

		local addBtn = makeButton("Add")
		addBtn.Size = UDim2.new(0.20, 0, 1, 0)
		addBtn.Position = UDim2.new(0.80, 4, 0, 0)

		nameField.Parent = container
		valueField.Parent = container
		addBtn.Parent = container

		local function commit()
			local key = trim(nameField.Text or "")
			if key == "" or not inst.Parent then return end
			local casted = inferAndCast(valueField.Text or "")
			pcall(function() inst:SetAttribute(key, casted) end)
			nameField.Text = ""
			valueField.Text = ""
			showProperties(inst)
		end

		valueField.FocusLost:Connect(function(enter) if enter then commit() end end)
		addBtn.MouseButton1Click:Connect(commit)

		addRow("Add attribute", container)
	end

	refreshPropsCanvas()
end

-- =============== Tree / Expansion ===============
local function buildChildren(parentState)
	-- Destroy any existing rendered children rows
	for _, childState in ipairs(parentState.children) do
		if childState.row then childState.row:Destroy() end
		instanceToState[childState.instance] = nil
	end
	parentState.children = {}

	local ok, kids = pcall(function() return parentState.instance:GetChildren() end)
	if not ok or not kids then return end

	-- Filter out our own GUI
	local filtered = {}
	for _, k in ipairs(kids) do
		if k and k.Parent == parentState.instance and not isDescendantOf(k, screenGui) then
			table.insert(filtered, k)
		end
	end

	-- Sort: Folders/Models first, then alphabetical
	table.sort(filtered, function(a, b)
		local ap = (a:IsA("Folder") or a:IsA("Model")) and 0 or 1
		local bp = (b:IsA("Folder") or b:IsA("Model")) and 0 or 1
		if ap ~= bp then return ap < bp end
		return a.Name:lower() < b.Name:lower()
	end)

	local created = 0
	for _, child in ipairs(filtered) do
		local childHas = hasChildren(child)
		local row, toggle, label = makeExplorerRow(parentState.depth + 1, child.Name, child.ClassName, childHas)
		-- LayoutOrder: keep children directly after parent, using fractional ordering
		row.LayoutOrder = parentState.row.LayoutOrder + (#parentState.children + 1) * 0.001
		row.Parent = explorerList

		local state = {
			instance = child,
			depth = parentState.depth + 1,
			expanded = false,
			row = row,
			children = {},
		}
		instanceToState[child] = state
		table.insert(parentState.children, state)

		toggle.MouseButton1Click:Connect(function()
			if not childHas then return end
			state.expanded = not state.expanded
			toggle.Text = state.expanded and "?" or "›"
			if state.expanded then
				buildChildren(state)
			else
				for _, grand in ipairs(state.children) do
					if grand.row then grand.row:Destroy() end
					instanceToState[grand.instance] = nil
				end
				state.children = {}
			end
			refreshCanvasSize()
		end)

		label.MouseButton1Click:Connect(function()
			if not child or not child.Parent then return end
			currentSelection = child
			safeSelect(child)
			showProperties(child)
		end)

		created += 1
		if created % 60 == 0 then task.wait() end -- throttle UI creation to avoid freezing
	end

	refreshCanvasSize()
end

local function addRoot(inst, order)
	if not inst then return end
	local hasKids = hasChildren(inst)
	local row, toggle, label = makeExplorerRow(0, inst.Name, inst.ClassName, hasKids)
	row.LayoutOrder = order
	row.Parent = explorerList

	local state = {
		instance = inst,
		depth = 0,
		expanded = false,
		row = row,
		children = {},
	}
	instanceToState[inst] = state

	toggle.MouseButton1Click:Connect(function()
		if not hasKids then return end
		state.expanded = not state.expanded
		toggle.Text = state.expanded and "?" or "›"
		if state.expanded then
			buildChildren(state)
		else
			for _, c in ipairs(state.children) do
				if c.row then c.row:Destroy() end
				instanceToState[c.instance] = nil
			end
			state.children = {}
		end
		refreshCanvasSize()
	end)

	label.MouseButton1Click:Connect(function()
		if not inst or not inst.Parent then return end
		currentSelection = inst
		safeSelect(inst)
		showProperties(inst)
	end)
end

-- Root services (client-visible; avoid ServerStorage/ServerScriptService)
local ROOTS = {
	game:GetService("Workspace"),
	game:GetService("ReplicatedStorage"),
	game:GetService("ReplicatedFirst"),
	game:GetService("StarterPlayer"),
	game:GetService("StarterGui"),
	game:GetService("StarterPack"),
	game:GetService("Lighting"),
	game:GetService("SoundService"),
	game:GetService("Players"),
}

for i, svc in ipairs(ROOTS) do
	addRoot(svc, i)
end

-- Optional: start with Workspace selected
do
	local ws = game:GetService("Workspace")
	currentSelection = ws
	safeSelect(ws)
	showProperties(ws)
end