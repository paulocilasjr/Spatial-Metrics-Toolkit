# Install and load necessary packages for the UI
required_packages_ui <- c("shiny")

# Check and install missing packages
new_packages_ui <- required_packages_ui[!(required_packages_ui %in% installed.packages()[,"Package"])]
if(length(new_packages_ui)) install.packages(new_packages_ui)

# Load the required packages
lapply(required_packages_ui, library, character.only = TRUE)

ui <- fluidPage(
  titlePanel("Spatial Data Analysis"),
  sidebarLayout(
    sidebarPanel(
      fileInput("yaml_file", "Upload YAML file", accept = c(".yml", ".yaml")),
      numericInput("cores", "Number of cores", value = 1, min = 1),
      textInput("output", "Output directory", value = "output"),
      actionButton("run_analysis", "Run Analysis")
    ),
    mainPanel(
      tableOutput("summary_table"),  
      uiOutput("dynamic_button"),    
    )
  )
)