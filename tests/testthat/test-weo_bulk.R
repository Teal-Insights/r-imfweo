test_that("weo_bulk errors when downloaded file is empty (via check_file)", {
  dummy_data <- charToRaw("dummy data")

  mock_resp <- function(req) {
    response(
      method = "GET",
      url = "https://fake.weo.test/test.xls",
      status_code = 200,
      body = dummy_data
    )
  }

  with_mocked_responses(mock_resp, {
    with_mocked_bindings(
      create_weo_url = function(...) "https://fake.weo.test/test.xls",
      check_file = function(path) TRUE,
      {
        expect_error(
          weo_bulk(2024, "Spring"),
          "file is empty"
        )
      }
    )
  })
})

test_that("download_weo handles req_perform error correctly", {
  with_mocked_bindings(
    perform_request = function(...) stop(),
    {
      expect_message(
        download_weo(
          url = "http://example.com/data.csv",
          dest = tempfile(),
          label = "test",
          quiet = TRUE
        )
      )
    }
  )
})


test_that("create_weo_url constructs correct URL for 2024+ format", {
  url <- create_weo_url(2024, 1)
  expect_match(url, "https://www.imf.org/.*/2024/April/WEOApr2024all.xls")

  url_fall <- create_weo_url(2025, 2)
  expect_match(
    url_fall,
    "https://www.imf.org/.*/2025/October/WEOOct2025all.xls"
  )
})

test_that("create_weo_url constructs correct URL for 2021-2023 format", {
  # These were served under .ashx until 2026, when the IMF retired those URLs
  url <- create_weo_url(2021, 1)
  expect_match(url, "https://www.imf.org/.*/2021/WEOApr2021all.xls")

  url_fall <- create_weo_url(2023, 2)
  expect_match(url_fall, "https://www.imf.org/.*/2023/WEOOct2023all.xls")

  url_groups <- create_weo_url(2022, 1, country_groups = TRUE)
  expect_match(url_groups, "https://www.imf.org/.*/2022/WEOApr2022alla.xls")

  expect_false(any(grepl("\\.ashx$", c(url, url_fall, url_groups))))
})

test_that("create_weo_url constructs correct URL for 2020 format", {
  url <- create_weo_url(2020, 2)
  expect_match(url, "https://www.imf.org/.*/2020/02/WEOOct2020all.xls")
})

test_that("create_weo_url constructs correct URL for 2020 release 1 format", {
  url <- create_weo_url(2020, 1)
  expect_match(url, "https://www.imf.org/.*/2020/WEOApr2020all.xls")
})

test_that("create_weo_url constructs correct URL for 2011 release 2 format", {
  url <- create_weo_url(2011, 2)
  expect_match(url, "https://www.imf.org/.*/2011/WEOSep2011all.xls")
})

test_that("create_weo_url constructs correct URL for pre-2020 format", {
  url <- create_weo_url(2019, 1)
  expect_match(url, "https://www.imf.org/.*/2019/WEOApr2019all.xls")

  url_fall <- create_weo_url(2018, 2)
  expect_match(url_fall, "https://www.imf.org/.*/2018/WEOOct2018all.xls")
})

test_that("process_weo_data works with valid WEO input", {
  raw <- tibble::tibble(
    Country = c("USA", "DEU"),
    ISO = c("USA", "DEU"),
    `Subject Descriptor` = c("GDP", "GDP"),
    Units = c("Billions", "Billions"),
    `WEO Subject Code` = c("NGDP", "NGDP"),
    `2020` = c("21,000", "4,000"),
    `2021` = c("22,000", "4,100"),
    stringsAsFactors = FALSE
  )

  result <- process_weo_data(raw)

  expect_s3_class(result, "data.frame")
  expect_equal(
    names(result),
    c("name", "id", "subject", "units", "series", "year", "value")
  )
  expect_equal(nrow(result), 4)
  expect_true(all(result$year %in% c(2020, 2021)))
  expect_type(result$value, "double")
})

test_that("process_weo_data errors when required columns are missing", {
  raw <- tibble::tibble(
    ISO = c("USA"),
    `Subject Descriptor` = c("GDP"),
    Units = c("Billions"),
    `WEO Subject Code` = c("NGDP"),
    `2020` = c("21,000")
  )

  expect_error(
    process_weo_data(raw),
    "Missing required columns"
  )
})

