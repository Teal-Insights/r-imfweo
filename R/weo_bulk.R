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
  }

  publication <- weo_lookup_release(year, release)

  full_data <- if (publication$layout == "portal") {
    weo_bulk_portal(publication$url, quiet)
  } else {
    weo_bulk_legacy(year, release, quiet)
  }

  if (is.null(full_data)) {
    return(invisible(NULL))
  }

  # Optionally cache
  .weo_cache$bulk <- full_data
  .weo_cache$year <- year
  .weo_cache$release <- release

  full_data
}

#' Download and Process a Legacy (www.imf.org) WEO Release
#'
#' Releases up to and including April 2025 are published as two tab-delimited
#' files, one for countries and one for country groups.
#'
#' @keywords internal
#' @noRd
weo_bulk_legacy <- function(year, release, quiet) {
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
  res1 <- download_weo(url_country, file_country, "WEO country", quiet)
  res2 <- download_weo(url_groups, file_groups, "WEO country groups", quiet)
  if (is.null(res1) || is.null(res2)) {
    return(NULL)
  }

  if (!quiet) {
    cli::cli_alert_info("Processing data...")
  }

  # Read and process both
  raw_country <- read_weo_file(file_country)
  data_country <- process_weo_data(raw_country)

  raw_group <- read_weo_file(file_groups)
  data_groups <- process_weo_group_data(raw_group)

  dplyr::bind_rows(data_country, data_groups)
}

#' Download and Process a Portal (data.imf.org) WEO Release
#'
#' Releases from October 2025 onwards are published as a single Excel workbook
#' that holds countries, country groups and commodity prices in separate
#' sheets.
#'
#' @keywords internal
#' @noRd
weo_bulk_portal <- function(url, quiet) {
  file_workbook <- tempfile(fileext = ".xlsx")
  on.exit(unlink(file_workbook))

  res <- download_weo(url, file_workbook, "WEO", quiet)
  if (is.null(res)) {
    return(NULL)
  }

  if (!quiet) {
    cli::cli_alert_info("Processing data...")
  }

  data <- weo_portal_sheets() |>
    lapply(function(sheet) {
      process_weo_portal_data(read_weo_workbook(file_workbook, sheet))
    }) |>
    dplyr::bind_rows()

  apply_weo_group_codes(data, read_weo_group_codes(file_workbook))
}

#' Sheets of a Portal Workbook That Hold Observations
#'
#' The legacy country group file also contained the commodity price series, so
#' all three sheets are needed to reproduce the legacy contents.
#'
#' @keywords internal
#' @noRd
weo_portal_sheets <- function() {
  c("Countries", "Country Groups", "Commodity Prices")
}

#' @keywords internal
#' @noRd
download_weo <- function(url, dest, label, quiet) {
  if (!quiet) {
    cli::cli_alert_info("Downloading {label} data...")
  }

  resp <- tryCatch(
    perform_request(url),
    error = function(e) {
      cli::cli_alert_warning(
        paste(
          "Failed to retrieve data from the WEO Database.",
          "Error message: {conditionMessage(e)}"
        ),
        wrap = TRUE
      )
      invisible(NULL)
    }
  )

  if (is.null(resp)) {
    return(invisible(NULL))
  }

  if (httr2::resp_status(resp) != 200) {
    cli::cli_alert_warning(
      paste(
        "Failed to download {label} data.",
        "URL: {url}.",
        "HTTP status: {httr2::resp_status(resp)}."
      ),
      wrap = TRUE
    )
    return(invisible(NULL))
  }

  body <- httr2::resp_body_raw(resp)

  # Some retired URLs answer with an error page under a 200 status, which would
  # otherwise be parsed as if it were data.
  if (is_html_body(body)) {
    cli::cli_alert_warning(
      paste(
        "Failed to download {label} data.",
        "URL: {url}.",
        "The server returned a web page instead of a data file."
      ),
      wrap = TRUE
    )
    return(invisible(NULL))
  }

  writeBin(body, dest)

  if (check_file(dest)) {
    cli::cli_abort(c(
      "Downloaded {label} file is empty",
      "i" = "URL: {url}"
    ))
  }

  invisible(TRUE) #nocov
}

