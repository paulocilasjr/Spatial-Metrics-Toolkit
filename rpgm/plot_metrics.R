library(ggplot2)
library(data.table)
library(tibble)
plot_kest = function(config, path){
  df = fread(path, data.table = FALSE)
  p = df %>%
    ggplot() +
    geom_line(aes(x = r, y = border - theo, color = Marker)) +
    facet_grid(get(config$variables$tissue_class_label)~.)
  
  pdf(file.path(config$paths$output, 'figures/metrics/kest/', paste0(basename(gsub(".csv.*", "", path)), ".pdf")),
      height = 7, width = 10)
  print(p)
  dev.off()
}

plot_gest = function(config, path){
  df = fread(path, data.table = FALSE)
  p = df %>%
    ggplot() +
    geom_line(aes(x = r, y = rs - theo, color = Marker)) +
    facet_grid(get(config$variables$tissue_class_label)~.)
  
  pdf(file.path(config$paths$output, 'figures/metrics/gest/', paste0(basename(gsub(".csv.*", "", path)), ".pdf")),
      height = 7, width = 10)
  print(p)
  dev.off()
}

plot_dbscan = function(config, path){
  db_res = readRDS(path)
  #convert results to table
  out = lapply(names(db_res), function(t){
    tis = db_res[[t]]
    lapply(names(tis), function(m){
      marker = tis[[m]]
      lapply(marker, function(r){
        data.table(clusters = r$num_clusters)
      }) %>% do.call(bind_rows, .) %>% 
        rownames_to_column("radius") %>%
        mutate(Marker = m)
    }) %>% do.call(bind_rows, .) %>%
      mutate(!!config$variables$tissue_class_label := t)
  }) %>%
    do.call(bind_rows, .)
  #create plot
  p = out %>%
    mutate(radius = as.numeric(radius)) %>%
    ggplot() + 
    geom_line(aes(x = radius, y = clusters, color = Marker)) +
    facet_grid(get(config$variables$tissue_class_label)~.)
  pdf(file.path(config$paths$output, 'figures/metrics/dbscan/', paste0(basename(gsub(".csv.*", "", path)), ".pdf")),
      height = 7, width = 10)
  print(p)
  dev.off()
}
