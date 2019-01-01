import numpy as np # linear algebra
import pandas as pd # data processing
import feather # fast reading data
from datetime import datetime
import pickle,requests
import matplotlib.pyplot as plt
import seaborn as sns

def read_data(train_name,test_name,features_name, home_path):
    #Loading Train and Test Data
    Base = home_path + "/Desktop/Elo_kaggle/input/aggregated/"
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
def line(text):
    line_notify_token = '07tI1nvYaAtGaLdsCaxKZxkboOU0OsvLregXqodN2ZV' #先程発行したコードを貼ります
    line_notify_api = 'https://notify-api.line.me/api/notify'
    message = '\n' + text
    #変数messageに文字列をいれて送信します トークン名の隣に文字が来てしまうので最初に改行しました
    payload = {'message': message}
    headers = {'Authorization': 'Bearer ' + line_notify_token}
    line_notify = requests.post(line_notify_api, data=payload, headers=headers)
def display_importances(features,model,title,home_path,file_name = None):
    # make data frame
    importance_df = pd.DataFrame({'feature':features, 'importance':model.feature_importance()})
    plt.figure(figsize=(14,25))
    sns.barplot(x="importance",y="feature",
                data=importance_df.sort_values(by="importance", ascending=False))
    plt.title(title)
    plt.tight_layout()
    if file_name is not None: 
        plt.savefig(home_path + '/Desktop/Elo_kaggle/output/image/' + file_name)
