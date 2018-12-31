### package ###
library(tidyverse)
library(lubridate)
library(feather)
library(anytime)
library(makedummies)
library(janitor)
library(skimr)

### column name list ###
source('~/Desktop/Elo_kaggle/script/column_name_list.R')

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
aggregate_history <- function(data1,data2,col,add_name){
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

  ## join history data and merchants data
  tmp <- data1 %>% 
    left_join(data2,by="merchant_label_id") 
  tmp <- bind_cols(
    tmp %>% select(-c(month_lag,category_1,category_2,category_3,state_id,subsector_id,
                      most_recent_sales_range,most_recent_purchases_range,category_4)),
    makedummies(dat = tmp,basal_level = TRUE,
                col = c("month_lag", "category_1","category_2","category_3","state_id","subsector_id",
                        "most_recent_sales_range","most_recent_purchases_range","category_4")))
  # test code
  tmp <- tmp %>% head(10000)
  # aggregate (binary, category, numeric)
  tmp %>% 
    group_by(col) %>% 
    summarise_at(vars(matches(str_flatten(col_binary,collapse = "|"))), fun_binary) %>% 
    ungroup() %>% 
    left_join(
      tmp %>% 
        group_by(col) %>% 
        summarise_at(col_category, fun_category) %>% 
        ungroup(),
      by = col) %>% 
    left_join(
      tmp %>% 
        group_by(col) %>% 
        summarise_at(col_numeric, fun_numeric) %>% 
        ungroup(),
      by = col) %>% 
    rename_if(!str_detect(names(.),"card_id"),. %>% tolower %>% str_c(add_name,sep="")) %>% 
    return()
}

### combine data ### 
train <- train %>% 
  left_join(
    aggregate_history(data1 = transactions,data2 = merchants, col = "card_id", add_name = "old"),
    by = "card_id") %>%
  left_join(
    aggregate_history(data1 = new_transactions,data2 = merchants, col = "card_id", add_name = "new"),
    by = "card_id") %>%
  mutate(transaction_flag_new = if_else(authorized_flag_mean_new %>% is.na, 1,0)) # new_transactionの有無

test <- test %>% 
  left_join(
    aggregate_history(data1 = transactions,data2 = merchants, col = "card_id", add_name = "old"),
    by = "card_id") %>%
  left_join(
    aggregate_history(data1 = new_transactions,data2 = merchants, col = "card_id", add_name = "new"),
    by = "card_id") %>%
  mutate(transaction_flag_new = if_else(authorized_flag_mean_new %>% is.na, 1,0)) # new_transactionの有無

### extract features ### 
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
