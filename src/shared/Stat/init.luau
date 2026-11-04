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
}
type Config = { Min: number?, Max: number? }

local Stat = {}

Stat.__index = Stat

export type Stat = typeof(setmetatable({} :: StatParams, Stat))

type ModeType = "Override" | "Flat" | "Percent"

Stat.Mode = table.freeze({
	Override = "Override" :: ModeType,
	Flat = "Flat" :: ModeType,
	Percent = "Percent" :: ModeType,
})

function Stat.new(BaseValue: number, Configuration: Config?): Stat
	assert(typeof(BaseValue) == "number", "Stat.new expects a number")

	local self: StatParams = {
		_base = BaseValue,
		_cached = BaseValue,
		Changed = Signal.new(),
		_trove = Trove.new(),
		_min = if Configuration then Configuration.Min else nil,
		_max = if Configuration then Configuration.Max else nil,
	}

	self._trove:Add(self.Changed)

	return setmetatable(self, Stat) :: any
end

function Stat.__call(
	self: Stat,
	Value: number?
): number? -- Sets the base value if there is a value parameter set, gets the base value if there are no parameters set
	if Value ~= nil then
		local old = self._base
		self._base = Value
		self.Changed:Fire(old, Value)
		return nil
	else
		return self._cached
	end
end

function Stat.Destroy(self: Stat)
	self._trove:Destroy()
end

return Stat
