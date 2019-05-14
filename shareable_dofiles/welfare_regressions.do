/*==================================================
Project:       Welfare Regressions
Author:        Javier Parada and Andres Castaneda 
Dependencies:  The World Bank
----------------------------------------------------
Creation Date:    	14 May 2019
Modification Date:  
Do-file version:    01
References:         
Output:             csv files
==================================================*/
cap ssc install blindschemes
set scheme plotplain, permanently
graph set window fontface "Times New Roman"

if ("`c(hostname)'" == "wbgmsbdat001") {
	global hostdrive "D:"
}
else {
	global hostdrive "\\Wbgmsbdat001"
}

/*==================================================
           Alternative version 2
==================================================*/

cd "${hostdrive}\SOUTH ASIA MICRO DATABASE\05.projects_requ\01.SARMD_Guidelines\02. qcheck\02. sar qcheck\09. shareable do-files\Javier_Note3_Final\"

local reponame  "sarmd"
local countries ""
local years     ""
local surveys   ""

*---------- Get repo
cap datalibweb, repo(create `reponame', force) type(SARMD)
contract country countryname years survname 
drop _freq
ds
local varlist "`r(varlist)'"

*---------- Evaluate initial conditions
*countries
if ("`countries'" == "") {
	levelsof country, local(countries)
}

*---------- Export to MATA
mata: R = st_sdata(.,tokens(st_local("varlist")))

*---------- Loop over countries

drop _all
tempfile cy // countries and years
save `cy', emptyok 

qui foreach country of local countries {
	
	eststo clear
	
	mata: st_local("years",                   /*   set local years 
	 */          invtokens(                   /*    create tokens out of matrix
	 */          select(R[.,2], R[.,1] :== st_local("country"))', /*  select years
	 */          " "))                          // separator (second term in )
	
	local years: list uniq years // in case of more than one survey 
	
	foreach year of local years {
		
		if ("`country'" == "IND" & "`year'"=="2011") {
			local surveyid "NSS68-SCH1.0-T1"
		}
		else local surveyid ""
	
		cap {
				
				
			datalibweb, country(`country') year(`year') type(SARMD) surveyid(`surveyid') clear 
			
			* Define control variables
			gen age_squared=age^2
			label var age_squared "Age squared"
			label define lbl_electricity  0 "No Electricity" 1 "Electricity" 
			label define lbl_ownhouse  0 "Not own house" 1 "Own house" 
			label define lbl_literacy  0 "Not literate" 1 "Literate" 
			cap label values electricity lbl_electricity
			cap label values ownhouse lbl_ownhouse
			cap label values literacy lbl_literacy
			
			* Generate dependent variable
			cap rename welfare_v2 welfare
			cap rename cpi_v2 cpi
			cap rename ppp_v2 ppp
			gen ln_welfare_perc=ln(welfare/cpi/ppp/365*12/1.90)
			
			* Declare survey design for dataset
			svyset psu [pw=pop_wgt], strata(strata)
		
			local controls_AFG "i.male age age_squared hsize i.urban i.electricity i.ownhouse i.subnatid1"
			local controls_BGD "i.male age age_squared hsize i.urban i.electricity i.ownhouse i.subnatid1"
			local controls_BTN "i.male age age_squared hsize i.urban i.electricity i.ownhouse i.subnatid1"
			local controls_IND "i.male age age_squared hsize i.urban i.electricity i.ownhouse i.subnatid1"
			local controls_MDV "i.male age age_squared hsize i.urban i.ownhouse i.subnatid1"
			local controls_NPL "i.male age age_squared hsize i.urban i.electricity i.ownhouse i.subnatid1"
			local controls_PAK "i.male age age_squared hsize i.urban i.electricity i.ownhouse i.subnatid1"
			local controls_LKA "i.male age age_squared hsize i.urban i.ownhouse i.subnatid1"

			* Describe data
			sum ln_welfare_perc poor_int `controls_`country'' if relationharm==1 [aw=pop_wgt]

			* Conduct regressions
			eststo model1_linear_`country'_`year': svy: reg ln_welfare_perc `controls_`country'' if relationharm==1
			eststo model2_logit_`country'_`year': svy: logit poor_int `controls_`country'' if relationharm==1
		
		}
		
		if (_rc) {
			noi disp in red "Error on `country' `year' `surveyid'"
			cap eststo model1_linear_`country'_`year': reg ln_welfare_perc `controls_`country'' if relationharm==1
			cap eststo model2_logit_`country'_`year': logit poor_int `controls_`country'' if relationharm==1
		}
		else {
			noi disp in y "`country' `year' `surveyid' Done."
		}

	}

	
	* Present results
	local mtitles_AFG mtitles("2007" "2011")
	local mtitles_BGD mtitles("2000" "2005" "2010" "2016")
	local mtitles_BTN mtitles("2003" "2007" "2012" "2017")
	local mtitles_IND mtitles("1993" "2004" "2009" "2011")
	local mtitles_MDV mtitles("2009" "2016")
	local mtitles_NPL mtitles("2003" "2010")
	local mtitles_PAK mtitles("2001" "2004" "2005" "2007" "2010" "2011" "2013" "2015")
	local mtitles_LKA mtitles("2002" "2006" "2009" "2012" "2016")

	local addnote_BGD ("Note psu not available in 2005.")



	esttab model1_linear_`country'* using model1_linear_`country'.csv, se r2 label replace nogaps   ///
	nonumbers `mtitles_`country'' ///
	title(Linear regression: Dependent variable ln_welfare_perc)       ///
	addnote(`addnote_`country'')

	esttab model2_logit_`country'* using model2_logit_`country'.csv, se pr2 label replace nogaps  ///
	nonumbers `mtitles_`country'' ///
	title(Logit regression: Dependent variable poor_int)       ///
	addnote(`addnote_`country'')

	
}


