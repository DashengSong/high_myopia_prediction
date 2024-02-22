/***********************
Summary for baseline
************************/
%initEnv(homelevel=1);

libname dt "Data";
%include "makebaseline.sas";

proc import datafile="./Data/trainForModel.csv" dbms=csv out=train replace;
proc import datafile="./Data/testForModel.csv" dbms=csv out=invalid replace;
run;
data outvalid;
	set dt.test;
	keep outcome basegrd baseucva familyHistory basesef;
run;

%makeBaseline(
	indata=train 			 /*The dataset you are interested in*/
	,catVars=basegrd|familyHistory|basesef 			 /*Some categorical variables separated by | */
	,qanVars=baseucva 			 /*Some quantitative variables separated by |*/
	,grpVar=outcome 			 /*A group variable*/
	,perType=col   		 /*The type of frequencies: col/row. Default:col*/
	,normal=S   		 /*Normal test method:S=Shapiro-Wilk/K=Kolmogorov-Smirnov*/
	,grplabels=%str(Not developed|Developed) 		 /*The labels for Group variables*/
	,file=%str(./Docus/Baseline for train)               /*The output file path (not contains file type)*/
	,title=%str(Train)     		 /*The title of table*/
	,page=portrait       /*The orieation of page. default:portrait, landscape be allowed*/
    ,width=99            /*The width of table covering the paper*/
    ,style=journal2a
	,debug=0 			 /*debug=0:Delete the dataset during runtime*/
	);

%makeBaseline(
	indata=invalid 			 /*The dataset you are interested in*/
	,catVars=basegrd|familyHistory|basesef 			 /*Some categorical variables separated by | */
	,qanVars=baseucva 			 /*Some quantitative variables separated by |*/
	,grpVar=outcome 			 /*A group variable*/
	,perType=col   		 /*The type of frequencies: col/row. Default:col*/
	,normal=S   		 /*Normal test method:S=Shapiro-Wilk/K=Kolmogorov-Smirnov*/
	,grplabels=%str(Not developed|Developed) 		 /*The labels for Group variables*/
	,file=%str(./Docus/Baseline for invalid)               /*The output file path (not contains file type)*/
	,title=%str(invalid)     		 /*The title of table*/
	,page=portrait       /*The orieation of page. default:portrait, landscape be allowed*/
    ,width=99            /*The width of table covering the paper*/
    ,style=journal2a
	,debug=0 			 /*debug=0:Delete the dataset during runtime*/
	);

%makeBaseline(
	indata=outvalid 			 /*The dataset you are interested in*/
	,catVars=basegrd|familyHistory|basesef 			 /*Some categorical variables separated by | */
	,qanVars=baseucva 			 /*Some quantitative variables separated by |*/
	,grpVar=outcome 			 /*A group variable*/
	,perType=col   		 /*The type of frequencies: col/row. Default:col*/
	,normal=S   		 /*Normal test method:S=Shapiro-Wilk/K=Kolmogorov-Smirnov*/
	,grplabels=%str(Not developed|Developed) 		 /*The labels for Group variables*/
	,file=%str(./Docus/Baseline for outvalid)               /*The output file path (not contains file type)*/
	,title=%str(outvalid)     		 /*The title of table*/
	,page=portrait       /*The orieation of page. default:portrait, landscape be allowed*/
    ,width=99            /*The width of table covering the paper*/
    ,style=journal2a
	,debug=0 			 /*debug=0:Delete the dataset during runtime*/
	);