
#' Title: simple_spatial_plot
#'
#' Takes in a csv file expecting x and y with a value
#'
#' @param x x axis
#' @param y y axis
#' @param pos_is_cell_positive expect 0 or 1
#'
#' @return ggplot2 plot object
#' @examples
#' # Example usage
#' simple_spatial_plot(data_base, "CD3..FOXP3.")
#'
#' @export
simple_spatial_plot <- function(data_base, colname) {
  data_base <- read.csv(filepath, header = TRUE, sep = ",")
  colname = "CD3..Opal.570..Positive"
  
  #p1 = simple_spatial_plot(data_base, colname)
  plot_data = cbind(data_base$x, data_base$y, data_base[,colname])
  colnames(plot_data) = c("x", "y", colname)
  plot_data = as.data.frame(plot_data)
  plot_data[which(plot_data[,colname] == 1), colname] = "present"
  plot_data[which(plot_data[,colname] == 0), colname] = "absent"
  p = ggplot(plot_data, aes(x = x, y = y, color = !!sym(colname))) + geom_point()
  
  return(p)
}

