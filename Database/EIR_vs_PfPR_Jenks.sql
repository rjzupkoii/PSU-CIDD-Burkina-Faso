-- Select EIR and PfPR values by popuation and beta, these will be used to calibratoin the model.
select replicateid,
  cast(substr(filename, 4, position('-' in substr(filename, 4)) - 1) as integer) population,
  cast(replace(substr(filename, position('-' in substr(filename, 4)) + 4), '.yml', '') as float) beta,
  avg(eir) as eir, 
  avg(pfprunder5) as pfprunder5, 
  avg(pfpr2to10) as pfpr2to10, 
  avg(pfprall) as pfprall
from sim.monthlydata md 
  inner join sim.monthlysitedata msd on msd.monthlydataid = md.id
  inner join sim.replicate r on r.id = replicateid
  inner join sim.configuration c on c.id = r.configurationid
where dayselapsed > 7305 and dayselapsed < 7701
  and replicateid in (select id from v_replicates where filename ~ '^bf-((?!200))[0-9]*-[0-9.]*.yml' )
  and EIR != 0
group by replicateid, filename
order by population, pfpr2to10