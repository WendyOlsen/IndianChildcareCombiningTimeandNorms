log using "LogAsianBaroSetupGNorm.smcl", replace

*Wendy Olsen 
*January 2024

*The data is Asian Barometer produced in 2019. 
*Aim to run a factor analysis for gender norms using Indian Asian Barometer data.

cd c:\data\AsianBaro
use  "data\AsianBaro2019.dta", clear

*Descriptives
tab Q63 
tab Q69
tab Q146
tab SE2
gen female=0
replace female=1 if SE2==2
hist w
tab Region
tab Level

tab Q63 
tab Q63 , nol
*Variable based on "Q63. When a mother-in-law and a daughter-in- law come into conflict, even if the mother- in-law is in the wrong, the husband should still persuade his wife to obey his mother."
gen age=Se3_1
gen age2=age*age
gen agegroup=0
replace agegroup=1 if age<36
replace agegroup=2 if age>35&age<66
replace agegroup=3 if age>65
tab agegroup 

gen rural=0
replace rural=1 if Level==1

gen edu=0
replace edu=1 if SE5==1|SE5==2
replace edu=2 if SE5==3
replace edu=3 if SE5==4|SE5==6
replace edu=4 if SE5==5|SE5==7
replace edu=5 if SE5==8|SE5==9|SE5==10
replace edu=1 if SE5==99
tab edu
label define educ 1 "Below Primary" 2 "Primary" 3 "Incomplete Secondary" 4 "Complete Secondary" 5 "Higher Educ", modify
label values edu educ

gen state=Region

 gen muslim=0
 replace muslim=1 if SE6==40
 label define muslim  0 "No" 1 "Muslim", modify
 label values muslim muslim
 
 summ Q63, detail
tab Q63
*Preferring that a daughter-in-law NOT concede to husband's mother is a high value on this ordinal scale.
 gen op1=Q63
replace op1=4 if Q63==3
replace op1=5 if Q63==4
*take care of Do not understand the question 7 Can't choose 8 and Decline to answer 9. 
replace op1=3 if Q63==7|Q63==8|Q63==9
tab op1

* NOtes: Do not understand the question |         7
*> 7        1.45       92.20
 *                 Can't choose |        22
*> 0        4.14       96.33
 *            Decline to answer |        19
*> 5        3.67      100.00



tab Q69, nol
*Preferring to have girl children is a high value on the ordinal scale.
gen op2=Q69
replace op2=4 if Q69==3
replace op2=5 if Q69==4
*take care of Do not understand the question 7 Can't choose 8 and Decline to answer 9. 
replace op2=3 if Q69==7|Q69==8|Q69==9
tab op2

summ Q146, detail
tab Q146, nol
* Preferring to have women engaged in politics is a high value on the ordinal scale.
gen op3=Q146
replace op3=4 if Q146==3
replace op3=5 if Q146==4
*take care of Do not understand the question 7 Can't choose 8 and Decline to answer 9. 
replace op3=3 if Q146==7|Q146==8|Q146==9
tab op3
table (female), stat(mean op1-op3) nformat(%9.1f)
format op1-op3 %9.1f
corr op1-op3, noformat

*Make a factor
gsem (op1 op2 op3 <-Ab1, family(ordinal) link(logit) vce(robust) pweights(w))
estat sd
estat ic
estat summarize
estat vce
predict factor_estimates, latent 
gen gn=factor_estimates
summ gn, detail
label variable gn "Gender Norm (2019), Z-Score Scale -3 to +3"
hist gn, kdensity
graph export "HistogramGNforIndia2019AsianBaromfrom3vars.jpg", replace

*Same factor, without weights on cases
gsem (op1 op2 op3 <-Ab1, family(ordinal) link(logit) vce(robust) )
estat sd
estat ic
estat summarize
estat vce
predict factor_estimatesNoWgt, latent 
gen gnNoWgt=factor_estimatesNoWgt
summ gnNoWgt, detail
hist gnNoWgt
graph export "VariantHistogramGNforIndia2019AsianBaromfrom3vars.jpg", replace

scatter gn gnNoWgt

*Examine the data alongside the weighted-Latent factor 'gender norm'
regress gn female i.Region [pweight=w]
regress gn Level Se3_1  [pweight=w]
regress gn i.Region Level [pweight=w]
regress gn i.Region female [pweight=w]

tab Region
*We see that Andhra Pradesh is not missing, it is the reference case.  So apparently gn in Kerala is similar to AP and Telangana - quite plausible. 

