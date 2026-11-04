--!strict

export type Primitive = string | number | boolean

type ValueorTable = Primitive | { Primitive }

local Stat = {}

function Stat.new(template: ValueorTable)
	if typeof(template) == "table" then
		for i, v in template do
			if typeof(v) == "table" then
				Stat.new(v)
			end
		end
	else
	end
end

return Stat
