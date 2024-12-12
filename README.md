
# Spatial Metrics Toolkit

## Overview

The Spatial Metrics Toolkit is designed to automate the computation of spatial summary metrics for tissue microenvironment data. This tool supports scalable and flexible analysis, enabling researchers to extract meaningful insights from spatial proteomics and transcriptomics data.

## Input Data Format

The input data must be a CSV file with the following required columns:

- Sample Identifier (like `sample_id` or `id`)
- **`x`**: The x-coordinate of the cell or point in the tissue.
- **`y`**: The y-coordinate of the cell or point in the tissue.
- **Marker Columns**: Binary columns (1/0) indicating the presence (1) or absence (0) of specific markers for each cell. Each marker should have its own column with a descriptive name (e.g., `CD3+`, `CD20+`).
- **`compartment`** (optional): A column indicating the tissue compartment or region for each cell (e.g., `tumor`, `stroma`, `lymph`).

### Example Input Data

| x       | y       | CD3 | CD20 | CD68 | compartment |
|---------|---------|-----|------|------|-------------|
| 100.23  | 200.45  | 1   | 0    | 0    | tumor       |
| 150.67  | 250.89  | 0   | 1    | 0    | stroma      |
| 300.11  | 400.56  | 0   | 0    | 1    | lymph       |

### Notes:
- The `x` and `y` columns must be in the same units and coordinate system for all points in the dataset.
- Marker columns should use consistent naming conventions and binary values only.
- The `compartment` column is optional but recommended for stratified analyses.

## Preparing Your Data

1. **Check your data for missing values:** Ensure there are no missing values in the `x`, `y`, or marker columns. Missing values can cause errors during processing.
2. **Convert marker positivity to binary values:** If your data contains continuous values for marker intensity, binarize them into 1 (positive) and 0 (negative) based on your chosen threshold.
3. **Format tissue compartments (optional):** If applicable, include a column indicating tissue compartments. Use consistent and meaningful labels.
4. **Save as CSV:** Ensure your file is saved in CSV format with a `.csv` extension.

## Using the Toolkit

Once your data is formatted correctly:
1. Place your CSV file in the `data/per-cell/` directory specified by the toolkit.
2. Run the tool using the appropriate command or script (refer to the [Usage Instructions](#usage-instructions) below).
3. Outputs will be saved in a structured folder with summary metrics and visualizations.

## Usage Instructions

1. **Command-line Execution**  
   Use the following command to run the toolkit:
   ```bash
   #need to figure this part out
   Rscript run_spatialmetrics.R --input /path/to/your/file.csv --output /path/to/output/dir
   ```

   Replace `/path/to/your/file.csv` with the path to your input file and `/path/to/output/dir` with the desired output directory.

2. **Optional Parameters**  
   - `--method`: Specify a spatial summary method to run (e.g., `Ripley's K`, `DBSCAN`).
   - `--compartment`: Use this flag to enable analyses stratified by tissue compartments.

## Output

The toolkit generates:
- **Spatial Summary Metrics:** CSV files containing computed spatial metrics.
- **Visualizations:** Plots showing spatial distribution and summary analyses.
