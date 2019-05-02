/*==================================================
Project:       Welfare Distribution and Access to Assets
Author:        Javier Parada and Andres Castaneda 
Dependencies:  The World Bank
----------------------------------------------------
Creation Date:    	10 April 2019
Modification Date:  30 April 2019
Do-file version:    01
References:         
Output:             access_to_assets.dta :)
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

cd "${hostdrive}\SOUTH ASIA MICRO DATABASE\05.projects_requ\01.SARMD_Guidelines\02. qcheck\02. sar qcheck\09. shareable do-files\Javier_Note2_Final\"

local assets = "bicycle cellphone computer electricity everattend fan landphone literacy motorcar motorcycle ownhouse piped_water radio refrigerator sewage_toilet sewingmachine television washingmachine"
local reponame  "sarmd"
local countries ""
local years     ""
local surveys   ""

local iff "if newvarx>=0 & newvarx<=4"
local iff2 "if ln_welfare>=0 & ln_welfare<=4"

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
	
		
				
				
			datalibweb, country(`country') year(`year') type(SARMD) surveyid(`surveyid') clear 
			
			cap{
			* Fix v2
			cap rename welfare_v2 welfare
			cap rename cpi_v2 cpi
			cap rename ppp_v2 ppp
			
			* Generate household density by per capita expenditures
			gen ln_welfare=ln(welfare/ppp/cpi/365*12)
            
			scalar pline_190=ln(1.90)
			scalar pline_320=ln(3.20)
			scalar pline_550=ln(5.50)
			scalar list
			gen poor_190=ln_welfare<pline_190 if welfare!=.
			gen poor_320=ln_welfare<pline_320 if welfare!=.
			gen poor_550=ln_welfare<pline_550 if welfare!=.
			noi disp in blue "`country' `year' `surveyid' Headcounts:."
			noi sum poor* [aw=wgt]

			sort ln_welfare
			kdensity ln_welfare [aw = wgt], gen(newvarx newvard) normal
			label var newvard "Household density"
			
			sum ln_welfare newvard newvarx
			preserve
			keep ln_welfare newvard newvarx
			drop if newvarx==.
			replace ln_welfare=newvarx
			gen country = "`country'"
			gen year    = "`year'"
			append using `cy'
			save `cy', replace 
			
			restore
						
			* Generate cumulative percentages for access to assets
			foreach asset of local assets{
				cap gen cum_mean_`asset'=.
				cap replace cum_mean_`asset' = sum(`asset'*wgt)/sum(wgt) if `asset' < . 
			}
						
			* Label new variables
			cap label var cum_mean_bicycle		"Bicycle"
			cap label var cum_mean_cellphone	"Cellphone"
			cap label var cum_mean_computer		"Computer"
			cap label var cum_mean_electricity	"Electricity"
			cap label var cum_mean_everattend	"Ever attend school"
			cap label var cum_mean_fan			"Fan"
			cap label var cum_mean_landphone	"Land phone"
			cap label var cum_mean_literacy		"Literacy"
			cap label var cum_mean_motorcar		"Motorcar"
			cap label var cum_mean_motorcycle	"Motorcycle"
			cap label var cum_mean_ownhouse 	"Own house"
			cap label var cum_mean_piped_water 	"Piped water"
			cap label var cum_mean_radio 		"Radio"
			cap label var cum_mean_refrigerator "Refrigerator"
			cap label var cum_mean_sewage_toilet "Sewage toilet"
			cap label var cum_mean_sewingmachine "Sewing machine"
			cap label var cum_mean_television 	"Television"
			cap label var cum_mean_washingmachine	"Washing machine"
			
			/*
			local asset "refrigerator"

			
			* Graph
			graph twoway ///
				(line newvard newvarx `iff', lcolor(black) lpattern(dash)) ///
				(line cum_mean_`asset' ln_welfare `iff2', lcolor(black)), ///
				xline(`=scalar(pline_190)' `=scalar(pline_320)' `=scalar(pline_550)', lwidth(vthin) lcol(red)) /// 
				xlabel(`=scalar(pline_190)' "1.90" `=scalar(pline_320)' "3.20" `=scalar(pline_550)' "5.50") ///
				ytitle("Fraction of households with `asset'") ///
				xtitle("Daily expenditure per person in 2011 USD (PPP) (ln scale)") ///
				title("Access to `asset' and Household Expenditure Level", size(medium)) ///
				subtitle("`country' `year'", size(medium)) ///
							
			graph export `country'_`year'.png, replace
			*/
			sum year
			scalar N_obs=round(r(N)/100)
			noi display N_obs
			gen count=_n
			drop if mod(count,N_obs) > 0
			
			keep ln_welfare cum_mean_*
			gen country = "`country'"
			gen year    = "`year'"
			drop if ln_welfare==.
			reshape long cum_mean_, i(country year ln_welfare) j(asset) string
			sort asset ln_welfare
			append using `cy'
			save `cy', replace 
			
			
			
			
	
		
		graph twoway ///
				(line newvard ln_welfare `iff', lcolor(black) lpattern(dash)) ///
				(line cum_mean_`asset' ln_welfare `iff2', lcolor(black))
				
		}
		
		if (_rc) {
			noi disp in red "Error on `country' `year' `surveyid'"
		}
		else {
			noi disp in y "`country' `year' `surveyid' Done."
		}

	}
}

