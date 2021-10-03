local Datastore = require(script.Parent.Datastore)
local Datastore_mt = { __index=Datastore }

local CombinedDatastore = require(script.Parent.CombinedDatastore)
local CombinedDatastore_mt = { __index=CombinedDatastore }

local Type = require(script.Parent.Type)

local Util = require(script.Parent.Util)
local clone = Util.clone

--- @class Profile
local Profile = { [Type] = "Profile" }
local Profile_mt = { __index=Profile }


function Profile_mt:__index(k)
    return self.Datastore[k]
end


function Profile_mt:__newindex(k, v)
    self.Datastore[k] = v
    self.CombinedDatastore[k] = v
end


function Profile.new(data)
    local self = {}

    self.Datastore = setmetatable(clone(data), Datastore_mt)
    self.Datastore.__index = self.Datastore

    self.CombinedDatastore = setmetatable(clone(data), CombinedDatastore_mt)
    self.CombinedDatastore.__index = self.CombinedDatastore

    return setmetatable(self, Profile_mt)
end


return Profile