# Capelin and Cod Abundance in Barents Sea in 2013

# Data are from acoustic surveys by IMR
# Here, using only 2013 data for Spatial Stats course and testing it all out
######################################################################

##########
# Setup
##########
# Working directory
setwd("/Users/janellemorano/Git/Reference-R-scripts/Spatial-Stats/Cod-Capelin-Project")

# Libraries
library(sp)
library(rgdal)
library(gstat)
library(geoR)
library(RColorBrewer)
library(classInt)

#All of the data from 2007-2013
data = read.csv("AllData.csv", head = TRUE)
head(data)
dim(data)
#123056     22

#make each year a unique number for reference
iyear = unique(data$year)
#assign the lat and lon
data$Xloc = jitter(data$lon)
data$Yloc = jitter(data$lat)
coordinates(data)=c("Xloc","Yloc")

#Make a dataset for just 2013 to simply things.
#######
yy = 2013
datai = data[data$year==yy,]
dim(datai)
#15571    22

##############################
# Plot: Visualize Survey Data
##############################
# Projection: NEEDS FIXING

# proj4string(data) <- NA_character_ # remove CRS information from lnd
# proj4string(data) <- CRS("+init=epsg:27700") # assign a new CRS
# EPSG <- make_EPSG() # create data frame of available EPSG codes
# EPSG[grepl("WGS 84$", EPSG$note), ]
# lnd84 <- spTransform(data, CRS("+init=epsg:4326")) # reproject
# saveRDS(object = lnd84, file = "data/lnd84.Rds")

# make the UTM cols spatial (X/Easting/lon, Y/Northing/lat)
# use sf package
# library(sf)
# data.SP <- st_as_sf(data, coords = c("Xloc","Yloc"), crs = 4326)
# ## Plot survey locations
# plot(lat~lon,data=data.SP)
# Projection doesn't look different

## Plot survey locations
plot(lat~lon,data=datai)

# Read in boundary layers
library(rgdal)
setwd("/Users/janellemorano/Git/Reference-R-scripts/Spatial-Stats/Cod-Capelin-Project/Barents Sea Shp")

## Read in boundary layers
ogrInfo(dsn=".",layer="iho")
barents = readOGR(dsn=".",layer="iho")

# proj4string the slot which contains the projection information
proj4string(data)
#[1] NA
plot(barents,add=T,lwd=2)

setwd("/Users/janellemorano/Git/Reference-R-scripts/Spatial-Stats/Cod-Capelin-Project")

# Plot capelin and cod relative densities, separately
#####
## Plot relative capelin densities for 2013
# Set colors
pal = brewer.pal(5,"Blues")
q5 = classIntervals(datai$capelin, n=5, style="quantile")
q5Colors = findColours(q5,pal)

# Plot
plot(c(min(datai$Xloc),max(datai$Xloc)),
     c(min(datai$Yloc),max(datai$Yloc)),
     xlab="Longitude",ylab="Latitude",type="n")
points(datai,col=q5Colors,pch=1,add=T, cex = 2*(datai$capelin/max(datai$capelin)))
legend("bottomright",fill=attr(q5Colors,"palette"),	legend = names(attr(q5Colors,"table")),bty="n")
title(paste("Capelin Abundance",yy))

## Plot relative cod densities for 2013
# Set colors
pal2 = brewer.pal(5,"Oranges")
q52 = classIntervals(datai$cod, n=5, style="quantile")
q5Colors2 = findColours(q52,pal2)
plot(c(min(datai$Xloc),max(datai$Xloc)),
     c(min(datai$Yloc),max(datai$Yloc)),
     xlab="Longitude",ylab="Latitude",type="n")
#plot(datai,col=q5Colors2,pch=19,add=T)
points(datai,col=q5Colors2,pch=1,add=T, cex = 2*(datai$cod/max(datai$cod)))
legend("bottomright",fill=attr(q5Colors2,"palette"), legend = names(attr(q5Colors2,"table")),bty="n")
title(paste("Cod Abundance",yy))

#####
## Plot relative capelin & cod (TOGETHER) densities for 2013
#####
# And makes the color intervals the same

# Capelin
capelin.pal = brewer.pal(5,"Blues")
capelin.q5 = classIntervals(datai$capelin, n=5, style="quantile")
capelin.q5Colors = findColours(capelin.q5,capelin.pal)

# Cod
cod.pal = brewer.pal(5,"Oranges")
cod.q5 = classIntervals(datai$capelin, n=5, style="quantile") #relative to capelin
cod.q5Colors = findColours(cod.q5,cod.pal)

plot(c(min(datai$Xloc),max(datai$Xloc)),
     c(min(datai$Yloc),max(datai$Yloc)),
     xlab="Longitude",ylab="Latitude",type="n")
