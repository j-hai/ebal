\name{ebalance-methods}
\alias{print.ebalance}
\alias{print.ebalance.trim}
\alias{summary.ebalance}
\alias{summary.ebalance.trim}
\alias{print.summary.ebalance}
\alias{print.summary.ebalance.trim}
\alias{plot.ebalance}
\alias{plot.ebalance.trim}
\alias{weights.ebalance}
\alias{weights.ebalance.trim}

\title{Methods for ebalance and ebalance.trim objects}

\description{
Convenience methods for inspecting and using objects returned by
\code{\link{ebalance}} and \code{\link{ebalance.trim}}.
}

\usage{
\method{print}{ebalance}(x, \dots)
\method{print}{ebalance.trim}(x, \dots)
\method{summary}{ebalance}(object, \dots)
\method{summary}{ebalance.trim}(object, \dots)
\method{print}{summary.ebalance}(x, digits = 4, \dots)
\method{print}{summary.ebalance.trim}(x, digits = 4, \dots)
\method{plot}{ebalance}(x, abs.values = TRUE,
     xlab = NULL, main = NULL, \dots)
\method{plot}{ebalance.trim}(x, \dots)
\method{weights}{ebalance}(object, \dots)
\method{weights}{ebalance.trim}(object, \dots)
}

\arguments{
  \item{x, object}{An object of class \code{ebalance} or \code{ebalance.trim}.}
  \item{abs.values}{Logical. If \code{TRUE} (default) the Love plot shows
    absolute standardized differences; if \code{FALSE} signed.}
  \item{xlab, main}{Standard graphical arguments passed to \code{plot()}.}
  \item{digits}{Number of digits used when printing the summary table.}
  \item{\dots}{Additional arguments. Currently unused for \code{print},
    \code{summary}, \code{weights}; passed to \code{plot()} for plot methods.}
}

\details{
\code{print} gives a one-screen overview: counts of treated/control units,
number of moments balanced, convergence status, and (for trimmed objects)
whether the trim target was met.

\code{summary} returns a list of class \code{summary.ebalance} (or
\code{summary.ebalance.trim}) containing a balance table that compares
treated and control covariate means before and after weighting along with
the corresponding standardized differences.

\code{plot} produces a Love plot of the standardized differences before and
after weighting, one row per covariate.

\code{weights} returns a length-\eqn{n} numeric vector aligned to the
original \code{Treatment}: treated observations receive weight 1 and control
observations receive their entropy-balancing weight. This is suitable for
use with \code{lm(\dots, weights = w)} and other model fitters that accept
case weights.
}

\value{
\code{print} and the print methods for summary objects return their input
invisibly. \code{summary} returns an object of class \code{summary.ebalance}
or \code{summary.ebalance.trim} containing \code{$call.info} and
\code{$balance}. \code{plot} returns the balance table invisibly. \code{weights}
returns a numeric vector of length equal to the original
\code{Treatment} vector.
}

\seealso{
\code{\link{ebalance}}, \code{\link{ebalance.trim}}.
}

\examples{
set.seed(1)
treatment <- c(rep(0, 50), rep(1, 30))
X <- rbind(replicate(3, rnorm(50, 0)), replicate(3, rnorm(30, 0.5)))
colnames(X) <- paste0("x", 1:3)

eb.out <- ebalance(Treatment = treatment, X = X)
print(eb.out)
summary(eb.out)
w <- weights(eb.out)
length(w) == length(treatment)
\dontrun{
plot(eb.out)
}
}
