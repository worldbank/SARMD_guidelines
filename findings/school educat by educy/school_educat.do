/*==================================================
Project:       School categories in SAR using SARMD
Author:        Javier Parada and Andres Castaneda 
Dependencies:  The World Bank
----------------------------------------------------
Creation Date:    	3 April 2019 
Modification Date:  3 April 2019
Do-file version:    01
References:         
Output:             Dashboard_educat.xls
==================================================*/


/*==================================================
           Alternative version 2
==================================================*/

cd "D:\SOUTH ASIA MICRO DATABASE\05.projects_requ\01.SARMD_Guidelines\02. qcheck\02. sar qcheck\08. new notes\02. educat7\"

local reponame  "sarmd"
local countries ""
local years     ""
local surveys   ""



*---------- Get repo
datalibweb, repo(create `reponame', force) type(SARMD)
contract country years survname 
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
			tempfile dlw 
			save `dlw'
					
			foreach educat in educat7 educat5 educat4{
				
				use `dlw', clear
				*graph bar (count), percentages over(educat7) over(educy) missing asyvars stack legend(cols(2) size(vsmall)) title(educat7 over educy in `country' `year') 
				*graph export G1`country'`year'.pdf
			
				*graph bar (count), over(educat7) over(educy) missing asyvars stack legend(cols(2) size(vsmall)) title(educat7 over educy in `country' `year') 
				*graph export G2`country'`year'.pdf
			
				collapse (count) year, by(`educat' educy male)
				cap rename educy_v2 educy
				cap rename `educat'_v2 `educat'
				rename year freq
				decode `educat', gen(educ_categories)
				drop `educat'
				merge m:1 educy using "educy.dta"
					
				gen country = "`country'"
				gen year    = `year'
				gen var = "`educat'"
					
				append using `cy'
				save `cy', replace 
			
				
			
			}
		
		
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

/*==================================================
           fix Data
==================================================*/

*rename (_margin _m1 _m2 _m3) (atsch age male urban)
label var country "Country"
label var year "Year"
gen ctryear = country + " - " + strofreal(year)
order country year ctryear educy educ_* freq
label var ctryear "Country Year"

replace freq = 0 if freq==.

bysort country: egen last = max(year) // max year
replace last = (last == year)




* Here your can save the data already clean
export excel using "Dashboard_educat.xls",  firstrow(variables) replace 

/*==================================================
      Types of graphs (you can do many more)
==================================================*/


*---------- Last year of each country
twoway (line atsch age if male == . & urban==., lpattern(l))  /* 
 */    (line atsch age if male == 1 & urban==., lpattern(l))  /* 
 */    (line atsch age if male == 0 & urban==., lpattern(l))  /* 
 */     if my == 1,                                           /* 
 */     legend(order(1 "Total" 2 "Male" 3 "Female" )          /* 
 */          position(6) rows(1))                             /* 
 */     by(ctryear, title("School Attendance by gender in"    /* 
 */                       "latest year available"))           /* 
 */     note("")

 
*---------- By year in one country

local country "BTN"

twoway (line atsch age if male == . & urban==., lpattern(l))  /* 
 */    (line atsch age if male == . & urban==1, lpattern(l))  /* 
 */    (line atsch age if male == . & urban==0, lpattern(l))  /* 
 */     if country == "`country'",                            /* 
 */     legend(order(1 "Total" 2 "Urban" 3 "Rural" )          /* 
 */          position(6) rows(1))                             /* 
 */     by(year, title("School Attendance by Urban/rural in"       /* 
 */                       "latest year available"))          


exit 
/* End of do-file */

><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><

Notes:
1.
2.
3.


Version Control:

 

