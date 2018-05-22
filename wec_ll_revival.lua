--[[


I'm gonna comment the shit out of this one in the hopes it can help some people trying to learn lua.
]]




--We're using CMF (and ever if we weren't, it's polite) so we set our identifer.
cm:set_saved_value("wec_ll_revival", true);

--these two things define the classes. We use a blank template style because it agrees with the type checker.
--if you aren't familiar with programming terms, a class is a type of object. Since we can have many lords we define the methods that can be applied to lords as a class.

llr_lord = {} --# assume llr_lord: LLR_LORD
llr_manager = {} --# assume llr_manager: LLR_MANAGER

--toggle this to turn logging on or off.
isLogAllowed = true --:boolean

--v function(text: string)
function LLRLOG(text)
    ftext = "LLR" --sometimes I use ftext as an arg of this function, but for simple mods like this one I don't need it.

    if not isLogAllowed then
      return; --if our bool isn't set true, we don't want to spam the end user with logs. 
    end

  local logText = tostring(text)
  local logContext = tostring(ftext)
  local logTimeStamp = os.date("%d, %m %Y %X")
  local popLog = io.open("WEC_LLR.txt","a")
  --# assume logTimeStamp: string
  popLog :write("WEC:  "..logText .. "    : [" .. logContext .. "] : [".. logTimeStamp .. "]\n")
  popLog :flush()
  popLog :close()
end




--v function(subtype: string, forename: string, surname: string, originating_faction: string) --> LLR_LORD
function llr_lord.new(subtype, forename, surname, originating_faction)

    LLRLOG("Adding lord with subtype ["..subtype.."], forename ["..forename.."], surname ["..surname.."] and originating faction ["..originating_faction.."] ")
    local self = {} --once again, we are defining the object as a blank because the type checker prefers this style of doing it.
    setmetatable(self, {
        __index = llr_lord
    }) 
    -- this basically tells the table we just created to take on the properties of that object type. 
    -- now, any function we define as llr_lord.something can be applied to this object.
    --# assume self: LLR_LORD
    --these are kailua language. Its the type checker I use. This basically is telling the type checker to treat this new object instance as a LLR_LORD class.
    
    self.subtype = subtype
    self.forename = forename
    self.surname = surname
    self.faction = originating_faction
    --these add the args we gave as the fields/properties of the object. 

    --this one is a boolean that tells the script to nope the fuck out if it starts acting on a human player.
    --this SHOULD never happen but if an error caused it to happen, we wouldn't want to ruin any saves.
    self.safety_abort = get_faction(originating_faction):is_human()

    --we now return our brand new object.
    return self
end

--this is a method of the llr_lord class. This means any object we create with llr_lord.new can use this method.
--this particular method is usually called an accessor or a getter, because it accesses or gets information about the object.

--v function(self: LLR_LORD) --> string
  function llr_lord.get_faction(self)
      return self.faction;
  end

--another one. This one checks if a lord has a given originating faction.
--v function(self: LLR_LORD, faction: string) --> boolean
function llr_lord.is_lord_involved(self, faction)
    LLRLOG("IsLordInvolved Returning ["..tostring(faction == self.faction).."] ")
    return faction == self.faction
end

--this one is a little more complicated. It checks if a lord is on the map after confederation has happened.
--v function(self: LLR_LORD, faction: string) --> boolean
function llr_lord.survived_confederation(self, faction)

    --we are trying to find something, so we set a variable to say whether we found it.
    _llrRetval = false --:boolean
    local character_faction = get_faction(faction);
    local character_list = character_faction:character_list();
    --CA objects are imported from the game engine, which is written in another languages. 
    --the engine language treats 0, not 1, as the start of a list, so our loop looks different here.
    --Furthermore, we can't apply standard Lua opperators, like # and [i] to a CA object, so we use methods.
    for i = 0, character_list:num_items() - 1 do --num items is equivalent to #
        local character = character_list:item_at(i); --item_at(i) is equivalent to [i]

        if character:character_subtype(self.subtype)  then --since we are only looking for legendary lords, we only need to check for the subtype. 
            _llrRetval = true; 
            --really I should break; here because it would save on performance. 
        end
    end
    LLRLOG("survived_confederation Returning ["..tostring(_llrRetval).."]")
    return _llrRetval;
