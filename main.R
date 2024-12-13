#run with
#"Rscript main.R -y config.yml"

#global libraries
cat("Prepping environment\n")

# Set a default CRAN mirror if none is already set
if (!getOption("repos")["CRAN"] == "https://cloud.r-project.org/") {
  options(repos = c(CRAN = "https://cloud.r-project.org/"))
}

# List of packages
packages <- c("yaml", "optparse", "parallel", "data.table",
              "ggplot2", "tibble", "dplyr", "tidyr",
              "spatstat.geom", "spatstat.explore", "dbscan", 
              "gridExtra", "grid", "qpdf")

# Install missing packages and load silently
lapply(packages, function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    cat(sprintf("Package '%s' is missing. Installing now...\n", pkg))
    install.packages(pkg, dependencies = TRUE)
  }
  suppressPackageStartupMessages(library(pkg, character.only = TRUE))
})

#for testing
#option_list = read_yaml("config.yml")
cat("Making options list\n")
#option - only taking in a yaml
option_list = list(
  make_option(
    opt_str = c("-y", "--yaml"),
    type = 'character',
    default = "config.yml",
    help = "path to yaml file with parameters",
    metavar = 'character'
  ),
  make_option(
    opt_str = c("-c", "--cores"),
    type = 'integer',
    default = 1,
    help = "number of cores for parallel processing",
    metavar = 'character'
  ),
  make_option(
    opt_str = c("-o", "--output"),
    type = 'character',
    default = "output",  # Default output folder
    help = "path to the output folder where plots and reports will be saved",
    metavar = 'character'
  )
)

#parse the option to get the yaml location
cat("Parsing Options\n")
opt_parser = OptionParser(option_list=option_list)
opt = parse_args(opt_parser)

#read in the yaml
cat("Reading yaml\n")
config = read_yaml(opt$yaml)

# Set output folder based on user input
output_dir <- opt$output

#spatial files
cat("Identifying spatial files\n")
sfiles = list.files(config$paths$spatial, 
                    pattern = 'csv',
                    full.names = TRUE)

#source functions
cat("Sourcing functions\n")
source("rpgm/create_folders.R")
source("rpgm/kest.R")
source("rpgm/gest.R")
source("rpgm/dbscan.R")
source("rpgm/xy_point.R")
source("rpgm/Summarise_function.R")

#prep folder structure
cat("Creating folder structure\n")
createfolders(config)

#plot functions for raw csv inputs
#use data.table to import gz
cat("Plotting xy points\n")
tmp = mclapply(sfiles, function(p){
  plot_xy(config, p)
}, mc.cores = opt$cores)

#summarize the spatial files
spatial_summary = mclapply(sfiles, function(p){
  generate_marker_summary(config, p)
}, mc.cores = opt$cores) %>%
  do.call(bind_rows, .)
fwrite(spatial_summary,
       config$paths$sample)

#calculate spatial metrics
cat("Calculating Metrics\n")
tmp = mclapply(config$metrics, function(m){
  mclapply(sfiles, function(f){
    if(m == "kest") calculate_kest(config, f)
    if(m == "gest") calculate_gest(config, f)
    if(m == "dbscan") calculate_dbscan(config, f)
  }, mc.allow.recursive = TRUE)
}, mc.cores = opt$cores, mc.allow.recursive = TRUE)

#plot functions for spatial metrics
cat("Plotting results\n")
cat("\tFinding derived results\n")
sm_files = lapply(config$metrics, function(m){
  list.files(file.path(config$paths$output, "metrics", m), full.names = TRUE)
})
names(sm_files) = config$metrics
cat("\tCreating plots\n")
tmp = mclapply(names(sm_files), function(m){
  tmp = mclapply(sm_files[[m]], function(f){
    if(m == "kest") plot_kest(config, f)
    if(m == "gest") plot_gest(config, f)
    if(m == "dbscan") plot_dbscan(config, f)
  }, mc.allow.recursive = TRUE)
}, mc.cores = opt$cores, mc.allow.recursive = TRUE)

# Set output folder based on user input
output_dir <- file.path(opt$output, "figures")

# Create a PDF file for the combined report
pdf_output_path <- file.path(opt$output, "combined_report.pdf")

# Find all directories inside the output_dir
dirs <- list.dirs(output_dir, full.names = TRUE, recursive = FALSE)

# Collect all PDF files in the directory, recursively
pdf_files <- c()
for (dir in dirs) {
  # Find all PDF files in the current directory
  pdf_files <- c(pdf_files, list.files(dir, pattern = "\\.pdf$", full.names = TRUE, recursive = TRUE))
}

# Check if there are any PDFs to combine
if (length(pdf_files) > 0) {
  cat("Found the following PDF files:\n")
  print(pdf_files)
  
  # Combine the PDFs into one report using qpdf
  qpdf::pdf_combine(pdf_files, pdf_output_path)
  
  cat("Saving combined PDF report to:", pdf_output_path, "\n")
} else {
  cat("No PDF files found to combine.\n")
}