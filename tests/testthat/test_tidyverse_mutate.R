context("test tidyverse mutate")
library(eeguana)

# tests when factors are used should be done.


# create fake dataset
data_1 <- eeg_lst(
  signal = signal_tbl(
    signal_matrix = as.matrix(
      data.frame(X = sin(1:30), Y = cos(1:30))
    ),
    ids = rep(c(1L, 2L, 3L), each = 10),
    sample_ids = sample_int(rep(seq(-4L, 5L), times = 3), sampling_rate = 500),
    dplyr::tibble(
      channel = c("X", "Y"), .reference = NA, theta = NA, phi = NA,
      radius = NA, .x = c(1, 1), .y = NA_real_, .z = NA_real_
    )
  ),
  events = dplyr::tribble(
    ~.id, ~type, ~description, ~.sample_0, ~.size, ~.channel,
    1L, "New Segment", NA_character_, -4L, 1L, NA,
    1L, "Bad", NA_character_, -2L, 3L, NA,
    1L, "Time 0", NA_character_, 1L, 1L, NA,
    1L, "Bad", NA_character_, 2L, 2L, "X",
    2L, "New Segment", NA_character_, -4L, 1L, NA,
    2L, "Time 0", NA_character_, 1L, 1L, NA,
    2L, "Bad", NA_character_, 2L, 1L, "Y",
    3L, "New Segment", NA_character_, -4L, 1L, NA,
    3L, "Time 0", NA_character_, 1L, 1L, NA,
    3L, "Bad", NA_character_, 2L, 1L, "Y"
  ),
  segments = dplyr::tibble(.id = c(1L, 2L, 3L), recording = "recording1", segment = c(1L, 2L, 3L), condition = c("a", "b", "a"))
)

# just some different X and Y
data_2 <- mutate(data_1, recording = "recording2", X = sin(X + 10), Y = cos(Y - 10), condition = c("b", "a", "b"))

# bind it all together
data <- bind(data_1, data_2)


# for checks later
reference_data <- data.table::copy(data)



### test dplyr mutate on ungrouped eeg_lst ###
mutate_eeg_lst <- mutate(data, X = X + 10)

mutate_tbl <- data %>%
  as_tibble() %>%
  dplyr::filter(channel == "X") %>%
  dplyr::mutate(X = amplitude + 10)

mutate2_eeg_lst <- mutate(data, ZZ = X + 10)

mutate2_tbl <- data %>%
  as_tibble() %>%
  dplyr::filter(channel == "X") %>%
  dplyr::mutate(ZZ = amplitude + 10)

mutate3_eeg_lst <- mutate(data, mean = mean(X))

mutate3_tbl <- data %>%
  as_tibble() %>%
  dplyr::filter(channel == "X") %>%
  dplyr::mutate(mean = mean(amplitude))

mutate4_eeg_lst <- mutate(data, subject = recording)

mutate4_tbl  <- data %>%
  as_tibble() %>%
  dplyr::filter(channel == "X") %>%
  dplyr::distinct(segment, condition, .keep_all = TRUE) %>%
  dplyr::mutate(subject = recording)

transmute_eeg_lst <- transmute(data, X = X + 1)

transmute_tbl <- data %>%
  as_tibble() %>%
  dplyr::filter(channel == "X") %>%
  dplyr::transmute(X = amplitude + 1)


test_that("mutate functions work correctly on ungrouped data", {
  expect_equal(as.double(mutate_eeg_lst$signal[["X"]]), mutate_tbl$X)
  expect_equal(as.double(mutate2_eeg_lst$signal[["ZZ"]]), mutate2_tbl$ZZ)
  expect_equal(as.double(mutate3_eeg_lst$signal[["mean"]]), mutate3_tbl$mean)
  expect_equal(mutate4_eeg_lst$segments[["subject"]], mutate4_tbl$subject)
  expect_equal(as.double(transmute_eeg_lst$signal[["X"]]), transmute_tbl$X)
})

# TODO - I don't think these functions exist yet
# mutate_all_eeg_lst <- mutate_all_ch(data, mean)
# mutate_at_eeg_lst <- mutate_at(data, channel_names(data), mean)


