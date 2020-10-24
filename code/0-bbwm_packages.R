## Functions
# Kaizad F. Patel
# November 2019

## packages ####

library(tidyverse)
library(readxl)
library(lubridate)     # 1.6.0
library(luzlogr)       # 0.2.0
library(Rmisc)
library(data.table)
library(cowplot)
library(qwraps2)
library(knitr)
library(reshape2)
library(ggalt)
library(ggExtra)
library(stringi)
library(nlme)
library(car)
library(agricolae)
library(drake)
library(harrypotter)





# create a custom ggplot theme
theme_kp <- function() {  # this for all the elements common across plots
  theme_bw() %+replace%
    theme(legend.position = "top",
          legend.key=element_blank(),
          legend.title = element_blank(),
          legend.text = element_text(size = 12),
          legend.key.size = unit(1.5, 'lines'),
          panel.border = element_rect(color="black",size=1.5, fill = NA),
          
          plot.title = element_text(hjust = 0.05, size = 14),
          axis.text = element_text(size = 14, color = "black"),
          axis.title = element_text(size = 14, face = "bold", color = "black"),
          
          # formatting for facets
          panel.background = element_blank(),
          strip.background = element_rect(colour="white", fill="white"), #facet formatting
          panel.spacing.x = unit(1.5, "lines"), #facet spacing for x axis
          panel.spacing.y = unit(1.5, "lines"), #facet spacing for x axis
          strip.text.x = element_text(size=12, face="bold"), #facet labels
          strip.text.y = element_text(size=12, face="bold", angle = 270) #facet labels
    )
}
