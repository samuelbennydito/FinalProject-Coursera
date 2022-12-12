--- Create Table.
CREATE TABLE divvy_tripdata_2021
	(ride_id varchar(50),
	 rideable_type varchar(50),
	 started_at TIMESTAMP,
	 ended_at TIMESTAMP,
	 start_station_name varchar(100),
	 start_station_id varchar(100),
	 end_station_name varchar(100),
	 end_station_id varchar(100),
	 start_lat numeric,
	 start_lng numeric,
	 end_lat numeric,
	 end_lng numeric,
	 member_casual varchar(100)
);
--- Check the preview of first n-values.
SELECT * FROM public.divvy_tripdata_2021;
LIMIT 10;
--- Check the total number of All rows from this table.
SELECT COUNT(*) FROM public.divvy_tripdata_2021;
--- Investigate the possibility of EXACT duplicate data in each columns.
SELECT 
	ride_id, rideable_type, started_at, ended_at, 
	start_station_name, start_station_id, end_station_name, end_station_id, start_lat,
	start_lng, end_lat, end_lng, member_casual, COUNT(*)
FROM public.divvy_tripdata_2021
GROUP BY 
	ride_id, rideable_type, started_at, ended_at, 
	start_station_name, start_station_id, end_station_name, end_station_id, start_lat,
	start_lng, end_lat, end_lng, member_casual
HAVING COUNT(*) > 1;
--  Check the duplicate data based on any certain columns to investigate it deeper. 
SELECT 
	ride_id, rideable_type, started_at, ended_at, 
	start_station_name, start_station_id, end_station_name, end_station_id, COUNT(*)
FROM public.divvy_tripdata_2021
GROUP BY 
	ride_id, rideable_type, started_at, ended_at, 
	start_station_name, start_station_id, end_station_name, end_station_id
HAVING COUNT(*) > 1;
---  Check the integrity of dataset. 
SELECT 
	started_at,
	ended_at,
	(ended_at - started_at) AS diff_time,
	((DATE_PART('day', ended_at::timestamp - started_at::timestamp) * 24 + 
               DATE_PART('hour', ended_at::timestamp - started_at::timestamp)) * 60 +
               DATE_PART('minute', ended_at::timestamp - started_at::timestamp)) * 60 +
			   DATE_PART('second', ended_at::timestamp - started_at::timestamp) AS diff_in_second
FROM public.divvy_tripdata_2021
ORDER BY diff_time DESC
--- Ensure it deeper, If there are not duration of trips in in negative values. 
SELECT 
	started_at,
	ended_at,
	(ended_at - started_at) AS diff_time,
	((DATE_PART('day', ended_at::timestamp - started_at::timestamp) * 24 + 
               DATE_PART('hour', ended_at::timestamp - started_at::timestamp)) * 60 +
               DATE_PART('minute', ended_at::timestamp - started_at::timestamp)) * 60 +
			   DATE_PART('second', ended_at::timestamp - started_at::timestamp) AS diff_in_second
FROM public.divvy_tripdata_2021
WHERE  ((DATE_PART('day', ended_at::timestamp - started_at::timestamp) * 24 + 
               DATE_PART('hour', ended_at::timestamp - started_at::timestamp)) * 60 +
               DATE_PART('minute', ended_at::timestamp - started_at::timestamp)) * 60 +
			   DATE_PART('second', ended_at::timestamp - started_at::timestamp) < 0;
			   
SELECT COUNT(*)
FROM public.divvy_tripdata_2021
WHERE  ((DATE_PART('day', ended_at::timestamp - started_at::timestamp) * 24 + 
               DATE_PART('hour', ended_at::timestamp - started_at::timestamp)) * 60 +
               DATE_PART('minute', ended_at::timestamp - started_at::timestamp)) * 60 +
			   DATE_PART('second', ended_at::timestamp - started_at::timestamp) < 0;
			   
--- remove these rows from dataset. 
DELETE FROM public.divvy_tripdata_2021
WHERE ride_id IN (SELECT 
						ride_id
						FROM public.divvy_tripdata_2021
						WHERE  ((DATE_PART('day', ended_at::timestamp - started_at::timestamp) * 24 + 
              			DATE_PART('hour', ended_at::timestamp - started_at::timestamp)) * 60 +
              			DATE_PART('minute', ended_at::timestamp - started_at::timestamp)) * 60 +
			   			DATE_PART('second', ended_at::timestamp - started_at::timestamp) < 0);		   

