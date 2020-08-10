SELECT replicateid,
  filename,
  cast((regexp_matches(filename, '^(\d*)-(\d*)-([\.\d]*)-([\.\d]*)'))[1] as integer) AS zone,
  cast((regexp_matches(filename, '^(\d*)-(\d*)-([\.\d]*)-([\.\d]*)'))[2] as integer) AS population,
  cast((regexp_matches(filename, '^(\d*)-(\d*)-([\.\d]*)-([\.\d]*)'))[3] as float) AS access,
  cast((regexp_matches(filename, '^(\d*)-(\d*)-([\.\d]*)-([\.\d]*)'))[4] as float) AS beta,
  avg(eir) AS eir, 
  avg(pfprunder5) AS pfprunder5, 
  avg(pfpr2to10) AS pfpr2to10, 
  avg(pfprall) AS pfprall
FROM sim.configuration c
  INNER JOIN sim.replicate r on r.configurationid = c.id
  INNER JOIN sim.monthlydata md on md.replicateid = r.id
  INNER JOIN sim.monthlysitedata msd on msd.monthlydataid = md.id
WHERE studyid = 8
  AND md.dayselapsed >= 3987
GROUP BY replicateid, filename
ORDER BY zone, population, access, pfpr2to10