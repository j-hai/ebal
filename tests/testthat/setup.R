# Tests use small toy panels that naturally have low ESS (e.g.,
# 18/50 = 36%, just above the 30% threshold) or sit close to other
# weak-fit thresholds. Suppressing the soft warnings keeps test
# output focused on real failures.
options(ebal.warn_weak_fit = FALSE)
