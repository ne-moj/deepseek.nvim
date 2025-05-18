local function class(base)
	local c = {}
	c.__index = c

	function c:new(...)
		local instance = setmetatable({}, c)
		if instance.init then
			instance:init(...)
		end
		return instance
	end

	if base then
		setmetatable(c, { __index = base })
		c.super = base
	end

	return c
end

return class
