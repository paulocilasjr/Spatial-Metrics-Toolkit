createfolders <- function(yaml){ 
  output_path <- ymlfile$paths$output
  dir.create(output_path)
  dir.create(file.path(output_path, "figures"))
  dir.create(file.path(output_path, "metrics"))
  figures_path <- file.path(output_path, "figures")
  dir.create(file.path(figures_path, "barplot"), )
  dir.create(file.path(figures_path, "metrics"))
  dir.create(file.path(figures_path, "point"))
}
createfolders(ymlfile)
