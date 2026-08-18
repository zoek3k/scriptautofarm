local ACTIVATION_KEY = Enum.KeyCode.G
local TARGET_SPEED = 220
local BLINK_STEP = 12
local LANDING_DELAY = 1.0
local LOOP_DELAY = 0.2
local STUCK_LIMIT = 300

local TARGET_LOOK_DIR = Vector3.new(-0.679, -0.215, -0.702)

local COORDS_1 = Vector3.new(6809.04, 17.76, 23.76)
local COORDS_2 = Vector3.new(-81.57, 49.25, 432.51)
local COORDS_4 = Vector3.new(4653.31, 17.22, 120.10)
local COORDS_5 = Vector3.new(5944.03, 24.53, 117.52)
local COORDS_3 = Vector3.new(6808.91, 17.44, -28.68)

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local player = Players.LocalPlayer

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BlinkGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local coordsLabel = Instance.new("TextLabel")
coordsLabel.Size = UDim2.new(0, 320, 0, 35)
coordsLabel.Position = UDim2.new(0, 20, 0, 20)
coordsLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
coordsLabel.BackgroundTransparency = 0.5
coordsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
coordsLabel.TextSize = 15
coordsLabel.TextXAlignment = Enum.TextXAlignment.Left
coordsLabel.Font = Enum.Font.SourceSansBold
coordsLabel.Text = " Position: Waiting..."
coordsLabel.Parent = screenGui

local speedLabel = coordsLabel:Clone()
speedLabel.Position = UDim2.new(0, 20, 0, 60)
speedLabel.Text = " Speed: 0.0 studs/sec"
speedLabel.Parent = screenGui

local statsLabel = coordsLabel:Clone()
statsLabel.Position = UDim2.new(0, 20, 0, 100)
statsLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
statsLabel.Text = " Loops: 0 | Time: 00:00:00"
statsLabel.Parent = screenGui

local statusLabel = coordsLabel:Clone()
statusLabel.Position = UDim2.new(0, 20, 0, 140)
statusLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
statusLabel.Text = " Status: Ready. Press [G]"
statusLabel.Parent = screenGui

local isRunning = false
local startTime = 0
local totalLoops = 0
local lastProgressTime = 0

local function resetAndStop()
	isRunning = false
	VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if humanoid then
			pcall(function()
				humanoid.Sit = false
				humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
				humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
			end)
		end
		if hrp then hrp.Velocity = Vector3.new(0, 0, 0) end
	end
	speedLabel.Text = " Speed: 0.0 studs/sec"
	statusLabel.TextColor3 = Color3.fromRGB(255, 90, 90)
	statusLabel.Text = " STOP!"
end

local function snapCameraToTarget()
	local camera = workspace.CurrentCamera
	local character = player.Character
	if camera and character then
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if hrp then
			local currentPos = hrp.Position
			hrp.CFrame = CFrame.lookAt(currentPos, currentPos + Vector3.new(TARGET_LOOK_DIR.X, 0, TARGET_LOOK_DIR.Z))
			pcall(function()
				local camPos = camera.CFrame.Position
				camera.CFrame = CFrame.lookAt(camPos, camPos + TARGET_LOOK_DIR)
			end)
		end
	end
end

local function startBackgroundThreads()
	task.spawn(function()
		while isRunning do
			local character = player.Character
			if character then
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				if humanoid and (humanoid.Sit or humanoid:GetState() == Enum.HumanoidStateType.Seated) then
					humanoid.Sit = false
					humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
				end
			end
			task.wait()
		end
	end)

	task.spawn(function()
		while isRunning do
			local elapsed = os.time() - startTime
			local hours = math.floor(elapsed / 3600)
			local minutes = math.floor((elapsed % 3600) / 60)
			local seconds = elapsed % 60
			statsLabel.Text = string.format(" Loops: %d | Time: %02d:%02d:%02d", totalLoops, hours, minutes, seconds)
			
			if os.time() - lastProgressTime >= STUCK_LIMIT then
				lastProgressTime = os.time()
				local character = player.Character
				if character then
					local humanoid = character:FindFirstChildOfClass("Humanoid")
					if humanoid then
						statusLabel.TextColor3 = Color3.fromRGB(255, 165, 0)
						statusLabel.Text = " Stuck detected! Resetting..."
						humanoid.Health = 0
						player.CharacterAdded:Wait()
						task.wait(1.0)
					end
				end
			end
			task.wait(1)
		end
	end)
