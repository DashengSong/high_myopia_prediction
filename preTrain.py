import numpy as np 
from sklearn.preprocessing import StandardScaler,OneHotEncoder
from sklearn.impute import SimpleImputer
from sklearn.compose import ColumnTransformer

# 计算权重
def calWeight(X,y):
    t=len(X)/(2*np.bincount(y))
    return t[1]/t[0]

def getPreprocess():
    catList=['familyHistory','basesef','basegrd','wearGlass']
    quanList=['baseucva']
    # 标准化
    numeric_preprocessor = StandardScaler()
    # One-Hot编码
    categorical_preprocessor =OneHotEncoder(handle_unknown="ignore",drop="first")
    # 组合预处理操作
    preprocessor= ColumnTransformer(
        transformers=[                
        ("num", numeric_preprocessor, quanList),
        ("cat", categorical_preprocessor, catList)
     ])       
    return preprocessor

def MakeParams():
    params={
        "cat":{
        "num_boost_round":np.arange(50,500,10),
        "learning_rate":np.arange(0.01,1,0.1),
        "l2_leaf_reg":np.arange(1e-3,10,0.01),
        'subsample':np.arange(0.5,1.0,0.1),
        'depth':np.arange(2,10,1),
        'auto_class_weights':['Balanced','SqrtBalanced']
        },
        "ANN":{
        "ANN__hidden_layer_sizes":[(50),(100),(150),(200)],
        "ANN__activation":['relu','tanh'],
        "ANN__alpha":np.arange(1e-4,1,0.0001),
        "ANN__learning_rate":['adaptive'],
        },
        "Logistic":{
        "Logistic__C": np.arange(0.1,1.1,0.1)
        },
        "rf":{
        "n_estimators":np.arange(100,1000,10),
        "max_depth":np.arange(2,10,1),
        "min_samples_split":np.arange(10,200,10),
        "class_weight":['balanced_subsample'],
        },
        "xgb":{
        "n_estimators":np.arange(100,300,50),
        "max_depth":np.arange(2,10,1),
        "learning_rate":np.arange(1e-2,0.3,0.01),
        "subsample":np.arange(0.5,1.0,0.1),
        "reg_alpha":np.arange(1e-3,10,0.1),
        "reg_lambda":np.arange(1e-3,10,0.1),
        "scale_pos_weight":[76.1,]
        },
        "gbm":{
        "n_estimators":np.arange(100,300,50),
        "max_depth":np.arange(2,10,1),
        "learning_rate":np.arange(1e-2,0.3,0.01),
        "subsample":np.arange(0.5,1.0,0.1),
        "reg_alpha":np.arange(1e-3,10,0.1),
        "reg_lambda":np.arange(1e-3,10,0.1)
        },
        "ada":{
        "n_estimators":np.arange(50,500,50),
        "learning_rate":np.arange(1e-3,10,0.01)
        }
    }
    return params