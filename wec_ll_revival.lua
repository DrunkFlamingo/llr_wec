cm:set_saved_value("wec_ll_revival", true);
llr_lord = {} --# assume llr_lord: LLR_LORD
llr_manager = {} --# assume llr_manager: LLR_MANAGER
--toggle this to turn logging on or off.
isLogAllowed = false --:boolean

--v function(text: string)
function LLRLOG(text)
    ftext = "LLR"

    if not isLogAllowed then
      return;
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

--v function(self: LLR_LORD) --> string
  function llr_lord.get_faction(self)
      return self.faction;
  end


--v function(self: LLR_LORD, faction: string) --> boolean
function llr_lord.is_lord_involved(self, faction)
    LLRLOG("IsLordInvolved Returning ["..tostring(faction == self.faction).."] ")
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
    LLRLOG("survived_confederation Returning ["..tostring(_llrRetval).."]")
    return _llrRetval;
end


--v function(self: LLR_LORD, human_faction_name: string)
function llr_lord.respawn_to_pool(self, human_faction_name)
    LLRLOG("Respawning lord with subtype ["..self.subtype.."] to pool!")
    cm:spawn_character_to_pool(human_faction_name, self.forename, self.surname, "", "", 18, true, "general", self.subtype, true, "");
end

--v function(self: LLR_LORD, faction: string)
function llr_lord.respec(self, faction)
    local exp_to_levels_table = {
      900, --1
      1900, --2
      3000, --3
      4200, --4
      5500,
      6870,
      8370,
      9940,
      11510,
      13080,
      14660,
      16240,
      17820,
      19400,
      20990,
      22580,
      24170,
      25770,
      27370,
      28980,
      30590,
      32210,
      33830,
      35460,
      37100,
      38740,
      40390,
      42050,
      43710,
      45380,
      47060,
      48740,
      50430,
      52130,
      53830,
      55540,
      57260,
      58990,
      60730,
      60730,
      60730 }--:vector<number>
    LLRLOG("Respecing lord with subtype ["..self.subtype.."] ")

    --this will catch any mishandle of the respec
    if self.safety_abort == true then
        LLRLOG("Aborting Respec, tried to respec a lord that originates from a human faction !?!?")
        return
    end
    local character_faction = get_faction(faction);
    local character_list = character_faction:character_list();
    LLRLOG("Cycling through the character list to find the new character")
    for i = 0, character_list:num_items() - 1 do
        local character = character_list:item_at(i);

        if character:character_subtype(self.subtype) and character:get_forename() == self.forename then
            LLRLOG("Checkpoint 2: Found our desired character.")
            --first, we need to store the army list.
            self.army_list = {} --:vector<string>
            for j = 0, character:military_force():unit_list():num_items() - 1 do
                local current_unit = character:military_force():unit_list():item_at(j):unit_key()
                table.insert(self.army_list, current_unit)
            end
            --there are problems with adding tons of units to an army, so we're going to have to assembly the string.
            self.spawn_string = ""
            for k = 2, #self.army_list do
                next_string = self.spawn_string..","..self.army_list[k]
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
            LLRLOG("found positioning data as x = ["..tostring(self.x).."], y = ["..tostring(self.y).."], region = ["..self.region.."]")

            LLRLOG("Killing the inherited lord!")
            --we need to prevent the message from showing uP

            cm:disable_event_feed_events(true, "", "wh_event_subcategory_character_deaths", "");
            cm:set_character_immortality(char_lookup_str(character:command_queue_index()), false);
            cm:kill_character(char_lookup_str(character:command_queue_index()), true, true)
            --turn message back on.
            cm:callback(function() cm:disable_event_feed_events(false, "", "wh_event_subcategory_character_deaths", "") end, 1);
            --now, spawn the lord
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
                "llr"..self.forename..self.subtype,
                false,
                function(cqi) 
                    LLRLOG("Levelling up the respec'd lord!")
                    output("WEC: CHEckpoint")
                    cm:set_character_immortality(char_lookup_str(cqi), true);
                    cm:add_agent_experience(char_lookup_str(cqi), exp_to_levels_table[self.exp_level])

                    
                    LLRLOG("Levelling up the respec'd lord finished.")
                end)
            end,
            0.1
        );
        --break otherwise the loop might find the character and keep doing this infinitely.
        break;
        end
    end
end

--v function() --> LLR_MANAGER
function llr_manager.new()
  LLRLOG("Creating the manager!");
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
    LLRLOG("Adding a lord to manager!");
      local faction = lord:get_faction()
    if self.lords[faction] == nil then self.lords[faction] = {} end;
      local t = self.lords[faction]
      table.insert(t, lord)
      self.factions[faction] = true
  end

--v function(self: LLR_MANAGER)
function llr_manager.activate(self)
  LLRLOG("Activating the Manager!");
    core:trigger_event("LegendaryLordModelActivated")
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
              if k == faction_name then
                for i = 1, #v do
                    if v[i]:survived_confederation(confederation_name) then
                        v[i]:respec(confederation_name)
                    else
                        v[i]:respawn_to_pool(confederation_name)
                    end
                end
              end
            end
        end,
        true);

end
_G.llr_manager = llr_manager;
_G.llr_lord = llr_lord
LLRLOG("Init Finished")
output("WEC: LEGENDARY LORD REVIVES ACTIVE")

function wec_ll_revival()

LLRLOG("Checkpoint [1]")
llr = llr_manager.new()
_G.llr = llr
llr:activate()

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
  
for i = 1, #vanilla_lords do
  local clord = vanilla_lords[i]
  local fact = clord.faction
  local fname = clord.forename
  local sname = clord.surname
  local subtype = clord.subtype
  local lord = llr_lord.new(subtype, fname, sname, fact)
  llr:add_lord(lord)
end

	
end

