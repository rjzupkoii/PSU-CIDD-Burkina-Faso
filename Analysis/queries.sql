-- Clinical case data for calibration range
SELECT district,
	max(population) AS population,
	sum(cases) AS cases,
	round(sum(treatedcases) * 0.832, 0) AS reportedcases,
	round((sum(treatedcases) * 0.832) / (max(population) / 1000), 0) AS clinicalper1000,
	round(cast(sum(pfpr2to10 * population) / sum(population) as numeric), 2) AS pfpr2to10,
	round(sum(cases) / max(population), 2) as incidence_acd
FROM (
	SELECT md.dayselapsed, l.district,
		sum(msd.population) AS population,
		sum(msd.clinicalepisodes) AS cases,
		sum(msd.treatments) AS treatedcases,
		sum(msd.pfpr2to10 * msd.population) / sum(msd.population) AS pfpr2to10
	FROM sim.configuration c
		INNER JOIN sim.replicate r ON r.configurationid = c.id
		INNER JOIN sim.monthlydata md ON md.replicateid = r.id
		INNER JOIN sim.monthlysitedata msd ON msd.monthlydataid = md.id
		INNER JOIN sim.location l on l.id = msd.locationid
	WHERE r.id = 123701
	AND md.dayselapsed BETWEEN (16 * 365) AND (17 * 365)
	GROUP BY md.dayselapsed, l.district) iq
GROUP BY district
ORDER BY district

-- Orginal betas query for calibration
SELECT replicateid,
  zone, population, access, beta,
  eir, 
  CASE WHEN zone IN (0, 1) THEN max ELSE pfpr2to10 END AS pfpr,
  min, pfpr2to10, max
FROM (
  SELECT replicateid,
    filename,
    cast((regexp_matches(filename, '^(\d*)-(\d*)-([\.\d]*)-([\.\d]*)'))[1] as integer) AS zone,
    cast((regexp_matches(filename, '^(\d*)-(\d*)-([\.\d]*)-([\.\d]*)'))[2] as integer) AS population,
    cast((regexp_matches(filename, '^(\d*)-(\d*)-([\.\d]*)-([\.\d]*)'))[3] as float) AS access,
    cast((regexp_matches(filename, '^(\d*)-(\d*)-([\.\d]*)-([\.\d]*)'))[4] as float) AS beta,
    avg(eir) AS eir, 
    min(pfpr2to10) AS min, 
    avg(pfpr2to10) AS pfpr2to10, 
    max(pfpr2to10) AS max
  FROM sim.configuration c
    INNER JOIN sim.replicate r on r.configurationid = c.id
    INNER JOIN sim.monthlydata md on md.replicateid = r.id
    INNER JOIN sim.monthlysitedata msd on msd.monthlydataid = md.id
  WHERE studyid = 1
    AND md.dayselapsed >= (4352 - 366)
  GROUP BY replicateid, filename) iq
WHERE (beta = 0 and pfpr2to10 = 0) OR (beta != 0 and min != 0)       
ORDER BY zone, population, access, pfpr