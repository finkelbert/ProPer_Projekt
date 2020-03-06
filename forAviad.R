require(ggplot2)
require(magrittr)
require(purrr)
library(reshape)
library(zoo)
require(tuneR)
library(seewave)



#' Print values while maintaining a pipeline.
#'
#' @param .x value
#' @param f a function from values \code{.x} to something printable
#' @return the passed \code{.x} value
#' The function \code{Pr} prints the single argument value, then returns it,
#' passing it on down the pipeline. The function \code{Prf} extends this by
#' applying the argument function to the value before printing it. The final
#' function \code{Prl} prints the length of the argument value
#' @examples
#' 2020 %>% Pr() %>% (function(.x) { 2.5 * .x }) ## prints 2020, then 5050
#' (1:100) %>% Prf(sum) %>% length() ## prints 5050 (sum of 1 to 100) then 100
#' (1:100) %>% Prl() %>% sum() ## prints 100 then 5050
#' @export
# =======================================================
# Two functions handy for debugging pipelines
# =======================================================
Pr <- function(.x) { print(.x); .x }
Prf <- function(.x,f) { print(f(.x)); .x }
Prl <- function(.x) Prf(.x,length)

#' Append a number of identical values to a vector
#'
#' @param v a vector
#' @param n the number of values to be appended to \code{v}. If this number
#' is less than zero, then that \code{-n} values are prepended
#' @param zero is the value to be repeatedly appended
#' @return the passed \code{v} with \code{n} copies of \code{zero} appended or
#' \code{-n} copies of \code{zero} prepended (if \code{n < 0})
#' @examples
#' (1:10) %>% append(3,0) %>% Pr() %>% length() ## prints 1..10,0,0,0 then 13
#' (1:10) %>% append(-3,0) %>% Pr() %>% length() ## prints 0,0,0,1..10 then 13
#' (1:10) %>% append(0,0) %>% Pr() %>% length() ## prints 1..10 then 10
#' @export
# =======================================================
# append(vector,n,value)
# a. if n positive, append n copies of value after the vector
# a. if n negative, prepend -n copies of value to start of vector
# =======================================================
ncopies <- function(n,zero) rep( zero, ifelse(n > 0,n,0) )
append <- function(v,n,zero) c( ncopies(-n,zero), v, ncopies(n, zero) )
test.append <- function() {
  print( append( (10:20), -5, 0 ) )
  print( append( (10:20),  5, 0 ) )
}

#' Align two copies of a vector slipped n positions in opposite directions
#' then combine these pairwise using a function
#'
#' @param v a vector
#' @param n the number of positions to slip each vector
#' @param op the function to combine paired items
#' @param zero is the default value to pad copies of the vector
#' with to complete partial matches in the alignment
#' @return if \code{u} is defined over integers to equal \code{v}, or \code{zero}
#' if \code{v} is undefined, then \code{slip} returns
#' \code{f(u[(1:l)-n],u[(1:l)+n])} where \code{l} is \code{length(v)}
#' @examples
#' ## In this example, there is no slippage, so all five elements are in the overlap
#' rep(1,5) %>% slip(0,`*`,0) ## prints 1,1,1,1,1
#' ## In the next example, there are only 4 items in the overlap, 2 non-overlapping
#' rep(1,5) %>% slip(1,`*`,0) ## prints 0,1,1,1,1,0
#' ## In the next example, there are only 3 items in the overlap, 4 non-overlapping
#' rep(1,5) %>% slip(2,`*`,0) ## prints 0,0,1,1,1,0,0
#' ## In the next example, we have alternating 1,0 sequence
#' ## and we look at a binary autocorrelation: slippage 1 or 2 :-)
#' rep(c(1,0),5) %>% slip(0,`*`,0) ## prints c(1,0) * 5
#' rep(c(1,0),5) %>% slip(1,`*`,0) ## prints rep(0,11)
#' rep(c(1,0),5) %>% slip(2,`*`,0) ## prints 0,0,rep(c(1,0),4),0,0
#' @export
# =======================================================
# slip(v,n,operation,zero)
# a. append -n zeroes to v, making v1
# b. append n zeroes to v, making v2
# c. apply operation with v1 and v2 as arguments
# =======================================================
slip <- function(v,n,op,zero) op(append(v,-n,zero), append(v,n,zero))
test.slip <- function() {
  for (i in (0:5)) {
    print( slip( (1:20), i, function(a,b) a+b, 0 ) )
  }
}

