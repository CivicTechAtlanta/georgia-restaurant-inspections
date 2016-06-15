# Get GA Food Service inspection data from a Socrata link, clean it up, and create:
#           "df" - data frame in the global environment
#   "scores.csv" - csv file in the working directory

library(RSocrata)
library(dplyr)

#Get Data From Socrata
SocrataLink <- "https://brigades.opendatanetwork.com/HEALTH/Fulton-County-Food-Service-Inspection-Scores-2014-/jzeg-w743"
df <- read.socrata(SocrataLink)

# Function "VectorSplitExtract": splits a homogeneous vector using strsplit, then extracts one of the elements
# Definition of homogeneous: all elements have same structure
VectorSplitExtract <- function(data, regex, elementnum){
  sapply(strsplit(data, regex), "[[", elementnum)
}

# Extract elements out of the "Address" field
  # Street Address
  address_street <- VectorSplitExtract(df$Address, "\n", 1)
  # City, State, Zip
  address_citystatezip <- VectorSplitExtract(df$Address, "\n", 2)
  address_city <- VectorSplitExtract(address_citystatezip, ", ", 1)
  address_statezip <- VectorSplitExtract(address_citystatezip, ", ", 2)
  address_state <- substr(address_statezip, 1, 2)
  address_zip <- substr(address_statezip, 4, nchar(address_statezip))
  # Latitude, Longitude
  address_latlon <- VectorSplitExtract(df$Address, "\n", 3)
  address_latlon_commaloc <- sapply(strsplit(address_latlon, ''), function(x) which(x == ","))
  address_latitude <- as.numeric(substr(address_latlon, 2, address_latlon_commaloc - 1))
  address_longitude <- as.numeric(substr(address_latlon, address_latlon_commaloc+3, nchar(address_latlon)-1))

# Add extracted Address elements to df
df$street <- address_street
df$city <- address_city
df$state <- address_state
df$zip <- address_zip
df$latitude <- address_latitude
df$longitude <- address_longitude

# Clean up
  # Remove "Address" from df
  df <- select(df, -Address)
  # Remove everything from environment except for df
  rm(list = ls()[ls() != "df"])

# Write df to "scores.csv" in the working directory
write.csv(df, "scores.csv")