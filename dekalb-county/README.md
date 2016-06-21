## Dekalb County Health Inspection Data

home page: http://atlanta.digitalhealthdepartment.com/dekalb/

#### Basic program flow:

1. Loop through search query that has all (295) pages, with 10 establishments each
2. Loop through each page and grab establishment info, save to a list in R
3. Loop through each inspection for the establishment, save info to list in R
4. For each inspection, scrape data and save to a list in R
	- Inspection Types: food service, pool, etc
	- Use appropriate scraping script depending on the template (most are defined in the URL)

#### Data Structure:
INDEX PAGE
- establishment links
	- ESTABLISHMENT PAGE
		- establishment name
		- establishment address <- -[ ] TODO: need to figure out
		- INSPECTIONS
			- inspection link
			- inspection title
			- inspection date
			- inspection score
			- INSPECTION DATA
				- Inspection Report Data Frame (scraped data pieces off of inspection report, such as temperature measurements, CFSM, other establishment info, etc.)
