

calculate_gest = function(yaml, path){
  #read in files
  df = fread(path)
  #split based on the classifier label colun
  df_list = split(df, df[[yaml$variables$tissue_class_label]])
  #identify windows of compartments
  windows = lapply(df_list, function(x){
    convexhull.xy(x$x, x$y)
  })
  #point pattern objects
  pp_objs = lapply(seq(df_list), function(l){
    x = df_list[[l]]
    ppp(x$x, x$y, window = windows[[l]],
        marks = x[,yaml$variables$markers, with = FALSE])
  })
  gest_res = lapply(seq(df_list), function(l){
    p = pp_objs[[l]]
    x = df_list[[l]] %>%
      as.data.frame(check.names = FALSE)
    id = unique(x[[yaml$variables$sample_id]])
    res = lapply(yaml$variables$markers, function(marker){
      p2 = subset(p, marks(p)[[marker]] == 1)
      if(npoints(p2) < 2){
        out = data.frame(r = eval(parse(text = yaml$variables$radii_range))) %>%
          mutate(!!yaml$variables$sample_id := id,
                 Marker = marker, 
                 .before = 1)
      } else {
        out = Gest(p2, r=eval(parse(text = yaml$variables$radii_range))) %>%
          as.data.frame(check.names = FALSE) %>%
          mutate(!!yaml$variables$sample_id := id,
                 Marker = marker, 
                 .before = 1)
      }
      
      return(out %>%
               mutate(!!yaml$variables$tissue_class_label := names(df_list)[l]))
    }) %>%
      do.call(bind_rows, .)
  }) %>%
    do.call(bind_rows, .)
  fwrite(gest_res,
         file.path(yaml$paths$output, 'metrics/gest/', paste0(basename(gsub(".csv.*", "", path)), ".csv.gz")),
         compress = "gzip")
}