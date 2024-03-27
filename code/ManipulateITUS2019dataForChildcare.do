log using "LogWendyOlsenManipulateChildcareTimeuse.smcl", replace
    *    * Stage 2

*Initial Data Cleaning for Indian Time-Use Data 2019, by Jihye Kim and Wendy Olsen 
* 2020, updated in 2023 and 2024 by Wendy Olsen 

* Wendy Olsen
* Clean, develop and summarise data from ITUS 2019
* Feb 2024.

* Use the file timeuse.dta from the datTUS2019downloadandmerge.do file.


cd "C:\data\ITUS\"
*clean time.
use "data\timeuse.dta", clear
*time is in minutes, when using this specific variable 'time'
gen temptimehours=time
drop time
gen time= 60*temptimehours
gen rural=0
replace rural=1 if sector == "1"
tab rural 

save "data\timeuseAmended.dta", replace

*Pseudocode.  *0Prep stage is to make time in hours per week, then ensure that each row spellings are correct for future use.
* 0 continue by cleaning activity codes at 2 and 3 digit level as required for childcare, cooking, co-resident children.
*note that earlier in the data DCT stage, we created weights as frequency relatives per person, not per activity . We will use unweighted time-sums.
*1 Identify both cooking  and whether kids resident. Then,
*2 identify childcare work with egen and max or sum at 2-digit level.  
*work out the time spent on it using a Literal Approach.  Similar to Govt of India methods.
*3 sum these 2 up, giving a total childcare amount.
*this is followed by dropping all simultaneous activity rows. We now have wide data with one row per person.
*4 clean the sociodemographics, so they match the other dataset (notably education)
*5 output



*1 Some details about step 1. 
*Childcare would include  
*31 Food and meals management and preparation 
*38 
*39 Other unpaid domestic services for household and family members
*41 Childcare and instruction 
*44 Travelling and accompanying goods or persons related to unpaid caregiving services for household and family members
 *49 Other activities related to unpaid caregiving services for household and family members [like waiting perhaps]

*and (11) col. 11: where the activity was performed: 1 in the home.  other numbers indicate outside the home. It is in block 6.  
*NExt we seek two activitis at once: one of them is cooking 31 , and another is childcare 38|39|41|44|49.

*& the adult must also be living with co-resident dependent-age children under age 16. 

*Step 0.  Check whether co-resident children.
 use "data\level2.dta", clear
gen linenum = _n
sort hhid
egen minline = min(linenum), by(hhid)
 egen hhsize= count(linenum), by(hhid)
 sort hhid
gen ischild=0 
replace ischild=1 if age<17
 egen numchild = sum(ischild) , by(hhid)
replace numchild=0 if numchild==.
scatter hhsize numchild
gen iselder=0
replace iselder=1 if age>65
 egen numelder = sum(iselder) , by(hhid)
replace numelder=0 if numelder==.
scatter hhsize numelder
gen conworkratio = (numelder+numchild)/hhsize
summ hhsize numchild numelder conworkratio
gen haschild=0
replace haschild=1 if numchild>0
egen maxeduinhh = max(highest_edu), by(hhid)
gen maxedu = 0
replace maxedu = maxeduinhh if maxeduinhh!=.

*Each person in roster has been assigned these variables which are measured at hhold level.

tab nic_2008 /// see url https://www.ncs.gov.in/Documents/NIC_Sector.pdf 

*Notice there is a sub-group for repairing computers- we will take that whole 'group' 95.
* We are forced to use only the 2-digit level of NIC_2008 with the 'ITUS 2019' data.
* 18 Printing and reproduction of recorded media
*26 Manufacture of computer, electronic and optical products
*59 Motion picture, video and television programme production, sound recording and music publishing activities
*60 Broadcasting and programming activities
*61 Telecommunications
*62 Computer programming, consultancy and related activities
*63 Information service activities
*72 Scientific research and development
*74 Other professional, scientific and technical activities
*79 Travel agency, tour operator and other reservation service activities
*82 Office administrative, office support and other business support activities
*95 Repair of computers and personal and household goods

*To use later, has a teacher ? includes ancillary staff?
egen numteach= count(psid) if (nic_2008==85), by(hhid)
replace numteach=0 if numteach==.
gen hasteach = 0
replace hasteach=1 if numteach>0
hist numteach

