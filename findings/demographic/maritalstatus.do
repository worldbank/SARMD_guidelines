/*==================================================
Project:       Household Composition and Poverty Status
Author:        Jayne Yoo and Javier Parada and Andres Castaneda 
Dependencies:  The World Bank
----------------------------------------------------
Creation Date:    	21 April 2019
Modification Date:  21 April 2019
Do-file version:    01
References:         
Output:             
==================================================*/

clear 
set more off 
*cap ssc install blindschemes
*set scheme plotplain, permanently
graph set window fontface "Times New Roman"

tempfile 00
save `00', replace emptyok

local reponame  "sarmd"
local countries ""
local years     ""
local surveys   ""


*---------- Get repo
cap datalibweb, repo(create `reponame', force) type(SARMD)
ren (code year) (country years)
drop if country=="IND"&survname!="NSS-SCH1"

contract country years survname


drop if year<2000 
drop if	(country=="AFG"&year==2013)
bys country: egen myr=max(year)
bys country: egen miyr=min(year)
keep if year==myr
bys country: egen n=count(year)

ds
gen id=country+"_"+strofreal(years)

local varlist "`r(varlist)'"
di in red "`r(varlist)'"

*---------- Evaluate initical conditions
*countries
if ("`countries'" == "") {
	levelsof country, local(countries)
}
	levelsof id, local(ids)

*---------- Loop over countries
drop _all
tempfile cy // countries and years
save `cy', emptyok 

glo path "C:\Users\WB502818\Documents\SARMD_guidelines\findings\hhtype"
set trace off

/*
`"AFG_2007"' `"AFG_2011"' `"BGD_2005"' `"BGD_2016"' `"BTN_2003"' `"BTN_2017"' `"IND_2009"'
>  `"IND_2011"' `"LKA_2006"' `"LKA_2016"' `"MDV_2002"' `"MDV_2016"' `"NPL_2003"' `"NPL_201
> 0"' `"PAK_2004"' `"PAK_2015"'
*/

qui foreach id of local ids {
		tokenize `id', parse("_")
		local country = "`1'"
		local year = "`3'"	

	if ("`country'" == "IND" & `year'==2011) {
		local surveyid "IND_2011_NSS68-SCH10"
		*local year "2011"
	}
	else local surveyid ""
		cap {
			datalibweb, countr(`country') year(`year') type(SARMD) clear surveyid(`surveyid')
			*RENAME VARIABLE NAMES
			
			cap rename welfare_v2 welfare
			cap ren welfareother welfare
			cap rename cpi_v2 cpi
			cap rename ppp_v2 ppp

			*GENERATE POVERTY QUINTILE
			quantiles welfare [aw=wgt], gen(q) n(5)
			quantiles welfare [aw=wgt], gen(p) n(10)
			*xtile q_test = welfare [aw=wgt], nq(5)
			*gen welfare_ppp=welfare/365/icp2011/cpi2011
			ta q, gen(q)
/*			su urban [aw=wgt] if q<=2
			gen value=`r(mean)'*100
			su welfare [aw=wgt]
			gen conspc=`r(mean)'
			contract countrycode year value conspc
			
			append using `cy'
			save `cy', replace
*/
		*di in red "`country'" "`year'"
		*cap keep countrycode year idh urban ownhouse piped_water pipedwater_acc sewage_toilet toilet_acc q p welfare wgt improved_sanitation sanitation_source

		cap keep countrycode idh year age male marital educat4 relationharm educat7 educy lstatus empstat wgt

		*keep if age<18 &male==0
					append using `cy'
			save `cy', replace
		*correlate urban ownhouse piped_water pipedwater_acc sewage_toilet toilet_acc if q<=1		
		}
		
		if (_rc) {
			noi disp in red "Error on `country' `year'"
		}
		else {
			noi disp in y "`country' `year' Done."
			
		}
	}
use `cy', clear
/*
		gen gchild_=(age<18&male==0)
		gen fedu_=educat4 if relationharm<=2&male==0
		gen medu_=educat4 if relationharm<=2&male==1	
		foreach v in fedu medu gchild {
				bys countrycode year idh: egen `v'=max(`v'_)
				drop `v'_
				}
*/
**********************************************
*EARLY MARRIAGE INDICATOR
**********************************************
gen earlym=(age<18&male==0&marital!=2&marital!=.)
replace earlym=. if marital==.

bys countrycode year idh: gen child=age if relationharm==3
 bys countrycode year idh: egen childage=max(child)
 
gen earlym_all=((age==20&male==0&relationharm<3&childage>1)|	///
				(age==21&male==0&relationharm<3&childage>2)|	///
				(age==23&male==0&relationharm<3&childage>3)|	///
				(age==24&male==0&relationharm<3&childage>4))|	///
				earlym==1
gen women_24=(male==0&age<=24)
replace women_24=. if marital==.

**********************************************
*SHARE OF EMPLOYED AMONG MEMBERS IN PRODUCTIVE AGE
**********************************************
gen femadults=(male==0&age>=25&age<=55)
bys countrycode year idh: egen nfemadults=sum(femadults)
gen maladults=(male==1&age>=25&age<=55)
bys countrycode year idh: egen nmaladults=sum(maladults)

gen femearners=(male==0&lstatus==1&age>=20&age<=60)
bys countrycode year idh: egen nfemearners=sum(femearners)

gen malearners=(male==1&lstatus==1&age>=20&age<=60)
bys countrycode year idh: egen nmalearners=sum(malearners)

foreach v in mal fem {
	gen share_`v'earn=n`v'earners/n`v'adults*100
}
**********************************************
*HIGHEST EDUCATION AMONG MEMBERS >25
**********************************************
cap drop femhhedu mfemhhedu
gen femhhedu=educat4 if male==0&age>=25
replace femhhedu=0 if femhhedu==.
bys countrycode year idh: egen mfemhhedu=max(femhhedu)

gen malhhedu=educat4 if male==1&earlym_all!=1
replace malhhedu=0 if malhhedu==.
bys countrycode year idh: egen mmalhhedu=max(malhhedu)

foreach v in /*share_malearn share_femearn*/ mfemhhedu mmalhhedu {
	preserve
	collapse (mean) earlym_all [aw=wgt] if women_24==1, by(countrycode year `v')
	ren earlym_all value
	gen indicator="`v'"
	replace value=value*100
	ren `v' category
	append using `00'
	save `00', replace
	restore
}
foreach v in share_malearn share_femearn {
	*preserve
	collapse (mean) share_malearn share_femearn  [aw=wgt] if women_24==1, by(countrycode year earlym_all)
	*gen indicator="`v'"
	
	reshape long share_*, i(countrycode year earlym_all) j(indicator)
	ren earlym_all category
	*keep countrycode year value indicator
	append using `00'
	save `00', replace
	restore
}
u `00', clear

s

/*wbopendata, country(AFG;BGD;BTN;IND;LKA;MDV;NPL;PAK) indicator(NY.GDP.MKTP.PP.KD ) long clear
keep countrycode year ny_gdp_mktp_pp_kd
sort countrycode year
tempfile gdp
save `gdp', replace*/

use `cy', clear
levelsof countrycode, loc(countries)
	glo path "C:\Users\WB502818\Documents\SARMD_guidelines\findings\Urban Poverty"	
	foreach c of loc countries {
	graph bar value  if countrycode=="`c'", ///
	over(year )	name("`c'", replace) title("Urban Poverty")  subtitle("`c'")
	graph export "${path}/`c'.png", replace	
	}

	graph combine  `countiries',  title("Urban Poverty")  subtitle("`c'")	
	graph export "${path}/all.png", replace	 
