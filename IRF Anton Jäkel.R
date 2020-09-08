#Impulse Response with CoinGecko Data

# Load package
library(vars)
library(car)
library(tidyverse)
library(dplyr)
library(xts)
library(lubridate)
library(tseries)

setwd("C:/Users/Anton/OneDrive/Antons-Dokumente/Bachelor Arbeit/R wd Abgabe")

#####Read Data#####
pow_data <- read.csv("Data/pow.csv", header = TRUE, dec = ".", fill = TRUE)
pos_data <- read.csv("Data/pos.csv", header = TRUE, dec = ".", fill = TRUE)
crix_data <- read.table("Data/crix.txt", header = TRUE, dec = ".", fill = TRUE)

pow_table <- read.csv("Data/pow.csv", header = TRUE, dec = ".", fill = TRUE)
pos_table<- read.csv("Data/pos.csv", header = TRUE, dec = ".", fill = TRUE)
crix_table <- read.table("Data/crix.txt", header = TRUE, dec = ".", fill = TRUE)

#####Check if equal#####
for(i in 1:1824){
  if(as.Date(crix_data$timestamps[i], tryFormats = c("%d.%m.%Y"))!=as.Date(pow_data$timestamps[i], tryFormats = c("%Y.%m.%d"))){
    print(as.Date(pow_data$timestamps[i], tryFormats = c("%Y.%m.%d")))
    print(as.Date(crix_data$timestamps[i], tryFormats = c("%d.%m.%Y")))
    print(i)
    break
  }
}

for(i in 1:length(1824)){
  if(as.Date(crix_data$timestamps[i], tryFormats = c("%d.%m.%Y"))!=as.Date(pos_data$timestamps[i], tryFormats = c("%Y.%m.%d"))){
    print(as.Date(pos_data$timestamps[i], tryFormats = c("%Y.%m.%d")))
    print(as.Date(crix_data$timestamps[i], tryFormats = c("%d.%m.%Y")))
    print(i)
    break
  }
}

#####Find bigest difference#####
data2 = pow_data
data2[is.na(data2)] = 0
diffData2 = diff(as.matrix(data2), lag = 1)
diffData2[diff(is.na(data))==0 & is.na(data[-1])] = NA

#####Create Index#####

#remove closing prices and timestamps
crix <- subset(crix_data, select = -c(timestamps))

toDelete_pow <- seq(3, ncol(pow_data), 2)
toDelete_pos <- seq(3, ncol(pos_data), 2)
pow_data <- pow_data[,toDelete_pow]
pos_data <- pos_data[,toDelete_pos]

pow_data <- subset(pow_data, select = -c(market_caps_bitcoin,market_caps_ethereum,market_caps_bitcoin.cash,market_caps_bitcoin.cash.sv,market_caps_litecoin))
pos_data <- subset(pos_data, select = -c(market_caps_cardano,market_caps_binancecoin,market_caps_stellar))

length(pow_data[1,])
length(pos_data[1,])

colnames(pow_data)
colnames(pos_data)

pow_row_sum <- rowSums(pow_data[1,],na.rm = TRUE)
pos_row_sum <- rowSums(pos_data[1,],na.rm = TRUE)

#Divisor so wählen, dass der Ausgangskurs des Indexes dem vom CRIX entspricht
divisor_pow = pow_row_sum/(crix_data$CRIX[1])
divisor_pos = pos_row_sum/(crix_data$CRIX[1])

pow_sum <- rowSums(pow_data, na.rm = TRUE)
pos_sum <- rowSums(pos_data, na.rm = TRUE)

pow <- pow_sum/divisor_pow
pow <- data.frame(pow)

pos <- pos_sum/divisor_pos
pos <- data.frame(pos)


#####Create Timeseries#####

#Check for same length and start
lengths(pow)
lengths(pos)
lengths(crix)
pow[1,1]
pos[1,1]
crix[1,1]

pow.ts <- ts(pow, start = c(2015,8,1), deltat = 1/365)
pos.ts <- ts(pos, start = c(2015,8,1), deltat = 1/365)
crix.ts <- ts(crix, start = c(2015,8,1), deltat = 1/365)

# Um die Zeitreihen weiter analysieren zu können, müssen diese stationär sein, also E[x] und Var[x] konstant und keine Saisonalität
# Alleine durch Betrachten der Plots erkennt man, dass diese nicht stationär sind:

plot(pow.ts,xlab = "Zeit", ylab = "USD", main = "PoW Index" )
plot(pos.ts,xlab = "Zeit", ylab = "USD", main = "PoS Index" )
plot(crix.ts,xlab = "Zeit", ylab = "USD", main = "CRIX Index" )

#Determine the Persistence
acf(pow.ts, main = "ACF for POW")
acf(pos.ts, main = "ACF for POS")
acf(crix.ts, main = "ACF for CRIX")

pacf(pow.ts, main = "PACF for PoW Index")
pacf(pos.ts, main = "PACF for PoS Index")
pacf(crix.ts, main = "PACF for CRIX")

