# Is missing 1st lap laptimes (quick test to see if something's missing)

select *
	from races
    join results r on r.raceId = races.raceId
    join drivers d on d.driverId = r.driverId
    left join laptimes l on l.raceId = r.raceId 
		AND l.driverId = r.driverId
        AND l.lap = 1
	where races.year > 1996
		AND r.laps > 0 	
        AND isnull(l.position)
	order by races.date;

# Check if the highest lap's laptime matches the number of completed laps for a driver        
select *
	from races
    join results r on r.raceId = races.raceId
    join drivers d on d.driverId = r.driverId
    left join laptimes l on l.raceId = r.raceId
		AND l.driverId = r.driverId
        AND l.lap = r.laps
	where races.year > 1996 
		AND r.laps > 0
        AND isnull(l.position)
	order by races.date;

# check if the # of laptime records in a race for a driver matches his completed laps count
select *,
	sum(if(isnull(laptime_position),0,1)) as laptime_records,
    laps - sum(if(isnull(laptime_position),0,1)) as delta_in_laptime_records_vs_laps
   
	from (
	select races.year,
		   races.date,
           races.name,
           races.raceId,
           driverRef,
           d.driverId,
           r.grid,
           r.position as position,
#           l.lap as laptime_lap,
           l.position as laptime_position,
           r.laps
           
		from races
		join results r on r.raceId = races.raceId
		join drivers d on d.driverId = r.driverId
		left join laptimes l on l.raceId = r.raceId
			AND l.driverId = r.driverId
			AND l.lap = r.laps
		where races.year > 1996 
		order by races.date
	) query1
    group by driverId, raceId
	#order by delta_in_laptime_records_vs_laps desc
    order by date, driverRef