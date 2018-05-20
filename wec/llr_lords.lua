local llr_lord = {} --# assume llr_lord: LLR_LORD

--v function(subtype: string, forename: string, surname: string, originating_faction: string) --> LLR_LORD
function llr_lord.new(subtype, forename, surname, originating_faction)
    local self = {}
    setmetatable(self, {
        __index = llr_lord
    })
    --# assume self: LLR_LORD

    self.subtype = subtype
    self.forename = forename
    self.surname = surname
    self.faction = originating_faction


    self.safety_abort = get_faction(originating_faction):is_human()


    return self
end

--v function(self: LLR_LORD) --> CA_FACTION
function llr_lord.get_faction(self)
    return get_faction(self.faction)
end


--v function(self: LLR_LORD, faction: string) --> boolean
function llr_lord.is_lord_involved(self, faction)
    return faction == self.faction
end


--v function(self: LLR_LORD, faction: string) --> boolean
function llr_lord.survived_confederation(self, faction)
    _llrRetval = false --:boolean
    local character_faction = get_faction(faction);
    local character_list = character_faction:character_list();

    for i = 0, character_list:num_items() - 1 do
        local character = character_list:item_at(i);

        if character:character_subtype(self.subtype)  then
            _llrRetval = true;
        end
    end
    return _llrRetval;
end


--v function(self: LLR_LORD, human_faction_name: string)
function llr_lord.respawn_to_pool(self, human_faction_name)
    cm:spawn_character_to_pool(human_faction_name, self.forename, self.surname, "", "", 18, true, "general", self.subtype, true, "");
end

--v function(self: LLR_LORD, faction: string)
function llr_lord.respec(self, faction)

    --this will catch any mishandle of the respec
    if self.safety_abort == true then
        return
    end
    local character_faction = get_faction(faction);
    local character_list = character_faction:character_list();

    for i = 0, character_list:num_items() - 1 do
        local character = character_list:item_at(i);

        if character:character_subtype(self.subtype) and character:get_forename() == self.forename then
            --first, we need to store the army list.
            self.army_list = {} --:vector<string>
            for j = 0, character:military_force():unit_list():num_items() - 1 do
                local current_unit = character:military_force():unit_list():item_at(j):unit_key()
                table.insert(self.army_list, current_unit)
            end
            --there are problems with adding tons of units to an army, so we're going to have to assembly the string.
            self.spawn_string = self.army_list[1];
            for k = 2, #self.army_list do
                next_string = self.spawn_string..","..self.army_list[k]
                self.spawn_string = next_string
            end
            --now, get the exp level of the character
            self.exp_level = character:rank() 
            self.x = character:logical_position_x()
            self.y = character:logical_position_y()
            self.region = character:region():name()


            
            cm:kill_character(char_lookup_str(character:command_queue_index()), true, true)
            --now, spawn the lord
            cm:callback( function()
                cm:create_force_with_general(
                faction,
                self.spawn_string,
                self.region,
                self.x,
                self.y,
                "general",
                self.subtype,
                self.forename,
                "",
                self.surname,
                "",
                "llr"..self.forename..self.subtype,
                false,
                function(cqi) 
                    cm:award_experience_level(char_lookup_str(cqi), self.exp_level)
                end)
            end,
            0.1
        );
            

        end
    end
end




return {
    new = llr_lord.new
}