test_that("process_weo_data errors when no year columns are present", {
  raw <- tibble::tibble(
    Country = c("USA"),
    ISO = c("USA"),
    `Subject Descriptor` = c("GDP"),
    Units = c("Billions"),
    `WEO Subject Code` = c("NGDP")
  )

  expect_error(
    process_weo_data(raw),
    "No year columns found"
  )
})

test_that("process_weo_data drops non-numeric values", {
  raw <- tibble::tibble(
    Country = c("USA"),
    ISO = c("USA"),
    `Subject Descriptor` = c("GDP"),
    Units = c("Billions"),
    `WEO Subject Code` = c("NGDP"),
    `2020` = c("21,000"),
    `2021` = c("n/a"), # Should be dropped
    stringsAsFactors = FALSE
  )

  result <- process_weo_data(raw)

  expect_equal(nrow(result), 1)
  expect_equal(result$year, 2020)
})

test_that("read_weo_file reads a valid ISO-8859-1 file", {
  tmp <- withr::local_tempfile(fileext = ".txt")
  writeLines(
    "Country\tISO\tSubject Descriptor\t2020\t\nUSA\tUSA\tGDP\t21000\t\n",
    tmp
  )

  result <- read_weo_file(tmp)

  expect_s3_class(result, "data.frame")
  expect_true("Country" %in% names(result))
  expect_false(any(grepl("^col\\d+$", names(result))))
})

test_that("read_weo_file errors if file does not exist", {
  expect_error(
    read_weo_file("nonexistent-file.txt"),
    "File does not exist"
  )
})

test_that("read_weo_file removes all-NA columns and '...1' columns", {
  tmp <- withr::local_tempfile(fileext = ".txt")
  writeLines(
    "Country\tISO\tSubject Descriptor\t2020\t...61\t\nUSA\tUSA\tGDP\t21000\n",
    tmp
  )

  result <- read_weo_file(tmp)

  expect_false("...61" %in% names(result))
})

test_that("read_weo_file uses fallback encoding if needed", {
  tmp <- withr::local_tempfile(fileext = ".txt")

  # Simulate UTF-16LE encoded tab-delimited data
  content <- "Country\tISO\tSubject Descriptor\t2020\nUSA\tUSA\tGDP\t21000\n"
  encoded <- iconv(content, from = "UTF-8", to = "UTF-16LE", toRaw = TRUE)[[1]]

  writeBin(encoded, con = tmp)

  result <- read_weo_file(tmp)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 1)
  expect_true("Country" %in% names(result))
})

test_that("weo_bulk returns cached data if available", {
  .weo_cache$bulk <- data.frame(dummy = 1)
  .weo_cache$year <- 2024
  .weo_cache$release <- "Spring"

  result <- weo_bulk(2024, "Spring")
  expect_equal(result, .weo_cache$bulk)

  # Clean up
  .weo_cache$bulk <- NULL
  .weo_cache$year <- NULL
  .weo_cache$release <- NULL
})

test_that("weo_bulk handles valid mocked response", {
  path <- tempfile(fileext = ".xls")
  writeBin(charToRaw("dummy data"), path)

  mock_resp <- function(req) {
    response(
      method = "GET",
      url = "https://fake.weo.test/test.xls",
      status_code = 200,
      body = charToRaw("dummy data")
    )
  }

  with_mocked_responses(mock_resp, {
    result <- with_mocked_bindings(
      create_weo_url = function(...) "https://fake.weo.test/test.xls",
      download_weo = function(...) TRUE,
      read_weo_file = function(path) data.frame(Country = "USA"),
      process_weo_data = function(df) data.frame(Cleaned = TRUE),
      process_weo_group_data = function(df) data.frame(Cleaned = TRUE),
      {
        weo_bulk(2024, "Spring")
      }
    )

    expect_equal(result, data.frame(Cleaned = c(TRUE, TRUE)))
  })
})

test_that("weo_bulk errors on non-200 mocked response", {
  mock_resp <- function(req) {
    response(
      method = "GET",
      url = "https://fake.weo.test/test.xls",
      status_code = 404,
      body = charToRaw("Not Found")
    )
  }

  with_mocked_responses(mock_resp, {
    with_mocked_bindings(
      create_weo_url = function(...) "https://fake.weo.test/test.xls",
      {
        expect_message(weo_bulk(2024, "Fall"), "Failed to download")
      }
    )
  })
})

