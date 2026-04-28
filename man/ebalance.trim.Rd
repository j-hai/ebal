\name{ebalance.trim}
\alias{ebalance.trim}
\title{
Trimming of Weights for Entropy Balancing
}
\description{
Trim weights obtained from entropy balancing. Takes the output from a call to
\code{\link{ebalance}} and trims the weights (subject to the moment conditions)
so that the ratio of the maximum (or minimum) weight to the mean weight is
reduced to satisfy a user-specified target. If no target is specified, the
maximum weight ratio is automatically trimmed as far as is feasible given the
data.
}
\usage{
ebalance.trim(ebalanceobj, max.weight = NULL,
              min.weight = 0, max.trim.iterations = 200,
              max.weight.increment = 0.92,
              min.weight.increment = 1.08,
              print.level = 0)
}

\arguments{
  \item{ebalanceobj}{
An object from a call to \code{ebalance}.
}
  \item{max.weight}{
Optional target for the ratio of the maximum to mean weight.
}
  \item{min.weight}{
Optional target for the ratio of the minimum to mean weight.
}         
  \item{max.trim.iterations}{
Maximum number of trimming iterations.
}
  \item{max.weight.increment}{
Increment for iterative trimming of the ratio of the maximum to mean weight (a scalar between 0-1, .92 indicates that 
the attempted reduction in the max ratio is 8 percent). 
}
  \item{min.weight.increment}{
Increment for iterative trimming of the ratio of the minimum to mean weight (a scalar  > 1, 1.08 indicates that 
the attempted reduction in the max ratio is 8 percent).
}
  \item{print.level}{
Controls the level of printing: 0 (silent, the default), 1 (normal printing), 2 (detailed), and 3 (very detailed).
}
}

\value{
An list object of class \code{ebalance.trim} with the following elements:
  \item{target.margins}{A vector that contains the target moments coded from the covariate distributions of the treatment group.}
  \item{co.xdata}{A matrix that contains the covariate data from the control group.}
  \item{w}{A vector that contains the control group weights assigned by trimming entropy balancing algorithm.}
  \item{coefs }{A vector that contains coefficients from the reweighting algorithm.}
  \item{maxdiff }{A scalar that contains the maximum deviation between the moments of the reweighted data and the target moments.}
  \item{norm.constant}{Normalizing constant used.}
  \item{constraint.tolerance}{The tolerance level used for the balance constraints.}
  \item{max.iterations}{Maximum number of trimming iterations used.}
  \item{base.weight}{The base weight used.}
  \item{converged}{Logical flag if the inner entropy-balancing algorithm converged within tolerance on the last successful iteration.}
  \item{trim.feasible}{Logical flag indicating whether the requested trimming target was achieved. \code{TRUE} when (a) an explicit \code{max.weight} (and optional \code{min.weight}) target was met, or (b) automated minimization mode finished. \code{FALSE} when an explicit target was not met because the maximum number of iterations was exceeded or the inner solve became numerically singular; in that case a warning is emitted and the most recent feasible fit is returned.}
}

\references{

Hainmueller, J. (2012) 'Entropy Balancing for Causal Effects: A Multivariate Reweighting Method to Produce Balanced Samples in Observational Studies', Political Analysis (Winter 2012) 20 (1): 25--46.

Zaslavsky, A. (1988), 'Representing local reweighting area adjustments by of households', Survey Methodology 14(2), 265--288.

Ireland, C. and Kullback, S. (1968), 'Contingency tables with given marginals', Biometrika 55, 179--188.

Kullback, S. (1959), Information Theory and Statistics, Wiley, NY.

}
\author{
Jens Hainmueller
}

\seealso{
Also see \code{\link{ebalance}}.
}

\examples{

# Toy data with substantial covariate imbalance
set.seed(20260427)
n_t <- 50; n_c <- 100
df  <- data.frame(
  treat = c(rep(1, n_t), rep(0, n_c)),
  x1    = c(rnorm(n_t, 0.6), rnorm(n_c, 0)),
  x2    = c(rnorm(n_t, 0.6), rnorm(n_c, 0)),
  x3    = c(rnorm(n_t, 0.6), rnorm(n_c, 0))
)
fit <- ebalance(treat ~ x1 + x2 + x3, data = df)

# ---- Auto-minimization mode ---------------------------------------
# Without a target, ebalance.trim() iteratively reduces the maximum
# weight ratio as far as the data allows. trim.feasible is TRUE by
# definition for auto mode.
trimmed <- ebalance.trim(fit)
trimmed                        # print method shows trim.feasible + max ratio
summary(trimmed)               # balance table for the trimmed weights

# Compare untrimmed vs. trimmed weight distributions
round(summary(fit$w),     2)
round(summary(trimmed$w), 2)

# ---- Explicit max.weight target -----------------------------------
# Pick a target above the natural minimum ratio so it's achievable.
target <- max(fit$w / mean(fit$w)) * 1.5
trimmed2 <- ebalance.trim(fit, max.weight = target)
trimmed2$trim.feasible         # TRUE — target was met

# ---- Infeasible target: graceful fallback (new in 0.2.0) ----------
# Asking for something the data cannot support no longer crashes.
# A warning is emitted and the most recent feasible fit is returned
# with trim.feasible = FALSE.
trimmed3 <- suppressWarnings(ebalance.trim(fit, max.weight = 1.2))
trimmed3$trim.feasible         # FALSE — target was infeasible
max(trimmed3$w) / mean(trimmed3$w)   # the best we could do

# ---- Use the trimmed weights downstream ---------------------------
df$y <- df$treat * 5 + df$x1 + df$x2 + df$x3 + rnorm(nrow(df))
df$w <- weights(trimmed)       # length = nrow(df), treated = 1
coef(lm(y ~ treat, data = df, weights = w))["treat"]

}
