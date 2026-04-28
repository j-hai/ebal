matrixmaker <-
function(mat) {
  k <- ncol(mat)
  obs <- nrow(mat)
  ncombs <- (k * (k + 1)) / 2
  out <- matrix(NA, obs, ncombs)
  out.names <- character(ncombs)
  count <- 0
  for (i in seq_len(k)) {
    for (j in seq_len(i)) {
      count <- count + 1
      out[, count] <- mat[, i] * mat[, j]
      out.names[count] <- paste(colnames(mat)[i], ".", colnames(mat)[j], sep = "")
    }
  }
  colnames(out) <- out.names
  cbind(mat, out)
}

