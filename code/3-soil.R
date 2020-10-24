### BBWM INITIAL RECOVERY -- NITRATE AND SULFATE STORY
### KAIZAD F. PATEL
### DECEMBER 2019

# 3-soil.R
# extractable soil N data from 2018 summer campaign

######################################## ###
######################################## ###

source("0-bbwm_packages.R")

soil = 
  read_excel("data/bbwm_soil_N.xlsx", sheet = "Sheet2")

soil2 = 
  soil %>% 
  dplyr::rename(Watershed = WS,
         NO3_N_mg_kg = `NO3 (ug N/g soil)`,
         NH4_N_mg_kg = `NH4 (ug N/g soil)`) %>% 
  dplyr::select(Watershed, NO3_N_mg_kg, NH4_N_mg_kg) %>% 
  dplyr::mutate(Watershed = case_when(Watershed == "BBE" ~ "EB",
                                      Watershed == "BBW" ~ "WB"))

soil3 = 
  soil2 %>% 
  group_by(Watershed) %>% 
  dplyr::summarise(NH4_mean = round(mean(NH4_N_mg_kg),2),
                   NO3_mean = round(mean(NO3_N_mg_kg),2),
                   NH4_se = round(sd(NH4_N_mg_kg)/sqrt(n()),2),
                   NO3_se = round(sd(NO3_N_mg_kg)/sqrt(n()),2))

nh4_aov = aov(data = soil2, NH4_N_mg_kg ~ Watershed)
summary(nh4_aov)

no3_aov = aov(data = soil2, NO3_N_mg_kg ~ Watershed)
summary(no3_aov)
