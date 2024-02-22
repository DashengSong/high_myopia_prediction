from shiny import ui, render, App,reactive
import shap
import matplotlib.pyplot as plt
from catboost import CatBoostClassifier
import pandas as pd
import seaborn as sns
from pathlib import Path
from faicons import icon_svg as icon

shap.initjs()

select_choices={
    1:"1",
    2:"2",
    3:"3",
    4:"4",
    5:"5",
    6:"6"
}

checkbox_choices={
    1:"Yes",
    0:"No"
}
# 导入模型和训练数据
model=CatBoostClassifier().load_model(Path(__file__).parent/"catboost")
#shap_values=joblib.load("./shap.pkl")
X=pd.read_pickle(Path(__file__).parent/"XtrainForModel.pkl")
y=pd.read_pickle(Path(__file__).parent/"ytrainForModel.pkl")

PERSONSPROBA=model.predict_proba(X)[:,1]
SINGLE=0

app_ui = ui.page_fluid(
    ui.tags.style(
        """
        .title{
            font-weight:bold;
            font-size:25pt;
            border-radius:5px;
            background-color:#1597A5;
            color:white;
            margin-bottom:0px;
            padding-left: 20px
        }
        .note{
           font-size:20pt;
        #    font-weight:800 
        }
        .t{
            font-weight:bold;
            font-size: 20pt;
        }
        
        """
    ),
    #{"style":"margin:0px;background-color:orange;padding:0px;bordor:0px"},
    ui.div("Prediction of High Myopia for Primary School Students",
           class_="title"),
    #ui.tags.link()
    ui.layout_sidebar(
        ui.panel_sidebar(          
            ui.p("Please input your information:",class_="note"),
            ui.card(
                ui.card_header("Grade"),
                ui.input_selectize('graden',None,select_choices),
                full_screen=True,
                height="150px"
            ),
            ui.card(
                ui.card_header("At least one of parents with myopia"),
                ui.input_radio_buttons("parentmy",None,checkbox_choices)
            ),
            ui.card(
                ui.card_header("UCVA"),
                ui.input_slider("oducva",None,value=5.0,min=0,max=5.3,step=0.1)
            ),
            ui.card(
                ui.card_header("SE"),
                ui.input_slider("se",None,value=0.0,max=5,min=-6)
            ),
            ui.card(
                ui.card_header("Wear glasses"),
                ui.input_radio_buttons(
                    "wg",
                    label=None,
                    choices={
                        1:"Yes",
                        2:"No"
                    }
                )
            ),
            ui.input_action_button("impute","Impute"),
            ui.hr(),
            ui.value_box(
                showcase_layout="left center",
                title=ui.p("Incidence of high myopia per year",
                           style="font-weight:400"),
                value="1.43%",
                showcase=icon("person",margin_left="px"),  
            ),

            class_="form"    
        ),
        ui.panel_main(
                #ui.markdown("按照您左侧的信息，您一年后发生高度近视的风险为:"),
                ui.output_ui("predict_risk"),
                #ui.markdown("上述风险来源："),
                ui.output_plot("show_shapplot"),
                ui.output_plot("distriplot")
        )
    ),
)

def server(input, output, session):
    @reactive.Calc
    def get_values():
        user_provided_values = reactive.Value([])
        values=user_provided_values()
        values.append(int(input.graden()))
        values.append(input.oducva())
        values.append(int(input.parentmy()))
        if input.se()>0:
            v=1
        elif input.se()>-1.75:
            v=2
        else:
            v=3
        values.append(v)
        values.append(int(input.wg()))         
        proba=model.predict_proba(values)[1]
        return values,proba
    @output
    @render.ui
    @reactive.event(input.impute)
    def predict_risk():
        if get_values()[1]<0.2:
            color="#32b5ff"
        elif get_values()[1]<0.5:
            color="#ffff00"
        elif get_values()[1]<0.8:
            color="orange"
        else:
            color="red"
        return ui.tags.div(ui.p("The probabilty of developing high myopia in the next 2 years:",class_="t"),ui.p("{0:.1%}".format(get_values()[1]),class_="v",style=f"color:{color};font-size:50pt;\
                                                                                                                 font-weight:bold;text-align: center;"))
    @output
    @render.plot
    @reactive.event(input.impute)
    def show_shapplot():
        values=get_values()[0]
        newX=pd.DataFrame([values],columns=['basegrd','baseucva','familyHistory','basesef','wearGlass'])
        newX=pd.concat([newX,X])
        explainer=shap.Explainer(model)
        shap_values=explainer.shap_values(newX)
        #values=pd.DataFrame([[5.0,-0.5,1,10]],columns=)
        return shap.force_plot(explainer.expected_value,shap_values[0],
                        matplotlib=True,
                        show=False,
                        feature_names=['Grade','UCVA','family History','SE',"Wear glasses"])

    @output
    @render.plot
    @reactive.event(input.impute)
    def distriplot():
        fig,ax=plt.subplots()
        sns.histplot(PERSONSPROBA,ax=ax)
        ax.axvline(get_values()[1],color="orange",ymax=0.95,linestyle=":",linewidth=2)
        ax.annotate('You', 
                    xy=(get_values()[1],5000),#箭头末端位置
                    xytext=(get_values()[1]+0.05,6000),#文本起始位置
                    color="red",
                    fontsize=25,
                    #箭头属性设置
                    arrowprops=dict(facecolor='#74C476', 
                                    #shrink=1,#箭头的收缩比
                                    arrowstyle='-|>',
                                    alpha=0.6,
                                    #headwidth=40,#箭头宽
                                    connectionstyle='arc3,rad=0.5',
                                    #color='r'
                                ),
                    )
        return fig

app = App(app_ui, server)