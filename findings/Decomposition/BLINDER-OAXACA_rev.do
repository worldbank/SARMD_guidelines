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
			
			ren B_ value


			append using `01'
			save `01', replace
			restore
				}


			
u `01', clear
export excel using "C:\Users\WB502818\Documents\SARMD_guidelines\findings\Decomposition\decomp_results.xls", sheetreplace firstrow(variables)
