## binary column
col_binary <- c(# "authorized_flag", 
                "installments_minus",
                "installments_outlier",
                "normal_holiday",
                "public_holiday",
                "public_pre_holiday")
## numeric column
col_numeric <- c("installments",
                 "reference_date_diff",
                 "purchase_amount",
                 "purchase_amount_diff",
                 "purchase_amount_abs",
                 "purchase_date_diff",
                 "numerical_1",
                 "numerical_2",
                 "avg_sales_lag3",
                 "avg_purchases_lag3",
                 "active_months_lag3",
                 "avg_sales_lag6",
                 "avg_purchases_lag6",
                 "active_months_lag6",
                 "avg_sales_lag12",
                 "avg_purchases_lag12",
                 "active_months_lag12")
## category column
col_category <- c("city_id",
                  "merchant_category_id")

## one hot encoding list
one_hot_list <- c("month_lag", 
                  "category_1",
                  "category_2",
                  "category_3",
                  "state_id",
                  "subsector_id",
                  "most_recent_sales_range",
                  "most_recent_purchases_range",
                  "category_4",
                  "purchase_month",
                  "purchase_wday",
                  "purchase_hour")
