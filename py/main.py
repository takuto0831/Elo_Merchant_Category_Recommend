import numpy as np # linear algebra
import pandas as pd # data processing
import feather # fast reading data
import os
from datetime import datetime
from models.Regressor import Ridge_Regressor, Lasso_Regressor, Bagging_Regressor
from sklearn.metrics import mean_squared_error

def read_data(train_name,test_name,features_name):
    #Loading Train and Test Data
    Base = home_path + "/Desktop/Elo_kaggle/input/processed/"
    train = feather.read_dataframe(Base + train_name + ".feather")
    test = feather.read_dataframe(Base + test_name + ".feather")
    features = feather.read_dataframe(Base + features_name + ".feather")
    # check data frame
    print("{} observations and {} features in train set.".format(train.shape[0],train.shape[1]))
    print("{} observations and {} features in test set.".format(test.shape[0],test.shape[1]))
    print("{} observations and {} features in features set.".format(features.shape[0],features.shape[1]))
    # transform
    target = train['target']; del train['target'] # data set
    features = features["feature"].tolist() # features list
    return train, test, features, target
def submit(predict,tech):
    # make submit file
    submit_file = feather.read_dataframe(home_path + "/Desktop/Elo_kaggle/input/feather/sample_submission.feather")
    submit_file["target"] = predict
    # save for output/(technic name + datetime + .csv)
    file_name = home_path + '/Desktop/Elo_kaggle/output/' + tech + datetime.now().strftime("%Y%m%d") + ".csv"
    submit_file.to_csv(file_name, index=False)
def main():
    # read file
    train_name = "train_20181223"; test_name = "test_20181223"; features_name = "features_20181223";
    train, test, features, target = read_data(train_name,test_name,features_name)
    # Ridge regression
    val_pred_ridge, test_pred_ridge = Ridge_Regressor(train,test,features,target) 
    # Lasso regression
    val_pred_lasso, test_pred_lasso = Lasso_Regressor(train,test,features,target) 
    # Ensemble regression (bagging)
    val_pred_bag, test_pred_bag = Bagging_Regressor(train,test,features,target) 
    # print validation RMSE 
    print("Ridge regression validation RMSE: %.4f" % np.sqrt(mean_squared_error(target.values, val_pred_ridge)))
    print("Lasso regression validation RMSE: %.4f" % np.sqrt(mean_squared_error(target.values, val_pred_lasso)))
    print("Bagging regression validation RMSE: %.4f" % np.sqrt(mean_squared_error(target.values, val_pred_bag)))
    # submit file
    submit(test_pred_ridge,"Ridge")
    submit(test_pred_lasso,"Lasso")
    submit(test_pred_bag,"Bagging")
if __name__ == "__main__":
    home_path = os.path.expanduser("~")
    main()
