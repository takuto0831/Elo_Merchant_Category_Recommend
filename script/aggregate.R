### package ###
library(tidyverse)
library(lubridate)
library(feather)
library(anytime)
library(makedummies)
library(janitor)
library(skimr)
library(fastDummies)
library(lineNotify)

### column name list ###
# source('~/Desktop/Elo_kaggle/script/column_name_list.R')
source('~/Desktop/Elo_kaggle/script/line_connection.R')

# input data
# rm(list = ls())
train <- read_feather("~/Desktop/Elo_kaggle/input/processed/train.feather")
test <- read_feather("~/Desktop/Elo_kaggle/input/processed/test.feather")
aggregated_history <- read_feather("~/Desktop/Elo_kaggle/input/processed/aggregated_history.feather")
aggregated_new <- read_feather("~/Desktop/Elo_kaggle/input/processed/aggregated_new.feather")
authorized_transactions <- read_feather("~/Desktop/Elo_kaggle/input/processed/authorized_transactions.feather")
history_transactions <- read_feather("~/Desktop/Elo_kaggle/input/processed/history_transactions.feather")
new_transactions <- read_feather("~/Desktop/Elo_kaggle/input/processed/new_transactions.feather")
merchants <- read_feather("~/Desktop/Elo_kaggle/input/processed/merchants.feather")

# train data and test data
train <- train %>% 
  mutate(feature_multi = feature_1 * feature_2 * feature_3,
         feature_sum = feature_1 + feature_2 + feature_3) 
test <- test %>% 
  mutate(feature_multi = feature_1 * feature_2 * feature_3,
         feature_sum = feature_1 + feature_2 + feature_3) 

# history datas and merchants data
aggregate_history <- function(data,col_name,add_name){
  ### column name list ###
  source('~/Desktop/Elo_kaggle/script/column_name_list.R')
  ## aggregate functions
  # count_max <- function(col) col %>% tabyl %>% .$n %>% max %>% return()
  # count_min <- function(col) col %>% tabyl %>% .$n %>% min %>% return()
  # count_mean <- function(col) col %>% tabyl %>% .$n %>% mean %>% return()
  # count_sd <- function(col) col %>% tabyl %>% .$n %>% sd %>% return()
  # mode <- function(col) col %>% tabyl %>% .$n %>% which.max %>% return()
  Range <- function(col,na.rm) diff(range(col,na.rm)) %>% return()
  ## funs lists
  fun_binary <- funs(mean, sum, sd, .args = list(na.rm = TRUE)) # for binary
  fun_numeric <- funs(mean, sum, min, max, sd, Range,.args = list(na.rm = TRUE)) # for numeric
  # fun_category <- funs(n_unique,n_missing,count_max,count_min,count_mean,count_sd,mode) # for category
  fun_category <- funs(n_unique)
  # start time
  start_time <- proc.time() 
  ## join history data and merchants data
  tmp <- data %>% 
    left_join(merchants,by="merchant_label_id") 

  # aggregate (binary, category, numeric)
  tmp_binary <- tmp %>% 
    select(col_name, col_binary) %>% 
    group_by_(col_name) %>% 
    summarise_all(fun_binary) %>% 
    ungroup()  
  tmp_category <- tmp %>% 
    select(col_name,col_category) %>% 
    group_by_(col_name) %>% 
    summarise_all(fun_category) %>% 
    ungroup()
  tmp_numeric <- tmp %>%
    select(col_name,col_numeric) %>% 
    group_by_(col_name) %>% 
    summarise_all(fun_numeric) %>% 
    ungroup()
  # left join 
  tmp1 <- tmp_binary %>% 
    left_join(tmp_category,by = "card_id") %>% 
    left_join(tmp_numeric, by = "card_id")
  # care memory
  rm(tmp_binary,tmp_category,tmp_numeric); gc(); gc();
  # middle time
  half_time <- proc.time() - start_time 
  # line notification
  notify <- paste("\n aggregate function finished execution time:",half_time[3] %>% as.numeric %>% round(5),"second")
  notify_msg(notify)
  ## one hot encoding and aggregate
  tmp <- select(tmp,col_name,one_hot_list)
  # one hot encoding
  for (i in 1:length(one_hot_list)) {
    tmp_ <- tmp %>%
      select(col_name,one_hot_list[i]) %>% 
      fastDummies::dummy_cols(select_columns = one_hot_list[i]) %>% 
      select(-c(2)) %>% # remove column
      group_by_(col_name) %>% 
      summarise_all(fun_binary) %>% 
      ungroup() 
    tmp1 <- tmp_ %>% 
      left_join(tmp1,.,by=col_name)
    }
  # end time
  end_time <- proc.time() - start_time 
  # line notification
  notify <- paste("\n one hot encoding finished execution time:",end_time[3] %>% as.numeric %>% round(5),"second")
  notify_msg(notify)
  # add each name
  tmp1 %>% 
    rename_at(vars(-col_name),. %>% tolower %>% str_c(add_name,sep="")) %>% 
    return()
}
# main

## aggregate transactions
authorized_transactions <- aggregate_history(data = authorized_transactions,col_name = "card_id", add_name = "_auth")
history_transactions <- aggregate_history(data = history_transactions,col_name = "card_id", add_name = "_hist")
new_transactions <- aggregate_history(data = new_transactions,col_name = "card_id", add_name = "_new")

## combine data and extratc features
train <- train %>% 
  left_join(aggregated_history, by = "card_id") %>%
  left_join(aggregated_new, by = "card_id") %>%
  left_join(authorized_transactions, by = "card_id") %>%
  left_join(history_transactions, by = "card_id") %>%
  left_join(new_transactions,by = "card_id") %>%
  mutate(transaction_flag_new = if_else(installments_mean_new %>% is.na, 0,1)) # new_transactionの有無

test <- test %>% 
  left_join(aggregated_history, by = "card_id") %>%
  left_join(aggregated_new, by = "card_id") %>%
  left_join(authorized_transactions, by = "card_id") %>%
  left_join(history_transactions, by = "card_id") %>%
  left_join(new_transactions,by = "card_id") %>%
  mutate(transaction_flag_new = if_else(installments_mean_new %>% is.na, 0,1)) # new_transactionの有無

features <- train %>% 
  # 特徴量として扱わないカラム
  select(-c(card_id,first_active_month,target,target_class)) %>% 
  colnames() %>% 
  data.frame(feature = .)

### save combine data and features ###
# train <- read_feather("~/Desktop/Elo_kaggle/input/aggregated/train_1037.feather")
write_feather(train,"~/Desktop/Elo_kaggle/input/aggregated/train_20190112.feather")
write_feather(test,"~/Desktop/Elo_kaggle/input/aggregated/test_20190112.feather")
write_feather(features, "~/Desktop/Elo_kaggle/input/aggregated/features_20190112.feather")
