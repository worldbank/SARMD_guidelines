/*==================================================
project:       Access to electricity in SAR using SARMF
Author:        Jayne and Javier Parada and Andres Castaneda 
Dependencies:  The World Bank
----------------------------------------------------
Creation Date:    4 April 2019 
Modification Date:   
Do-file version:    01
References:         
Output:             STata graph
==================================================*/


/*==================================================
           Set up
==================================================*/
cd ""

local reponame "sarmd"
local countries ""
local years     ""
local surveys   ""


*houselanding electricity piped_water sewage_toilet electricity electricity landphone electricity computer electricity
*---------- Get repo
datalibweb, repo(create `reponame', force) type(SARMD)
contract country years survname 
ds
local varlist "`r(varlist)'"

*---------- Evaluate initical conditions
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
	
	
	mata: st_local("years",    /*   set local years 
	 */           invtokens(   /*    create tokens out of matrix
	 */          select(R[.,2], R[.,1] :== st_local("country"))', /*  select years
	 */            " "))     // separator (second temr in )
	
	local years: list uniq years // in case of more than one survey 
	
	if ("`country'" == "IND") {
		local surveyid "IND_2011_NSS68-SCH10"
	}
	else local surveyid ""
	
	foreach year of local years {
	
		cap {
			datalibweb, countr(`country') year(`year') type(SARMD) clear surveyid(`surveyid')

			/*keep atschool age male urban wgt
			anova atschool i.age##i.male##i.urban  [aw=wgt] if (age < 25) // Estimate a two-way anova model
			
			tempfile g
			margins i.age##i.male##i.urban        [aw=wgt] if (age < 25), saving(`g')*/
			
			keep countrycode year electricity welfare wgt
			*quintile 
			egen q= xtile(welfare), weights(wgt) nq(5)
			*gen b40=(q==1|q==2)
			collapse (mean) electricity [aw=wgt], by(countrycode year q)
			
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
*drop if year<2000
drop if country=="AFG"
ta q ,gen(q)
*bys country: egen yearma=max(year)
*bys country: egen yearmi=min(year)
*keep if yearma==year|yearmi==year
*bys country: egen count=count(year)
*drop if count<4
line electricity year  if q1==1 ||line electricity year if q5==1 , by(countrycode) legend(label(1 "Bottom 20") label(2 "Top 20"))
graph save Graph "C:\Users\WB502818\Documents\SARMD_guidelines\jayne\electricity.gph"