--- Investigate the number of NUll per colummns. 
SELECT
	SUM(CASE WHEN ride_id IS NULL THEN 1 ELSE 0 END) AS null_ride_id,
	SUM(CASE WHEN rideable_type IS NULL THEN 1 ELSE 0 END) AS null_rideable_type,
	SUM(CASE WHEN started_at IS NULL THEN 1 ELSE 0 END) AS null_started_at,
	SUM(CASE WHEN ended_at IS NULL THEN 1 ELSE 0 END) AS null_ended_at,
	SUM(CASE WHEN start_station_name IS NULL THEN 1 ELSE 0 END) AS null_start_station_name,
	SUM(CASE WHEN start_station_id  IS NULL THEN 1 ELSE 0 END) AS null_start_station_id,
	SUM(CASE WHEN end_station_name IS NULL THEN 1 ELSE 0 END) AS null_end_station_name,
	SUM(CASE WHEN end_station_id IS NULL THEN 1 ELSE 0 END) AS null_end_station_id,
	SUM(CASE WHEN start_lat IS NULL THEN 1 ELSE 0 END) AS null_start_lat,
	SUM(CASE WHEN start_lng IS NULL THEN 1 ELSE 0 END) AS null_start_lng,
	SUM(CASE WHEN end_lat IS NULL THEN 1 ELSE 0 END) AS null_end_lat,
	SUM(CASE WHEN end_lng IS NULL THEN 1 ELSE 0 END) AS null_end_lng,
	SUM(CASE WHEN member_casual IS NULL THEN 1 ELSE 0 END) AS null_member_casual,
	Count(*)
FROM public.divvy_tripdata_2021;
--- Investigate where does the Nulll mostly occur in dataset. The easiest parameter is using 'rideable_type' column because it contains 3 variables for comparasion. 
SELECT 
	rideable_type, 
	SUM(CASE WHEN start_station_name IS NULL THEN 1 ELSE 0 END) AS null_start_station_name,
	SUM(CASE WHEN end_station_name IS NULL THEN 1 ELSE 0 END) AS null_end_station_name,
	COUNT(*)
FROM public.divvy_tripdata_2021
GROUP BY rideable_type; 

--- CASE 1: If total dif_in_second is Not 0 AND start_lat or start_lng is Not Null AND end_lat or end_lng is NOT NUll THEN there is a transaction on this ride_id even though the column of 'start_station_name' or 'end_station_name' contains Null values. 
--- CASE 2: If total dif_in_second is 0 AND start_lat or start_lng is NULL OR Not Null AND end_lat or end_lng is NUll THEN there is no transaction on this ride_id. WE MUST REMOVE THIS ROWS.
--- Case 1 Sample:
SELECT 
	((DATE_PART('day', ended_at::timestamp - started_at::timestamp) * 24 + 
               DATE_PART('hour', ended_at::timestamp - started_at::timestamp)) * 60 +
               DATE_PART('minute', ended_at::timestamp - started_at::timestamp)) * 60 +
			   DATE_PART('second', ended_at::timestamp - started_at::timestamp) AS diff_in_second,
	start_station_name,
	end_station_name,
	start_lat, start_lng, end_lat, end_lng
FROM public.divvy_tripdata_2021
WHERE end_station_name IS NULL AND 
((DATE_PART('day', ended_at::timestamp - started_at::timestamp) * 24 + 
               DATE_PART('hour', ended_at::timestamp - started_at::timestamp)) * 60 +
               DATE_PART('minute', ended_at::timestamp - started_at::timestamp)) * 60 +
			   DATE_PART('second', ended_at::timestamp - started_at::timestamp) != 0;
--- Case 2 Sample:
SELECT
((DATE_PART('day', ended_at::timestamp - started_at::timestamp) * 24 + 
               DATE_PART('hour', ended_at::timestamp - started_at::timestamp)) * 60 +
               DATE_PART('minute', ended_at::timestamp - started_at::timestamp)) * 60 +
			   DATE_PART('second', ended_at::timestamp - started_at::timestamp) AS diff_in_second,
