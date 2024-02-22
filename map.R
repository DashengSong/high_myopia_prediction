
library(sf)
library(ggplot2)
library(dplyr)
library(patchwork)

rm(list = ls())
setwd("D:/projects/HighMyopia")
# 地图数据(来源:http://datav.aliyun.com/portal/school/atlas/area_selector)
tianjin <- sf::st_read("misc/天津市.json")
df <- haven::read_sas("./Data/highmyopiabyarea.sas7bdat")

# 将学生数与地图数据连接
tianjin <- merge(tianjin,df,by.x="name",by.y="area_name")
#tianjin <- dplyr::rename(tianjin,Students=index)
tianjin$label <- c("Baodi","Beichen","Binhai New Area","Dongli","Heping","Hebei","Hedong",
                   "Hexi","Hongqiao","Jizhou","Jinnan","Jinghai","Nankai","Ninghe","Wuqing",
                   "Xiqing")
# Prevalence
ggplot(data = tianjin) + 
  geom_sf(aes(fill = COUNT), # 将income映射到填充颜色上
          color = "black",  # 轮廓颜色
          size = .5) + # 轮廓粗细
 # geom_sf_text(aes(label=label),check_overlap = T,color="orange",
 #              nudge_y=ifelse(tianjin$name=="Ninghe",0.5,0),fontface="bold")
  # 颜色设定
  scale_fill_gradient(low = "#F8F4F8", high = "#646C87",name="Students")+
  theme_classic()+
  theme(axis.ticks = element_blank(), 
        axis.text = element_blank(),
        axis.line = element_blank(),
        legend.position = c(1.2,0.2),
        plot.background=element_blank())+
        #panel.background = element_rect(fill = "grey"))
  xlab(NULL)+ylab(NULL)
# 保存地图
ggsave("./Plots/all_students_from_area.svg",dpi=1000,bg=NULL)


highmyopia <- haven::read_sas("./Data/highmyopiabygrd.sas7bdat")
highmyopia <- highmyopia[!is.na(highmyopia$graden) & highmyopia$highmyopia==1,c("graden","PCT_ROW")]
ggplot(data=highmyopia,aes(graden,PCT_ROW,fill=PCT_ROW))+
  geom_bar(stat = "identity")+
  scale_x_continuous(breaks = seq(1,9,1))+
  scale_fill_gradient(low="#58B1F4",high="#142B42",name="Prevalence(%)")+
  ylab("Highmyopia Prevalence(%)")+
  xlab("Grade")+
  theme_classic()+
  theme(panel.grid.major.y = element_line())
ggsave("./Plots/all_students_from_area_prevalence.svg",dpi=300)


# Incidence
df <- haven::read_sas("./Data/personsfromarea.sas7bdat")
tianjin <- sf::st_read("misc/天津市.json")
tianjin <- merge(tianjin,df,by.x="name",by.y="area_name")
#tianjin <- dplyr::rename(tianjin,Students=index)
tianjin$label <- c("Baodi","Beichen","Binhai New Area","Dongli","Heping","Hebei","Hedong",
                   "Hexi","Hongqiao","Jizhou","Jinnan","Jinghai","Nankai","Ninghe","Wuqing",
                   "Xiqing")
# 绘制地图
options(scipen= 999)
ggplot(data = tianjin) + 
  geom_sf(aes(fill = COUNT), # 将income映射到填充颜色上
          color = "black",  # 轮廓颜色
          size = .5) + # 轮廓粗细
  # geom_sf_text(aes(label=label),check_overlap = T,color="orange",
  #              nudge_y=ifelse(tianjin$name=="Ninghe",0.5,0),fontface="bold")
  # 颜色设定
  scale_fill_gradient(low = "#F8F4F8", high = "#646C87",name="Students")+
  theme_classic()+
  theme(axis.ticks = element_blank(), 
        axis.text = element_blank(),
        axis.line = element_blank(),
        legend.position = c(1.2,0.2),
        plot.background=element_blank())+
#panel.background = element_rect(fill = "grey"))
labs("Students")+
  xlab(NULL)+ylab(NULL)
ggsave("./Plots/model_students_from_area.svg",dpi=300)

highmyopia <- haven::read_sas("./Data/incidencebygrd.sas7bdat")
ggplot(data=highmyopia,aes(basegrd,incidence,fill=incidence))+
  geom_bar(stat = "identity")+
  scale_x_continuous(breaks = seq(1,6,1))+
  scale_fill_gradient(low="#58B1F4",high="#142B42",name="Incidence(%)")+
  ylab("Highmyopia Incidence(%)")+
  xlab("Grade")+
  theme_classic()+
  theme(panel.grid.major.y = element_line())
ggsave("./Plots/model_students_from_area_incidence.svg",dpi=300)
