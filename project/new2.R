library(quantmod)
library(forecast)
library(xlsx)
library(tseries)
library(timeSeries)
library(dplyr)
library(fGarch)
library(xts)
library(readr)
library(moments)
library(rugarch)
library(prophet)
library(tsfknn)

wmt <- read.csv("WMT.csv")
wmt
View(wmt)
# Extracting stock data for walmart
getSymbols('wmt', from= '2011-01-01')
# Separating Closing Prices of stocks from data
wmt_close = wmt[,4]

# Plotting graph of walmart Stock Prices to observe the trend
plot(wmt_close)

# Plotting the ACF and PACF plot of data
par(mfrow=c(1,2))
Acf(wmt_close, main = 'ACF Plot')
Pacf(wmt_close, main = 'PACF Plot')

# Plotting Additive and Multiplicative Decomposition
wmt.ts <- ts(wmt_close, start=c(2010,1,1), frequency = 365.25)
wmt.add  <- decompose(wmt.ts,type = "additive")
plot(wmt.add)
wmt.mult <- decompose(wmt.ts,type = "multiplicative")
plot(wmt.mult)
# ADF test on Closing Prices 
print(adf.test(AMZN_CP))

# Splitting into test and train data 
N = length(wmt_close)
N
n = 0.7*N
n
train = wmt_close[1:n, ]
test  = wmt_close[(n+1):N,  ]
predlen=length(test)

# Taking log of dataset 
logs=diff(log(wmt_close), lag =1)
logs = logs[!is.na(logs)]

# Log returns plot
plot(logs, type='l', main= 'Log Returns Plot')

# ADF test on log of Closing Prices
print(adf.test(logs))

# ACF and PACF of log data 
Acf(logs, main = 'ACF of log data')
Pacf(logs, main = 'PACF of log data')
# Fitting the ARIMA model
# Auto ARIMA with seasonal = FALSE
fit1<-auto.arima(wmt_close, seasonal=FALSE)
tsdisplay(residuals(fit1), lag.max = 40, main='(1,1,1) Model Residuals')
fcast1<-forecast(fit1, h=30)
plot(fcast1)
accuracy(fcast1)

# Auto ARIMA with lambda = "auto"
fit2<-auto.arima(wmt_close, lambda = "auto")
tsdisplay(residuals(fit2), lag.max = 40, main='(2,1,2) Model Residuals')
fcast2<-forecast(fit2, h=30)
plot(fcast2)
accuracy(fcast2)

# ARIMA model with optimized p,d and q
fit3<-arima(wmt_close, order=c(8,2,8))
tsdisplay(residuals(fit3), lag.max = 40, main='(8,2,8) Model Residuals')
fcast3<-forecast(fit3, h=30)
plot(fcast3)
accuracy(fcast3)

# Histogram and Emperical Distribution
m=mean(logs);
s=sd(logs);
hist(logs, nclass=40, freq=FALSE, main='Closing Price Histogram');
curve(dnorm(x, mean=m,sd=s), from = -0.3, to = 0.2, add=TRUE, col="red")
plot(density(logs), main='Closing Price Empirical Distribution');
curve(dnorm(x, mean=m,sd=s), from = -0.3, to = 0.2, add=TRUE, col="red")

# Kurtosis
kurtosis(logs)

# Dataset forecast upper first 5 values
fitarfima = autoarfima(data = train, ar.max = 2, ma.max = 2, 
                       criterion = "AIC", method = "full")
fitarfima
# Prophet
df <- data.frame(ds = index(wmt),
                 y = as.numeric(wmt[,'wmt_Close']))
prophetpred <- prophet(df)
future <- make_future_dataframe(prophetpred, periods = 30)
forecastprophet <- predict(prophetpred, future)
plot(
  prophetpred,
  forecastprophet,
  uncertainty = TRUE,
  plot_cap = TRUE,
  xlabel = "ds",
  ylabel = "y"
)
dataprediction <- data.frame(forecastprophet$ds,forecastprophet$yhat)
trainlen <- length(wmt_close)
dataprediction <- dataprediction[c(1:trainlen),]
prophet_plot_components(prophetpred,forecastprophet)

# K Nearest Neighbours
df <- data.frame(ds = index(wmt),
                 y = as.numeric(wmt[,'wmt_Close']))

predknn <- knn_forecasting(df$y, h = 30, lags = 1:30, k = 40, msas = "MIMO")
ro <- rolling_origin(predknn)
print(ro$global_accu)
plot(predknn, type="c")

# Neural Networks
# Hidden layers creation
alpha <- 1.5^(-10)
hn <- length(wmt_close)/(alpha*(length(wmt_close)+30))
lambda <- BoxCox.lambda(wmt_close)
dnn_pred <- nnetar(wmt_close, size= hn, lambda = lambda)
dnn_forecast <- forecast(dnn_pred, h= 30, PI = TRUE)
plot(dnn_forecast)
accuracy(dnn_forecast)

# ETS
library(readr)
library(tidyverse)
library(ggplot2)
library(scales)
library(forecast)
wmt <- read_csv("WMT.csv")

glimpse(wmt)
head(wmt)
tail(wmt)

# Let the package automatically select the model base on AIC and BIC
auto.wmt.aic = ets(wmt$Close,model="ZZZ",ic="aic") 
auto.wmt.aic$method

auto.wmt.bic = ets(wmt$Close,model="ZZZ",ic="bic") 
auto.wmt.bic$method

auto.wmt.aic.damped = ets(wmt$Close,model="ZZZ",damped = TRUE, ic="aic") #
auto.wmt.aic.damped$method

auto.wmt.bic.damped = ets(wmt$Close,model="ZZZ",damped = TRUE, ic="bic") #
auto.wmt.bic.damped$method

# The model selected by the package was MNN, MAN and MAdN
# Package autoselection
auto.wmt = ets(wmt$Close, model = "ZZZ")
auto.wmt$method

# Applying model, MNN, MAN and MAdN
wmt.MNN = ets(wmt$Close, model = "MNN")
summary(wmt.MNN)

wmt.MAN = ets(wmt$Close, model = "MAN")
summary(amzn.MAN)

wmt.MAdN = ets(wmt$Close, model = "MAN", damped = TRUE)
summary(wmt.MAdN)

# Although the MASE of the series is simillar. 
# But, the smallest MASE can be observed in the MAN series. 
# This suggested that MAN model is better model. 
# However, due to similarity of the MASE values, it was suspected that residuals will show similar result.

# Model diagnostic
checkresiduals(wmt.MNN)
checkresiduals(wmt.MAN)
checkresiduals(wmt.MAdN)

# Plot the forecast for 90 days
forecast.MNN = forecast(wmt.MNN, h = 30)
forecast.MAN = forecast(wmt.MAN, h = 30)
forecast.MAdN = forecast(wmt.MAdN, h = 30)

plot(forecast.MAN, ylab = "Closing stock", type = "l", fcol = "green", xlab = "Series")
plot(forecast.MNN, ylab = "Closing stock", type = "l", fcol = "red", xlab = "Series")
plot(forecast.MAdN, ylab = "Closing stock", type = "l", fcol = "blue", xlab = "Series")

accuracy(forecast.MNN)
accuracy(forecast.MAdN)
accuracy(forecast.MAN) 
