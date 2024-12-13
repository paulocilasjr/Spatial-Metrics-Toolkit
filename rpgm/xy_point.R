
plot_xy = function(yaml, path){
  #read in files
  df = fread(path)
  #convert data to long format
  id = unique(df[[yaml$variables$sample_id]])
  #get data
  df2 = df %>% 
    as.data.frame(check.names = FALSE) %>%
    select(any_of(c(yaml$variables$x_value, yaml$variables$y_value,
                    yaml$variables$markers,
                    yaml$variables$tissue_class_label))) %>%
    mutate(background = ifelse(rowSums(across(!!yaml$variables$markers)) == 0,
                               1, #not positive
                               0)) %>%
    pivot_longer(cols = c(!!yaml$variables$markers, background), 
                 values_to = "positive", names_to = "Marker") %>%
    filter(positive == 1)
  
  #plot
  if(!is.null(yaml$variables$tissue_class_label)){
    p = df2 %>%
      ggplot() + 
      geom_point(data = . %>%
                   filter(Marker == "background"),
                 aes(x = get(yaml$variables$x_value), y = get(yaml$variables$y_value), shape = get(yaml$variables$tissue_class_label)),
                 color = 'grey75') +
      geom_point(data = . %>%
                   filter(Marker != "background"),
                 aes(x = get(yaml$variables$x_value), y = get(yaml$variables$y_value), shape = get(yaml$variables$tissue_class_label), color = Marker)) +
      guides(shape=guide_legend(title=yaml$variables$tissue_class_label)) +
      coord_equal() +
      theme_classic()
  } else {
    p = df2 %>%
      ggplot() + 
      geom_point(data = . %>%
                   filter(Marker == "background"),
                 aes(x = get(yaml$variables$x_value), y = get(yaml$variables$y_value)),
                 color = 'grey75') +
      geom_point(data = . %>%
                   filter(Marker != "background"),
                 aes(x = get(yaml$variables$x_value), y = get(yaml$variables$y_value), color = Marker)) +
      coord_equal() +
      theme_classic()
  }
  
  pdf(file.path(yaml$paths$output, 'figures/point/', paste0(basename(gsub(".csv.*", "", path)), ".pdf")),
      height = 10, width = 10)
  print(p +
          labs(x = yaml$variables$x_value,
               y = yaml$variables$y_value,
               title = id))
  dev.off()
}