
source("0-bbwm_packages.R")


bbwm_dep = read.csv("data/dep_bbwm_annual.csv")
how_dep = read.csv("data/dep_how_annual.csv")
gville_dep_seasonal = read.csv("data/dep_gville_seasonal.csv")

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



#
## using greenville data ----
gville_dep_seasonal %>% 
  dplyr::mutate(YEAR = if_else(seas=="Fall",as.integer(yr+1),yr)) %>%
  filter(NO3>0) %>% 
  group_by(YEAR) %>% 
  dplyr::summarize(NO3_kgha = sum(NO3),
                   SO4_kgha = sum(SO4)) %>% 
  filter(YEAR>1987&YEAR<2019) %>% 
  ungroup %>% 
  dplyr::mutate(N_greenv = round(NO3_kgha*14/62,2),
                S_greenv = round(SO4_kgha*32/96,2)) %>% 
  dplyr::select(YEAR, N_greenv, S_greenv)->gville_dep_annual

ggplot(gville_dep_annual, aes(x = YEAR, y = N_greenv))+
  geom_point()


##
bbwm_dep[bbwm_dep$YEAR<2013,] %>% 
  dplyr::rename(S_bb = S_WET,
                N_bb = N_WET) %>% 
  full_join(gville_dep_annual, by = "YEAR")->
  temp

s_gr_lm = lm(S_bb~S_greenv, data = temp, na.action = na.omit)
summary(s_gr_lm)
s_gr_slope = s_gr_lm$coefficients["S_greenv"]
s_gr_int = s_gr_lm$coefficients["(Intercept)"]


n_gr_lm = lm(N_bb~N_greenv, data = temp, na.action = na.omit)
summary(n_gr_lm)
n_gr_slope = n_gr_lm$coefficients["N_greenv"]
n_gr_int = n_gr_lm$coefficients["(Intercept)"]

temp %>% 
  dplyr::mutate(S_est = (S_greenv*s_gr_slope)+s_gr_int,
                N_est = (N_greenv*n_gr_slope)+n_gr_int,
                S_bb = round(if_else(YEAR>2012, S_est,S_bb),2),
                N_bb = round(if_else(YEAR>2012, N_est,N_bb),2),
                data_type=if_else(YEAR>2012,"estimated","measured")) %>% 
  dplyr::select(YEAR, S_bb, N_bb, data_type)->
  bbwm_dep_processed

ggplot(bbwm_dep_processed, aes(x = YEAR, y = N_bb))+
         geom_point()


### plotting input and output
temp_flux_WB = 
  bbwm_dep_processed %>% 
  dplyr::mutate(N_in_W = if_else(YEAR>1988&YEAR<2017, N_bb+25.2, N_bb),
                S_in_W = if_else(YEAR>1988&YEAR<2017, S_bb+28.8, S_bb)) %>% 
  dplyr::select(YEAR, S_in_W, N_in_W, data_type) %>% 
  dplyr::rename(S_bb = S_in_W,
                N_bb = N_in_W) %>% 
  dplyr::mutate(Watershed="WB")

combined_flux = 
  bbwm_dep_processed %>% 
  dplyr::mutate(Watershed="EB") %>% 
  rbind(temp_flux_WB) %>% 
  dplyr::rename(WY=YEAR) %>% 
  left_join(select(annual, WY, Watershed,NO3_N, SO4_S), by = c("WY","Watershed")) %>% 
  dplyr::rename(
                N_in = N_bb,
                S_in = S_bb,
                N_out = NO3_N,
                S_out = SO4_S) %>% 
  filter(!WY==1988) %>% 
  group_by(Watershed) %>% 
  dplyr::mutate(N_ret = N_in-N_out,
                S_ret = S_in-S_out,
                N_out = N_out*-1,
                S_out = S_out*-1,
                N_cumret = cumsum(N_ret),
                S_cumret = cumsum(S_ret))
  
  
ggplot() +
  geom_point(data=combined_flux,aes(x = WY, y = N_in))+
  geom_path(data=combined_flux,aes(x = WY, y = N_in))+
  geom_point(data=combined_flux,aes(x = WY, y = N_out))+
  geom_path(data=combined_flux,aes(x = WY, y = N_out))+
  geom_bar(data=combined_flux,aes(x = WY, y = N_cumret/10), stat = "identity", alpha = 0.2)+
  annotate("text", label = "input",x = 1995, y = 20)+
  annotate("text", label = "output",x = 1995, y = -10)+
  ylab("N, kg/ha/yr")+
  scale_y_continuous(sec.axis = sec_axis(~.*10, name = "cum retention, kg/ha"))+
  facet_wrap(~Watershed)+
  theme_kp()
  
ggplot() +
  geom_point(data=combined_flux,aes(x = WY, y = S_in))+
  geom_path(data=combined_flux,aes(x = WY, y = S_in))+
  geom_point(data=combined_flux,aes(x = WY, y = S_out))+
  geom_path(data=combined_flux,aes(x = WY, y = S_out))+
  geom_bar(data=combined_flux,aes(x = WY, y = S_cumret/10), stat = "identity", alpha = 0.2)+
  scale_y_continuous(sec.axis = sec_axis(~.*10, name = "cum retention"))+
  ylab("S, kg/ha/yr")+
  facet_wrap(~Watershed)+
  theme_kp()


ggplot() +
  geom_bar(data=combined_flux,aes(x = WY, y = S_in), stat = "identity", alpha = 0.2, fill = "blue")+
  geom_bar(data=combined_flux,aes(x = WY, y = S_out), stat = "identity", alpha = 0.2)+
  geom_point(data=combined_flux,aes(x = WY, y = S_cumret/10))+
  geom_hline(yintercept = 0)+
  scale_y_continuous(sec.axis = sec_axis(~.*10, name = "cum retention"))+
  ylab("S, kg/ha/yr")+
  facet_wrap(~Watershed)+
  theme_kp()

ggplot() +
  geom_bar(data=combined_flux,aes(x = WY, y = N_in), stat = "identity", alpha = 0.5, fill = "blue")+
  geom_bar(data=combined_flux,aes(x = WY, y = N_out), stat = "identity", alpha = 0.2)+
  geom_point(data=combined_flux,aes(x = WY, y = N_cumret/20))+
  geom_hline(yintercept = 0)+
  scale_y_continuous(sec.axis = sec_axis(~.*20, name = "cum retention"))+
  ylab("N, kg/ha/yr")+
  facet_wrap(~Watershed)+
  theme_kp()
