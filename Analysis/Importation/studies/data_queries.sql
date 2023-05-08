-- Query to get infections, weighted 580Y, AND 580Y frequency for a single cell
SELECT infection.*, 
  coalesce(mutation.weighted_580y, 0) as weighted_580y,
  coalesce(round((cast(infection.treatments as decimal) / infection.clinicalepisodes) * 100.0, 2), 0) AS percent_treated,
  coalesce(mutation.weighted_580y / infection.infectedindividuals, 0) AS frequency
FROM (
	SELECT c.filename, r.id, md.dayselapsed, msd.infectedindividuals, msd.clinicalepisodes, msd.treatments, msd.pfpr2to10
	FROM sim.configuration c
		INNER JOIN sim.replicate r ON r.configurationid = c.id
		INNER JOIN sim.monthlydata md ON md.replicateid = r.id
		INNER JOIN sim.monthlysitedata msd ON msd.monthlydataid = md.id
	WHERE c.studyid = 10
	  AND r.starttime > '2023-05-02 12:00'
	  AND md.dayselapsed > (11 * 365)) infection
LEFT JOIN (
	SELECT c.filename, r.id, md.dayselapsed, sum(mgd.weightedoccurrences) weighted_580y
	FROM sim.configuration c
		INNER JOIN sim.replicate r ON r.configurationid = c.id
		INNER JOIN sim.monthlydata md ON md.replicateid = r.id
		INNER JOIN sim.monthlygenomedata mgd ON mgd.monthlydataid = md.id
	WHERE c.studyid = 10
	  AND r.starttime > '2023-05-02'
	  AND md.dayselapsed > (11 * 365)
	  AND mgd.genomeid IN (2, 3,  6, 7,  10, 11,  14, 15, 18, 19, 22, 23, 26, 27, 30, 31, 34, 35, 38, 39, 42, 43, 46, 47, 50, 51, 54, 55, 58, 59, 62, 63)
	GROUP BY c.filename, r.id, md.dayselapsed) mutation 
ON mutation.filename = infection.filename AND mutation.id = infection.id AND mutation.dayselapsed = infection.dayselapsed
ORDER BY infection.filename, infection.id, infection.dayselapsed

-- Query to get infections, weighted 580Y, AND 580Y frequency for multi-grid configurations
SELECT infection.*, 
  coalesce(mutation.weighted_580y, 0) as weighted_580y,
  coalesce(round((cast(infection.treatments as decimal) / infection.clinicalepisodes) * 100.0, 2), 0) AS percent_treated,
  coalesce(mutation.weighted_580y / infection.infectedindividuals, 0) AS frequency
FROM (
	SELECT c.filename, r.id, md.dayselapsed, 
		sum(msd.infectedindividuals) as infectedindividuals,
		sum(msd.clinicalepisodes) as clinicalepisodes,
		sum(msd.treatments) as treatments,
		sum(msd.pfpr2to10) as pfpr2to10
	FROM sim.configuration c
		INNER JOIN sim.replicate r ON r.configurationid = c.id
		INNER JOIN sim.monthlydata md ON md.replicateid = r.id
		INNER JOIN sim.monthlysitedata msd ON msd.monthlydataid = md.id
	WHERE c.studyid = 10
	  AND r.starttime > '2023-05-04 12:00'
	  AND md.dayselapsed > (11 * 365)
	GROUP BY c.filename, r.id, md.dayselapsed) infection
LEFT JOIN (
	SELECT c.filename, r.id, md.dayselapsed, sum(mgd.weightedoccurrences) weighted_580y
	FROM sim.configuration c
		INNER JOIN sim.replicate r ON r.configurationid = c.id
		INNER JOIN sim.monthlydata md ON md.replicateid = r.id
		INNER JOIN sim.monthlygenomedata mgd ON mgd.monthlydataid = md.id
	WHERE c.studyid = 10
	  AND r.starttime > '2023-05-04 12:00'
	  AND md.dayselapsed > (11 * 365)
	  AND mgd.genomeid IN (2, 3,  6, 7,  10, 11,  14, 15, 18, 19, 22, 23, 26, 27, 30, 31, 34, 35, 38, 39, 42, 43, 46, 47, 50, 51, 54, 55, 58, 59, 62, 63)
	GROUP BY c.filename, r.id, md.dayselapsed) mutation 
ON mutation.filename = infection.filename AND mutation.id = infection.id AND mutation.dayselapsed = infection.dayselapsed
ORDER BY infection.filename, infection.id, infection.dayselapsed