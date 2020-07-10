library(testthat)
library(assertthat)

context("missingReportables tests")

source("./demo.R", chdir = T)

setup({
  prod_df <- read_parquet("../data/test_sas_file.parquet") 
  colnames(prod_df) <- toupper(colnames(prod_df)) 
  prod_df <- prod_df %>% rename(`Visit Name` = `VISJEDI`)
  a450 <<- missingReportables(prod_df, "a450")
})

test_that("number of columns in before", {
  expect_equal(ncol(a450), 10)
})

test_that("name of columns in before", {
  expected_colnames <- c("LBTESTCD", "LBTEST", "ACCSNNUM", "RCVDTM", "LBSPEC",
                         "Visit Name", "BATTRNAM", "LBDTM", "TSTSTAT",
                         "Test Date" )
  expect_true(all(colnames(a450) %in%  expected_colnames))
})


