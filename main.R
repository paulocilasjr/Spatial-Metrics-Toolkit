#run with
#"Rscript main.R -y config.yml"

#global libraries
library(yaml)
library(optparse)
library(parallel)

#for testing
#option_list = read_yaml("config.yml")

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
  )
)

#parse the option to get the yaml location
opt_parser = OptionParser(option_list=option_list)
opt = parse_args(opt_parser)

#read in the yaml
config = read_yaml(opt$yaml)

#spatial files
sfiles = list.files(config$paths$spatial, 
                    pattern = 'csv',
                    full.names = TRUE)

#source functions
source("rpgm/create_folders.R")
source("rpgm/kest.R")
#prep folder structure
createfolders(config)

#plot functions for raw csv inputs
#use data.table to import gz

#calculate spatial metrics
if('kest' %in% config$metrics){
  tmp = mclapply(sfiles, function(p){
    calculate_kest(config, p)
  }, mc.cores = opt$cores)
}

#plot functions for spatial metrics
