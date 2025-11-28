-- WordleHelper.lua
-- This runs in your executor.

local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local VirtualInputManager = game:GetService("VirtualInputManager")

-- 1. CONFIGURATION
-- REPLACE THESE URLs with your "Raw" GitHub links once you upload the files
local REPO_URL = "https://raw.githubusercontent.com/opjladdad-bot/roblox-wordle-solver/main/"
local LIST_URL = REPO_URL .. "https://raw.githubusercontent.com/opjladdad-bot/roblox-wordle-solver/refs/heads/main/WordList.lua"
local SOLVER_URL = REPO_URL .. "https://raw.githubusercontent.com/opjladdad-bot/roblox-wordle-solver/refs/heads/main/WordleSolver.lua"

-- 2. LOAD MODULES
local success, WordList = pcall(function() return loadstring(game:HttpGet(LIST_URL))() end)
local success2, WordleSolver = pcall(function() return loadstring(game:HttpGet(SOLVER_URL))() end)

if not success or not success2 then
    warn("Failed to load modules! Check your URLs.")
    return
end

-- 3. STATE
local currentCandidates = WordList.WORDS
local currentGuessWord = "crane" -- Best starter
local state = {
    chars = {"c","r","a","n","e"},
    colors = {0,0,0,0,0} -- 0=Gray, 1=Yellow, 2=Green
}

-- 4. GUI CREATION
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "WordleSolverGUI"
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 300, 0, 350)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -175)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

-- Draggable
local Drag = Instance.new("UIDragDetector")
Drag.Parent = MainFrame

-- Title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundTransparency = 1
Title.Text = "Wordle Solver"
Title.TextColor3 = Color3.new(1,1,1)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 20
Title.Parent = MainFrame

-- Suggestion Label
local SuggestionLabel = Instance.new("TextLabel")
SuggestionLabel.Size = UDim2.new(1, 0, 0, 30)
SuggestionLabel.Position = UDim2.new(0, 0, 0, 40)
SuggestionLabel.BackgroundTransparency = 1
SuggestionLabel.Text = "Suggestion: " .. string.upper(currentGuessWord)
SuggestionLabel.TextColor3 = Color3.fromRGB(0, 255, 127)
SuggestionLabel.Font = Enum.Font.Gotham
SuggestionLabel.TextSize = 18
SuggestionLabel.Parent = MainFrame

-- Letter Buttons Container
local ButtonContainer = Instance.new("Frame")
ButtonContainer.Size = UDim2.new(1, -20, 0, 60)
ButtonContainer.Position = UDim2.new(0, 10, 0, 80)
ButtonContainer.BackgroundTransparency = 1
ButtonContainer.Parent = MainFrame

local letterButtons = {}

local function updateButtonColor(btn, stateVal)
    if stateVal == 0 then
        btn.BackgroundColor3 = Color3.fromRGB(100, 100, 100) -- Gray
    elseif stateVal == 1 then
        btn.BackgroundColor3 = Color3.fromRGB(200, 180, 0)   -- Yellow
    elseif stateVal == 2 then
        btn.BackgroundColor3 = Color3.fromRGB(0, 180, 0)     -- Green
    end
end

for i=1, 5 do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 50, 0, 50)
    btn.Position = UDim2.new(0, (i-1)*55, 0, 0)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 24
    btn.Text = string.upper(string.sub(currentGuessWord, i, i))
    btn.Parent = ButtonContainer
    updateButtonColor(btn, 0)
    
    btn.MouseButton1Click:Connect(function()
        -- Cycle colors: Gray -> Yellow -> Green -> Gray
        state.colors[i] = (state.colors[i] + 1) % 3
        updateButtonColor(btn, state.colors[i])
    end)
    
    table.insert(letterButtons, btn)
end

-- 5. LOGIC FUNCTIONS

local function calculateNext()
    local greens = {"_", "_", "_", "_", "_"}
    local yellows = {} -- list of objects
    local grays = {}

    for i=1, 5 do
        local char = state.chars[i]
        local color = state.colors[i]
        
        if color == 2 then -- Green
            greens[i] = char
        elseif color == 1 then -- Yellow
            table.insert(yellows, {char = char, disallowedPositions = {i}})
        elseif color == 0 then -- Gray
            table.insert(grays, char)
        end
    end

    -- Filter
    currentCandidates = WordleSolver.filterCandidates(greens, yellows, grays, currentCandidates)
    
    -- Rank
    local ranked = WordleSolver.rankCandidates(currentCandidates, 5)
    
    if #ranked > 0 then
        currentGuessWord = ranked[1].word
        SuggestionLabel.Text = "Best Guess: " .. string.upper(currentGuessWord)
        
        -- Update buttons for new word (reset colors to gray)
        for i=1, 5 do
            state.chars[i] = string.sub(currentGuessWord, i, i)
            state.colors[i] = 0
            letterButtons[i].Text = string.upper(state.chars[i])
            updateButtonColor(letterButtons[i], 0)
        end
    else
        SuggestionLabel.Text = "No words found!"
    end
end

local function typeWord()
    -- Uses VirtualInputManager to act as keyboard
    for i = 1, #currentGuessWord do
        local char = string.upper(string.sub(currentGuessWord, i, i))
        local key = Enum.KeyCode[char]
        if key then
            VirtualInputManager:SendKeyEvent(true, key, false, game)
            task.wait(0.05)
            VirtualInputManager:SendKeyEvent(false, key, false, game)
            task.wait(0.05)
        end
    end
    -- Press Enter
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
end

-- 6. ACTION BUTTONS

local SolveBtn = Instance.new("TextButton")
SolveBtn.Size = UDim2.new(0, 130, 0, 50)
SolveBtn.Position = UDim2.new(0, 10, 0, 160)
SolveBtn.Text = "CALCULATE NEXT"
SolveBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
SolveBtn.TextColor3 = Color3.new(1,1,1)
SolveBtn.Font = Enum.Font.GothamBold
SolveBtn.Parent = MainFrame
SolveBtn.MouseButton1Click:Connect(calculateNext)

local TypeBtn = Instance.new("TextButton")
TypeBtn.Size = UDim2.new(0, 130, 0, 50)
TypeBtn.Position = UDim2.new(1, -140, 0, 160)
TypeBtn.Text = "AUTO TYPE"
TypeBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 255)
TypeBtn.TextColor3 = Color3.new(1,1,1)
TypeBtn.Font = Enum.Font.GothamBold
TypeBtn.Parent = MainFrame
TypeBtn.MouseButton1Click:Connect(typeWord)

-- Candidate List Display
local CandidateList = Instance.new("TextLabel")
CandidateList.Size = UDim2.new(1, -20, 0, 100)
CandidateList.Position = UDim2.new(0, 10, 0, 220)
CandidateList.BackgroundTransparency = 0.5
CandidateList.BackgroundColor3 = Color3.new(0,0,0)
CandidateList.TextColor3 = Color3.new(0.8,0.8,0.8)
CandidateList.TextYAlignment = Enum.TextYAlignment.Top
CandidateList.Text = "Candidates will appear here..."
CandidateList.Font = Enum.Font.Code
CandidateList.TextSize = 14
CandidateList.Parent = MainFrame

-- Update candidate text helper
local function updateCandidateList()
    local s = ""
    for i=1, math.min(10, #currentCandidates) do
        s = s .. currentCandidates[i] .. ", "
    end
    CandidateList.Text = "Possible words ("..#currentCandidates.."):\n" .. s
end
SolveBtn.MouseButton1Click:Connect(updateCandidateList)

print("Wordle Solver Loaded")
