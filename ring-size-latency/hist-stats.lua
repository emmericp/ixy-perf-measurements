local file = ...
if not file then
	print("usage: lua hist-stats.lua <filename.csv>")
end
local file, err = io.open(file, "r")
if not file then
	print("failed to open file: " .. tostring(err))
end

print("all values are in nanoseconds")
print("calculation will take a few seconds because it's super inefficient")

local hist = {}
for line in file:lines() do
	local bucket, size = line:match("(.-),(.+)")
	bucket, size = tonumber(bucket), tonumber(size)
	if bucket and size then
		hist[bucket] = size
	end
end

local sortedHist = {}
local sum = 0
local numSamples = 0

for k, v in pairs(hist) do
	table.insert(sortedHist, { k = k, v = v })
	numSamples = numSamples + v
	sum = sum + k * v
end

local avg = sum / numSamples
local stdDevSum = 0
for k, v in pairs(hist) do
	stdDevSum = stdDevSum + v * (k - avg)^2
end
local stdDev = (stdDevSum / (numSamples - 1)) ^ 0.5

print("avg: " .. avg .. " stddev: " .. stdDev)

table.sort(sortedHist, function(e1, e2) return e1.k < e2.k end)
local maxCell = sortedHist[#sortedHist]
local maximum = maxCell.k
local minCell = sortedHist[1]
local minimum = minCell.k

print("min: " .. minimum .. " max: " .. maximum)

local percs = {}
local perc999
local idx = 0
for _, p in ipairs(sortedHist) do
	for _ = 1, p.v do
		-- really inefficient but whatever
		for perc = math.max(1, #percs), 100 do
			if not percs[perc] and idx >= numSamples * perc / 100 then
				percs[perc] = p.k
			end
			if not perc999 and idx >= numSamples * 0.999 then
				perc999 = p.k
			end
		end
		idx = idx + 1
	end
end

for i, v in ipairs(percs) do
	print("Percentile " .. i .. ": " .. v)
end

print("99.9th percentile: " .. perc999)

