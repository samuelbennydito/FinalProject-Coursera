#Starting  R
library(tidyverse)
library(dplyr)
library(readr)
library(data.table)

#Importing csv into R
trip_data <- fread("C:/Users/Data Analyst/Final_Data_Without_Outliers.csv", header = TRUE, sep = ",")
summary(trip_data)
head(trip_data)

#Creating variable distance into data frame
library(geosphere)
trip_data <- trip_data %>% mutate(dist_in_m = distHaversine(cbind(start_lng, start_lat), cbind(end_lng, end_lat)))
summary(trip_data$dist_in_m)

#Creating variable duration into data frame
library(lubridate)
trip_data <- trip_data %>% mutate(duration_min = as.numeric(difftime(trip_data$ended_at, trip_data$started_at, unit = "mins")))
summary(trip_data$duration_min)

#Creating variable duration into data frame
trip_data$date <- as.Date(trip_data$started_at)
trip_data$day_of_week <- format(as.Date(trip_data$date), "%A")
summary(trip_data$day_of_week)
unique(trip_data$day_of_week)

#Counting each member and casual users and converting into percentage
library(scales)
Count_Member <- count(trip_data, member_casual, sort=TRUE)
Count_Member
print ("Percentage conversion")
percent(Count_Member$n/sum(Count_Member$n))

#Creating plot bar to compare the casual and member in their distribution of rideable type
ggplot(trip_data, aes(rideable_type, fill=member_casual)) + geom_bar() + coord_flip()

#Creating plot bar for days of week for each casual and memebr users. Fisr we must mutate 'data'day_of_week' into dactor
trip_data$day_of_week <- factor(trip_data$day_of_week, levels = c("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"))
ggplot(trip_data) + geom_bar(mapping = aes(x = day_of_week, fill = rideable_type)) + facet_wrap(~ member_casual, ncol = 1)

#Creating histogram to analyze duration of trip for each casual and member users
ggplot(filter(trip_data, trip_data$duration_min < 100), aes(x=duration_min)) + geom_histogram(binwidth = 10) + facet_wrap(~ member_casual)

#Creating histogram to analyze distance of trip for each casual and member users
ggplot(filter(trip_data, trip_data$dist_in_m < 15000), aes(x=dist_in_m)) + geom_histogram(binwidth = 500) + facet_wrap(~ member_casual)

#Createingnew filtered variables 
filtered_member <- filter(trip_data, member_casual=="member")
filtered_casual <- filter(trip_data, member_casual=="casual")

#Creating summary based on previous parameters for each filtered users
summary(drop_na(select(filtered_member, c('day_of_week', 'dist_in_m', 'duration_min'))))
summary(drop_na(select(filtered_casual, c('day_of_week', 'dist_in_m', 'duration_min'))))

#Counting most favorite starting station
head(count(filtered_member, start_station_name, sort=TRUE), n=10)
head(count(filtered_casual, start_station_name, sort=TRUE), n=10)
