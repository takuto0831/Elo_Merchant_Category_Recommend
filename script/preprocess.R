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
preprocess_train <- function(data){
  data %>% 
    mutate(first_active_diff = difftime(anytime("2018-02-28"), anytime(first_active_month),
                                        units = "days") %>% as.integer) %>% # 時間差 (tz = JST)
              
    return()
}

# main
train <- train %>%
  preprocess_train %>% 
  mutate(target_class = 
           case_when(target < -30 ~ 1,target >= 0 ~ 3,TRUE ~ 2)) # クロスバリデーションで使用

test <- test %>% 
  preprocess_train 

#!!!!!!!!!!!!! transaction_history and new_transaction_history !!!!!!!!!!!!!#
# historyデータには支払い固有の情報と店舗に依存する情報がある!!
preprocess_history <- function(data){
  # 基準日(month_lag == 0)との差を算出する
  tmp1 <- data %>% 
    group_by(card_id) %>% 
    top_n(1,wt=purchase_date) %>% 
    distinct(card_id,.keep_all = TRUE) %>% 
    ungroup() %>% 
    mutate(reference_date = purchase_date %m+% months(abs(month_lag)) ) %>% 
    mutate(reference_date_diff = difftime(as.POSIXct("2018-02-28 23:59:59",tz="UTC"), reference_date,
                                          units = "days") %>% as.integer()) %>% 
    select(card_id,reference_date_diff)
  # main
  tmp <- data %>% 
    # authorized_flagを0or1に, category_2, month_lag, state_id, subsector_idをfactor型に
    mutate(authorized_flag = if_else(authorized_flag == "Y",0,1),
           category_2 = category_2 %>% as.factor,
           month_lag = month_lag %>% as.factor,
           state_id = state_id %>% as.factor,
           subsector_id = subsector_id %>% as.factor) %>% 
    # 支払い分割数 (-1, 999の処理)
    mutate(installments_minus = if_else(installments == -1,1,0),
           installments_outlier = if_else(installments == 999,1,0),
           installments = if_else(installments == -1,NA_integer_,
                                  if_else(installments == 999, NA_integer_,installments))) %>% 
    # 会計金額を直近1時間の平均と比較した差分, 絶対値を追加
    group_by(hours = floor_date(purchase_date,"hour")) %>% 
    mutate(purchase_amount_diff = purchase_amount - mean(purchase_amount),
           purchase_amount_abs = abs(purchase_amount - mean(purchase_amount))) %>% 
    ungroup() %>% 
    select(-hours) %>% 
    # 会計記録の差分
    group_by(card_id) %>% 
    mutate(purchase_date_diff = 
             difftime(purchase_date, lag(purchase_date, default=0 , order_by=purchase_date),
                      units = "days") %>% as.integer()) %>% 
    ungroup() %>% 
    # tmp1を結合
    left_join(tmp1,by="card_id")
  return(tmp)
}
# main
transactions <- preprocess_history(transactions)
new_transactions <- preprocess_history(new_transactions)

#!!!!!!!!!!!!! merchants data !!!!!!!!!!!!!#
merchants <- merchants %>% 
  # merchant_idが複数ある問題を解決 (この処理に妥当性はない)
  distinct(merchant_id, .keep_all = TRUE) %>% 
  # history data内で処理するid等は削除
  # target encoding 等で使用する場合は適宜検討
  select(-c(merchant_id, merchant_group_id,merchant_category_id,city_id,
            subsector_id,category_1,category_2, state_id)) 

### save file ### 
write_feather(train, "~/Desktop/Elo_kaggle/input/processed/train.feather")
write_feather(test, "~/Desktop/Elo_kaggle/input/processed/test.feather")
write_feather(transactions, "~/Desktop/Elo_kaggle/input/processed/historical_transactions.feather")
write_feather(new_transactions, "~/Desktop/Elo_kaggle/input/processed/new_merchant_transactions.feather")
write_feather(merchants, "~/Desktop/Elo_kaggle/input/processed/merchants.feather")