test_that("process_weo_group_data errors when required columns are missing", {
  incomplete_data <- data.frame(
    `Country Group Name` = "Group A",
    `Subject Descriptor` = "GDP",
    check.names = FALSE
  )

  expect_error(
    process_weo_group_data(incomplete_data),
    regexp = "Missing required columns"
  )
})

test_that("process_weo_group_data errors when no year columns are found", {
  data_no_years <- data.frame(
    `Country Group Name` = "Group A",
    `Subject Descriptor` = "GDP",
    `Units` = "USD",
    `WEO Subject Code` = "NGDP",
    check.names = FALSE
  )

  expect_error(
    process_weo_group_data(data_no_years),
    regexp = "No year columns found"
  )
})

test_that("process_weo_group_data correctly tidies numeric year cols", {
  sample_data <- data.frame(
    `Country Group Name` = c("Group A", "Group B"),
    `Subject Descriptor` = c("GDP", "Inflation"),
    `Units` = c("USD", "Percent"),
    `WEO Subject Code` = c("NGDP", "PCPIPCH"),
    `WEO Country Group Code` = c("001", "002"),
    `2020` = c("1,000", "2.5"),
    `2021` = c("1,200", "3.0"),
    check.names = FALSE
  )

  result <- process_weo_group_data(sample_data)

  expect_s3_class(result, "data.frame")
  expect_named(
    result,
    c("name", "id", "subject", "units", "series", "year", "value")
  )
  expect_equal(nrow(result), 4)
  expect_type(result$year, "integer")
  expect_type(result$value, "double")
})

test_that("process_weo_group_data removes rows with NA values in year col", {
  data_with_na <- data.frame(
    `Country Group Name` = "Group A",
    `Subject Descriptor` = "GDP",
    `Units` = "USD",
    `WEO Subject Code` = "NGDP",
    `WEO Country Group Code` = "001",
    `2020` = "1,000",
    `2021` = NA,
    check.names = FALSE
  )

  result <- process_weo_group_data(data_with_na)
  expect_equal(nrow(result), 1)
  expect_equal(result$year, 2020)
})

test_that("process_weo_group_data handles numeric year values directly", {
  numeric_year_data <- data.frame(
    `Country Group Name` = "Group A",
    `Subject Descriptor` = "GDP",
    `Units` = "USD",
    `WEO Subject Code` = "NGDP",
    `WEO Country Group Code` = "001",
    `2020` = 1000,
    `2021` = 1200,
    check.names = FALSE
  )

  result <- process_weo_group_data(numeric_year_data)
  expect_equal(nrow(result), 2)
  expect_equal(result$value, c(1000, 1200))
})

test_that("weo_bulk handles empty response", {
  weo_cache_reset()
  withr::defer(weo_cache_reset())

  with_mocked_bindings(
    download_weo = function(...) NULL,
    {
      res <- weo_bulk(2024, "Spring")
      expect_equal(res, NULL)
    }
  )
})

test_that("weo_bulk errors for an unknown publication", {
  expect_error(
    weo_bulk(9999, "Spring"),
    "No known WEO publication"
  )
})

test_that("weo_bulk uses the portal path for portal releases", {
  with_mocked_bindings(
    weo_lookup_release = function(...) {
      list(layout = "portal", url = "https://fake.weo.test/test.xlsx")
    },
    weo_bulk_portal = function(url, quiet) data.frame(url = url),
    weo_bulk_legacy = function(...) stop("legacy path must not be used"),
    {
      weo_cache_reset()
      result <- weo_bulk(2025, "Fall")
      expect_equal(result$url, "https://fake.weo.test/test.xlsx")
      weo_cache_reset()
    }
  )
})

test_that("weo_bulk_portal returns NULL when the download fails", {
  with_mocked_bindings(
    download_weo = function(...) NULL,
    {
      expect_null(weo_bulk_portal("https://fake.weo.test/test.xlsx", TRUE))
    }
  )
})

