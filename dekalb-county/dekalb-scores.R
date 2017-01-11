# Scrape Dekalb County Health Inspection Data, and output to csv

# NEED TO BUILD IN ERROR HANDLING FOR PAGES THROWING ERRORS (while preserving data structures):
#    - "http://atlanta.digitalhealthdepartment.com/_templates/22/Food/_report_full.cfm?fsimID=434152&domainID=22",
#    - "http://atlanta.digitalhealthdepartment.com/_templates/22/Food/_report_full.cfm?fsimID=400422&domainID=22"
#    - "http://atlanta.digitalhealthdepartment.com/_templates/22/Food/_report_full.cfm?fsimID=499196&domainID=22"
#         -table issue: inconsistent number of columns (see html_table code)
#    - http://atlanta.digitalhealthdepartment.com/_templates/22/Food/_report_full.cfm?fsimID=459092&domainID=22
#         -table issue
#    - http://atlanta.digitalhealthdepartment.com/_templates/22/Food/_report_full.cfm?fsimID=474459&domainID=22
#         -Error in .[[1]] : subscript out of bounds
#    - http://atlanta.digitalhealthdepartment.com/_templates/22/Food/_report_full.cfm?fsimID=474144&domainID=22
#         -(html_table) Error: Table has inconsistent number of columns