*85 Education
*Group 851 Primary education
*Group 852 Secondary education
*Group 853 Higher education
*Group 854 Other education
*Group 855 Educational support services


egen numcompoccup= count(psid) if (nic_2008==18|nic_2008==26|nic_2008==59|nic_2008==60|nic_2008==61|nic_2008==62|nic_2008==63|nic_2008==82|nic_2008==74|nic_2008==79|nic_2008==82|nic_2008==85), by(hhid)
replace numcompoccup=0 if numcompoccup==.
gen hascompoccup = 1 if numcompoccup>0
replace hascompoccup=0 if hascompoccup==.
gen has2compoccup=1 if numcompoccup>1
replace has2compoccup=0 if has2compoccup==.
hist numcompoccup

tab numcompoccup numteach
save "data\level2augmented.dta", replace
*Use the trick of line numbers.
keep if(linenum == minline)
    * Use the 3-digit level of nic_2008
*    261 Manufacture of electronic components
*next, 262 Manufacture of computers and peripheral equipment 
*264 Manufacture of consumer electronics
*264 Manufacture of consumer electronics
*432 Electrical, plumbing and other construction installation activities
*474 Retail sale of information and communications equipment in specialized stores
*620 Computer programming, consultancy and related activities
*951 Repair of computers and communication equipment
keep hhid hhsize numchild haschild numelder conworkratio maxeduinhh maxedu numcompoccup hascompoccup has2compoccup numteach hasteach 
save "data\householdnewvars.dta", replace

use  "data\timeuseAmended.dta", clear
merge m:1 hhid using  "data\householdnewvars.dta"
tab _merge
keep if _merge==3
drop _merge
save "data\timeuseAmended13022024.dta", replace


use "data\timeuseAmended13022024.dta", clear
sort psid

*Before finishing, create big aggregates using the literal method.
**********************************************
*** Make literal measurement data*****Acknowledging J. Kim, et al., article in Development and Practice, 2023; github website 
***********************************************
*https://github.com/WendyOlsen/excessworkhoursindia , with the code as open access via Creative Commons; and the Report on India's Time-Use Survey 2019 At URL https://mospi.gov.in/sites/default/files/publication_reports/Report_TUS_2019_0.pdf , accessed Feb 2024. 
*Modifications by W Olsen****************************************

* the number of simultaneous activities per slot (simultaneousactivity yes=1 or no=2)
* we found we need a baseline for each stint which is one line in this dataset, call this sim0.
* in general 1 means yes, and 2 or 0 means no.
gen simultaneous0=1 if simultaneousactivity==1
by psid time_from, sort: egen simultaneous = total(simultaneous0) 
*Now simultaneous is a count variable.
*tab simultaneous

* the number of activities per slot (multipleactivity yes=1 or no=2)
gen multiple0=1 if multipleactivity==1
by psid time_from, sort: egen multiple = total(multiple0) 
*Now multiple is a count variable. For a person, all their rows for one 'stint' (2-3 rows starting at one time) will show the n of rows here. 
tab multiple0
tab multiple 
* The above variable just records 0=no, not multiple.  and 1=yes, multiple,  Often it's 2 activities, 2 rows here.
tab haschild
* the number of activities per slot that are multiple but not simultaneous
gen notsimultaneous0=1 if multiple ==1 & simultaneous!=1
replace notsimultaneous0=0 if notsimultaneous0==.
by  psid time_from, sort: egen no_activities = total(notsimultaneous0) 
replace  no_activities=1 if notsimultaneous==0
*Now, we have the flag for number of activities being 1 in a time-slot and hence, for the one stint at that time.

* Allocate the new amount of time (stint/num of activities if they are not simultaneous; two non-simultaneous activities will have 15 minutes, each; three non-simultaneous activities will have 10 minutes, each) 
gen time_new=time/no_activities
gen time_new_adj = time_new 
*We already adjusted this for being in minutes rather than hours.  Be careful, do that just once. 
* Therefore, move the date to 14th of Feb 2024. 
save "data\timeuseAmended14022024.dta", replace


