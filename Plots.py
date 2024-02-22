
from sklearn.metrics import RocCurveDisplay,PrecisionRecallDisplay
from sklearn.calibration import CalibrationDisplay
import matplotlib.pyplot as plt 
from sklearn.metrics import confusion_matrix
import numpy as np

# ROC/PR/Calibration cruve
def plot_curve(models,X,y,type="roc",rows=1,cols=1,labels=None,file=None,legendPos=None,**pltparams):
    '''
    绘制各个模型的ROC/PR曲线
    参数:
        models: 模型列表
        X,y: 数据和真实标签
        type: roc-ROC曲线; pr-PR曲线
        file: ROC曲线保存路径
        row,col:网格行数和列数
        labels:模型标签
        **pltparams: 传递给plot的绘图参数,待用
    '''
    if not isinstance(models,list):
        raise TypeError("models必须是字典")
    assert type in ['roc','pr','cr'],"type必须是roc,pr和cr中的一个"
    fig,axs=plt.subplots(nrows=rows,ncols=cols)
    if type=='roc':
        obj=RocCurveDisplay
        labely="FPR"
        labelx="TPR"
    elif type=='pr':
        obj=PrecisionRecallDisplay
        labely="Precision"
        labelx="Recall"
    else:
        obj=CalibrationDisplay
        labelx="Mean Prediction probability"
        labely="Fraction of positives"
    index=0
    if rows*cols>1:
        assert len(models)==rows*cols,"模型数必须与rows*cols相等"
        for r in range(rows):
            for c in range(cols):
                obj.from_estimator(models[index],X,y,ax=axs[r,c],name=labels[index] if labels else None,**pltparams)
                axs[r,c].set(xlabel=labelx,ylabel=labely)
                axs[r,c].legend(loc=legendPos)
                index+=1
    else:
        for _ in models:
            try:
                obj.from_estimator(models[index],X,y,ax=axs,name=labels[index] if labels else None,**pltparams)
            except Exception as e:
                models[index].fit(X,y)
                obj.from_estimator(models[index],X,y,ax=axs,name=labels[index] if labels else None,**pltparams)
            axs.set(xlabel=labelx,ylabel=labely)
            axs.legend(loc=legendPos)
            index+=1
    if file:
        fig.tight_layout()
        fig.savefig(file,dpi=300)
        
## DCA curve
def calculate_net_benefit_model(thresh_group, y_pred_score, y_label):
    net_benefit_model = np.array([])
    for thresh in thresh_group:
        y_pred_label = y_pred_score > thresh
        _, fp, _, tp = confusion_matrix(y_label, y_pred_label).ravel()
        n = len(y_label)
        net_benefit = (tp / n) - (fp / n) * (thresh / (1 - thresh))
        net_benefit_model = np.append(net_benefit_model, net_benefit)
    return net_benefit_model


def calculate_net_benefit_all(thresh_group, y_label):
    net_benefit_all = np.array([])
    tn, fp, fn, tp = confusion_matrix(y_label, y_label).ravel()
    total = tp + tn
    for thresh in thresh_group:
        net_benefit = (tp / total) - (tn / total) * (thresh / (1 - thresh))
        net_benefit_all = np.append(net_benefit_all, net_benefit)
    return net_benefit_all


def plot_DCA(ax, thresh_group, net_benefit_model, net_benefit_all,model_label):
    #Plot
    ax.plot(thresh_group, net_benefit_model, color = 'crimson', label = model_label)
    ax.plot(thresh_group, net_benefit_all, color = 'black',label = 'Treat all')
    ax.plot((0, 1), (0, 0), color = 'black', linestyle = ':', label = 'Treat none')

    #Fill，显示出模型较于treat all和treat none好的部分
    y2 = np.maximum(net_benefit_all, 0)
    y1 = np.maximum(net_benefit_model, y2)
    ax.fill_between(thresh_group, y1, y2, color = 'crimson', alpha = 0.2)

    #Figure Configuration， 美化一下细节
    ax.set_xlim(0,1)
    ax.set_ylim(net_benefit_model.min() - 0.15, net_benefit_model.max() + 0.15)#adjustify the y axis limitation
    ax.set_xlabel(
        xlabel = 'Threshold Probability', 
        fontdict= {'family': 'Arial', 'fontsize': 12}
        )
    ax.set_ylabel(
        ylabel = 'Net Benefit', 
        fontdict= {'family': 'Arial', 'fontsize': 12}
        )
    ax.grid('major')
    ax.spines['right'].set_color((0.8, 0.8, 0.8))
    ax.spines['top'].set_color((0.8, 0.8, 0.8))
    ax.legend(loc = 'upper right')

    return ax
        
