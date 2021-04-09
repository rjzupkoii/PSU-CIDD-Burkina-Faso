-- Clinical case data for calibration range
SELECT district,
	max(population) AS population,
	sum(cases) AS cases,
	round(sum(treatedcases) * 0.832, 0) AS reportedcases,
	round((sum(treatedcases) * 0.832) / (max(population) / 1000), 0) AS clinicalper1000,
	round(cast(sum(pfpr2to10 * population) / sum(population) as numeric), 2) AS pfpr2to10
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
	WHERE r.id = 113895
	AND md.dayselapsed BETWEEN (11 * 365) AND (12 * 365)
	GROUP BY md.dayselapsed, l.district) iq
GROUP BY district
ORDER BY district