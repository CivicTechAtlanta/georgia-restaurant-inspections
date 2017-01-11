library(lubridate)
library(rvest)
library(dplyr)
library(readr)

base.url <- "http://ga.healthinspections.us/dekalb/"

# Search for Inspection Type = "Food", and save results to an html object
s <- html_session("http://ga.healthinspections.us/dekalb/search.cfm")
form1 <- s %>% html_nodes("form") %>% 
     html_form() %>% .[[1]] %>% set_values(inspectionType = "Food")
r <- submit_form(s, form1)

# Collect all links that have "start=" in them (these are result pages, length 10 each)
result_pages <- 
     r %>% read_html() %>% html_nodes("a") %>% 
     html_attr("href") %>% .[grepl("start=", .)] %>%
     paste0(base.url, .)

# Loop through result pages and get establishment pages
results <- vector(mode = "list", length = length(result_pages))
for(i in 1:length(results)){
     results[[i]]$establishment_pages <- 
          result_pages[i] %>% read_html() %>% html_nodes("a") %>% 
          html_attr("href") %>% .[grepl("id=", .)] %>%
          paste0(base.url, .)
}
establishment_pages <- bind_rows(results)$establishment_pages

# Loop through each establishment page and get inspection links
inspection_links <- vector(mode = "list", length = length(establishment_pages))
for(i in 1:length(inspection_links)){
     inspection_links[[i]]$link <- 
          establishment_pages[i] %>% read_html() %>% html_nodes("a") %>% 
          html_attr("href") %>% .[grepl("_template", .)] %>%
          paste0(base.url, .)
}
inspection_links <- bind_rows(inspection_links) %>%
     mutate(template_type = str_extract(link, "(?<=_templates/22/)(Food_2015|Food|Pool_2008)"))

# Function to handle cases where inspection record doesn't have a header with Establishment Name, Score, etc
zerolength_nacheck <- function(x){
     ifelse(length(x) == 0, NA, x)
}

# Function to parse an html_node call and remove junk from the text (extra whitespace, newline characters)
scrape.node <- function(page.html, selector, type = "text"){
     require(lubridate, quietly = TRUE)
     if(type == "text"){
          page.html %>% html_nodes(selector) %>% html_text() %>% 
               gsub("\\r|\\n|\\t", "", .)
     } else if(type == "number"){
          page.html %>% html_nodes(selector) %>% html_text() %>% 
               gsub("\\r|\\n|\\t|\\s", "", .) %>% as.numeric()
     } else if(type == "date"){
          page.html %>% html_nodes(selector) %>% html_text() %>% mdy()
     } else if(type == "raw"){
          page.html %>% html_nodes(selector)
     }
}

