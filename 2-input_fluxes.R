
source("0-bbwm_packages.R")


bbwm_dep = read.csv("data/dep_bbwm_annual.csv")
how_dep = read.csv("data/dep_how_annual.csv")


bbwm_dep %>% 
  dplyr::rename(YEAR = CalYear) %>% 
  select(YEAR, S_WET, N_WET) %>% 
  filter(!YEAR=="2013")->bbwm_dep

how_dep %>% 
  filter(SITE_ID=="HOW191") %>%
  filter(YEAR>2012) %>% 
  select(YEAR, S_WET, N_WET)->how_dep

dep = rbind(bbwm_dep,how_dep)

ggplot(dep, aes(x = YEAR, y = N_WET))+
  geom_point()
ggplot(dep, aes(x = YEAR, y = S_WET))+
  geom_point()
