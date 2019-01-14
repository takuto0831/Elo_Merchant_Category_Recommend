import numpy as np # linear algebra
import pandas as pd # data processing
import feather # fast reading data
from datetime import datetime
import pickle,requests
import matplotlib.pyplot as plt
import seaborn as sns
import time, os
from contextlib import contextmanager

def line(text):
    line_notify_token = '07tI1nvYaAtGaLdsCaxKZxkboOU0OsvLregXqodN2ZV' #先程発行したコードを貼ります
    line_notify_api = 'https://notify-api.line.me/api/notify'
    message = '\n' + text
    #変数messageに文字列をいれて送信します トークン名の隣に文字が来てしまうので最初に改行しました
    payload = {'message': message}
    headers = {'Authorization': 'Bearer ' + line_notify_token}
    line_notify = requests.post(line_notify_api, data=payload, headers=headers)
    
def read_data(train_name,test_name,features_name, best_features_name,num,home_path):
    #Loading Train and Test Data
    Base = home_path + "/Desktop/Elo_kaggle/input/aggregated/"
    train = feather.read_dataframe(Base + train_name + ".feather")
    test = feather.read_dataframe(Base + test_name + ".feather")
    features = feather.read_dataframe(Base + features_name + ".feather")
    # check data frame
    print("{} observations and {} features in train set.".format(train.shape[0],train.shape[1]))
    print("{} observations and {} features in test set.".format(test.shape[0],test.shape[1]))
    print("{} observations and {} features in features set.".format(features.shape[0],features.shape[1]))
    # about best features
    if os.path.exists(home_path + "/Desktop/Elo_kaggle/input/features/" + best_features_name + ".feather"):
        best_features = feather.read_dataframe(home_path + "/Desktop/Elo_kaggle/input/features/" + best_features_name + ".feather")
        print("{} observations and {} features in features importance set.".format(best_features.shape[0],best_features.shape[1]))
        best_features = best_features["feature"].tolist()[:num] # features to list
    else: 
        best_features = []
        print("not exist best features list")   
    # extract target
    target = train['target']; # 必要??
    features = features["feature"].tolist() # features list
    return train, test, features, best_features, target
def submit(predict,tech, home_path):
    # make submit file
    submit_file = feather.read_dataframe(home_path + "/Desktop/Elo_kaggle/input/feather/sample_submission.feather")
    submit_file["target"] = predict
    # save for output/(technic name + datetime + .csv)
    file_name = home_path + '/Desktop/Elo_kaggle/output/submit/' + tech + datetime.now().strftime("%Y%m%d") + ".csv"
    submit_file.to_csv(file_name, index=False)
def open_parameter(file_name, home_path):
    f = open(home_path + '/Desktop/Elo_kaggle/input/parameters/' + file_name + '.txt', 'rb')
    list_ = pickle.load(f)
    return list_
def display_importances(importance_df,title,home_path,file_name = None):
    cols = (importance_df[["feature", "importance"]]
            .groupby("feature")
            .mean()
            .sort_values(by="importance", ascending=False)[:500].index)
    best_features = importance_df.loc[importance_df.feature.isin(cols)]
    plt.figure(figsize=(14,80))
    sns.barplot(x="importance",y="feature",
                data=best_features.sort_values(by="importance",ascending=False))
    plt.title(title + 'Features (avg over folds)')
    plt.tight_layout()
    # save or not
    if file_name is not None: 
        plt.savefig(home_path + '/Desktop/Elo_kaggle/output/image/' + file_name)
def extract_best_features(importance_df,num,home_path,file_name = None):
    cols = (importance_df[["feature", "importance"]]
            .groupby("feature")
            .mean()
            .sort_values(by="importance", ascending=False)
            .reset_index())
    # save or not
    if file_name is not None: 
        feather.write_dataframe(cols, home_path + '/Desktop/Elo_kaggle/input/features/' + file_name + '.feather')
    return cols[:num]["feature"].tolist()

@contextmanager
def timer(title):
    start = time.time()
    yield
    end = time.time()
    line("{} - done in {:.0f}s".format(title, end-start))
