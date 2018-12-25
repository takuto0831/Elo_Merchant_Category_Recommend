import numpy as np # linear algebra
import pandas as pd # data processing, CSV file I/O (e.g. pd.read_csv)
import lightgbm as lgb
import xgboost as xgb
from sklearn.model_selection import StratifiedKFold
from sklearn.metrics import mean_squared_error

def Validation(k):
    return StratifiedKFold(n_splits=k, shuffle=True, random_state=831)
    
def Regressors(algorithm,param_set,train,test,features,target,folds=5):
    ## predict data box
    validation_pred = np.zeros(train.shape[0])
    test_pred = np.zeros(test.shape[0])
    ## k-stratified k-Fold
    folds = Validation(folds)
    # 外れ値を考慮して, データを分割する
    for fold_, (trn_idx, val_idx) in enumerate(folds.split(train,train['outliers'].values)):
        print("fold n°{}".format(fold_+1))
        # make model
        validation_pred, test_pred, model = algorithm(train,trn_idx,val_idx,features,target,param_set, \
                                                      validation_pred,test_pred)
    return validation_pred, test_pred, model
    
def Lightgbm_Regressor(train,trn_idx,val_idx,features,target,param_set,validation_pred,test_pred):
    # data set
    trn_data = lgb.Dataset(train.iloc[trn_idx][features], label=target.iloc[trn_idx])
    val_data = lgb.Dataset(train.iloc[val_idx][features], label=target.iloc[val_idx])
    # model
    model = lgb.train(param_set, trn_data, num_boost_round=10000, valid_sets = [trn_data, val_data], \
                      verbose_eval=100, early_stopping_rounds=200)
    # predicting validation data and predicting data
    validation_pred[val_idx] = model.predict(train.iloc[val_idx][features], num_iteration=model.best_iteration)
    test_pred += model.predict(test[features], num_iteration=model.best_iteration) / folds.n_splits
    return validation_pred, test_pred, model

def Xgboost_Regressor(train,trn_idx,val_idx,features,target,param_set,validation_pred,test_pred):
    # data set
    trn_data = xgb.DMatrix(data=train.iloc[trn_idx][features], label=target.iloc[trn_idx])
    val_data = xgb.DMatrix(data=train.iloc[val_idx][features], label=target.iloc[val_idx])
    # model
    model = xgb.train(param_set, trn_data, evals = [(trn_data, 'train'), (val_data, 'valid')], \
                      num_boost_round = 10000, early_stopping_rounds=200, verbose_eval= 100)
    # predicting validation data and predicting data             
    validation_pred[val_idx] = model.predict(xgb.DMatrix(train.iloc[val_idx][features]), \
                                             ntree_limit = model.best_ntree_limit+50)
    test_pred += model.predict(xgb.DMatrix(test[features]), \
                               ntree_limit=model.best_ntree_limit+50) / folds.n_splits
    return validation_pred, test_pred, model
