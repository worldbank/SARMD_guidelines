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

}

collapse (mean) fscpo fscp fsco fsc fspo fsp fso fs fcpo fcp fco fc fpo fp fo f 	///
		mscpo mscp msco msc mspo msp mso ms mcpo mcp mco mc mpo mp mo m [aw=wgt] if q==1, by(countrycode year)
sort countrycode year

		