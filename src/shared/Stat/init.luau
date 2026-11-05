--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)

type StatFields = {
	_base: number,
	_cached: number,
	Changed: Signal.Signal<number, number>,
	_trove: Trove.Trove,
	_min: number?,
	_max: number?,
	_modifiers: { Modifier },
}
export type config = { Min: number?, Max: number? }

local Stat = {}

Stat.__index = Stat

export type Stat = typeof(setmetatable({} :: StatFields, Stat))

export type ModifierType = "Override" | "Flat" | "Percent"

export type Modifier = { Type: ModifierType, Value: number, Source: string, Duration: number? }

-- Creates main object

function Stat.new(BaseValue: number, Configuration: config?): Stat
	assert(typeof(BaseValue) == "number", "Stat.new expects a number")

	local self: StatFields = {
		_base = BaseValue,
		_cached = BaseValue,
		Changed = Signal.new(),
		_trove = Trove.new(),
		_min = if Configuration then Configuration.Min else nil,
		_max = if Configuration then Configuration.Max else nil,
		_modifiers = {},
	}

	self._trove:Add(self.Changed)

	local stat = setmetatable(self, Stat) :: any

	stat._cached = stat:_calculate()

	return stat
end

-- Getter and Setter

function Stat.__call(self: Stat, Value: number?): number
	if Value ~= nil then
		self._base = Value
		self:_refresh()
	end
	return self._cached
end

-- Add Modifier

function Stat.AddModifier(self: Stat, ModifierInfo: Modifier)
	assert(typeof(ModifierInfo.Value) == "number", "Modifier.Value must be a number")
	table.insert(self._modifiers, table.clone(ModifierInfo))
	self:_refresh()
end
-- Cleanup Function

function Stat.Destroy(self: Stat)
	self._trove:Destroy()
end

-- Calculate Total

function Stat._calculate(self: Stat): number
	local flat = 0
	local percent = 0
	local override: number? = nil

	for _, mod in self._modifiers do
		if mod.Type == "Flat" then
			flat += mod.Value
		elseif mod.Type == "Percent" then
			percent += mod.Value
		elseif mod.Type == "Override" then
			override = mod.Value
		end
	end

	local v = if override ~= nil then override else (self._base + flat) * (1 + percent)

	if self._min then
		v = math.max(v, self._min)
	end
	if self._max then
		v = math.min(v, self._max)
	end

	return v
end

function Stat.RemoveSource(self: Stat, Source: string)
	for i = #self._modifiers, 1, -1 do
		if self._modifiers[i].Source == Source then
			table.remove(self._modifiers, i)
		end
	end
	self:_refresh()
end

function Stat._refresh(self: Stat)
	local old = self._cached
	local new = self:_calculate()
	if new ~= old then
		self._cached = new
		self.Changed:Fire(new, old)
	end
end

return Stat
