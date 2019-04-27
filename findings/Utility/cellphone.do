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
*---------- Export to MATA
*mata: R = st_sdata(.,tokens(st_local("varlist")))

*---------- Loop over countries
drop _all
tempfile cy // countries and years
save `cy', emptyok 

glo path "C:\Users\WB502818\Documents\SARMD_guidelines\findings\Utility"
set trace off

qui foreach id of local ids {
		tokenize `id', parse("_")
		local country = "`1'"
		*noi di in yellow "`vermast_p'";
		local year = "`3'"	
	
	/*mata: st_local("years",    /*   set local years 
	 */           invtokens(   /*    create tokens out of matrix
	 */          select(R[.,2], R[.,1] :== st_local("country"))', /*  select years
	 */            " "))     // separator (second temr in )
	*di in red "`years'"
	local years: list uniq years // in case of more than one survey 
	*/
	if ("`country'" == "IND" & `year'==2011) {
		local surveyid "IND_2011_NSS68-SCH10"
		*local year "2011"
	}
	else local surveyid ""
	cap {
			datalibweb, countr(`country') year(`year') type(SARMD) clear surveyid(`surveyid')
			*RENAME VARIABLE NAMES
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
			gen cell=`r(mean)'
			su electricity if q==1 [aw=wgt]
			gen elect=`r(mean)'
			su cellnoelect if q==1 [aw=wgt]
			gen cellnoel=`r(mean)'
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
	over( year) name("`c'", replace) title("Access to Cell Phone & Electricity among Poor")  subtitle("`c'")	///
	bar(1, color(blue)) bar(2, color(orange))  bar(3, color(green))	///
	legend(order(ring(0) position(8) 1 "Cell Phone" 2 "Electricity" 3 "Cell Phone w/o Electricity"))


	graph export "${path}/`c'.png", replace	
	}

	grc1leg  `countiries',  ///
	title("Access to Cell Phone & Electricity among Poor")  subtitle("`c'")	///
	bar(1, color(blue)) bar(2, color(orange))  bar(3, color(green))	///
	legend(order(1 "Cell Phone" 2 "Electricity" 3 "Cell Phone w/o Electricity"))
	graph export "${path}/all.png", replace	 
