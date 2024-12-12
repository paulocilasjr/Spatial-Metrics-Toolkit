#run with
#"Rscript main.R -y config.yml"


#global libraries
library(yaml)
library(optparse)

#option - only taking in a yaml
option_list = list(
  make_option(
    opt_str = c("-y", "--yaml"),
    type = 'character',
    default = NULL,
    help = "path to yaml file with parameters",
    metavar = 'character'
  )
)

#parse the option to get the yaml location
opt_parser = OptionParser(option_list=option_list)
opt = parse_args(opt_parser)

#read in the yaml
config = read_yaml(opt$yaml)