end


--v function(self: LLR_LORD, human_faction_name: string)
function llr_lord.respawn_to_pool(self, human_faction_name)
    LLRLOG("Respawning lord with subtype ["..self.subtype.."] to pool!")
    --a simple one, I just need to respawn a lord to the pool with one command. 
    cm:spawn_character_to_pool(human_faction_name, self.forename, self.surname, "", "", 18, true, "general", self.subtype, true, "");
    --notice how the information I need for the lord is all taken from the object, 
    --but I use human_faction dynamically because there could potential be a situation where players could both confederate a lord. (bret)
end

--v function(self: LLR_LORD, faction: string)
function llr_lord.respec(self, faction)
    local exp_to_levels_table = {
        0, 900,  1900,  3000, 4200,  5500,6870, 8370, 9940,
      11510,13080,14660, 16240,17820,19400, 20990,22580,24170,25770,27370,28980,30590,32210,
      33830,35460,37100,38740, 40390,42050,43710,45380,47060,48740,50430,52130, 53830, 55540,57260,58990,
      60730, 60730, 60730, 60730,  60730, 60730, 60730, 60730, 60730,  60730, 60730, 60730,
      60730 }--:vector<number>

    --this long ass list is just a list of exp quantities to level.
    --we add a bunch of extras on the end to compat with extra level mods. 


    LLRLOG("Respecing lord with subtype ["..self.subtype.."] ")

    --this will catch any mishandle of the respec
    if self.safety_abort == true then
        LLRLOG("Aborting Respec, tried to respec a lord that originates from a human faction !?!?")
        return
    end

    local character_faction = get_faction(faction);
    local character_list = character_faction:character_list();
    LLRLOG("Cycling through the character list to find the new character")
    --once again, we are handling imported objects, not lists. This means we use the modified loop.
    --here we cycle through the faction's characters to find the newly aquired lord.
    for i = 0, character_list:num_items() - 1 do
        local character = character_list:item_at(i);

        if character:character_subtype(self.subtype) and character:get_forename() == self.forename then --if the forename and subtype match, we've found him.
            LLRLOG("Checkpoint 2: Found our desired character.")
            --first, we need to store the army list.
            self.army_list = {} --:vector<string>
            --first we define an empty table to store it in.
            --notice we use j in this loop because i is already taken.
            for j = 0, character:military_force():unit_list():num_items() - 1 do
                local current_unit = character:military_force():unit_list():item_at(j):unit_key()
                --now we get each unit object in the army and convert it into it's unit key string.
                table.insert(self.army_list, current_unit)
                --finally, we add that string to the list we declared.
            end
            --there are problems with adding tons of units to an army, so we're going to have to assembly the string.
            --first, we need a blank string to start adding stuff to.
            self.spawn_string = ""
            --the first "unit" in every army is the general himself. 
            --so we're going to start this loop at #2 because otherwise we might end up with two lords!
            for k = 2, #self.army_list do
                --we define the next string as a variable.
                --we insert the comma to conform to the unit_spawn_list_string format that CA uses.
                next_string = self.spawn_string..","..self.army_list[k]
                --now, we set the self.spawn_string to the string we assembled.
                --we cannot do this directly in the way that you would increment a variable a = a + 1 because in lua strings are immutable.
                self.spawn_string = next_string
            end
            LLRLOG("Assembled spawn string as ["..self.spawn_string.."] ")

            --now, get the exp level of the character
            self.exp_level = character:rank() 
            LLRLOG("noted the ranked of the lord as ["..tostring(self.exp_level).."] ")
            --get the positioning of the army.
            self.x = character:logical_position_x()
            self.y = character:logical_position_y()
            self.region = character:region():name()
            --this one is actually risky, so we need to do a check!
            --if the lord happens to be in the chaos wastes then the spawn command will fail.
            --a quirk of the spawn command is that the spawn region has to have a settlement.
            --as a backup, we make the spawn region the capital of the faction.
            if get_region(self.region):settlement():is_null_interface() then
                self.region = get_faction(faction):home_region():name()
            end

            LLRLOG("found positioning data as x = ["..tostring(self.x).."], y = ["..tostring(self.y).."], region = ["..self.region.."]")

            LLRLOG("Killing the inherited lord!")
            --we need to prevent the message from showing up in the event feed.
            cm:disable_event_feed_events(true, "", "wh_event_subcategory_character_deaths", "");
            --now, we need to strip immortality from the character
            cm:set_character_immortality(char_lookup_str(character:command_queue_index()), false);
            --finally, we kill him and his army.
            cm:kill_character(char_lookup_str(character:command_queue_index()), true, true)
            --turn message back on on a callback.
            cm:callback(function() cm:disable_event_feed_events(false, "", "wh_event_subcategory_character_deaths", "") end, 1);
            --now, spawn the lord
            --we do this on a callback for safety. 
            cm:callback( function()
                LLRLOG("spawning lord for respec!")
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
                "llr"..self.forename..self.subtype, --this just has to be unique, so we assembly it with bits of data from the object.
                false,
                function(cqi) 
                    LLRLOG("Levelling up the respec'd lord!")
                    cm:set_character_immortality(char_lookup_str(cqi), true);
                    --this makes sure our shiny new lord is immortal.
                    cm:add_agent_experience(char_lookup_str(cqi), exp_to_levels_table[self.exp_level])
                    --this references our exp table at the top of this function.

                    
                    LLRLOG("Levelling up the respec'd lord finished.")
                end)
            end,
            0.1
        );
        --break otherwise the loop might find the character again and keep doing this infinitely.
        break;
        end
    end
