### BBWM INITIAL RECOVERY -- NITRATE AND SULFATE STORY
### KAIZAD F. PATEL
### DECEMBER 2019

# 2-input_fluxes.R
# input deposition for N and S
# using data from BBWM and Howland


source("0-bbwm_packages.R")

# 1. input files ----
bbwm_dep = read.csv("data/dep_bbwm_annual.csv")
how_dep = read.csv("data/dep_how_annual.csv")
gville_dep_seasonal = read.csv("data/dep_gville_seasonal.csv")

# clean the files 
bbwm_dep %>% 
  dplyr::rename(YEAR = CalYear) %>% 
  select(YEAR, S_WET, N_WET) %>% 
  filter(!YEAR=="2013")->
  bbwm_dep
### NOTE: BBWM dep data are for WATER YEAR


how_dep %>% 
  filter(SITE_ID=="HOW191") %>%
  #filter(YEAR>2012) %>% 
  select(YEAR, S_WET, N_WET, S_DRY, N_DRY)->
  how_dep
### NOTE: Howland dep data are for CALENDAR YEAR, so we can't use them with BBWM's WY.
# we want Dry Dep data from HOW, 
# so we calculate the dry-dep factor and apply that to BBWM's wet dep to estimate dry-dep at the site.
# FML
# multiply wet-dep by the factor to get dry-dep

N_FACTOR = mean(how_dep$N_DRY/how_dep$N_WET)
S_FACTOR = mean(how_dep$S_DRY/how_dep$S_WET)

              # plots to check trends
                ggplot(how_dep, aes(y = N_WET/N_DRY, x = YEAR))+
                  geom_point()

                ggplot(bbwm_dep, aes(x = YEAR, y = N_WET))+
                  geom_point()+
                  geom_smooth(method = "lm")
                  
                ggplot(bbwm_dep, aes(x = YEAR, y = S_WET))+
                  geom_point()+
                  geom_smooth(method = "lm")
                
#
# 2. filling missing data for 2013 onwards ----
## 2a. simple linear regression extrapolation of BBWM data ----

                
                s_lm = lm(S_WET~YEAR, data = bbwm_dep)
                s_slope =s_lm$coefficients["YEAR"]
                s_int =s_lm$coefficients["(Intercept)"]
                
                n_lm = lm(N_WET~YEAR, data = bbwm_dep)
                n_slope =n_lm$coefficients["YEAR"]
                n_int =n_lm$coefficients["(Intercept)"]
               
bb_temp = 
  data.frame("YEAR"=2013:2019) %>% 
  dplyr::mutate(S_WET = (YEAR*s_slope)+s_int,
                N_WET = (YEAR*n_slope)+n_int,
                data_type ="estimated")

bbwm_dep = 
  bbwm_dep %>% 
  dplyr::mutate(data_type="measured") %>% 
  rbind(bb_temp)


ggplot(bbwm_dep, aes(x = YEAR, y = S_WET))+
  geom_smooth(method = "lm", se = FALSE)+
  geom_point(aes(shape=data_type), size=2, stroke=1)+
  scale_shape_manual(values = c(1,19))+
  theme_kp()

ggplot(bbwm_dep, aes(x = YEAR, y = N_WET))+
  geom_smooth(method = "lm", se = FALSE)+
  geom_point(aes(shape=data_type), size=2, stroke=1)+
  scale_shape_manual(values = c(1,19))+
  theme_kp()
#

## 2b. simple linear regression with HOW data ----

# first, rename the HOW columns for ease later
how_dep %>% 
  dplyr::rename(S_how = S_WET,
         N_how = N_WET)->
  how_temp

# format bbwm deposition before merging with how. 
bbwm_dep[bbwm_dep$YEAR<2013,] %>% 
  dplyr::rename(S_bb = S_WET,
                N_bb = N_WET) %>% 
  full_join(how_temp, by = "YEAR")->
  temp

# now, run linear regressions of BBWM vs. HOW to get the slope and intercept
# sulfur
s_how_lm = lm(S_bb~S_how, data = temp, na.action = na.omit)
summary(s_how_lm)
s_how_slope = s_how_lm$coefficients["S_how"]
s_how_int = s_how_lm$coefficients["(Intercept)"]

# nitrogen
n_how_lm = lm(N_bb~N_how, data = temp, na.action = na.omit)
summary(n_how_lm)
n_how_slope = n_how_lm$coefficients["N_how"]
n_how_int = n_how_lm$coefficients["(Intercept)"]

