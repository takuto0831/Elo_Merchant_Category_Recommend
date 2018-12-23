import numpy as np # linear algebra
import pandas as pd # data processing, CSV file I/O (e.g. pd.read_csv)
import feather
from datetime import datetime
from models.Ridge_Regressor import Ridge_Regressor 
from sklearn.metrics import mean_squared_error

def submit(predict,tech):
  # make submit file
  submit_file = feather.read_dataframe("/Users/takuto/Desktop/Elo_kaggle/input/feather/sample_submission.feather")
  submit_file["target"] = predict
  # save for output/(technic name + datetime + .csv)
  file_name = '/Users/takuto/Desktop/Elo_kaggle/output/' + tech + datetime.now().strftime("%Y%m%d") + ".csv"
  submit_file.to_csv(file_name, index=False)
def main():
  #Loading Train and Test Data
  train = feather.read_dataframe("/Users/takuto/Desktop/Elo_kaggle/input/processed/train_20181223.feather")
  test = feather.read_dataframe("/Users/takuto/Desktop/Elo_kaggle/input/processed/test_20181223.feather")
  print("{} observations and {} features in train set.".format(train.shape[0],train.shape[1]))
  print("{} observations and {} features in test set.".format(test.shape[0],test.shape[1]))
  # data set
  target = train['target']
  del train['target']
  features = [c for c in train.columns if c not in ['card_id', 'outliers']]
  # Ridge
  val_pred_ridge, test_pred_ridge = Ridge_Regressor(train,target,test,features)
  # print validation RMSE 
  print("Ridge regression validation RMSE: %.4f" % np.sqrt(mean_squared_error(target.values, val_pred_ridge)))
  # submit file
  submit(test_pred_ridge,"Ridge")
if __name__ == "__main__":
    main()
