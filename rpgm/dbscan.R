library(dbscan)
calculate_dbscan = function(config, path){
  #read in files
  df = fread(path, data.table = FALSE)
  #split based on the classifier label colun
  df_list = split(df, df[[config$variables$tissue_class_label]])
  
  #broken down by
  #tissue_class_label > marker > radius
  radii = eval(parse(text = config$variables$radii_range)) %>%
    setNames(.,.)
  out = lapply(df_list, function(tcl){
    res = lapply(config$variables$markers, function(marker){
      #print(marker)
      #subset to positive for marker
      wkn_df = tcl %>% filter(get(marker) == 1)
      #handle 0
      if(nrow(wkn_df) < 2) return() #do something to skip/handle
      x = as.matrix(wkn_df[,c('x', 'y')])
      db_out = lapply(radii, function(r){
        set.seed(333)
        db = dbscan(x, eps = r, minPts = 5)
        cluster_sizes = table(db$cluster)
        cluster_props = cluster_sizes / sum(cluster_sizes)
        return(list(clusters = db$cluster,
                    num_clusters = length(unique(db$cluster)) - 1,
                    cluster_sizes = cluster_sizes,
                    cluster_props = cluster_props))
      })
    })
    names(res) = config$variables$markers
    return(res)
  })
  saveRDS(out,
          file.path(config$paths$output, 'metrics/dbscan/', paste0(basename(gsub(".csv.*", "", path)), ".rds")))
}