use "data\timeuseAmended14022024.dta", clear
sort psid
by psid, sort: egen time_economic0=sum(time_new_adj) if (activity_1digit==1|activity_1digit==2)
summ age if(time_economic0==.)
summ(haschild) if time_new_adj==.
*16 cases have a missing value. 
order time_economic0
by psid, sort: egen testvar = sum(time_economic0) 
by psid, sort: egen testvar2 = max(time_economic0)
*the testvar is the sum and gives 1000 minutes plus for most people, up to 15000.  The other one is the max and because they were already summed, it is the correct number.  The machine ignores the missing values in assessing both sum and max.  So, max is correct for taking total personal economic worktime here.
scatter testvar testvar2
by psid, sort: egen time_economic = max(time_economic0)
by psid, sort: egen time_unpaidservice0=sum(time_new_adj) if (activity_1digit==3|activity_1digit==4|activity_1digit==5)
by psid, sort: egen time_unpaidservice = max(time_unpaidservice0) 
by psid, sort: egen time_anywork0=sum(time_new_adj) if (activity_1digit==1|activity_1digit==2|activity_1digit==3|activity_1digit==4|activity_1digit==5) 
by psid, sort: egen time_anywork= max(time_anywork0) 
by psid, sort: egen time_total0=sum(time_new_adj) 
by psid, sort: egen time_total= max(time_total0) 
replace time_economic=0 if time_economic==.
replace time_unpaidservice=0 if time_unpaidservice==.
replace time_anywork=0 if time_anywork==.
replace time_total=0 if time_total==.

*social group
gen socialgroup2=socialgroup
replace socialgroup2=4 if (socialgroup!=1 & socialgroup!=2) & religion==2 
recode socialgroup2 (9=0)

*type of work
*Type of work (BY USUAL STATUS) Type of work dominantly
*1) farming 
*2) household non-ag business 
*3) agricultural labour
*4) non-ag labour 
*5) domestic work
gen type=1  if (usualstatus==11|usualstatus==12|usualstatus==21) & (nic_2008==1)
replace type=2  if (usualstatus==11|usualstatus==12|usualstatus==21) & nic_2008!=. & type!=1
replace type=3  if (usualstatus==31|usualstatus==41|usualstatus==51) & (nic_2008==1)
replace type=4  if (usualstatus==31|usualstatus==41|usualstatus==51) & nic_2008!=. & type!=3
replace type=5  if (usualstatus==92|usualstatus==93)
replace type=0 if type==.

gen type2=1  if (nic_2008==1)
replace type2=2  if nic_2008!=. & type2!=1
replace type2=3  if (usualstatus==92|usualstatus==93)
replace type2=0 if type2==.

*land category
gen landcategory=land
recode landcategory (1/5=0) (6=1) (7/10=2)(11/12=3) (99=.)

*social class
gen class=.
replace class=0 if (usualstatu==41|usualstatu==51) & nic_2008!=1
replace class=1 if (usualstatu==41|usualstatu==51) & nic_2008==1
replace class=2 if (usualstatu==31)
replace class=3 if (usualstatu==11|usualstatu==12|usualstatu==21) & nic_2008!=1
replace class=4 if (usualstatu==11|usualstatu==12|usualstatu==21) & nic_2008==1 & landcategory==0
replace class=5 if (usualstatu==11|usualstatu==12|usualstatu==21) & nic_2008==1 & landcategory==1
replace class=6 if (usualstatu==11|usualstatu==12|usualstatu==21) & nic_2008==1 & landcategory==2
replace class=7 if (usualstatu==11|usualstatu==12|usualstatu==21) & nic_2008==1 & landcategory==3
replace class=8 if class==.

*household class by head status*
gen hhclass0=class if  relation_head==1
by hhid, sort: egen hhclass = max(hhclass0) 

*exploitation not available when I use the literal approach. 

*****************************************
*** Labelling ***************************
*****************************************

label define payment 1	"	Unpaid	self development		" 2	"	Unpaid	care for children		" 3	"	Unpaid	production of other services		" 4	"	Unpaid	production of goods own consumption		" 5	"	Unpaid	voluntary	goods in households	" 6	"	Unpaid	voluntary	services in households	" 7	"	Unpaid	voluntary	goods in market and non-market unit	" 8	"	Unpaid	voluntary	services in market and non-market unit	" 9	"	Unpaid	trainee	goods	" 10	"	Unpaid	trainee	services	" 11	"	Unpaid	other	goods	"  12	"	Unpaid	other	services	" 13	"	Paid	self employment	goods	" 14	"	Paid	self employment	services	" 15	"	Paid	regular waged	goods	" 16	"	Paid	regular waged	services	" 17	"	Paid	casual labour	goods	" 18	"	Paid	casual labour	services	"
label value payment payment 

