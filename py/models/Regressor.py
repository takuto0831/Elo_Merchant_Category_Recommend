import numpy as np # linear algebra
import pandas as pd # data processing, CSV file I/O (e.g. pd.read_csv)
from sklearn.linear_model import Ridge, Lasso
from sklearn.ensemble import BaggingRegressor
from sklearn.tree import DecisionTreeRegressor
from sklearn.model_selection import StratifiedKFold
from sklearn.metrics import mean_squared_error

def Validation(k):
  return StratifiedKFold(n_splits=k, shuffle=True, random_state=15)
def Ridge_Regressor(train,test,features,target):
  # model
  ## predict data box
  val_pred_ridge = np.zeros(train.shape[0])
  test_pred_ridge = np.zeros(test.shape[0])
  ## make test data
  test_data = test.copy()
  test_data.fillna((test_data.mean()), inplace=True)
  test_data = test_data[features].values
  ## k-stratified k-Fold
  folds = Validation(5)
  ## 実行
  # 外れ値を考慮して, データを分割する
  for fold_, (trn_idx, val_idx) in enumerate(folds.split(train,train['outliers'].values)):
    print("fold n°{}".format(fold_+1))
    trn_data, trn_y = train.iloc[trn_idx][features], target.iloc[trn_idx].values
    val_data, val_y = train.iloc[val_idx][features], target.iloc[val_idx].values
    # fill missing values
    trn_data.fillna((trn_data.mean()), inplace=True); val_data.fillna((val_data.mean()), inplace=True);
    # extract data
    trn_data = trn_data.values; val_data = val_data.values;
    # fitting model for train data
    clf = Ridge(alpha=100); clf.fit(trn_data, trn_y);
    # predicting validation data and predicting data
    val_pred_ridge[val_idx] = clf.predict(val_data)
    test_pred_ridge += clf.predict(test_data) / folds.n_splits
  return val_pred_ridge, test_pred_ridge
  
def Lasso_Regressor(train,test,features,target):
  # model
  ## predict data box
  val_pred_ridge = np.zeros(train.shape[0])
  test_pred_ridge = np.zeros(test.shape[0])
  ## make test data
  test_data = test.copy()
  test_data.fillna((test_data.mean()), inplace=True)
  test_data = test_data[features].values
  ## k-stratified k-Fold
  folds = Validation(5)
  ## 実行
  # 外れ値を考慮して, データを分割する
  for fold_, (trn_idx, val_idx) in enumerate(folds.split(train,train['outliers'].values)):
    print("fold n°{}".format(fold_+1))
    trn_data, trn_y = train.iloc[trn_idx][features], target.iloc[trn_idx].values
    val_data, val_y = train.iloc[val_idx][features], target.iloc[val_idx].values
    # fill missing values
    trn_data.fillna((trn_data.mean()), inplace=True); val_data.fillna((val_data.mean()), inplace=True);
    # extract data
    trn_data = trn_data.values; val_data = val_data.values;
    # fitting model for train data
    clf = Lasso(alpha=100); clf.fit(trn_data, trn_y);
    # predicting validation data and predicting data
    val_pred_ridge[val_idx] = clf.predict(val_data)
    test_pred_ridge += clf.predict(test_data) / folds.n_splits
  return val_pred_ridge, test_pred_ridge

def Bagging_Regressor(train,test,features,target):
  # model
  ## predict data box
  val_pred_ridge = np.zeros(train.shape[0])
  test_pred_ridge = np.zeros(test.shape[0])
  ## make test data
  test_data = test.copy()
  test_data.fillna((test_data.mean()), inplace=True)
  test_data = test_data[features].values
  ## k-stratified k-Fold
  folds = Validation(5)
  ## 実行
  # 外れ値を考慮して, データを分割する
  for fold_, (trn_idx, val_idx) in enumerate(folds.split(train,train['outliers'].values)):
    print("fold n°{}".format(fold_+1))
    trn_data, trn_y = train.iloc[trn_idx][features], target.iloc[trn_idx].values
    val_data, val_y = train.iloc[val_idx][features], target.iloc[val_idx].values
    # fill missing values
    trn_data.fillna((trn_data.mean()), inplace=True); val_data.fillna((val_data.mean()), inplace=True);
    # extract data
    trn_data = trn_data.values; val_data = val_data.values;
    # fitting model for train data
    reg = BaggingRegressor(DecisionTreeRegressor(), n_estimators=100, max_samples=0.3)
    reg.fit(trn_data, trn_y)
    # predicting validation data and predicting data
    val_pred_ridge[val_idx] = reg.predict(val_data)
    test_pred_ridge += reg.predict(test_data) / folds.n_splits
  return val_pred_ridge, test_pred_ridge
