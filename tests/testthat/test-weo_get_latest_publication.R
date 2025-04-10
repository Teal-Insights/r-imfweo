test_that("weo_get_latest_publication returns cached result when available", {
    # Set up and ensure cleanup
    withr::local_options(list(weo.cache = TRUE))

    # Backup existing cache if any
    original_cache <- .weo_cache$latest_publication

    # Cleanup function to restore original state
    withr::defer({
        if (is.null(original_cache)) {
            .weo_cache$latest_publication <- NULL
        } else {
            .weo_cache$latest_publication <- original_cache
        }
    })

    # Set a mock cached value
    .weo_cache$latest_publication <- list(year = 2023, release = "Fall")

    # Function should return cached value without making any requests
    result <- weo_get_latest_publication()

    # Check result
    expect_equal(result, list(year = 2023, release = "Fall"))
})