use `cy', clear
tostring year, replace
gen country_year=country+" "+year
gen exp_perc=exp(ln_welfare)
order country year country_year newvard newvarx ln_welfare cum_mean_*


save "access_to_assets.dta", replace
export excel using "access_to_assets.xls", firstrow(variables) replace


x

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
		(line newvard newvarx `iff', lcolor(black) lpattern(dash)) ///
		(line cum_mean_`asset' ln_welfare `iff2', lcolor(black)), ///
		by(year, style(compact) title("Access to `asset' and Household Expenditure Level in `name'", size(medium))) ///
		xline(`=scalar(pline_190)' `=scalar(pline_320)' `=scalar(pline_550)', lwidth(vthin) lcol(red)) /// 
		xlabel(`=scalar(pline_190)' "1.90" `=scalar(pline_320)' "3.20" `=scalar(pline_550)' "5.50", labsize(vsmall)) ///
		ytitle("Fraction of households with `asset'") ///
		ylabel(, nogrid) ///
		xtitle("Daily expenditure per person in 2011 USD (PPP) (ln scale)") 
	
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

local assets = "bicycle cellphone computer electricity everattend fan landphone literacy motorcar motorcycle ownhouse piped_water radio refrigerator sewage_toilet sewingmachine television washingmachine"

foreach asset of local assets{

	graph twoway ///
		(line newvard newvarx `iff', lcolor(black) lpattern(dash) lwidth(thin)) ///
		(line cum_mean_`asset' ln_welfare `iff2', lcolor(black) lpattern(solid) lwidth(thin)), ///
		by(country_year, cols(4) style(compact) title("Access to `asset' and household expenditure levels in South Asia", size(medium))) ///
		xline(`=scalar(pline_190)' `=scalar(pline_320)' `=scalar(pline_550)', lwidth(vthin) lcol("38 139 210") lpattern(solid)) /// 
		xlabel(`=scalar(pline_190)' "1.90" `=scalar(pline_320)' "3.20" `=scalar(pline_550)' "5.50", labsize(vsmall) angle(vertical)) ///
		ytitle("Fraction of households with `asset'") ///
		ylabel(, nogrid) ///
		xtitle("Daily expenditure per person in 2011 USD (PPP) (ln scale)") ///
		legend(row(1)) subtitle(,fcolor(white))
	
	graph export sar_latest_`asset'.png, replace
}
