import numpy as np # linear algebra
import pandas as pd # data processing, CSV file I/O (e.g. pd.read_csv)
from sklearn.linear_model import Ridge, Lasso
from sklearn.ensemble import BaggingRegressor
from sklearn.tree import DecisionTreeRegressor
from sklearn.model_selection import StratifiedKFold
from sklearn.metrics import mean_squared_error

### fitting model list ###
# Ridde(alpha=100)
# Lasso(alpha=100)
# BaggingRegressor(DecisionTreeRegressor(), n_estimators=100, max_samples=0.3)

def Validation(k):
    return StratifiedKFold(n_splits=k, shuffle=True, random_state=831)

def Regressors(clf,train,test,features,target,folds=5):
    ## predict data box
    validation_pred = np.zeros(train.shape[0])
    test_pred = np.zeros(test.shape[0])
    ## make test data
    test_data = test.copy()
    test_data = test_data.replace([np.inf, -np.inf], np.nan) # inf 処理
    test_data.fillna((test_data.mean()), inplace=True) # nan 処理
    test_data = test_data[features].values
    ## k-stratified k-Fold
    folds = Validation(folds)
    # 外れ値を考慮して, データを分割する
    for fold_, (trn_idx, val_idx) in enumerate(folds.split(train,train['target_class'].values)):
        print("fold n°{}".format(fold_+1))
        trn_data, trn_y = train.iloc[trn_idx][features], target.iloc[trn_idx].values
        val_data, val_y = train.iloc[val_idx][features], target.iloc[val_idx].values
        # fill Inf values
        trn_data = trn_data.replace([np.inf, -np.inf], np.nan)
        val_data = val_data.replace([np.inf, -np.inf], np.nan)
        # fill missing values
        trn_data.fillna((trn_data.mean()), inplace=True);
        val_data.fillna((val_data.mean()), inplace=True);
        # extract data
        trn_data = trn_data.values; val_data = val_data.values;
        # fitting arvitrary model for train data
        clf.fit(trn_data, trn_y);
        # predicting validation data and predicting data
        validation_pred[val_idx] = clf.predict(val_data)
        test_pred += clf.predict(test_data) / folds.n_splits
    return validation_pred, test_pred


