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
  dplyr::select(WY,Watershed,Area,H2O,DOC,NO3,SO4,ANC,`Discharge.L.s`,EQPH) %>% 
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
# create columns for volume-weighted
                NO3_vol = round(NO3/(H2O/Area),2),
                SO4_vol = round(SO4/(H2O/Area),2),
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
  dplyr::mutate(dates = as.Date(paste(Year, Month, Day,sep="-"))),




# STEP 4: annual flux summary table -------------------- # ----

summary = annual %>% 
  dplyr::select(Watershed,period,NO3,SO4) %>% 
  #gather(species,flux,NO3:SO4) %>% 
  melt(measure.vars = c("NO3","SO4"),value.name = "flux") %>% 
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
