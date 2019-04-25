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