started_at, ended_at, start_station_name, end_station_name, start_lat, start_lng, end_lat, end_lng 
FROM public.divvy_tripdata_2021
WHERE ((DATE_PART('day', ended_at::timestamp - started_at::timestamp) * 24 + 
               DATE_PART('hour', ended_at::timestamp - started_at::timestamp)) * 60 +
               DATE_PART('minute', ended_at::timestamp - started_at::timestamp)) * 60 +
			   DATE_PART('second', ended_at::timestamp - started_at::timestamp) = 0
LIMIT 10;

SELECT rideable_type, COUNT(*)
FROM public.divvy_tripdata_2021
WHERE ((DATE_PART('day', ended_at::timestamp - started_at::timestamp) * 24 + 
               DATE_PART('hour', ended_at::timestamp - started_at::timestamp)) * 60 +
               DATE_PART('minute', ended_at::timestamp - started_at::timestamp)) * 60 +
			   DATE_PART('second', ended_at::timestamp - started_at::timestamp) = 0
GROUP BY rideable_type;

--- Remove all rows with Case 2 Condition
DELETE FROM public.divvy_tripdata_2021
WHERE ride_id IN (SELECT ride_id
						FROM public.divvy_tripdata_2021
						WHERE ((DATE_PART('day', ended_at::timestamp - started_at::timestamp) * 24 + 
               DATE_PART('hour', ended_at::timestamp - started_at::timestamp)) * 60 +
               DATE_PART('minute', ended_at::timestamp - started_at::timestamp)) * 60 +
			   DATE_PART('second', ended_at::timestamp - started_at::timestamp) = 0);
			   
--- Detect Outliers use standard deviation. In PostgreSQL, the function is called stddev_samp().
--- CASE Average with outliers

SELECT started_at, ended_at, (started_at - ended_at), 
DATE_PART('day', ended_at::timestamp - started_at::timestamp) AS diff_in_day
FROM public.divvy_tripdata_2021
ORDER BY diff_in_day DESC
LIMIT 30;

--- Outliers Preview
SELECT member_casual, COUNT(*)
FROM public.divvy_tripdata_2021
WHERE  DATE_PART('day', ended_at::timestamp - started_at::timestamp) >= 20 
GROUP BY member_casual

--- Next, we can detect outliers using stddev_samp() function
SELECT DATE_PART('day', ended_at::timestamp - started_at::timestamp) * 24 +
		DATE_PART('hour', ended_at::timestamp - started_at::timestamp) as diff_in_hour
FROM public.divvy_tripdata_2021
WHERE 
		DATE_PART('day', ended_at::timestamp - started_at::timestamp) * 24 +
		DATE_PART('hour', ended_at::timestamp - started_at::timestamp) NOT IN 
		(
	SELECT DATE_PART('day', ended_at::timestamp - started_at::timestamp) * 24 +
			DATE_PART('hour', ended_at::timestamp - started_at::timestamp) as diff_in_hour 
	FROM public.divvy_tripdata_2021 
	WHERE 
		DATE_PART('day', ended_at::timestamp - started_at::timestamp) * 24 +
		DATE_PART('hour', ended_at::timestamp - started_at::timestamp) > 
			(SELECT 
			 	(AVG(DATE_PART('day', ended_at::timestamp - started_at::timestamp) * 24 +
				DATE_PART('hour', ended_at::timestamp - started_at::timestamp)) - 
			  	STDDEV_SAMP(DATE_PART('day', ended_at::timestamp - started_at::timestamp) * 24 +
				DATE_PART('hour', ended_at::timestamp - started_at::timestamp)) * 3)
			FROM public.divvy_tripdata_2021) 
		AND 
		DATE_PART('day', ended_at::timestamp - started_at::timestamp) * 24 +
		DATE_PART('hour', ended_at::timestamp - started_at::timestamp) < 
			(SELECT 
			 	(AVG(DATE_PART('day', ended_at::timestamp - started_at::timestamp) * 24 +
				DATE_PART('hour', ended_at::timestamp - started_at::timestamp)) + 
			  	STDDEV_SAMP(DATE_PART('day', ended_at::timestamp - started_at::timestamp) * 24 +
				DATE_PART('hour', ended_at::timestamp - started_at::timestamp)) * 3)
			FROM public.divvy_tripdata_2021));
						   
