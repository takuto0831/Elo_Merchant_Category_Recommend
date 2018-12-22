# package
library(tidyverse)
library(lubridate)
library(feather)
library(anytime)
library(makedummies)

# read data
train <- read_feather("~/Desktop/Elo_kaggle/input/feather/train.feather")
test <- read_feather("~/Desktop/Elo_kaggle/input/feather/test.feather")
transactions <- read_feather("~/Desktop/Elo_kaggle/input/feather/historical_transactions.feather")
new_transactions <- read_feather("~/Desktop/Elo_kaggle/input/feather/new_merchant_transactions.feather")
merchants <- read_feather("~/Desktop/Elo_kaggle/input/feather/merchants.feather")

# Feature engineering
## train, test
train <-train %>% 
  mutate(diff = anytime("2018-02-02") - anytime(first_active_month)) %>% # 時間差
  mutate(diff = diff %>% as.numeric()) %>% 
  select(-first_active_month)
test <- test %>% 
  mutate(diff = anytime("2018-02-02") - anytime(first_active_month)) %>% # 時間差
  mutate(diff = diff %>% as.numeric()) %>% 
  select(-first_active_month)
## transaction_history
# 0 or 1に変更
tmp <- transactions %>% 
  mutate(authorized_flag = if_else(authorized_flag == "Y",1,0), 
         category_1 = if_else(category_1 == "Y",1,0)) %>% 
  mutate(category_2 = category_2 %>% as.factor())
# one hot encoding
tmp <- bind_cols(tmp %>% select(-c(category_2,category_3)),
                 makedummies(dat = tmp,basal_level = TRUE,col = c("category_2","category_3"))) 
# aggregate
tmp1 <- tmp %>% 
  group_by(card_id) %>% 
  summarise(pay_count = n(),
            authorized_flag_sum = sum(authorized_flag),
            authorized_flag_mean = mean(authorized_flag),
            installments_mean = mean(installments),
            )
  

summarise_at(vars(starts_with("category")), funs(mean,sum)) # お店のカテゴリ
summarise_at(vars(ends_with("id")), funs(n_distinct)) # 各種idのカウント, NAも1種とする.


  