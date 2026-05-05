\name{diagnostics}
\alias{diagnostics}
\alias{print.ebalance.diagnostics}
\title{"Is my fit okay?" diagnostic check for an entropy-balancing fit}
\description{
Runs a small set of fitness checks against an \code{\link{ebalance}}
or \code{\link{ebalance.trim}} object and returns a structured object
with a \code{print()} method that renders each check as
\code{PASS} / \code{WARN} / \code{FAIL}. The checks are:
\describe{
  \item{\code{control}}{Effective sample size and max-weight ratio on the control side (when the controls are reweighted).}
  \item{\code{treated}}{Same on the treated side (when the treated are reweighted).}
  \item{\code{balance}}{The largest absolute post-weighting standardized difference across all covariates.}
  \item{\code{converged}}{Whether the entropy-balancing algorithm reached its \code{constraint.tolerance}.}
  \item{\code{trim}}{Only present for \code{ebalance.trim} objects: whether the requested max-weight target was met.}
}
}
\usage{
diagnostics(fit, ess_warn = 0.30, ratio_warn = 10, std_diff_warn = 0.05)
}
\arguments{
  \item{fit}{An object of class \code{ebalance} or \code{ebalance.trim}.}
  \item{ess_warn}{ESS-as-fraction-of-n threshold below which the check is flagged \code{WARN}. Default 0.30 (i.e., effective sample size below 30\% of the side's unit count).}
  \item{ratio_warn}{Max-weight ratio above which the check is flagged \code{WARN}. Default 10.}
  \item{std_diff_warn}{Maximum absolute post-weighting standardized difference above which the balance check is flagged \code{WARN}. Default 0.05.}
}
\value{
A list of class \code{ebalance.diagnostics} carrying the underlying numbers (everything in \code{\link[generics]{glance}} plus \code{trim_feasible}) and one \code{check_*} sublist per check. The \code{print()} method is the typical way to consume the output; see the examples.
}
\seealso{\code{\link{ebalance}}, \code{\link{balance_table}}, \code{\link[generics]{glance}}.}
\examples{
\donttest{
set.seed(1)
treatment <- c(rep(0, 50), rep(1, 30))
X <- rbind(replicate(3, rnorm(50)), replicate(3, rnorm(30, 0.5)))
colnames(X) <- paste0("x", 1:3)
fit <- ebalance(Treatment = treatment, X = X)
diagnostics(fit)
}
}
