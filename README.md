# Elo_Merchant_Category_Recommendation_Kaggle

Diners Club(クレジットカード)

## Overview

"知らない街でお腹が空いた時, 瞬時に個人の好みに基づいたレストランのレコメンドを得る. お勧めは, コーナーの近くの地元の場所にあなたのクレジットカード会社からの添付割引が付属しています！"

"Elo"はブラジル最大の決済ブランドの一つであり, カード会員へのプロモーションや割引を提供するために, 加盟店と提携している. しかし, これらのプロモーションは消費者または加盟店のどちらに取っても有効であるか? 顧客は自分の経験を楽しんでいるか? お店は繰り返し事業を見ているか? ここの趣向が重要である!!

"Elo"は食品から買い物まで, 顧客のライフサイクルにとって重要な側面や好みを解釈する機械学習モデルを持っている. しかしこれまでのところ, 個人やプロフィールのために特別に調整されたものではない.そこであなたたちの出番です!!

このコンペティションでは, 顧客ロイヤリティのシグナルを明らかにすることによって, 個人に最も関連のある機会を特定して提供するアルゴリズムを開発する. 顧客の生活を向上し, "Elo"が不必要なキャンペーンを行うのを減らし, 顧客に正しい経験を生み出す.

## Evaluation

Root Mean Squared Error (RMSE)を利用する. カードidごとに, y_hatはロイヤリティの予測値, yはロイヤリティの実測値を表す.

<img src="https://latex.codecogs.com/gif.latex?\centering&space;\mbox{RMSE}&space;=&space;\sqrt{\frac{1}{n}\sum_{i=1}^n(y_i&space;-&space;\hat{y}_i)^2}"/>

## Data

- train.csv,test.csv:

訓練データおよび予測に使用するデータ, `card_id`が各顧客のidとなる.

- historical_transactions.csv, new_merchant_transactions.csv:

それそれのカードにおける取引情報を含み, 前者は3ヶ月間の全てのカードの`merchant_id`ごとの取引情報を含み, 後者は新しい加盟店との取引情報(任意のカードにおいてまだ訪問されていない`merchant_id`)が2ヶ月間含まれている.

- merchants.csv:

それぞれの`merchant_id`に関する情報を含む.

- Data_Dictionary.xlsx:

テーブル説明,データの諸情報追加する.

## Purpose

このコンペティションでは, 顧客ロイヤリティのシグナルを明らかにすることによって, 個人に最も関連のある機会を特定して提供するアルゴリズムを開発する. 顧客の生活を向上し, "Elo"が不必要なキャンペーンを行うのを減らし, 顧客に正しい経験を生み出す. 

# Directory

```
├── Elo_kaggle.Rproj
├── README.md
├── input
│   ├── About_data.xlsx
│   ├── feather
│   │   ├── historical_transactions.feather
│   │   ├── merchants.feather
│   │   ├── new_merchant_transactions.feather
│   │   ├── sample_submission.feather
│   │   ├── test.feather
│   │   └── train.feather
│   ├── original
│   │   ├── historical_transactions.csv
│   │   ├── merchants.csv
│   │   ├── new_merchant_transactions.csv
│   │   ├── sample_submission.csv
│   │   ├── test.csv
│   │   └── train.csv
│   └── processed
├── jn
│   ├── Kaggle_kernel_tunguz.ipynb
│   └── main.ipynb
├── output
│   ├── Bagging20181224.csv
│   ├── Lasso20181224.csv
│   └── Ridge20181224.csv
├── py
│   ├── __pycache__
│   │   └── models.cpython-36.pyc
│   ├── main.py
│   └── models
│       ├── Ensemble.py
│       ├── GradientBoosting.py
│       ├── Regressor.py
│       ├── __init__.py
│       └── __pycache__
│           ├── Boosting.cpython-36.pyc
│           ├── GradientBoosting.cpython-36.pyc
│           ├── Regressor.cpython-36.pyc
│           └── Ridge_Regressor.cpython-36.pyc
├── rmd
│   ├── EDA.Rmd
│   └── EDA.html
└── script
    ├── convert_to_feather.R
    └── preprocess1.R
```
