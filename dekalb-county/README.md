## Dekalb County Health Inspection Data

home page: http://atlanta.digitalhealthdepartment.com/dekalb/
info from Dekalb Health Dept. on food safety inspection form: http://dekalbhealth.net/wp-content/uploads/2010/09/foodsfty_inspectionReport.html

#### Basic program flow:

1. Loop through search query that has all (295) pages, with 10 establishments each
2. Loop through each page and grab establishment info, save to a list in R
3. Loop through each inspection for the establishment, save info to list in R
4. For each inspection, scrape data and save to a list in R
	- Inspection Types: food service, pool, etc
	- Use appropriate scraping script depending on the template (most are defined in the URL)

#### Data Structure:
- index page link
     - establishment link
     	- establishment name
     	- establishment address <- -[ ] TODO: need to figure out
     	- inspection link
     		- inspection title
     		- inspection date
     		- inspection score
     		- Inspection Data Frame (scraped data pieces off of inspection report, such as temperature measurements, CFSM, other establishment info, etc.)
