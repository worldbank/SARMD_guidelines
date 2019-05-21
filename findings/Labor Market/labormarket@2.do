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
tempfile pp 
tempfile pp1

	
	save `pp', emptyok 
	save `pp1', emptyok 



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
			drop if industry==.
			ta  industry, g(ind_)
			cap confirm var welfare 
			if _rc==0 {
			drop if welfare==.
			quantiles welfare [aw=wgt], gen(q) n(5)
			gen poor=(q<=1)
			gen top=(q==5)

			
			preserve
			collapse (mean)  ind_* [aw=wgt] if q==1, by(countrycode year  )
			gen label="q1"
			append using `pp'
			save `pp', replace	
			restore
			
			collapse (mean)  ind_* [aw=wgt] if q==5, by(countrycode year  )
			gen label="q5"
			append using `pp1'
			save `pp1', replace	
			
			/*
			collapse (mean)  ind_* [aw=wgt], by(countrycode year q)
			
			append using `qi'
			save `qi', replace
			*/
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

u `pp', clear

append using `pp1'

append using `pp1'
			ren ind* re_ind*
			reshape long re_, i(countrycode year label ) j(indicator, string)
			ren re_ value



export excel using "${path}/labor.xlsx", sheet("master") sheetreplace first(variable)

