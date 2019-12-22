
source("0-bbwm_packages.R")


bbwm_dep = read.csv("data/dep_bbwm_annual.csv")
how_dep = read.csv("data/dep_how_annual.csv")


bbwm_dep %>% 
  dplyr::rename(YEAR = CalYear) %>% 
  select(YEAR, S_WET, N_WET) %>% 
  filter(!YEAR=="2013")->bbwm_dep

how_dep %>% 
  filter(SITE_ID=="HOW191") %>%
  #filter(YEAR>2012) %>% 
  select(YEAR, S_WET, N_WET)->how_dep

dep = rbind(bbwm_dep,how_dep)

ggplot(bbwm_dep, aes(x = YEAR, y = N_WET))+
  geom_point()+
  geom_smooth(method = "lm")
  
ggplot(bbwm_dep, aes(x = YEAR, y = S_WET))+
  geom_point()+
  geom_smooth(method = "lm")


s_lm = lm(S_WET~YEAR, data = bbwm_dep)
s_slope =s_lm$coefficients["YEAR"]
s_int =s_lm$coefficients["(Intercept)"]

n_lm = lm(N_WET~YEAR, data = bbwm_dep)
n_slope =n_lm$coefficients["YEAR"]
n_int =n_lm$coefficients["(Intercept)"]

## estimating bbwm deposition fluxes 2013 onwards by simple linear regression extrapolation ----
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

## using how to estimate bbwm deposition ----


how_dep %>% 
  dplyr::rename(S_how = S_WET,
         N_how = N_WET)->
  how_temp

bbwm_dep[bbwm_dep$YEAR<2013,] %>% 
  dplyr::rename(S_bb = S_WET,
                N_bb = N_WET) %>% 
  full_join(how_temp, by = "YEAR")->
  temp

s_how_lm = lm(S_bb~S_how, data = temp, na.action = na.omit)
summary(s_how_lm)
s_how_slope = s_how_lm$coefficients["S_how"]
s_how_int = s_how_lm$coefficients["(Intercept)"]


n_how_lm = lm(N_bb~N_how, data = temp, na.action = na.omit)
summary(n_how_lm)
n_how_slope = n_how_lm$coefficients["N_how"]
n_how_int = n_how_lm$coefficients["(Intercept)"]

temp %>% 
  dplyr::mutate(S_est = (S_how*s_how_slope)+s_how_int,
                N_est = (N_how*n_how_slope)+n_how_int,
                S_bb = round(if_else(YEAR>2012, S_est,S_bb),2),
                N_bb = round(if_else(YEAR>2012, N_est,N_bb),2),
                data_type=if_else(YEAR>2012,"estimated","measured")) %>% 
  dplyr::select(YEAR, S_bb, N_bb, data_type)->
  bbwm_dep_processed

write_csv(bbwm_dep_processed,"processed/deposition.csv")  



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