label define usualstatus 11 "own account worker hh enterprise" 12 "employer hhenterprise" 21 "unpaid family worker" 31 "regular paid worker" 41 "casual labourer public" 51 "casual labourer other" 81 "seeking work"  91 "attended education" 92 "domestic duties only" 93 "domestic duties and collection" 94 "rentiers pensioners" 95 "not able to work" 97 "others"
label value usualstatus usualstatus

label define socialgroup 1 "ST" 2 "SC" 3 "OBC" 4 "Muslim Non SC/ST" 0 "Others"
label value socialgroup2 socialgroup

label define activity 110	"	Employment in corporations		" 121	"	Informal goods	Growing of crops	" 122	"	Informal goods	Raising animals	" 123	"	Informal goods	Forestry and logging	" 124	"	Informal goods	Fishing	" 125	"	Informal goods	Aquaculture	" 126	"	Informal goods	Mining and quarrying	" 127	"	Informal goods	Making and processing goods	" 128	"	Informal goods	Construction	" 129	"	Informal goods	Others	" 131	"	Informal services	Vending and trading	" 132	"	Informal services	Paid repair	" 133	"	Informal services	Paid business	" 134	"	Informal services	Transporting goods	" 135	"	Informal services	Paid personal care	" 136	"	Informal services	Paid domestic services	" 139	"	Informal services	Others	" 141	"	Employment related	Ancillary activities	" 142	"	Employment related	Breaks during working time	" 150	"	Employment related	Training and studies	" 160	"	Seeking employment		" 170	"	Setting up a business		" 181	"	Employment related	Travel	" 182	"	Employment related	Commuting	" 211	"	Own use production goods	Growing crops	" 212	"	Own use production goods	Farming of animals	" 213	"	Own use production goods	Hunting	" 214	"	Own use production goods	Forestry	" 215	"	Own use production goods	Gathering wild products	" 216	"	Own use production goods	Fishing	" 217	"	Own use production goods	Aquaculture	" 218	"	Own use production goods	Mining and quarrying	" 221	"	Own use processing goods	food products, beverages, tobacco	" 222	"	Own use processing goods	textiles, wearing apparel, leather	" 223	"	Own use processing goods	wood and bark products	" 224	"	Own use processing goods	bricks, concrete slabs	" 225	"	Own use processing goods	herbal and medicinal preparations	" 226	"	Own use processing goods	herbal and medicinal preparations	" 227	"	Own use processing goods	others	" 229	"	Own use processing goods	Acquiring supplies and disposing of products	" 230	"	Own use 	Construction activities	" 241	"	Own use 	Gathering firewood	" 242	"	Own use 	Fetching water	" 250	"	Own use	travelling	" 311	"	Unpaid domestic services	Preparing meals	" 312	"	Unpaid domestic services	Serving meals	" 313	"	Unpaid domestic services	Cleaning up	" 314	"	Unpaid domestic services	Storing, arranging	" 319	"	Unpaid domestic services	other food work	" 321	"	Unpaid domestic services	Indoor cleaning	" 322	"	Unpaid domestic services	Outdoor cleaning	" 323	"	Unpaid domestic services	Recycling	" 324	"	Unpaid domestic services	plants, hedges, garden	" 325	"	Unpaid domestic services	furnace, boiler, fireplace	" 329	"	Unpaid domestic services	other dwelling	" 331	"	Unpaid domestic services	maintenance	" 332	"	Unpaid domestic services	equipment	" 333	"	Unpaid domestic services	vehicle maintenance	" 339	"	Unpaid domestic services	other decoration	" 341	"	Unpaid domestic services	washing	" 342	"	Unpaid domestic services	Drying	" 343	"	Unpaid domestic services	Ironing	" 344	"	Unpaid domestic services	Mending	" 349	"	Unpaid domestic services	other textile care	" 359	"	Unpaid domestic services	other household management	" 361	"	Unpaid domestic services	pet care	" 362	"	Unpaid domestic services	veterinary care	" 369	"	Unpaid domestic services	other pet	" 371	"	Unpaid domestic services	Shopping	" 380	"	Unpaid domestic services	Travelling	" 390	"	Unpaid domestic services	Others	"
destring activity_code, replace
label value activity_code activity

