rm(list=ls())
args = commandArgs(trailingOnly=TRUE)
#options(warn=-1)
library(data.table)
library(xlsx)
library(dplyr)
library(readxl)
library(openxlsx)
library(sqldf)
library(BTYD)
library(BTYDplus)
library(bbmle)
library(hypergeo)
#options(warn=0)

##### this is the path to the Input files

ProcessStartTime <- Sys.time()

# insert your local input path
inputPath <<- ""

# insert your local output path
outputPath <<- ""

# insert your local codeBase path
codeBasePath <<- ""

# set the length of predicted period
# years
pp <<- 1

# annual discount - business setting
disc <<- 0.1

# Read the input file
filename <- list.files(path = inputPath, pattern = "trans_input_clv" )
print(filename)
elog <- fread(paste0(inputPath, filename), header = TRUE)

# Run the bgbb process
source(paste0(codeBasePath, "bgbb_process.R"))

# Run the HML segmentation using kmeans clustering
source(paste0(codeBasePath, "Kmeans_clustering.R"))
