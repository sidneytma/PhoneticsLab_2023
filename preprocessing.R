# Script for pre-processing data for analysis

#----------------------------

# Takes the cleaned ppt_data file and prepares it for data analysis:

# Removes irrelevant columns
# Removes participants who fail certain tests
# Removes training and attention trials
# Removes rows with negative reaction times
# Removes rows with excessively long reaction times

#----------------------------

# Remove date and audio path columns
ppt_data_prep <- ppt_data |> select(-date, -audio)

# Remove participants who fail too many attention trials

# Calculate proportion of passed attention trials
calculate_attention_proportion <- function(ppt_id) {
  indiv_data <- ppt_data_prep[ppt_data_prep$participant == ppt_id, ]
  attention_trials <- indiv_data[indiv_data$category == "attention", ]
  proportion_correct <- mean(attention_trials$correct, na.rm = TRUE)
  return(proportion_correct)
}

# Get attention scores for each participant
ppt_ids <- unique(ppt_data_prep$participant)
attention_scores <- sapply(ppt_ids, function(x) calculate_attention_proportion(x))

# Only include participants with an attention score of 80% or higher
names(attention_scores) <- ppt_ids
ppts_to_keep <- names(attention_scores[attention_scores > 0.8])
ppt_data_prep <- ppt_data_prep |> filter(participant %in% ppts_to_keep)

# Remove participants who have too many negative reaction times

# Count the number of trials in which a given participant has a negative reaction time
count_low_rts <- function(ppt_id) {
  indiv_data <- ppt_data_prep[ppt_data_prep$participant == ppt_id, ]
  count <- sum(indiv_data$reaction_time < 0, na.rm = TRUE)
  return(count)
}

# Get negative rt counts for each participant
low_rt_counts <- sapply(ppt_ids, function(x) count_low_rts(x))
names(low_rt_counts) <- ppt_ids

# Only include participants who had 5 or fewer negative reaction times
ppts_to_keep <- names(low_rt_counts[low_rt_counts <= 5])
ppt_data_prep <- ppt_data_prep |> filter(participant %in% ppts_to_keep)

# Remove training and attention trials
ppt_data_prep <- ppt_data_prep |>
  filter(!category %in% c("training", "attention"))

# Remove rows with negative reaction times
ppt_data_prep <- ppt_data_prep |> filter(reaction_time > 0)

# Remove rows with excessively high reaction times
ppt_data_prep <- ppt_data_prep |> filter(reaction_time < 5)