test_that("the classes of channels of signal_tbl remain in non-grouped eeg_lst", {
  expect_equal(is_channel_dbl(mutate_eeg_lst$signal$X), TRUE)
  expect_equal(is_channel_dbl(mutate2_eeg_lst$signal$X), TRUE)
  expect_equal(is_channel_dbl(mutate2_eeg_lst$signal$ZZ), TRUE)
  expect_equal(is_channel_dbl(transmute_eeg_lst$signal$X), TRUE)
  # expect_equal(is_channel_dbl(mutate_all_eeg_lst$signal$X), TRUE)
  # expect_equal(is_channel_dbl(mutate_at_eeg_lst$signal$X), TRUE)
  expect_equal(is_channel_dbl(summarizeX_eeg_lst$signal$`mean(X)`), TRUE)
  expect_equal(is_channel_dbl(summarize_at_eeg_lst$signal$X), TRUE)
})


# check against original data
test_that("data didn't change", {
  expect_equal(reference_data, data)
})




### test dplyr mutate on grouped eeg_lst ###
group_by_eeg_lst <- group_by(data, .sample_id) 
group2_by_eeg_lst <- group_by(data, .id)
group3_by_eeg_lst <- group_by(data, recording)
group4_by_eeg_lst <- group_by(data, .sample_id, recording)
group5_by_eeg_lst <- group_by(data, .id, recording)
group6_by_eeg_lst <- group_by(data, .id, .sample_id, recording)
group7_by_eeg_lst <- group_by(data, .sample_id, condition)


mutate_g_signal_tbl <- mutate(group_by_eeg_lst, X = X + 1)

mutate_g_tbl <- data %>%
  as_tibble() %>%
  dplyr::group_by(recording) %>%
  dplyr::filter(channel == "X") %>%
  dplyr::mutate(X = amplitude + 1)

mutate2_g_signal_tbl <- mutate(group3_by_eeg_lst, ZZ = X + 1)

mutate2_g_tbl <- data %>%
  as_tibble() %>%
  dplyr::group_by(.id) %>%
  dplyr::filter(channel == "X") %>%
  dplyr::mutate(ZZ = amplitude + 1)

mutate3_g_signal_tbl <- mutate(group3_by_eeg_lst, Y = Y + 1)

mutate3_g_tbl <- data %>%
  as_tibble() %>%
  dplyr::group_by(recording) %>%
  dplyr::filter(channel == "Y") %>%
  dplyr::mutate(Y = amplitude + 1)

mutate4_g_signal_tbl <- mutate(group4_by_eeg_lst, X = X + 1)

mutate4_g_tbl <- data %>%
  as_tibble() %>%
  dplyr::group_by(time, recording) %>%
  dplyr::filter(channel == "X") %>%
  dplyr::mutate(X = amplitude + 1)

mutate5_g_signal_tbl <- mutate(group5_by_eeg_lst, ZZ = X + 1)

mutate5_g_tbl <- data %>%
  as_tibble() %>%
  dplyr::group_by(.id, recording) %>%
  dplyr::filter(channel == "X") %>%
  dplyr::mutate(ZZ = amplitude + 1)

mutate6_g_signal_tbl <- mutate(group6_by_eeg_lst, Y = Y + 1)

mutate6_g_tbl <- data %>%
  as_tibble() %>%
  dplyr::group_by(.id, time, recording) %>%
  dplyr::filter(channel == "Y") %>%
  dplyr::mutate(Y = amplitude + 1)

mutate7_g_signal_tbl <- mutate(group7_by_eeg_lst, mean = mean(Y))

mutate7_g_tbl <- data %>%
  as_tibble() %>%
  dplyr::filter(channel == "Y") %>%
  dplyr::group_by(condition, time) %>% # have to reverse order 
  dplyr::mutate(mean = mean(amplitude)) 

transmute_g_signal_tbl <- transmute(group_by_eeg_lst, X = X + 1)

transmute_g_tbl <- data %>%
  as_tibble %>%
  dplyr::group_by(time) %>%
  dplyr::filter(channel == "X") %>%
  dplyr::transmute(X = amplitude + 1)

mutate_all_g_signal_tbl <- mutate_all(group_by_eeg_lst, mean) # mean of everything except .sample_id
mutate_at_g_signal_tbl <- mutate_at(group_by_eeg_lst, channel_names(data), mean) # mean of channels

mutate_a_tbl <- data %>%
  as_tibble() %>%
  dplyr::group_by(time, channel) %>%
  dplyr::mutate(mean = mean(amplitude)) %>% 
  dplyr::select(.id, time, channel, mean) %>%
  tidyr::spread(key = channel, value = mean) %>%
  ungroup()
  

