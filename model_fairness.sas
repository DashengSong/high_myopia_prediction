/********************************
Model fairness
*********************************/
%initEnv(homelevel=1);

filename inf "./Data/shap_fairness.csv";
proc import datafile=inf out=fairness dbms=csv replace;
run; 

proc means data=fairness sum std n nway;
	class label basegrd_;
	var basegrd;
run;