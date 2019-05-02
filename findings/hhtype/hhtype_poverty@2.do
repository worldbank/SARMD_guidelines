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
bys country: egen myr=max(years)
keep if years==myr
contract country years survname 
ds



gen id=country+"_"+strofreal(years)
/*
        BTN |          1       10.00       30.00
        IND |          3       30.00       60.00
        LKA |          1       10.00       70.00
        MDV |          1       10.00       80.00
        NPL |          1       10.00       90.00
        PAK |          1       10.00      100.00
		*/

local varlist "`r(varlist)'"
di in red "`r(varlist)'"

qui su years
loc y1 `r(min)'
loc y2 `r(max)'



*---------- Evaluate initical conditions
*countries
if ("`countries'" == "") {
	levelsof country, local(countries)
}
	levelsof id, local(ids)
*---------- Export to MATA
*mata: R = st_sdata(.,tokens(st_local("varlist")))
/*
*---------- Loop over countries
drop _all
tempfile cy // countries and years
save `cy', emptyok 
*/
glo path "C:\Users\WB502818\Documents\SARMD_guidelines\findings\hhtype"
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
	if ("`country'" == "IND") {
		local surveyid "IND_2011_NSS68-SCH10"
		local year "2011"
	}
	else local surveyid ""
		*di in red "`country'" "`surveyid'"
		*ssssssssss

		*di in red "`country'" "`year'"
		*ssssssssss
		*cap {*/
			datalibweb, countr(`country') year(`year') type(SARMD) clear surveyid(`surveyid')
			*RENAME VARIABLE NAMES
			
			cap rename welfare_v2 welfare
			cap ren welfareother welfare
			cap rename cpi_v2 cpi
			cap rename ppp_v2 ppp
			cap confirm var welfare 
			if _rc==0 {
			*HOUSHOLD COMPOSITION

			*One-person hh
			bys countrycode year idh idp: gen onep=(hsize==1)

			*Couple only hh
			*bys countrycode year idh : gen coup=((gmarital==101|gmarital==103|gmarital==201|gmarital==203)&hsize==2)
			bys countrycode year idh : gen coup_=(relationharm<=2&hsize==2)
			bys countrycode year idh : egen coup_s=total(coup_)
			gen coup=(hsize==coup_s)
			*br countrycode year idh gmarital hsize relationharm coup age  

			*Couple only with children
			**Find hh with couple
			bys countrycode year idh : gen coupch_1=(relationharm<=2)
			bys countrycode year idh : egen coupch_s1=total(coupch_1)

			**Find hh with couple and children
			bys countrycode year idh : gen coupch_=(relationharm<=3)
			bys countrycode year idh : egen coupch_s=total(coupch_)
			gen coupch=(hsize==coupch_s& hsize>=3& coupch_s1==2)
			cap drop coupch_ coupch_s coupch_1 coupch_s1
			set trace off
		    if (countrycode=="BGD"|countrycode=="AFG") {
				gen ch_gr=(relationcs==5&relationharm==3)
				bys countrycode year idh : egen grp_gh_=max(ch_gr)
				gen grp_gh=(coupch==1&grp_gh_==1)
				drop ch_gr grp_gh_
				}

		    if (countrycode=="IND") {
				gen ch_gr=(relationcs==6&relationharm==3)
				bys countrycode year idh : egen grp_gh_=max(ch_gr)
				gen grp_gh=(coupch==1&grp_gh_==1)
				drop ch_gr grp_gh_
				}
		    if (countrycode=="BTN") {
				gen ch_gr=((relationcs==7&relationharm==3)|(relationcs==6&relationharm==1))
				bys countrycode year idh : egen grp_gh_=max(ch_gr)
				gen grp_gh=(coupch==1&grp_gh_==1)
				drop ch_gr grp_gh_
				}
		    if (countrycode=="PAK") {
				gen ch_gr=((relationcs==4&relationharm==3)|(relationcs==11&relationharm==1))
				bys countrycode year idh : egen grp_gh_=max(ch_gr)
				gen grp_gh=(coupch==1&grp_gh_==1)
				drop ch_gr grp_gh_
				}
		    if (countrycode=="MDV") {
				gen ch_gr=(relationcs==11&relationharm==3)
				bys countrycode year idh : egen grp_gh_=max(ch_gr)
				gen grp_gh=(coupch==1&grp_gh_==1)
				drop ch_gr grp_gh_
				}
		    if (countrycode=="NPL") {
				gen ch_gr=(relationcs==8&relationharm==3)
				bys countrycode year idh : egen grp_gh_=max(ch_gr)
				gen grp_gh=(coupch==1&grp_gh_==1)
				drop ch_gr grp_gh_
				}


			*br countrycode year idh relationharm age

			gen ch_18_=(relationharm==3&age<18)
			bys countrycode year idh : egen ch_18=max(ch_18_) 
			*bys countrycode year idh : egen ch_l=min(age) 
			gen coupch_18=(ch_18==1&coupch==1)

			gen ch_=age if relationharm==3
			replace ch_=0 if ch_==.
			bys countrycode year idh: egen mch_=max(ch_) 

			gen coupch_15=(mch_<15&coupch==1)
			cap drop ch_ coupch_15_
			*drop par_chld_ par_chld spar_chld

			*SINGLE PARENTS
			**find single parent
			gen spar_=(relationharm<3)
			bys countrycode year idh : egen spar_s=total(spar_)
			gen spar=(spar_s==1)
			**find single parent with children
			gen sparch_=(relationharm<=3&spar==1)
			bys countrycode year idh : egen sparch_s=total(sparch_)
			gen sparch=(hsize==sparch_s& hsize>=2)
			replace sparch=0 if coupch==1 |coup==1
			drop spar_ spar_s spar sparch_ sparch_s

			*SINGLE PARENTS - FATHER
			clonevar msparch=sparch
			replace msparch=0 if sparch==1&relationharm<3&male==0
			bys countrycode year idh : egen msparch_m=min(msparch)
			replace msparch=0 if msparch_m==0

			*SINGLE PARENTS - MOTHER
			gen fhead_=(male==0& relationharm==1)
			bys countrycode year idh :egen fhead_m=max(fhead_)
			gen fsparch=(sparch==1&fhead_m==1)
			drop fhead_m fhead_

			* Non-relative 
			gen rel6=(relationharm==6)
			gen norel_=(relationharm==.)
			bys countrycode year idh : egen rel5_m=max(relationharm)
			bys countrycode year idh : egen rel6_m=max(rel6)
			gen nrel=rel6_m
			replace nrel=0 if onep==1|coup==1|coupch==1|sparch==1|norel==1
			drop  rel6_m rel5_m
			
			* Extended Family households 
			bys countrycode year idh : egen rel5_m=max(relationharm)
			bys countrycode year idh : egen rel6_m=max(rel6)
			bys countrycode year idh : egen norel=max(norel_)
			gen extf=(rel5_m<=5)
			replace extf=0 if onep==1|coup==1|coupch==1|sparch==1
			replace extf=0 if extf==1&(rel6_m==1|norel==1)

			*Single mother age (collapse shoudl be done for max)
			gen fsparch0_17_=(fsparch==1&age<=17&relationharm<3&male==0)
			gen fsparch18_24_=(fsparch==1&age>=18&age<=24&relationharm<3&male==0)
			gen fsparch25_34_=(fsparch==1&age>=25&age<=34&relationharm<3&male==0)
			gen fsparch35_54_=(fsparch==1&age>=35&age<=54&relationharm<3&male==0)
			gen fsparch55p_=(fsparch==1&age>=55&age!=.&relationharm<3&male==0)
			foreach v in 0_17 18_24 25_34 35_54 55p {
			bys idh: egen fsparch`v'=max(fsparch`v'_)
			}
			* grand parents and grand children 
			
			
			gen byte hhtype = 0
			local i 1
			foreach v of varlist onep coup coupch fsparch nrel extf norel {
			   replace hhtype =`i' if (`v' ==1)
			   local ++i
			}


			label var hhtype "HH composition for poverty"
			label define hhtype 1 "one person" 2 "couple" 3 "couple & children" 4 "single mothers" 5 "three generation" 6 "extended family" 7 "non relevant"
			label value hhtype hhtype	
		
			gen byte hhtype_chld = 0
			local i 1
			foreach v of varlist coupch msparch fsparch nrel extf norel {
			   replace hhtype_chld =`i' if (`v' ==1)
			   local ++i
			}
			
			*egen hhtype_chld = group(coupch msparch fsparch nrel extf norel )
			label var hhtype_chld "HH composition for child poverty"
			label define hhtype_chld 1 "couple and children only" 2 "single father" 3 "single mother" 4 "three generation" 5 "extended family" 6 "non relevant", modify
			label value hhtype_chld hhtype_chld 	
			gen young=(age<=9&relationharm==3)
			
			loc fsparhlist fsparch0_17 fsparch18_24 fsparch25_34 fsparch35_54 fsparch55p
			gen byte hhtype_fsparch = 0
			local i 1
			foreach v of varlist  fsparch0_17 fsparch18_24 fsparch25_34 fsparch35_54 fsparch55p {
			   replace hhtype_fsparch  =`i' if (`v' ==1)
			   local ++i
			}
			*GENERATE POVERTY QUINTILE
			quantiles welfare [aw=wgt], gen(q) n(5)
			quantiles welfare [aw=wgt], gen(p) n(10)
			*xtile q_test = welfare [aw=wgt], nq(5)
			ta q, gen(q)
			*gen b20=(q==1)
			set trace off
			levelsof countrycode, loc(c)	
			levelsof year, loc(y)	
			graph bar welfare if hhtype>0 , ///
			over(hhtype) name(`country', replace) ytitle("Mean of Total Consumption Per Capita") subtitle("`c'_`y'")	///
			legend(pos(6) col(1))  subtitle("`country' `year'", size(medium)) blabel(total, format(%9.1f)) 

			levelsof countrycode, loc(c)
			graph export "${path}/`country'.png", replace	
			
		/*
			qui mlogit hhtype i.p age i.male i.educat4 i.urban hsize if hhtype>=3&hhtype<=6
			qui margins i.p , atmeans predict(outcome(3))
			qui marginsplot, name(coup, replace) 
			qui margins i.p , atmeans predict(outcome(4))
			qui marginsplot, name(sparent, replace) 
			qui margins i.p , atmeans predict(outcome(5))
			qui marginsplot, name(threegen, replace) 
			qui margins i.p , atmeans predict(outcome(6))
			qui marginsplot, name(extf, replace)
			graph combine coup sparent threegen extf, title("Household Composition by Percentile", size(medium)) subtitle("`country' `year'", size(medium)) 
							
			graph export "${path}/`country'_`year'.png", replace			
			*s
	*/		
			qui mlogit q1 i.hhtype age i.male i.educat4 i.urban hsize if hhtype>=3&hhtype<=6
			qui margins i.hhtype  , atmeans predict(outcome(1))
			qui marginsplot, name(`country'_`year', replace) ytitle("Probability of Being Poor") subtitle("`country' `year'", size(medium)) legend(pos(6) col(1)) 
			*qui margins i.hhtype  , atmeans predict(outcome(0))
			*qui marginsplot, name(sparent, replace) 


			
		
		if (_rc) {
			noi disp in red "Error on `country' `year'"
		}
		else {
			noi disp in y "`country' `year' Done."
		}

	}

	}



grc1leg  BGD BTN IND  MDV PAK, ycommon title("Probabilty of Being Poor by HH Types")  
graph export "${path}/all.png", replace	

			*graph combine AFG BGD	BTN	IND	LKA	MDV	NPL	PAK, xlabel(, size(v.small))	title("Probabilty of Being Poor by HH Types", size(medium)) 
			*graph export "${path}/poor_hhtype.png", replace		 
	
grc1leg  BGD_2016 BTN_2017 IND_2011  MDV_2016  PAK_2015,  ytitle("Probability of Being Poor") title("Probabilty of Being Poor by HH Types")  
graph export "${path}/poor_hhtype.png", replace	