# Functions to take an html inspection record page, scrape key pieces of info, and save to a data frame
# There are 2 separate functions for each template type: Food and Food_2015
scrape_inspection_data_Food <- function(page){
     page.html <- read_html(page)
     data.frame(
          # establishment name
          establishment.name = scrape.node(page.html, "tr:nth-child(2) .bottom.slightlyLargerFont"),
          # address
          address = scrape.node(page.html, "td .bottom.slightlyLargerFont"),
          # city
          city = scrape.node(page.html,"table:nth-child(2) .slightlyLargerFont:nth-child(2)"),
          # time in (H)
          time.in.h = scrape.node(page.html, "table:nth-child(2) .slightlyLargerFont:nth-child(4)", type = "number"),
          # time in (M)
          time.in.m = scrape.node(page.html, ".slightlyLargerFont:nth-child(6)", type = "number"),
          # time in (AM/PM)
          time.in.ampm = scrape.node(page.html, ":nth-child(7) sup"),
          # time out (H)
          time.out.h = scrape.node(page.html, ".slightlyLargerFont:nth-child(8)", type = "number"),
          # time out (M)
          time.out.m = scrape.node(page.html, ".slightlyLargerFont:nth-child(10)", type = "number"),
          # time out (AM/PM)
          time.out.ampm = scrape.node(page.html, ":nth-child(11) sup"),
          # inspection date
          inspection.date = scrape.node(page.html, ".bottom.slightlyLargerFont strong", type = "date"),
          # cfsm (a.k.a. Certified Food Safety Manager)
          cfsm = scrape.node(page.html, "table:nth-child(3) .slightlyLargerFont:nth-child(4)") %>% gsub("Â\\W+", "", .) %>% str_trim(),
          # purpose of inspection
          purpose.of.inspection = c("Construction/Preoperational", "Initial", 
                                    "Premise Visit", "Routine", "Follow-Up", 
                                    "Temporary")[scrape.node(page.html, ".mains img", type = "raw") %>% 
                                                      html_attr("src") %>% str_detect("_filled") %>% .[1:6]],
          # risk type
          risk.type = c(1:3)[scrape.node(page.html, ".mains img", type = "raw") %>% html_attr("src") %>% str_detect("_filled") %>% .[7:9]],
          # permit number
          permit.number = scrape.node(page.html, ".slightlyLargerFont16", type = "text") %>% gsub("\\s", "", .),
          # current score
          current.score = page.html %>% html_nodes(".bottom .right.bottom strong") %>% html_text() %>% gsub("\\r|\\n|\\t", "", .) %>% as.numeric(),
          # current grade
          current.grade = page.html %>% html_nodes(".bottom .bottom:nth-child(2) div strong") %>% html_text() %>% gsub("\\r|\\n|\\t|\\s{2,}", "", .) %>% gsub(".+Â\\s", "", .)
     )
}

scrape_inspection_data_Food_2015 <- function(page){
     page.html <- read_html(page)
     data.frame(
          # establishment name
          establishment.name = zerolength_nacheck(scrape.node(page.html, ".ArialEleven:nth-child(3) .borderBottom")),
          # address
          address = zerolength_nacheck(scrape.node(page.html, ":nth-child(4) .borderBottom")),
          # city
          city = zerolength_nacheck(scrape.node(page.html,".borderRightBottom .ArialEleven:nth-child(1) :nth-child(2)")),
          # time in (H)
          time.in.h = zerolength_nacheck(scrape.node(page.html, ".ArialEleven:nth-child(1) :nth-child(4)", type = "number")),
          # time in (M)
          time.in.m = zerolength_nacheck(scrape.node(page.html, ".ArialEleven:nth-child(1) :nth-child(6)", type = "number")),
          # time in (AM/PM)
          time.in.ampm = zerolength_nacheck(scrape.node(page.html, ":nth-child(2) :nth-child(1) :nth-child(7) b")),
          # time out (H)
          time.out.h = zerolength_nacheck(scrape.node(page.html, ".borderBottom:nth-child(9)", type = "number")),
          # time out (M)
          time.out.m = zerolength_nacheck(scrape.node(page.html, ".borderBottom:nth-child(11)", type = "number")),
          # time out (AM/PM)
          time.out.ampm = zerolength_nacheck(scrape.node(page.html, ":nth-child(12) b")),
          # inspection date
          inspection.date = zerolength_nacheck(scrape.node(page.html, ".borderBottom strong", type = "date")),
          # cfsm (a.k.a. Certified Food Safety Manager)
          cfsm = zerolength_nacheck(scrape.node(page.html, ".ArialEleven:nth-child(2) :nth-child(6)")) %>% gsub("Â\\W+", "", .) %>% str_trim(),
          # purpose of inspection
          purpose.of.inspection = ifelse(length(scrape.node(page.html, ".ArialTen img", type = "raw")) == 0,
                                         NA,
                                         c("Routine", "Followup", "Initial", 
                                           "Issued Provisional Permit", "Temporary")[scrape.node(page.html, ".ArialTen img", type = "raw") %>% 
                                                      html_attr("src") %>% str_detect("_filled") %>% .[1:5]]),
          # risk type
          risk.type = ifelse(length(scrape.node(page.html, ".ArialTen img", type = "raw")) == 0,
                             NA,
                             c(1:3)[scrape.node(page.html, ".ArialTen img", type = "raw") %>% 
                                         html_attr("src") %>% str_detect("_filled") %>% .[6:8]]),
          # permit number
          permit.number = ifelse(length(scrape.node(page.html, ".ArialTen .borderBottom", type = "text")) == 0,
                                 NA,
                                 scrape.node(page.html, ".ArialTen .borderBottom", type = "text") %>% gsub("\\s", "", .)),
          # current score
          current.score = ifelse(length(page.html %>% html_nodes("#div_finalScore")) == 0,
                                 NA,
                                 page.html %>% html_nodes("#div_finalScore") %>% html_text() %>% 
                                      gsub("\\r|\\n|\\t", "", .) %>% as.numeric()),
          # current grade
          current.grade = ifelse(length(page.html %>% html_nodes("#div_grade")) == 0,
                                 NA,
                                 page.html %>% html_nodes("#div_grade") %>% html_text() %>% 
                                      gsub("\\r|\\n|\\t|\\s{2,}", "", .) %>% gsub(".+Â\\s", "", .))
     )
}