SELECT 
		member_casual, 
		count(*), 
		MAX(DATE_PART('day', ended_at::timestamp - started_at::timestamp) * 24 +
		DATE_PART('hour', ended_at::timestamp - started_at::timestamp)) as max_hour_outlier, 
		MIN(DATE_PART('day', ended_at::timestamp - started_at::timestamp) * 24 +
		DATE_PART('hour', ended_at::timestamp - started_at::timestamp)) as min_hour_oitlier
FROM public.divvy_tripdata_2021
WHERE 
		DATE_PART('day', ended_at::timestamp - started_at::timestamp) * 24 +
		DATE_PART('hour', ended_at::timestamp - started_at::timestamp) NOT IN 
		(
	SELECT DATE_PART('day', ended_at::timestamp - started_at::timestamp) * 24 +
			DATE_PART('hour', ended_at::timestamp - started_at::timestamp) as diff_in_hour 
	FROM public.divvy_tripdata_2021 
	WHERE 
		DATE_PART('day', ended_at::timestamp - started_at::timestamp) * 24 +
		DATE_PART('hour', ended_at::timestamp - started_at::timestamp) > 
			(SELECT 
			 	(AVG(DATE_PART('day', ended_at::timestamp - started_at::timestamp) * 24 +
				DATE_PART('hour', ended_at::timestamp - started_at::timestamp)) - 
			  	STDDEV_SAMP(DATE_PART('day', ended_at::timestamp - started_at::timestamp) * 24 +
				DATE_PART('hour', ended_at::timestamp - started_at::timestamp)) * 3)
			FROM public.divvy_tripdata_2021) 
		AND 
		DATE_PART('day', ended_at::timestamp - started_at::timestamp) * 24 +
		DATE_PART('hour', ended_at::timestamp - started_at::timestamp) < 
			(SELECT 
			 	(AVG(DATE_PART('day', ended_at::timestamp - started_at::timestamp) * 24 +
				DATE_PART('hour', ended_at::timestamp - started_at::timestamp)) + 
			  	STDDEV_SAMP(DATE_PART('day', ended_at::timestamp - started_at::timestamp) * 24 +
				DATE_PART('hour', ended_at::timestamp - started_at::timestamp)) * 3)
			FROM public.divvy_tripdata_2021))
GROUP BY member_casual;

--- Case Final data by removing outliers

DELETE FROM public.divvy_tripdata_2021
WHERE 
		DATE_PART('day', ended_at::timestamp - started_at::timestamp) * 24 +
		DATE_PART('hour', ended_at::timestamp - started_at::timestamp) NOT IN 
		(
	SELECT DATE_PART('day', ended_at::timestamp - started_at::timestamp) * 24 +
			DATE_PART('hour', ended_at::timestamp - started_at::timestamp) as diff_in_hour 
	FROM public.divvy_tripdata_2021 
	WHERE 
		DATE_PART('day', ended_at::timestamp - started_at::timestamp) * 24 +
		DATE_PART('hour', ended_at::timestamp - started_at::timestamp) > 
			(SELECT 
			 	(AVG(DATE_PART('day', ended_at::timestamp - started_at::timestamp) * 24 +
				DATE_PART('hour', ended_at::timestamp - started_at::timestamp)) - 
			  	STDDEV_SAMP(DATE_PART('day', ended_at::timestamp - started_at::timestamp) * 24 +
				DATE_PART('hour', ended_at::timestamp - started_at::timestamp)) * 3)
			FROM public.divvy_tripdata_2021) 
		AND 
		DATE_PART('day', ended_at::timestamp - started_at::timestamp) * 24 +
		DATE_PART('hour', ended_at::timestamp - started_at::timestamp) < 
			(SELECT 
			 	(AVG(DATE_PART('day', ended_at::timestamp - started_at::timestamp) * 24 +
				DATE_PART('hour', ended_at::timestamp - started_at::timestamp)) + 
			  	STDDEV_SAMP(DATE_PART('day', ended_at::timestamp - started_at::timestamp) * 24 +
				DATE_PART('hour', ended_at::timestamp - started_at::timestamp)) * 3)
			FROM public.divvy_tripdata_2021))
