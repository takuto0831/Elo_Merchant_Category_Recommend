library(rvest)
library(tidyverse)

# ブラジルの祝日情報
data_2017 <- read_html("https://www.timeanddate.com/holidays/brazil/2017", encoding = "UTF-8")
data_2018 <- read_html("https://www.timeanddate.com/holidays/brazil/2018", encoding = "UTF-8")

# tableデータを抽出し, 変形する
make_table <- function(data,Year){
  tmp <- data %>% 
    html_table() %>% 
    .[[1]] %>% 
    as.data.frame() %>% 
    filter(Date != "Date") %>% 
    mutate(Date = str_replace(Date,"日","")) %>%
    mutate(Date = case_when(
      str_length(Date) == 2 ~ str_c("0",Date,sep = ""),
      str_length(Date) == 3 & as.integer(Date) >= 130 ~ str_c("0",Date,sep = ""),
      TRUE ~ Date)) %>% 
    mutate(Date = str_c(Year,Date,sep = "") %>% 
             parse_date_time2(.,orders = "ymd",tz = "Brazil") %>% 
             as.Date(tz = "Brazil"))
  return(tmp)
}
# 祝日による他の曜日への効果を導入する
check_pre_holiday <- function(data){
  data %>% 
    filter(`Holiday Type` == "National Holiday") %>% 
    filter(Weekday != "日曜日", Weekday != "月曜日") %>% 
    mutate(Date = Date - days(1),
           `Holiday Type` = "Pre Holiday") %>% 
    bind_rows(data,.) %>% 
    arrange(Date) %>% 
    distinct(Date,.keep_all = TRUE) %>% 
    mutate(Holiday_info = 
             case_when(`Holiday Type` == "Pre Holiday" ~ 1,
                       TRUE ~ 2)) %>%
    select(Date,Holiday_info) %>% 
    return()
}

# main
tmp1 <- make_table(data_2017, Year = "17")
tmp2 <- make_table(data_2018, Year = "18")

bind_rows(tmp1,tmp2) %>% 
  check_pre_holiday() %>% 
  write_csv("~/Desktop/Elo_kaggle/input/original/holiday_list.csv")
