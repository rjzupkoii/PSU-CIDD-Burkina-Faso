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
group by filename, dayselapsed

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