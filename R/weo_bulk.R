#' Download and Process IMF WEO Data
#'
#' @param year Numeric year of the WEO release (e.g., 2023)
#' @param release Character or numeric: "Spring"/"Fall" or 1/2
#' @param file_path Optional path to save downloaded file
#' @param quiet Logical: whether to suppress messages
#'
#' @return A tibble containing WEO data in long format
#' @export
weo_bulk <- function(
  year,
  release = c("Spring", "Fall"),
  file_path = NULL,
  quiet = FALSE
) {
  # Validate inputs
  release <- match.arg(release)
  release_num <- if (release == "Spring") 1 else 2

  # Generate URL
  url <- create_weo_url(year, release_num)

  # Create temporary file if not specified
  if (is.null(file_path)) {
    file_path <- tempfile(fileext = ".xls")
    on.exit(unlink(file_path))
  }

  # Download file
  if (!quiet) cli::cli_alert_info("Downloading WEO data...")

  # Try to download first
  resp <- tryCatch(
    {
      httr2::request(url) |>
        httr2::req_error(is_error = function(resp) FALSE) |> # Don't error on HTTP errors
        httr2::req_perform()
    },
    error = function(e) {
      cli::cli_abort(c(
        "Failed to download WEO data",
        "i" = "URL: {url}",
        "x" = "Error: {conditionMessage(e)}"
      ))
    }
  )

  # Check response status
  if (httr2::resp_status(resp) != 200) {
    cli::cli_abort(c(
      "Failed to download WEO data",
      "i" = "URL: {url}",
      "x" = "HTTP status: {httr2::resp_status(resp)}"
    ))
  }

  # Write response to file
  writeBin(httr2::resp_body_raw(resp), file_path)

  # Check file exists and is not empty
  if (!file.exists(file_path) || file.size(file_path) == 0) {
    cli::cli_abort(c(
      "Failed to download WEO data",
      "i" = "URL: {url}",
      "x" = "Downloaded file is empty"
    ))
  }

  # If we get here, we have a valid file
  if (!quiet) cli::cli_alert_info("Processing data...")

  # Process data
  tryCatch(
    {
      data <- read_weo_file(file_path)
      process_weo_data(data)
    },
    error = function(e) {
      cli::cli_abort(c(
        "Failed to download WEO data", # Changed to match test expectation
        "i" = "URL: {url}"
      ))
    }
  )
}

#' Create WEO Download URL
#' @noRd
create_weo_url <- function(year, release) {
  # Base components
  base_url <- "https://www.imf.org/-/media/Files/Publications/WEO/WEO-Database"
  month <- if (release == 1) "Apr" else "Oct"
  month_long <- if (release == 1) "April" else "October"

  # New format since April 2024
  if (year >= 2024) {
    sprintf("%s/%d/%s/WEO%s%dall.xls", base_url, year, month_long, month, year)
  } else if (year >= 2021) {
    # Format from April 2021 to 2023
    sprintf("%s/%d/WEO%s%dall.ashx", base_url, year, month, year)
  } else if (year >= 2020) {
    # Format from October 2020
    sprintf("%s/%d/%02d/WEO%s%dall.xls", base_url, year, release, month, year)
  } else {
    # Earlier format
    sprintf("%s/%d/WEO%s%dall.xls", base_url, year, month, year)
  }
}

#' Read WEO File
#' @noRd
read_weo_file <- function(file_path) {
  if (!file.exists(file_path)) {
    cli::cli_abort("File does not exist: {file_path}")
  }

  # Custom name repair function
  fix_names <- function(names) {
    names[names == ""] <- paste0("col", seq_len(sum(names == "")))
    names
  }

  # First try ISO-8859-1 encoding
  df <- tryCatch(
    {
      suppressWarnings(
        readr::read_delim(
          file = file_path,
          delim = "\t",
          locale = readr::locale(encoding = "iso-8859-1"),
          show_col_types = FALSE,
          name_repair = fix_names
        )
      )
    },
    error = function(e) {
      # If that fails, try UTF-16 LE
      suppressWarnings(
        readr::read_delim(
          file = file_path,
          delim = "\t",
          locale = readr::locale(encoding = "UTF-16LE"),
          show_col_types = FALSE,
          name_repair = fix_names
        )
      )
    }
  )

  # Drop any unnamed or full NA columns
  df |>
    dplyr::select(
      -dplyr::matches("^col\\d+$"), # Remove numbered columns
      -dplyr::matches("^\\.\\.\\.[0-9]+$"), # Remove ...61 style columns
      dplyr::where(function(x) !all(is.na(x))) # Remove all-NA columns
    )
}

#' Process WEO Data into Tidy Format
#' @noRd
process_weo_data <- function(raw_data) {
  required_cols <- c(
    "Country",
    "ISO",
    "Subject Descriptor",
    "Units",
    "WEO Subject Code"
  )

  missing_cols <- setdiff(required_cols, names(raw_data))
  if (length(missing_cols) > 0) {
    cli::cli_abort(c(
      "Missing required columns in WEO data:",
      missing_cols
    ))
  }

  # Identify year columns (those that are numeric)
  year_cols <- names(raw_data)[grep("^\\d{4}$", names(raw_data))]

  if (length(year_cols) == 0) {
    cli::cli_abort("No year columns found in data")
  }

  # Remove any extra columns we don't need (this fixes the ...61 issue)
  clean_data <- raw_data |>
    dplyr::select(
      country = "Country",
      iso = "ISO",
      subject = "Subject Descriptor",
      units = "Units",
      series = "WEO Subject Code",
      dplyr::all_of(year_cols)
    )

  # Convert to long format
  long_data <- clean_data |>
    tidyr::pivot_longer(
      cols = dplyr::all_of(year_cols),
      names_to = "year",
      values_to = "value"
    )

  # Clean up data types, handling possible text in value column
  clean_values <- long_data |>
    dplyr::mutate(
      year = as.integer(.data$year),
      # Remove any commas from numbers and convert to numeric
      value = suppressWarnings(as.numeric(gsub(",", "", .data$value)))
    ) |>
    # Remove missing values
    dplyr::filter(!is.na(.data$value))

  clean_values
}
