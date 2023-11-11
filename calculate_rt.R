# Script for calculating the reaction times based on Sidney's time-to-target measurements.

# Set up directories
dir_output <- "/Users/sidneyma/Desktop/school/lign199/" # Where final csv should end up
dir_new_data <- "/Users/sidneyma/Desktop/school/lign199/New data/" # Name of folder with all participant data
path_durations <- "/Users/sidneyma/Desktop/school/lign199/durations_updated.csv" # Filename for durations_updated.csv

# Load tidyverse
library(tidyverse)

#### Part 1 - Cleaning and organizing participant data into one table

# Function to read in the relevant columns from a participant data sheet
get_df <- function(filename) {
  relevant_cols <- c('word1', 'word2', 'target', 'voicequality', 'speaker', 
                     'time_to_target', 'response', 'audio', 'file',
                     'category', 'key_resp.keys', 'key_resp.corr',
                     'key_resp.rt', 'participant', 'date')
  df <- read.csv(filename)[,relevant_cols]
  df <- df[!is.na(df$key_resp.corr),]
  return(df)
}

# Apply this function to all participants in the "New Data" folder
filenames <- list.files(dir_new_data, full.names = TRUE)
print(filenames)
dfs <- lapply(filenames, get_df)
big_df <- bind_rows(dfs) |>
  arrange(participant)

# Set up voice quality columns
big_df$vq1 <- ifelse(is.na(big_df$voicequality), NA, substr(big_df$voicequality, 1, 1))
big_df$vq2 <- ifelse(is.na(big_df$voicequality), NA, substr(big_df$voicequality, 3, 3))

#Set up reaction time column (based on Maxine's time-to-targets)
big_df$reaction_time <- big_df$key_resp.rt - big_df$time_to_target
big_df <- big_df |>
  select(-time_to_target) |>
  rename(ppt_response = key_resp.keys, correct = key_resp.corr)

# Fix date column
big_df$date <- sapply(strsplit(big_df$date, "_"), `[`, 1)

# Reorder columns
reorder_cols <- c('category', 'word1', 'word2', 'target', 'ppt_response', 
                  'voicequality', 'vq1', 'vq2', 'correct', 'reaction_time', 
                  'key_resp.rt', 'speaker', 'audio', 'file', 'participant', 
                  'date')
big_df <- big_df[, reorder_cols]

# Add index column
big_df <- big_df |>
  mutate(index = row_number()) |>
  select(index, everything())

# Rename as ppt_data
ppt_data <- big_df

#### Part 2 - adding reaction times based on durations_updated.csv

# Read in durations_updated.csv
durations <- read_csv(path_durations)

# Make sure the columns and values are usable
durations$file <- paste0(durations$file, ".wav")
durations <- durations |> rename(ttt_sidney = time_to_target)
durations$ttt_sidney <- as.numeric(gsub("[^0-9.]", "", durations$ttt_sidney))

# Join the durations data into ppt_data
ppt_data <- left_join(ppt_data, durations, by = "file")

# For attention-check trials, set the time-to-target to none
ppt_data <- ppt_data |>
  mutate(ttt_sidney = ifelse(category == "attention", NA, ttt_sidney))

# When the distinction is between "gate" and "gape", add 0.2 seconds to the time-to-target
ppt_data <- ppt_data |>
  mutate(ttt_sidney = ifelse(word1 == "gape" | word2 == "gape", 
                             ttt_sidney + 0.2, ttt_sidney))

# Calculate the reaction time based on Sidney's data
ppt_data$rt_sidney <- with(ppt_data, key_resp.rt - ttt_sidney)

# Round reaction time columns
ppt_data$reaction_time <- round(ppt_data$reaction_time, digits = 3)
ppt_data$rt_sidney <- round(ppt_data$rt_sidney, digits = 3)

# Reorder columns
reorder_cols <- c('index', 'category', 'word1', 'word2', 'target', 
                  'ppt_response', 'voicequality', 'vq1', 'vq2', 'correct', 
                  'reaction_time', 'rt_sidney', 'speaker', 'audio', 'file', 
                  'participant', 'date')
ppt_data <- ppt_data[, reorder_cols]

# Write to csv file
ppt_data |> write_csv(paste0(dir_output, "ppt_data.csv"))