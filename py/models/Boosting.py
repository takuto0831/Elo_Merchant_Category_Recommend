import numpy as np # linear algebra
import pandas as pd # data processing, CSV file I/O (e.g. pd.read_csv)
import lightgbm as lgb
import xgboost as xgb
from sklearn.model_selection import StratifiedKFold
from sklearn.metrics import mean_squared_error

def Validation(k):
  return StratifiedKFold(n_splits=k, shuffle=True, random_state=15)
def Lightgbm_Regressor():
  # parameters
  param = {'num_leaves': 120,
           'min_data_in_leaf': 30, 
           'objective':'regression',
           'max_depth': -1,
           'learning_rate': 0.005,
           "min_child_samples": 30,
           "boosting": "gbdt",
           "feature_fraction": 0.9,
           "bagging_freq": 1,
           "bagging_fraction": 0.9 ,
           "bagging_seed": 11,
           "metric": 'rmse',
           "lambda_l1": 0.1,
           "verbosity": -1}
  # model         
  oof_lgb = np.zeros(len(train))
  predictions_lgb = np.zeros(len(test))
  ## k-stratified k-Fold
  folds = Validation(5)
  for fold_, (trn_idx, val_idx) in enumerate(folds.split(train,train['outliers'].values)):    
    print('-')
    print("Fold {}".format(fold_ + 1))
    trn_data = lgb.Dataset(train.iloc[trn_idx][features], label=target.iloc[trn_idx])
    val_data = lgb.Dataset(train.iloc[val_idx][features], label=target.iloc[val_idx])

    num_round = 10000
    clf = lgb.train(param, trn_data, num_round, valid_sets = [trn_data, val_data], verbose_eval=100, early_stopping_rounds=200)
    oof_lgb[val_idx] = clf.predict(train.iloc[val_idx][features], num_iteration=clf.best_iteration)
    predictions_lgb += clf.predict(test[features], num_iteration=clf.best_iteration) / folds.n_splits
    np.save('oof_lgb', oof_lgb)
    np.save('predictions_lgb', predictions_lgb)
    np.sqrt(mean_squared_error(target.values, oof_lgb))
