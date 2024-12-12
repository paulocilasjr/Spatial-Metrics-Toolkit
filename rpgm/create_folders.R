#library(yaml)
#ymlfile <- yaml::read_yaml("/Users/4479438/Documents/hackathon2024/Spati_met_toolkit/config.yml")
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
