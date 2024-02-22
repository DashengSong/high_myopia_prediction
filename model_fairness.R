#-----------------------
# Model fairness 
#-----------------------
library(tidyr)
library(dplyr)
library(ggplot2)
library(patchwork)
library(ggsci)

setwd("D:/projects/Highmyopia")
df <- readxl::read_xlsx("./Docus/fairness.xlsx")

ggplot(data=df,aes(grade,value,fill=factor(models)))+
  geom_bar(stat = "identity",position = "dodge")+
  scale_x_continuous(breaks = seq(1,6,1))+
  scale_fill_jama(name="",breaks=c(1,2),labels=c("Overall","Grade-specific"))+
  theme_classic()+
  theme(legend.position = c(0.1,0.95))+
  xlab("Grade")+ylab("TPR")
ggsave(filename = "./Plots/fairnessbygrade.jpg",dpi=300)
