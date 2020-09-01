## BBWM stream recovery 
## stream chemistry 1989-2018

source("0-bbwm_packages.R")

plan = drake_plan(
#
# STEP 1: load files -------------------- # ----
bbwm_annual = read.csv ("data/bbwm_annual.csv"), ## fluxes
bbwm_all = read_csv("data/bbwm_all.csv"), ## concentrations

# STEP 2: process annual concentrations data ----
# create subset with select columns
annual = 
  bbwm_annual %>%
  dplyr::select(WY,Watershed,Area,H2O,NO3,SO4) %>% 
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

# create columns for volume-weighted
# these will have units of ueq/L
NO3_vol_ueq_L = round(NO3/(H2O/Area),2),
SO4_vol_ueq_L = round(SO4/(H2O/Area),2),
# convert ueq to mg
# these units are mg/L
#                NO3_N = NO3_vol_ueq_L*14/1000,
#                SO4_S = SO4_vol_ueq_L*32/(2*1000)
),

# STEP 3: process concentrations dataset ----

# create subset with select columns
all = 
  bbwm_all %>%
  dplyr::select(Watershed,Year,WY,Month,Day,`NO3 (ueq/L)`,
         `SO4 (ueq/L)`) %>%
  dplyr::filter(Watershed %in% c("EB","WB")) %>% 
  dplyr::rename(NO3_ueq_L = `NO3 (ueq/L)`,
              SO4_ueq_L = `SO4 (ueq/L)`) %>% 
#  dplyr::mutate(NO3_N = NO3_ueq_L*14/1000, # mg/L
#                SO4_S = SO4_ueq_L*32/(2*1000)) %>% # mg/L 
  dplyr::mutate(dates = as.Date(paste(Year, Month, Day,sep="-"))),

# STEP 4: annual flux summary table -------------------- # ----

summary = annual %>% 
  dplyr::select(Watershed,period,NO3_vol_ueq_L,SO4_vol_ueq_L) %>% 
  #gather(species,flux,NO3:SO4) %>% 
  melt(measure.vars = c("NO3_vol_ueq_L","SO4_vol_ueq_L"),value.name = "conc_ueq_L") %>% 
  dplyr::rename(species = variable) %>% 
  group_by(Watershed,period,species) %>% 
  dplyr::summarise(mean = mean(conc_ueq_L),
                   se = sd(conc_ueq_L)/sqrt(n())) %>% 
  dplyr::mutate(summary = paste(round(mean,2),"\u00B1",round(se,2))),

# STEP 5: annual export flux ----

export_wy = 
  bbwm_annual  %>% 
  dplyr::mutate(NH4 = replace_na(NH4,0),
                N_eq = NH4+NO3,
                N_kgha = round(N_eq*14/1000,2),
                S_kgha = round(SO4*32/(2*1000),2)) %>% 
  dplyr::select(WY, Watershed, N_kgha, S_kgha),

#
# STEP 6: exporting ALL and ANNUAL ----
write.csv(all,"processed/concentrations.csv", row.names = FALSE),
write.csv(annual,"processed/fluxes.csv", row.names = FALSE),
write.csv(summary,"processed/summary.csv", row.names = FALSE),
write.csv(export_wy,"processed/flux_export.csv", row.names = FALSE)

)

make(plan)

################################
################################


all %>% 
  dplyr::mutate(doy = yday(dates))->
  all

ggplot(all[all$Watershed=="WB",], aes(x = doy, y = NO3_N, color = as.factor(Year)))+
  geom_point()+
  geom_path()+
  geom_smooth()+
  xlim(0,200)+
  facet_wrap(Watershed~Year)

      ##  
      ##    )
      ##    melt(id = c("Watershed","period"), measure) %>% 
      ##  
      ##  
      ##  annual_melt = melt(annual, 
      ##                     id.vars = c("Watershed", "period"),
      ##                     measure.vars = c("NO3","SO4"))
      ##  
      ##  annual_melt_rmisc = summarySE(annual_melt,
      ##                                measurevar = "value",
      ##                                groupvars = c("variable","Watershed","period"), na.rm = TRUE)
      ##  
      ##  annual_melt_rmisc$summary = paste(round(annual_melt_rmisc$value,2),"\u00B1",round(annual_melt_rmisc$se,2))
      ##  
      ##  annual_summary = dcast(annual_melt_rmisc,
      ##                         variable+Watershed~period,
      ##                         value.var = "summary")
      ##  write.csv(annual_summary, file="annual_flux_summary.csv")
      ##  
      ##  #
      ##  # summary stats -------------------- # ----
      ##  # summary stats
      ##  
