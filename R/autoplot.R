# ggplot2 autoplot for ebalance and ebalance.trim objects.
# Discoverable via library(ggplot2); ggplot2 is Suggests:.

utils::globalVariables(c(".data"))

autoplot.ebalance <-
function(object, ...)
  {
    if (!requireNamespace("ggplot2", quietly = TRUE))
      stop("ggplot2 is required for autoplot(). install.packages(\"ggplot2\")")
    if (is.null(object$Treatment) || is.null(object$X))
      stop("\n autoplot() requires the Treatment vector and X matrix on\n the ebalance object (added in 0.2.0). Refit with the current\n ebalance() to enable this method. \n")

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

autoplot.ebalance.trim <- autoplot.ebalance
