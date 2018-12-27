### package ###
library(tidyverse)
library(lubridate)
library(feather)
library(anytime)
library(makedummies)

### read data ###
train <- read_feather("~/Desktop/Elo_kaggle/input/feather/train.feather")
test <- read_feather("~/Desktop/Elo_kaggle/input/feather/test.feather")
transactions <- read_feather("~/Desktop/Elo_kaggle/input/feather/historical_transactions.feather")
new_transactions <- read_feather("~/Desktop/Elo_kaggle/input/feather/new_merchant_transactions.feather")
merchants <- read_feather("~/Desktop/Elo_kaggle/input/feather/merchants.feather")

####################### Feature engineering #########################
#!!!!!!!!!!!!! train data and test data !!!!!!!!!!!!!#
# function
aggregate_train <- function(data){
  data %>% 
    mutate(diff = anytime("2018-02-01") - anytime(first_active_month)) %>% # 時間差
    mutate(diff = diff %>% as.numeric(),
           feature_multi = feature_1 * feature_2 * feature_3,
           feature_sum = feature_1 + feature_2 + feature_3) %>% 
    return()
}
# main
train <- train %>%
  aggregate_train %>% 
  mutate(target_class = 
           case_when(target < -30 ~ 1,target >= 0 ~ 3,TRUE ~ 2)) # クロスバリデーションで使用
test <- test %>% 
  aggregate_train 

#!!!!!!!!!!!!! transaction_history and new_transaction_history !!!!!!!!!!!!!#
# historyデータには支払い固有の情報と店舗に依存する情報があるので分割して考える.
# 支払い固有の情報
tmp <- data %>% 
  # authorized_flagを0or1に
  mutate(authorized_flag = if_else(authorized_flag == "Y",0,1)) %>% 
  # 支払い分割数 (-1, 999の処理)
  mutate(installments_minus = if_else(installments == -1,1,0),
         installments_outlier = if_else(installments == 999,1,0),
         installments = if_else(installments == -1,NA_integer_,
                                if_else(installments == 999, NA_integer_,installments))) 

# お店カテゴリー(one hot encoding)
tmp <- bind_cols(tmp %>% select(-c(category_1,category_2,category_3)),
                 makedummies(dat = tmp,basal_level = TRUE,col = c("category_1","category_2","category_3"))) 



