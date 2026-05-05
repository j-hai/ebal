\name{ebalance}
\alias{ebalance}

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

Two interfaces are supported. With \code{Treatment} as a numeric or logical
vector, supply the covariate matrix \code{X} directly. With \code{Treatment}
as a two-sided \code{formula}, supply a \code{data} frame; the formula's
left-hand side is used as the treatment indicator and the right-hand side
as the covariate matrix (the intercept column is dropped automatically).
}

\usage{
ebalance(Treatment, X = NULL, base.weight = NULL,
         norm.constant = NULL, coefs = NULL,
         max.iterations = 200, constraint.tolerance = 1,
         print.level = 0, data = NULL,
         method = c("newton", "autodiff"),
         estimand = c("ATT", "ATE", "ATC"), \dots)
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
  \item{method}{
Solver. \code{"newton"} (default) uses the classical Newton-Raphson loop on
the dual problem -- fast and exact for well-conditioned problems, behavior
unchanged from earlier releases. \code{"autodiff"} uses BFGS on gradients
computed by automatic differentiation via the \pkg{torch} package -- more
stable when the optimization landscape is poorly conditioned and scales
better at large covariate counts. The autodiff path requires the
\pkg{torch} package (in \code{Suggests:}); the first call may require
\code{torch::install_torch()} to download libtorch. Contributed by Apoorva
Lal; ported from \url{https://github.com/apoorvalal/ebal}.
}
  \item{estimand}{
Causal estimand the weights are constructed for. One of \code{"ATT"}
(default; reweight controls to match treated moments -- the original
behavior of the package), \code{"ATC"} (reweight treated to match control
moments; symmetric to ATT with roles swapped), or \code{"ATE"} (reweight
both groups to match the overall sample moments; the resulting per-unit
weights -- accessible via \code{weights(fit)} -- can be passed to a
weighted regression for the average treatment effect on the population).
For \code{"ATE"}, \code{base.weight} can be either a single vector
(applied to controls; treated default to uniform) or a named list
\code{list(control = ..., treated = ...)}. The returned object carries
both per-side solves under \code{$control_solve} and \code{$treated_solve};
the top-level fields (\code{$w}, \code{$coefs}, \code{$target.margins})
mirror the control-side solve for backward compatibility with code that
reads them. \code{ebalance.trim()} currently supports \code{"ATT"} and
\code{"ATC"} only.
}
  \item{\dots}{
Additional arguments. For the formula method, passed through to the default
method.
}
}

\value{
A list of class \code{ebalance} with the following elements:
  \item{target.margins}{Target moments. For \code{"ATT"} these are the treated-group totals (length = number of moments + 1, with the leading entry equal to \code{norm.constant}). For \code{"ATC"} these are the control-group totals. For \code{"ATE"} the field mirrors the control-side solve; the treated-side targets live under \code{$treated_solve$target.margins}.}
  \item{co.xdata}{Covariate data for the side that is being reweighted (with leading intercept column). Controls for \code{"ATT"} (and the control-side solve under \code{"ATE"}); treated for \code{"ATC"}.}
  \item{w}{Estimated weights on the reweighted side. Length = number of controls for \code{"ATT"} and \code{"ATE"}; length = number of treated for \code{"ATC"}. To get a length-n vector aligned to \code{Treatment}, use \code{\link[=weights.ebalance]{weights(fit)}} (this routes correctly for every estimand and is the recommended access pattern).}
  \item{coefs}{Coefficients from the reweighting algorithm for the side carried in \code{$w}. \code{base.weight * exp(co.xdata \%*\% coefs)} reproduces \code{$w}.}
  \item{maxdiff}{Maximum deviation between reweighted moments and targets. For \code{"ATE"}, the worse of the two side-solves.}
  \item{norm.constant}{Normalizing constant used. For \code{"ATT"} defaults to the number of treated, for \code{"ATC"} to the number of controls. For \code{"ATE"} this is a list \code{list(control = ncontrols, treated = ntreated)} (the argument is not user-settable for ATE).}
  \item{constraint.tolerance}{Tolerance level used for the balance constraints.}
  \item{max.iterations}{Maximum number of iterations used.}
  \item{base.weight}{Base weight used. For \code{"ATT"} / \code{"ATC"} a length-(reweighted side) vector. For \code{"ATE"} a list \code{list(control = ..., treated = ...)}.}
  \item{print.level}{Print level used.}
  \item{converged}{Logical flag indicating convergence within tolerance. For \code{"ATE"}, \code{TRUE} only when both side solves converged.}
  \item{Treatment}{The treatment indicator vector as supplied (length = number of observations).}
  \item{X}{The covariate matrix as supplied.}
  \item{estimand}{The estimand the fit was built for: \code{"ATT"}, \code{"ATC"}, or \code{"ATE"}.}
  \item{control_solve, treated_solve}{(\code{"ATE"} only.) Per-side solves carrying their own \code{w}, \code{coefs}, \code{target.margins}, \code{co.xdata}, \code{maxdiff}, \code{converged}.}
}
\section{Slot fields by estimand}{
The same field names mean different things across estimands. The
table below summarizes the per-estimand semantics so you can read
\code{fit$w} / \code{weights(fit)} without having to remember which
side was reweighted:

\tabular{llll}{
                 \tab \strong{ATT}                          \tab \strong{ATC}                          \tab \strong{ATE} \cr
\code{$w}        \tab control weights (length n_C)          \tab treated weights (length n_T)          \tab control weights (mirrors \code{$control_solve$w}) \cr
\code{weights(fit)} \tab length n: treated = 1, controls = \code{$w} \tab length n: treated = \code{$w}, controls = 1 \tab length n: each side carries its solve's weights \cr
\code{$target.margins} \tab treated-group totals     \tab control-group totals      \tab control-side targets (treated-side at \code{$treated_solve$target.margins}) \cr
\code{$norm.constant}  \tab scalar (default n_T)    \tab scalar (default n_C)      \tab \code{list(control=n_C, treated=n_T)} (not user-settable) \cr
\code{$base.weight}    \tab length n_C              \tab length n_T                \tab \code{list(control=, treated=)} \cr
}
}

\references{

Hainmueller, J. (2012) 'Entropy Balancing for Causal Effects: A Multivariate Reweighting Method to Produce Balanced Samples in Observational Studies', Political Analysis (Winter 2012) 20 (1): 25--46.

Zaslavsky, A. (1988), 'Representing local reweighting area adjustments by of households', Survey Methodology 14(2), 265--288.

Ireland, C. and Kullback, S. (1968), 'Contingency tables with given marginals', Biometrika 55, 179--188.

Kullback, S. (1959), Information Theory and Statistics, Wiley, NY.

}

\author{Jens Hainmueller}

\section{Formula interface examples}{
The formula interface accepts anything the standard \code{\link[stats]{model.matrix}} machinery understands. The intercept column is dropped automatically. Examples:

\preformatted{
# Quadratic and interaction terms
ebalance(treat ~ age + I(age^2) + educ + income, data = df)
ebalance(treat ~ age * educ + income, data = df)

# Categorical predictors expand into dummies (k - 1 levels by default)
ebalance(treat ~ factor(region) + age + income, data = df)

# Combinations
ebalance(treat ~ factor(region) + age * educ + I(income^2), data = df)
}

For balancing higher moments mechanically (means, variances, covariances of the raw covariates) without specifying the formula by hand, see \code{\link{matrixmaker}} and \code{\link{getsquares}}.
}

\seealso{
\code{\link{ebalance.trim}} for trimming weights, and the
\code{\link[=summary.ebalance]{summary}}, \code{\link[=plot.ebalance]{plot}}, and
\code{\link[=weights.ebalance]{weights}} methods for inspection and downstream use.
}

\examples{

# Toy observational-study data: treatment is associated with older,
# more educated, higher-income units; the true effect on the outcome
# is 5, but a naive comparison is biased upward by the confounders.
set.seed(42)
n_t <- 75; n_c <- 250
df  <- data.frame(
  treat  = c(rep(1, n_t), rep(0, n_c)),
  age    = c(rnorm(n_t, 45,  8), rnorm(n_c, 38, 10)),
  educ   = c(rnorm(n_t, 16,  2.5), rnorm(n_c, 13, 3)),
  income = c(rnorm(n_t, 65, 12), rnorm(n_c, 50, 15))
)
df$y <- 0.1 * df$age + 0.3 * df$educ + 0.05 * df$income +
        5 * df$treat + rnorm(nrow(df), 0, 3)

# ---- Naive (biased) regression ------------------------------------
coef(lm(y ~ treat, data = df))["treat"]   # ATT estimate; pulled up by confounders

# ---- Entropy balancing: formula interface -------------------------
fit <- ebalance(treat ~ age + educ + income, data = df)
fit                       # one-screen overview via print()
summary(fit)              # balance table: pre/post means and std diffs

# ---- Equivalent matrix interface ----------------------------------
X <- as.matrix(df[, c("age", "educ", "income")])
fit2 <- ebalance(Treatment = df$treat, X = X)
all.equal(fit$w, fit2$w)  # identical results

# ---- Use the weights downstream ----------------------------------
df$w <- weights(fit)              # length = nrow(df); treated get 1
coef(lm(y ~ treat, data = df,     # weighted regression, ATT
        weights = w))["treat"]

# ---- Visualize balance --------------------------------------------
\dontrun{
plot(fit)                         # base-R Love plot, no dependencies
}

}
