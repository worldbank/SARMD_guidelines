* How to run regressions 
* Example

* Preamble
eststo clear

* Open data
datalibweb, country(BGD) year(2016) type(SARMD) mod(IND) vermast(01) veralt(03) surveyid(HIES)

* Describe survey characteristics
codebook idh idp psu strata
egen tag=tag(idh)
bysort psu: egen households_per_psu=sum(tag)
bysort strata: egen households_per_strata=sum(tag)
tab households_per_psu
tab households_per_strata

* Generate new variables
gen ln_welfare_perc=ln(welfare/ppp/cpi/365*12/1.90)
gen age_sq=age^2
local controls "age age_sq i.male hsize educy i.educat7 i.literacy i.marital i.urban i. electricity i.ownhouse i.subnatid1"

** Run regressions

* Without psu and strata
mean welfare ln_welfare_perc [aw=wgt]
sum welfare ln_welfare_perc `controls' if relationharm==1 [aw=pop_wgt]
eststo model1_a: reg ln_welfare_perc `controls' if relationharm==1 [aw=pop_wgt]
eststo model2_a: logit poor_int `controls' if relationharm==1 [pw=pop_wgt]

* With psu and strata (when possible)
svyset psu [pw=pop_wgt], strata(strata)
svy: mean welfare ln_welfare_perc if relationharm==1 
eststo model1_b: svy: reg ln_welfare_perc `controls' if relationharm==1
eststo model2_b: svy: logit poor_int `controls' if relationharm==1

* Present results			
esttab model1_a model1_b model2_a model2_b, se

* Multinomial Logit 
** Dependent var: Household Type
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
							
			*graph export "${path}/`country'_`year'.png", replace			
** Dependent var: Being poor
			qui mlogit q1 i.hhtype age i.male i.educat4 i.urban hsize if hhtype>=3&hhtype<=6
			qui margins i.hhtype  , atmeans predict(outcome(1))
			qui marginsplot, name(`country', replace) subtitle("`country' `year'", size(medium)) 
