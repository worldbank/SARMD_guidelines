/*==================================================
Project:       Cell Phone
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
			keep countrycode year cellphone electricity wgt
			gen cellelec=(cellphone==1&electricity==1)
			gen cellnoelec=(cellphone==1&electricity==0)
			su cellelec [aw=wgt]
			gen cell01=`r(mean)'*100
			su cellnoelec [aw=wgt]
			gen cell00=`r(mean)'*100
			contract countrycode year cell01 cell00	
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

drop if countrycode=="AFG"&year==2011
drop if countrycode=="PAK"&year==2010
drop if countrycode=="IND"
keep if (countrycode=="BGD"&(year==2005|year==2016))|	///
(countrycode=="BTN"&(year==2007|year==2017))|	///
(countrycode=="NPL"&(year==2003|year==2016))|	///
(countrycode=="LKA"&(year==2006|year==2016))

label var cell00 "Cell Phone w/o Electricity"	
label var cell01 "Cell Phone w/ Electricity"

levelsof countrycode, loc(countries)
foreach c of loc countries {
	graph bar cell00 cell01  if countrycode=="`c'" , ///
	stack over( year) name("`c'", replace)  subtitle("`c'")	///
	bar(1, color(blue)) bar(2, color(orange)) 	///
	legend(order( 1 "No Access to Electricity" 2 "Access to Electricity")) legend(pos(6) row(1)) blabel(bar, pos(center) format(%9.1f)) 


	graph export "${path}/`c'.png", replace	
	}
	
grc1leg  BGD BTN LKA NPL, ycommon title("Access to Cell Phone (%)")  
graph export "${path}/all.png", replace	

