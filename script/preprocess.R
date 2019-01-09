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
holidays <- read_csv("~/Desktop/Elo_kaggle/input/original/holiday_list.csv")

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
           case_when(target < -30 ~ 1,TRUE ~ 2)) # クロスバリデーションで使用

test <- test %>% 
  preprocess_train 

#!!!!!!!!!!!!! authorized mean !!!!!!!!!!!!!#
authorized_mean <- transactions %>% 
  mutate(authorized_flag = if_else(authorized_flag == "Y",0,1)) %>% 
  group_by(card_id) %>% 
  summarise(authorized_mean = mean(authorized_flag)) %>% 
  ungroup()

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
    mutate(reference_date_diff = difftime(as.POSIXct("2018-02-28 23:59:59",tz="Brazil"), reference_date,
                                          units = "days") %>% as.integer()) %>% 
    select(card_id,reference_date_diff)
  # main
  tmp <- data %>% 
    # 購入月, 曜日を追加
    mutate(purchase_month = month(purchase_date),
           purchase_wday = wday(purchase_date)) %>% 
    # 祝日, 祝前日情報を付与(一時的に Date列を用意)
    mutate(Date = as.Date(strftime(purchase_date, "%Y-%m-%d"))) %>% 
    left_join(.,holidays,by = "Date") %>% 
    # 祝日であるか? 祝前日であるか?土日であるかどうか?のカラムを用意
    mutate(normal_holiday = 
             case_when(purchase_wday == 1 ~ 1,
                       purchase_wday == 7 ~ 1,
                       TRUE ~ 0),
           public_holiday =
             case_when(Holiday_info == 2 ~ 1,
                       TRUE ~ 0),
           public_pre_holiday = 
             case_when(Holiday_info == 1 ~ 1,
                       TRUE ~ 0)) %>% 
    # 不要列削除
    select(-Date,-Holiday_info) %>% 
    # category_2, month_lag, state_id, subsector_idをfactor型に, installmentsをint型に
    mutate(category_2 = category_2 %>% as.factor,
           month_lag = month_lag %>% as.factor,
           state_id = state_id %>% as.factor,
           subsector_id = subsector_id %>% as.factor,
           installments = installments %>% as.integer) %>% 
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
    # authorized_flagの削除
    select(-authorized_flag) %>% 
    # tmp1を結合
    left_join(tmp1,by="card_id")
  return(tmp)
}
# main
authorized_transactions <- transactions %>% 
  mutate(authorized_flag = if_else(authorized_flag == "Y",0,1)) %>% 
  filter(authorized_flag == 1) %>% 
  preprocess_history
history_transactions <- transactions %>% 
  mutate(authorized_flag = if_else(authorized_flag == "Y",0,1)) %>% 
  filter(authorized_flag == 0) %>% 
  preprocess_history
new_transactions <- new_transactions %>% 
  mutate(authorized_flag = if_else(authorized_flag == "Y",0,1)) %>% 
  preprocess_history

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
write_feather(authorized_mean, "~/Desktop/Elo_kaggle/input/processed/authorized_mean.feather")
write_feather(authorized_transactions, "~/Desktop/Elo_kaggle/input/processed/authorized_transactions.feather")
write_feather(history_transactions, "~/Desktop/Elo_kaggle/input/processed/history_transactions.feather")
write_feather(new_transactions, "~/Desktop/Elo_kaggle/input/processed/new_transactions.feather")
write_feather(merchants, "~/Desktop/Elo_kaggle/input/processed/merchants.feather")