test_that("process_weo_portal_data works with valid portal input", {
  raw <- tibble::tibble(
    COUNTRY = c("United States", "Germany"),
    `COUNTRY.ID` = c("USA", "DEU"),
    INDICATOR = c("GDP", "GDP"),
    UNIT = c("US dollar", "US dollar"),
    `INDICATOR.ID` = c("NGDPD", "NGDPD"),
    `2020` = c("21,000", "4,000"),
    `2021` = c("22,000", "n/a")
  )

  result <- process_weo_portal_data(raw)

  expect_s3_class(result, "data.frame")
  expect_named(
    result,
    c("name", "id", "subject", "units", "series", "year", "value")
  )
  # The "n/a" cell is dropped
  expect_equal(nrow(result), 3)
  expect_type(result$year, "integer")
  expect_type(result$value, "double")
  expect_equal(result$value[result$id == "DEU"], 4000)
})

test_that("process_weo_portal_data errors when required columns are missing", {
  raw <- tibble::tibble(
    `COUNTRY.ID` = "USA",
    INDICATOR = "GDP",
    UNIT = "US dollar",
    `INDICATOR.ID` = "NGDPD",
    `2020` = "21,000"
  )

  expect_error(
    process_weo_portal_data(raw),
    "Missing required columns"
  )
})

test_that("process_weo_portal_data errors when no year columns are present", {
  raw <- tibble::tibble(
    COUNTRY = "United States",
    `COUNTRY.ID` = "USA",
    INDICATOR = "GDP",
    UNIT = "US dollar",
    `INDICATOR.ID` = "NGDPD"
  )

  expect_error(
    process_weo_portal_data(raw),
    "No year columns found"
  )
})

test_that("apply_weo_group_codes maps portal group codes to legacy codes", {
  data <- tibble::tibble(
    name = c("World", "United States"),
    id = c("G001", "USA"),
    subject = "GDP",
    units = "US dollar",
    series = "NGDPD",
    year = 2020L,
    value = 1
  )
  group_codes <- tibble::tibble(id = "G001", id_legacy = "001")

  result <- apply_weo_group_codes(data, group_codes)

  expect_named(result, names(data))
  expect_equal(result$id, c("001", "USA"))
})

test_that("apply_weo_group_codes passes data through without a crosswalk", {
  data <- tibble::tibble(id = "G001")
  empty <- tibble::tibble(id = character(), id_legacy = character())

  expect_equal(apply_weo_group_codes(data, NULL), data)
  expect_equal(apply_weo_group_codes(data, empty), data)
})

test_that("is_html_body detects error pages but not data files", {
  expect_true(is_html_body(charToRaw("<HTML><HEAD>\n<TITLE>Access Denied")))
  expect_true(is_html_body(charToRaw("\n  <!DOCTYPE html>")))
  expect_false(is_html_body(charToRaw("Country\tISO\t2020\n")))
  expect_false(is_html_body(raw(0)))

  # UTF-16LE encoded data contains nuls, which rawToChar would reject
  utf16 <- iconv("Country\tISO\n", from = "UTF-8", to = "UTF-16LE",
                 toRaw = TRUE)[[1]]
  expect_false(is_html_body(utf16))
})

test_that("download_weo rejects an error page served with status 200", {
  mock_resp <- function(req) {
    response(
      method = "GET",
      url = "https://fake.weo.test/test.ashx",
      status_code = 200,
      body = charToRaw("<HTML><HEAD>\n<TITLE>Access Denied</TITLE>")
    )
  }

  dest <- withr::local_tempfile(fileext = ".xls")

  with_mocked_responses(mock_resp, {
    expect_message(
      res <- download_weo(
        "https://fake.weo.test/test.ashx", dest, "test", TRUE
      ),
      "returned a web page"
    )
    expect_null(res)
    expect_false(file.exists(dest))
  })
})

test_that("read_weo_workbook errors for a missing file or sheet", {
  expect_error(
    read_weo_workbook("nonexistent-file.xlsx", "Countries"),
    "File does not exist"
  )
})

test_that("check_file works correctly", {
  tmp_file <- tempfile()
  expect_true(check_file(tmp_file))
  file.create(tmp_file)
  expect_true(check_file(tmp_file))
  writeLines("some content", tmp_file)
  expect_false(check_file(tmp_file))
  unlink(tmp_file)
})
