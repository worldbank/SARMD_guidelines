/*==================================================
project:       Create dataset with information of 
               variable derivation for all SARMD 
							 collection
Author:        R.Andrés Castañeda 
Dependencies:  The World Bank
----------------------------------------------------
Creation Date:    19 Jun 2019 - 15:08:51
Modification Date:   
Do-file version:    01
References:          
Output:             
==================================================*/

/*==================================================
                        0: Program set up
==================================================*/
version 15.1
drop _all

global var_der_dir "c:\Users\wb384996\OneDrive - WBG\SARTSD\SARMD_guidelines\findings\variable_derivation"

/*==================================================
           Dependencies
==================================================*/

if ("${sarmd_cmds_ssc}" == "") {
  * list of commands avialble in SSC 
  local cmds do2screen
  
  * Check whether the command is installed.
  foreach cmd of local cmds {
    capture which `cmd'
    if (_rc != 0) ssc install `cmd' // isntall if not in local computer
  }
  
  adoupdate `cmds', ssconly   // check if commands are up to date
  if ("`r(pkglist)'" != "") adoupdate `r(pkglist)', update ssconly // those that are not. 
  global sarmd_cmds_ssc = 1  // make sure it does not execute again per session
}



/*==================================================
           1: Find out all do-files
==================================================*/

*----------1.1: define small mata function
mata:
	mata clear
	y = J(0,1, "")
	void _dopaths(string colvector y) {
		if (rows(y) == 0) {
			y = st_local("dopath")
		}
		else {
			y = y \ st_local("dopath")				
		}
	}
	
	void _getdopath(string colvector y) {
		i = strtoreal(st_local("i"))
		st_local("dopath", y[i]) 
	} // end of IDs variables
end

*----------1.2: Identify do-files
local dirtest ""
local dodir "//Wbgmsbdat001/south asia micro database/SAR_DATABANK`dirtest'"

local dirs: dir "`dodir'" dir "*"


gettoken dir dirs : dirs
while ("`dir'" != "")  {
	if regexm("`dir'", "^\.git|^_")  {
		gettoken dir dirs : dirs
		continue
	}
	
	// Check if we are in the right folder
	
	local dos: dir "`dodir'/`dir'" files "*sarmd.do"
	
	*  save do-files path
	if (`"`dos'"' != `""') {
		foreach do of local dos {
			local dopath = "`dodir'/`dir'/`do'"
			mata: _dopaths(y)
		}
	}
	
	 */ 
	local subdirs: dir "`dodir'/`dir'" dir "*"
	
	if (`"`subdirs'"' != "") {
		foreach subdir of local subdirs {
			if regexm("`subdir'", "^\.git|^_") continue
			local dirs `"`dirs' "`dir'/`subdir'" "'
		}		
	}
	gettoken dir dirs : dirs
	disp "." _c
}



/*==================================================
       2: Create file with all informaiton
==================================================*/

*----------2.1: import variable names

import delimited using "${var_der_dir}/sarmd_vars.csv", clear /* 
 */ varnames(1) encoding("utf-8") 

levelsof vars, local(vars)

*----------2.2: Create empty dataset
drop _all
mata: st_local("nrows", strofreal(rows(y)))
local nvars: word count `vars'
set obs `=`nrows'*`nvars''

gen str60 dofile = ""
gen str60 var    = ""
gen strL  code   = ""


*----------2.3: store results
local n = 0
local mod = 10
qui foreach i of numlist 1/`nrows' {
	mata: _getdopath(y)   // dofile path
	if regexm("`dopath'", "(.*)/(.*\.do$)") { // do-file name
		local dofile = regexs(2)
	}
	foreach var of local vars {
		local ++n
		cap do2screen using "`dopath'", var(`var') nolinenumbers
		if (_rc) scalar  s_varcode = "err"
		
		// complete file
		replace dofile = "`dofile'" in `n'
		replace var = "`var'" in `n'
		replace code = s_varcode in `n'
		if (mod(`n', 10) == 0 ) {
			noi disp "`mod'" _c
			local mod = `mod' + 10
		} 
		else {
			noi disp "." _c 
		}
		
	}
}

compress
save tempfile, replace // 
*##s
use tempfile, clear


/*==================================================
           3: rearrange file and export
==================================================*/

*----------3.1:rename and split
rename dofile id
replace id = subinstr(id, ".do","",.)
replace id = regexs(1) + "-" + regexs(2) if /* 
 */ regexm(id, "([a-z]+_[0-9]+_[a-z]+)_([a-z0-9]+_v[0-9]+.*)")


split id, parse(_) gen(sec)
rename (sec1 sec2 sec3 sec4 sec6) ///
			(countrycode year survey vermast veralt)

drop sec*
replace countrycode = upper(countrycode)
destring year, force replace
replace survey = upper(survey)
order id country year survey ver* var code

*----------3.2: later variable
replace vermast = subinstr(vermast, "v", "", .)
replace veralt  = subinstr(veralt, "v", "", .)

destring vermast veralt, replace force 

bysort countrycode year survey: egen mmax = max(vermast)
bysort countrycode year survey: egen amax = max(veralt) if vermast == 1
keep if (mmax == vermast & amax == veralt)
drop mmax amax

tostring vermast veralt, replace force


*---------- fix trailing code
 
replace code = ustrtrim(code)
replace code = subinstr(code, "`=char(10)'`=char(13)' ", "`=char(10)'`=char(13)'", .)
replace code = subinstr(code, "`=char(10)'", "", .)
 
*----------3.3: export 
compress
save "${var_der_dir}/sarmd_vars_derivation.dta", replace
export delimited "${var_der_dir}/sarmd_vars_derivation.csv", replace quote
*##e







exit
/* End of do-file */

><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><

Notes:
1.
2.
3.


Version Control:

