# calculating Nearest neighbor as a terminal script -----------------------------
#this script will be called by what ever balancer is use
#arguments from yaml will be passed to this script to run 
#yaml::read_yaml("config.yml")

set.seed(333)
#libraries needed
suppressWarnings(library(optparse))
library(magrittr)
#spatial time would be called when needed
#data table will be called when needed

#option list
option_list = list(
  #yaml is all that is needed
  make_option(
    opt_str = c("-y", "--yaml"),
    type = "character",
    default = NULL,
    help = "path to yaml file with parameters",
    metavar = "character"
  )
)

opt_parser = OptionParser(option_list=option_list, add_help_option=FALSE)
opt = parse_args(opt_parser)

config = yaml::read_yaml(opt$yaml)

print(config)

#need to make a function taht converts opt into the yaml input or the yaml input into the opt

#options that can't be null
#cat(c(is.null(opt$sampleid), is.null(opt$subjectid), is.null(opt$spatialfolder), is.null(opt$radiusrange), is.null(opt$markers)), "\n")

if(is.null(config$variables$sample_id) | 
   is.null(config$variables$subject_id) | 
   is.null(config$variables$radii_range) | 
   is.null(config$variables$markers) | 
   is.null(config$paths$spatial) |
   is.null(config$paths$clinical) |
   is.null(config$paths$sample)){
  stop("At least one argument must be supplied (input file).", call.=FALSE)
}

#prep the working directory
#getwd() produces the path ot where the script is called.
working_dir = getwd()

# getting files -----------------------------------------------------------
#clinical
clinical = get_clinical(config$paths$clinical, config$variables$subject_id)
#temp spatial for creating mIF object
tmp_spatial = get_temp_spatial(spatial_path = config$paths$spatial,
                               sample_id = config$variables$sample_id)

#checking spatial columns
#make sure that the markers are in the spatial file otherwise quit
if(!all(config$variables$markers %in% colnames(tmp_spatial[[1]])))
  stop("not all yaml markers are in temp spatial file")
#make sure that the sample ID exists in spatial files
if(!(config$variables$sample_id %in% colnames(tmp_spatial[[1]])))
  stop("yaml sample id not in temp spatial file")
#make sure that classifier, if provided, exists in spatial
check_tissue_class(tissue_class_label = config$variables$tissue_class_label,
                   tissue_class = config$variables$tissue_class,
                   tmp_spatial = tmp_spatial)
    



# will do in loop for samples
# #check if location columns exist
# if(!is.null(opt$locs)){
#   opt$locs = unlist(strsplit(opt$locs, ","))
#   loc_cols_exist = lapply(spatial_list, function(s){
#     opt$locs %in% colnames(s)
#   }) %>% unlist() %>% unique()
#   if(FALSE %in% loc_cols_exist){
#     stop(cat("Cell location columns (", paste0(opt$locs, collapse = "/"), ") not in all spatial files"), call.=FALSE)
#   }
# }


#summary
#if no summary file, check if sample id is in clinical
if(is.null(opt$summary)){
  sampleid_col_exists = opt$sampleid %in% colnames(clinical)
  if(FALSE %in% subjectid_col_exists){
    stop(cat("Sample ID column (", opt$sampleid, ") not in clinical"), call.=FALSE)
  }
  #if not, create summary
  summary_dat = lapply(spatial_list, function(s){
    cell_sums = colSums(s[,opt$markers])
    cell_freqs = cell_sums / nrow(s) * 100
    names(cell_freqs) = paste(names(cell_freqs), "%")
    out_vec = c(unique(s[[opt$sampleid]]), cell_sums, `Total Cells` = nrow(s), cell_freqs)
    names(out_vec)[1] = opt$sampleid
    out_vec %>% t() %>% data.frame(check.names = FALSE)
  }) %>% 
    do.call(dplyr::bind_rows, .)
  summary_dat = summary_dat %>%
    dplyr::right_join(clinical[,c(opt$subjectid, opt$sampleid)], ., by = dplyr::join_by(!!opt$sampleid))
} else { #if there is a summary file, check that the sample and subject ID exists in it
  summary_dat = data.table::fread(file.path(working_dir, opt$path, opt$summary), data.table = FALSE)
  tissue_level_exists = c(opt$subjectid, opt$sampleid) %in% colnames(summary_dat)
  if(FALSE %in% tissue_level_exists){
    stop(cat("Either subject or sample not available in summary"), call.=FALSE)
  }
}

