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