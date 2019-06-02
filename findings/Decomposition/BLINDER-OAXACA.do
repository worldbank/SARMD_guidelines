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
drop if country=="AFG"

/*drop if country=="IND" |country=="MDV"
drop if country=="LKA"&year==2002
*keep if country=="MDV" &year>2002*/

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

			set trace off
			*gen cellnoelect=(cellphone==1&electricity==0)
			cap rename welfare_v2 welfare
			cap ren welfareother welfare
			cap rename welfare_v2 welfare
			cap rename cpi_v2 cpi
			cap rename ppp_v2 ppp
			cap ren (educat4_v2 lstatus_v2) (educat4 lstatus)
			* Generate household density by per capita expenditures

			cap ren industry_orig_v2 industry
			recode industry (2 3 4 5=2) (6 7 8 9=3) (10=4) (11 12 13 14=.)
			*drop if industry==.
*			ta  industry, g(ind_)
			cap confirm var welfare 
			if _rc==0 {
			drop if welfare==.
			cap gen welfare_ppp=welfare/ppp/cpi/365*12
			gen ln_welfare=log(welfare_ppp)
			scalar pline_190=ln(1.90)
			scalar pline_320=ln(3.20)
			scalar pline_550=ln(5.50)
			scalar list
			gen poor=welfare_ppp<1.9 if welfare!=.			
			keep if relationharm==1
			keep countrycode year educat4 lstatus industry welfare_ppp wgt

			append using `00'
			save `00', replace	
			restore
		}
		
		if (_rc) {
			noi disp in red "Error on `country' `year'"
		}
		else {
			noi disp in y "`country' `year' Done."
		}

	}
}

u `00', clear

drop if countrycode=="BGD" &year<2010
drop if countrycode=="IND"
drop if countrycode=="LKA" & (year==2012|year<2009)
drop if countrycode=="MDV"
drop if countrycode=="PAK" & (year==2011|year==2013|year<2010)

save "C:\Users\WB502818\Documents\SARMD_guidelines\findings\Decomposition\data.dta", replace
u "C:\Users\WB502818\Documents\SARMD_guidelines\findings\Decomposition\data.dta", clear

keep if countrycode=="BGD"

replace educat4=educat4_v2 if educat4==.
replace lstatus=lstatus_v2 if lstatus==.

gen education_none = (educat4==1)
gen education_prim = (educat4==2)
gen education_seco = (educat4==3)
gen education_tert = (educat4==4)
gen education_miss = (educat4==.)
cap drop educat4 lstatus_v2 educat4_v2

*gen lfs_inac = (lfs_head==0)
gen lfs_empl = (lstatus==1)
gen lfs_unem = (lstatus==2)
gen lfs_OLF = (lstatus==3)
gen lfs_miss = (lstatus==.)
	
gen industry_agri = (industry==1)
gen industry_indu = (industry==2)
gen industry_service= (industry==3)
gen industry_other = (industry==4)
gen industry_miss = (industry==.)
drop industry
replace poor_190=poor_190*100
levelsof countrycode, loc(code)
foreach c of loc code {
oaxaca poor_190 educ* lfs* industry* [iw=wgt] if countrycode=="`c'", by(year) swap relax  ///
categorical(educ*, lfs*, industry*) logit
outreg2 using "C:\Users\WB502818\Documents\SARMD_guidelines\findings\Decomposition\results@2.xls", replace ctitle("`c'")
}

s

append using `pp1'
			ren ind* re_ind*
			reshape long re_, i(countrycode year label ) j(indicator, string)
			ren re_ value



export excel using "${path}/decomposition.xlsx", sheet("master") sheetreplace first(variable)