#' Extract the middle subvector of a given length from a vector
#'
#' @param v a vector
#' @param n the length of the middle subvector to extract
#' @return returns the middle \code{n} values from \code{v} as a vector
#' @examples
#' ## In this example, there is no slippage, so all five elements are in the overlap
#' c((1:10),(10:1)) %>% middle(10) ## prints 6,7,8,9,10,10,9,8,7,6
#' @export
# =======================================================
# middle(v,n)
# return
#   if n < length(v): the middle n values from a vector v
#   else: the vector v
# =======================================================
range <- function(i,n) ((i+1):(i+n))
middle <- function(v,n) {
  v %>% length() -> l
  if (n >= l) return( v )
  ((l-n)/2) %>%
    floor() %>%
    range(n) %>%
    (function(sp) { v[sp] })
}
test.middle <- function() {
  for (i in (15:22)) {
    print( paste( "test.middle", i,"/", 20, ":", paste(middle( 1:20, i ), collapse=" ") ) )
  }
}

#' Slip two copies of a vector by a displacement in opposite directions,
#' then extract the middle region of the same length as the original vector
#'
#' @param v a vector
#' @param n the length of the middle subvector to extract
#' @param op the function to combine paired items
#' @param zero is the default value to pad copies of the vector
#' with to complete partial matches in the alignment
#' @return returns the middle $|v|$ values from the slip defined by the four
#' arguments
#' @examples
#' ## In this example, there is no slippage, so all five elements are in the overlap
#' rep(1,5) %>% slipCentre(0,`*`,0) ## prints 1,1,1,1,1
#' ## In the next example, there are only 4 items in the overlap, 2 non-overlapping
#' rep(1,5) %>% slipCentre(1,`*`,0) ## prints 0,1,1,1,1
#' ## In the next example, there are only 3 items in the overlap, 4 non-overlapping
#' rep(1,5) %>% slipCentre(2,`*`,0) ## prints 0,1,1,1,0
#' ## In the next example, we have alternating 1,0 sequence
#' ## and we look at a binary autocorrelation: slippage 1 or 2 :-)
#' rep(c(1,0),5) %>% slipCentre(0,`*`,0) ## prints c(1,0) * 5
#' rep(c(1,0),5) %>% slipCentre(1,`*`,0) ## prints rep(0,10)
#' rep(c(1,0),5) %>% slipCentre(2,`*`,0) ## prints 0,rep(c(1,0),4),0
#' @export
# =======================================================
# slipWindow(v,n,operation,zero)
# a. add a window of width 2^n around each point
# b. expand v to cater for all potential non-zero windows
# =======================================================
slipCentre <- function(v,n,op,zero) {
  v %>% length() -> l
  v %>% slip(n,op,zero) %>% middle(l)
}
test.slipCentre <- function() {
  for (i in (0:4)) {
    print( paste( "test.slipCentre", i, "/", 20, ":", paste( slipCentre( (1:20), i, function(a,b) a+b, 0 ), collapse=" " ) ) )
  }
}

# =======================================================
# sumWindow(v,n)
# a. add a window of width 2^n around each point
# b. expand v to cater for all potential non-zero windows
# =======================================================
sumWindow <- function(v,log2windowsize) {
  if (log2windowsize < 1) return( v )
  v %>%
    sumWindow(log2windowsize-1) %>%
    slip((2 ** (log2windowsize-1)),function(a,b) a+b, 0)
}
test.sumWindow <- function() {
  for (i in (0:4)) {
    print( paste( "test.slipCentre", i, "/", 20, ":", paste( sumWindow( rep(1,20), i ), collapse=" " ) ) )
  }
}

# =======================================================
# sumWindow(v,n)
# a. add a window of width 2^n around each point
# b. expand v to cater for all potential non-zero windows
# =======================================================
sumWindowCentre <- function(v,log2windowsize) {
  v %>% length() -> l
  v %>% sumWindow(log2windowsize) %>% middle(l)
}
test.sumWindowCentre <- function() {
  for (i in (0:4)) {
    print( paste( "test.slipCentre", i, "/", 20, ":", paste( sumWindowCentre( rep(1,20), i ), collapse=" " ) ) )
  }
}


