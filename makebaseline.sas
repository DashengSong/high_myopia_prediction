/*************************************************************
Purpose:
		Make baseline summary table
Model:
		TEST
Date:
		20230430 First version;
		20230504 fix some bugs[format error,name error];
		20231102 add arguments debug; fix group label display;
		20231225 add Miss for Quan variables;
				 add order for all variables;
				 add footnote;
		20240113 add Style template;
**************************************************************/
%macro makeBaseline(
					indata= 			 /*The dataset you are interested in*/
					,catVars= 			 /*Some categorical variables separated by | */
					,qanVars=  			 /*Some quantitative variables separated by |*/
					,grpVar= 			 /*A group variable*/
					,perType=col   		 /*The type of frequencies: col/row. Default:col*/
					,normal=S   		 /*Normal test method:S=Shapiro-Wilk/K=Kolmogorov-Smirnov*/
					,grplabels= 		 /*The labels for Group variables*/
					,file=               /*The output file path (not contains file type)*/
					,title=     		 /*The title of table*/
					,page=portrait       /*The orieation of page. default:portrait, landscape be allowed*/
				    ,width=99            /*The width of table covering the paper*/
				    ,style=journal2a
					,debug=0 			 /*debug=0:Delete the dataset during runtime*/
					)/des="Make baseline summary table"; 
	ods escapechar="^";
	options  nomexecnote validvarname=any;
	%local i numOFCatVARS numOFQanVARS tempfmt;
	%local chisqVars correctchisqVars;
	%if %length(&indata)=0 %then %do;
		%put ERROR:INDATA MUST SPECIFY!;
		%abort cancel;
	%end;
	%if %length(&catVars)=0 & %length(&qanVars)=0 %then %do;
		%put ERROR:AT LEAST ONE OF CATVARS OR QANVARS SPECIFY!;
		%abort cancel;
	%end;
	%let dsid=%sysfunc(open(&indata,i));
	%if &dsid=0 %then %do;
		%put ERROR:PLEASE CHECK WHETHER THE SPELLING OF &indata IS RIGHT;
		%abort cancel; 
	%end;%else 
	%do;
		%let numOfCatVARS=%sysfunc(countw(&catVars,|));
		%if %length(&catVars)>0 %then %do;
			%do i=1 %to &numOFCatVARS;
				%let rc=%sysfunc(varnum(&dsid,%scan(&catVars,&i,|)));
				%if &rc=0 %then %do;
					%put ERROR:%scan(&catVars,&i,|) NOT IN &indata;
					%abort cancel;
				%end;
			%end;
		%end;
		%let numOfQanVARS=%sysfunc(countw(&qanVars,|));
		%if %length(&qanVars)>0 %then %do;
			%do i=1 %to &numOfQanVARS;
				%let rc=%sysfunc(varnum(&dsid,%scan(&qanVars,&i,|)));
				%if &rc=0 %then %do;
					%put ERROR:%scan(&qanVars,&i,|) NOT IN &indata;
					%abort cancel;
				%end;
			%end;
		%end;
		%let rc=%sysfunc(close(&dsid));
	%end;
	proc sql noprint;
		select count(distinct &grpVar) into :levelsOfgrp from &indata;
	quit;
	%if %length(&catVars)>0 %then %do;
		%do i=1 %to &numOfCatVARS;
			%let temp=%scan(&catVars,&i,|);
			proc sql noprint;
				select cats(fmtname,".") into :tempfmt 
					from sashelp.vcformat 
						where lowcase(fmtname) contains "%lowcase(&temp)fmt";
			quit;
			data __stat_&temp;
				call missing(stat);
				call missing(pvalue);
			run;
			proc freq data=&indata;
				%if %length(&tempfmt)>0 %then format &temp &tempfmt;;
				table &temp.*&grpVar/out=__freq_&temp outexpect outpct sparse;
			run;
			proc sql noprint;
				select sum(count),
					   count(distinct &temp),
					   min(expected),
					   sum(expected<5),
					   count(*) into :totalN,:nLevels,:minExpected,:minExpectedCells,:Ncells
				from __freq_&temp;
			quit;

			%if &nLevels=2 %then %do;
				%if &minExpected>=5 and &totalN>40 %then %do;
					%put &temp.--Chisq square Test;
					proc freq data=&indata;
						table &temp.*&grpVar/chisq;
						output out=__stat_&temp(keep=_pchi_ p_pchi
												rename=(_pchi_=stat p_pchi=pvalue)) chisq ;
					run;
					data __stat_&temp;
						set __stat_&temp;
						length statc $20;
						statc=compress(put(stat,8.3));
					run;
				%end;%else %if &minExpected<5 and &minExpected>=1 and &totalN>40 %then %do;
					%put &temp.--Adjusted Chisq square Test;
					proc freq data=&indata;
						table &temp.*&grpVar/chisq;
						output out=__stat_&temp(keep= _AJCHI_ P_AJCHI
												rename=(_AJCHI_=stat P_AJCHI=pvalue)) ajchi;
					run;
					data __stat_&temp;
						set __stat_&temp;
						length statc $20;
						statc=compress(put(stat,8.3));
					run;
				%end;%else %do;
					%put &temp.--Fisher Test;
					proc freq data=&indata;
						table &temp.*&grpVar/fisher;
						output out=__stat_&temp(rename=(XP2_FISH=pvalue)) fisher;
					run;
					data __stat_&temp;
						set __stat_&temp;
						length statc $20;
						statc=compress("*");
					run;	
				%end;	
			%end;
			%else %do;
				%if %sysevalf(&minExpectedCells/&Ncells)>0.2 or &minExpected<1 %then %do;
					%put &temp.--Fisher Test;
					proc freq data=&indata;
						table &temp.*&grpVar/fisher;
						output out=__stat_&temp(rename=(XP2_FISH=pvalue)) fisher;
					run;
					data __stat_&temp;
						set __stat_&temp;
						length statc $20;
						statc=compress("*");
					run;
				%end;%else %do;
					%put &temp.--Chisq square Test;
					proc freq data=&indata;
						%if %length(&tempfmt)>0 %then format &temp &tempfmt;;
						table &temp.*&grpVar/chisq;
						output out=__stat_&temp(keep=_pchi_ p_pchi
												rename=(_pchi_=stat p_pchi=pvalue)) 
												chisq;
					run;
					data __stat_&temp;
						set __stat_&temp;
						length statc $20;
						statc=compress(put(stat,8.3));
					run;
				%end;
			%end;
			data __freq_&temp;
				set __freq_&temp;
				if ~missing(pct_&perType) then do;
					nper=cats(count,"(",put(pct_&perType,8.2),")");
				end;else do;
					nper=cats(count);
				end;
			run;
			proc transpose data=__freq_&temp. out=__freq_&temp. prefix=&grpVar._;
				by &temp;
				var nper;
				id &grpVar;
			run;
			data __cats_&temp;
				length variables $100;
				if _n_=1 then do;
					set __STAT_&temp;
					variables=compress(vlabel(&temp)," ",'d');
				end;else do;
					set __freq_&temp;
					variables="^{nbspace 4}"||cats(vvalue(&temp));
					call missing(statc,pvalue);
				end;
				order=&i;
				type=2;
				drop &temp _name_ ;
			run;
			data __cats_&temp;
				set __cats_&temp;
				if cats(variables)="^{nbspace 4}" then variables=cats("^{nbspace 4}","缺失");
			run;
		%end;
	%end;
	%if %length(&qanVars)>0 %then %do;
		%do i=1 %to &numOfQanVARS;
			%let temp=%scan(&qanVars,&i,|);
			data __stat_&temp;
				length variables $100 statc $20;
				call missing(variables,statc,pvalue);
			run;
			ods output TestsForNormality=normal;
			proc univariate data=&indata. normal;
				ods select TestsForNormality;
				class &grpVar;
				var &temp;
			run;
			proc sql noprint;
				select min(pValue) into :np from normal where lowcase(test) eqt "%lowcase(&normal)";
			quit;
			%if &np.>=0.05 %then %do;
				%if &levelsOfgrp.=2 %then %do;
					ods output ttests=__stat_&temp equality=__varEq_&temp;
					proc ttest data=&indata;
						ods select ttests equality;
						class &grpVar;
						var &temp;
					run;
					ods output close;
					data _null_;
						set __varEq_&temp;
						call symputx("varEq",pvalue);
					run;
					%if &varEq<0.05 %then %do;
						%put &temp.---T-TEST;
						data _null_;
							if 0 then set &indata;
							call symputx('varlbl',vlabel(&temp));
						run;
						data __stat_&temp;
							length variables $100;
							set __stat_&temp;
							variables=compress("&varlbl.",' ','d');
							if _n_=2;
							keep tvalue probt variables;
							rename tvalue=stat probt=pvalue;
						run;
						data __stat_&temp;
							set __stat_&temp;
							length statc $20;
							statc=compress(put(stat,8.3));
						run;
					%end;%else %do;
						%put &temp.---corrected T-TEST;
						data _null_;
							if 0 then set &indata;
							call symputx('varlbl',vlabel(&temp));
						run;
						data __stat_&temp;
							length variables $100;
							set __stat_&temp;
							variables=compress("&varlbl.",' ','d');
							if _n_=1;
							keep tvalue probt variables;
							rename tvalue=stat probt=pvalue;
						run;
						data __stat_&temp;
							set __stat_&temp;
							length statc $20;
							statc=compress(put(stat,8.3));
						run;
					%end;
				%end;
				%else %do;
					ods output ModelANOVA=__stat_&temp bartlett=__VAREQ_&temp.;
					proc glm data=&indata ;
						ods select Bartlett ModelANOVA; 
						class &grpvar;
						model &temp.=&grpvar.;
						means &grpvar. / hovtest=bartlett;
					run;
					ods output close;
					data _null_;
						set __varEq_&temp;
						call symputx("varEq",ProbChiSq);
					run;
					%if &varEq>=0.05 %then %do;
						%put &temp.---ANOVA;
						data _null_;
							if 0 then set &indata;
							call symputx('varlbl',vlabel(&temp));
						run;
						data __stat_&temp;
							set __stat_&temp;
							if _n_=1;
							keep probf Dependent;
							rename probf=pvalue Dependent=variables;
						run;
						data __stat_&temp;
							set __stat_&temp;
							length statc $20;
							variables=compress("&varlbl.",' ','d');
							statc=compress(put(stat,8.3));
						run;
					%end;%else %do;
						%put &temp.---Kruskal Wallis Test;
						ods output KruskalWallisTest=__stat_&temp.(rename=(variable=variables prob=pvalue ChiSquare=stat) drop=df);
						proc npar1way data=&indata wilcoxon;
							ods select KruskalWallisTest;
							class &grpVar;
							var &temp;
						run;
						ods output close;
						data _null_;
							if 0 then set &indata;
							call symputx('varlbl',vlabel(&temp));
						run;
						data __stat_&temp;
							set __stat_&temp;
							length statc $20;
							variables=compress("&varlbl.",' ','d');
							statc=compress(put(stat,8.3)||"^{super **}");
						run;
					%end; 
				%end;
			%end;
			%else %do;
			%if &levelsOfgrp=2 %then %do;
				%put &temp.---Wilcoxon Test;
				ods output WilcoxonTest=__stat_&temp(keep=variable Z prob2
												  rename=(variable=variables Z=stat prob2=pvalue));
				proc npar1way data=&indata wilcoxon;
					ods select WilcoxonTest;
					class &grpVar;
					var &temp;
				run;
				ods output close;
				data _null_;
					if 0 then set &indata;
					call symputx('varlbl',vlabel(&temp));
				run;
				data __stat_&temp;
					set __stat_&temp;
					length statc $20;
					variables=compress("&varlbl.",' ','d');
					statc=compress(put(stat,8.3)||"^{super **}");
				run;
			%end;%else %do;
				%put &temp.---Kruskal Wallis Test;
				ods output KruskalWallisTest=__stat_&temp(rename=(variable=variables 
												prob=pvalue ChiSquare=stat) drop=df);
				proc npar1way data=&indata wilcoxon;
					ods select KruskalWallisTest;
					class &grpVar;
					var &temp;
				run;
				ods output close;
				data _null_;
					if 0 then set &indata;
					call symputx('varlbl',vlabel(&temp));
				run;
				data __stat_&temp;
					set __stat_&temp;
					length statc $20;
					variables=compress("&varlbl.",' ','d');
					statc=compress(put(stat,8.3)||"^{super **}");
				run;
			%end;	
			%end;
			proc means data=&indata n mean median std p25 p75 min max nmiss;
					class &grpVar;
					var &temp;
					output out=__freq_&temp nmiss=miss n=n mean=mean median=median std=std p25=p25 p75=p75 min=min max=max;
			run;
			data __freq_&temp;
				set __freq_&temp;
				if missing(std) & ~missing(mean) then std=0;
				nmiss=cats(miss);
				count=cats(n);
				mstd=cats(put(mean,8.2),unicode("&#177;",'ncr'),put(std,8.2));
				miqr=cats(put(median,8.2),"(",put(p25,8.2),",",put(p75,8.2),")");
				minmax=cats(put(min,8.2),",",put(max,8.2));
				if cats(mstd)=unicode("&#177;",'ncr') then call missing(mstd);
				if cats(miqr)="(,)" then call missing(miqr);
				if cats(minmax)="," then call missing(minmax);
			run;
			proc transpose data=__freq_&temp out=__freq_&temp prefix=&grpvar._;
				where _type_=1;
				var nmiss count--minmax;
				id &grpvar;
			run;
			data __qan_&temp;
				length variables $100;
				set  __stat_&temp __freq_&temp;
				if _name_="nmiss" then variables="^{nbspace 4}Miss";
				else if _name_="count" then variables="^{nbspace 4}N";
				else if _name_="mstd" then variables="^{nbspace 4}Mean"||unicode("&#177;",'ncr')||"Std";
				else if _name_="miqr" then variables="^{nbspace 4}Median(P25,P75)";
				else if _name_="minmax" then variables="^{nbspace 4}Min,Max";		
				order=&i;
				type=1;
				drop _name_;
			run;
		%end;
	%end;
	data __total;
	length variables $100;
	set %if %length(&catVars)>0 %then __cats_:; %if %length(&qanVars)>0 %then __qan_:;;
	if missing(pvalue) then call missing(statc);
	run;
	proc sort data=__total;
		by type order;
	run;
	proc sql noprint;
		select count(*) into :nofgrp separated by "|" from &indata where &grpVar is not null group by &grpVar ;
		select distinct &grpVar into :grplabelsraw separated by "|" from &indata where &grpVar is not null 
			order by &grpVar ;
	quit;
	options nodate nonumber  orientation=&page missing = '';
	ods tagsets.rtf style=&style. file="&file..rtf";
	title j=center height=12pt "&title";
	proc report data=__total spacing=1 headline headskip split = "|" threads style(report)={width=&width%};
		col type order variables &grpVar._: statc pvalue;
		define type /order noprint;
		define order/order noprint;
		define variables /"变量" left display ;
		%do i=1 %to &levelsOfgrp;
			define &grpVar._%scan(&grplabelsraw,&i,|) /right display %if %length(&grplabels)=0 %then %do; "%scan(&grplabelsraw,&i,|)|(N=%scan(&nofgrp,&i,|))" %end;
																	%else %do; 
																		"%scan(&grplabels,&i,|)|(N=%scan(&nofgrp,&i,|))"
																	%end;;
		%end;
		define statc / display left "统计量";
		define pvalue /display f=pvalue6.3 "P";
		compute after/ style={bordertopstyle=solid borderbottomstyle=hidden};
			line @1 "Note:* Fisher Exact Test **Wilcoxon Test";
		endcomp;
	run;
	ods tagsets.rtf close;
	title;
	%if &debug=0 %then %do;
		proc datasets lib=work mt=data nowarn nolist nodetails;
			delete __freq_: __stat_: __cats_: __qan_: normal __:;
		quit;
	%end;
	options mexecnote;
%mend;
