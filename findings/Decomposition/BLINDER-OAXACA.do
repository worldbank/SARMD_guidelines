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

if ("`c(username)'" == "wb384996") {
	cd "c:/Users/wb384996/OneDrive - WBG/SARTSD/SARMD_guidelines/findings/Decomposition/"
}


tempfile reponame

local countries ""
local years     ""
local surveys   ""

cap which oaxaca
if (_rc) ssc install oaxaca

drop _all
tempfile  01
save `01', emptyok

			
*---------- Get repo
cap datalibweb, repo(create `reponame', force) type(SARMD)
cap ren (code year) (country years)
contract country years survname 

keep if (country=="BGD"&(year==2010|year==2016))|	///
(country=="BTN"&(year==2007|year==2017))|	///
(country=="PAK"&(year==2011|year==2015))

gen id=country+"_"+strofreal(years)
ds
local varlist "`r(varlist)'"
di in red "`r(varlist)'"



*---------- Evaluate initical conditions
*countries
if ("`countries'" == "") {
	levelsof country, local(countries)
}

levelsof id, local(ids)
set trace off
*---------- Loop over countries

preserve
drop _all
tempfile 00
save `00', emptyok	
restore
 foreach id of local ids {
		tokenize `id', parse("_")
		local country = "`1'"

		local year = "`3'"	


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
set trace off
			gen lfs_empl = (lstatus==1)
			gen lfs_unem = (lstatus==2)
			gen lfs_OLF = (lstatus==3)
			gen lfs_miss = (lstatus==.)
				
			gen industry_agri = (industry==1)
			gen industry_industry = (industry==2)
			gen industry_services= (industry==3)
			gen industry_other = (industry==4)
			gen industry_miss = (industry==.)
			drop industry

			g poor_190=poor_nat*100
			drop if poor_nat==.

			levelsof countrycode, loc(code)
			foreach c of loc code {
			su year if countrycode=="`c'"
			loc y1=r(min)
			loc y2=r(max)
			preserve
				oaxaca poor_190 urban literacy  male lfs_* industry_* [aw=wgt] if countrycode=="`c'" , by(year) swap relax  ///
				categorical( lfs_*, industry_*) 
// -------------------------------------------------------------------------------------------------
// Export results
// -------------------------------------------------------------------------------------------------

			mat B = e(b)

			clear
			svmat2 B
			gen countrycode="`c'"

			foreach n of numlist 31/43 {
				drop B`n'
				}

// -------------------------------------------------------------------------------------------------
// Export results
// -------------------------------------------------------------------------------------------------

			loc coeff B1 B2 B3 B4 B5 B6 B7 B8 B9 B10 B11 B12 B13 B14 B15 B16 B17 ///
						B18 B19 B20 B21 B22 B23 B24 B25 B26 B27 B28 B29 B30
			local name Year2	Year1	Difference	Endowments	Coefficients	///
					Interaction	Urban	Literacy	Male	Employed	Unemployed	///
					OLF	lstatus_missing	Agriculture	Industry	Service	Other	Sector_missing	///
					c_Urban	c_Literacy	c_Male	c_Employed	c_Unemployed	c_OLF	c_lstatus_missing		///
					c_Agriculture	c_Industry	c_Service	c_Other	c_Sector_missing

			rename (`coeff') (`name')

			foreach v of loc name {
				ren `v' B_`v'
				}
			reshape long B_, i(countrycode) j(variable, string)	
			
			*Order variable label
			label define order  1 Year2	2 Year1	3 Difference	4 Endowments	5 Coefficients	///
					6 Interaction	7 Urban	8 Literacy	9 Male	10 Employed	11 Unemployed	///
					12 OLF	13 lstatus_missing	14 Agriculture	15 Industry	16 Service	17 Other	18 Sector_missing	///
					19 c_Urban	20 c_Literacy	21 c_Male	22 c_Employed	23 c_Unemployed	24 c_OLF	25 c_lstatus_missing		///
					26 c_Agriculture	27 c_Industry	28 c_Service	29 c_Other	30 c_Sector_missing
			encode variable, gen(b) label(order)
			sort b
			
			gen category="Total effect" if inrange(b, 1,5)
			replace category="Endowment" if inrange(b,6,18)
			replace category="Coefficient" if inrange(b,19,30)
			replace variable=subinstr(variable,"c_","",.) 
			drop if inlist(b, 13, 18, 25, 30)
			drop b
			
			ren B_ value

			format value %15.2f
			order countrycode category variable value
			append using `01'
			save `01', replace
			restore
				}


// -------------------------------------------------------------------------------------------------
// Export results as CSV
// -------------------------------------------------------------------------------------------------			
u `01', clear

preserve
keep if category=="Total effect"
replace value=round(value,0.01)
reshape wide value, i(variable) j(countrycode, string)
label define order  1 Year2 2 Year1 3 Difference 4 Endowments 5 Coefficients
encode variable, gen(b) label(order)
sort b 
drop b category
ren value* *
export delimited using "C:\Users\WB502818\Documents\SARMD_guidelines\findings\Decomposition\toteffect.csv", replace
restore

drop if category=="Total effect"
reshape wide value, i(category variable) j(countrycode, string)
ren value* *
order category variable PAK BTN BGD
label define order  1 Endowment 2 Coefficient
encode category, gen(b) label(order)
label define order2 1 Urban	2 Literacy	3 Male	4 Employed	5 Unemployed	///
					6 OLF	7 lstatus_missing	8 Agriculture	9 Industry	10 Service	11 Other
encode variable, gen(c) label(order2)
sort b c
drop b c category
foreach v in PAK BTN BGD {
	replace `v'=round(`v',0.01)
	}
export delimited using "C:\Users\WB502818\Documents\SARMD_guidelines\findings\Decomposition\sub_effect.csv", replace
