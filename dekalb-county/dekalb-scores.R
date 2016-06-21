#NEED TO FIGURE OUT HOW TO COMBINE DATA INTO ONE OBJECT (LIST OR DATA FRAME)

page <- "http://atlanta.digitalhealthdepartment.com/dekalb/search.cfm?f=s&inspectionType=&s=&r=ename&fromScore=0&toScore=100&Search=Search"
base.page <- "http://atlanta.digitalhealthdepartment.com/dekalb/"

page.list <- read_html(page) %>% 
     html_nodes(".teaser") %>% html_attr("href")
i <- 0
for(page in page.list[1:2]){
     i <- i + 1
     print(paste0("i: ",i))
     establishment.links <- paste0(base.page,
                              read_html(paste0(base.page, page)) %>% 
          html_nodes("a") %>% html_attr("href") %>% .[grepl("id=", .)])
     print("establishment links: ")
     print(establishment.links)
     
     establishment.name <- character()
     inspections <- character()
     
     j <- 0
     for(page2 in establishment.links[1:2]){
          j <- j + 1
          print(paste0("j: ", j))
          
          page2.html <- read_html(page2)
          establishment.name <-
               c(establishment.name,
                 page2.html %>% html_nodes("h3") %>% 
                      html_text())
          inspection.links <- page2.html %>% html_nodes("b a") %>% html_attr("href") %>% gsub("\\.\\.", "http://atlanta.digitalhealthdepartment.com", .)
          print("inspection.links: ")
          print(inspection.links)
          
          k <- 0
          for(inspection.link in inspection.links){
               k <- k + 1
               print(paste0("k: ", k))
               if(grepl("Food", inspection.link)){
                    inspections[k] <- scrape.food.service.inspection(inspection.link)
               } else{
                    print("not a food service inspection")
               }
               print(inspections)
               
          }
     }
}

scrape.food.service.inspection <- function(page){
     require(rvest)
     require(dplyr)
     require(stringr)
     
     # Scraping Dekalb County restaurant inspection data from a food service inspection report

     page.html <- read_html(page)
     
     # TOP SECTION: MAIN INSPECTION INFO
     
     # Score
     page.html %>% html_nodes(".small:nth-child(2) div") %>% html_text()
     
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
     
     # establishment name
     scrape.node(page.html, "tr:nth-child(2) .bottom.slightlyLargerFont")
     # address
     scrape.node(page.html, "td .bottom.slightlyLargerFont")
     # city
     scrape.node(page.html,"table:nth-child(2) .slightlyLargerFont:nth-child(2)")
     # time in (H)
     scrape.node(page.html, "table:nth-child(2) .slightlyLargerFont:nth-child(4)", type = "number")
     # time in (M)
     scrape.node(page.html, ".slightlyLargerFont:nth-child(6)", type = "number")
     # time in (AM/PM)
     scrape.node(page.html, ":nth-child(7) sup")
     # time out (H)
     scrape.node(page.html, ".slightlyLargerFont:nth-child(8)", type = "number")
     # time out (M)
     scrape.node(page.html, ".slightlyLargerFont:nth-child(10)", type = "number")
     # time out (AM/PM)
     scrape.node(page.html, ":nth-child(11) sup")
     # inspection date
     scrape.node(page.html, ".bottom.slightlyLargerFont strong", type = "date")
     # cfsm (a.k.a. Certified Food Safety Manager)
     scrape.node(page.html, "table:nth-child(3) .slightlyLargerFont:nth-child(4)") %>% gsub("Â\\W+", "", .)
     # purpose of inspection
     c("Construction/Preoperational", "Initial", "Premise Visit", "Routine", "Follow-Up", "Temporary")[scrape.node(page.html, ".mains img", type = "raw") %>% html_attr("src") %>% str_detect("_filled") %>% .[1:6]]
     # risk type
     c(1:3)[scrape.node(page.html, ".mains img", type = "raw") %>% html_attr("src") %>% str_detect("_filled") %>% .[7:9]]
     # permit number
     scrape.node(page.html, ".slightlyLargerFont16", type = "text") %>% gsub("\\s", "", .)
     # current score
     page.html %>% html_nodes(".bottom .right.bottom strong") %>% html_text() %>% gsub("\\r|\\n|\\t", "", .) %>% as.numeric()
     # current grade
     page.html %>% html_nodes("tr:nth-child(6) .eleven td:nth-child(1)") %>% html_text() %>% gsub("\\r|\\n|\\t|\\s{2,}", "", .) %>% gsub(".+Â\\s", "", .)
     
     ## Addendum 1 Food Temperatures
     cold.holding <- page.html %>% html_nodes("table:nth-child(8) tr:nth-child(3) table") %>% html_table() %>% .[[1]]
     names(cold.holding) <- cold.holding[2,]
     
     cold.holding <- rbind(
          cold.holding %>% .[3:nrow(.),] %>% 
               lapply(., function(vec) gsub("(Â)|(Â\\s{1})", "", vec)) %>% .[1:4] %>% data.frame(),
          cold.holding %>% .[3:nrow(.),] %>%
               lapply(., function(vec) gsub("(Â)|(Â\\s{1})", "", vec)) %>% .[5:8] %>% data.frame())
     
          cold.holding %>% mutate(Item = str_split(Item.Location, pattern = " / ") %>% lapply(function(x) x[1]) %>% unlist() %>% factor(),
                                  Location = str_split(Item.Location, pattern = " / ") %>% lapply(function(x) x[2]) %>% unlist() %>% factor(),
                                  Temp = as.numeric(substr(Temp, 1, 4))) %>% select(-Item.Location)
     
     
}