# =======================================================
# sumWindowScaleCentre(v,n)
# a. add a window of width 2^n around each point
# b. expand v to cater for all potential non-zero windows
# =======================================================
sumWindowScaleCentre <- function(v,log2windowsize, l) {
  rep(1,l) %>% sumWindow(log2windowsize) %>% middle(l) -> scaling
  v %>% sumWindow(log2windowsize) %>% middle(l) -> datum
  ## print( paste( length( scaling ), length( datum ) ) )
  datum %>%
    (function(v) v / scaling)
}
test.sumWindowScaleCentre <- function() {
  for (i in (0:4)) {
    print( paste( "test.slipCentre", i, "/", 20, ":", paste( sumWindowScaleCentre( sin((1:20)*10), i, 20 ), collapse=" " ) ) )
  }
}

# =======================================================
# autocorrelateTau(v,tau,log2delta)
# a. for a given
# b. expand v to cater for all potential non-zero windows
# =======================================================
autocorrelateTau <- function(v,tau,log2delta) {
  v %>% length() -> l
  v %>%
    slip(tau,function(a,b) a*b, 0) %>%
    sumWindowScaleCentre(log2delta,l)
}
test.autocorrelateTau <- function() {
  a <- sin( (1:500)*2*pi/23.0 )
  for (i in 0:50) {
    print( paste("test.autocorrelateTau",i,"/",20,sum( autocorrelateTau(a,i,5) ) ))
  }
}

# =======================================================
# scaleByMax(v)
# =======================================================
scaleByMax <- function(v) v / max(abs(v))

# =======================================================
# autocorrelate(v,taus,log2delta)
# a. for a given
# b. expand v to cater for all potential non-zero windows
# =======================================================
autocorrelate <- function(v,taus,log2delta) {
  ac <- function(tau) autocorrelateTau(v,tau,log2delta)
  taus %>% map(ac) %>% unlist() %>% matrix(ncol=length(taus))
}
test.autocorrelate <- function() {
  a1 <- sin( (1:500)*2*pi/23.0 )
  ac1 <- autocorrelate(a1,(0:100),7)
  a2 <- 2 * (runif(500) - 0.5)
  ac2 <- autocorrelate(a2,(0:100),7)
  print( paste("test.autocorrelate","(1:500)","/",20, ac1 ))
  df1 <- data.frame(x=(1:dim(ac1)[2]),y=ac1[250,],z="sine")
  df2 <- data.frame(x=(1:dim(ac2)[2]),y=ac2[250,],z="runif")
  df <- rbind(df1,df2)
  g <- ggplot(data=df) +
    geom_line(aes(x=x,y=y,colour=z)) +
    theme_bw()
  plot( g )
}

# =======================================================
# autocorrelateAvPowerSinusoid(v,taus,log2delta)
# a. for a given
# b. expand v to cater for all potential non-zero windows
# =======================================================
meanSinusoidPower <- function(v) {
  l <- length(v); i1 <- (1:(l-1)); i2 <- i1+1
  power <- abs(v[1]) ** 2; powers <- c()
  diffSign <- (sign(v[i2]) != sign(v[i1]))
  for (i in (i1)) {
    if (diffSign[i]) { powers <- c(powers, power); power <- 0.0 }
    power <- power + abs(v[i]) ** 2
  }
  powers <- c(powers, power)
  mean( powers )
}
autocorrelateMeanSinusoidPower <- function(ac) {
  ac %>% apply(1,meanSinusoidPower) %>% unlist()
}
test.autocorrelateMeanSinusoidPower <- function() {
  sin( (1:500)*2*pi/23.0 ) %>%
    autocorrelate((0:100),7) %>%
    autocorrelateMeanSinusoidPower() %>%
    print()
  (2 * (runif(500) - 0.5)) %>%
    autocorrelate((0:100),7) %>%
    autocorrelateMeanSinusoidPower() %>%
    print()
}