# Der ADF-Test (Dickey-Fuller-Test) und der KPSS-Test (Kwiatkowski-Phillips-Schmidt-Shin-Test) bestätigen dies:
# ADF: p-value < 0.05 indicates the TS is stationary
# KPSS: p-value > 0.05 indicates the TS is stationary
adf.test(pow.ts)
kpss.test(pow.ts)

adf.test(pos.ts)
kpss.test(pos.ts)

adf.test(crix.ts) 
kpss.test(crix.ts) 

# log und Differenz anwenden, um stationär zu machen
pow.ts.s <- diff(log(pow.ts))
pos.ts.s <- diff(log(pos.ts))
crix.ts.s <- diff(log(crix.ts))

# Anhand der plots kann man nun stationarity vermuten
plot(pow.ts.s)
plot(pos.ts.s)
plot(crix.ts.s)

#Liegt nach ADF und KPSS auch stationarity vor?
adf.test(pow.ts.s) # p-value < 0.05 indicates the TS is stationary
kpss.test(pow.ts.s) # p-value > 0.05 indicates the TS is stationary

adf.test(pos.ts.s)
kpss.test(pos.ts.s)

adf.test(crix.ts.s)
kpss.test(crix.ts.s)

#Stationäre Matrix für VAR, WICHTIG: Ordering, wegen Decomposition of the variance-covariance of the VAR-Model, Annahme: CRIX hat Einfluss auf POW, und nicht umgekehrt, daher CRIX an erster Stelle 

#PoW
crix_pow <- cbind(crix,pow)
crix_pow

crix_pow.ts <- ts(crix_pow, start = c(2015,8), deltat = 1/365)
plot(crix_pow.ts)

crix_pow.ts.s <- diff(log(crix_pow.ts))
plot(crix_pow.ts.s)

#PoS
crix_pos <- cbind(crix,pos)
crix_pos

crix_pos.ts <- ts(crix_pos, start = c(2015,8), deltat = 1/365)
plot(crix_pos.ts)

crix_pos.ts.s <- diff(log(crix_pos.ts))
plot(crix_pos.ts.s)

#####VAR-Modell#####

#Ordnung p anhand von min[Informationskriterien] bestimmen, um System schätzen zu können
pow_lag.p<-VARselect(crix_pow.ts.s, lag.max = 100, type = "none", season = NULL, exogen = NULL)
pow_lag.p$selection

pos_lag.p<-VARselect(crix_pos.ts.s, lag.max = 100, type = "none", season = NULL, exogen = NULL)
pos_lag.p$selection

#PoW
crix_pow.ts.s.model <- VAR(crix_pow.ts.s, p = pow_lag.p$selection[3], type = "none")
# Man kann für type noch const und trend wählen, da allerdings kein Aufwärts- oder Abwärtstrend vorhanden ist und btc.ts.s von 0 aus geht, habe ich beide weggelassen
plot(crix_pow.ts.s.model)
crix_pow.ts.s.model_summary <- summary(crix_pow.ts.s.model)
crix_pow.ts.s.model_summary

#PoS
crix_pos.ts.s.model <- VAR(crix_pos.ts.s, p = pos_lag.p$selection[3], type = "none")
plot(crix_pos.ts.s.model)
crix_pos.ts.s.model_summary <- summary(crix_pos.ts.s.model)
crix_pos.ts.s.model_summary

#####Diagnosis#####

#erstmal nicht beachten, muss noch auf Relevanz geprüft werden

# Serial Crrelation -> if p-value>0.05 then there is no serial correlation
serial <- serial.test(all.ts.s.model, lags.pt = 12, type = "PT.asymptotic")
serial

# Heteroskedastizität -> if p-value>0.05 then there is no heteroskedasticity
arch <- arch.test(all.ts.s.model,lags.multi = 12, multivariate.only = TRUE)
arch

# Normal Distribution of the Residuals -> if p-value>0.05 then normal distribution
normal <- normality.test(all.ts.s.model, multivariate.only = TRUE)
normal

# Testing for Structural Breaks in Residuals

stability <- stability(all.ts.s.model, type = "OLS-CUSUM")
stability
plot(stability$stability$crix)

# Obtain variance-covariance matrix
all.ts.s.model_summary$covres

# Obtain correlation matrix
all.ts.s.model_summary$corres

# Decompose the variance-covariance matrix to a lower triangular matrix with positve diagonal elements
t(chol(all.ts.s.model_summary$covres))

#Diesen Schritt kann man mit der irf Funktion automatisch machen, indem man ortho=TRUE setzt

#####Orthogonal Impulse Response#####
#PoW
pow.oir <- irf(crix_pow.ts.s.model, n.ahead = 8, ortho = TRUE, runs = 1000, seed = 12345)
plot(pow.oir)
summary(pow.oir)
pow.oir$irf

#PoS
pos.oir <- irf(crix_pos.ts.s.model, n.ahead = 8, ortho = TRUE, runs = 1000, seed = 12345)
plot(pos.oir)
summary(pos.oir)
pos.oir$irf
