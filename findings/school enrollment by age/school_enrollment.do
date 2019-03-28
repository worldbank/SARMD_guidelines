/*==================================================
Project:       School attendance in SAR using SARMD
Author:        Javier Parada and Andres Castaneda 
Dependencies:  The World Bank
----------------------------------------------------
Creation Date:    	21 Mar 2019 
Modification Date:  28 Mar 2019
Do-file version:    01
References:         
Output:             Stata graph
==================================================*/


/*==================================================
                    Set up
==================================================*/

cd ""

local reponame  "sarmd"
local countries "PAK"
local years     "2015" 
local surveys   ""

cap which combomarginsplot 
if (_rc) ssc install combomarginsplot 

/*==================================================
           Alternative version 1
==================================================*/

*---------- Get repo
datalibweb, repo(create `reponame', force) type(SARMD)
contract country years survname 
drop _freq
ds
local varlist "`r(varlist)'"

*---------- Evaluate initial conditions

if ("`countries'" == "") {
	levelsof country, local(countries) /* list countries if not specified */
}

*---------- Export to MATA
mata: R = st_sdata(.,tokens(st_local("varlist"))) /* replace with putmata? */

*---------- Loop over countries
foreach country of local countries {

	
	if ("`years'" == "") {
		mata: st_local("years",                     /*   set local years 
		 */       invtokens(                        /*    create tokens out of matrix
		 */       select(R[.,2], R[.,1] :== st_local("country"))', /*  select years
		 */       " "))                            // separator (second term in )
	}
	 
	foreach year of local years {

		if ("`country'" == "IND" & "`year'"=="2011") {
			local surveyid "NSS68-SCH1.0-T1"
		}
		else local surveyid ""
		
		datalibweb, country(`country') year(`year') type(SARMD) surveyid(`surveyid') clear 
		
		mean atschool [aw=wgt] if age < 25, over(age male urban) // same as anova
		anova atschool i.age##i.male##i.urban  [aw=wgt] if (age < 25) // Estimate a two-way anova model
		
		tempfile g u gu a
		margins i.age##i.male         [aw=wgt] if (age < 25), saving(`g')
		margins i.age##i.urban        [aw=wgt] if (age < 25), saving(`u')
		
		combomarginsplot  `u' `g', noci recast(line) legend(cols(2) position(6)) /* 
		 */ plotopts(lpattern(l)) by(_filenumber) labels("Urban/rural" "Gender")
		
	}
}


/*==================================================
           Alternative version 2
==================================================*/

cd ""

local reponame  "sarmd"
local countries ""
local years     ""
local surveys   ""



*---------- Get repo
datalibweb, repo(create `reponame', force) type(SARMD)
contract country years survname 
drop _freq
ds
local varlist "`r(varlist)'"

*---------- Evaluate initial conditions
*countries
if ("`countries'" == "") {
	levelsof country, local(countries)
}

*---------- Export to MATA
mata: R = st_sdata(.,tokens(st_local("varlist")))

*---------- Loop over countries
drop _all
tempfile cy // countries and years
save `cy', emptyok 

qui foreach country of local countries {
	
	mata: st_local("years",                   /*   set local years 
	 */          invtokens(                   /*    create tokens out of matrix
	 */          select(R[.,2], R[.,1] :== st_local("country"))', /*  select years
	 */          " "))                          // separator (second term in )
	
	local years: list uniq years // in case of more than one survey 
	

	if ("`country'" == "IND" & "`year'"=="2011") {
		local surveyid "NSS68-SCH1.0-T1"
	}
	else local surveyid ""
	
	
	foreach year of local years {
	
		cap {
			datalibweb, country(`country') year(`year') type(SARMD) surveyid(`surveyid') clear 

			keep atschool age male urban wgt
			anova atschool i.age##i.male##i.urban  [aw=wgt] if (age < 25) // Estimate a two-way anova model
			
			tempfile g
			margins i.age##i.male##i.urban        [aw=wgt] if (age < 25), saving(`g')
			
			use `g', clear 
			gen country = "`country'"
			gen year    = `year'
			
			append using `cy'
			save `cy', replace 
		}
		if (_rc) {
			noi disp in red "Error on `country' `year'"
		}
		else {
			noi disp in y "`country' `year' Done."
		}

	}
}

use `cy', clear

/*==================================================
           fix Data
==================================================*/

rename (_margin _m1 _m2 _m3) (atsch age male urban)
label var atsch "School attendance (%)"
replace atsch = atsch*100

bysort country: egen my = max(year) // max year
replace my = (my == year)

gen ctryear = country + " - " + strofreal(year)


* Here your can save the data already clean

/*==================================================
      Types of graphs (you can do many more)
==================================================*/


*---------- Last year of each country
twoway (line atsch age if male == . & urban==., lpattern(l))  /* 
 */    (line atsch age if male == 1 & urban==., lpattern(l))  /* 
 */    (line atsch age if male == 0 & urban==., lpattern(l))  /* 
 */     if my == 1,                                           /* 
 */     legend(order(1 "Total" 2 "Male" 3 "Female" )          /* 
 */          position(6) rows(1))                             /* 
 */     by(ctryear, title("School Attendance by gender in"    /* 
 */                       "latest year available"))           /* 
 */     note("")

 
*---------- By year in one country

local country "BTN"

twoway (line atsch age if male == . & urban==., lpattern(l))  /* 
 */    (line atsch age if male == . & urban==1, lpattern(l))  /* 
 */    (line atsch age if male == . & urban==0, lpattern(l))  /* 
 */     if country == "`country'",                            /* 
 */     legend(order(1 "Total" 2 "Urban" 3 "Rural" )          /* 
 */          position(6) rows(1))                             /* 
 */     by(year, title("School Attendance by Urban/rural in"       /* 
 */                       "latest year available"))          


exit 
/* End of do-file */

><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><

Notes:
1.
2.
3.


Version Control:

 

