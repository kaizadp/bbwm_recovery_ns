## BBWM stream recovery 
## stream chemistry 1989-2018

source("0-bbwm_packages.R")

plan = drake_plan(
#
# STEP 1: load files -------------------- # ----
bbwm_annual = read.csv ("data/bbwm_annual.csv"), ## fluxes
bbwm_all = read_csv("data/bbwm_all.csv"), ## concentrations

# STEP 2: process annual flux data ----
# create subset with select columns
annual = 
  bbwm_annual %>%
  dplyr::select(WY,Watershed,Area,H2O,DOC,NO3,SO4,ANC,`Discharge.L.s`,EQPH,`N.flux`) %>% 
  dplyr::rename(Q = `Discharge.L.s`) %>% 
  dplyr::mutate(Watershed = factor(Watershed, levels = c("EB","WB")),
# create columns to group by year/period
                WY_group = case_when(WY <1990 ~"1989",
                                     (WY>1989 & WY <2000) ~ "1990-99",
                                     (WY>1999 & WY <2010) ~ "2000-09",
                                     (WY>2009 & WY <2017) ~ "2010-16",
                                     (WY>2016) ~ "2017-18"),
                period = case_when(WY<1990 ~ "pre-treatment",
                                   (WY>1989 & WY <2000)~ "first decade",
                                   (WY>1999 & WY <2010)~ "second decade",
                                   (WY>2009 & WY <2017)~ "third decade",
                                   (WY>2016)~ "recovery"),
                WY_group = factor(WY_group,
                                  levels=c("1989","1990-99","2000-09","2010-16","2017-18")),
                period = factor(period,
                                levels=c("pre-treatment","first decade","second decade","third decade","recovery")),
# convert ueq to kg
                NO3_N = NO3*14/1000,
                SO4_S = SO4*32/(2*1000),
                N_kgha = `N.flux`*14/1000,
# create columns for volume-weighted
                NO3_vol = round(NO3_N/(H2O/Area),2),
                SO4_vol = round(SO4_S/(H2O/Area),2),
                DOC_vol = round(DOC/(H2O/Area),2)),


# STEP 3: process concentrations dataset ----

# create subset with select columns
all = 
  bbwm_all %>%
  dplyr::select(Watershed,Year,WY,Month,Day,`NO3 (ueq/L)`,
         `SO4 (ueq/L)`,`DOC (mg/L)`,`Discharge (L/sec)`,`Specific Conductance (us/cm)`,`ANC (ueq/L)`) %>%
  dplyr::filter(Watershed %in% c("EB","WB")) %>% 
  dplyr::rename(NO3 = `NO3 (ueq/L)`,
              SO4 = `SO4 (ueq/L)`,
              DOC = `DOC (mg/L)`,
              Q = `Discharge (L/sec)`,
              ANC = `ANC (ueq/L)`) %>% 
  dplyr::mutate(NO3_N = NO3*14/1000,
                SO4_S = SO4*32/(2*1000)) %>% 
  dplyr::mutate(dates = as.Date(paste(Year, Month, Day,sep="-"))),




# STEP 4: annual flux summary table -------------------- # ----

summary = annual %>% 
  dplyr::select(Watershed,period,NO3_N,SO4_S) %>% 
  #gather(species,flux,NO3:SO4) %>% 
  melt(measure.vars = c("NO3_N","SO4_S"),value.name = "flux") %>% 
  dplyr::rename(species = variable) %>% 
  group_by(Watershed,period,species) %>% 
  dplyr::summarise(mean = mean(flux),
                   se = sd(flux)/sqrt(n())) %>% 
  dplyr::mutate(summary = paste(round(mean,2),"\u00B1",round(se,2))),

# STEP 5: exporting ALL and ANNUAL ----
write.csv(all,"processed/concentrations.csv", row.names = FALSE),
write.csv(annual,"processed/fluxes.csv", row.names = FALSE),
write.csv(summary,"processed/summary.csv", row.names = FALSE)

)


################################
################################

export_month = read.csv("data/bbwm_export_month.csv")

  export_month %>% 
  dplyr::select(Year, Month, Watershed, NH4, NO3, SO4) %>% 
  dplyr::mutate(NH4 = as.numeric(as.character(NH4)),
                NO3 = as.numeric(as.character(NO3)),
                SO4 = as.numeric(as.character(SO4)),
                WY  = if_else(Month>9, as.integer(Year+1),Year)) ->
    temp
  
export_cy = 
  temp  %>% 
  group_by(Year, Watershed) %>% 
  dplyr::summarise(n = n(),
                   NH4_eq = sum(NH4, na.rm = TRUE),
                   NO3_eq = sum(NO3, na.rm = TRUE),
                   SO4_eq = sum(SO4, na.rm = TRUE),
                   N_eq = NH4_eq+NO3_eq,
                   N_kgha = N_eq*14/1000,
                   S_kgha = SO4_eq*32/(2*1000)) %>% 
  filter(n==12) %>% 
  ungroup %>% 
  dplyr::select(Year, Watershed, N_kgha, S_kgha)

export_wy = 
  temp  %>% 
  group_by(WY, Watershed) %>% 
  dplyr::summarise(n = n(),
                   NH4_eq = sum(NH4, na.rm = TRUE),
                   NO3_eq = sum(NO3, na.rm = TRUE),
                   SO4_eq = sum(SO4, na.rm = TRUE),
                   N_eq = NH4_eq+NO3_eq,
                   N_kgha = N_eq*14/1000,
                   S_kgha = SO4_eq*32/(2*1000)) %>% 
  filter(n==12) %>% 
  ungroup %>% 
  dplyr::select(WY, Watershed, N_kgha, S_kgha)


# comparing WY and CY
ggplot()+
# calendar year calculated from months
  geom_path(data=export_cy, aes(x = Year, y = N_kgha), color = "red")+
# WY calculated from months
  geom_path(data=export_wy, aes(x = WY, y = N_kgha), color = "blue")+
  facet_wrap(~Watershed)
  
ggplot()+
  geom_path(data=export_cy, aes(x = Year, y = S_kgha), color = "red")+
  geom_path(data=export_wy, aes(x = WY, y = S_kgha), color = "blue")+
  facet_wrap(~Watershed)














