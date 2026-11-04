--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)

type StatParams = {
	_base: number,
	_cached: number,
	Changed: Signal.Signal<number, number>,
	_trove: Trove.Trove,
	_min: number?,
	_max: number?,
	_modifiers: { Modifier },
}
type Config = { Min: number?, Max: number? }

local Stat = {}

Stat.__index = Stat

export type Stat = typeof(setmetatable({} :: StatParams, Stat))

type ModeType = "Override" | "Flat" | "Percent"

type Modifier = { Type: ModeType, Value: number, Source: string, Duration: number? }

-- Creates main object

function Stat.new(BaseValue: number, Configuration: Config?): Stat
	assert(typeof(BaseValue) == "number", "Stat.new expects a number")

	local self: StatParams = {
		_base = BaseValue,
		_cached = BaseValue,
		Changed = Signal.new(),
		_trove = Trove.new(),
		_min = if Configuration then Configuration.Min else nil,
		_max = if Configuration then Configuration.Max else nil,
		_modifiers = {},
	}

	self._trove:Add(self.Changed)

	return setmetatable(self, Stat) :: any
end

-- Getter and Setter

function Stat.__call(self: Stat, Value: number?): number?
	if Value ~= nil then
		local old = self._base
		self._base = Value
		self.Changed:Fire(old, Value)
		return nil
	else
		return self._cached
	end
end

-- Add Modifier

function Stat.AddModifier(self: Stat, ModifierInfo: Modifier)
	table.insert(self._modifiers, ModifierInfo)
	self:_refresh()
end
-- Cleanup Function

function Stat.Destroy(self: Stat)
	self._trove:Destroy()
end

-- Calculate Total

function Stat._calculate(self: Stat) end

function Stat._refresh(self: Stat) end

return Stat