label define activity2 11  "Employment in corporations, government and non-profit institutions" 12 "Employment in household enterprises to produce goods" 13 "Employment in households and household enterprises to provide services" 14 "Ancillary activities and breaks related to employment" 15 "Training and studies in relation to employment" 16 "Seeking employment" 17 "Setting up a business" 18 "Travelling and commuting for employment" 21 "Agriculture, forestry, fishing and mining for own final use" 22 "Making and processing goods for own final use" 23 "Construction activities for own final use" 24 "Supplying water and fuel for own household or for own final use" 25 "Travelling, moving, ...goods or persons related to own-use production of goods" 31 "Food and meals management and preparation" 32 "Cleaning and maintaining of own dwelling and surroundings" 33 "Do-it-yourself decoration, maintenance and repair" 34 "Care and maintenance of textiles and footwear" 35 "Household management for own final use" 36 "Pet care" 37 "Shopping for own household and family members" 38 "Travelling, moving, transporting or accompanying goods or persons ...unpaid domestic household and family" 39 "Other unpaid domestic services for household and family members" 41 "Childcare and instruction" 42 "Care for dependent adults" 43 "Help to non-dependent adult household and family members" 44 "Travelling and accompanying goods or persons ...unpaid caregiving ...household and family members" 49 "Other activities ...unpaid caregiving services for household"  51 "Unpaid direct volunteering for other households" 52 "Unpaid community- and organization-based volunteering" 53 "Unpaid trainee work and related activities" 54 "Travelling time related to unpaid volunteer, trainee and other unpaid work" 59 "Other unpaid work activities" 61 "Formal education" 62 "Homework, being tutored, ...research ...activities"  63 "Additional study, non-formal education and courses" 64 "Travelling time related to learning" 69 "Other activities related to learning" 71 "Socializing and communication" 72 "Participating in community cultural/social events" 73 "Involvement in civic and related responsibilities" 74 "Religious practices" 75 "Travelling time related to socializing ...particip...religious" 79 "Other activities related to socializing ...community particip...religious" 81 "Attending/visiting cultural, entertainment and sports events/venues" 82 "Cultural participation, hobbies, games and other pastime activities" 83 "Sports participation and exercise, and related activities" 84 "Mass media use" 85 "Activities associated with reflecting, resting, relaxing" 86 "Travelling time related to culture, leisure, mass media and sports practices" 89 "Other activities related to culture, leisure, mass media and sports practices" 91 "Sleep and related activities" 92 "Eating and drinking" 93 "Personal hygiene and care" 94 "Receiving personal and health/medical care from others" 95 "Travelling time related to self-care and maintenance activities" 99 "Other self-care and maintenance activities", modify

*Source:  *for codes used at 2-digit level, see UN (2021), International Classification of Activities for Time-Use Statistics 2016, Department of Economic and Social Affairs Statistics Division, Statistical Papers Series M No. 98, New York:  United Nations. URL accessed Feb 2023, https://unstats.un.org/unsd/gender/timeuse/23012019%20ICATUS.pdf;  see pages 17-19.

destring activity_2digits, replace
label value activity_2digits activity2

label define type 1 "Farming" 2 "Hh non-ag business" 3 "Ag labourer" 4 "Non-ag labourer"  5 "Hh worker" 0 "Others"
label value type type

label define land 0 "<1hec" 1 "1-2hec" 2 "2-6hec" 3 "6+hec"
label value landcategory landcategory

label define class 1 "Ag labourers" 0 "Non-ag labourers" 2 "Waged workers" 3 "Family business" 4 "Marginal farmers" 5 "Small farmers" ///
6 "Middle farmers" 7 "Large farmers"  8 "Others"
label value class class
label value hhclass class

label define sector 1 "Rural" 2 "Urban"
destring sector, replace
label value sector sector

save "data\timeuse_literalChildcareAll14022024step0.dta", replace
use  "data\timeuse_literalChildcareAll14022024step0.dta", clear

