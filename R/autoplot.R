# ggplot2 autoplot for ebalance and ebalance.trim objects.
# Discoverable via library(ggplot2); ggplot2 is Suggests:.

utils::globalVariables(c(".data"))

autoplot.ebalance <-
function(object, type = c("balance", "weights"), ...)
  {
    if (!requireNamespace("ggplot2", quietly = TRUE))
      stop("ggplot2 is required for autoplot(). install.packages(\"ggplot2\")")
    if (is.null(object$Treatment) || is.null(object$X))
      stop("\n autoplot() requires the Treatment vector and X matrix on\n the ebalance object (added in 0.2.0). Refit with the current\n ebalance() to enable this method. \n")
    type <- match.arg(type)
    if (type == "weights")
      return(.autoplot_ebalance_weights(object))
    .autoplot_ebalance_balance(object)
  }

autoplot.ebalance.trim <- autoplot.ebalance

# Internal: Love plot.
.autoplot_ebalance_balance <-
function(object)
  {
    bt <- .balance_table(object$Treatment, object$X, weights(object))
    df <- data.frame(
      term  = factor(rownames(bt), levels = rev(rownames(bt))),
      pre   = bt$std.diff.pre,
      post  = bt$std.diff.post,
      stringsAsFactors = FALSE
    )
    long <- rbind(
      data.frame(term = df$term, std_diff = df$pre,  status = "pre",
                 stringsAsFactors = FALSE),
      data.frame(term = df$term, std_diff = df$post, status = "post-weighting",
                 stringsAsFactors = FALSE)
    )
    long$status <- factor(long$status, levels = c("pre", "post-weighting"))

    ggplot2::ggplot(long,
                    ggplot2::aes(x = .data$std_diff, y = .data$term,
                                 color = .data$status, shape = .data$status)) +
      ggplot2::geom_vline(xintercept = 0, color = "grey60",
                          linetype = "dashed") +
      ggplot2::geom_vline(xintercept = c(-0.1, 0.1), color = "grey80",
                          linetype = "dotted") +
      ggplot2::geom_point(size = 2.5) +
      ggplot2::scale_color_manual(values = c("pre" = "grey50",
                                              "post-weighting" = "black")) +
      ggplot2::scale_shape_manual(values = c("pre" = 1, "post-weighting" = 19)) +
      ggplot2::labs(x = "Standardized difference (pooled SD)",
                    y = NULL,
                    color = NULL, shape = NULL,
                    title = "Covariate balance: treated minus control") +
      ggplot2::theme_minimal()
  }

# Internal: weight-distribution plot. Histogram(s) of the unit weights
# on whichever side(s) carry estimated weights. Subtitle reports the
# Kish ESS and max-weight ratio.
.autoplot_ebalance_weights <-
function(object)
  {
    ag <- .active_group(object)
    rows <- list()
    if (ag$reweighted %in% c("controls", "both"))
      rows$controls <- data.frame(side = "controls", weight = ag$w_control,
                                  stringsAsFactors = FALSE)
    if (ag$reweighted %in% c("treated", "both"))
      rows$treated  <- data.frame(side = "treated",  weight = ag$w_treated,
                                  stringsAsFactors = FALSE)
    long <- do.call(rbind, rows)
    long$side <- factor(long$side, levels = c("controls", "treated"))

    .ess   <- function(w) sum(w)^2 / sum(w^2)
    .ratio <- function(w) max(w) / mean(w)
    diag_lines <- vapply(levels(long$side), function(s) {
      w <- long$weight[long$side == s]
      if (length(w) == 0) return(NA_character_)
      sprintf("%s: ESS = %.0f / %d, max/mean = %.2f",
              s, .ess(w), length(w), .ratio(w))
    }, character(1))
    sub <- paste(diag_lines[!is.na(diag_lines)], collapse = "   |   ")

    p <- ggplot2::ggplot(long, ggplot2::aes(x = .data$weight)) +
      ggplot2::geom_histogram(bins = 30, fill = "grey85", color = "grey40") +
      ggplot2::labs(x = "Unit weight", y = "Count",
                    title = sprintf("Weight distribution (%s)", ag$estimand),
                    subtitle = sub) +
      ggplot2::theme_minimal()
    if (length(unique(long$side)) > 1) {
      p <- p + ggplot2::facet_wrap(~ side, ncol = 2, scales = "free")
    }
    p
  }
