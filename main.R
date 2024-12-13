# run with
# "Rscript main.R -y config.yml"

# global libraries
cat("Prepping environment\n")

# Set a default CRAN mirror if none is already set
if (!getOption("repos")["CRAN"] == "https://cloud.r-project.org/") {
  options(repos = c(CRAN = "https://cloud.r-project.org/"))
}

# List of packages
packages <- c("yaml", "optparse", "parallel", "data.table",
              "ggplot2", "tibble", "dplyr", "tidyr",
              "spatstat.geom", "spatstat.explore", "dbscan", "htmltools", 
              "R.utils", "gridExtra", "pdftools", "qpdf")

# Install missing packages and load silently
lapply(packages, function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    cat(sprintf("Package '%s' is missing. Installing now...\n", pkg))
    install.packages(pkg, dependencies = TRUE)
  }
  suppressPackageStartupMessages(library(pkg, character.only = TRUE))
})

# for testing
cat("Making options list\n")
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

# parse the option to get the yaml location
cat("Parsing Options\n")
opt_parser = OptionParser(option_list=option_list)
opt = parse_args(opt_parser)

# read in the yaml
cat("Reading yaml\n")
config = read_yaml(opt$yaml)

# Set output folder based on user input
output_dir <- opt$output

# spatial files
cat("Identifying spatial files\n")
sfiles = list.files(config$paths$spatial, 
                    pattern = 'csv',
                    full.names = TRUE)

# source functions
cat("Sourcing functions\n")
source("rpgm/create_folders.R")
source("rpgm/kest.R")
source("rpgm/gest.R")
source("rpgm/dbscan.R")
source("rpgm/xy_point.R")

# prep folder structure
cat("Creating folder structure\n")
createfolders(config)

# plot functions for raw csv inputs
cat("Plotting xy points\n")
tmp = mclapply(sfiles, function(p){
  plot_xy(config, p)
}, mc.cores = opt$cores)

# calculate spatial metrics
cat("Calculating Metrics\n")
tmp = mclapply(config$metrics, function(m){
  mclapply(sfiles, function(f){
    if(m == "kest") calculate_kest(config, f)
    if(m == "gest") calculate_gest(config, f)
    if(m == "dbscan") calculate_dbscan(config, f)
  }, mc.allow.recursive = TRUE)
}, mc.cores = opt$cores, mc.allow.recursive = TRUE)

# Set output folder based on user input
output_dir <- file.path(opt$output, "figures")

# Create a PDF file for the report
pdf_output_path <- file.path(output_dir, "combined_report.pdf")

# Find all directories inside the output_dir
dirs <- list.dirs(output_dir, full.names = TRUE, recursive = FALSE)

# Collect all PDF files in the directory
pdf_files <- c()
for (dir in dirs) {
  # Find all PDF files in the current directory
  pdf_files <- c(pdf_files, list.files(dir, pattern = "\\.pdf$", full.names = TRUE))
}

# Combine the PDFs into one report using qpdf
if (length(pdf_files) > 0) {
  qpdf::pdf_combine(pdf_files, pdf_output_path)
  cat("Saving combined PDF report to:", pdf_output_path, "\n")
} else {
  cat("No PDF files found to combine.\n")
}