**************Step 1  
*Childcare activity-codes are:    *31 *38 *39 *41 *44  *49  of which cooking is 31. 
*Note.  ICATUS 2016 published 2021 does not match pages 15 ff in India's TUS Report 2020. See URL https://mospi.gov.in/sites/default/files/publication_reports/Report_TUS_2019_0.pdf, accessed Feb. 2024. Page 15 has cooking per se. 
*and (11) col. 11: where the activity was performed: 1 in the home.  other numbers indicate outside the home. It is in block 6.  
*Next we also allow them to do two activities at once: one of them is cooking 31 , and another is childcare 38|41|44|49.
*We do not want to double-count this situation.  The initial activity-code is for any time-slot in any role as 1st, 2nd, or 3rd activity. 
*But, if they are doing either and have a co-resident child, we can assume they are cooking for that child among others. 
*thus, this adult must also be living with co-resident dependent-age children under age 16. 

*combined with
*2 identify childcare work with egen and max or sum at 2-digit level.  
*3 sum these 2 up, giving a total childcare amount.

by psid, sort: egen allchildcaretime0 = sum(time_new_adj) if ((activity_2digits==31 & haschild==1)|(activity_2digits==38|activity_2digits==39|activity_2digits==41|activity_2digits==44|activity_2digits==49))
by psid, sort:  egen  allchildcaretime= max(allchildcaretime0) 

by psid, sort:  egen cooktime0=sum(time_new_adj) if activity_2digits==31 & haschild==1
by psid, sort:  egen  cooktime= max(cooktime0) 

by psid, sort: egen minichildcaretime0 = sum(time_new_adj) if (activity_2digits==38|activity_2digits==39|activity_2digits==41|activity_2digits==49)
by psid, sort:  egen  minichildcaretime= max(minichildcaretime0) 

by psid, sort:  egen minitraveltime0 = sum(time_new_adj) if activity_2digits==44
by psid, sort:  egen  minitraveltime= max(minitraveltime0) 
 
replace minitraveltime=0 if minitraveltime==.
replace minichildcaretime=0 if minichildcaretime==.
replace cooktime=0 if cooktime==.
replace allchildcaretime=0 if allchildcaretime==.

hist cooktime
hist minichildcaretime
summ cooktime minichildcaretime
summ cooktime minichildcaretime if haschild==1&female==1
summ allchildcaretime
summ minitraveltime
*scatter bigchildcaretime age || qfit bigchildcaretime age
*save the data as extensive coverage timeuse dta

save "data\timeuse_literalChildcareAll14022024step1.dta", replace
use  "data\timeuse_literalChildcareAll14022024step1.dta", clear

*getting to know your rectangular data
*duplicates report hhid psid time_from2
 *duplicates report hhid psid time_from2 multipleactivity activity_id
 * duplicates report psid time_from2 activity_id
 isid psid time_from2 activity_id
*reduce it to persons, one line per person. However, avoid collapse command. Delete unmeaningful vars afterward.
*RISE TO HIGHER LEVEL OF INDIVIDUAL NOW.
*Use the _n  approach:  sort makes this robust; egen within {hhid psid} using 'minimum' gives 1 person and 1 time-slot with the minimum _n; and select that person but then ignore all the other time-slots.  Thus, records that are time-slot specific should be DROPPED.
sort psid time_from2 activity_id
gen linenum=_n
summ linenum

egen psidfirstactivityinpsid = min(linenum), by(psid)
keep if psidfirstactivityinpsid==linenum
isid psid
summ  highest_edu linenum
*Drop the time-slot specific variables now.
drop activity_id time_from time_to multipleactivity simultaneousactivity majoractivity activity_code activity_performed payment type_enterprise

*4 clean the sociodemographics, so they match the other dataset (notably education)

tab maritalstatus
gen edu = 0
replace edu=1 if highest_edu==1|highest_edu==2
replace edu=2 if highest_edu==3|highest_edu==4
replace edu=3 if highest_edu==5
replace edu=4 if highest_edu==6|highest_edu==7
replace edu=5 if highest_edu==8|highest_edu==10|highest_edu==11|highest_edu==12
tab edu 
tabstat age, by(edu)
drop if edu==0

label define educ 1 "Below Primary" 2 "Primary" 3 "Incomplete Secondary" 4 "Complete Secondary" 5 "Higher Educ", modify
label values edu educ

save "data\IndiaITUSChildcareTimeuse.dta", replace
*this basic file has all ages.  Don't change this program to remove ages.  Create a seaprate code file & separate datafile.

log close

translate "LogWendyOlsenManipulateChildcareTimeuse.smcl" "LogWendyOlsenManipulateChildcareTimeuse.pdf", replace
