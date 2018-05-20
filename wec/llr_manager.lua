local llr_manager = {} --# assume llr_manager: LLR_MANAGER


--v function() --> LLR_MANAGER
function llr_manager.new()
    local self = {}
    setmetatable(self, {
        __index = llr_manager
    })
    --# assume self: LLR_MANAGER
    local cm = get_cm()
    self.humans = cm:get_human_factions()
    
    self.subcultures = {} --:map<string, bool>
    for i, v in pairs(self.humans) do
        local sc = get_faction(v):subculture()
        self.subcultures[sc] = true
    end
    self.factions = {} --:map<string, bool>
    self.lords = {} --:map<string, vector<LLR_LORD>>




    return self
end

--v function(self: LLR_MANAGER, lord: LLR_LORD)
function llr_manager.add_lord(self, lord)
    local faction = lord:get_faction():name()
    local t = self.lords[faction]
    table.insert(t, lord)
    self.factions[faction] = true
end

--v function(self: LLR_MANAGER)
function llr_manager.activate(self)

    core:add_listener(
        "llr_manager",
        "FactionJoinsConfederation",
        function(context)
            local sc = context:faction():subculture()
            local faction = context:faction():name()
            --check if we are listening for that subculture, and if any lords are registered for it.
            return self.subcultures[sc] and self.factions[faction]
        end,
        function(context)
            local faction_name = context:faction():name();
            local confederation_name = context:confederation():name();

            for k, v in pairs(self.lords) do
                for i = 1, #v do
                    if v[i]:survived_confederation(confederation_name) then
                        v[i]:respec(confederation_name)
                    else
                        v[i]:respawn_to_pool(confederation_name)
                    end
                end
            end
        end,
        true
    );

end

return {
    new = llr_manager.new
}