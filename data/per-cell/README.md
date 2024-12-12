
# Per-Cell Data Folder

## Overview

The `data/per-cell/` folder is designed to store CSV files containing per-cell spatial data. These files serve as the input for the Spatial Metrics Toolkit and must follow a specific format to ensure compatibility with the processing workflows.

## Data Format

Each CSV file in this folder must adhere to the following structure:

### Required Columns

- Sample Identifier (like `sample_id` or `id`)
- **`x`**: The x-coordinate of the cell in the tissue. Must be numeric.
- **`y`**: The y-coordinate of the cell in the tissue. Must be numeric.
- **Marker Columns**: Binary (1/0) columns indicating the presence (1) or absence (0) of specific markers for each cell. Marker names should be descriptive and consistent (e.g., `CD3+`, `CD20+`).
- **Optional Column**:  
  - **`compartment`**: A column indicating the tissue compartment or region for each cell (e.g., `tumor`, `stroma`, `lymph`). If included, values must be categorical.

### Example Data

| x       | y       | CD3 | CD20 | CD68 | compartment |
|---------|---------|-----|------|------|-------------|
| 120.50  | 240.75  | 1   | 0    | 0    | tumor       |
| 145.20  | 315.60  | 0   | 1    | 0    | stroma      |
| 300.90  | 400.45  | 0   | 0    | 1    | lymph       |

### Notes:
- All coordinates (`x`, `y`) must use the same units and reference frame across the dataset.
- Marker columns must be binary (1/0) and use descriptive names.
- The `compartment` column, while optional, is recommended for analyses that consider tissue regions.

## File Naming

- File names should reflect the sample or dataset they correspond to. Examples:
  - `sample_1.csv`
  - `patient_ABC.csv`
  - `experiment_2023.csv`

## Preparing Your Data

1. Ensure there are no missing values in the `x`, `y`, or marker columns.
2. Verify that all marker columns are binary. Convert continuous marker intensities to binary values using an appropriate threshold.
3. Save the file in CSV format with a `.csv` extension.

## Folder Guidelines

- Place only per-cell data CSV files in this folder.
- Avoid mixing other file types or data formats to ensure clarity and organization.
- Each file should correspond to one dataset or sample.
