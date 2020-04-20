setwd('C:\\Users\\Mike\\Desktop\\School\\networks_replication')
library(rstan)


source('Barbera/functions.R')

## change the following lines to run this Rscript for other countries
matrixfile <- 'Barbera/adj-matrix-US.rdata'
#outputfile <- 'stan-fit-US.rdata'
#samplesfile <- 'samples-US.rdata'
#resultsfile <- 'results-elites-US.rdata'
outputfile <- 'stan-fit2-US.rdata'
samplesfile <- 'samples2-US.rdata'
resultsfile <- 'results2-elites-US.rdata'
country <- 'US'

# parameters for Stan model
n.iter <- 3000
n.warmup <- 2000
thin <- 1 ## this will give up to 200 effective samples for each chain and par

# loading data
load(matrixfile)

## starting values for elites (for identification purposes)
load("Barbera/elites-data.Rdata")

# US:
if (country=="US"){
  us <- elites.data[['US']]
  parties <- merge(
    data.frame(screen_name = colnames(y), stringsAsFactors=F),
    us[,c("screen_name", "party")], sort=FALSE, all.x=TRUE)$party
  start.phi <- rep(0, length(parties))
  start.phi[parties=="D"] <- -1
  start.phi[parties=="R"] <- 1
}

J <- dim(y)[1]

# choosing a sample of 10,000 "informative" users who follow 10 or more
# politicians, and then subsetting politicians followed by >200 of these

if (J>10000){
  J <- 10000
  inform <- which(rowSums(y)>10)
  set.seed(12345)
  subset.i <- sample(inform, J)
  y <- y[subset.i, ]
  start.phi <- start.phi[which(colSums(y)>200)]
  y <- y[,which(colSums(y)>200)]
}

## data for model
J <- dim(y)[1]
K <- dim(y)[2]
N <- J * K
jj <- rep(1:J, times=K)
kk <- rep(1:K, each=J)

stan.data <- list(J=J, K=K, N=N, jj=jj, kk=kk, y=c(as.matrix(y)))

## rest of starting values
colK <- colSums(y)
rowJ <- rowSums(y)
normalize <- function(x){ (x-mean(x))/sd(x) }

# set the initial parameters for the model. Currently set at 2 sets of inits. 1 init = 1 chain
inits <- rep(list(list(alpha=normalize(log(colK+0.0001)), 
                       beta=normalize(log(rowJ+0.0001)),
                       theta=rnorm(J), phi=start.phi,mu_beta=0, sigma_beta=1, 
                       mu_phi=0, sigma_phi=1, sigma_alpha=1)),5)


# get the names of the politicians sampled
names <- rownames(as.matrix(inits[[1]]$alpha))

# Experimental model, no gamma
stan.code <- '
data {
  int<lower=1> J; // number of twitter users
  int<lower=1> K; // number of elite twitter accounts
  int<lower=1> N; // N = J x K
  int<lower=1,upper=J> jj[N]; // twitter user for observation n
  int<lower=1,upper=K> kk[N]; // elite account for observation n
  int<lower=0,upper=1> y[N]; // dummy if user i follows elite j
}

parameters {
  vector[K] alpha;
  vector[K] phi;
  vector[J] theta;
  vector[J] beta;
  real mu_beta;
  real<lower=0.1> sigma_beta;
  real mu_phi;
  real<lower=0.1> sigma_phi;
  real<lower=0.1> sigma_alpha;
}

model {
  alpha ~ normal(0, sigma_alpha);
  beta ~ normal(mu_beta, sigma_beta);
  phi ~ normal(mu_phi, sigma_phi);
  theta ~ normal(0, 1);

for (n in 1:N)
  y[n] ~ bernoulli_logit( alpha[kk[n]] + beta[jj[n]] + 
    ( theta[jj[n]] * phi[kk[n]] ) );
}
'

#stan.model <- stan_model(model_code=stan.code)


# fit the model
stan.fit <- stan(model_code=stan.code, data = stan.data, 
                 iter=n.iter, warmup=n.warmup, init=inits, chains=5, 
                 thin=thin, cores=5)

# save and export results
samples <- extract(stan.fit, pars=c("alpha", "phi", "mu_beta",
                                    "sigma_beta", "sigma_alpha"))

save(samples, file=samplesfile)

results <- data.frame(
  screen_name = names,
  phi = apply(samples$phi, 2, mean),
  phi.sd = apply(samples$phi, 2, sd),
  alpha = apply(samples$alpha, 2, mean),
  alpha.sd = apply(samples$alpha, 2, sd),
  stringsAsFactors=F)
save(results, file=resultsfile)
results

# diagnostics
pairs(
  x = stan.fit
  , pars = c(
    'mu_beta'
    , 'sigma_beta'
    , 'mu_phi'
    , 'sigma_phi'
    , 'sigma_alpha'
    #, 'gamma'
  )
)

traceplot(stan.fit, par = c('phi[1]', 'alpha[1]', 'beta[1]', 'theta[1]'))
#traceplot(stan.fit)
fit <- as.matrix(stan.fit)

#library(boa)
#boa.menu()