points(datai,col=capelin.q5Colors,pch=1, cex = 2*(datai$capelin/max(datai$capelin))) 
# Add cod on top, but then the legend and title need to be fixed
points(datai,col=cod.q5Colors,pch=1, cex = 2*(datai$cod/max(datai$cod)))
legend("topright",fill=attr(capelin.q5Colors,"palette"),	legend = names(attr(capelin.q5Colors,"table")),bty="n")
legend("bottomright",fill=attr(cod.q5Colors,"palette"),	legend = names(attr(cod.q5Colors,"table")),bty="n")
title(paste("Capelin (blue) and Cod (orange) Abundance",yy))

# Histogram of data
hist(datai$capelin)
# Log of capelin
datai$logcapelin = log(datai$capelin)
hist(datai$logcapelin)
summary(datai$logcapelin)
# Add 1
datai$capelin1 = (datai$capelin) + 1
summary(datai$capelin1)
# Log of (capelin + 1)
datai$logcapelin1 = log(datai$capelin1)
summary(datai$logcapelin1)
hist(datai$logcapelin1)


hist(datai$cod)

#######################
# Capelin: Empirical Variogram
########################

# Calculate the empirical variogram for Capelin
capelin.vario = variogram(log(capelin+1)~1,datai,cutoff=20)
#
# Plot the empirical variogram
plot(gamma~dist,capelin.vario,
     ylim=c(0,max(gamma)),type='n',
     xlab="Distance",ylab="Semivariance",
     main=paste("Capelin Variogram",yy))
points(gamma~dist,capelin.vario,cex=2*np/max(np),pch=16,col="lightblue")


#######################
# Capelin: Fit Model By-Eye
########################

my.range = 8.8
my.nugget = 0.8
my.psill = 5.2-my.nugget
#
capelin.eye = vgm(model="Sph",psill=my.psill,range=my.range,nugget=my.nugget)
plot(gamma~dist,capelin.vario,
     ylim=c(0,max(gamma)),type='n',
     xlab="Distance",ylab="Semivariance",
     main=paste("Capelin Variogram By-Eye",yy))
points(gamma~dist,capelin.vario,cex=2*np/max(np),pch=16,col="lightblue")
vgmline = variogramLine(capelin.eye,max(capelin.vario$dist))
lines(gamma~dist,vgmline,lwd=2)

#######################
# Capelin: Fit Actual Model
########################
capelin.fit=fit.variogram(capelin.vario,
                          vgm(model="Sph",psill=my.psill,range=my.range,nugget=my.nugget),
                          fit.method=1)

# Look at estimates
capelin.fit
capelin.psill=capelin.fit$psill[2]
capelin.range=capelin.fit$range[2]
capelin.nugget=capelin.fit$psill[1]

# Plot the data, model and parameter estimates
#####
plot(gamma~dist,capelin.vario,
     ylim=c(0,max(gamma)),type='n',
     xlab="Distance",ylab="Semivariance",
     main=paste("Capelin Variogram Fit",yy))
points(gamma~dist,capelin.vario,cex=2*np/max(np),pch=16,col="lightblue")
vgmline = variogramLine(capelin.fit,max(capelin.vario$dist))
lines(gamma~dist,vgmline,lwd=2)
#
legend("bottomright",legend = c(
  paste("Psill  =",round(capelin.psill,2)),
  paste("Range  =",round(capelin.range,2)),
  paste("Nugget = ",round(capelin.nugget,2))),
  bty="n")

#######################
# Capelin: Predict: Kriging
########################

# Given the fitted model, let's make some predictions about the data.

# Create a grid of points to predict over
capelin.grid = expand.grid(
  Xloc=seq(min(datai$Xloc),max(datai$Xloc),length=40),
  Yloc=seq(min(datai$Yloc),max(datai$Yloc),length=40))
names(capelin.grid)=c("Xloc","Yloc")
coordinates(capelin.grid)=c("Xloc","Yloc")
capelin.grid = as(capelin.grid, "SpatialPixels")

# Now plot the data and overlay the prediction grid
plot(Yloc~Xloc,capelin.grid,cex=1.2,pch='+',col="green")
points(Yloc~Xloc,datai,pch=".")	

# Predict the value at all the points in the domain
date()	
capelin.ok = krige(log(capelin+1)~1, datai, capelin.grid, m=capelin.fit)	
date()
#With length=40 grid, takes ~19 mins to run

# Plot the prediction
plot(barents)
image(capelin.ok["var1.pred"],col=rev(heat.colors(4)),add=T)
#contour(capelin.ok["var1.pred"],add=T)
title(paste("Predicted Log(Capelin+1)",yy))
legend("bottomright",legend=c(0,1,2,3),fill=rev(heat.colors(4)),
       bty="n",title="log(Capelin+1)")
plot(barents,add=T)
summary(capelin.ok["var1.pred"])


###
bubble(datai, "capelin", col=c("#00ff0088", "#00ff0088"), main = "capelin")
