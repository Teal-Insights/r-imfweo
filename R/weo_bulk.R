#' Download and Process IMF WEO Data (including country groups)
#'
#' @param year Numeric year of the WEO release (e.g., 2024)
#' @param release Character: "Spring" / "Fall"
#' @param quiet A logical indicating whether to print download information.
#'
#' @return A data frame containing WEO data (countries + groups) in long format.
#'
#' @keywords internal
#' @noRd
weo_bulk <- function(
  year,
  release,
  quiet = FALSE
) {
  if (
    !is.null(.weo_cache$bulk) &&
      year == .weo_cache$year &&
      .weo_cache$release == release
  ) {
    return(.weo_cache$bulk)
  } else {
    release_num <- ifelse(release == "Spring", 1L, 2L)

    # Create URLs
    url_country <- create_weo_url(year, release_num, country_groups = FALSE)
    url_groups <- create_weo_url(year, release_num, country_groups = TRUE)

    # Temp file paths
    file_country <- tempfile(fileext = ".xls")
    file_groups <- tempfile(fileext = ".xls")
    on.exit({
      unlink(file_country)
      unlink(file_groups)
    })

    # Download both files
    download_weo(url_country, file_country, "WEO country", quiet)
    download_weo(url_groups, file_groups, "WEO country groups", quiet)

    if (!quiet) cli::cli_alert_info("Processing data...")

    # Read and process both
    raw_country <- read_weo_file(file_country)
    data_country <- process_weo_data(raw_country)

    raw_group <- read_weo_file(file_groups)
    data_groups <- process_weo_group_data(raw_group)

    full_data <- dplyr::bind_rows(data_country, data_groups)

    # Optionally cache
    .weo_cache$bulk <- full_data
    .weo_cache$year <- year
    .weo_cache$release <- release

    full_data
  }
}

#' @keywords internal
#' @noRd
download_weo <- function(url, dest, label, quiet) {
  if (!quiet) cli::cli_alert_info("Downloading {label} data...")

  resp <- tryCatch(
    perform_request(url),
    error = function(e) {
      cli::cli_abort(c(
        "Failed to download {label} data",
        "i" = "URL: {url}",
        "x" = "Error: {conditionMessage(e)}"
      ))
    }
  )

  if (httr2::resp_status(resp) != 200) {
    cli::cli_abort(c(
      "Failed to download {label} data",
      "i" = "URL: {url}",
      "x" = "HTTP status: {httr2::resp_status(resp)}"
    ))
  }

  writeBin(httr2::resp_body_raw(resp), dest)

  if (check_file(dest)) {
    cli::cli_abort(c(
      "Downloaded {label} file is empty",
      "i" = "URL: {url}"
    ))
  }
}

#' @keywords internal
#' @noRd
perform_request <- function(url) {
  httr2::request(url) |>
    httr2::req_error(is_error = function(resp) FALSE) |>
    httr2::req_user_agent(
      "imfweo R package (https://github.com/teal-insights/r-imfweo)"
    ) |>
    httr2::req_perform()
}

#' @keywords internal
#' @noRd
check_file <- function(file_path) {
  !file.exists(file_path) || file.size(file_path) == 0
}

#' Create WEO Download URL
#'
#' @keywords internal
#' @noRd
create_weo_url <- function(year, release, country_groups = FALSE) {
  base_url <- "https://www.imf.org/-/media/Files/Publications/WEO/WEO-Database"
  month <- ifelse(release == 1, "Apr", "Oct")
  month_long <- ifelse(release == 1, "April", "October")
  suffix <- ifelse(country_groups, "alla", "all")

  # New format since April 2024
  if (year >= 2024) {
    paste0(
      base_url,
      "/",
      year,
      "/",
      month_long,
      "/WEO",
      month,
      year,
      suffix,
      ".xls"
    )
  } else if (year >= 2021) {
    # Format from April 2021 to 2023
    paste0(base_url, "/", year, "/WEO", month, year, suffix, ".ashx")
  } else if (year >= 2020) {
    # Format from October 2020
    release_pad <- ifelse(
      release < 10,
      paste0("0", release),
      as.character(release)
    )
    paste0(
      base_url,
      "/",
      year,
      "/",
      release_pad,
      "/WEO",
      month,
      year,
      suffix,
      ".xls"
    )
  } else {
    # Earlier format
    paste0(base_url, "/", year, "/WEO", month, year, suffix, ".xls")
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

#' @keywords internal
#' @noRd
check_file <- function(file_path) {
  !file.exists(file_path) || file.size(file_path) == 0
}

#' Create WEO Download URL
#'
#' @keywords internal
#' @noRd
create_weo_url <- function(year, release, country_groups = FALSE) {
  base_url <- "https://www.imf.org/-/media/Files/Publications/WEO/WEO-Database"
  month <- ifelse(release == 1, "Apr", "Oct")
  month_long <- ifelse(release == 1, "April", "October")
  suffix <- ifelse(country_groups, "alla", "all")

  # New format since April 2024
  if (year >= 2024) {
    paste0(
      base_url,
      "/",
      year,
      "/",
      month_long,
      "/WEO",
      month,
      year,
      suffix,
      ".xls"
    )
  } else if (year >= 2021) {
    # Format from April 2021 to 2023
    paste0(base_url, "/", year, "/WEO", month, year, suffix, ".ashx")
  } else if (year >= 2020) {
    # Format from October 2020
    release_pad <- ifelse(
      release < 10,
      paste0("0", release),
      as.character(release)
    )
    paste0(
      base_url,
      "/",
      year,
      "/",
      release_pad,
      "/WEO",
      month,
      year,
      suffix,
      ".xls"
    )
  } else {
    # Earlier format
    paste0(base_url, "/", year, "/WEO", month, year, suffix, ".xls")
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
      name = "Country",
      id = "ISO",
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

#' Process WEO Country Group Data into Tidy Format
#'
#' @keywords internal
#' @noRd
process_weo_group_data <- function(raw_data) {
  required_cols <- c(
    "Country Group Name",
    "Subject Descriptor",
    "Units",
    "WEO Subject Code"
  )

  missing_cols <- setdiff(required_cols, names(raw_data))
  if (length(missing_cols) > 0) {
    cli::cli_abort(c(
      "Missing required columns in WEO group data:",
      missing_cols
    ))
  }

  year_cols <- names(raw_data)[grep("^\\d{4}$", names(raw_data))]
  if (length(year_cols) == 0) {
    cli::cli_abort("No year columns found in group data")
  }

  clean_data <- raw_data |>
    dplyr::transmute(
      name = .data$`Country Group Name`,
      id = .data$`WEO Country Group Code`,
      subject = .data$`Subject Descriptor`,
      units = .data$Units,
      series = .data$`WEO Subject Code`,
      dplyr::across(
        dplyr::all_of(year_cols),
        \(x) {
          if (is.character(x)) {
            suppressWarnings(readr::parse_number(x))
          } else {
            x
          }
        }
      )
    )

  long_data <- clean_data |>
    tidyr::pivot_longer(
      cols = dplyr::all_of(year_cols),
      names_to = "year",
      values_to = "value"
    ) |>
    dplyr::mutate(
      year = as.integer(.data$year),
      value = suppressWarnings(as.numeric(gsub(",", "", .data$value)))
    ) |>
    dplyr::filter(!is.na(.data$value))

  long_data
}
