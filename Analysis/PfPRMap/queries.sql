
-- Weighted average for bounded model calibration
select cast(substr(filename, 9, 4) as float) scaling,
  dayselapsed,
  district,
  avg(msd.eir) as eir,
  sum(population * pfprunder5) / sum(population) as pfprunder5,
  sum(population * pfpr2to10) / sum(population) as pfpr2to10,
  sum(population * pfprall) / sum(population) as pfprall
from sim.replicate r
  inner join sim.configuration c on c.id = r.configurationid
  inner join sim.monthlydata md on md.replicateid = r.id
  inner join sim.monthlysitedata msd on msd.monthlydataid = md.id
  inner join sim.location l on l.id = msd.locationid
where c.studyid = 7 and eir != 0
  and filename like '%-bfa-2.yml'
group by filename, district, dayselapsed