# =======================================================
# autocorrelatePower(v,taus,log2delta)
# a. for a given
# b. expand v to cater for all potential non-zero windows
# =======================================================
differenceScale <- function(v) {
  l1 <- floor(length(v)/2)
  v1 <- v[1:l1]; v2 <- v[l1+(1:(length(v)-l1))]
  sum(v1*v2) / sqrt(sum(v1*v1) * sum(v2*v2))
}
autocorrelateFisher <- function(acm) {
  acml <- rbind(acm[1,],acm)
  acmr <- rbind(acm,acm[dim(acm)[1],])
  acm <- cbind(acml,acmr)
  print( dim(acm) )
  acm %>%
    apply(1,differenceScale)
}
test.autocorrelateFisher <- function() {
  a1 <- sin( (1:500)*2*pi/23.0 )
  ace1 <- autocorrelate(a1,(0:100),5) %>% autocorrelateFisher()

  a2 <- 2 * (runif(500) - 0.5)
  ace2 <- autocorrelate(a2,(0:100),5) %>% autocorrelateFisher()

  df1 <- data.frame(x=(1:length(ace1)),y=ace1,z="sine")
  df2 <- data.frame(x=(1:length(ace2)),y=ace2,z="runif")
  df <- rbind(df1,df2)
  g <- ggplot(data=df) +
    geom_line(aes(x=x,y=y,colour=z)) +
    theme_bw()
  plot( g )
}


# =======================================================
# autocorrelatePower(v,taus,log2delta)
# a. for a given
# b. expand v to cater for all potential non-zero windows
# =======================================================
entropyScale <- function(v) {
  ## v <- v*v
  v <- v / sum(v)
  (- v * log(v, 2)) %>%
    sum()
}
autocorrelateEntropy <- function(acm) {
  acm %>%
    apply(1,entropyScale)
}
test.autocorrelateEntropy <- function() {
  a1 <- sin( (1:500)*2*pi/23.0 )
  ace1 <- autocorrelate(a1,(0:100),5) %>% autocorrelateEntropy()

  a2 <- 2 * (runif(500) - 0.5)
  ace2 <- autocorrelate(a2,(0:100),5) %>% autocorrelateEntropy()

  df1 <- data.frame(x=(1:length(ace1)),y=ace1,z="sine")
  df2 <- data.frame(x=(1:length(ace2)),y=ace2,z="runif")
  df <- rbind(df1,df2)
  g <- ggplot(data=df) +
    geom_line(aes(x=x,y=y,colour=z)) +
    theme_bw()
  plot( g )
}



# =======================================================
# autocorrelateFft(v,taus,log2delta)
# a. for a given
# b. expand v to cater for all potential non-zero windows
# =======================================================
autocorrelateFft <- function(acm) {
  acm %>%
    (function(x) { plot(acm[250,]); x }) %>%
    t() %>%
    (function(x) { print(dim(x)); x }) %>%
    mvfft() %>%
    t() %>%
    (function(x) { x[,(1:(dim(x)[2]/2))] })
}
test.autocorrelateFft <- function(tt=500) {
  nperiods <- 31
  sampleRate <- 1024
  x <- (0:sampleRate) * (nperiods / sampleRate)
  a1 <- sin( x * pi  )
  a1 <- a1 + sin( 5 * x * pi  )
  a1 <- a1 + sin( 7 * x * pi  )
  print(x)
  plot(x,a1,type="l")
  a1fft <- Re(fft(a1))
  print(a1fft)
  plot(a1fft, type="l")
  return()

  ace1 <- autocorrelate(a1,(1:100),5) %>% autocorrelateFft()
  ace1 <- Re(ace1[tt,])
  print(ace1)

  a2 <- 2 * (runif(1000) - 0.5)
  ace2 <- autocorrelate(a2,(1:100),5) %>% autocorrelateFft()
  ace2 <- Re(ace2[tt,])

  df1 <- data.frame(x=(1:length(ace1)),y=ace1,z="sine")
  df2 <- data.frame(x=(1:length(ace2)),y=ace2,z="runif")
  df <- rbind(df1,df2)
  g <- ggplot(data=df) +
    geom_line(aes(x=x,y=y,colour=z)) +
    theme_bw()
  plot( g )
}

