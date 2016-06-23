get.establishment.pages <- 
     function(index.page.links, index.start, index.end){
          lapply(index.page.links[index.start:index.end],
                 function(x){
                      read_html(x) %>% html_nodes("a") %>% html_attr("href") %>% 
                           .[grepl("id=", .)] %>% paste0(base.url, .)
          }
          ) %>% 
     unlist()
     }

establishment.pages1 <- character(500) #1-50
establishment.pages2 <- character(500) #51-100
establishment.pages3 <- character(500) #101-150
establishment.pages4 <- character(500) #151-200
establishment.pages5 <- character(500) #201-250
establishment.pages6 <- character(470) #250-296

print("1-50")
establishment.pages1 <- get.establishment.pages(index.page.links, 1, 50)
print("51-100")
establishment.pages2 <- get.establishment.pages(index.page.links, 51, 100)
print("101-150")
establishment.pages3 <- get.establishment.pages(index.page.links, 101, 150)
print("151-200")
establishment.pages4 <- get.establishment.pages(index.page.links, 151, 200)
print("201-250")
establishment.pages5 <- get.establishment.pages(index.page.links, 201, 250)
print("251-296")
establishment.pages6 <- get.establishment.pages(index.page.links, 251, 296)

get.inspection.links <- function(establishment.pages, 
                                start.establishment = 1, 
                                end.establishment = length(establishment.pages))
     {
     lapply(establishment.pages[start.establishment:end.establishment],
            function(x) read_html(x) %>% html_nodes("b a ") %>%
                 html_attr("href") %>% 
                 gsub("\\.\\.", "http://atlanta.digitalhealthdepartment.com", .)) %>% 
          unlist()
}

inspection.links <- vector("list", length = 1000)

for(i in 1:1000){
     inspection.links[[i]] <- get.inspection.links(establishment.pages = establishment.pages, start.establishment = i,
                                                end.establishment = i + 1)
}