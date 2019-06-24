/*==================================================
Project:       Industry
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

*drop if country=="IND"&survname!="NSS-SCH1"

contract country years survname 
/*drop if country=="IND" |country=="MDV"

drop if country=="LKA"&year==2002
*keep if country=="MDV" &year>2002*/

drop if country=="MDV"& year==2002
drop if country=="LKA"
*keep if country=="BGD"
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
tempfile cy pp

	save `cy', emptyok 
	save `pp', emptyok 



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

			set trace off
			*gen cellnoelect=(cellphone==1&electricity==0)
			cap rename welfare_v2 welfare
			cap ren welfareother welfare
			cap rename welfare_v2 welfare
			cap rename cpi_v2 cpi
			cap rename ppp_v2 ppp
			
			* Generate household density by per capita expenditures
			gen welfare_ppp=welfare/ppp/cpi/365*12
			cap ren industry_orig_v2 industry
			recode industry (2 3 4 5=2) (6 7 8 9=3) (10=4) (11 12 13 14=.)
			ta  industry, g(ind_)
			cap confirm var welfare 
			if _rc==0 {
			drop if welfare==.
			quantiles welfare [aw=wgt], gen(q) n(5)
			*gen poor=(q<=2)
			
			preserve
			collapse (mean)  ind_* [aw=wgt], by(countrycode year  )
			append using `cy'
			save `cy', replace
			
			restore
			
			*preserve
			collapse (mean)  welfare_ppp [aw=wgt], by(countrycode year industry )
			gen label=""
			replace label="Agriculture" if industry==1
			replace label="Manufacturing" if industry==2
			replace label="Services" if industry==3
			replace label="Other" if industry==4
			drop industry
			append using `pp'
			save `pp', replace	
			*			restore
			/*
			collapse (mean)  ind_* [aw=wgt], by(countrycode year q)
			
			append using `qi'
			save `qi', replace
			*/
		
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
*drop if industry==.
ren ind* re_ind*
reshape long re_, i(countrycode year) j(label, string)
ren re_ value
append using `pp'
s
gen label =""
replace label="All" if poor==2
replace label="Poor" if poor==1
replace label="Non Poor" if poor==0

ren (piped_water toilet_acc) (re_piped_water re_toilet_acc)
reshape long re_, i(countrycode year poor) j(indicator, string)
ren re_ value



export excel using "${path}/sanitation.xlsx", sheet("master") sheetreplace first(variable)

