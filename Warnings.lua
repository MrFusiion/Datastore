local Settings = require(script.Parent.Settings)
local warns = {}


--- Saving
warns.SAVE_FAILED = "Saving data failed! tries(%d/%d), %s"
warns.SAVE_CLOSED = "Cannot save datastore is closed!"

warns.SAVE_IN_STUDIO = "Tried to save in studio but SaveInStudio is not set to True in the config!"
warns.SAVE_BACKUP_VALUE = "Cannot save data, Data is backup data!"
warns.SAVE_VALUE_NOT_UPDATED = "Cannot save data, Data was not updated!"
warns.SAVE_NO_DATA = "Cannot save data, No data to save!"

warns.SAVE_MAX_QUEUE_SIZE = "Queue size is allready at maximum %d"


--- Serialize and Deserialize
warns.SERIALIZE_RETURNED_NIL = "Serialize returned nil!"
warns.SERIALIZE_ERROR = "An error occurred while serializing the retrieved value!, %s"
warns.DESERIALIZE_RETURNED_NIL = "Deserialize returned nil!"
warns.DESERIALIZE_ERROR = "An error occurred while deserializing the retrieved value!, %s"


--- Retrieving
warns.RETRIEVE_FAILED = "Rerieving data failed! tries(%d/%d), %s"


--- Updating
warns.UPDATE_RETURNED_NIL = "Value returned by 'f' was nil. Value was not updated!\
If removing the value was the intention use None instead!"
warns.UPDATE_ERROR = "An error occurred while calling 'f': %s"


--- Incrementing
warns.INCREMENT_ERROR = "An error occurred while incrementing: %s"


--- Libary
warns.COMBINE_KEYS_OVERIDE = "Tried to combine %s with %s while its allready combined with %s!"
warns.COMBINE_KEYS_ILLEGAL_SYMBOLS = "the key %s contains illegal symbols!"
warns.PROFILE_OVERIDE = "Tried to overide an existing profile %s!"


return function (name: string, ...)
	local suc, e = pcall(function(name, ...)
		local err = warns[name] and warns[name]:format(...)
		if err and Settings.Warnings[name] then
			warn(err, debug.traceback())
			return err
		else
			warn(("Error %s is not valid!"):format())
		end
	end, name, ...)

	if not suc then
		assert(("Warning %s experienced an Error %s")
			:format(name, e))
	end
end