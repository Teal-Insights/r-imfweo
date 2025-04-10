test_that("validate_publication handles valid and invalid inputs correctly", {
    # Valid case
    valid_pub <- list(year = 2023, release = "April")
    expect_no_error(validate_publication(valid_pub))

    # Missing year
    invalid_pub1 <- list(release = "April")
    expect_error(
        validate_publication(invalid_pub1),
        "`publication` must have non-null 'year' and 'release'",
        fixed = TRUE
    )

    # Missing release
    invalid_pub2 <- list(year = 2023)
    expect_error(
        validate_publication(invalid_pub2),
        "`publication` must have non-null 'year' and 'release'",
        fixed = TRUE
    )

    # Both missing
    invalid_pub3 <- list()
    expect_error(
        validate_publication(invalid_pub3),
        "`publication` must have non-null 'year' and 'release'",
        fixed = TRUE
    )
})

test_that("validate_year handles valid and invalid inputs correctly", {
    # Valid cases
    expect_no_error(validate_year(2023))
    expect_no_error(validate_year(2023.5))

    # Invalid cases
    expect_error(
        validate_year("2023"),
        "`year` must be numeric",
        fixed = TRUE
    )

    expect_error(
        validate_year(list(2023)),
        "`year` must be numeric",
        fixed = TRUE
    )

    expect_error(
        validate_year(TRUE),
        "`year` must be numeric",
        fixed = TRUE
    )
})

test_that("validate_years handles valid and invalid inputs correctly", {
    # Valid cases
    expect_no_error(validate_years(2022, 2023))
    expect_no_error(validate_years(2000, 2100))

    # Non-numeric start_year
    expect_error(
        validate_years("2022", 2023),
        "`start_year` and `end_year` must be numeric",
        fixed = TRUE
    )

    # Non-numeric end_year
    expect_error(
        validate_years(2022, "2023"),
        "`start_year` and `end_year` must be numeric",
        fixed = TRUE
    )

    # Both non-numeric
    expect_error(
        validate_years("2022", "2023"),
        "`start_year` and `end_year` must be numeric",
        fixed = TRUE
    )

    # start_year > end_year
    expect_error(
        validate_years(2024, 2023),
        "`start_year` must be smaller than `end_year`",
        fixed = TRUE
    )
})

test_that("resolve_publication handles various input combinations", {
    # Mock weo_get_latest_publication using with_mocked_bindings
    with_mocked_bindings(
        weo_get_latest_publication = function()
            list(year = 2023, release = "October"),
        {
            # Case 1: Both year and release provided
            result1 <- resolve_publication(year = 2022, release = "April")
            expect_equal(result1, list(year = 2022, release = "April"))

            # Case 2: Neither year nor release provided (should use latest)
            result2 <- resolve_publication()
            expect_equal(result2, list(year = 2023, release = "October"))

            # Case 3: Only year provided (invalid, but function still passes it through)
            expect_error(
                resolve_publication(year = 2022),
                "`publication` must have non-null 'year' and 'release'",
                fixed = TRUE
            )

            # Case 4: Only release provided (invalid, but function still passes it through)
            expect_error(
                resolve_publication(release = "April"),
                "`publication` must have non-null 'year' and 'release'",
                fixed = TRUE
            )
        }
    )
})
