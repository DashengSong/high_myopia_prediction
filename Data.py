
import pandas as pd 
import numpy as np 
from sklearn.model_selection import train_test_split,cross_validate,StratifiedKFold


def transform_data():
    # 数据导入和划分
    students=pd.read_pickle("./Data/students.pkl")
    students.dropna(axis=0,inplace=True)
    students['glass']=np.where(students['glass']>=2,2,1)
    students=students[students['odse']>-6]
    # 根据IV图，保留7个建模变量
    #features=['odse','vision','oducva','age','graden','parentmy','diffh']
    catList=['graden','parentmy','vision','glass','paper','parentedu','recreation','study',
             'exerdur','gender']
    quanList=['odse','oducva','age']
    X,y=students.loc[:,catList+quanList],students['label']
    students=students[catList+quanList+['label']]
    # 拆分数据
    Xtrain,Xtest,ytrain,ytest=train_test_split(X,y,train_size=0.8,random_state=1234,stratify=y)
    Xtrain[catList]=Xtrain[catList].astype(int)
    Xtest[catList]=Xtest[catList].astype(int)
    return Xtrain,Xtest,ytrain,ytest,students