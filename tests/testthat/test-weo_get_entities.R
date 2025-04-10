test_that("weo_get_entities returns correct structure and content", {
    # Create mock data that weo_bulk would return
    mock_data <- tibble::tibble(
        series = c(
            "NGDP_RPCH",
            "NGDP_RPCH",
            "PCPIPCH",
            "PCPIPCH",
            "NGDP_RPCH",
            "PCPIPCH"
        ),
        subject = c(
            "Gross domestic product, constant prices",
            "Gross domestic product, constant prices",
            "Inflation, average consumer prices",
            "Inflation, average consumer prices",
            "Gross domestic product, constant prices",
            "Inflation, average consumer prices"
        ),
        units = c(
            "Percent change",
            "Percent change",
            "Percent change",
            "Percent change",
            "Percent change",
            "Percent change"
        ),
        country = c(
            "United States",
            "Germany",
            "United States",
            "Germany",
            "European Union",
            "European Union"
        ),
        iso = c("USA", "DEU", "USA", "DEU", "EUU", "EUU"),
        year = c(2022, 2022, 2022, 2022, 2022, 2022),
        value = c(2.1, 1.8, 8.0, 7.9, 3.5, 7.0)
    )

    # Expected output after transformation
    expected_output <- tibble::tibble(
        entity_id = c("EUU", "DEU", "USA"),
        entity_name = c("European Union", "Germany", "United States")
    )

    # Test with default parameters (using latest publication)
    with_mocked_bindings(
        resolve_publication = function(year, release) {
            list(year = 2023, release = "Fall")
        },
        weo_bulk = function(year, release, quiet) {
            expect_equal(year, 2023)
            expect_equal(release, "Fall")
            expect_true(quiet)
            mock_data
        },
        {
            # Call the function
            result <- weo_get_entities()

            # Check structure
            expect_s3_class(result, "tbl_df")
            expect_named(result, c("entity_id", "entity_name"))

            # Check content
            expect_equal(result, expected_output)
        }
    )
})

test_that("weo_get_entities handles custom year and release parameters", {
    # Create mock data
    mock_data <- tibble::tibble(
        series = c("NGDP", "NGDP", "PCPI", "PCPI"),
        subject = rep("Some subject", 4),
        units = rep("Some units", 4),
        country = c("Japan", "Canada", "Japan", "Canada"),
        iso = c("JPN", "CAN", "JPN", "CAN"),
        year = rep(2021, 4),
        value = c(1, 2, 3, 4)
    )

    # Expected output
    expected_output <- tibble::tibble(
        entity_id = c("CAN", "JPN"),
        entity_name = c("Canada", "Japan")
    )

    # Test with custom parameters
    with_mocked_bindings(
        resolve_publication = function(year, release) {
            expect_equal(year, 2021)
            expect_equal(release, "Spring")
            list(year = 2021, release = "Spring")
        },
        weo_bulk = function(year, release, quiet) {
            expect_equal(year, 2021)
            expect_equal(release, "Spring")
            expect_false(quiet)
            mock_data
        },
        {
            # Call the function with custom parameters
            result <- weo_get_entities(
                year = 2021,
                release = "Spring",
                quiet = FALSE
            )

            # Check output
            expect_equal(result, expected_output)
        }
    )
})

test_that("weo_get_entities handles rows with NA entity_id", {
    # Create mock data with some NA values
    mock_data <- tibble::tibble(
        series = c("NGDP", "NGDP", "NGDP"),
        subject = rep("Some subject", 3),
        units = rep("Some units", 3),
        country = c("United States", "World", "Euro Area"),
        iso = c("USA", NA, "EUR"),
        year = rep(2022, 3),
        value = c(1, 2, 3)
    )

    # Expected output - should filter out the NA value
    expected_output <- tibble::tibble(
        entity_id = c("EUR", "USA"),
        entity_name = c("Euro Area", "United States")
    )

    # Test filtering of NA values
    with_mocked_bindings(
        resolve_publication = function(year, release) {
            list(year = 2022, release = "Fall")
        },
        weo_bulk = function(year, release, quiet) {
            mock_data
        },
        {
            # Call the function
            result <- weo_get_entities()

            # Check NA filtering
            expect_false(any(is.na(result$entity_id)))
            expect_equal(nrow(result), 2)
            expect_equal(result, expected_output)
        }
    )
})

test_that("weo_get_entities handles empty dataset gracefully", {
    # Create empty mock data
    empty_data <- tibble::tibble(
        series = character(0),
        subject = character(0),
        units = character(0),
        country = character(0),
        iso = character(0),
        year = integer(0),
        value = numeric(0)
    )

    # Expected empty output
    expected_empty <- tibble::tibble(
        entity_id = character(0),
        entity_name = character(0)
    )

    # Test with empty data
    with_mocked_bindings(
        resolve_publication = function(year, release) {
            list(year = 2023, release = "Fall")
        },
        weo_bulk = function(year, release, quiet) {
            empty_data
        },
        {
            # Call the function
            result <- weo_get_entities()

            # Check structure is maintained even when empty
            expect_s3_class(result, "tbl_df")
            expect_named(result, c("entity_id", "entity_name"))
            expect_equal(nrow(result), 0)
            expect_equal(result, expected_empty)
        }
    )
})

test_that("weo_get_entities correctly sorts output by entity name", {
    # Create unsorted mock data
    mock_data <- tibble::tibble(
        series = rep("NGDP", 4),
        subject = rep("Some subject", 4),
        units = rep("Some units", 4),
        country = c("United States", "Germany", "Albania", "Japan"),
        iso = c("USA", "DEU", "ALB", "JPN"),
        year = rep(2022, 4),
        value = 1:4
    )

    # Expected output should be sorted by entity_name
    expected_output <- tibble::tibble(
        entity_id = c("ALB", "DEU", "JPN", "USA"),
        entity_name = c("Albania", "Germany", "Japan", "United States")
    )

    # Test sorting
    with_mocked_bindings(
        resolve_publication = function(year, release) {
            list(year = 2023, release = "Fall")
        },
        weo_bulk = function(year, release, quiet) {
            mock_data
        },
        {
            # Call the function
            result <- weo_get_entities()

            # Check sorting
            expect_equal(result, expected_output)
            expect_equal(result$entity_name, sort(unique(mock_data$country)))
        }
    )
})
