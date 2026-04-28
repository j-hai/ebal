\name{ebalance}
\alias{ebalance}
\alias{ebalance.default}
\alias{ebalance.formula}

\title{
Entropy balancing
}
\description{
This function implements entropy balancing, a data preprocessing procedure that
allows users to reweight a dataset. The preprocessing is based on a maximum
entropy reweighting scheme that assigns weights to each unit such that the
covariate distributions in the reweighted data satisfy a set of moment
conditions specified by the researcher. This can be useful to balance covariate
distributions in observational studies with a binary treatment where the
control group data can be reweighted to match the covariate moments in the
treatment group. Entropy balancing can also be used to reweight a survey sample
to known characteristics from a target population. The weights that result
from entropy balancing can be passed to regression or other models to
subsequently analyze the reweighted data.

By default, \code{ebalance} reweights the covariate distributions from a
control group to match target moments computed from a treatment group such
that the reweighted data can be used to analyze the average treatment effect
on the treated.

Two interfaces are supported. The default method takes a \code{Treatment}
vector and a covariate matrix \code{X}; the formula method takes a two-sided
formula and a \code{data} frame.
}

\usage{
ebalance(Treatment, \dots)

\method{ebalance}{default}(Treatment, X, base.weight = NULL,
        norm.constant = NULL, coefs = NULL,
        max.iterations = 200, constraint.tolerance = 1,
        print.level = 0, \dots)

\method{ebalance}{formula}(Treatment, data, \dots)
}

\arguments{
  \item{Treatment}{
For the default method: a vector indicating the observations to reweight
(controls) and those used to compute target moments (treatment). This can be
a logical vector or a numeric vector where 0 denotes control observations
and 1 denotes treatment observations. For the formula method: a two-sided
formula of the form \code{treat ~ x1 + x2 + ...}, with the treatment
indicator on the left-hand side and the covariates on the right.
}
  \item{X}{
A matrix containing the covariates to include in the reweighting. To adjust
the means of the covariates, include the raw covariates. To adjust the
variances, include squared terms; for co-moments, include interaction terms.
All columns must have positive variance and the matrix must be invertible.
No missing data is allowed.
}
  \item{data}{
For the formula method: a data frame containing the variables in
\code{Treatment}.
}
  \item{base.weight}{
An optional vector of base weights for the maximum entropy reweighting (one
weight per control unit). Default: uniform base weights.
}
  \item{norm.constant}{
An optional normalizing constant. By default the weights are normalized such
that their sum equals the number of treated observations.
}
  \item{coefs}{
An optional vector of starting coefficients.
}
  \item{max.iterations}{
Maximum number of iterations.
}
  \item{constraint.tolerance}{
Tolerance for declaring the moments in the reweighted data equal to the
target moments.
}
  \item{print.level}{
Controls the level of printing: 0 (silent, the default), 1 (normal printing),
2 (detailed), and 3 (very detailed).
}
  \item{\dots}{
Additional arguments. For the formula method, passed through to the default
method.
}
}

\value{
A list of class \code{ebalance} with the following elements:
  \item{target.margins}{Target moments computed from the treatment group.}
  \item{co.xdata}{Covariate data from the control group (with intercept column).}
  \item{w}{Control-group weights assigned by entropy balancing (length = number of controls).}
  \item{coefs}{Coefficients from the reweighting algorithm.}
  \item{maxdiff}{Maximum deviation between reweighted moments and targets.}
  \item{norm.constant}{Normalizing constant used.}
  \item{constraint.tolerance}{Tolerance level used for the balance constraints.}
  \item{max.iterations}{Maximum number of iterations used.}
  \item{base.weight}{Base weight used.}
  \item{print.level}{Print level used.}
  \item{converged}{Logical flag indicating convergence within tolerance.}
  \item{Treatment}{The treatment indicator vector as supplied (length = number of observations).}
  \item{X}{The covariate matrix as supplied.}
}

\references{

Hainmueller, J. (2012) 'Entropy Balancing for Causal Effects: A Multivariate Reweighting Method to Produce Balanced Samples in Observational Studies', Political Analysis (Winter 2012) 20 (1): 25--46.

Zaslavsky, A. (1988), 'Representing local reweighting area adjustments by of households', Survey Methodology 14(2), 265--288.

Ireland, C. and Kullback, S. (1968), 'Contingency tables with given marginals', Biometrika 55, 179--188.

Kullback, S. (1959), Information Theory and Statistics, Wiley, NY.

}

\author{Jens Hainmueller}

\seealso{
\code{\link{ebalance.trim}} for trimming weights, and the
\code{\link[=summary.ebalance]{summary}}, \code{\link[=plot.ebalance]{plot}}, and
\code{\link[=weights.ebalance]{weights}} methods for inspection and downstream use.
}

\examples{

# Create toy data
set.seed(1)
treatment   <- c(rep(0, 50), rep(1, 30))
X           <- rbind(replicate(3, rnorm(50, 0)), replicate(3, rnorm(30, .5)))
colnames(X) <- paste0("x", 1:3)
df          <- data.frame(treat = treatment, X)

# Matrix interface
eb.out <- ebalance(Treatment = treatment, X = X)

# Formula interface (equivalent)
eb.out2 <- ebalance(treat ~ x1 + x2 + x3, data = df)

# Means in the treated group
apply(X[treatment == 1, ], 2, mean)
# Means in the reweighted control group
apply(X[treatment == 0, ], 2, weighted.mean, w = eb.out$w)
# Means in the raw control group
apply(X[treatment == 0, ], 2, mean)

# Or use summary() for a balance table
summary(eb.out)

}
