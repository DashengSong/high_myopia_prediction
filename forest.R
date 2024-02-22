##############################
# Plot forest
##############################

library(forestploter)
library(grid)
# Home
# Import Data
df <- haven::read_sas("./Data/est_exp.sas7bdat")

# Clean
df2 <- df[,c("variables","level1","pvalue","irrc","lu")]
#plotds <- df[,c(1,2,8,6,7)]
df2$` ` <- paste(rep(" ",40),collapse = " ")
names(df2)[1] <- "Features"
names(df2)[2] <- " "
names(df2)[3] <- "P"
names(df2)[4] <- "IRR"
names(df2)[5] <- "95%CI"

p <- forest(
  df2,
  est = df$irr,
  lower = df$irr_l,
  upper = df$irr_u,
  ci_column = 6,
  ref_line = 1,
  arrow_lab = c("Not Devloped","Devloped")
)
p
p <- edit_plot(p,
               col = 1,
               gp=gpar(fontface="bold")
               )
p <- edit_plot(p,
               col = c(1,2,3,4,5),
               gp=gpar(cex=0.8)
)

p <- add_border(p,row=1,part = "header",where="bottom")

jpeg(filename = "./Plots/forestplot.jpg",width = 2750,height = 1500,res=300)
p
dev.off()