end
local function blinkTo(targetPos, isTargetPoint)
	if not isRunning then return end
	local character = player.Character or player.CharacterAdded:Wait()
	local hrp = character:WaitForChild("HumanoidRootPart", 5)
	local humanoid = character:WaitForChild("Humanoid", 5)
	if not hrp or not humanoid then return end
	
	humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	
	while isRunning and character and character.Parent and (hrp.Position - targetPos).Magnitude > 0.5 do
		if humanoid.Sit then humanoid.Sit = false end
		local currentPos = hrp.Position
		local direction = (targetPos - currentPos).Unit
		local distanceLeft = (targetPos - currentPos).Magnitude
		local currentStep = math.min(BLINK_STEP, distanceLeft)
		local nextPos = currentPos + (direction * currentStep)
		local startTime = os.clock()
		
		hrp.CFrame = CFrame.new(nextPos)
		hrp.Velocity = Vector3.new(0, 0, 0)
		
		local requiredWait = currentStep / TARGET_SPEED
		local elapsed = os.clock() - startTime
		local remainingWait = math.max(0, requiredWait - elapsed)
		
		if remainingWait > 0 then
			task.wait(remainingWait)
		else
			RunService.RenderStepped:Wait()
		end
		
		local frameTime = os.clock() - startTime
		local calculatedSpeed = currentStep / frameTime
		coordsLabel.Text = string.format(" Position: X: %.1f | Y: %.1f | Z: %.1f", nextPos.X, nextPos.Y, nextPos.Z)
		speedLabel.Text = string.format(" Speed: %.1f studs/sec", calculatedSpeed)
	end
	
	if isRunning and isTargetPoint and character and character.Parent then
		snapCameraToTarget()
		local stopTime = os.clock()
		while isRunning and (os.clock() - stopTime) < LANDING_DELAY do
			if not hrp or not hrp.Parent then break end
			hrp.CFrame = CFrame.new(targetPos)
			hrp.Velocity = Vector3.new(0, 0, 0)
			task.wait(0.05)
		end
	end
	
	if character and character.Parent and humanoid and hrp then
		hrp.Velocity = Vector3.new(0, 0, 0)
		pcall(function()
			humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end)
	end
end

local function holdE()
	if not isRunning then return end
	VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
	for i = 1, 12 do if not isRunning then break end task.wait(0.05) end
	VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
end

local function runMacroSequence()
	startTime = os.time()
	lastProgressTime = os.time()
	totalLoops = 0
	startBackgroundThreads()
	
	while isRunning do
		statusLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
		statusLabel.Text = string.format(" Loop %d: TP to P1", totalLoops + 1)
		blinkTo(COORDS_1, true)
		if not isRunning then break end
		
		for i = 1, 5 do
			if not isRunning then break end
			statusLabel.Text = string.format(" Loop %d: Holding E (%d/5)", totalLoops + 1, i)
			snapCameraToTarget()
			holdE()
			if not isRunning then break end
			task.wait(0.1)
		end
		if not isRunning then break end
		
		statusLabel.Text = string.format(" Loop %d: TP to P2", totalLoops + 1)
		blinkTo(COORDS_2, true)
		if not isRunning then break end
		
		statusLabel.Text = string.format(" Loop %d: Holding E P2", totalLoops + 1)
		snapCameraToTarget()
		holdE()
		if not isRunning then break end
		
		statusLabel.Text = string.format(" Loop %d: Wall 4", totalLoops + 1)
		blinkTo(COORDS_4, false)
		if not isRunning then break end
		
		statusLabel.Text = string.format(" Loop %d: Wall 5", totalLoops + 1)
		blinkTo(COORDS_5, false)
		if not isRunning then break end
		
		statusLabel.Text = string.format(" Loop %d: TP to P3", totalLoops + 1)
		blinkTo(COORDS_3, true)
		if not isRunning then break end
		
		statusLabel.Text = string.format(" Loop %d: Holding E P3", totalLoops + 1)
		snapCameraToTarget()
		holdE()
		if not isRunning then break end
		
		totalLoops = totalLoops + 1
		lastProgressTime = os.time()
		statusLabel.TextColor3 = Color3.fromRGB(0, 255, 127)
		statusLabel.Text = string.format(" Loop %d Done!", totalLoops)
		task.wait(LOOP_DELAY)
	end
end

game:GetService("UserInputService").InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == ACTIVATION_KEY then
		if isRunning then resetAndStop() else isRunning = true task.spawn(runMacroSequence) end
	end
end)
