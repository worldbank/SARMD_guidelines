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
			gen cellnoelect=(cellphone==1&electricity==0)
			cap rename welfare_v2 welfare
			cap ren welfareother welfare
			cap rename cpi_v2 cpi
			cap rename ppp_v2 ppp
			cap confirm var welfare 
			if _rc==0 {
			quantiles welfare [aw=wgt], gen(q) n(5)
			su cellphone if q==1 [aw=wgt]
			gen cell=`r(mean)'*100
			su electricity if q==1 [aw=wgt]
			gen elect=`r(mean)'*100
			su cellnoelect if q==1 [aw=wgt]
			gen cellnoel=`r(mean)'*100
			contract countrycode year cell elect cellnoel
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

bys country: egen myr=max(year)
bys country: egen miyr=min(year)
keep if year==myr|year==miyr
bys country: egen n=count(year)
keep if n>1

label var cell "Cell Phone"	
label var elect "Electricity"	
label var cellnoel "Cell Phone w/o Electricity"

levelsof countrycode, loc(countries)
foreach c of loc countries {
	graph bar cell elect cellnoel if countrycode=="`c'", ///
	over( year) name("`c'", replace)  subtitle("`c'")	///
	bar(1, color(blue)) bar(2, color(orange))  bar(3, color(green))	///
	legend(order( 1 "Cell Phone" 2 "Electricity" 3 "Cell Phone w/o Electricity")) legend(pos(6) row(1)) blabel(total, format(%9.1f)) 


	graph export "${path}/`c'.png", replace	
	}
	
grc1leg AFG BGD BTN LKA NPL PAK, ycommon title("Access to Cell Phone & Electricity among Poor (%)")  
graph export "${path}/all.png", replace	

