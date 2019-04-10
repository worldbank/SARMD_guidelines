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
			gen cum_mean_refrigerator = sum(refrigerator*wgt)/sum(wgt) if refrigerator < .
			gen cum_mean_electricity  = sum(electricity*wgt)/sum(wgt) if electricity < .

			* Label new variables
			label var cum_mean_refrigerator "Refrigerator"
			label var cum_mean_electricity "Electricity"

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
				title("Refrigerator Ownership and Household Expenditure Level", size(medium)) ///
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


foreach country of local countries{

	mata: st_local("name",                   /*   set local years 
	 */          invtokens(                   /*    create tokens out of matrix
	 */          select(R[.,4], R[.,1] :== st_local("country"))', /*  select years
	 */          " "))                          // separator (second term in )
	
	local name: list uniq name // in case of more than one survey 
	
	use `cy', clear

	keep if country=="`country'"

	graph twoway ///
		(line newvard newvarx, lcolor(black) lpattern(dash)) ///
		(line cum_mean_`asset' ln_welfare, lcolor(black)), ///
		by(year, title("Refrigerator Ownership and Household Expenditure Level in `name'", size(medium))) ///
		xline(`=scalar(pline_190)' `=scalar(pline_320)' `=scalar(pline_550)', lwidth(vthin) lcol(red)) /// 
		xlabel(`=scalar(pline_190)' "1.90" `=scalar(pline_320)' "3.20" `=scalar(pline_550)' "5.50", labsize(vsmall)) ///
		ytitle("Fraction of households with `asset'") ///
		ylabel(, nogrid) ///
		xtitle("Daily expenditure per person in 2011 USD (PPP) (ln scale)") ///
		scheme(s1color)
	
	graph export `country'.png, replace

}
