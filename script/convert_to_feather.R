library(feather)
library(tidyverse)
library(lubridate)
# read csv
## 訓練データ, テストデータ
train <- read_csv("~/Desktop/Elo_kaggle/input/original/train.csv",
                  na = c("XNA","NA","","NaN","?")) %>% 
  mutate_if(is.character, funs(factor(.))) 
test <- read_csv("~/Desktop/Elo_kaggle/input/original/test.csv",
                 na = c("XNA","NA","","NaN","?")) %>% 
  mutate_if(is.character, funs(factor(.))) 
## 取引情報データ
transactions <- read_csv("~/Desktop/Elo_kaggle/input/original/historical_transactions.csv",
                         na = c("XNA","NA","","NaN","?")) %>% 
  mutate_if(is.character, funs(factor(.))) %>% 
  mutate(purchase_date = force_tz(purchase_date, tz = "GMT"))

new_transactions <- read_csv("~/Desktop/Elo_kaggle/input/original/new_merchant_transactions.csv",
                             na = c("XNA","NA","","NaN","?")) %>% 
  mutate_if(is.character, funs(factor(.))) %>% 
  mutate(purchase_date = force_tz(purchase_date, tz = "GMT"))
## 加盟店情報
merchants <- read_csv("~/Desktop/Elo_kaggle/input/original/merchants.csv",
                      na = c("XNA","NA","","NaN","?")) %>% 
  mutate_if(is.character, funs(factor(.))) 
## サブミットファイル
sample_submit <- read_csv("~/Desktop/Elo_kaggle/input/original/sample_submission.csv",
                          na = c("XNA","NA","","NaN","?")) %>% 
  mutate_if(is.character, funs(factor(.))) 

# label encoding
# merchant_idについてnumeric型のidにする
merchants <- merchants %>% 
  mutate(merchant_label_id = as.numeric(merchant_id)) %>% 
  select(merchant_id,merchant_label_id,everything()) 
transactions <- transactions %>% 
  left_join(
    merchants %>% 
      select(merchant_id,merchant_label_id) %>% 
      distinct(merchant_label_id,.keep_all = TRUE),
    by = "merchant_id") %>% 
  select(authorized_flag, card_id, city_id, category_1,installments,
         category_3,merchant_category_id,merchant_id,merchant_label_id,everything()) %>% 
  mutate(merchant_id = merchant_id %>% as.factor())
new_transactions <- new_transactions %>% 
  left_join(
    merchants %>% 
      select(merchant_id,merchant_label_id) %>% 
      distinct(merchant_label_id,.keep_all = TRUE),
    by = "merchant_id") %>% 
  select(authorized_flag, card_id, city_id, category_1,installments,
         category_3,merchant_category_id,merchant_id,merchant_label_id,everything()) %>% 
  mutate(merchant_id = merchant_id %>% as.factor())

# convert to feather file
write_feather(train, "~/Desktop/Elo_kaggle/input/feather/train.feather")
write_feather(test, "~/Desktop/Elo_kaggle/input/feather/test.feather")
write_feather(transactions, "~/Desktop/Elo_kaggle/input/feather/historical_transactions.feather")
write_feather(new_transactions, "~/Desktop/Elo_kaggle/input/feather/new_merchant_transactions.feather")
write_feather(merchants, "~/Desktop/Elo_kaggle/input/feather/merchants.feather")
write_feather(sample_submit, "~/Desktop/Elo_kaggle/input/feather/sample_submission.feather")
