input = {}
output = {}
async = {}
property = {}

--- @function Gets the number value of a property block
--- @param name string The name of the property block (CASE SENSITIVE)
--- @return number
property.getNumber = function(name) return 0 end

--- @function Gets the boolean value of a property block
--- @param name string The name of the property block (CASE SENSITIVE)
--- @return boolean
property.getBool = function(name) return false end

--- @function Gets the number value of a composite input channel
--- @param channel number The number of the composite channel
--- @return number
input.getNumber = function(channel) return 0 end

--- @function Outputs a number to a composite channel
--- @param channel number The number of the composite channel
--- @param value number The number to output to the channel
output.setNumber = function(channel, value) end

--- @function Gets the boolean value of a composite input channel
--- @param channel number The number of the composite channel
--- @return boolean
input.getBool = function(channel) return false end

--- @function Outputs a boolean state to a composite channel
--- @param channel number The number of the composite channel
--- @param value boolean The state to output to the channel
output.setBool = function(channel, value) end