# now, use the regression coefficients to calculate BBWM deposition
bbwm_dep_processed = 
  temp %>% 
  dplyr::mutate(
# estimating wet N and S    
                S_est = (S_how*s_how_slope)+s_how_int,
                N_est = (N_how*n_how_slope)+n_how_int,
# combine estimated and measured data into a single column
                S_bb = round(if_else(YEAR>2012, S_est,S_bb),2),
                N_bb = round(if_else(YEAR>2012, N_est,N_bb),2),
                data_type=if_else(YEAR>2012,"estimated","measured"),
# now calculate dry-dep using the factors above 
                N_bb_dry = round(N_bb*N_FACTOR,2),
                S_bb_dry = round(S_bb*S_FACTOR,2)) %>% 
  dplyr::select(YEAR, S_bb, N_bb, S_bb_dry, N_bb_dry,data_type) %>% 
  dplyr::rename(S_wet = S_bb,
                S_dry = S_bb_dry,
                N_wet = N_bb,
                N_dry = N_bb_dry) %>% 
  dplyr::mutate(N_in = N_wet+N_dry,
                S_in = S_wet+S_dry)

### OUTPUT  
write_csv(bbwm_dep_processed,"processed/deposition.csv")  


# random graphs 
ggplot(bbwm_dep_processed, aes(x = YEAR, y = S_bb))+
  geom_path()+
  geom_point(aes(shape=data_type), size=2, stroke=1)+
  scale_shape_manual(values = c(1,19))+
  ylim(0,7)+
  ylab(expression(bold("S, kg ha"^-1*" yr"^-1)))+
  theme_kp()

ggplot(bbwm_dep_processed, aes(x = YEAR, y = N_bb))+
  geom_path()+
  geom_point(aes(shape=data_type), size=2, stroke=1)+
  scale_shape_manual(values = c(1,19))+
  ylim(0,7)+
  ylab(expression(bold("N, kg ha"^-1*" yr"^-1)))+
  theme_kp()



#
# 3. input-output fluxes ----
# the input fluxes so far are ambient (EB) only
# we need to add values for WB
# create a temporary file and then combine with ambient

temp_flux_WB = 
  bbwm_dep_processed %>% 
  dplyr::mutate(N_in_W = if_else(YEAR>1989&YEAR<2017, N_in+25.2, N_in),
                S_in_W = if_else(YEAR>1989&YEAR<2017, S_in+28.8, S_in)) %>% 
  dplyr::select(YEAR, S_in_W, N_in_W, data_type) %>% 
  dplyr::rename(S_in = S_in_W,
                N_in = N_in_W) %>% 
  dplyr::mutate(Watershed="WB")


export_wy = read.csv("processed/flux_export.csv")
  
combined_flux = 
  bbwm_dep_processed %>% 
# this is EB-deposition only
  dplyr::mutate(Watershed="EB") %>% 
  select(YEAR, S_in, N_in, data_type, Watershed) %>% 
# now add WB-deposition
  rbind(temp_flux_WB) %>% 
  dplyr::rename(WY=YEAR) %>% 
# now combine with exports (WY)  
  left_join(select(export_wy, WY, Watershed,N_kgha, S_kgha), by = c("WY","Watershed")) %>% 
  dplyr::rename(
                N_out = N_kgha,
                S_out = S_kgha) %>% 
  filter(!WY==1988) %>% 
  group_by(Watershed) %>% 
# calculate retention as input-output. and then cumulative retention. 
  dplyr::mutate(N_ret = N_in-N_out,
                S_ret = S_in-S_out,
                N_out2 = N_out*-1,
                S_out2 = S_out*-1,
                N_cumret = cumsum(N_ret),
                S_cumret = cumsum(S_ret)) %>% 
  dplyr::mutate(N_percret = (N_ret/N_in)*100,
                S_percret = (S_ret/S_in)*100)
  
### OUTPUT  ----
write_csv(combined_flux,"processed/input_output.csv")  
write_csv(bbwm_dep_processed,"processed/deposition.csv")  


combined_flux %>% 
  filter(WY>1989 & WY < 2017) %>% 
  group_by(Watershed) %>% 
  dplyr::summarise(S_percret = mean(S_percret))

combined_flux %>% 
  ggplot(aes(x = WY, y = S_percret, color = Watershed))+
  geom_point()+geom_path()
