-- Query to generate list of replicates that need to be run
select replace(filename, '.yml', '.pbs') as filename, 
  target - count as goal
from (
select filename, 
  symptomatic, mutations, month, imports,
  running + complete as count,
  case when mutations = 0 then 50 else 10 end as target
from (
select c.studyid, c.filename, count(r.id) as replicates,
  case when ((regexp_match(c.filename, '-(\d*)-(\d)-([\d.]*)-(\d.\d*)'))[3] = '3.0') then 0 else 1 end AS symptomatic,
  case when ((regexp_match(c.filename, '-(\d*)-(\d)-([\d.]*)-(\d.\d*)'))[4] = '0.') then 0 else 1 end AS mutations,
  cast((regexp_match(c.filename, '-(\d*)-(\d)-([\d.]*)-(\d.\d*)'))[1] as integer) AS month,
  cast((regexp_match(c.filename, '-(\d*)-(\d)-([\d.]*)-(\d.\d*)'))[2] as integer) AS imports,
  sum(case when r.endtime is null then 1 else 0 end) as running,
  sum(case when r.endtime is not null then 1 else 0 end) as complete
from sim.configuration c
  inner join sim.replicate r on r.configurationid = c.id
where c.studyid = 7
group by c.studyid, c.filename) iq) xls
where (target - count) != 0
order by mutations desc, symptomatic, month, imports


-- All 580Y genotypes
select sd.replicateid,
  cast((regexp_match(c.filename, '-(\d*)-(\d)-([\d.]*)-(\d.\d*)'))[1] as integer) AS month,
  cast((regexp_match(c.filename, '-(\d*)-(\d)-([\d.]*)-(\d.\d*)'))[2] as integer) AS imports,
  case when ((regexp_match(c.filename, '-(\d*)-(\d)-([\d.]*)-(\d.\d*)'))[3] = '3.0') then 0 else 1 end AS symptomatic,
  case when ((regexp_match(c.filename, '-(\d*)-(\d)-([\d.]*)-(\d.\d*)'))[4] = '0.') then 0 else 1 end AS mutations,
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
  where md.replicateid in (select id from v_importation_replicates)
    and md.dayselapsed > (11 * 365)
  group by md.replicateid, md.dayselapsed) sd
left join (
  select md.replicateid, md.dayselapsed, 
    sum(mgd.clinicaloccurrences) as clinicaloccurrences,
    sum(mgd.weightedoccurrences) as weightedoccurrences
  from sim.monthlydata md
    inner join sim.monthlygenomedata mgd on mgd.monthlydataid = md.id
    inner join sim.genotype g on g.id = mgd.genomeid
  where md.replicateid in (select replicateid from v_importation_replicates)
    and md.dayselapsed > (11 * 365)
    and g.name ~ '^.....Y..'
  group by md.replicateid, md.dayselapsed) gd on (gd.replicateid = sd.replicateid and gd.dayselapsed = sd.dayselapsed)
inner join sim.replicate r on r.id = sd.replicateid
inner join sim.configuration c on c.id = r.configurationid
where r.endtime is not null
order by replicateid, dayselapsed
	
-- TNY--Y1x importations only
select sd.replicateid,
  cast((regexp_match(c.filename, '-(\d*)-(\d)-([\d.]*)-(\d.\d*)'))[1] as integer) AS month,
  cast((regexp_match(c.filename, '-(\d*)-(\d)-([\d.]*)-(\d.\d*)'))[2] as integer) AS imports,
  case when ((regexp_match(c.filename, '-(\d*)-(\d)-([\d.]*)-(\d.\d*)'))[3] = '3.0') then 0 else 1 end AS symptomatic,
  case when ((regexp_match(c.filename, '-(\d*)-(\d)-([\d.]*)-(\d.\d*)'))[4] = '0.') then 0 else 1 end AS mutations,
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
  where md.dayselapsed > (11 * 365)
    and mgd.genomeid = 69
  group by md.replicateid, md.dayselapsed) gd on (gd.replicateid = sd.replicateid and gd.dayselapsed = sd.dayselapsed)
inner join sim.replicate r on r.id = sd.replicateid
inner join sim.configuration c on c.id = r.configurationid
where r.endtime is not null
order by replicateid, dayselapsed
	

-- Count of running replicates
select c.studyid, c.filename, count(r.id) as replicates,
  case when ((regexp_match(c.filename, '-(\d*)-(\d)-([\d.]*)-(\d.\d*)'))[3] = '3.0') then 0 else 1 end AS symptomatic,
  case when ((regexp_match(c.filename, '-(\d*)-(\d)-([\d.]*)-(\d.\d*)'))[4] = '0.') then 0 else 1 end AS mutations,
  cast((regexp_match(c.filename, '-(\d*)-(\d)-([\d.]*)-(\d.\d*)'))[1] as integer) AS month,
  cast((regexp_match(c.filename, '-(\d*)-(\d)-([\d.]*)-(\d.\d*)'))[2] as integer) AS imports,
  sum(case when r.endtime is null then 1 else 0 end) as running,
  sum(case when r.endtime is not null then 1 else 0 end) as complete
from sim.configuration c
  inner join sim.replicate r on r.configurationid = c.id
where c.studyid = 7
group by c.studyid, c.filename
order by symptomatic, mutations, month, imports


-- View for replicate data
CREATE OR REPLACE VIEW public.v_importation_replicates AS
SELECT iq.configurationid, iq.replicates, iq.mutations,
  CASE WHEN iq.mutations = 0::double precision THEN 50 ELSE 10 END AS target
  FROM (
    SELECT c.id AS configurationid,
      count(r.id) AS replicates,
      (regexp_match(c.filename::text, '-(\d*)-(\d)-([\d.]*)-(\d.\d*)'::text))[4]::double precision AS mutations
    FROM sim.configuration c
      JOIN sim.replicate r ON r.configurationid = c.id
    WHERE c.studyid = 7
	    AND r.endtime IS NOT NULL    
    GROUP BY c.id, c.filename
    UNION
    SELECT c.id AS configurationid,
      count(r.id) AS replicates,
      0 AS mutations
    FROM sim.configuration c
      JOIN sim.replicate r ON r.configurationid = c.id
    WHERE c.studyid = 8
	    AND r.endtime IS NOT NULL 
    GROUP BY c.id, c.filename) iq;
ALTER TABLE public.v_importation_replicates OWNER TO sim;