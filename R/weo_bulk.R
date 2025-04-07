#' Download and Process IMF WEO Data
#'
#' @param year Numeric year of the WEO release (e.g., 2024)
#' @param release Character: "Spring" / "Fall"
#' @param file_path Optional path to save downloaded file.
#' @param quiet A logical indicating whether to print download information.
#'  Defaults to TRUE.
#'
#' @return A data frame containing WEO data in long format.
#'
#' @keywords internal
#' @noRd
weo_bulk <- function(
  year,
  release,
  file_path = NULL,
  quiet = FALSE
) {
  if (
    !is.null(.weo_cache$bulk) &&
      year == .weo_cache$year &&
      .weo_cache$release == release
  ) {
    return(.weo_cache$bulk)
  } else {
    release_num <- if (release == "Spring") 1 else 2

    url <- create_weo_url(year, release_num)

    if (is.null(file_path)) {
      file_path <- tempfile(fileext = ".xls")
      on.exit(unlink(file_path))
    }

    if (!quiet) {
      cli::cli_alert_info("Downloading WEO data...")
    }

    resp <- tryCatch(
      {
        httr2::request(url) |>
          httr2::req_error(is_error = function(resp) FALSE) |>
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

    if (httr2::resp_status(resp) != 200) {
      cli::cli_abort(c(
        "Failed to download WEO data",
        "i" = "URL: {url}",
        "x" = "HTTP status: {httr2::resp_status(resp)}"
      ))
    }

    writeBin(httr2::resp_body_raw(resp), file_path)

    if (!file.exists(file_path) || file.size(file_path) == 0) {
      cli::cli_abort(c(
        "Failed to download WEO data",
        "i" = "URL: {url}",
        "x" = "Downloaded file is empty"
      ))
    }

    if (!quiet) cli::cli_alert_info("Processing data...")

    tryCatch(
      {
        data <- read_weo_file(file_path)
        process_weo_data(data)
      },
      error = function(e) {
        cli::cli_abort(c(
          "Failed to download WEO data",
          "i" = "URL: {url}"
        ))
      }
    )
  }
}

#' Create WEO Download URL
#'
#' @keywords internal
#' @noRd
create_weo_url <- function(year, release) {
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
#'
#' @keywords internal
#' @noRd
read_weo_file <- function(file_path) {
  if (!file.exists(file_path)) {
    cli::cli_abort(c("x" = "File does not exist: {file_path}"))
  }

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

  df |>
    dplyr::select(
      -dplyr::matches("^col\\d+$"), # Remove numbered columns
      -dplyr::matches("^\\.\\.\\.[0-9]+$"), # Remove ...61 style columns
      dplyr::where(function(x) !all(is.na(x))) # Remove all-NA columns
    )
}

#' Process WEO Data into Tidy Format
#'
#' @keywords internal
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

  year_cols <- names(raw_data)[grep("^\\d{4}$", names(raw_data))]

  if (length(year_cols) == 0) {
    cli::cli_abort(c("x" = "No year columns found in data"))
  }

  clean_data <- raw_data |>
    dplyr::select(
      country = "Country",
      iso = "ISO",
      subject = "Subject Descriptor",
      units = "Units",
      series = "WEO Subject Code",
      dplyr::all_of(year_cols)
    )

  long_data <- clean_data |>
    tidyr::pivot_longer(
      cols = dplyr::all_of(year_cols),
      names_to = "year",
      values_to = "value"
    )

  clean_values <- long_data |>
    dplyr::mutate(
      year = as.integer(.data$year),
      value = suppressWarnings(as.numeric(gsub(",", "", .data$value)))
    ) |>
    dplyr::filter(!is.na(.data$value))

  clean_values
}
