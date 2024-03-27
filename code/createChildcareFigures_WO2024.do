log using "LogWendyOlsenChildcareanalysis.smcl", replace
******  Code for creating big aggregate time variables for the manuscript Women’s Invisibilised Childcare Work: Indian Trends 2015-2021 by Wendy Olsen and Jihye Kim, for the Conference of Radical Statistics - London - Feb 2024
******  University of Manchester and held at github.com/WendyOlsen/  DIRECTORY TBC* See the github site for advice on how to cite this, 
*#          It is Creative Commons licensed.
******  Data is Indian Time Use Survey (ITUS) microdata 2019 (NSS, 2020) Available at: *https://mospi.gov.in/web/mospi/download-tables-data/-/reports/view/templateTwo/20702?q=TBDCAT. Accessed Sept. 15, 2022.
               *    *    *   Stage 3 
* 2020, updated in 2023 and 2024. 

*This file is related to our publication as shown, which you must cite! creative commons copyright.
* Women’s Invisibilised Childcare Work: Indian Trends 2015-2021 
*  by      Wendy Olsen, Sonny McCann (TBC) and Kim, Jihye, (2024), submitted to Radical Statistics, Creative Commons Open access.  Feb 2024.

* This  stage assumes you cleaned and merged the raw text files from MOSPI for India Time-Use survey of 2019, and created 2-digit and 1-digit time-use variables at the personal level.  N

******  

clear
cd "C:\data\ITUS"
use "data\IndiaITUSChildcareTimeuse.dta", clear
 
* OBJECTIVES: 
*6 descriptives.  Match in the data from another data source, via exact matching in groups.
*Use adult data only. 
*Group formation     Rural / age-group <=35 36-65, 65+ / Edu (nested; not all combos exist in sample) 2*3*5 = 25 groups.
            * notice - we are not including social group because we do not anticipate or allow for group-specific cultures in this paper. Children in household? becz not in other survey.
			*And not sex, because gender norms don't vary by sex.  But they do vary by education. Note, age-group is aproxy for some other child-rearing stages, so we use youth-35, 36-65, 65+. 

*7 graphics.
*8 regression.
gen rawgender=gender
drop if rawgender==3
drop if socialgroup2==.
*Note we will have to drop 129 cases where gender was unknown, average age 37 years.- A range of ages.
drop gender
gen gender=female
label define fem 0 "Male" 1 "Female", modify
label values female fem
label values gender fem
tab edu, nol
tab edu
drop cooktime0 minichildcaretime0 allchildcaretime0 minitraveltime0
gen agegroup=0
replace agegroup=1 if age<36
replace agegroup=2 if age>35&age<66
replace agegroup=3 if age>65
tab agegroup
summ i.agegroup [fweight=fwt], detail
tab state
gen st=0
gen sc=0
gen other=0
gen muslim=0
*Note a conservative way of avoiding a vague border between obc and others.
replace muslim=1 if socialgroup2==4
replace other=1 if socialgroup2==0|socialgroup2==3
replace sc=1 if socialgroup2==2
replace st=1 if socialgroup2==1
*Use caution. Muslim was already defined carefully in socialgroup2 so use that.
label define sc 0 "Not SC" 1 "SC", modify
label define st 0 "Not SC" 1 "ST", modify
label define muslim 0 "Not Muslim" 1 "Muslim, Not SC Nor ST", modify
label define other 0 "Not Other" 1 "Others", modify
label values sc sc
label values st st
label values muslim muslim
label values other other
gen married=0
*note 1, currently married – 2, widowed – 3, divorced/separated – 4
replace married=1 if maritalstatus==2
label define marr 0 "Not Present Married" 1 "Married"
label values married marr
tab numchild agegroup, col
gen numchild2=numchild*numchild
gen numadult=hhsize-numchild
tab numadult

summ gender i.edu i.agegroup i.state i.socialgroup2 haschild hasteach hascompoccup hhsize numchild numchild2 numadult married


                  **** HERE AN IMPORTANT SAVE POINT.******************************
**re-save final, revised, well-labelled adult-ages-only data
save "data\IndiaITUSChildcareTimeuseAll.dta", replace

                 * divide and save adult, then children, versions.
*All those 16 and under are considered children. Drop them.
*Keep 17-18 year olds only if married, so that they might be doing adult work of cooking & childcare.
keep if age>17|(age>=16&age<18&maritalstatus==2)
save "data\ITUSChildcareTimeuseAdults.dta", replace
export delimited using "data\ITUSChildcareTimeuseAdults.csv", replace

use "data\IndiaITUSChildcareTimeuseAll.dta", clear
*make child-ages-only data
keep if age>=5 & age<=17
save "data\ITUSChildcareTimeuseChildren.dta", replace
export delimited using "data\ITUSChildcareTimeuseChildren.csv", replace

use  "data\ITUSChildcareTimeuseAdults.dta", clear

