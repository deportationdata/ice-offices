suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
})

old <- read_parquet("/tmp/old-ice-offices.parquet")
new <- read_parquet("data/ice-offices.parquet")

added   <- setdiff(new$office_name, old$office_name)
removed <- setdiff(old$office_name, new$office_name)

# Check for modified details in offices present in both
common <- intersect(new$office_name, old$office_name)
key_cols <- setdiff(names(new), "office_name")

modified_lines <- unlist(lapply(common, function(nm) {
  o <- old |> filter(office_name == nm) |> select(any_of(key_cols)) |> slice(1)
  n <- new |> filter(office_name == nm) |> select(any_of(key_cols)) |> slice(1)
  if (identical(o, n)) return(NULL)
  diffs <- unlist(lapply(key_cols, function(col) {
    ov <- as.character(o[[col]])
    nv <- as.character(n[[col]])
    if (!identical(ov, nv)) paste0("  - ", col, ": `", ov, "` -> `", nv, "`")
  }))
  c(paste0("- **", nm, "**"), diffs)
}))

lines <- character(0)
if (length(added) > 0) {
  lines <- c(lines, paste0("**", length(added), " office(s) added:**"))
  lines <- c(lines, paste0("- ", added))
  lines <- c(lines, "")
}
if (length(removed) > 0) {
  lines <- c(lines, paste0("**", length(removed), " office(s) removed:**"))
  lines <- c(lines, paste0("- ", removed))
  lines <- c(lines, "")
}
if (length(modified_lines) > 0) {
  n_modified <- sum(startsWith(modified_lines, "- **"))
  lines <- c(lines, paste0("**", n_modified, " office(s) with modified details:**"))
  lines <- c(lines, modified_lines)
  lines <- c(lines, "")
}
if (length(lines) == 0) {
  writeLines("NO_REAL_CHANGES", "/tmp/office-changes.txt")
} else {
  writeLines(lines, "/tmp/office-changes.txt")
}
