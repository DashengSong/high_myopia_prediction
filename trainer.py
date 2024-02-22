
import joblib
from sklearn.model_selection import cross_validate
import pandas as pd 
import numpy  as np
from sklearn.calibration import CalibratedClassifierCV

class trainer():
    def __init__(self,models):
        self.models=models
        self.optimizers=None
        self.fitted=False  
        self._trained={}
        self._hasfit={} 
        for k in self.models.keys():
            self._trained[k]=True
            self._hasfit[k]=False
            
        
    def __repr__(self) -> str:
        return f"Trainer中包含的模型是:{list(self.models.keys())}"
        
    def setup(self,optimizer,params,cv,*args,**kwargs):
        '''
        Object:
            训练模型,产生最佳参数\n
        Params:
            optimizer: sklearn样式的优化器,比如:RandomizedSearchCV,GridSearchCV...\n
            cv: 交叉验证,可以是数字,或者cv对象\n
            *args,**kwargs:其它指定给optimizer的参数
        '''
        if not self.models:
            print("必须指定模型！")
        trainedModels={}
        for k,v in self._trained.items():
            if v:
                trainedModels[k]=self.models[k]
        assert len(trainedModels)==len(params),"模型个数和参数不一致，请检查!"
        assert trainedModels.keys()==params.keys(),"模型字典的键要和参数字典的键值相等"
        self.optimizers={}
        for model in trainedModels.keys():
            if self._trained.get(model):
                self.optimizers[model]=optimizer(trainedModels[model],params[model],cv=cv,refit=True,*args,**kwargs)
                
    def setTrained(self,trained=None):
        '''
            Object:\n
                设置模型是否添加到优化器以进行超参数搜索\n
            Params:\n
                trained: 以模型名为key的逻辑字典,如果不需要进行超参数搜索,设置为False;\n
                         否则设置为True
        ''' 
        for k,v in trained.items():
            if self.models.get(k):
                self._trained[k]=v
                print(f"{k}已经设置为不进行超参数搜索!")
            else:
                print(f"{k}不在待训练的模型中，请检查!")
            
    
    def addModels(self,name,model,searchHyper=True):
        '''
            Object:\n
                添加模型到Trainer对象\n
            Params:\n
                name,model: 模型名字和对象\n
                searchHyper: 是否需要进行超参数优化,默认True
        '''
        self.models[name]=model
        self._trained[name]=searchHyper

    def fit(self,x,y,*args, **kwargs):
        '''
            Object:\n
                开始寻找超参数\n
            Params:\n
                x,y: 训练特征(X)和标签(Y)\n
               *args, **kwargs: 其它给fit的模型参数字典
        '''
        if len(self.optimizers)==0:
            print("需要先调用setup方法!")
        else:
            n=len(self.optimizers)
            for i,o in enumerate(self.optimizers.keys()):
                print(f"共有{n}个模型,开始训练{i+1}个,模型是{o}...")
                if not self._hasfit.get(o):
                    try:
                        self.optimizers[o].fit(x,y,*args,**kwargs)
                        self.models[o]=self.optimizers[o].best_estimator_
                        self._hasfit[o]=True
                    except Exception as e:
                        print(f"{o}无法训练，原因是:{e}")
                        continue
                else:
                    print(f"{o}已经训练过，无需再次训练")
            self.fitted=True
            
    def get_best_params(self):
        '''
        Object:
            返回train之后的最佳参数
        '''
        assert self.fitted==True,"模型必须先被训练"
        best_params={}
        for k,v in self.optimizers.items():
            best_params[k]=v.best_params_
        return best_params

    def get_best_score(self):
        '''
        Object:
            返回最佳得分
        '''
        assert self.fitted==True,"模型必须先被训练"
        best_scores={}
        for k,v in self.optimizers.items():
            best_scores[k]=v.best_score_
        return best_scores      

    def get_cv_result(self):
        '''
        Object:
            返回train之后的cv结果
        '''
        assert self.fitted==True,"模型必须先被训练"
        cv_results={}
        for k,v in self.optimizers.items():
            cv_results[k]=v.cv_results_
        return cv_results
        
    def get_best_estimator(self):
        '''
        Object:
            返回train之后的最佳模型
        '''
        assert self.fitted==True,"模型必须先被训练"
        return self.models
    
    def get_metrics(self,X,y,scores=None,cv=10,summary=True,*args, **kwargs):
        '''
        Object:
            返回模型的交叉验证得分
        params:
            X,y:需要计算得分的特征和标签\n
            scores:测量指标,同sklearn中的mertics,参考:https://scikit-learn.org/stable/modules/model_evaluation.html#model-evaluation
            
        '''
        assert self.fitted==True,"模型必须先被训练"
        cv_scores={}
        for k,v in self.models.items():
            cv_scores[k]=cross_validate(v,X,y,n_jobs=-1,cv=cv,scoring=scores,*args, **kwargs)
        if summary:
            return pd.DataFrame.from_dict(cv_scores,orient="index").map(func=np.mean)
        return cv_scores

    
    def save_model(self,object="trainer",file=None):
        '''
        Object:\n
            保存训练好的模型\n
        Params:\n
            object: 保存的内容，'all':保存训练过程中的所有内容；"params":仅仅保存训练好的最佳参数; "model":保存训练好的最佳模型\n
            file: 保存文件地址
        '''
        if self.fitted:
            if object=="optim":
                joblib.dump(self.optimizers,file)
            elif object=="params":
                joblib.dump(self.get_params(),file)
            elif object=="model":
                joblib.dump(self.models,file)
            elif object=="trainer":
                joblib.dump(self,file)
            else:
                print("object必须是['params','model','trainer','optim']中的一个")
        else:
            print("需要先训练后保存!")
    
    def predict(self,X,y,newdata=None,proba=True):
        '''
            Object:\n
                用训练好的模型去预测;\n
            Params:\n
                X:待预测的样本;\n
        '''
        outcome={}
        newdata=newdata if newdata else X
        for k,v in self.models.items():
            v.fit(X,y)
            try:
                if proba:
                    outcome[k]=v.predict_proba(newdata)
                else:
                    outcome[k]=v.predict(newdata)
            except Exception:
                outcome[k]=None
                print(f"{k}出现异常,跳过")
                continue
        return outcome

    def status(self):
        '''
            Object:\n
                返回模型拟合状态
        '''
        return pd.DataFrame([self._hasfit])
    
    def addCalibration(self,model=None,method='sigmoid',*args, **kwargs):
        '''
            Objects:\n
                对模型进行校准\n
            Params:\n
                model:模型的key,如果不指定,则对Trainer中的所有模型进行校准;
            *args,**kwargs:其它传递给CalibratedClassifierCV的参数,
            参考:https://scikit-learn.org/stable/modules/generated/sklearn.calibration.CalibratedClassifierCV.html#sklearn.calibration.CalibratedClassifierCV
        '''
        if not model:
            calibrated_models={k:CalibratedClassifierCV(v,method=method,*args, **kwargs) for k,v in self.models.items()}
            return calibrated_models
        return CalibratedClassifierCV(self.models[model],method=method,*args, **kwargs)
    @staticmethod
    def load_model(file):
        '''
            Object:\n
                加载保存的模型\n
            Params:\n
                file: 模型存储文件
        '''
        return joblib.load(file)