*Now do the descriptives and figures for adults.
sort rural agegroup edu
  merge m:1 rural agegroup edu using "C:\data\AsianBaro\data\AsBarGroupInfoGN.dta" , keepusing (gngroupmean gngroupsd wcountofgroup)
drop _merge

summ cooktime

tabstat cooktime minichildcaretime minitraveltime allchildcaretime [fweight=fwt], by(female)

tabstat cooktime minichildcaretime minitraveltime allchildcaretime [fweight=fwt] if haschild==1&hhsize>1, by(female) 
tab fwt
summ cooktime [fweight=fwt] if haschild==1&female==1
summ minichildcaretime [iweight=fwt] if haschild==1&female==1
summ cooktime [iweight=fwt] if haschild==1&female==1
summ allchildcaretime [iweight=fwt] if haschild==1&female==1
summ allchildcaretime if haschild==1&female==1
*finishing off all the data cleaning and variable creation stage. 
collect:  table gender [pweight=fwt]  , stat(mean  cooktime allchildcaretime )  stat(sd cooktime  allchildcaretime )  stat(n cooktime allchildcaretime ) nformat(%9.1f) 
collect export "results\IndiaTimeuseTablesRadstats.xlsx", sheet(Table 1) modify cell(c6) 
putexcel set "results\IndiaTimeuseTablesRadstats.xlsx" , sheet("Table 1") modify
putexcel d7:ad7 , txtwrap
putexcel A2 = "Mean of the cooking variable and the overall total childcare time"
putexcel a3 = "India Time-Use 2019"
putexcel a4 = "All adult respondents"
putexcel a5= "Please note the adults were aged 18+, or were married age 16 or 17 years."
putexcel save

collect:  table gender [pweight=fwt]  , stat(mean  minichildcaretime minitraveltime gngroupmean)  stat(sd minichildcaretime minitraveltime )  stat(n minichildcaretime minitraveltime ) nformat(%9.1f) 
collect export "results\IndiaTimeuseTablesRadstats.xlsx", sheet(Table 2) modify cell(c6) 
putexcel set "results\IndiaTimeuseTablesRadstats.xlsx" , sheet("Table 2") modify
putexcel d7:ad7 , txtwrap
putexcel A2 = "Mean of specified childcare time, travel time with family, and gender norm"
putexcel a3 = "India Time-Use 2019 and AB Gender Norm index (pro-male is from 0 to 2, range {-2,+2})"
putexcel a4 = "All adult respondents"
putexcel a5= "Please note the adults were aged 18+, or were married age 16 or 17 years."
putexcel save

collect:  table gender socialgroup2 [pweight=fwt]  , stat(mean  cooktime allchildcaretime )  stat(sd cooktime  allchildcaretime )  stat(n cooktime allchildcaretime ) nformat(%9.1f) 
collect export "results\IndiaTimeuseTablesRadstats.xlsx", sheet(Table 3) modify cell(c6) 
putexcel set "results\IndiaTimeuseTablesRadstats.xlsx" , sheet("Table 3") modify
putexcel d7:ad7 , txtwrap
putexcel A2 = "Mean of the cooking variable and the overall total childcare time"
putexcel a3 = "India Time-Use 2019"
putexcel a4 = "Adult respondents, broken down by sex and social group"
putexcel a5= "Please note the adults were aged 18+, or were married age 16 or 17 years."
putexcel save

collect:  table state gender haschild [pweight=fwt]  , stat(mean  cooktime allchildcaretime numchild)  stat(sd cooktime allchildcaretime numchild )  stat(n cooktime allchildcaretime numchild) nformat(%9.1f) 
collect export "results\IndiaTimeuseTablesRadstats.xlsx", sheet(Table 4) modify cell(c6) 
putexcel set "results\IndiaTimeuseTablesRadstats.xlsx" , sheet("Table 4") modify
putexcel d7:ad7 , txtwrap
putexcel A2 = "Mean of the cooking variable and the overall total childcare time"
putexcel a3 = "India Time-Use 2019"
putexcel a4 = "By Sex Within State, and Showing Childcare Time By Whether a Child is Present"
putexcel a5= "Please note the adults were aged 18+, or were married age 16 or 17 years."
putexcel save

collect:  table gender [pweight=fwt] , stat(mean  allchildcaretime cooktime married numchild hhsize haschild i.edu i.agegroup i.socialgroup2 hasteach hascompoccup )  stat(sd allchildcaretime cooktime married numchild hhsize haschild i.edu i.agegroup i.socialgroup2 hasteach hascompoccup ) stat(n allchildcaretime cooktime married numchild hhsize haschild i.edu i.agegroup i.socialgroup2 hasteach hascompoccup ) nformat(%9.1f) 
collect export "results\IndiaTimeuseTablesRadstats.xlsx", sheet(appendix) modify cell(c6) 
putexcel set "results\IndiaTimeuseTablesRadstats.xlsx" , sheet("appendix") modify
putexcel d7:ad7 , txtwrap
putexcel A2 = "Mean of several variables "
putexcel a3 = "India Time-Use 2019"
putexcel a4 = "All adult respondents"
putexcel a5= "Please note the adults were aged 18+, or were married age 16 or 17 years."
putexcel save

