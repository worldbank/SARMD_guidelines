************************** Schooling by age *************************
************************** Javier Parada ****************************
************************** March 21, 2019 ***************************

*************************** Set directory ***************************

if ("`c(hostname)'" == "wbgmsbdat001") {
	global hostdrive "D:"
}
else {
	global hostdrive "\\Wbgmsbdat001"
}
cd "${hostdrive}\SOUTH ASIA MICRO DATABASE\05.projects_requ\01.SARMD_Guidelines\02. qcheck\02. sar qcheck\08. new notes\01. school enrollment\" 

*************** Import SAR inventory from excel table ***************

clear all

import excel "${hostdrive}\SOUTH ASIA MICRO DATABASE\05.projects_requ\01.SARMD_Guidelines\02. qcheck\02. sar qcheck\01. sarmd inventory\inventory.xlsx", sheet("inventory") firstrow allstring clear

levelsof countries, local(countries)

foreach country of local countries {
	display "`country'"
	levelsof years if (countries == "`country'"), local(`country'_years)
	foreach year of local `country'_years { 
		levelsof SARMD if (countries == "`country'" & years == "`year'"), local(`country'_`year'_address) clean	
	}
}

/******************** Create appended dataset ************************

gen countrycode=""
save "appended_data.dta", 

* Loop over sarmd
foreach country of local countries {
	foreach year of local `country'_years { 
	 cap ``country'_`year'_address'
		if (_rc) continue
			append using appended_data.dta, force
			save "appended_data.dta", replace
	}
}
*/

******************************* Graphs *******************************

use appended_data.dta, clear
replace atschool=atschool_v2 if atschool==. & countrycode=="AFG" & year==2007
local age_trim "age<=30"
collapse (mean) atschool [aw=wgt], by(countrycode year age male urban)

preserve

foreach country of local countries {
	restore
	preserve
	display "`country'"
	keep if countrycode=="`country'"
	twoway (line atschool age if male==1 & urban==1 & `age_trim')(line atschool age if male==0 & urban==1 & `age_trim')(line atschool age if male==1 & urban==0 & `age_trim')(line atschool age if male==0 & urban==0 & `age_trim'), legend(order(1 "Urban Male" 2 "Urban Female" 3 "Rural Male" 4 "Rural Female")) by(countrycode year, title(Percentage attending school (`country')))
	graph export `country'_school_enrollment.pdf, replace
}

