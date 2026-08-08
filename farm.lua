local ACTIVATION_KEY = Enum.KeyCode.G
local TARGET_SPEED = 220
local BLINK_STEP = 12
local LANDING_DELAY = 1.0
local LOOP_DELAY = 0.2

local TARGET_LOOK_DIR = Vector3.new(-0.679, -0.215, -0.702)

local COORDS_1 = Vector3.new(6820.83, 17.42, 21.85)
local COORDS_2 = Vector3.new(-81.57, 49.25, 432.51)
local COORDS_4 = Vector3.new(4653.31, 17.22, 120.10)
local COORDS_5 = Vector3.new(5944.03, 24.53, 117.52)
local COORDS_3 = Vector3.new(6808.91, 17.44, -28.68)

local _1 = game:GetService("RunService")
local _2 = game:GetService("Players")
local _3 = game:GetService("VirtualInputManager")
local _4 = _2.LocalPlayer
local _5 = Instance.new("ScreenGui")
_5.Name = "BlinkGui"
_5.ResetOnSpawn = false
_5.Parent = _4:WaitForChild("PlayerGui")

local _6 = Instance.new("TextLabel")
_6.Size = UDim2.new(0, 320, 0, 40)
_6.Position = UDim2.new(0, 20, 0, 20)
_6.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
_6.BackgroundTransparency = 0.5
_6.TextColor3 = Color3.fromRGB(255, 255, 255)
_6.TextSize = 16
_6.TextXAlignment = Enum.TextXAlignment.Left
_6.Font = Enum.Font.SourceSansBold
_6.Text = " Position: Waiting..."
_6.Parent = _5

local _7 = _6:Clone()
_7.Position = UDim2.new(0, 20, 0, 65)
_7.Text = " Speed: 0.0 studs/sec"
_7.Parent = _5

local _8 = _6:Clone()
_8.Position = UDim2.new(0, 20, 0, 110)
_8.TextColor3 = Color3.fromRGB(255, 215, 0)
_8.Text = " Status: Ready. Press [G]"
_8.Parent = _5

local _9 = false

local function _10()
	_9 = false
	_3:SendKeyEvent(false, Enum.KeyCode.E, false, game)
	local c = _4.Character
	if c then
		local h = c:FindFirstChildOfClass("Humanoid")
		local r = c:FindFirstChild("HumanoidRootPart")
		if h then
			pcall(function()
				h.Sit = false
				h:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
				h:ChangeState(Enum.HumanoidStateType.GettingUp)
			end)
		end
		if r then r.Velocity = Vector3.new(0, 0, 0) end
	end
	_7.Text = " Speed: 0.0 studs/sec"
	_8.TextColor3 = Color3.fromRGB(255, 90, 90)
	_8.Text = " STOP!"
end

local function _11()
	local ca = workspace.CurrentCamera
	local c = _4.Character
	if ca and c then
		local r = c:FindFirstChild("HumanoidRootPart")
		if r then
			local cp = r.Position
			r.CFrame = CFrame.lookAt(cp, cp + Vector3.new(TARGET_LOOK_DIR.X, 0, TARGET_LOOK_DIR.Z))
			pcall(function()
				local camp = ca.CFrame.Position
				ca.CFrame = CFrame.lookAt(camp, camp + TARGET_LOOK_DIR)
			end)
		end
	end
end

local function _12()
	task.spawn(function()
		while _9 do
			local c = _4.Character
			if c then
				local h = c:FindFirstChildOfClass("Humanoid")
				if h and (h.Sit or h:GetState() == Enum.HumanoidStateType.Seated) then
					h.Sit = false
					h:ChangeState(Enum.HumanoidStateType.Jumping)
				end
			end
			task.wait()
		end
	end)
end
local function _13(t, isCheck)
	if not _9 then return end
	local c = _4.Character or _4.CharacterAdded:Wait()
	local r = c:WaitForChild("HumanoidRootPart", 5)
	local h = c:WaitForChild("Humanoid", 5)
	if not r or not h then return end
	h:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	h:ChangeState(Enum.HumanoidStateType.Physics)
	while _9 and c and c.Parent and (r.Position - t).Magnitude > 0.5 do
		if h.Sit then h.Sit = false end
		local cp = r.Position
		local dir = (t - cp).Unit
		local dl = (t - cp).Magnitude
		local cs = math.min(BLINK_STEP, dl)
		local np = cp + (dir * cs)
		local st = os.clock()
		r.CFrame = CFrame.new(np)
		r.Velocity = Vector3.new(0, 0, 0)
		local rw = cs / TARGET_SPEED
		local el = os.clock() - st
		local rem = math.max(0, rw - el)
		if rem > 0 then task.wait(rem) else _1.RenderStepped:Wait() end
		local ft = os.clock() - st
		local sp = cs / ft
		_6.Text = string.format(" Position: X: %.1f | Y: %.1f | Z: %.1f", np.X, np.Y, np.Z)
		_7.Text = string.format(" Speed: %.1f studs/sec", sp)
	end
	if _9 and isCheck and c and c.Parent then
		_11()
		local stp = os.clock()
		while _9 and (os.clock() - stp) < LANDING_DELAY do
			if not r or not r.Parent then break end
			r.CFrame = CFrame.new(t)
			r.Velocity = Vector3.new(0, 0, 0)
			task.wait(0.05)
		end
	end
	if c and c.Parent and h and r then
		r.Velocity = Vector3.new(0, 0, 0)
		pcall(function()
			h:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
			h:ChangeState(Enum.HumanoidStateType.GettingUp)
		end)
	end
end

local function _14()
	if not _9 then return end
	_3:SendKeyEvent(true, Enum.KeyCode.E, false, game)
	for i = 1, 12 do if not _9 then break end task.wait(0.05) end
	_3:SendKeyEvent(false, Enum.KeyCode.E, false, game)
end

local function _15()
	local l = 1
	_12()
	while _9 do
		_8.TextColor3 = Color3.fromRGB(255, 215, 0)
		_8.Text = string.format(" Loop %d: TP to P1", l)
		_13(COORDS_1, true)
		if not _9 then break end
		for i = 1, 5 do
			if not _9 then break end
			_8.Text = string.format(" Loop %d: Holding E (%d/5)", l, i)
			_11()
			_14()
			if not _9 then break end
			task.wait(0.1)
		end
		if not _9 then break end
		_8.Text = string.format(" Loop %d: TP to P2", l)
		_13(COORDS_2, true)
		if not _9 then break end
		_8.Text = string.format(" Loop %d: Holding E P2", l)
		_11()
		_14()
		if not _9 then break end
		_8.Text = string.format(" Loop %d: Wall 4", l)
		_13(COORDS_4, false)
		if not _9 then break end
		_8.Text = string.format(" Loop %d: Wall 5", l)
		_13(COORDS_5, false)
		if not _9 then break end
		_8.Text = string.format(" Loop %d: TP to P3", l)
		_13(COORDS_3, true)
		if not _9 then break end
		_8.Text = string.format(" Loop %d: Holding E P3", l)
		_11()
		_14()
		if not _9 then break end
		_8.TextColor3 = Color3.fromRGB(0, 255, 127)
		_8.Text = string.format(" Loop %d Done!", l)
		task.wait(LOOP_DELAY)
		l = l + 1
	end
end

game:GetService("UserInputService").InputBegan:Connect(function(i, p)
	if p then return end
	if i.KeyCode == ACTIVATION_KEY then
		if _9 then _10() else _9 = true task.spawn(_15) end
	end
end)
