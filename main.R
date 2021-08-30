library(tercen)
library(dplyr)
library(tools)
library(tidyr)

# loads an RData file, and returns it
loadRData <- function(fileName) {
  load(fileName)
  get(ls()[ls() != "fileName"])
}

cube_to_data = function(filename, separateQT) {
  data <- try(loadRData(filename), silent = TRUE)
  
  if (class(data) == "try-error") {
    stop("File can't be loaded, please check that it's available and it has the right format (Rdata).")
  }
  
  data <- data %>%
    select(-c(rowSeq, colSeq)) 
  
  if (separateQT) {
    data <- data %>% 
      pivot_wider(names_from = "QuantitationType", values_from = "value") 
  }
  
  data %>%
    select(-sids) %>%
    mutate_if(is.logical, as.character) %>%
    mutate_if(is.integer, as.double) %>%
    mutate(.ci = rep_len(0, nrow(.))) %>%
    mutate(filename = rep_len(basename(filename), nrow(.)))
}

ctx = tercenCtx()

if (!any(ctx$cnames == "documentId")) stop("Column factor documentId is required")

# properties
separateQT <- ifelse(is.null(ctx$op.value('separateQT')), TRUE, as.logical(ctx$op.value('separateQT')))

# extract files
df <- ctx$cselect()

docId = df$documentId[1]
doc = ctx$client$fileService$get(docId)
filename = tempfile()
writeBin(ctx$client$fileService$download(docId), filename)
on.exit(unlink(filename))

# unzip if archive
if (length(grep(".zip", doc$name)) > 0) {
  tmpdir <- tempfile()
  unzip(filename, exdir = tmpdir)
  f.names <- list.files(tmpdir, full.names = TRUE)
} else {
  f.names <- filename
}

assign("actual", 0, envir = .GlobalEnv)
task = ctx$task

# import files in Tercen
f.names %>%
  lapply(function(filename){
    data = cube_to_data(filename, separateQT)
    if (!is.null(task)) {
      # task is null when run from RStudio
      actual = get("actual",  envir = .GlobalEnv) + 1
      assign("actual", actual, envir = .GlobalEnv)
      evt = TaskProgressEvent$new()
      evt$taskId = task$id
      evt$total = length(f.names)
      evt$actual = actual
      evt$message = paste0('processing Cube file ' , filename)
      ctx$client$eventService$sendChannel(task$channelId, evt)
    } else {
      cat('processing Cube file ' , filename)
    }
    data
  }) %>%
  bind_rows() %>%
  ctx$addNamespace() %>%
  ctx$save()