*** Regression stage
*** Prior to Multilevel Modelling

* W I T H O U T   S T A T E 
*cooking time in households with a child - all hholds
tobit cooktime gender i.agegroup numchild numadult sc st muslim [pweight=fwt], ll(0) vce(robust)
*cooking time - all females
tobit cooktime        i.agegroup numchild numadult sc st muslim [pweight=fwt] if female==1, ll(0) vce(robust)

*All child care time - all hholds
tobit allchildcaretime gender i.agegroup numchild numadult sc st muslim [pweight=fwt], ll(0) vce(robust)
*All child care time - all females
tobit allchildcaretime gender i.agegroup numchild numadult sc st muslim [pweight=fwt], ll(0) vce(robust)

* * * W I T H     * * * STATE
*cooking time in households with a child - all hholds
tobit cooktime gender i.agegroup numchild numchild2 numadult sc st muslim i.state [pweight=fwt], ll(0) vce(robust)
*cooking time - all females
tobit cooktime i.agegroup numchild numchild2 numadult sc st muslim i.state [pweight=fwt] if female==1, ll(0) vce(robust)
*All child care time - all hholds
tobit allchildcaretime gender i.agegroup numchild numchild2 numadult sc st muslim i.state [pweight=fwt], ll(0) vce(robust)
*All child care time - all females
tobit allchildcaretime gender i.agegroup numchild numchild2 numadult sc st muslim i.state if female==1 [pweight=fwt], ll(0) vce(robust)

*Test further theory that certain household occupations have women doing less childcare.
  * * WITHOUT STATE* * 

  *COOKING TIME, ALL HHOLDS
  tobit cooktime gender i.agegroup numchild numchild2 numadult hasteach hascompoccup sc st muslim [pweight=fwt], ll(0) vce(robust)
  * COOKING TIME, ONLY FEMALES
tobit cooktime         i.agegroup numchild numchild2 numadult hasteach hascompoccup sc st muslim [pweight=fwt] if female==1, ll(0) vce(robust)
   *ALL CHILDCARE, ALLHHOLDS
tobit allchildcaretime gender i.agegroup numchild numchild2 numadult hasteach hascompoccup sc st muslim [pweight=fwt], ll(0) vce(robust)
*ALL CHILDCARE, ONLY FEMALES
tobit allchildcaretime       i.agegroup numchild numchild2 numadult hasteach hascompoccup sc st muslim [pweight=fwt], ll(0) vce(robust)

*It looks like the large amounts are driven by demography plus gender norms.  Therefore, now test the gender norms.
   * * * WITHOUT STATE * * * 
  *COOKING TIME, ALL HHOLDS
tobit cooktime gender i.agegroup numchild numchild2 numadult hasteach hascompoccup sc st muslim gngroupmean [pweight=fwt], ll(0) vce(robust)
  * COOKING TIME, ONLY FEMALES
tobit cooktime i.agegroup numchild numchild2 numadult hasteach hascompoccup sc st muslim gngroupmean [pweight=fwt] if female==1, ll(0) vce(robust)
*ALL CHILDCARE, ALLHHOLDS
tobit allchildcaretime gender i.agegroup numchild numchild2 numadult hasteach hascompoccup sc st muslim gngroupmean [pweight=fwt], ll(0) vce(robust)
*ALL CHILDCARE, ONLY FEMALES
tobit allchildcaretime i.agegroup numchild numchild2 numadult hasteach hascompoccup sc st muslim gngroupmean if female==1 [pweight=fwt], ll(0) vce(robust)
* the hypothesis that rural residents have different gender norms would be tested
*if we added Rural but it should be in a SEM context, and with state, not at a national level and without SEM.  Because it creates collinearity with education.

*Two further random tests beyond endogeneity level:
*1. does state matter? technically yes, but the effect sizes are small.

tobit allchildcaretime gender i.agegroup numchild numchild2 numadult hasteach hascompoccup sc st muslim gngroupmean i.state [pweight=fwt], ll(0) vce(robust)

*2. does rural matter?  no:  technically yes, but the effect size is very small.
tobit allchildcaretime gender i.agegroup numchild numchild2 numadult hasteach hascompoccup sc st muslim gngroupmean rural [pweight=fwt], ll(0) vce(robust)

* 3 do both matter?   technically yes, but the effect sizes are small.
tobit allchildcaretime gender i.agegroup numchild numchild2 numadult hasteach hascompoccup sc st muslim gngroupmean rural i.state [pweight=fwt], ll(0) vce(robust)

* Do Not Save Data Now.  save  "data\IndiaITUSChildcareTimeuseAll.dta", replace
* Why? Because: Place any labelling or manipulation above the save line earlier at Linenumber 71.
translate "LogWendyOlsenChildcareanalysis.smcl" "LogWendyOlsenChildcareanalysis.pdf" , replace
