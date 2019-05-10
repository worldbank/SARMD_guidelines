
clear all

datalibweb, country(IND) year(2011) type(SARRAW) surveyid(IND_2011_NSS68-SCH1.0-T1_v01_M) filename(NSS68_Sch1-T1_bk_4.dta)

**********************************
* Demographic Composition of the HH
**********************************

* Average age (B4_v05) is  28.76 years old
sum B4_v05, meanonly

* Generate Senior (>=65), Non-senior (18-64) )and Child (0-18)
gen senior = inrange(B4_v05, 65, r(max))  if B4_v05 < .
label var senior "Senior (65 years old or more)"

gen non_senior = inrange(B4_v05, 18, 64) if B4_v05 < .
label var non_senior "Non-senior adult (18-64 years old)"

gen child = inrange(B4_v05, 0, 17) if B4_v05 < .
label var child "Children (17 or younger)"


** Number of people of each group in each HH
sort ID

foreach var in senior non_senior child {
	by ID: egen n_`var'hh = total(`var') if B4_v05 < .
	label var n_`var'hh "Number of `var' in household"
}

** Non-senior gender (B4_v04)
recode B4_v04 (2 = 0)  if B4_v05 < .
replace B4_v04=0 if B4_v04==2
by ID: egen nonsensex = mean(B4_v04) if inrange(n_non_seniorhh, 1, .) & B4_v05 < .
recode nonsensex (0.01/0.99 = 2)  if B4_v05 < .
replace nonsensex = 3 if nonsensex == .  & B4_v05 < .
label var nonsensex "Non-seniors gender within HH"

label define nonsensex 0 "Only female" 1 "Only male" 2 "Both female and male" 3 " ", modify
label value nonsensex nonsensex 


** Composition of household by age: agecomp
gen agecomp  = . 
replace agecomp = 0 if inrange(n_non_seniorhh, 1, .) 
replace agecomp = 1 if inrange(n_seniorhh, 1, .) & n_non_seniorhh == 0
replace agecomp = 2 if inrange(n_childhh, 1, .)  & n_non_seniorhh == 0 & n_seniorhh == 0 

label define agecomp 0 "Non-senior adult" 1 "Only senior adults" 2 "Only children", modify
label values agecomp  agecomp 


xxxx











* economic composition 
sort earnhh hhdivision wdepent
cap label drop ecocomp
egen ecocomp = group(earnhh hhdivision wdepent) ,  lname(ecocomp)  
label var ecocomp "Economic composition of HH"

** with children
gen wchild = n_childhh>0 & n_childhh <. & age < .  
replace wchild = 2 if agecomp == 2 
label define wchild  0 "without children" 1 "whith children" 2 " ", modify
label values wchild  wchild  

** demographic decompositioin
sort agecomp nonsensex wchild
cap label drop demcomp
egen demcomp = group(agecomp nonsensex wchild),  lname(demcomp)
label var demcomp "Demographic composition of HH"



