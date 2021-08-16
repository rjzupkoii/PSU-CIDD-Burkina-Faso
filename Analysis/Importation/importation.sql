select sd.replicateid,
  cast((regexp_match(c.filename, '-(\d)-(\d)-([\d.]*)-(\d.\d*)'))[1] as integer) AS month,
  cast((regexp_match(c.filename, '-(\d)-(\d)-([\d.]*)-(\d.\d*)'))[2] as integer) AS imports,
  case when ((regexp_match(c.filename, '-(\d)-(\d)-([\d.]*)-(\d.\d*)'))[3] = '3.0') then 0 else 1 end AS symptomatic,
  case when ((regexp_match(c.filename, '-(\d)-(\d)-([\d.]*)-(\d.\d*)'))[4] = '0.') then 0 else 1 end AS mutations,
  sd.dayselapsed, 
  infectedindividuals, 
  clinicalepisodes, 
  case when gd.clinicaloccurrences is null then 0 else gd.clinicaloccurrences end as clinicaloccurrences,
  case when gd.weightedoccurrences is null then 0 else gd.weightedoccurrences end as weightedoccurrences
from (
  select md.replicateid, md.dayselapsed, 
    sum(msd.infectedindividuals) as infectedindividuals, 
    sum(msd.clinicalepisodes) as clinicalepisodes
  from sim.monthlydata md
    inner join sim.monthlysitedata msd on msd.monthlydataid = md.id
  where md.dayselapsed > (11 * 365)
  group by md.replicateid, md.dayselapsed) sd
left join (
  select md.replicateid, md.dayselapsed, 
    sum(mgd.clinicaloccurrences) as clinicaloccurrences,
    sum(mgd.weightedoccurrences) as weightedoccurrences
  from sim.monthlydata md
    inner join sim.monthlygenomedata mgd on mgd.monthlydataid = md.id
    inner join sim.genotype g on g.id = mgd.genomeid
  where md.dayselapsed > (11 * 365)
    and g.name ~ '^.....Y..'
  group by md.replicateid, md.dayselapsed) gd on (gd.replicateid = sd.replicateid and gd.dayselapsed = sd.dayselapsed)
inner join sim.replicate r on r.id = sd.replicateid
inner join sim.configuration c on c.id = r.configurationid
where r.endtime is not null
order by replicateid, dayselapsed
	