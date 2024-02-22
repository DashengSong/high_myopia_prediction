
library(ggalluvial)
library(dplyr)
library(patchwork)

setwd("D:\\projects\\Highmyopia")

df <- read.csv("./Data/sankeyData.csv")
df$baseucva <- abs(df$baseucva)
df2 <- df

df <- df %>% group_by(basegrd,familyHistory,baseucva,basesef,wearGlass,cluster) %>% summarise(prop=mean(prop,na.rm = T))
df$basegrd <- factor(df$basegrd)
df$baseucva <- cut(df$baseucva,breaks = c(-Inf,4,4.99,Inf),labels = c("≤4","4-5",">=5"))
df$basesef <- factor(df$basesef,levels = c(1,2,3),labels=c("≥0D","-1.75~0D","<=-1.75D"))
df$familyHistory <- factor(df$familyHistory,levels = c(1,2),labels = c("Yes","No"))
df$cluster <- factor(df$cluster,levels = c(0,3,2,1),labels = c("Very Low","Low","High","Very High"))
df$wearGlass <- factor(df$wearGlass,levels = c(1,2),labels = c("Yes","No"))
df <- data.frame(df)
df <- arrange(df,cluster,)

ggplot(data = df,
       aes(axis1 = basegrd, 
           axis2 = familyHistory, 
           axis3 = baseucva,
           axis4 = basesef,
           axis5 = wearGlass,
           axis6 = cluster,
           y = prop)) +
  scale_x_discrete(limits = c("Grade", "Family history", "UCVA","Baseline SE","Wear glassess","Cluster"), expand = c(.2, .05)) +
  geom_alluvium(aes(fill = prop)) +
  geom_stratum(width = 0.5) +
  geom_text(stat = "stratum", aes(label = after_stat(stratum))) +
  scale_fill_gradient(low="#00A1D5",high = "#B34745",name="Probablity")+
  ylab(NULL)+
  theme_classic()+
  theme(axis.ticks = element_blank(),
        axis.line = element_blank(),
        axis.text.y.left = element_blank(),
        legend.position = c(0.94,0.5),
        axis.text.x.bottom = element_text(size=15)
        )
ggsave("./Plots/sankey.jpeg",dpi=300)

?element_text
# Distribution

df2$cluster <- factor(df2$cluster,levels = c(0,1,2,3),labels = c("Low","Very high","Very low","High"))
df2$baseucva <- cut(df2$baseucva,breaks = c(-Inf,4,4.99,Inf),labels = c("≤4","4-5",">=5"))
df2$basesef <- factor(df2$basesef,levels = c(1,2,3),labels=c("≥0D","-1.75~0D","<=-1.75D"))
df2$familyHistory <- factor(df2$familyHistory,levels = c(1,2),labels=c("Yes","No"))

a <- ggplot(data = df2,aes(cluster,..count..,group=basegrd,fill=factor(basegrd)))+
  geom_bar(position="fill")+
  scale_x_discrete(limits=c("Very low","Low","High","Very high"))+
  scale_fill_manual(name="Baseline grade",values=c("#79AF97","#00A1D5","#6A6599","#DF8F44","#374E55","#B24745"))+
  ylab("Proportion")+
  theme_classic()+
  xlab(NULL)

b <- ggplot(data=df2,aes(x=cluster,y=..count..,group=baseucva,fill=baseucva))+
  geom_bar(position="fill")+
  scale_x_discrete(limits=c("Very low","Low","High","Very high"))+
  scale_fill_manual(name="Baseline UCVA",values=c("#B24745","#DF8F44","#79AF97"))+
  ylab("Proportion")+
  xlab(NULL)

c <- ggplot(data=df2,aes(x=cluster,y=..count..,group=basesef,fill=basesef))+
  geom_bar(position="fill")+
  scale_x_discrete(limits=c("Very low","Low","High","Very high"))+
  scale_fill_manual(name="Baseline SE",values=c("#B24745","#DF8F44","#79AF97"))+
  ylab("Proportion")+
  xlab(NULL)

d <- ggplot(data=df2,aes(x=cluster,y=..count..,group=familyHistory,fill=familyHistory))+
  geom_bar(position="fill")+
  scale_x_discrete(limits=c("Very low","Low","High","Very high"))+
  scale_fill_manual(name="Family History",values=c("#B24745","#79AF97"))+
  ylab("Proportion")+
  xlab(NULL)

a+b+c+d
ggsave("./Plots/distribution_by_cluster.jpeg",dpi=300)