#' Detect an HTML Error Page in a Downloaded Body
#'
#' @keywords internal
#' @noRd
is_html_body <- function(body) {
  if (length(body) == 0) {
    return(FALSE)
  }

  start <- body[seq_len(min(512L, length(body)))]
  # UTF-16 encoded WEO files are full of nuls, which rawToChar rejects
  start <- start[start != as.raw(0)]

  if (length(start) == 0) {
    return(FALSE)
  }

  # Binary workbooks are not valid text in any encoding, so the comparison has
  # to stay on the bytes to avoid translation warnings
  text <- rawToChar(start)
  Encoding(text) <- "bytes"

  grepl(
    "^[[:space:]]*<(!doctype|html)",
    text,
    ignore.case = TRUE,
    useBytes = TRUE
  )
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
#' Only used for legacy releases, i.e. up to and including April 2025. Later
#' releases carry an opaque per-vintage GUID and are looked up in
#' `weo_releases()` instead.
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
  } else if (year == 2020 && release == 2) {
    # Special case: October 2020 is nested under the release number
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
  } else if (year == 2011 && release == 2) {
    # Special case: the 2011 fall release was published in September
    paste0(base_url, "/", year, "/WEO", "Sep", year, suffix, ".xls")
  } else {
    # Everything else, including 2021-2023, which used to be served under
    # .ashx but is now only reachable as .xls
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

#' Read a Sheet of a Portal WEO Workbook
#'
#' Everything is read as text so that the numeric parsing below matches the
#' legacy code path.
#'
#' @keywords internal
#' @noRd
read_weo_workbook <- function(file_path, sheet) {
  if (!file.exists(file_path)) {
    cli::cli_abort(c("x" = "File does not exist: {file_path}"))
  }

  sheets <- readxl::excel_sheets(file_path)
  if (!sheet %in% sheets) {
    cli::cli_abort(c(
      "x" = "Sheet {.val {sheet}} not found in the WEO workbook.",
      "i" = "Available sheets: {.val {sheets}}."
    ))
  }

  suppressWarnings(
    readxl::read_excel(file_path, sheet = sheet, col_types = "text")
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
      values_to = "value",
      values_transform = list(value = as.character)
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

#' Process a Portal WEO Sheet into Tidy Format
#'
#' The IMF Data portal renames the identifying columns: `Country` becomes
#' `COUNTRY` (also used for country group and commodity labels), `ISO` and
#' `WEO Country Group Code` become `COUNTRY.ID`, `Subject Descriptor` becomes
#' `INDICATOR`, `Units` becomes `UNIT` and `WEO Subject Code` becomes
#' `INDICATOR.ID`. Year columns are unchanged.
#'
#' @keywords internal
#' @noRd
process_weo_portal_data <- function(raw_data) {
  required_cols <- c(
    "COUNTRY",
    "COUNTRY.ID",
    "INDICATOR",
    "UNIT",
    "INDICATOR.ID"
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

  raw_data |>
    dplyr::select(
      name = "COUNTRY",
      id = "COUNTRY.ID",
      subject = "INDICATOR",
      units = "UNIT",
      series = "INDICATOR.ID",
      dplyr::all_of(year_cols)
    ) |>
    tidyr::pivot_longer(
      cols = dplyr::all_of(year_cols),
      names_to = "year",
      values_to = "value",
      values_transform = list(value = as.character)
    ) |>
    dplyr::mutate(
      year = as.integer(.data$year),
      value = suppressWarnings(as.numeric(gsub(",", "", .data$value)))
    ) |>
    dplyr::filter(!is.na(.data$value))
}

#' Read the Country Group Code Crosswalk From a Portal Workbook
#'
#' The portal renumbered the country groups (e.g. `001` became `G001`). The
#' workbook ships the IMF's own mapping back to the legacy codes, which keeps
#' entity IDs comparable across vintages.
#'
#' @keywords internal
#' @noRd
read_weo_group_codes <- function(file_path) {
  sheet <- "Country Group Composition"

  if (!sheet %in% readxl::excel_sheets(file_path)) {
    return(NULL)
  }

  raw_data <- read_weo_workbook(file_path, sheet)

  required_cols <- c("groupcode", "groupcode_previous")
  if (!all(required_cols %in% names(raw_data))) {
    return(NULL)
  }

  raw_data |>
    dplyr::distinct(
      id = .data$groupcode,
      id_legacy = .data$groupcode_previous
    ) |>
    dplyr::filter(!is.na(.data$id), !is.na(.data$id_legacy))
}

#' Map Portal Country Group Codes Back to Their Legacy Codes
#'
#' @keywords internal
#' @noRd
apply_weo_group_codes <- function(data, group_codes) {
  if (is.null(group_codes) || nrow(group_codes) == 0) {
    return(data)
  }

  data |>
    dplyr::left_join(group_codes, by = "id") |>
    dplyr::mutate(id = dplyr::coalesce(.data$id_legacy, .data$id)) |>
    dplyr::select(-"id_legacy")
}
