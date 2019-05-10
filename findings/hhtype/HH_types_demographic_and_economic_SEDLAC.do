
**********************************
* Economic Composition of the HH
**********************************

sort id

* Earner (employed as proxy)
gen earner = (ila > 0 & ila <.)
by id: egen n_earnhh = total(earner)
label var n_earnhh "number of earners in HH"

* single  and multiple earners
sum n_earnhh, meanonly
local earnmax = r(max)
recode n_earnhh (0 = 0 "No earners") (1 = 1 "Single earners") ///
(2/`earnmax' = 2 "Multiple earners"), gen(earnhh)
label var earnhh "HH earner definition"

tab earnhh
* Dependent 
gen dependent = (ila == 0 | ila  == .)

* household with and w/0 dependents

by id: egen wdepent = max(dependent)
replace wdepent = 2 if n_earnhh == 0
label var wdepent  "Household with or w/o dependents"
label define wdepent  0 "w/o dependets" 1 "with dependents" 2 " ", modify
label values wdepent wdepent 

tab wdepent, mis 

** gender for single earners  or couple or other for multiple earners
gen hhdivision = hombre if n_earnhh == 1
replace hhdivision = 2 if n_earnhh == 2
sum miembros, meanonly
replace hhdivision = 3 if inrange(n_earnhh, 3, r(max)) 
replace hhdivision = 4 if n_earnhh == 0

label define hhdivision  0 "female" 1 "male" 2 "head couple" ///
3 "other" 4 " ", modify
label values hhdivision  hhdivision  
label var hhdivision "gender of earners" 

**********************************
* Demographic Composition of the HH
**********************************
sum edad, meanonly
gen senior = inrange(edad, 65, r(max))  if edad < .
label var senior "Senior (65 y/old or more)"

gen nonsenior = inrange(edad, 18, 64) if edad < .
label var nonsenior "Non-senior adult (18-64 y/old)"

gen child = inrange(edad, 0, 17) if edad < .
label var child "Children (17 or younger)"

** Number of people of each group in each HH

sort id

foreach var in senior nonsenior child {
	by id: egen n_`var'hh = total(`var') if edad < .
	label var n_`var'hh "number of `var' in HH"
}

** Non-senior gender
by id: egen nonsensex = mean(hombre) ///
if inrange(n_nonseniorhh, 1, .) & edad < .
recode nonsensex (0.01/0.99 = 2)  if edad < .
replace nonsensex = 3 if nonsensex == .  & edad < .
label var nonsensex "Non-seniors gender within HH"

label define nonsensex 0 "Only female" ///
1 "Only male" ///
2 "Both female and male" ///
3 " ", modify
label value nonsensex nonsensex 

** Composition of househodl by age: agecomp
gen agecomp  = . 
replace agecomp = 0 if inrange(n_nonseniorhh, 1, .) 
replace agecomp = 1 if inrange(n_seniorhh, 1, .) & n_nonseniorhh == 0
replace agecomp = 2 if inrange(n_childhh, 1, .)  & n_nonseniorhh == 0 & n_seniorhh == 0 

label define agecomp 0 "Non-senior adult" ///
1 "Only senior adults" 2 "Only children", modify
label values agecomp  agecomp 


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



