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
transactions <- read_feather("~/Desktop/Elo_kaggle/input/processed/historical_transactions.feather")
new_transactions <- read_feather("~/Desktop/Elo_kaggle/input/processed/new_merchant_transactions.feather")
merchants <- read_feather("~/Desktop/Elo_kaggle/input/processed/merchants.feather")

# train data and test data
train <- train %>% 
  mutate(feature_multi = feature_1 * feature_2 * feature_3,
         feature_sum = feature_1 + feature_2 + feature_3) 
test <- test %>% 
  mutate(feature_multi = feature_1 * feature_2 * feature_3,
         feature_sum = feature_1 + feature_2 + feature_3) 

# history datas and merchants data
aggregate_history <- function(data1,data2,col_name,add_name,one_hot_list){
  ### column name list ###
  source('~/Desktop/Elo_kaggle/script/column_name_list.R')
  ## aggregate functions
  count_max <- function(col) col %>% tabyl %>% .$n %>% max %>% return()
  count_min <- function(col) col %>% tabyl %>% .$n %>% min %>% return()
  count_mean <- function(col) col %>% tabyl %>% .$n %>% mean %>% return()
  count_sd <- function(col) col %>% tabyl %>% .$n %>% sd %>% return()
  mode <- function(col) col %>% tabyl %>% .$n %>% which.max %>% return()
  ## funs lists
  fun_binary <- funs(mean(.,na.rm = TRUE), sum(.,na.rm = TRUE), sd(.,na.rm = TRUE), n_missing) # for binary
  fun_numeric <- funs(mean, sum, min, max, sd, .args = list(na.rm = TRUE)) # for numeric
  fun_category <- funs(n_unique,n_missing,count_max,count_min,count_mean,count_sd,mode) # for category

  # start time
  start_time <- proc.time() 
  ## join history data and merchants data
  tmp <- data1 %>% 
    left_join(data2,by="merchant_label_id") 

  # aggregate (binary, category, numeric)
  tmp1 <- tmp %>% 
    group_by_(col_name) %>% 
    summarise_at(vars(matches(str_flatten(col_binary,collapse = "|"))), fun_binary) %>% 
    ungroup() %>% 
    left_join(
      tmp %>% 
        group_by_(col_name) %>% 
        summarise_at(col_category, fun_category) %>% 
        ungroup(),
      by = col_name) %>% 
    left_join(
      tmp %>% 
        group_by_(col_name) %>% 
        summarise_at(col_numeric, fun_numeric) %>% 
        ungroup(),
      by = col_name) %>% 
    mutate_if(is.numeric, round,4)
  # middle time
  half_time <- proc.time() - start_time 
  # line notification
  notify <- paste("\n middle point execution time:",half_time[3] %>% as.numeric %>% round(4),"second")
  notify_msg(notify)
  ## one hot encoding and aggregate
  for (i in 1:length(one_hot_list)) {
    tmp1 <- tmp %>%
      select_(col_name,one_hot_list[i]) %>% 
      fastDummies::dummy_cols(select_columns = one_hot_list[i]) %>% 
      select(-c(2)) %>% # remove
      group_by_(col_name) %>% 
      summarise_if(is.integer,fun_binary) %>% # exclusive card_id
      ungroup() %>% 
      left_join(tmp1,.,by=col_name)
  }
  # end time
  end_time <- proc.time() - start_time 
  # line notification
  notify <- paste("\n finished execution time:",end_time[3] %>% as.numeric %>% round(4),"second")
  notify_msg(notify)
  # add each name
  tmp1 %>% 
    mutate_if(is.numeric, round,4) %>% 
    rename_if(is.factor %>% negate,. %>% tolower %>% str_c(add_name,sep="")) %>% 
    return()
}
# main
## one hot encoding list
one_hot_list <- c("month_lag", "category_1","category_2","category_3","state_id","subsector_id",
                  "most_recent_sales_range","most_recent_purchases_range","category_4")
## aggregate transactions
transactions <- aggregate_history(data1 = transactions,data2 = merchants,
                                  col_name = "card_id", add_name = "_old",one_hot_list)

new_transactions <- aggregate_history(data1 = new_transactions,data2 = merchants, 
                                      col_name = "card_id", add_name = "_new",one_hot_list)

## combine data and extratc features
train <- train %>% 
  left_join(transactions, by = "card_id") %>%
  left_join(new_transactions,by = "card_id") %>%
  mutate(transaction_flag_new = if_else(authorized_flag_mean_new %>% is.na, 1,0)) # new_transactionの有無

test <- test %>% 
  left_join(transactions, by = "card_id") %>%
  left_join(new_transactions,by = "card_id") %>%
  mutate(transaction_flag_new = if_else(authorized_flag_mean_new %>% is.na, 1,0)) # new_transactionの有無

features <- train %>% 
  # 特徴量として扱わないカラム
  select(-c(card_id, merchant_id, purchase_date,first_active_month,target,target_class)) %>% 
  colnames() %>% 
  data.frame(feature = .)

### save combine data and features ###
# train <- read_feather("~/Desktop/Elo_kaggle/input/processed/train_20181223.feather")
write_feather(train,"~/Desktop/Elo_kaggle/input/processed/train_20190101.feather")
write_feather(test,"~/Desktop/Elo_kaggle/input/processed/test_20190101.feather")
write_feather(features, "~/Desktop/Elo_kaggle/input/processed/features_20190101.feather")
