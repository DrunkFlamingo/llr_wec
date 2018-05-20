
--toggle this to turn logging on or off.
isLogAllowed = true --:boolean

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


local llr_lord = require("wec/llr_lords")
local llr_manager = require("wec/llr_manager")

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
  {faction = "placeholder",forename = "names_name_497575138",surname = "names_name_266919778",subtype ="wh2_main_skv_warlord"},
  {faction = "placeholder",forename = "names_name_2147359300",surname = "names_name_2147360908",subtype ="wh2_main_skv_queek_headtaker"},
  {faction = "placeholder",forename = "names_name_2147359289",surname = "names_name_2147359296",subtype ="wh2_main_skv_lord_skrolk"},
  {faction = "placeholder",forename = "names_name_2147359221",surname = "names_name_2147359230",subtype ="wh2_main_lzd_lord_mazdamundi"},
  {faction = "placeholder",forename = "names_name_2147359240",surname = "names_name_2147360514",subtype ="wh2_main_lzd_kroq_gar"},
  {faction = "placeholder",forename = "names_name_2147360906",surname = "names_name_2147360506",subtype ="wh2_main_hef_tyrion"},
  {faction = "placeholder",forename = "names_name_2147359256",surname = "names_name_2147360506",subtype ="wh2_main_hef_teclis"},
  {faction = "placeholder",forename = "names_name_2147360555",surname = "names_name_2147360560",subtype ="wh2_main_hef_prince_alastar"},
  {faction = "placeholder",forename = "names_name_2147359274",surname = "names_name_2147360508",subtype ="wh2_main_def_morathi"},
  {faction = "placeholder",forename = "names_name_2147359265",surname = "names_name_2147360508",subtype ="wh2_main_def_malekith"},
  {faction = "placeholder",forename = "names_name_2147359236",surname = "names_name_",subtype ="wh_dlc05_vmp_red_duke"},
  {faction = "placeholder",forename = "names_name_2147343886",surname = "names_name_2147343895",subtype ="vmp_mannfred_von_carstein"},
  {faction = "placeholder",forename = "names_name_2147345320",surname = "names_name_2147345313",subtype ="vmp_heinrich_kemmler"},
  {faction = "placeholder",forename = "names_name_2147345124",surname = "names_name_2147343895",subtype ="pro02_vmp_isabella_von_carstein"},
  {faction = "placeholder",forename = "names_name_2147358917",surname = "names_name_2147358935",subtype ="pro01_dwf_grombrindal"},
  {faction = "placeholder",forename = "names_name_2147343863",surname = "names_name_2147343867",subtype ="grn_grimgor_ironhide"},
  {faction = "placeholder",forename = "names_name_2147345906",surname = "names_name_2147357356",subtype ="grn_azhag_the_slaughterer"},
  {faction = "placeholder",forename = "names_name_2147343849",surname = "names_name_2147343858",subtype ="emp_karl_franz"},
  {faction = "placeholder",forename = "names_name_2147343922",surname = "names_name_2147343928",subtype ="emp_balthasar_gelt"},
  {faction = "placeholder",forename = "names_name_2147344414",surname = "names_name_2147344423",subtype ="dwf_ungrim_ironfist"},
  {faction = "placeholder",forename = "names_name_2147343883",surname = "names_name_2147343884",subtype ="dwf_thorgrim_grudgebearer"},
  {faction = "placeholder",forename = "names_name_2147358931",surname = "names_name_2147359018",subtype ="dlc07_brt_fay_enchantress"},
  {faction = "placeholder",forename = "names_name_2147345888",surname = "names_name_1529663917",subtype ="dlc07_brt_alberic"},
  {faction = "placeholder",forename = "names_name_2147358023",surname = "names_name_2147358027",subtype ="dlc06_grn_wurrzag_da_great_prophet"},
  {faction = "placeholder",forename = "names_name_2147358016",surname = "names_name_2147358924",subtype ="dlc06_grn_skarsnik"},
  {faction = "placeholder",forename = "names_name_2147358029",surname = "names_name_2147358036",subtype ="dlc06_dwf_belegar"},
  {faction = "placeholder",forename = "names_name_2147352809",surname = "names_name_2147359013",subtype ="dlc05_wef_orion"},
  {faction = "placeholder",forename = "names_name_2147352813",surname = "names_name_2147359013",subtype ="dlc05_wef_durthu"},
  {faction = "placeholder",forename = "names_name_2147352897",surname = "names_name_2147357944",subtype ="dlc05_bst_morghur"},
  {faction = "placeholder",forename = "names_name_2147345130",surname = "names_name_2147343895",subtype ="dlc04_vmp_vlad_con_carstein"},
  {faction = "placeholder",forename = "names_name_2147358044",surname = "names_name_2147345294",subtype ="dlc04_vmp_helman_ghorst"},
  {faction = "placeholder",forename = "names_name_2147358013",surname = "names_name_2147358014",subtype ="dlc04_emp_volkmar"},
  {faction = "placeholder",forename = "names_name_2147343937",surname = "names_name_2147343940",subtype ="dlc03_emp_boris_todbringer"},
  {faction = "placeholder",forename = "names_name_2147357619",surname = "names_name_2147358923",subtype ="dlc03_bst_malagor"},
  {faction = "placeholder",forename = "names_name_2147352487",surname = "names_name_2147357906",subtype ="dlc03_bst_khazrak"},
  {faction = "placeholder",forename = "names_name_2147345922",surname = "names_name_2147357370",subtype ="chs_prince_sigvald"},
  {faction = "placeholder",forename = "names_name_2147345931",surname = "names_name_2147345934",subtype ="chs_kholek_suneater"},
  {faction = "placeholder",forename = "names_name_2147343903",surname = "names_name_2147357364",subtype ="chs_archaon"},
  {faction = "placeholder",forename = "names_name_2147343915",surname = "names_name_2147343917",subtype ="brt_louen_leoncouer"}
},  
  