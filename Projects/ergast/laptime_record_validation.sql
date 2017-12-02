# variables to ignore certain races or results if they're actualy correct, but just weird (like 2014 China)

set @ignored_raceIds = "903"; # used by FIND_IN_SET to ignore these races (2014 china?)... a bit inefficient but the only way to use a variable to store the 'array' of raceIds
set @ignored_resultIds = ""; # see above... just specifify like any array. just something like "23,45,67,89"


# results.laps says the driver had at least 1 lap, but the driver's first lap laptime doesn't exist
select *
	from races
    join results r on r.raceId = races.raceId
    join drivers d on d.driverId = r.driverId
    left join laptimes l on l.raceId = r.raceId 
		AND l.driverId = r.driverId
        AND l.lap = 1
	where races.year >= 1996
		AND r.laps > 0 	
        AND isnull(l.position)
        AND NOT FIND_IN_SET(r.resultId, @ignored_resultIds)
        AND NOT FIND_IN_SET(r.raceId, @ignored_raceIds)
        
	order by races.date;

# Check if a laptime record for the driver's total laps in the results table exists
select *
	from races
    join results r on r.raceId = races.raceId
    join drivers d on d.driverId = r.driverId
    left join laptimes l on l.raceId = r.raceId
		AND l.driverId = r.driverId
        AND l.lap = r.laps  # This is the main check
	where races.year >= 1996 
		AND r.laps > 0
        AND isnull(l.position)
        AND NOT FIND_IN_SET(r.resultId, @ignored_resultIds)
        AND NOT FIND_IN_SET(r.raceId, @ignored_raceIds)
        
	order by races.date;
    
# The number of laptime records does not match the driver's results.laps value
select *
	from (
	select year, date, name, raceId, driverId, resultId, driverRef, grid, 
		sum(if(lap = 1, laptime_position,null)) as position_2nd,
        position as position_final,
        laps,
		sum(if(isnull(laptime_position),0,1)) as laptime_records,
		laps - sum(if(isnull(laptime_position),0,1)) as delta_in_laptime_records_vs_laps	   
		from (
		select races.year,
			   races.date,
			   races.name,
			   races.raceId,
			   driverRef,
			   d.driverId,
               r.resultId,
			   r.grid,
			   r.position as position,
	#           l.lap as laptime_lap,
			   l.position as laptime_position,
			   r.laps,
               l.lap
			   
			from races
			join results r on r.raceId = races.raceId
			join drivers d on d.driverId = r.driverId
			left join laptimes l on l.raceId = r.raceId
				AND l.driverId = r.driverId
			where races.year >= 1996 
				AND NOT FIND_IN_SET(r.resultId, @ignored_resultIds)
				AND NOT FIND_IN_SET(r.raceId, @ignored_raceIds)
        
			order by races.date
		) query1
		group by driverId, raceId
		#order by delta_in_laptime_records_vs_laps desc
		order by date, driverRef
	) query2
    where (laps <> laptime_records);
    
    
    
# Other potential validation queries

# query to compare the driver's position in his final lap to his official finishing position
##  too many false positives though, because of post-race penalties
##  example: 1996 European F1... 2 DSQs (10th and 12th) moved a bunch of drivers 4 drivers (11th, 13th, 14th, and 15th) up 1 or 2 positions
/*
select *
	from races
    join results r on r.raceId = races.raceId
    join drivers d on d.driverId = r.driverId
    join status s on s.statusId = r.statusId
    join laptimes l on l.raceId = r.raceId
		AND l.driverId = r.driverId
        AND l.lap = r.laps
	where races.year >= 1996 
		AND r.laps > 0
        AND NOT FIND_IN_SET(r.resultId, @ignored_resultIds)
        AND NOT FIND_IN_SET(r.raceId, @ignored_raceIds)
        AND l.position <> r.position
        AND (s.status like "%lap%" or status like "%complete%") # need this, for scenarios like brundle 1996 Brazil.  He spun off, but was classified.  So although he was 7th in his last completed lap, he ended up 12th.
        
	order by races.date;
*/

# query to print out the laptime of the highest lap for each driver, then manually compare this laptime with the records
## go through these one-by-one against official records to spot check each driver's race result
## Would be 2% of the work of verifying every single laptime record (8,137 records vs 426,663 records), but hopefully provide 99.99% of the benefit.
