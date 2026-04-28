getsquares <-
function(mat) {
  mat.add <- matrix(NA, nrow(mat), 0)
  mat.add.names <- c()
  for (i in seq_len(ncol(mat))) {
    if (length(unique(mat[, i])) > 2) {
      mat.add <- cbind(mat.add, mat[, i]^2)
      mat.add.names <- c(paste(colnames(mat)[i], ".2", sep = ""), mat.add.names)
    }
  }
  colnames(mat.add) <- mat.add.names
  out <- cbind(mat, mat.add)
  out
}

