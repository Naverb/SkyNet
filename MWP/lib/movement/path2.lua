-- @CLASS Task @PARAMS ?
Path = Class {
    constructor = function(self, params)
		local waypoints = _waypoints or {}
        local obj = {}
        obj.enabled = true
        obj.name = assert(params.name, "Attempted to create a path without a name!")

        return obj
    end,

    registerToTaskSequence = function(self, taskSequence)
        self.enclosingTaskSequence = taskSequence
    end,

	potato2 = function(asd)
		asd
	end

}