save.image("run.RData")
#make mif
mif = spatialTIME::create_mif(clinical_data = clinical,
                              sample_data = summary_dat,
                              spatial_list = spatial_list,
                              patient_id = opt$subjectid,
                              sample_id = opt$sampleid)

#calculate ripley's k
mif = spatialTIME::ripleys_k(mif = mif,
                             mnames = opt$markers,
                             r_range = eval(parse(text = opt$radiusrange)),
                             permute = opt$permute,
                             num_permutations = opt$numperms,
                             edge_correction = opt$edgecorrection,
                             xloc = opt$locs[1],
                             yloc = opt$locs[2],
                             keep_permutation_distribution = TRUE)


# save results ------------------------------------------------------------
if(opt$permute){
  #permutations
  subdir_perms = paste0("output/spatialTIME/derived/univariate_ripleys_k_", opt$numperms, "_perms")
  dir.create(file.path(working_dir, "output"), showWarnings = FALSE)
  dir.create(file.path(working_dir, "output/spatialTIME"), showWarnings = FALSE)
  dir.create(file.path(working_dir, "output/spatialTIME/derived"), showWarnings = FALSE)
  dir.create(file.path(working_dir, subdir_perms), showWarnings = FALSE)
  
  out = split(mif$derived$univariate_Count, mif$derived$univariate_Count[[opt$sampleid]])
  tmp = lapply(names(out), function(f){
    data.table::fwrite(out[[f]], paste0(file.path(working_dir, subdir_perms, f), ".csv"))
  })
  #data.table::fwrite(mif$sample, paste0(file.path(working_dir, subdir_perms), "/per_sample.csv"))
  
  #simplified
  subdir_simp = "output/spatialTIME/derived/univariate_ripleys_k_simplified"
  dir.create(file.path(working_dir, "output"), showWarnings = FALSE)
  dir.create(file.path(working_dir, "output/spatialTIME"), showWarnings = FALSE)
  dir.create(file.path(working_dir, "output/spatialTIME/derived"), showWarnings = FALSE)
  dir.create(file.path(working_dir, subdir_simp), showWarnings = FALSE)
  
  out = mif$derived$univariate_Count %>%
    dplyr::select(-iter) %>%
    dplyr::group_by(dplyr::across(c(!!opt$sampleid, Marker, r))) %>%
    dplyr::summarise(dplyr::across(dplyr::everything(), ~ mean(.x, na.rm = TRUE)), .groups = NULL)
  out = split(out, out[[opt$sampleid]])
  tmp = lapply(names(out), function(f){
    data.table::fwrite(out[[f]], paste0(file.path(working_dir, subdir_simp, f), ".csv"))
  })
  #data.table::fwrite(mif$sample, paste0(file.path(working_dir, subdir_simp), "/per_sample.csv"))
} else {
  #simplified
  subdir_simp = "output/spatialTIME/derived/univariate_ripleys_k_simplified"
  dir.create(file.path(working_dir, "output"), showWarnings = FALSE)
  dir.create(file.path(working_dir, "output/spatialTIME"), showWarnings = FALSE)
  dir.create(file.path(working_dir, "output/spatialTIME/derived"), showWarnings = FALSE)
  dir.create(file.path(working_dir, subdir_simp), showWarnings = FALSE)
  
  out = split(mif$derived$univariate_Count, mif$derived$univariate_Count[[opt$sampleid]])
  tmp = lapply(names(out), function(f){
    data.table::fwrite(out[[f]], paste0(file.path(working_dir, subdir_simp, f), ".csv"))
  })
}
