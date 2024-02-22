/****************************************
* Purpose: 处理数据
*	 Date: 20240128	
****************************************/

%initEnv(homelevel=1);
libname allcity "Data";
libname source "D:\projects\Allcity\Data";
%include "makebaseline.sas";

proc datasets lib=work mt=data kill;
quit;

proc datasets lib=allcity kill mt=data;
quit;

data final(compress=yes);
	set source.final;
run;

/*5472844*/
proc sql threads;
	select wave,count(distinct card_no) as count 
	from final
	group by wave;
quit;

data final;
	set final;
	if area_name in: ("和平","南开","红桥","河东","河西","河北") then area=1;
	else if area_name in: ("西青","北辰","津南","东丽") then area=2;
	else if ~missing(area_name) then area=3;
	if (.<odse<-6 or .<osse<-6) and .<min(oducva,osucva)<5 then highmyopia=1;
	else highmyopia=0;
	if .<graden<=9;
run;

proc sort data=final threads;
	by card_no wave;
run;

proc sql;
	create table allcity.highmyopiabyarea as
	select area_name,count(distinct card_no) as COUNT
	from final group by area_name;
quit;

proc freq data=final;
	table graden*highmyopia/out=allcity.highmyopiabygrd outpct;
run;
proc freq data=final;
	where graden<=6;
	table highmyopia/out=allcity.highmyopiabygrd bin(level="1") outpct;
run;

proc sql;
	select count(distinct card_no) from final;
quit;

data final;
	do _n_=1 by 1 until(last.card_no);
		set final;
		by card_no;
		seq=_n_;
		max_highmyopia=max(max_highmyopia,highmyopia);
		max_grade=max(max_grade,graden);
	end;
	do _n_=1 by 1 until(last.card_no);
		set final;
		by card_no;
		if first.card_no then do;
			basegrd=graden;
			if nmiss(odse,osse)=0 then do;
				basese=min(odse,osse);
			if nmiss(oducva,osucva)<2 then do;
				baseucva=min(oducva,osucva);
			end;
			end;else call missing(basese);
			basedate=checkdate;		
        end;
		if .<basegrd<=6 then output;
	end;
run;

proc sql;
	create table allcity.area_persons as
	select area_name,count(distinct card_no) as COUNT 
	from final group by area_name;
quit;

proc sql;
	select count(distinct card_no) from final;
quit;

/*997407 id*/

/*患病率*/
data final1;
	set final(in=a) final(in=b);
	if b then graden=7;
run;

proc freq data=final1;
	table wave*myopia/ chisq trend out=allcity.myopia 
					   outpct bin cl;
	table wave*gender*myopia/ chisq trend out=allcity.myopiabysex
					   outpct bin cl;
	table wave*graden*myopia/ chisq trend out=allcity.myopiabygrd
					   outpct bin cl;
	table wave*highmyopia/ chisq trend out=allcity.highmyopia 
					   outpct bin cl;
	table wave*gender*highmyopia/ chisq trend out=allcity.highmyopiabysex
					   outpct bin cl;
	table graden*highmyopia/ chisq trend out=allcity.highmyopiabygrd
					   outpct bin cl;
run;
proc sql;
	select count(distinct card_no) from final;
quit;

data final;	
	set final;
	if seq>1;
run;

proc sql;
	select count(distinct card_no) from final;
quit;

proc datasets lib=work nowarn;
	delete final1;
quit;

/*2384234*/
data final;
	do until(last.card_no);
		set final;
		by card_no;
		temp=sum(temp,highmyopia);
		if temp<=1 then output;
	end;
run;

data final;
	set final;
	if basese>-6;
run;

proc sql;
	select count(distinct card_no) from final;
quit;

/*2375326*/
data final;
	do until(last.card_no);
		set final;
		by card_no;
		max_date=max(max_date,checkdate);
	end;
	do until(last.card_no);
		set final;
		by card_no;
		diff_date=datdif(basedate,max_date,'act/act')/365.25;
		output;
	end;
run;
data final;
	do until(last.card_no);
		set final;
		by card_no;
		if first.card_no then basehighmyopia=highmyopia;
		output;
	end;
