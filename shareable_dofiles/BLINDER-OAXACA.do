/*==================================================
Project:       Oaxaca Decomposition
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

glo path "C:\Users\WB502818\Documents\SARMD_guidelines\findings\Labor Market"

*---------- Get repo
cap datalibweb, repo(create `reponame', force) type(SARMD)
ren (code year) (country years)

contract country years survname 

keep if country=="BGD" 
drop if year<2010

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
tempfile 00
	save `00', emptyok 

 foreach id of local ids {
		tokenize `id', parse("_")
		local country = "`1'"

		local year = "`3'"	

	if ("`country'" == "IND" & `year'==2011) {
		local surveyid "IND_2011_NSS68-SCH10"

	}
	else local surveyid ""
	cap {
			datalibweb, countr(`country') year(`year') type(SARMD) clear surveyid(`surveyid')
			cap ren (educat4_v2 lstatus_v2) (educat4 lstatus)

			cap ren industry_orig_v2 industry
			recode industry (2 3 4 5=2) (6 7 8 9=3) (10=4) (11 12 13 14=.)

					
			keep if relationharm==1
			keep countrycode year literacy urban male lstatus industry  wgt poor_nat

			append using `00'
			save `00', replace	
			restore
		
		
		if (_rc) {
			noi disp in red "Error on `country' `year'"
		}
		else {
			noi disp in y "`country' `year' Done."
		}

	}
}

u `00', clear

gen lfs_empl = (lstatus==1)
gen lfs_unem = (lstatus==2)
gen lfs_OLF = (lstatus==3)
gen lfs_miss = (lstatus==.)
	
gen industry_agri = (industry==1)
gen industry_ining = (industry==2)
gen industry_manu= (industry==3)
gen industry_public = (industry==4)
gen industry_miss = (industry==.)
drop industry
g poor_190=poor_nat*100
drop if poor_nat==.

levelsof countrycode, loc(code)

oaxaca poor_190 urban literacy  male lfs* industry* [aw=wgt] , by(year) swap relax  ///
categorical( lfs*, industry*) 