end

--we are creating another object now, this one to handle all those little objects we made. 
--v function() --> LLR_MANAGER
function llr_manager.new()
  LLRLOG("Creating the manager!");
    local self = {}
    setmetatable(self, {
        __index = llr_manager
    })
    --# assume self: LLR_MANAGER
    local cm = get_cm() --this isn't 100% necessary, but its safe.
    self.humans = cm:get_human_factions()
    --this one actually returns a vector of strings (the faction names) so we handle it like a normal lua list.
    
    --we only want to listen for confederations for human subcultures. Doing it for the rest is a waste of resources.
    --first we initialise the table.
    self.subcultures = {} --:map<string, bool>
    --now we start cycling through our humans list.
    for i, v in pairs(self.humans) do
        --we get a subculture for each human
        local sc = get_faction(v):subculture()
        --we set the value of that subculture key in the table to true.
        self.subcultures[sc] = true
    end
    --now we initialise the same for factions, but we don't know what factions we want to listen for yet, so we leave this alone.
    self.factions = {} --:map<string, bool>
    --finally, we have to initialise our storage table for the lord objects themselves. They go in here!
    self.lords = {} --:map<string, vector<LLR_LORD>>

    --once again, return our object.
    return self
end

--unlike the other methods we've looked at, which were basically functional or accessors, this one is a "mutator", or a "setter"
--it adds or edits information in the model.
--v function(self: LLR_MANAGER, lord: LLR_LORD)
  function llr_manager.add_lord(self, lord) 
    LLRLOG("Adding a lord to manager!");
    --first of all, we want to get the faction associated with the lord object we've been given. 
    local faction = lord:get_faction()
    --if we haven't stored any lords for this faction yet, then the index for them isn't going to be initialised.
    --trying to table.insert into soemthing that isn't yet a table would crash the script, not good!
    if self.lords[faction] == nil then self.lords[faction] = {} end;
    --this will handle that problem.
      local t = self.lords[faction] --get a handle on the index of lords for that faction
      table.insert(t, lord) --insert our new lord
      self.factions[faction] = true --tell the script to check for this faction when listening for confederations. 
      --we can do the above multiple times because as long as it is true, it works.
  end

