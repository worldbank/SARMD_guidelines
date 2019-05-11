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

cap ssc install blindschemes
set scheme plotplain, permanently
graph set window fontface "Times New Roman"

local reponame  "sarmd"
local countries ""
local years     ""
local surveys   ""


*---------- Get repo
cap datalibweb, repo(create `reponame', force) type(SARMD)
ren (code year) (country years)
drop if country=="IND"&survname!="NSS-SCH1"

contract country years survname
preserve
keep if (country=="NPL"&year==2010)|(country=="AFG"&year==2011)
tempfile 00
save `00', replace
restore


bys country: egen myr=max(year)

keep if year==myr
drop if country=="NPL"|country=="AFG"
append using `00'

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

qui foreach id of local ids {
		tokenize `id', parse("_")
		local country = "`1'"

		local year = "`3'"	

	if ("`country'" == "IND" & `year'==2011) {
		local surveyid "NSS68-SCH1.0-T1"

	}
	else local surveyid ""
		cap {
			datalibweb, countr(`country') year(`year') type(SARMD) clear surveyid(`surveyid')
			
			cap rename welfare_v2 welfare
			cap ren welfareother welfare
			quantiles welfare [aw=wgt], gen(q) n(5)
				
			cap keep countrycode year idh idp wgt relationharm relationcs age male welfare q
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

u `cy', clear

*Female head
gen fhead=(male==0&relationharm==1)
gen mhead=(male==1&relationharm==1)
gen spouse=(relationharm==2)
gen child=(age<18&relationharm==3)
gen parent=(relationharm==4)
gen other=(relationharm==5)
preserve
collapse (max) fhead mhead spouse child parent other, by(countrycode year idh)
sort idh
tempfile hh
save `hh', replace
restore
drop  fhead mhead spouse child parent other
sort idh
merge idh using `hh'
ta _m
drop _m


foreach v in f m {
gen	`v'scpo	=	(`v'head==	1	&spouse==	1	&child==	1	&parent==	1	&other==	1)
gen	`v'scp	=	(`v'head==	1	&spouse==	1	&child==	1	&parent==	1	&other==	0)

gen	`v'sco	=	(`v'head==	1	&spouse==	1	&child==	1	&parent==	0	&other==	1)
gen	`v'sc	=	(`v'head==	1	&spouse==	1	&child==	1	&parent==	0	&other==	0)
gen	`v'spo	=	(`v'head==	1	&spouse==	1	&child==	0	&parent==	1	&other==	1)
gen	`v'sp	=	(`v'head==	1	&spouse==	1	&child==	0	&parent==	1	&other==	0)
gen	`v'so	=	(`v'head==	1	&spouse==	1	&child==	0	&parent==	0	&other==	1)
gen	`v's	=	(`v'head==	1	&spouse==	1	&child==	0	&parent==	0	&other==	0)
gen	`v'cpo	=	(`v'head==	1	&spouse==	0	&child==	1	&parent==	1	&other==	1)
gen	`v'cp	=	(`v'head==	1	&spouse==	0	&child==	1	&parent==	1	&other==	0)
gen	`v'co	=	(`v'head==	1	&spouse==	0	&child==	1	&parent==	0	&other==	1)
gen	`v'c	=	(`v'head==	1	&spouse==	0	&child==	1	&parent==	0	&other==	0)
gen	`v'po	=	(`v'head==	1	&spouse==	0	&child==	0	&parent==	1	&other==	1)
gen	`v'p	=	(`v'head==	1	&spouse==	0	&child==	0	&parent==	1	&other==	0)
gen	`v'o	=	(`v'head==	1	&spouse==	0	&child==	0	&parent==	0	&other==	1)
gen	`v'	=	(`v'head==	1	&spouse==	0	&child==	0	&parent==	0	&other==	0)
gen `v'ext=(`v'scpo==1|`v'sco==1)
gen s`v'ext=(fcpo==1|fcp==1|fco)
}
gen ext=(fext==1|mext==1)
gen sext=(sfext==1|smext==1)
gen scp=(fscp==1|mscp==1)
gen sc=(fsc==1|msc==1)
gen c=(fc==1|mc==1)
gen onep=(f==1|m==1)


gen 	agecat=age
recode 	agecat 0/9=1 10/14=2 15/19=3 20/24=4 25/29=5 30/34=6 35/39=7 40/44=8 45/49=9 50/54=10 55/59=11 60/64=12 65/150=13
/*
preserve
collapse (mean) fext sfext fscp fsc fc  	///
		mext smext mscp msc mc  [aw=wgt] if q<=2, by(countrycode year agecat)
sort countrycode year
tempfile poor
save `poor', replace
restore

collapse (mean) fext sfext fscp fsc fc  	///
		mext smext mscp msc mc  [aw=wgt] , by(countrycode year agecat)

foreach v in fext sfext fscp fsc fc mext smext mscp msc mc {
ren `v' all_`v'
}
*/
sort countrycode year
merge countrycode year using `poor'
ta _m
drop _m
ren * re_*
drop if agecat==.
ren (re_countrycode re_year re_agecat) (countrycode year agecat)
reshape long re_, i(countrycode year agecat) j(var, string)
reshape wide re_, i(countrycode year var) j(agecat)

		