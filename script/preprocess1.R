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

#### Feature engineering ####
# train data and test data
train <- train %>% 
  mutate(diff = anytime("2018-02-02") - anytime(first_active_month)) %>% # 時間差
  mutate(diff = diff %>% as.numeric()) %>% 
  mutate(outliers = if_else(target < -30,1,0)) %>% # クロスバリデーションで使用
  select(-first_active_month)
test <- test %>% 
  mutate(diff = anytime("2018-02-02") - anytime(first_active_month)) %>% # 時間差
  mutate(diff = diff %>% as.numeric()) %>% 
  select(-first_active_month)
# transaction_history and new_transaction_history
### function ###
aggregate_transactions <- function(data){
  # mode function
  mode <- function(data,col){
    # new col names
    new_col = paste(col,"_mode",sep="")
    # main
    data %>% 
      group_by_("card_id",col) %>% 
      summarise(count = n()) %>% 
      group_by_("card_id") %>% 
      top_n(n=1,wt=count) %>% 
      distinct(card_id,.keep_all =TRUE) %>% 
      ungroup() %>% 
      dplyr::select("card_id", col) %>%
      rename(!!new_col := col) %>% 
      return()
  }
  # convert data
  tmp <- 
    # flag, category1: 0 or 1に変更, category_2: factor typeに変更
    data %>% 
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
    # 日付情報, factorのid情報を削除
    select(-c(merchant_id, purchase_date))
  # お店カテゴリー(one hot encoding)
  tmp <- bind_cols(tmp %>% select(-c(category_2,category_3)),
                   makedummies(dat = tmp,basal_level = TRUE,col = c("category_2","category_3"))) 

  # aggregate
  tmp1 <- tmp %>% group_by(card_id) 
  # main 
  tmp2 <- 
    # 会計回数
    summarise(tmp1, pay_count = n()) %>% 
    # 各種idのカウント, NAも1種とする. 
    left_join(
      summarise_at(tmp1,c("city_id","merchant_category_id","merchant_label_id","state_id","subsector_id"), 
                   funs(n_distinct)),
      by = "card_id") %>%
    left_join(tmp %>% mode(col="city_id"),by = "card_id") %>% 
    left_join(tmp %>% mode(col="merchant_category_id"),by = "card_id") %>% 
    left_join(tmp %>% mode(col="merchant_label_id"),by = "card_id") %>% 
    left_join(tmp %>% mode(col="state_id"),by = "card_id") %>% 
    left_join(tmp %>% mode(col="subsector_id"),by = "card_id") %>%     
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
  # numeric変数を小数点第4位までとする
  tmp2 <- tmp2 %>% mutate_if(is.numeric, round, 4)
  return(tmp2)
}
## execute
transactions <- aggregate_transactions(transactions)
new_transactions <- aggregate_transactions(new_transactions) %>% 
  rename_if(!str_detect(names(.),"card_id"),. %>% tolower %>% str_c("_new",sep="")) # add column "_new"

# merchants data (データに問題あるため保留)

### combine data ### 
train <- train %>% 
  left_join(transactions,by="card_id") %>% 
  left_join(new_transactions, by="card_id")
test <- test %>% 
  left_join(transactions,by="card_id") %>% 
  left_join(new_transactions, by="card_id")

### save combine data ###
write_feather(train,"~/Desktop/Elo_kaggle/input/processed/train_20181223.feather")
write_feather(test,"~/Desktop/Elo_kaggle/input/processed/test_20181223.feather")
