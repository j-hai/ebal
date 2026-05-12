# ebal

[![R-CMD-check](https://github.com/j-hai/ebal/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/j-hai/ebal/actions/workflows/R-CMD-check.yaml)

Entropy balancing for the construction of balanced samples in observational
studies. Reweights a control group so that user-specified covariate moments
match those of a treatment group, or reweights a survey sample to match
known population characteristics. The weights can then be passed to
regression or other downstream models to estimate treatment effects on the
reweighted data.

The method is described in:

> Hainmueller, J. (2012). "Entropy Balancing for Causal Effects:
> A Multivariate Reweighting Method to Produce Balanced Samples in
> Observational Studies." *Political Analysis*, 20(1), 25–46.
> [doi:10.1093/pan/mpr025](https://doi.org/10.1093/pan/mpr025)

## Installation

```r
# From CRAN (when published)
install.packages("ebal")

# Development version from GitHub
# install.packages("remotes")
remotes::install_github("j-hai/ebal")
```

## Documentation

- [Project page](https://web.stanford.edu/~jhain/projects/4_project_ebal/) — package overview and current release notes.
- [Explainer](https://web.stanford.edu/~jhain/projects/entropy-balancing-explainer/) — a self-contained tutorial on entropy balancing for R and Stata users, including the Lalonde NSW benchmark.

## Estimands at a glance

`ebalance(..., estimand = ...)` chooses what gets reweighted:

| `estimand` | who gets reweighted | targets | answers |
|---|---|---|---|
| `"ATT"` (default) | controls | treated-group means | "what was the effect on those who actually got treatment?" |
| `"ATC"` | treated   | control-group means | "what would the effect have been on the control population if it had been treated?" |
| `"ATE"` | both      | overall sample means | "what is the average effect across the whole population?" |

**Reading weights:** always use `weights(fit)`, which returns a length-`n` vector aligned to your original `Treatment`/`X` and routes the per-side semantics correctly. `fit$w` is side-specific (controls under ATT; treated under ATC; control side only under ATE) and is kept for backward compatibility — prefer `weights(fit)` in new code. See `?ebalance` for the full per-estimand slot table.

## Quick start

```r
library(ebal)

# Toy data
set.seed(1)
treatment <- c(rep(0, 50), rep(1, 30))
X <- rbind(replicate(3, rnorm(50, 0)), replicate(3, rnorm(30, 0.5)))
colnames(X) <- paste0("x", 1:3)
df <- data.frame(treat = treatment, X)

# Fit (formula interface)
fit <- ebalance(treat ~ x1 + x2 + x3, data = df)

# Or matrix interface
fit <- ebalance(Treatment = treatment, X = X)

print(fit)
summary(fit)        # balance table, before vs. after weighting
plot(fit)           # Love plot of standardized differences
plot(fit, type = "weights")  # weight histogram with ESS / max-weight ratio

diagnostics(fit)    # PASS / WARN / FAIL on ESS, balance, convergence, trimming

# Use weights in a downstream regression
df$w <- weights(fit)        # length nrow(df), correct shape per estimand
df$y <- treatment + rnorm(nrow(df))            # toy outcome for the example
mod  <- lm(y ~ treat, data = df, weights = w)
```

## Trimming extreme weights

```r
# Auto-minimize maximum weight ratio
trimmed <- ebalance.trim(fit)

# Or specify a target
trimmed <- ebalance.trim(fit, max.weight = 5)

trimmed$trim.feasible      # TRUE if target was met (or auto mode finished)
weights(trimmed)           # length-n vector for downstream use
```

If the requested `max.weight` is infeasible the function emits a warning
and returns the most recent feasible fit with `trim.feasible = FALSE`.

## What's new in 0.2.0

* Formula interface: `ebalance(treat ~ x1 + x2, data = df)`
* `print()`, `summary()`, `plot()`, `weights()` S3 methods
* New `trim.feasible` field on `ebalance.trim` objects
* Numerical hardening: no more `NaN` crashes on aggressive trim targets;
  graceful fallback when the inner solve becomes singular

See [`NEWS.md`](NEWS.md) for the full change log.

## License

GPL (>= 2). See `LICENSE.note`.
