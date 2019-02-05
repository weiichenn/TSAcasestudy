/*Access Data*/
%let path=/home/weiichen0;
libname tsa "&path";
options validvarname=v7;

proc import datafile="&path/TSAClaims2002_2017.csv" dbms=csv 
		out=tsa.ClaimsImport replace;
	guessingrows=max;
run;

/*Explore Data*/
proc print data=tsa.ClaimsImport (obs=20);
run;

proc contents data=tsa.claimsimport varnum;
run;

proc freq data=tsa.claimsimport;
	tables claim_site disposition claim_type date_received incident_date / nocum 
		nopercent;
	format incident_date date_received year4.;
run;

proc print data=tsa.ClaimsImport;
	where date_received < Incident_date;
	format date_received Incident_date date9.;
run;

/*Prepare Data*/
proc sort data=tsa.claimsimport out=tsa.Claims_NoDups noduprecs;
	by _all_;
run;

proc sort data=tsa.Claims_NoDups;
	by Incident_Date;
run;

data tsa.claims_cleaned;
	set tsa.claims_nodups;

	if Claim_Site in ('-', '') then
		Claim_Site="Unknown";

	if Disposition in ('-', '') then
		Disposition="Unknown";
	else if Disposition='losed: Contractor Claim' then
		Dispostion=Disposition='Closed:Contractor Claim';
	else if Disposition='Closed: Cancelled' then
		Disposition='Closed:Canceled';

	if Claim_Type in ('-', '') then
		Claim_Type='Unknown';
	else if Claim_Type='Passenger Property Loss/Personal Injur' then
		Claim_Type='Passenger Property Loss';
	else if Claim_Type='Passenger Property Loss/Personal Injury' then
		Claim_Type='Passenger Property Loss';
	else if Claim_Type='Property Damage/Personal Injury' then
		Claim_Type='Property Damage';
	State=upcase(state);
	StateName=propcase(StateName);

	if (Incident_Date > Date_Received or Date_Received=. or Incident_Date=. or 
		year(Incident_Date)<2002 or year(Incident_Date)>2017 or 
		year(Date_Received)<2002 or year(Date_Received)>2017) then
			Date_Issues='Needs Review';
	format Incident_Date Date_Received date9. Close_Amount Dollar20.2;
	label Airport_Code='Airport Code' Airport_Name='Airport Name' 
		Claim_Number='Claim Number' Claim_Site='Claim Site' Claim_Type='Claim Type' 
		Close_Amount='Close Amount' Date_Issues='Date Issues' 
		Date_Received='Date Received' Incident_Date='Incident Date' 
		Item_Category='Item Category';
	drop county city;
run;

proc freq data=tsa.claims_cleaned order=freq;
	tables Claim_Site Disposition Claim_Type Date_Issues/ nopercent nocum;
run;

/*Analyze Data*/
%let statename=California;
%let outpath=/home/weiichen0;
ods pdf file="&outpath/ClaimsReport.pdf" style=meadow pdftoc=1;
ods noproctitle;
ods proclabel "Overall Date Issues";
title "Overall Date Issues in the Data";

proc freq data=tsa.claims_cleaned;
	table Date_Issues /missing nocum nopercent;
run;

title;
ods graphics on;
ods proclabel "Overall Claims by Year";
title "Overall Claims by Year";

proc freq data=tsa.claims_cleaned;
	table Incident_Date /nocum nopercent plots=freqplot;
	format Incident_Date year4.;
	where Date_Issues is null;
run;

title;
ods proclabel "&Statename Claims Overview";
title "&StateName Claim Types, Claim Sites and Disposition";

proc freq data=tsa.claims_cleaned order=freq;
	table Claim_Type Claim_Site Disposition / nocum nopercent;
	where StateName="&StateName" and Date_Issues is null;
run;

title;
ods proclabel "&Statename Close Amount Statistics";
title "Close_Amount Statistics for &statename";

proc means data=tsa.claims_cleaned mean min max sum maxdec=0;
	var Close_Amount;
	where StateName="&StateName" and Date_Issues is null;
run;

title;

/*Export Report*/
ods pdf close;