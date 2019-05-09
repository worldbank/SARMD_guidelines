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


drop if year<2000 
drop if	(country=="AFG"&year==2013)
bys country: egen myr=max(year)
bys country: egen miyr=min(year)
keep if year==myr|year==miyr
bys country: egen n=count(year)
keep if n>1
preserve
keep if (country=="LKA"|country=="PAK"|country=="IND"|country=="BGD") 
	keep if myr==years
tempfile 00
save `00', replace
restore
drop if (country=="NPL"|country=="LKA"|country=="PAK"|country=="IND"|country=="BGD") 
append using `00'
tempfile 01
save `01' , replace
cap datalibweb, repo(create `reponame', force) type(SARMD)
ren (code year) (country years)
drop if country=="IND"&survname!="NSS-SCH1"

contract country years survname

keep if (country=="NPL"&year==2003) |	///
		(country=="NPL"&year==2010) |	///
		(country=="LKA"&year==2006) |	///
		(country=="PAK"&year==2004) |	///
		(country=="IND"&year==2009) |	///
		(country=="BGD"&year==2005)
append using `01'

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

glo path "C:\Users\WB502818\Documents\SARMD_guidelines\findings\Utility"
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
				
			cap keep countrycode year idh idp wgt cellphone electricity welfare q
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
gen cellelect=.
replace  cellelect=1 if cellphone==0& electricity==0
replace  cellelect=2 if cellphone==0& electricity==1
replace  cellelect=3 if cellphone==1& electricity==0
replace  cellelect=4 if cellphone==1& electricity==1
ta cellelect, gen(cell_el)

