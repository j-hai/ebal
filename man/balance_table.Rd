\name{balance_table}
\alias{balance_table}
\title{Per-covariate balance table for an entropy-balancing fit}
\description{
Returns a tidy \code{data.frame} comparing pre- and post-weighting
moments for every column of \code{X}, under whichever estimand the
\code{\link{ebalance}} fit was built for. This is the canonical
balance representation for the package; \code{summary()},
\code{\link[generics]{tidy}}, \code{\link[generics]{glance}},
\code{\link{plot.ebalance}}, and \code{autoplot()} (when \pkg{ggplot2} is available) all
read from the same underlying numbers.
}
\usage{
balance_table(fit)
}
\arguments{
  \item{fit}{An object of class \code{ebalance} or \code{ebalance.trim}.}
}
\value{
A \code{data.frame} with one row per covariate and the following columns:
\describe{
  \item{\code{variable}}{covariate name (\code{rownames(X)}).}
  \item{\code{mean_treated_pre}, \code{mean_treated_post}}{raw and weighted treated means. Equal for ATT (treated weights are 1); differ for ATC and ATE.}
  \item{\code{mean_control_pre}, \code{mean_control_post}}{raw and weighted control means. Equal for ATC; differ for ATT and ATE.}
  \item{\code{diff_pre}, \code{diff_post}}{treated minus control means before and after weighting.}
  \item{\code{std_diff_pre}, \code{std_diff_post}}{standardized differences using the pooled pre-weighting SD as the denominator (so the two are directly comparable).}
  \item{\code{pct_reduction}}{percent reduction in absolute standardized difference: \eqn{100 (1 - |\mathrm{std\_diff\_post}|/|\mathrm{std\_diff\_pre}|)}. \code{NA} when \code{std_diff_pre} is zero.}
}
The estimand is also carried as \code{attr(out, "estimand")}.
}
\seealso{\code{\link{ebalance}}, \code{\link{summary.ebalance}}, \code{\link{plot.ebalance}}.}
\examples{
\donttest{
set.seed(1)
treatment <- c(rep(0, 50), rep(1, 30))
X <- rbind(replicate(3, rnorm(50)), replicate(3, rnorm(30, 0.5)))
colnames(X) <- paste0("x", 1:3)
fit <- ebalance(Treatment = treatment, X = X)
balance_table(fit)
}
}