test_that("mutate works correctly on data grouped by .sample_id", {
  expect_equal(as.double(mutate_g_signal_tbl$signal[["X"]]), mutate_g_tbl$X)
  expect_equal(as.double(mutate2_g_signal_tbl$signal[["ZZ"]]), mutate2_g_tbl$ZZ)
  expect_equal(as.double(mutate3_g_signal_tbl$signal[["Y"]]), mutate3_g_tbl$Y)
  expect_equal(as.double(mutate4_g_signal_tbl$signal[["X"]]), mutate4_g_tbl$X)
  expect_equal(as.double(mutate5_g_signal_tbl$signal[["ZZ"]]), mutate5_g_tbl$ZZ)
  expect_equal(as.double(mutate6_g_signal_tbl$signal[["Y"]]), mutate6_g_tbl$Y)
  expect_equal(as.double(mutate7_g_signal_tbl$signal[["mean"]]), mutate7_g_tbl$mean)
  expect_equal(as.double(transmute_g_signal_tbl$signal[["X"]]), transmute_g_tbl$X)
  expect_equal(as.matrix(mutate_all_g_signal_tbl$signal[, c("X", "Y")]), as.matrix(mutate_at_g_signal_tbl$signal[, c("X", "Y")]))
  expect_equal(as.matrix(mutate_all_g_signal_tbl$signal[, c("X", "Y")]), as.matrix(select(mutate_a_tbl, X, Y)))
})


test_that("the classes of channels of signal_tbl remain in grouped eeg_lst", {
  expect_equal(is_channel_dbl(group_by_eeg_lst$signal$X), TRUE)
  expect_equal(is_channel_dbl(group2_by_eeg_lst$signal$X), TRUE)
  expect_equal(is_channel_dbl(mutate_g_signal_tbl$signal$X), TRUE)
  expect_equal(is_channel_dbl(mutate2_g_signal_tbl$signal$ZZ), TRUE)
  expect_equal(is_channel_dbl(mutate3_g_signal_tbl$signal$Y), TRUE)
  expect_equal(is_channel_dbl(transmute_g_signal_tbl$signal$X), TRUE)
  expect_equal(is_channel_dbl(mutate_all_g_signal_tbl$signal$X), TRUE)
  expect_equal(is_channel_dbl(mutate_at_g_signal_tbl$signal$X), TRUE)
})


# check against original data
test_that("data didn't change after grouping and mutate functions", {
  expect_equal(reference_data, data)
})




### test as_time conversion (bug #44) ###
eeg_time <- mutate(data, time = as_time(.sample_id, unit = "seconds")) %>%
  summarize(mean = mean(time))

tbl_time <- data %>%
  as_tibble() %>%
  dplyr::summarize(mean = mean(time))

test_that("as_time works as expected", {
  expect_equal(as.double(eeg_time$signal[["mean"]]), tbl_time$mean)
})



### test serial mutates ###

# Bruno's note: Maybe it's fine that the following fails:
# mutate(data, time = as_time(.sample_id, unit = "milliseconds")) %>% group_by(time) %>% summarize(mean(X))

# create new variable with mutate
eeg_mutate_1 <- data %>%
  mutate(bin = ntile(.sample_id, 5))

tbl_mutate_1 <- data %>%
  as_tibble() %>%
  dplyr::mutate(bin = ntile(time, 5))

# use new variable in second variable doesn't work in eeg_lst (#35)
## eeg_mutate_2 <- data %>% mutate(time = as_time(.sample_id, unit = "ms"), bin = ntile(time, 5))
# work around:
eeg_mutate_2 <- data %>%
  mutate(time = as_time(.sample_id, unit = "ms")) %>%
  mutate(bin = ntile(time, 5))

tbl_mutate_2 <- data %>%
  as_tibble() %>%
  dplyr::mutate(test = time + 1, bin = ntile(test, 5))

# can't summarize by a mutated variable within eeg_lst (#43)
eeg_mutate_3 <- data %>%
  mutate(bin = ntile(.sample_id, 5)) %>%
  dplyr::group_by(bin) %>%
  dplyr::summarize(mean = mean(X))

tbl_mutate_3 <- data %>%
  as_tibble() %>%
  dplyr::mutate(bin = ntile(time, 3)) %>%
  dplyr::group_by(bin) %>%
  dplyr::summarize(mean = mean(amplitude[channel == "X"]))


test_that("mutate works the same on eeg_lst as on tibble", {
  expect_equal(eeg_mutate_1$signal[["bin"]], tbl_mutate_1$bin[tbl_mutate_1$channel == "X"])
  expect_equal(eeg_mutate_2$signal[["bin"]], tbl_mutate_2$bin[tbl_mutate_1$channel == "X"])
  expect_equal(eeg_mutate_3$signal[["bin"]], tbl_mutate_3$bin)
})