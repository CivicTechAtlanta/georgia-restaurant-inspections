## Dekalb County Health Inspection Data

Home Page: http://atlanta.digitalhealthdepartment.com/dekalb/
Info from Dekalb Health Dept. on food safety inspection form: http://dekalbhealth.net/wp-content/uploads/2010/09/foodsfty_inspectionReport.html
Food Safety Rules: https://dekalbhealth.net/envhealth/food-safety/

#### Basic program flow:

1. Loop through search query that has all (~295) pages, with 10 establishments each (as of 1/10/17...these numbers will grow as more data is added)
2. Loop through each page and grab establishment info, save to a list in R
3. Loop through each inspection for the establishment, save info to list in R
4. For each inspection record, scrape data to R

#### Data Structure:
- index page link
     - establishment link
     	- inspection link
     		- inspection metadata: establishment name, address, city, time in, time out,
     		  inspection date, Certified Food Safety Manager (CFSM), purpose of inspection,
     		  risk type, permit number
     		- inspection score
     		- inspection grade (A, B, C, or U)