# Install and load necessary packages for the server
required_packages <- c("shiny", "shinyjs", "yaml", "parallel", "data.table", "ggplot2", 
                       "dplyr", "tidyr", "spatstat.geom", "spatstat.explore", "dbscan", 
                       "gridExtra", "grid", "qpdf", "shinyFiles", "future", 
                       "future.apply", "promises", "tibble", "stats")

# Check and install missing packages
new_packages <- required_packages[!(required_packages %in% installed.packages()[,"Package"])]
if(length(new_packages)) install.packages(new_packages, dependencies = TRUE)

# Load the required packages
lapply(required_packages, library, character.only = TRUE)

# Source other necessary functions
source("rpgm/create_folders.R")
source("rpgm/kest.R")
source("rpgm/gest.R")
source("rpgm/dbscan.R")
source("rpgm/xy_point.R")
source("rpgm/Summarise_function.R")

# Function to check if all PDFs are valid and ready for merging
wait_for_files <- function(pdf_files, timeout = 30) {
  start_time <- Sys.time()
  while (Sys.time() - start_time < timeout) {
    # Check if all files exist and have non-zero size
    valid_pdfs <- sapply(pdf_files, function(file) tryCatch({
      file.exists(file) && file.info(file)$size > 0
    }, error = function(e) FALSE))
    if (all(valid_pdfs)) {
      return(TRUE)  # All files are ready
    }
    Sys.sleep(1)  # Wait for 1 second before checking again
  }
  return(FALSE)  # Timeout reached
}

server <- function(input, output, session) {
  
  # Placeholder for combined report path
  combined_report_path <- reactiveVal()
  
  observeEvent(input$run_analysis, {
    req(input$yaml_file)
    
    # Load YAML configuration
    config <- read_yaml(input$yaml_file$datapath)
    
    # Output directory and cores
    output_dir <- input$output
    cores <- input$cores
    
    # Create necessary folders (clear existing contents if the folder exists)
    createfolders(config)
    
    # Spatial files processing
    output$status <- renderText("Processing files...")
    sfiles <- list.files(config$paths$spatial, pattern = 'csv', full.names = TRUE)
    
    # Plotting XY points (Asynchronous processing)
    xy_results <- future_lapply(sfiles, function(p) plot_xy(config, p), future.seed = TRUE)
    output$xy_plot <- renderPlot({
      # Display first plot as example
      xy_results[[1]] 
    })
    
    # Summarizing the spatial files
    spatial_summary <- future_lapply(sfiles, function(p) generate_marker_summary(config, p), future.seed = TRUE)
    spatial_summary <- do.call(bind_rows, spatial_summary)
    fwrite(spatial_summary, config$paths$sample)
    
    # Output the summary table
    output$summary_table <- renderTable({
      spatial_summary
    })
    
    # Calculate spatial metrics (Asynchronous processing)
    cat("Calculating Metrics\n")
    metrics_results <- future_lapply(config$metrics, function(m) {
      lapply(sfiles, function(f) {
        if (m == "kest") calculate_kest(config, f)
        if (m == "gest") calculate_gest(config, f)
        if (m == "dbscan") calculate_dbscan(config, f)
      })
    }, future.seed = TRUE)
    
    # Plot functions for spatial metrics
    cat("Plotting results\n")
    sm_files <- lapply(config$metrics, function(m) {
      list.files(file.path(config$paths$output, "metrics", m), full.names = TRUE)
    })
    names(sm_files) <- config$metrics
    tmp <- future_lapply(names(sm_files), function(m) {
      future_lapply(sm_files[[m]], function(f) {
        if (m == "kest") plot_kest(config, f)
        if (m == "gest") plot_gest(config, f)
        if (m == "dbscan") plot_dbscan(config, f)
      })
    }, future.seed = TRUE)
    
    # After the metrics are calculated, combine the PDFs using qpdf
    pdf_output_path <- file.path(output_dir, "combined_report.pdf")
    pdf_files <- list.files(output_dir, pattern = "\\.pdf$", full.names = TRUE, recursive = TRUE)
    
    # Check if PDFs are available
    if (length(pdf_files) > 0) {
      # Wait for PDFs to be ready
      if (wait_for_files(pdf_files)) {
        tryCatch({
          qpdf::pdf_combine(pdf_files, pdf_output_path)
          combined_report_path(pdf_output_path)
          output$status <- renderText(paste("Combined report saved to", pdf_output_path))
        }, error = function(e) {
          output$status <- renderText(paste("Error combining PDFs:", e$message))
        })
      } else {
        output$status <- renderText("Timeout: PDFs are not ready for combination.")
      }
    } else {
      output$status <- renderText("No PDF files found to combine.")
    }
  })
  
  # Dynamically render the download button once the report is ready
  output$dynamic_button <- renderUI({
    req(combined_report_path())  # Ensure the report is ready before showing the button
    downloadButton("download_report", "Download Combined Report")
  })
  
  # Download handler for the combined report PDF
  output$download_report <- downloadHandler(
    filename = function() {
      paste("combined_report", Sys.Date(), ".pdf", sep = "")
    },
    content = function(file) {
      # Ensure the report exists before allowing download
      req(combined_report_path())
      file.copy(combined_report_path(), file)
    }
  )
}