import numpy as np # linear algebra
import pandas as pd # data processing 
from sklearn.model_selection import StratifiedKFold

def Validation(k):
    return StratifiedKFold(n_splits=k, shuffle=True, random_state=831)