run;

proc sql;
	select count(distinct card_no) from final;
quit;

data final;
	set final;
	by card_no;
	if first.card_no & ~missing(basegrd);
	drop temp;
run;

proc freq data=final;
	table basegrd;
run;

proc sql;
	create table allcity.personsfromarea as
	select area_name,count(distinct card_no) as COUNT from final
	group by area_name;
quit;

proc sql;
	title "新发高度近视率";
/*	create table allcity.incidence as*/
	select sum(max_highmyopia) as numbers,sum(max_highmyopia)/sum(diff_date)*100
	from final;
	title "新发高度近视率 by grade";
/*	create table allcity.incidencebygrd as*/
	select basegrd,sum(max_highmyopia)/sum(diff_date)*100 as incidence
	from final where ~missing(basegrd) group by basegrd;
	title "新发高度近视率 by sex";
/*	create table allcity.incidencebygender as*/
	select gender,sum(max_highmyopia)/sum(diff_date)*100 as incidence
	from final where ~missing(basegrd) group by gender;
	select area_name,sum(max_highmyopia)/sum(diff_date)*100 as incidence
	from final where ~missing(basegrd) group by area_name;
quit;

data allcity.final_cleaned(compress=yes);
	do until(last.card_no);
		set final;
		by card_no;
	end;
	format birth basedate yymmdd10.;
	keep card_no name basedate basegrd basese basedate age area max_highmyopia glass 
		gender birth school_name SEFlag diff_date area_name baseucva;
run;

proc datasets lib=work mt=data kill nodetails nolist nowarn;
quit;

data final_cleaned(compress=yes);
	set allcity.final_cleaned;
	name=upcase(name);
run;

data ques(compress=yes);
	set source.ques2;
run;

proc sort data=final_cleaned out=final_cleaned;
	by name birth;
run;
proc sort data=ques nodupkey;
	by name birth;
run;

data total;
	merge final_cleaned(in=a) ques(in=b);
	by name birth;
	rename max_highmyopia=outcome;
	if a & b then match=1;
	else if a & ~b then match=2;
	if a;
run;

proc freq data=total;
	table match;
run;

%makebaseline(
	indata=total,
	catVars=gender|basegrd,
	qanVars=age|basese,
	grpVar=match,
	grplabels=%str(Matched|Not macthed),
	file=%str(./Docus/match),
	title=%str(Comparsion of matched and not matched)
	);


proc ttest data=total;
	class match;
	var age basese;
run;

data total;
	set total;
	if match=1;
run;

proc sql;
	select count(distinct card_no) from total;
quit;

data total;
	set total;
	outdoor=min(outdoor,3);
	nearDisPlay=min(nearDisPlay,3);
	nearDisStudy=min(nearDisStudy,3);
	nearDisRead=min(nearDisRead,3);
	if coarse<=2 then coarse=1;
	else if coarse<=4 then coarse=2;
	else if coarse<=6 then coarse=3;
	if seafood<=2 then seafood=1;
	else if seafood<=4 then seafood=2;
	else if seafood<=6 then seafood=3;
	if fruit<=2 then fruit=1;
	else if fruit<=4 then fruit=2;
	else if fruit<=6 then fruit=3;
	if vegatables<=2 then vegatables=1;
	else if vegatables<=4 then vegatables=2;
	else if vegatables<=6 then vegatables=3;
	if cookies<=2 then cookies=1;
	else if cookies<=4 then cookies=2;
	else if cookies<=6 then cookies=3;
	if friedFood<=2 then friedFood=1;
	else if friedFood<=4 then friedFood=2;
	else if friedFood<=6 then friedFood=3;
	if soda<=2 then soda=1;
	else if soda<=4 then soda=2;
	else if soda<=6 then soda=3;
run;

proc sql;
	select count(distinct card_no) from total where disease=2;
	select count(distinct card_no) from total where glass>2;
quit;

data total;
	set total;
	if disease ^=2 and glass<=2;
run;

proc sql;
	select count(distinct card_no) from total;
quit;

proc sql;
/*	create table allcity.incidencebygender as*/
	select familyhistory,sum(outcome)/sum(diff_date)*100 as incidence
	from total where ~missing(basegrd) group by familyhistory;
