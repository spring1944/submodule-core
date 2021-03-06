local moduleInfo = {
	name = "tableExt",
	desc = "table functions extension",
	author = "Michal Mojzik, PepeAmpere",
	date = "2017-09-16",
	license = "MIT",
}


-- tableExt
-- table functions extension

-- @module tableExt
local newTableExt = {

	-- @description Check if all entries satisfy a predicate
	-- @argument inputTable [table]
	-- @argument predicate [function(key, value)] predicate which has to be satisfied
	-- @return result [boolean]
	["All"] = function(inputTable, predicate)
		for k, v in pairs(inputTable) do
			if (not predicate(k, v)) then
				return false
			end
		end
		return true
	end,
	
	-- @description Check if at least one entry satisfies a predicate
	-- @argument inputTable [table]
	-- @argument predicate [function(key, value)] predicate which has to be satisfied
	-- @return result [boolean]
	["Any"] = function(inputTable, predicate)
		for k, v in pairs(inputTable) do
			if (predicate(k, v)) then
				return true
			end
		end
		return false
	end,
	
	-- @description Check if any entry in a table is equal to a specific value
	-- @argument someTable [table] table of entries
	-- @argument searchedValue [anything] value to search for
	-- @return result [boolean] true if any entry is equal to the value, false otherwise
	["Contains"] = function(someTable, searchedValue)
		return tableExt.Any(someTable, function(_, value) return value == searchedValue end)
	end,
	
	-- @description Returns deep-copy of an inserted table
	-- @argument object [anything] source table which should be copied
	-- @argument seen [table] contains all previously seen tables to prevent never ending recursion
	-- @return table
	["DeepCopy"] = function(object, seen)
		if (type(object) ~= "table") then return object end
		if (seen and seen[object]) then return seen[object] end
		
		local newSeen = seen or {}
		local newTable = setmetatable({}, getmetatable(object))
		
		newSeen[object] = newTable
		for k, v in pairs(object) do 
			newTable[tableExt.DeepCopy(k, newSeen)] = tableExt.DeepCopy(v, newSeen) 
		end
		return newTable
	end,
	
	-- @description Returns deep-copy of an inserted table
	-- @argument object [anything] source table which should be copied
	-- @argument maxDepth [number|optional] The maximal depth into which to serialize the table.
	-- @comment It is preferable that the graph of the tables that are to be serialized should not contain cycles. If it does, @{dump} might end up producing duplicite output.
	["Dump"] = function(object, maxDepth)
		maxDepth = maxDepth or 1
		if type(object) == 'table' then
			if (maxDepth == 0) then 
				return "..." 
			end
			--if (object.name ~= nil) then -- For outputing chili objects
				--return object.name
			--end
			local s = '{ '
			for k,v in (object.pairs or pairs)(object) do
				s = s .. '[' .. tableExt.Dump(k, 0) .. '] = ' .. tableExt.Dump(v, maxDepth-1) .. ','
			end
			return s .. '} '
		elseif type(object) == 'string' then
			return string.format("%q", object):gsub("\\\n", "\\n")
		else
			return tostring(object)
		end
	end,
	
	-- @description Merge n tables
	-- @argument target [table] source table which should be merged
	-- @argument ... [tables] tables we want to merge together into target
	-- @return target [table] does not make new table, returns first argument, unless first argument is nil
	["Extend"] = function(target, ...)
		if target == nil then target = {} end
		for _, source in pairs({...}) do
			for k, v in pairs(source) do
				target[k] = v
			end
		end
		return target
	end,
	
	-- @description Return table of items which pass the filter
	-- @argument originalTable [table]
	-- @argument predicate [function(key,value)] predicate which has to be satisfied
	["Filter"] = function(originalTable, predicate)
		local newTable = {}
		
		for k,v in pairs (originalTable) do
			if (predicate(k,v) == true) then
				newTable[k] = v
			end
		end
		
		return newTable
	end,
	
	-- @description Combine sequentially all values in table with initial value and return the result
	-- @argument inputTable [table] source table which should be copied
	-- @argument initValue [anything] source table which should be copied
	-- @argument FoldFunction [function] fold function(previousValue, k, v)
	-- @argument result [anything] any other parameters
	["Fold"] = function(inputTable, initValue, FoldFunction, ...)
		for k,v in pairs(inputTable) do
			initValue = FoldFunction(initValue, k, v, ...)
		end
		
		return initValue
	end,
	
	-- @description Check if given table is empty
	-- @argument someTable [table] table we want to check
	-- @return result [boolean] false if the table contains at least one entry, otherwise true
	["IsEmpty"] = function(someTable)
		if next(someTable) then
			return false
		end
		return true
	end,
	
	-- @description Return number of entries in a table
	-- @argument inputTable [table]
	-- @return count [number]
	["Length"] = function(inputTable)
		local count = 0
		
		for _,_ in pairs (inputTable) do
			count = count + 1
		end
		
		return count
	end,
	
	-- @description Return new table that contains same entries as originalTable
	-- @argument object [anything] source object which should be copied
	-- @return newTable [table]
	["ShallowCopy"] = function(object)
		if type(object) ~= 'table' then return object end
		
		local newTable = setmetatable({}, getmetatable(object))
		
		for k, v in pairs(object) do
			newTable[k] = v
		end
		
		return newTable
	end,
	
	-- @description Produces an alternate view of the given table that diregards `__index` metamethod.
	-- @argument t [table] original table 
	-- @comment This is equivalent to a situation where we would only use `rawget` on the original table. The original table is not modified in any way.
	["Raw"] = function(t)
		return setmetatable({}, {
			__index = function(_, key) return rawget(t, key) end, -- retrieves only the directly stored value
			__newindex = function() error("Attempt to write to a read-only rawTable.") end, -- disallow an writing to the resulting table
			__pairs = function() return pairs(t) end, -- iterates only through the directly stored key-value pairs
		})
	end,
	
	-- @description elements of someTable transformed by function
	-- @argument someTable [table] table of entries
	-- @argument TransformationFunction [function(key, value)] function that transforms items
	-- @return transformedTable [table] table of transformed elements
	["Transform"] = function(someTable, TransformationFunction)
		local transformedTable = {}
		for key, value in pairs(someTable) do
			transformedTable[key] = TransformationFunction(key, value)
		end

		return transformedTable
	end,
}

-- END OF MODULE DEFINITIONS --

-- update global tables 
if (tableExt == nil) then tableExt = {} end
for k,v in pairs(newTableExt) do
	-- if (tableExt[k] ~= nil) then Spring.Echo("NOTIFICATION: Attempt to rewrite global table in module [" .. moduleInfo.name ..  "] - key: " .. k) end
	tableExt[k] = v 
end

return tableExt
