### package ###
library(tidyverse)
library(lubridate)
library(feather)
library(anytime)
library(makedummies)

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

# history datas (one hot encoding)

fun_binary <- funs(mean, sum, .args = list(na.rm = TRUE)) # for binary
fun_numeric <- funs(mean, sum, min, max, sd, .args = list(na.rm = TRUE)) # for numeric
fun_category <- funs()

tmp <- bind_cols(tmp %>% select(-c(month_lag,category_1,category_2,
                                   category_3,state_id,subsector_id)),
                 makedummies(dat = tmp,basal_level = TRUE,
                             col = c("month_lag", "category_1","category_2",
                                     "category_3","state_id","subsector_id"))) 




### combine data ### 
train <- train %>% 
  left_join(transactions,by="card_id") %>% 
  left_join(new_transactions, by="card_id") %>% 
  mutate(transaction_flag_new = if_else(authorized_flag_mean_new %>% is.na, 1,0)) # new_transactionの有無

test <- test %>% 
  left_join(transactions,by="card_id") %>% 
  left_join(new_transactions, by="card_id") %>% 
  mutate(transaction_flag_new = if_else(authorized_flag_mean_new %>% is.na, 1,0)) # new_transactionの有無

### extract features ### 
features <- train %>% 
  # 特徴量として扱わないカラム
  select(-c(card_id, merchant_id, purchase_date,first_active_month,target,target_class)) %>% 
  colnames() %>% 
  data.frame(feature = .)

### save combine data and features ###
# train <- read_feather("~/Desktop/Elo_kaggle/input/processed/train_20181223.feather")
write_feather(train,"~/Desktop/Elo_kaggle/input/processed/train_20181223.feather")
write_feather(test,"~/Desktop/Elo_kaggle/input/processed/test_20181223.feather")
write_feather(features, "~/Desktop/Elo_kaggle/input/processed/features_20181223.feather")
