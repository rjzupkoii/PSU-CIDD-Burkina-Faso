-- Query to get infections, weighted 580Y, and 580Y frequency
select infection.*, mutation.weighted_580y, 
  round((cast(infection.treatments as decimal) / infection.clinicalepisodes) * 100.0, 2) as percent_treated,
  mutation.weighted_580y / infection.infectedindividuals as frequency
from (
	select c.filename, r.id, md.dayselapsed, msd.infectedindividuals, msd.clinicalepisodes, msd.treatments
	from sim.configuration c
		inner join sim.replicate r on r.configurationid = c.id
		inner join sim.monthlydata md on md.replicateid = r.id
		inner join sim.monthlysitedata msd on msd.monthlydataid = md.id
	where c.studyid = 10
	  and r.starttime > '2023-05-01'
	  and md.dayselapsed > (11 * 365) and md.dayselapsed < (21 * 365)) infection
inner join (
	select c.filename, r.id, md.dayselapsed, sum(mgd.weightedoccurrences) weighted_580y
	from sim.configuration c
		inner join sim.replicate r on r.configurationid = c.id
		inner join sim.monthlydata md on md.replicateid = r.id
		inner join sim.monthlygenomedata mgd on mgd.monthlydataid = md.id
	where c.studyid = 10
	  and r.starttime > '2023-05-01'
	  and md.dayselapsed > (11 * 365) and md.dayselapsed < (21 * 365)
	  and mgd.genomeid in (2, 3,  6, 7,  10, 11,  14, 15, 18, 19, 22, 23, 26, 27, 30, 31, 34, 35, 38, 39, 42, 43, 46, 47, 50, 51, 54, 55, 58, 59, 62, 63)
	group by c.filename, r.id, md.dayselapsed) mutation 
on mutation.filename = infection.filename and mutation.id = infection.id and mutation.dayselapsed = infection.dayselapsed
order by infection.filename, infection.id, infection.dayselapsed