autocorrelateFftFisher <- function(acm) {
  acm %>%
    autocorrelateFft() %>%
    autocorrelateFisher()

}
test.autocorrelateFftFisher <- function(tt=500) {
  nperiods <- 31
  sampleRate <- 1024
  x <- (0:sampleRate) * (nperiods / sampleRate)
  a1 <- sin( x * pi  )
  a1 <- a1 + sin( 5 * x * pi  )
  a1 <- a1 + sin( 7 * x * pi  )
  print(x)
  plot(x,a1,type="l")
  a1fft <- Re(fft(a1))
  print(a1fft)
  plot(a1fft, type="l")
  return()

  ace1 <- autocorrelate(a1,(1:100),5) %>% autocorrelateFft()
  ace1 <- Re(ace1[tt,])
  print(ace1)

  a2 <- 2 * (runif(1000) - 0.5)
  ace2 <- autocorrelate(a2,(1:100),5) %>% autocorrelateFft()
  ace2 <- Re(ace2[tt,])

  df1 <- data.frame(x=(1:length(ace1)),y=ace1,z="sine")
  df2 <- data.frame(x=(1:length(ace2)),y=ace2,z="runif")
  df <- rbind(df1,df2)
  g <- ggplot(data=df) +
    geom_line(aes(x=x,y=y,colour=z)) +
    theme_bw()
  plot( g )
}



autocorrelateFftEntropy <- function(acm) {
  acm %>%
    autocorrelateFft() %>%
    autocorrelateEntropy()

}
test.autocorrelateFftEntropy <- function(tt=500) {
  nperiods <- 31
  sampleRate <- 1024
  x <- (0:sampleRate) * (nperiods / sampleRate)
  a1 <- sin( x * pi  )
  a1 <- a1 + sin( 5 * x * pi  )
  a1 <- a1 + sin( 7 * x * pi  )
  print(x)
  plot(x,a1,type="l")
  a1fft <- Re(fft(a1))
  print(a1fft)
  plot(a1fft, type="l")
  return()

  ace1 <- autocorrelate(a1,(1:100),5) %>% autocorrelateFft()
  ace1 <- Re(ace1[tt,])
  print(ace1)

  a2 <- 2 * (runif(1000) - 0.5)
  ace2 <- autocorrelate(a2,(1:100),5) %>% autocorrelateFft()
  ace2 <- Re(ace2[tt,])

  df1 <- data.frame(x=(1:length(ace1)),y=ace1,z="sine")
  df2 <- data.frame(x=(1:length(ace2)),y=ace2,z="runif")
  df <- rbind(df1,df2)
  g <- ggplot(data=df) +
    geom_line(aes(x=x,y=y,colour=z)) +
    theme_bw()
  plot( g )
}

normalise <- function(v) {
  v <- Re(v)
  mx <- max(v,na.rm=TRUE)
  mn <- min(v,na.rm=TRUE)
  (v - mn) / (mx - mn)
}
sumsq <- function(v) {
  sqrt( sum( v * v ) )
}
sampleDf <- function(df,n) {
  indices <- (1:floor(dim(df)[1] / n)) * n - floor( n / 2 )
  df[ indices, ]
}

mkPeriodicEnergy <- function(wavFile, transform=(function(x) { log(1+x) }), subSample=10, taus=(44:512), log2WindowSize=11) {
  wavFile %>% readWave() -> a
  an <- a@left %>% normalise() %>% (function(v) 0.2*(v - 1.0))
  l <- length(an); x <- (1:l)*1000/a@samp.rate
  dfa <- data.frame(x=(1:l)*1000/a@samp.rate,y=an,z="amplitude")
  ac <- autocorrelate(a@left,taus,log2WindowSize)
  df <- data.frame(x=x,i=(1:l))
  autocorrelateMeanSinusoidPower( ac ) %>% sqrt() %>% normalise() -> df$w
  df$vv <- transform( df$w )
  dg <- df %>% sampleDf(subSample)
  g <- ggplot() +
    ## geom_line(data=df,aes(x=x,y=-a*q),colour="darkgreen",size=0.7) +
    geom_line(data=dg,aes(x=x,y=vv),colour="red",size=0.7) +
    geom_line(data=dfa,aes(x=x,y=y),colour="black",size=0.3) +
    theme_bw() +
    ggtitle("red = average areas under autocorrelation curves" ) +
    xlab("ms") + ylab("averaged areas under autocorrelation curves, fitted to unit interval")
  plot( g )
  df
}