quit;

data allcity.total(compress=yes);
	set total;
run;

proc sql;
	create table randomTable as
	select distinct area_name from allcity.total;
quit;

data randomTable;
	set randomTable;
	if area_name in: ("和平","南开","红桥","河东","河西","河北") then area=1;
	else if area_name in: ("西青","北辰","津南","东丽") then area=2;
	else if ~missing(area_name) then area=3;
run;

proc sort data=randomTable;
	by area;
run;

proc surveyselect data=randomTable seed=1234 out=areaSelected method=srs n=(1 1 1);
 strata area;
run;

proc sql;
	select quote(cats(area_name)) into :selected separated by "," from areaSelected;
quit;
%put &=selected;

data allcity.total;
	set allcity.total;
	if missing(glass) then do;
		glass=ifn(wearglass=1,2,1);
	end;
	logtime=log(diff_date);
	if basese>0 then basesef=1;
	else if basese>-1.75 then basesef=2;
	else basesef=3;
run;

data allcity.train allcity.test;
	set allcity.total;
	if area_name in (&selected) then output allcity.test;
	else output allcity.train;
run;

%makebaseline(
	indata=allcity.train,
	catVars=familyHistory|gender|basegrd|nearDisPlay|nearDisRead|nearDisStudy|Coarse|cookies|friedFood|outdoor|soda|seaFood|glass,
	qanVars=basese|baseucva,
	grpVar=outcome,
	grplabels=%str(No|Yes),
	file=%str(./Docus/baseline),
	title=%str(Baseline)
	);

proc means data=allcity.train mean std;
	var basese;
run;
proc freq data=allcity.train;
	table basegrd;
run;

proc hpgenselect data=allcity.train;
	class gender basegrd(ref="1") area familyHistory nearDisPlay nearDisRead nearDisStudy
		  Coarse cookies friedFood outdoor soda seaFood glass basesef;
  	model outcome(event="1")=basesef baseucva age gender basegrd familyHistory nearDisPlay nearDisRead nearDisStudy
		  Coarse cookies friedFood outdoor soda seaFood glass/ distribution=poisson 
		  offset=logtime;
	performance nthreads=6;
    selection method=backward(choose=SBC stop=SL);
run; 
/*Intercept basese age familyHistory:20847*/
/*Intercept basese gender basegrd familyHistory:20735*/

ods output GEEEmpPEst = est;
proc genmod data=allcity.train;
/*	where basese>-3;*/
	class gender basegrd(ref="1") familyHistory(ref="2") area glass card_no basesef;
	model outcome(event="1")=basesef  baseucva familyHistory  basegrd glass
			/dist=poisson type3 offset=logtime;
/*	lsmeans gender/ cl ilink exp;*/
	repeated subject=card_no;
run;
ods output close;

data allcity.est_exp;
length variables $50 level1 $20;
  set est;  
  if parm="glass" then do;
		if level1="1" then do;
			level1="Yes";
			variables="Wearing glasses";
		end;
		else if level1="2" then level1="No";
  end;
  if Parm="basesef" then do;
		if level1="1" then do;  level1="0D or above"; variables="Baseline SE";end;
		else if level1="2" then  level1="-1.75 to 0 D";
		else if level1="3" then  level1="-1.75D or below";
  end;
  if Parm="basegrd" then do;
		if level1="2" then do;
			variables="Baseline grade";
		end;
  end;
  if Parm="familyHistory" then do;
		if level1="1" then do;
			level1="Yes";
			variables="Family history of myopia";
		end;else level1="No";
  end;
  if Parm="baseucva" then do;
		variables="Baseline UCVA";	
  end;
  irr = exp(estimate);
  irr_l=exp(LowerCL);
  irr_u=exp(UpperCL);
  irrc=cats(put(irr,8.2));
  irr_lc=cats(put(irr_l,8.2));
  irr_uc=cats(put(irr_u,8.2));
  lu=cats(irr_lc,",",irr_uc);
  pvalue=cats(put(ProbZ,pvalue6.3));
  if parm ^="Intercept" ; 
run;