get.dekalb.scores <- function(index.start = 1, index.end = 296){
     require(dplyr) #for munging data
     require(rvest) #for web scraping (read_html, html_nodes, html_attr)
     require(stringr) #for handling & converting strings
     require(lubridate) #for handling dates
     
     search.url <- "http://atlanta.digitalhealthdepartment.com/dekalb/search.cfm?f=s&inspectionType=&s=&r=ename&fromScore=0&toScore=100&Search=Search"
     base.url <- "http://atlanta.digitalhealthdepartment.com/dekalb/"
     
     # Definition of "index": page containing links (generally qty 10) to establishment pages
     
     # scrape the list of url's numbered 1-296 (as of 6/21/16) at the bottom of the page
     index.page.links <- read_html(search.url) %>% 
          html_nodes(".teaser") %>% html_attr("href") %>% paste0(base.url, .)
     
     # for each index page, get a list of establishment links
     establishment.pages <- 
          lapply(index.page.links[index.start:index.end], 
                 function(x) read_html(x) %>% html_nodes("a") %>% 
                      html_attr("href") %>% .[grepl("id=", .)] %>% 
                      paste0(base.url, .)) %>% unlist()
     
     # for each establishment page, get a list of all of the inspection links
     inspection.link <-
          lapply(establishment.pages,
                 function(x) read_html(x) %>% html_nodes("b a ") %>%
                      html_attr("href") %>% 
                      gsub("\\.\\.", "http://atlanta.digitalhealthdepartment.com", .)) %>% 
          unlist()
     
     # for each inspection link, extract the inspection template type
     # it is embedded in the inspection link url after _templates/22/; examples: Food, Food_2015, Pool_2008
     # later, each inspection template type will have its own unique scraper
     inspection.template.type <-
          substr(inspection.link, nchar("http://atlanta.digitalhealthdepartment.com/_templates/22/"), 
                 nchar("http://atlanta.digitalhealthdepartment.com/_templates/22/") + 10) %>% 
          str_split("/") %>%
          lapply(function(x) x[2]) %>% unlist()
     
     # create data frame of inspection info
     inspections <- data.frame(inspection.link, inspection.template.type, 
                               stringsAsFactors = FALSE)
     
     # separate above data frame into the different templates
     # NOTE: for efficiency sake if needed, can be done more efficiently with group_by(inspection.template.type)
     inspections.Food <- inspections %>% filter(inspection.template.type == "Food")
     inspections.Food_2015 <- inspections %>% filter(inspection.template.type == "Food_2015")
     inspections.Pool_2008 <- inspections %>% filter(inspection.template.type == "Pool_2008")
     
     # function definition for scraping template type Food
     scrape.Food.inspection <- function(page){
          print(paste0("inspection page: ",page))
          
          # Scraping Dekalb County restaurant inspection data from a food service inspection report
          
          page.html <- read_html(page)
          
          # TOP SECTION: MAIN INSPECTION INFO
          
          # Score
          # page.html %>% html_nodes(".small:nth-child(2) div") %>% html_text()
          
          scrape.node <- function(page.html, selector, type = "text"){
               require(lubridate, quietly = TRUE)
               if(type == "text"){
                    page.html %>% html_nodes(selector) %>% html_text() %>% gsub("\\r|\\n|\\t", "", .)
               } else if(type == "number"){
                    page.html %>% html_nodes(selector) %>% html_text() %>% as.numeric()
               } else if(type == "date"){
                    page.html %>% html_nodes(selector) %>% html_text() %>% mdy()
               } else if(type == "raw"){
                    page.html %>% html_nodes(selector)
               }
          }
          
          inspection.info <- data.frame(
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
               cfsm = scrape.node(page.html, "table:nth-child(3) .slightlyLargerFont:nth-child(4)") %>% gsub("Â\\W+", "", .),
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
          
          ## Addendum 1 Food Temperatures
          
          # if(inspection.info$purpose.of.inspection == "Construction/Preoperational"){
          #      cold.holding <- NA
          # } else {
          #      cold.holding <- page.html %>% 
          #           html_nodes("table:nth-child(8) tr:nth-child(3) table") %>% 
          #           html_table() %>% .[[1]]
          #      names(cold.holding) <- cold.holding[2,]
          #      
          #      cold.holding <- rbind(
          #           cold.holding %>% .[3:nrow(.),] %>% 
          #                lapply(., function(vec) gsub("(Â)|(Â\\s{1})", "", vec)) %>% .[1:4] %>% data.frame(),
          #           cold.holding %>% .[3:nrow(.),] %>%
          #                lapply(., function(vec) gsub("(Â)|(Â\\s{1})", "", vec)) %>% .[5:8] %>% data.frame())
          #      
          #      cold.holding <- cold.holding %>% 
          #           mutate(Item = str_split(Item.Location, pattern = " / ") %>% 
          #                       lapply(function(x) x[1]) %>% 
          #                       unlist() %>% factor(), 
          #                  Location = str_split(Item.Location, pattern = " / ") %>% 
          #                       lapply(function(x) x[2]) %>% unlist() %>% factor(),
          #                  Temp = as.numeric(substr(Temp, 1, 4))) %>% select(-Item.Location)
          # }
          # 
          # return(list(inspection.info, cold.holding))
          return(inspection.info)
     }
     
     # exceptions: pages that caused errors in the scraper (will skip over these, and handle later)
     inspection.page.exceptions <- 
          c("http://atlanta.digitalhealthdepartment.com/_templates/22/Food/_report_full.cfm?fsimID=434152&domainID=22",
            "http://atlanta.digitalhealthdepartment.com/_templates/22/Food/_report_full.cfm?fsimID=400422&domainID=22")
     
     # for each inspection link (not in exception list), run scraper scrape.Food.inspection (outputs a list)
     inspections.Food.data <- lapply(inspections.Food$inspection.link, 
                                     function(x) ifelse((x %in% inspection.page.exceptions), NA, scrape.Food.inspection(x)))
     
     # bind all elements of above list into a data frame via rbind_all, and add a column for inspection.link
     inspections.Food.dataframe <- rbind_all(lapply(inspections.Food.data, function(x) x[1][[1]])) %>% 
          mutate(link = as.character(inspections.Food$inspection.link))
     
     # write it to csv.  BLAM.
     write.csv(inspections.Food.dataframe,
               paste0("scraped-data/Template_Food", 
                      "_start-", str_pad(index.start, width = 3, pad = 0), 
                      "_end-", str_pad(index.end, width = 3, pad = 0),
                      ".csv"),
               row.names = FALSE)
     
     return(inspections.Food.dataframe)
}