test_that("create_weo_url constructs correct URL for 2024+ format", {
  url <- create_weo_url(2024, 1)
  expect_match(url, "https://www.imf.org/.*/2024/April/WEOApr2024all.xls")

  url_fall <- create_weo_url(2025, 2)
  expect_match(
    url_fall,
    "https://www.imf.org/.*/2025/October/WEOOct2025all.xls"
  )
})

test_that("create_weo_url constructs correct URL for 2021–2023 format", {
  url <- create_weo_url(2021, 1)
  expect_match(url, "https://www.imf.org/.*/2021/WEOApr2021all.ashx")

  url_fall <- create_weo_url(2023, 2)
  expect_match(url_fall, "https://www.imf.org/.*/2023/WEOOct2023all.ashx")
})

test_that("create_weo_url constructs correct URL for 2020 format", {
  url <- create_weo_url(2020, 2)
  expect_match(url, "https://www.imf.org/.*/2020/02/WEOOct2020all.xls")
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
    withr::local_options(list(weo_test_url = "https://fake.weo.test/test.xls"))

    # patch create_weo_url to use test URL
    result <- with_mocked_bindings(
      create_weo_url = function(...) getOption("weo_test_url"),
      read_weo_file = function(path) data.frame(Country = "USA"),
      process_weo_data = function(df) data.frame(Cleaned = TRUE),
      {
        weo_bulk(2024, "Spring")
      }
    )

    expect_equal(result, data.frame(Cleaned = c(TRUE)))
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
        expect_error(weo_bulk(2024, "Fall"), "HTTP status: 404")
      }
    )
  })
})

test_that("weo_bulk errors when request throws exception", {
  mock_resp <- function(req) {
    stop("Network failure")
  }

  with_mocked_responses(mock_resp, {
    with_mocked_bindings(
      create_weo_url = function(...) "https://fake.weo.test/test.xls",
      {
        expect_error(
          weo_bulk(2024, "Spring"),
          regexp = "Error: Network failure"
        )
      }
    )
  })
})

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

test_that("weo_bulk errors if read_weo_file or process_weo_data fails", {
  mock_resp <- function(req) {
    response(
      method = "GET",
      url = "https://fake.weo.test/test.xls",
      status_code = 200,
      body = charToRaw("dummy data")
    )
  }

  with_mocked_responses(mock_resp, {
    with_mocked_bindings(
      create_weo_url = function(...) "https://fake.weo.test/test.xls",
      read_weo_file = function(path) stop("Failed to read Excel"),
      process_weo_data = function(df) df,
      {
        expect_error(
          weo_bulk(2024, "Spring"),
          "Failed to process"
        )
      }
    )
  })
})
