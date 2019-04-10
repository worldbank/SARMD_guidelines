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
s
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
loc varlist electricity welfare wgt landholding water_source improved_water piped_water pipedwater_acc sewage_toilet toilet_acc improved_sanitation ///
				landphone cellphone computer internet 
			/*///
			improved_water piped_water pipedwater_acc sewage_toilet toilet_acc improved_sanitation ///
			electricity landphone cellphone computer internet radio television fan sewingmachine ///
			washingmachine refrigerator lamp bicycle motorcycle motorcar cow buffalo chicken ///
			welfare welfarenat quintile_cons_aggregate decile_cons_aggregate pline_nat poor_nat
			loc varlist electricity welfare wgt ownhouse tenure landholding water_source ///
			*/
			

*qui foreach country of local countries {
loc country "IND"	
	
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
	
		*cap {
			datalibweb, countr(`country') year(`year') type(SARMD) clear surveyid(`surveyid')
s
			/*keep atschool age male urban wgt
			anova atschool i.age##i.male##i.urban  [aw=wgt] if (age < 25) // Estimate a two-way anova model
			
			tempfile g
			margins i.age##i.male##i.urban        [aw=wgt] if (age < 25), saving(`g')*/
			*set trace on
			foreach v of local varlist {
			cap confirm var `v' 
			if _rc!=0 {
			gen `v'=.
			}
			}
			
			keep countrycode year `varlist' welfare wgt
			*quintile 
			egen q= xtile(welfare), weights(wgt) nq(5)
			*gen b40=(q==1|q==2)
			collapse (firstnm) countrycode (mean) `varlist' year [aw=wgt], by( q)
			
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
*}

use `cy', clear

*drop if year<2000
drop if country=="AFG"
ta q ,gen(q)
bys country: egen yearma=max(year)
*bys country: egen yearmi=min(year)
keep if yearma==year
*bys country: egen count=count(year)
*drop if count<4
loc varlist electricity welfare wgt landholding water_source improved_water piped_water pipedwater_acc sewage_toilet toilet_acc improved_sanitation ///
				landphone cellphone computer internet 
cd "C:\Users\WB502818\Documents\SARMD_guidelines\figures"
foreach v of local varlist {
di in red "`v'"
line `v' year  if q1==1 ||line electricity year if q5==1 , by(countrycode) legend(label(1 "Bottom 20") label(2 "Top 20")) ytitle("`v'")

graph export `v'.png, replace
}
