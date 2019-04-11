/*==================================================
Project:       Welfare Distribution and Access to Assets
Author:        Javier Parada and Andres Castaneda 
Dependencies:  The World Bank
----------------------------------------------------
Creation Date:    	10 April 2019
Modification Date:  10 April 2019
Do-file version:    01
References:         
Output:             
==================================================*/

if ("`c(hostname)'" == "wbgmsbdat001") {
	global hostdrive "D:"
}
else {
	global hostdrive "\\Wbgmsbdat001"
}

/*==================================================
           Alternative version 2
==================================================*/

cd "${hostdrive}\SOUTH ASIA MICRO DATABASE\05.projects_requ\01.SARMD_Guidelines\02. qcheck\02. sar qcheck\08. new notes\03. welfare distribution and assets\"

local assets = "bicycle cellphone computer electricity everattend fan landphone literacy motorcar motorcycle ownhouse piped_water radio refrigerator sewage_toilet sewingmachine television washingmachine"
local reponame  "sarmd"
local countries ""
local years     ""
local surveys   ""

*---------- Get repo
datalibweb, repo(create `reponame', force) type(SARMD)
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
			
			* Fix v2
			cap rename welfare_v2 welfare
			cap rename cpi_v2 cpi
			cap rename ppp_v2 ppp
			
			* Generate household density by per capita expenditures
			gen ln_welfare=ln(welfare/ppp/cpi/365*12)
			gen pline_190=ln(1.90)
			gen pline_320=ln(3.20)
			gen pline_550=ln(5.50)
			gen poor_190=ln_welfare<pline_190 if welfare!=.
			gen poor_320=ln_welfare<pline_320 if welfare!=.
			gen poor_550=ln_welfare<pline_550 if welfare!=.
			noi disp in blue "`country' `year' `surveyid' Headcounts:."
			noi sum poor* [aw=wgt]

			sort ln_welfare
			kdensity ln_welfare [aw = wgt], gen(newvarx newvard) normal
			label var newvard "Household density"
			
			* Generate cumulative percentages for access to assets
			foreach asset of local assets{
				cap gen cum_mean_`asset' = sum(`asset'*wgt)/sum(wgt) if `asset' < .
			}

			* Label new variables
			label var cum_mean_refrigerator "Refrigerator"
			label var cum_mean_electricity "Electricity"
			label var cum_mean_bicycle "Bicycle"


			scalar pline_190=ln(1.90)
			scalar pline_320=ln(3.20)
			scalar pline_550=ln(5.50)
			scalar list

			local asset "refrigerator"

			* Graph
			graph twoway ///
				(line newvard newvarx, lcolor(black) lpattern(dash)) ///
				(line cum_mean_`asset' ln_welfare, lcolor(black)), ///
				xline(`=scalar(pline_190)' `=scalar(pline_320)' `=scalar(pline_550)', lwidth(vthin) lcol(red)) /// 
				xlabel(`=scalar(pline_190)' "1.90" `=scalar(pline_320)' "3.20" `=scalar(pline_550)' "5.50") ///
				ytitle("Fraction of households with `asset'") ///
				xtitle("Daily expenditure per person in 2011 USD (PPP) (ln scale)") ///
				title("Access to `asset' and Household Expenditure Level", size(medium)) ///
				subtitle("`country' `year'", size(medium)) ///
				scheme(s1color)
			
			graph export `country'_`year'.png, replace
			
			keep ln_welfare newvard newvarx cum_mean_*
			gen country = "`country'"
			gen year    = `year'
			append using `cy'
			save `cy', replace 
			
			
		
		
		}
		
		if (_rc) {
			noi disp in red "Error on `country' `year' `surveyid'"
		}
		else {
			noi disp in y "`country' `year' `surveyid' Done."
		}

	}
}


* Graph of asset by country 

local asset "refrigerator"

foreach country of local countries{

	mata: st_local("name",                   /*   set local name 
	 */          invtokens(                   /*    create tokens out of matrix
	 */          select(R[.,4], R[.,1] :== st_local("country"))', /*  select name
	 */          " "))                          // separator (second term in )
	
	local name: list uniq name // in case of more than one survey 
	
	use `cy', clear

	keep if country=="`country'"
	 
	graph twoway ///
		(line newvard newvarx, lcolor(black) lpattern(dash)) ///
		(line cum_mean_`asset' ln_welfare, lcolor(black)), ///
		by(year, title("Access to `asset' and Household Expenditure Level in `name'", size(medium))) ///
		xline(`=scalar(pline_190)' `=scalar(pline_320)' `=scalar(pline_550)', lwidth(vthin) lcol(red)) /// 
		xlabel(`=scalar(pline_190)' "1.90" `=scalar(pline_320)' "3.20" `=scalar(pline_550)' "5.50", labsize(vsmall)) ///
		ytitle("Fraction of households with `asset'") ///
		ylabel(, nogrid) ///
		xtitle("Daily expenditure per person in 2011 USD (PPP) (ln scale)") ///
		scheme(s1color)
	
	graph export `country'.png, replace

}

* Graph latest by country

use `cy', clear

keep if country=="AFG" & year==2011 | country=="BGD" & year==2016 | country=="BTN" & year==2017 | country=="IND" & year==2011 | country=="MDV" & year==2016 | country=="NPL" & year==2010 | country=="PAK" & year==2013 | country=="LKA" & year==2016

tostring year, replace
gen country_year=country + " " + year
replace country_year="Afghanistan 2011" if country_year=="AFG 2011"
replace country_year="Bangladesh 2016" if country_year=="BGD 2016"
replace country_year="Bhutan 2017" if country_year=="BTN 2017"
replace country_year="India 2011" if country_year=="IND 2011"
replace country_year="Sri Lanka 2016" if country_year=="LKA 2016"
replace country_year="Maldives 2016" if country_year=="MDV 2016"
replace country_year="Nepal 2010" if country_year=="NPL 2010"
replace country_year="Pakistan 2013" if country_year=="PAK 2013"

foreach asset of local assets{

	graph twoway ///
		(line newvard newvarx, lcolor(black) lpattern(dash)) ///
		(line cum_mean_`asset' ln_welfare, lcolor(black)), ///
		by(country_year, cols(4) title("Access to `asset' and household expenditure levels in South Asia", size(medium))) ///
		xline(`=scalar(pline_190)' `=scalar(pline_320)' `=scalar(pline_550)', lwidth(vthin) lcol(red)) /// 
		xlabel(`=scalar(pline_190)' "1.90" `=scalar(pline_320)' "3.20" `=scalar(pline_550)' "5.50", labsize(vsmall) angle(vertical)) ///
		ytitle("Fraction of households with `asset'") ///
		ylabel(, nogrid) ///
		xtitle("Daily expenditure per person in 2011 USD (PPP) (ln scale)") ///
		scheme(s1color)
	
	graph export sar_latest_`asset'.png, replace
}