*run a larger model and test them in nested format.
gsem (Ab1 <- female ) (op1 op2 op3 <-Ab1, family(ordinal) link(logit) vce(robust) pweights(w))
estat ic
gsem, coeflegend
estat summarize
estat vce
predict factvariant, latent
gen gn2=factor_estimates
summ gn2, detail
hist gn2
scatter gn gn2
corr gn gn2

*the much better model is the one used in  MPLUS where we also have latent continuous factors for each
*of the manifest variables.  Finally one aggregate factor is the index for the norm overall.
*but the thresholds are visible within this ordinal model so it is fine.
*compare this model's fit with the other, using a penalised fit measure like AIC.

*Outputs
* graphs

* tables

collect:  table Region [pweight=w]  , stat(mean  gn age w )  stat(sd gn age w )  stat(n gn age w ) nformat(%9.2f) 
collect export "results\IndiaGnTablesAsianBarom.xlsx", sheet(Table 1) modify cell(c6) 
putexcel set "results\IndiaGnTablesAsianBarom.xlsx" , sheet("Table 1") modify
putexcel d7:ad7 , txtwrap
putexcel A2 = "Mean of the Gender Norm Factor (Z-Scaled) By State"
putexcel a3 = "Asian Barometer Data 2019"
putexcel a4 = "All respondents"
putexcel a5= "Please note we have used ordinal logit confirmatory factor analysis, giving four thresholds per Likert scale."
putexcel save

hist gn, kdensity
label variable gn "Gender Norm (Negative Values Pro-Male Sexist)"
gen idraw=_n
egen numobsraw= count(idraw)
summ idraw numobsraw
svyset [pweight=w]
svy:  mean gn 
egen meangn = mean(gn)
*The true mean is 0.

save "data\temp.dta", replace
collapse (mean) meangn= gn (sd) sdgn=gn (count) n=gn, by(edu)
generate hign= meangn+ invttail(n-1,0.025)*(sdgn / sqrt(n))
generate logn= meangn- invttail(n-1,0.025)*(sdgn/ sqrt(n))
graph bar meangn, over(edu)

list
graph twoway (bar meangn edu ) (rcap hign logn edu), by(edu) 
generate education= 1 if edu== 1
replace  education= edu+5  if edu == 2
replace  education= edu+10 if edu == 3
replace  education= edu+10 if edu == 4
replace  education= edu+10 if edu== 5

sort education
twoway (bar meangn education if edu==1) ///
       (bar meangn education if edu==2) ///
       (bar meangn education if edu==3) ///
       (bar meangn education if edu==4) ///
	   (bar meangn education if edu==5)
       (rcap hign logn edu)

	   list sesrace ses race, sepby(ses)
graph bar gn , over(edu) 
twoway (bar meangn education if edu==1) ///
       (bar meangn education if edu==2) ///
       (bar meangn education if edu==3) ///
       (bar meangn education if edu==4) ///
	   (bar meangn education if edu==5)

use "data\temp.dta", clear
collect:  table  edu [pweight=w]  , stat(mean  gn w)  stat(sd gn w)  stat(n gn w) nformat(%9.2f) 
collect export "results\IndiaGNTablesAsianBarom.xlsx", sheet(Table 2) modify cell(c6) 
putexcel set "results\IndiaGNTablesAsianBarom.xlsx" , sheet("Table 2") modify
putexcel d7:ad7 , txtwrap
putexcel A2 = "Mean of the Gender Norm Factor and Case-Weights by Education"
putexcel a3 = "Asian Barometer Data 2019"
putexcel a4 = "All respondents"
putexcel a5= "Please note the gender norm index ran from -3 to +3 approximately"
putexcel save

* dataset
save AsianBaro2019withGN.dta, replace

* make an R data set as csv too
cd c:\data\AsianBaro
use  AsianBaro2019withGN.dta, clear
egen gngroupmean = mean(gn), by(rural agegroup edu)
egen gngroupsd = sd(gn), by(rural agegroup edu)
keep IDnumber female state rural agegroup gngroupmean gngroupsd edu w
egen wcountofgroup = sum(w), by (rural agegroup edu)
collapse (max) gngroupmean gngroupsd wcountofgroup, by(rural agegroup edu )
order rural agegroup edu 
sort rural agegroup edu
list
save "data\AsBarGroupInfoGN.dta", replace
log close
translate "LogAsianBaroSetupGNorm.smcl" "LogAsianBaroSetupGNorm.pdf", replace
