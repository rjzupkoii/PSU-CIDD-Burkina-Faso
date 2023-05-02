-- Query to get infections, weighted 580Y, and 580Y frequency
select infections.*, mutation.weighted_580y, mutation.weighted_580y / infections.infections as frequency
from (select c.filename, r.id, md.dayselapsed, sum(msd.infectedindividuals) infections
from sim.configuration c
  inner join sim.replicate r on r.configurationid = c.id
  inner join sim.monthlydata md on md.replicateid = r.id
  inner join sim.monthlysitedata msd on msd.monthlydataid = md.id
where c.studyid = 10
  and r.starttime > '2023-05-01'
  and md.dayselapsed > (11 * 365)
group by c.filename, r.id, md.dayselapsed) infections
inner join (
select c.filename, r.id, md.dayselapsed, sum(mgd.weightedoccurrences) weighted_580y
 from sim.configuration c
   inner join sim.replicate r on r.configurationid = c.id
   inner join sim.monthlydata md on md.replicateid = r.id
   inner join sim.monthlygenomedata mgd on mgd.monthlydataid = md.id
   inner join sim.genotype g on g.id = mgd.genomeid
 where c.studyid = 10
   and r.starttime > '2023-05-01'
   and md.dayselapsed > (11 * 365)
   and g.name ~ '^.....Y..'
 group by c.filename, r.id, md.dayselapsed) mutation on mutation.filename = infections.filename
   and mutation.id = infections.id
   and mutation.dayselapsed = infections.dayselapsed
order by infections.filename, infections.id, infections.dayselapsed