--v function(self: LLR_MANAGER)
function llr_manager.activate(self)
    --time to tell our manager to actually do stuff!
  LLRLOG("Activating the Manager!");
    core:trigger_event("LegendaryLordModelActivated")
    --this event is listened for by other mods, to know when to add their lords into the system!
    

    --this listener is the key part of the map.
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
            local faction_name = context:faction():name(); --the faction getting eaten up.
            local confederation_name = context:confederation():name(); --the (player?) faction doing the eating.

            for k, v in pairs(self.lords) do
              if k == faction_name then --we only want lords who are from the faction being confederated
                for i = 1, #v do
                    if v[i]:survived_confederation(confederation_name) then --if they have survived the confederation (IE they are alive on the map)
                        v[i]:respec(confederation_name) --we use the respec method we defined earlier.
                    else --otherwise, if we can't find them on the map
                        v[i]:respawn_to_pool(confederation_name) -- we give them to our confederator.
                    end
                end
              end
            end
        end,
        true); --we want this listener to trigger as many times as necessary.

end

--for other mods to use these functions, we need to add them to the game space, making them public.
_G.llr_manager = llr_manager; --this one doesn't really need to be touched by anyone else, but whatever.
_G.llr_lord = llr_lord --this will let other people create new llr_lord objects
LLRLOG("Init Finished")
output("WEC: LEGENDARY LORD REVIVES ACTIVE") --we want to leave some trace of our mod in the general log.

function wec_ll_revival() --this is the function that CMF (our script loading infrastructure) calls at the start of a session.

LLRLOG("Checkpoint [1]")
llr = llr_manager.new() --create our manager
_G.llr = llr --add our new manager to the gamespace, other mods will need this to add any lords to it!

llr:activate() --activate our manager.

--lord template
--[[

  {
    ["subtype"] = "",
    ["forename"] = "",
    ["surname"] = "",
    ["faction"] = ""
  },

]]


