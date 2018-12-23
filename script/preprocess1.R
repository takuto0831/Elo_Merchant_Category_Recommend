# package
library(tidyverse)
library(lubridate)
library(feather)
library(anytime)
library(makedummies)
# devtools::install_github("paulponcet/modeest")
library(modeest)

# read data
train <- read_feather("~/Desktop/Elo_kaggle/input/feather/train.feather")
test <- read_feather("~/Desktop/Elo_kaggle/input/feather/test.feather")
transactions <- read_feather("~/Desktop/Elo_kaggle/input/feather/historical_transactions.feather")
new_transactions <- read_feather("~/Desktop/Elo_kaggle/input/feather/new_merchant_transactions.feather")
merchants <- read_feather("~/Desktop/Elo_kaggle/input/feather/merchants.feather")

# Feature engineering
## train, test
train <- train %>% 
  mutate(diff = anytime("2018-02-02") - anytime(first_active_month)) %>% # 時間差
  mutate(diff = diff %>% as.numeric()) %>% 
  select(-first_active_month)
test <- test %>% 
  mutate(diff = anytime("2018-02-02") - anytime(first_active_month)) %>% # 時間差
  mutate(diff = diff %>% as.numeric()) %>% 
  select(-first_active_month)
## transaction_history
tmp <- 
  # flag, category1: 0 or 1に変更, category_2: factor typeに変更
  transactions %>% 
  mutate(authorized_flag = if_else(authorized_flag == "Y",1,0), 
         category_1 = if_else(category_1 == "Y",1,0)) %>% 
  mutate(category_2 = category_2 %>% as.factor()) %>% 
  # 支払い分割数 (-1, 999の処理)
  mutate(installments_minus = if_else(installments == -1,1,0),
         installments_outlier = if_else(installments == 999,1,0),
         installments = if_else(installments == -1,NA_integer_,
                                if_else(installments == 999, NA_integer_,installments))) %>% 
  # 支払い金額 (時系列変動を取り除くために, 平均との差を使う)
  group_by(hours = floor_date(purchase_date,"hour")) %>% 
  mutate(purchase_amount_diff = purchase_amount - mean(purchase_amount),
         purchase_amount_abs = abs(purchase_amount - mean(purchase_amount))) %>% 
  ungroup() %>% 
  select(-purchase_date)
# お店カテゴリー(one hot encoding)
tmp <- bind_cols(tmp %>% select(-c(category_2,category_3)),
                 makedummies(dat = tmp,basal_level = TRUE,col = c("category_2","category_3"))) 

# aggregate
mode <- function(col) mlv(col,method='mfv',na.rm = TRUE)[1]
tmp1 <- tmp %>% group_by(card_id) 
tmp2 <- 
  # 会計回数
  summarise(tmp1, pay_count = n()) %>% 
  # 各種idのカウント, NAも1種とする. 
  left_join(
    summarise_at(tmp1,c("city_id","merchant_category_id","merchant_id","state_id","subsector_id"), 
                 funs(n_distinct,mode)),
    by = "card_id") %>% 
  # installments~
  left_join(
    summarise_at(tmp1,vars(starts_with("installments_")), funs(sum,mean)),
    by = "card_id") %>% 
  left_join(
    summarise_at(tmp1, "installments", funs(mean(.,na.rm=TRUE),sum(.,na.rm=TRUE),sd(.,na.rm = TRUE))) %>% 
      rename_if(!str_detect(names(.),"card_id"),. %>% tolower %>% str_c("installments_",.,sep="")),
    by = "card_id") %>% 
  # month_lag
  left_join(
    summarise_at(tmp1, "month_lag", funs(max,min,mean,sd)) %>% 
      rename_if(!str_detect(names(.),"card_id"),. %>% tolower %>% str_c("month_lag_",.,sep="")),
    by = "card_id") %>%
  # フラッグ
  left_join(
    summarise_at(tmp1, vars(starts_with("authorized_flag")), funs(mean,sum)) %>% 
      rename_if(!str_detect(names(.),"card_id"),. %>% tolower %>% str_c("authorized_flag_",.,sep="")),
    by = "card_id") %>% 
  # 購入金額について
  left_join(
    summarise_at(tmp1, vars(starts_with("purchase")), funs(max,min,mean,sum,sd)),
    by = "card_id") %>% 
  # お店のカテゴリ
  left_join(
    summarise_at(tmp1, vars(starts_with("category")), funs(mean(.,na.rm=TRUE),sum(.,na.rm=TRUE))),
    by = "card_id")




  
  



  