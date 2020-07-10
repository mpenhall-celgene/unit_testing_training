library(tidyverse)
library(readr)
library(arrow)
library(readxl)

double_gate_codes <- read_excel("../data/H125_A450_DoubleGate_codes.xlsx")
A355_codes <- read_excel("../data/H125_Reportables_codes.xlsx", sheet=1)
A450_codes <- read_excel("../data/H125_Reportables_codes.xlsx", sheet=2)
A452_codes <- read_excel("../data/H125_Reportables_codes.xlsx", sheet=3)

summary_Df <- data.frame(ACCSNNUM=character(),Visit=character(),`Test Date`=character(),Sample=character(),Issue=character(),Count=integer())
names(summary_Df) <- gsub("\\.", " ", names(summary_Df))
doubleGate <- function(ds){
  output_df <- NULL
  output_df2 <- NULL
  out2 <- list()
  # Only the A450 panel undergoes double positive gating
  a450samps <- filter(ds, grepl("A450", BATTRNAM))
  for(num in unique(a450samps$ACCSNNUM)){
    df_subset <- a450samps[which(a450samps$ACCSNNUM == num & a450samps$TSTSTAT == "D"),] %>% select(ACCSNNUM, `Visit Name`, BATTRNAM, RCVDTM, LBDTM, LBSPEC, LBTESTCD, LBTEST, TSTSTAT)
    # Add a new column that provides the date in YYYY-MM-DD format
    df_subset$`Test Date` <- sapply(strsplit(df_subset$LBDTM, "T"), "[", 1)
    beforeDoubPos <- df_subset[df_subset$`Test Date` < "2019-06-17", ]
    afterDoubPos <- df_subset[df_subset$`Test Date` >= "2019-06-17", ]
    if(!(is.null(beforeDoubPos))){
      if(any(beforeDoubPos$LBTESTCD %in% double_gate_codes$Code)){
        print(paste0(num, " : ", df_subset$`Test Date`))
        # These samples were reported as DoublePos despite being tested prior to 6-18-2019
        mislabeledSamps <- beforeDoubPos[which(beforeDoubPos$LBTESTCD %in% double_gate_codes$Code & beforeDoubPos$TSTSTAT == "D"),]
        mislabeledSamps$RCVDTM <- mislabeledSamps$LBDTM
        output_df <- rbind(output_df, mislabeledSamps)
        tryCatch({
          writeData(wb = out, sheet = "Unexpected Double+ Samples", output_df)
        }, error = function(err){
          addWorksheet(wb = out, sheetName = "Unexpected Double+ Samples")
          writeData(wb = out, sheet = "Unexpected Double+ Samples", output_df)
        })
      }
    }
    if(nrow(afterDoubPos) != 0){
      matrix_assay <- unique(afterDoubPos$LBSPEC)
      subDoubPos <- double_gate_codes %>% filter(Matrix %in% matrix_assay)
      if(!(all(subDoubPos$Code %in% afterDoubPos$LBTESTCD))){
        # There are Double+ samples that aren't reported
        missingReportables <- subDoubPos[which(!(subDoubPos$Code %in% afterDoubPos$LBTESTCD)),] %>% select(-c(Unit,Matrix))
        missingReportables['ACCSNNUM'] <- num
        missingReportables['RCVDTM'] <- unique(afterDoubPos$RCVDTM)
        missingReportables['LBSPEC'] <- unique(afterDoubPos$LBSPEC)
        missingReportables['Visit Name'] <- unique(afterDoubPos$`Visit Name`)
        missingReportables['BATTRNAM'] <- unique(afterDoubPos$BATTRNAM)
        missingReportables['LBDTM'] <- unique(afterDoubPos$LBDTM)
        missingReportables['TSTSTAT'] <- "Not Recorded"
        missingReportables['Test Date'] <- unique(afterDoubPos$`Test Date`)
        missingReportables <- missingReportables %>% rename(LBTESTCD=Code)
        missingReportables <- missingReportables %>% rename(LBTEST=`Reportable Population`)
        #missingReportables <- missingReportables[c("ACCSNNUM", "RCVDTM", "LBSPEC", "Visit Name", "Code", "Reportable Population", "Unit", "Matrix")]
        output_df2 <- rbind(output_df2, missingReportables)
      }
    }
  }
  if(is.null(output_df)){ out2$before <- "Empty"}else{out2$before <- output_df}
  if(is.null(output_df2)){ out2$after <- "Empty"}else{out2$after <- output_df2}
  return(out2)
}

#' A function run through the reportables on each panel
#' @param ds the input dataframe
#' @param assay of interest
#' @return a output dataframe
missingReportables <- function(ds, assay){
  if(assay == "A355"){
    codes <- A355_codes
  } else if(assay == "A450"){
    codes <- A450_codes
  } else{
    codes <- A452_codes
  }
  output_df <- NULL
  samples <- filter(ds[ds$TSTSTAT == "D",], grepl(assay, BATTRNAM))
  for(num in unique(samples$ACCSNNUM)){
    df_subset <- samples[samples$ACCSNNUM == num,] %>% select(ACCSNNUM, `Visit Name`, RCVDTM, BATTRNAM, LBDTM, LBSPEC, LBTESTCD, LBTEST, TSTSTAT)
    df_subset$`Test Date` <- sapply(strsplit(df_subset$LBDTM, "T"), "[", 1)
    if(!is.na(unique(df_subset$LBSPEC)) && df_subset$LBSPEC == "PB" && grepl("BMA", unique(df_subset$`Visit Name`))){matrix <- "BMA"}else{matrix <- unique(df_subset$LBSPEC)}
    if(assay == "A452"){
      subCodes = codes
    } else {
      subCodes <- codes[codes$Matrix == matrix,]
      }
    if(!(all(subCodes$Code %in% df_subset$LBTESTCD)) & !is.na(matrix)){
      #print("checkpoint 3")
      if(assay == "A452"){
        missing <- codes[which(!(subCodes$Code %in% df_subset$LBTESTCD)),] %>%
          select(-Unit)}else{missing <- codes[which(!(subCodes$Code %in% df_subset$LBTESTCD)),] %>%
            select(-c(Unit,Matrix))
          }
      if(assay == "A450" && nrow(missing) == 12){
        x <- "this is a test"
      } else {
        missing['ACCSNNUM'] <- num
        missing['RCVDTM'] <- unique(df_subset$RCVDTM)
        missing['LBSPEC'] <- unique(df_subset$LBSPEC)
        missing['Visit Name'] <- unique(df_subset$`Visit Name`)
        missing['BATTRNAM'] <- unique(df_subset$BATTRNAM)
        missing['LBDTM'] <- unique(df_subset$LBDTM)
        missing['TSTSTAT'] <- "Not Recorded"
        missing['Test Date'] <- unique(df_subset$`Test Date`)
        missing <- missing %>% rename(LBTESTCD=Code)
        missing <- missing %>% rename(LBTEST=`Reportable Population`)
        output_df <- rbind(output_df, missing)
        msg <- paste0("Missing ", assay, " Reportables")
      }
    }
  }
  return(output_df)
}