# Split inspection_links data frame into 2, by template type
inspection_links_Food <- inspection_links %>% 
     filter(template_type == "Food") %>% .$link
inspection_links_Food_2015 <- inspection_links %>% 
     filter(template_type == "Food_2015") %>% .$link

# Initialize lists to scrape data into
inspection_data_Food <- vector(mode = "list", length = length(inspection_links_Food))
inspection_data_Food_2015 <- vector(mode = "list", length = length(inspection_links_Food_2015))

# Scrape data from records with template "Food"
for(i in 1:length(inspection_links_Food)){
     print(now())
     print(paste0("Scraping template Food, # ", i))
     inspection_data_Food[[i]] <- scrape_inspection_data_Food(inspection_links_Food[i])
     Sys.sleep(rnorm(n = 1, mean = 2, sd = .01))
}

# Scrape data from records with template "Food_2015"
for(i in 1:length(inspection_links_Food_2015)){
     print(now())
     print(paste0("Scraping template Food_2015 # ", i))
     inspection_data_Food_2015[[i]] <- 
          scrape_inspection_data_Food_2015(inspection_links_Food_2015[i])
     Sys.sleep(rnorm(n = 1, mean = 2, sd = .01))
}

# Clean up date field in inspection_data_Food_2015 (some were showing up as 5 digit number...
# ... in R, 5 digit numeric dates are the # of days since 1/1/1970
for(i in 1:length(inspection_data_Food_2015)){
     x <- inspection_data_Food_2015[[i]]$inspection.date
     inspection_data_Food_2015[[i]]$inspection.date <- 
          as.Date(x, origin = as.Date("1970-01-01"))
}

# Save data from both templates into one data frame
restaurant_inspection_data <- 
     bind_rows(bind_rows(inspection_data_Food[1:2235]) %>% mutate(template_type = "Food"), 
               bind_rows(inspection_data_Food_2015[1:3396]) %>% mutate(template_type = "Food_2015"))

# Combine time_in and time_out features into one date/time vector, and calculate inspection duration
restaurant_inspection_data <-
     restaurant_inspection_data %>% 
     mutate(date_time_in = ymd_hm(paste0(inspection.date, " ", time.in.h, ":", time.in.m, " ", time.in.ampm)), 
            date_time_out = ymd_hm(paste0(inspection.date, " ", time.out.h, ":", time.out.m, " ", time.out.ampm)), 
            inspection_duration = as.numeric(difftime(date_time_out, date_time_in, units = "hours"))) %>%
     filter(!is.na(establishment.name))

# Write data to csv file in "scraped-data" folder
write_csv(restaurant_inspection_data, "dekalb-county/scraped-data/dekalb_county_restaurant_inspections.csv")