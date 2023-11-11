# Script for cleaning and setting up the participant data

#------------------------------

# Saves dataset as "ppt_data.csv", which stacks all participant data
# For our analysis, we're going to include many columns:

# participant (number)
# date
# category (of trial): target, filler, or attention
# speaker (of audio)
# voicequality (of sentence and of target): m_m, m_c, m_g, c_m, c_c, or c_g
# vq1 (voice quality of sentence)
# vq2 (voice quality of target)
# word1
# word2
# target (correct answer)
# target_at_onset (whether the target phoneme is at the onset of the target word): 0 or 1
# ppt_response: left or right
# correct (whether ppt answered correctly): 0 or 1
# response_time
# time_to_target
# rt_maxine (based on Maxine's time-to-targets)
# rt_sidney (reaction time based on Sidney's time-to-targets)
# reaction_time (rt_maxine, and rt_sidney to fill in missing data)
# log_rt (log reaction time)
# audio (full pathname)
# file (basename)

#------------------------------

#### Organize dataset from data folder

# Set up directories
dir_new_data <- "data/New data/" # Name of folder with all participant data sheets
path_durations <- "data/durations_updated.csv" # Filename for durations_updated.csv

# Load tidyverse
library(tidyverse)

# Function to read in the relevant columns from a participant data sheet
get_df <- function(filename) {
  relevant_cols <- c("word1", "word2", "target", "voicequality", "speaker", 
                     "time_to_target", "response", "audio", "file",
                     "category", "key_resp.keys", "key_resp.corr",
                     "key_resp.rt", "participant", "date")
  df <- read.csv(filename)[,relevant_cols]
  df <- df[!is.na(df$key_resp.corr),]
  return(df)
}

# Apply this function to all participants in the "New Data" folder,
# then bind them together
filenames <- list.files(dir_new_data, full.names = TRUE)
print(filenames)
dfs <- lapply(filenames, get_df)
ppt_data <- bind_rows(dfs) |>
  arrange(participant)

# Set up voice quality columns
ppt_data <- ppt_data |> mutate(
  vq1 = ifelse(is.na(voicequality), NA, substr(voicequality, 1, 1))
)
ppt_data <- ppt_data |> mutate(
  vq2 = ifelse(is.na(voicequality), NA, substr(voicequality, 3, 3))
)

# Fix date column
ppt_data$date <- sapply(strsplit(ppt_data$date, "_"), `[`, 1)

# Rename key_resp columns and time-to-target column
ppt_data <- ppt_data |> 
  rename(ppt_response = key_resp.keys, 
         correct = key_resp.corr,
         response_time = key_resp.rt,
         ttt_maxine = time_to_target)

#### Calculate reaction times

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

# When the distinction is between "gate" and "gape":
# add 0.2 seconds to the time-to-target, and set target_at_onset to 0.
ppt_data <- ppt_data |>
  mutate(
    ttt_sidney = ifelse(word1 == "gape" | word2 == "gape", ttt_sidney + 0.2, ttt_sidney),
    target_at_onset = ifelse(word1 == "gape" | word2 == "gape", 0, target_at_onset)
    )

# Create a new time-to-target column that uses ttt_maxine when possible,
# and ttt_sidney when necessary
ppt_data <- ppt_data |>
  mutate(time_to_target = coalesce(ttt_maxine, ttt_sidney))

# Calculate reaction times
ppt_data <- ppt_data |>
  mutate(reaction_time = response_time - time_to_target)

# Create a log reaction time column
ppt_data <- ppt_data |>
  mutate(log_rt = log(reaction_time))

# Reorder columns
reorder_cols <- c("participant", "date", "category", "speaker", "voicequality", "vq1", "vq2", 
                  "word1", "word2", "target", "target_at_onset", 
                  "ppt_response", "correct", "response_time", "time_to_target",
                  "ttt_maxine", "ttt_sidney",
                  "reaction_time", "log_rt",
                  "audio", "file")
ppt_data <- ppt_data[, reorder_cols]

# Write to csv file
ppt_data |> write_csv("data/ppt_data.csv")