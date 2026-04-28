# Internal helpers. Not exported.

# Cap-then-exponentiate. exp() of a double overflows at about 709.78;
# at that point the result is Inf, and Inf multiplied against a zero
# entry of the design matrix or a zero base weight yields NaN, which
# breaks the convergence check downstream.
#
# This helper caps the input at 700 before exponentiating. The cap
# is inactive (no-op) for any well-conditioned problem, since fitted
# coefficients on standardized covariates produce linear predictors
# in the single digits. It only kicks in when the optimizer is being
# pushed into the overflow regime, e.g. by an aggressive
# ebalance.trim() target. In that regime, returning a very large but
# finite weight lets line.searcher() and eb()'s gradient check
# continue numerically; the optimizer then steers back away from the
# cap on subsequent iterations.
.safe_exp <- function(x, cap = 700) {
  exp(pmin(x, cap))
}
