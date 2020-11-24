-- Basic monitoring query
select filename, replicateid, 
  starttime, now() - starttime as runningtime, 
  max(dayselapsed) as modeldays
from sim.replicate r
  inner join sim.configuration c on c.id = r.configurationid
  inner join sim.monthlydata md on md.replicateid = r.id
where r.endtime is null
group by filename, replicateid, starttime
order by modeldays desc

-- Count of running replicates
select c.filename, count(r.id) as replicates,
  sum(case when r.endtime is null then 1 else 0 end) as running
from sim.configuration c
  inner join sim.replicate r on r.configurationid = c.id
where c.studyid > 2
group by c.filename

-- October peaks
select dayselapsed, 
  cast(to_date('2007-1-1', 'yyyy-mm-dd') + dayselapsed*INTERVAL'1 day' as varchar) date,
  ROUND(cast(sum(population * pfpr2to10) / sum(population) as decimal), 3) as pfpr2to10,
  ROUND((sum(msd.infectedindividuals) / cast(sum(msd.population) as decimal)) * 100, 3) as pfprall
from sim.replicate r
  inner join sim.monthlydata md on md.replicateid = r.id
  inner join sim.monthlysitedata msd on msd.monthlydataid = md.id
where r.configurationid = 59797
  and dayselapsed > 4000
--  and dayselapsed in (5022, 6117, 7213, 8309, 9405, 10866)
  and cast(to_date('2007-1-1', 'yyyy-mm-dd') + dayselapsed*INTERVAL'1 day' as varchar) ~ '^....-10-.*'
group by dayselapsed
order by dayselapsed asc

-- Treatment failure comparison
-- 59797 - de novo emergence
-- 59801 - vector control
select c.id,
  md.dayselapsed, 
  sum(md.treatmentfailures) / count(md.treatmentfailures) tfaverage
from sim.configuration c
  inner join sim.replicate r on r.configurationid = c.id
  inner join sim.monthlydata md on md.replicateid = r.id
where (c.id = 59797 or c.id = 59801)
  and md.treatmentfailures != 0
group by c.id, dayselapsed
order by c.id, dayselapsed

-- Treatment failures / work in progress
select c.id,
  r.id,
  md.dayselapsed,
  md.treatmentfailures
--  avg(md.treatmentfailures) as tfaverage,
--  stddev(md.treatmentfailures) as tfstddev
from sim.configuration c
  inner join sim.replicate r on r.configurationid = c.id
  inner join sim.monthlydata md on md.replicateid = r.id
where c.studyid > 4
  and r.endtime is not null  
  and md.dayselapsed >= 4748
--group by c.id, dayselapsed
order by c.id, r.id, dayselapsed

select distinct c.id, filename 
from sim.configuration c 
  inner join sim.replicate r on r.configurationid = c.id
where c.studyid > 4
  and r.endtime is not null


-- Select country level treatment faliures
SELECT cast((regexp_matches(filename, '^(\d\.\d*)-bfa\.yml'))[1] as float) as rate,
  md.replicateid, md.dayselapsed, md.treatmentfailures
FROM sim.configuration c 
  inner join sim.replicate r on r.configurationid = c.id
  inner join sim.monthlydata md on md.replicateid = r.id
WHERE c.studyid = 18
  and md.dayselapsed > 4015

-- Query for dates
select distinct dayselapsed, to_date('2007-1-1', 'yyyy-mm-dd') + dayselapsed*INTERVAL'1 day'
from sim.monthlydata
where replicateid = 62339
order by dayselapsed desc

-- Select country level summary across all districts and studies
select cast((regexp_matches(filename, '^(\d\.\d*)-bfa\.yml'))[1] as float) as rate,
  dayselapsed,
  sum(clinicalepisodes) as clinicalepisodes,
  sum(md.treatmentfailures) as treatmentfailures,
  avg(msd.eir) as eir,
  sum(population * pfprunder5) / sum(population) as pfprunder5,
  sum(population * pfpr2to10) / sum(population) as pfpr2to10,
  sum(population * pfprall) / sum(population) as pfprall
from sim.replicate r
  inner join sim.configuration c on c.id = r.configurationid
  inner join sim.monthlydata md on md.replicateid = r.id
  inner join sim.monthlysitedata msd on msd.monthlydataid = md.id
where c.studyid = 16
  and msd.eir != 0 
  and md.treatmentfailures != 0
group by filename, dayselapsed

select cast((regexp_matches(filename, '^(\d\.\d*)-bfa\.yml'))[1] as float) as rate, 
  dayselapsed, 
  sum(msd.population) as population, 
  sum(msd.treatments) as treatments, 
  sum(msd.treatmentfailures) as treatmentfailures
from sim.configuration c
  inner join sim.replicate r on c.id = r.configurationid
  inner join sim.monthlydata md on r.id = md.replicateid
  inner join sim.monthlysitedata msd on msd.monthlydataid = md.id
where c.studyid = 16
  and md.treatmentfailures != 0
  and msd.eir != 0
group by rate, dayselapsed

-- Select country level summary genome data across all districts and studies
select cast((regexp_matches(filename, '^(\d\.\d*)-bfa\.yml'))[1] as float) as rate,
  dayselapsed,
  sum(occurrences) as occurrences,
  sum(clinicaloccurrences) as clinicaloccurrences,
  sum(occurrences0to5) as occurrences0to5,
  sum(occurrences2to10) as occurrences2to10
from sim.replicate r
  inner join sim.configuration c on c.id = r.configurationid
  inner join sim.monthlydata md on md.replicateid = r.id
  inner join sim.monthlygenomedata mgd on mgd.monthlydataid = md.id
where c.studyid = 16
group by filename, dayselapsed

-- Select country level summary with data broken down by genotype
select cast((regexp_matches(filename, '^(\d\.\d*)-bfa\.yml'))[1] as float) as rate,
  dayselapsed,
  g.name,
  sum(occurrences) as occurrences,
  sum(clinicaloccurrences) as clinicaloccurrences,
  sum(occurrences0to5) as occurrences0to5,
  sum(occurrences2to10) as occurrences2to10
from sim.replicate r
  inner join sim.configuration c on c.id = r.configurationid
  inner join sim.monthlydata md on md.replicateid = r.id
  inner join sim.monthlygenomedata mgd on mgd.monthlydataid = md.id
  inner join sim.genotype g on mgd.genomeid = g.id
where c.studyid = 16
group by filename, dayselapsed, g.name

-- Grid of resistance frequency post model burn-in
select dayselapsed, l.x, l.y,
  sum(mgd.weightedfrequency) as resistancefrequency
from sim.monthlydata md
  inner join sim.monthlygenomedata mgd on mgd.monthlydataid = md.id
  inner join sim.location l on l.id = mgd.locationid
  inner join sim.genotype g on g.id = mgd.genomeid
where md.replicateid = 62248
  and md.dayselapsed > (365 * 11)
  and g.name ~ '^.....Y..'
group by dayselapsed, x, y