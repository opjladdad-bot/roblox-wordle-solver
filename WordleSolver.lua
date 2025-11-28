-- WordleSolver.lua
local WordleSolver = {}

-- Helpers
local function lower(s) return string.lower(s) end

local function setFromList(list)
    local s = {}
    for _,v in ipairs(list) do s[v] = true end
    return s
end

local function requiredCountsFromClues(greens, yellows)
    local counts = {}
    for i,ch in ipairs(greens) do
        if ch and ch ~= "_" then
            counts[ch] = (counts[ch] or 0) + 1
        end
    end
    for _,y in ipairs(yellows) do
        counts[y.char] = (counts[y.char] or 0) + 1
    end
    return counts
end

-- UPDATED: Added wordList argument to the function
function WordleSolver.filterCandidates(greens, yellows, grays, wordListTable)
    -- Normalize
    for i=1,5 do
        if not greens[i] then greens[i] = "_" end
        greens[i] = lower(greens[i])
    end
    local graySet = setFromList(grays or {})
    local requiredCounts = requiredCountsFromClues(greens, yellows)

    -- Yellow map
    local yellowMap = {}
    for _,y in ipairs(yellows or {}) do
        local ch = lower(y.char)
        yellowMap[ch] = yellowMap[ch] or {}
        for _,pos in ipairs(y.disallowedPositions or {}) do
            yellowMap[ch][pos] = true
        end
    end

    local candidates = {}

    -- Use the passed wordListTable
    for _,w in ipairs(wordListTable) do
        local word = lower(w)
        if #word == 5 then
            local ok = true

            -- check greens
            for i=1,5 do
                local g = greens[i]
                if g ~= "_" and string.sub(word, i, i) ~= g then
                    ok = false; break
                end
            end
            if not ok then goto continue end

            -- check grays
            for gch,_ in pairs(graySet) do
                if requiredCounts[gch] then
                    -- allowed
                else
                    if string.find(word, gch) then
                        ok = false; break
                    end
                end
            end
            if not ok then goto continue end

            -- check yellows
            for ch,positions in pairs(yellowMap) do
                if not string.find(word, ch) then ok = false; break end
                for pos,_ in pairs(positions) do
                    if string.sub(word, pos, pos) == ch then ok = false; break end
                end
                if not ok then break end
            end
            if not ok then goto continue end

            -- check counts
            for rch,need in pairs(requiredCounts) do
                local count = 0
                for i=1,5 do
                    if string.sub(word,i,i) == rch then count = count + 1 end
                end
                if count < need then ok = false; break end
            end
            if not ok then goto continue end

            table.insert(candidates, word)
        end
        ::continue::
    end

    return candidates
end

function WordleSolver.rankCandidates(candidates, topN)
    topN = topN or 10
    local freq = {}
    for _,w in ipairs(candidates) do
        local seen = {}
        for i=1,5 do
            local ch = string.sub(w,i,i)
            if not seen[ch] then
                freq[ch] = (freq[ch] or 0) + 1
                seen[ch] = true
            end
        end
    end

    local scored = {}
    for _,w in ipairs(candidates) do
        local score = 0
        local seen = {}
        for i=1,5 do
            local ch = string.sub(w,i,i)
            if not seen[ch] then
                score = score + (freq[ch] or 0)
                seen[ch] = true
            end
        end
        table.insert(scored, {word = w, score = score})
    end

    table.sort(scored, function(a,b) return a.score > b.score end)

    local results = {}
    for i=1, math.min(topN, #scored) do
        table.insert(results, scored[i])
    end

    return results
end

return WordleSolver
