/*==================================================
Project:       Sanitation
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

glo path "C:\Users\WB502818\Documents\SARMD_guidelines\findings\Sanitation"

*---------- Get repo
cap datalibweb, repo(create `reponame', force) type(SARMD)
ren (code year) (country years)

*drop if country=="IND"&survname!="NSS-SCH1"

contract country years survname 
drop if country=="IND" |country=="MDV"

drop if country=="LKA"&year==2002
*keep if country=="MDV" &year>2002
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
		local surveyid "IND_2011_NSS68-SCH10"

	}
	else local surveyid ""
	cap {
			datalibweb, countr(`country') year(`year') type(SARMD) clear surveyid(`surveyid')

			set trace off
			*gen cellnoelect=(cellphone==1&electricity==0)
			cap rename welfare_v2 welfare
			cap ren welfareother welfare
			cap rename cpi_v2 cpi
			cap rename ppp_v2 ppp
			cap ren sar_improved_toilet_v2 toilet_acc 
			cap ren piped_water_v2 piped_water
			cap ren sar_improved_toilet toilet_acc
			cap recode pipedwater_acc   (2=1)
			cap ren pipedwater_acc piped_water
			recode toilet_acc (2 3=1)
			cap confirm var welfare 
			if _rc==0 {
			drop if welfare==.
			quantiles welfare [aw=wgt], gen(q) n(5)
			gen poor=(q<=2)
			preserve
			collapse (mean)  piped_water  toilet_acc [aw=wgt], by(countrycode year )
			gen poor=2
			append using `cy'
			save `cy', replace
			restore
			collapse (mean)  piped_water  toilet_acc [aw=wgt], by(countrycode year poor)
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

u `cy', clear

gen label =""
replace label="All" if poor==2
replace label="Poor" if poor==1
replace label="Non Poor" if poor==0

ren (piped_water toilet_acc) (re_piped_water re_toilet_acc)
reshape long re_, i(countrycode year poor) j(indicator, string)
ren re_ value



export excel using "${path}/sanitation.xlsx", sheet("master") sheetreplace first(variable)