local vanilla_lords = {
  {faction = "wh2_main_skv_clan_mors",forename = "names_name_2147359300",surname = "names_name_2147360908",subtype ="wh2_main_skv_queek_headtaker"},
  {faction = "wh2_main_skv_clan_pestilens",forename = "names_name_2147359289",surname = "names_name_2147359296",subtype ="wh2_main_skv_lord_skrolk"},
  {faction = "wh2_main_lzd_hexoatl",forename = "names_name_2147359221",surname = "names_name_2147359230",subtype ="wh2_main_lzd_lord_mazdamundi"},
  {faction = "wh2_main_lzd_last_defenders",forename = "names_name_2147359240",surname = "names_name_2147360514",subtype ="wh2_main_lzd_kroq_gar"},
  {faction = "wh2_main_hef_eataine",forename = "names_name_2147360906",surname = "names_name_2147360506",subtype ="wh2_main_hef_tyrion"},
  {faction = "wh2_main_hef_order_of_loremasters",forename = "names_name_2147359256",surname = "names_name_2147360506",subtype ="wh2_main_hef_teclis"},
  {faction = "wh2_main_def_cult_of_pleasure",forename = "names_name_2147359274",surname = "names_name_2147360508",subtype ="wh2_main_def_morathi"},
  {faction = "wh2_main_def_naggarond",forename = "names_name_2147359265",surname = "names_name_2147360508",subtype ="wh2_main_def_malekith"},
  {faction = "wh_main_vmp_vampire_counts",forename = "names_name_2147343886",surname = "names_name_2147343895",subtype ="vmp_mannfred_von_carstein"},
  {faction = "wh_main_vmp_vampire_counts",forename = "names_name_2147345320",surname = "names_name_2147345313",subtype ="vmp_heinrich_kemmler"},
  {faction = "wh_main_vmp_schwartzhafen",forename = "names_name_2147345124",surname = "names_name_2147343895",subtype ="pro02_vmp_isabella_von_carstein"},
  {faction = "wh_main_dwf_dwarfs",forename = "names_name_2147358917",surname = "names_name_2147358935",subtype ="pro01_dwf_grombrindal"},
  {faction = "wh_main_grn_greenskins",forename = "names_name_2147343863",surname = "names_name_2147343867",subtype ="grn_grimgor_ironhide"},
  {faction = "wh_main_grn_greenskins",forename = "names_name_2147345906",surname = "names_name_2147357356",subtype ="grn_azhag_the_slaughterer"},
  {faction = "wh_main_emp_empire",forename = "names_name_2147343849",surname = "names_name_2147343858",subtype ="emp_karl_franz"},
  {faction = "wh_main_emp_empire",forename = "names_name_2147343922",surname = "names_name_2147343928",subtype ="emp_balthasar_gelt"},
  {faction = "wh_main_dwf_dwarfs",forename = "names_name_2147344414",surname = "names_name_2147344423",subtype ="dwf_ungrim_ironfist"},
  {faction = "wh_main_dwf_dwarfs",forename = "names_name_2147343883",surname = "names_name_2147343884",subtype ="dwf_thorgrim_grudgebearer"},
  {faction = "wh_main_brt_carcassonne",forename = "names_name_2147358931",surname = "names_name_2147359018",subtype ="dlc07_brt_fay_enchantress"},
  {faction = "wh_main_brt_bordeleaux",forename = "names_name_2147345888",surname = "names_name_1529663917",subtype ="dlc07_brt_alberic"},
  {faction = "wh_main_grn_orcs_of_the_bloody_hand",forename = "names_name_2147358023",surname = "names_name_2147358027",subtype ="dlc06_grn_wurrzag_da_great_prophet"},
  {faction = "wh_main_grn_crooked_moon",forename = "names_name_2147358016",surname = "names_name_2147358924",subtype ="dlc06_grn_skarsnik"},
  {faction = "wh_main_dwf_karak_izor",forename = "names_name_2147358029",surname = "names_name_2147358036",subtype ="dlc06_dwf_belegar"},
  {faction = "wh_dlc05_wef_wood_elves",forename = "names_name_2147352809",surname = "names_name_2147359013",subtype ="dlc05_wef_orion"},
  {faction = "wh_dlc05_wef_argwylon",forename = "names_name_2147352813",surname = "names_name_2147359013",subtype ="dlc05_wef_durthu"},
  {faction = "wh_main_vmp_schwartzhafen",forename = "names_name_2147345130",surname = "names_name_2147343895",subtype ="dlc04_vmp_vlad_con_carstein"},
  {faction = "wh_main_vmp_vampire_counts",forename = "names_name_2147358044",surname = "names_name_2147345294",subtype ="dlc04_vmp_helman_ghorst"},
  {faction = "wh_main_emp_empire",forename = "names_name_2147358013",surname = "names_name_2147358014",subtype ="dlc04_emp_volkmar"},
  {faction = "wh_main_emp_middenland",forename = "names_name_2147343937",surname = "names_name_2147343940",subtype ="dlc03_emp_boris_todbringer"},
  {faction = "wh_main_brt_bretonnia",forename = "names_name_2147343915",surname = "names_name_2147343917",subtype ="brt_louen_leoncouer"},
  {faction = "wh2_dlc09_skv_clan_rictus",forename = "names_name_2147343915",surname = "names_name_2147343917",subtype ="wh2_dlc09_skv_tretch_craventail"},
}--:vector<map<string, string>>
  
for i = 1, #vanilla_lords do --start looping through the information we just defined.
  local clord = vanilla_lords[i] --makes the rest shorter and easier to type.
  local fact = clord.faction 
  local fname = clord.forename
  local sname = clord.surname
  local subtype = clord.subtype
  local lord = llr_lord.new(subtype, fname, sname, fact) --create the new lord object.
  llr:add_lord(lord) --add the new lord to our model.
end

	
end

--THE FUCKING END

--if you have any questions feel free to hop on C&C discord and ask me!