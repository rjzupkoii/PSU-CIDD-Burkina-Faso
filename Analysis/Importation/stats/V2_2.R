

# Pull in deata and separate by de novo, importation during low-transmission, 
#	and importation during high-transmission

setwd('')

dat.denovo = read.csv('BFA_Data/denovo_May2022.csv')
dat.low = read.csv('BFA_Data/lowtransmission_May2022.csv')
dat.high = read.csv('BFA_Data/hightransmission_May2022.csv')

dat.denovo = dat.denovo[which(!is.na(dat.denovo$DaysElapsed)), ]
dat.denovo = dat.denovo[which(dat.denovo$DaysElapsed > 11*365), ]

dat.low = dat.low[which(!is.na(dat.low$DaysElapsed)), ]
dat.low = dat.low[which(dat.low$DaysElapsed > 11*365), ]

dat.high = dat.high[which(!is.na(dat.high$DaysElapsed)), ]
dat.high = dat.high[which(dat.high$DaysElapsed > 11*365), ]




med.denovo = aggregate(dat.denovo[ , c('MedianTheta', 'MeanTheta', 'Treatments', 'ParasiteClones', 'Multiclonal', 
	'X580yUnweighted', 'X')], 
	by = list('DaysElapsed' = dat.denovo$DaysElapsed, 'ClimaticZone' = dat.denovo$ClimaticZone), FUN = mean, na.rm = TRUE)
names(med.denovo)[ncol(med.denovo)] = 'X580yMulticlonal'

med.low = aggregate(dat.low[ , c('MedianTheta', 'MeanTheta', 'Treatments', 'ParasiteClones', 'Multiclonal', 
	'X580yUnweighted', 'X580yMulticlonal')], 
	by = list('DaysElapsed' = dat.low$DaysElapsed, 'ClimaticZone' = dat.low$ClimaticZone), FUN = mean, na.rm = TRUE)
	
med.high = aggregate(dat.high[ , c('MedianTheta', 'MeanTheta', 'Treatments', 'ParasiteClones', 'Multiclonal', 
	'X580yUnweighted', 'X580yMulticlonal')], 
	by = list('DaysElapsed' = dat.high$DaysElapsed, 'ClimaticZone' = dat.high$ClimaticZone), FUN = mean, na.rm = TRUE)



# lagged correlation between theta and infections

cors.all = NULL
for (c in 0:2) {
med.denovo.s = med.high[which(med.high$ClimaticZone == c), ]
cors = NULL
for (ll in 0:12) {
	ln = nrow(med.denovo.s); lg = ll
	cc = cor(med.denovo.s$ParasiteClones[-c((ln - lg + 1):ln)], 
		c(med.denovo.s$MeanTheta[-c(1:lg)]), method = 'spearman')
		
	cors = rbind(cors, c(ll, cc))
}
cors.all = cbind(cors.all, cors)
}
cors.all


# lagged correlation between theta and treatments

cors.all = NULL
for (c in 0:2) {
med.denovo.s = med.high[which(med.high$ClimaticZone == c), ]
cors = NULL
for (ll in 0:12) {
	ln = nrow(med.denovo.s); lg = ll
	cc = cor(med.denovo.s$Treatments[-c((ln - lg + 1):ln)], 
		c(med.denovo.s$MeanTheta[-c(1:lg)]), method = 'spearman')
		
	cors = rbind(cors, c(ll, cc))
}
cors.all = cbind(cors.all, cors)
}
cors.all


	


# lagged correlation between theta and 580Y (detrended)


cors.all = NULL
for (c in 0:2) {
med.s = med.low[which(med.low$ClimaticZone == c), ]
mod = lm(log(med.s$X580yUnweighted + 0.001) ~ med.s$DaysElapsed)
y.f = fitted(mod)
cors = NULL
for (ll in 0:12) {
	ln = nrow(med.s); lg = ll
	if (lg == 0) {
		cc = cor(med.s$MeanTheta, (med.s$X580yUnweighted - exp(y.f)), method = 'spearman')
	} else {
	cc = cor((med.s$X580yUnweighted-exp(y.f))[-c((ln - lg + 1):ln)], 
#		(med.s$X580yUnweighted)[-c(1:lg)], method = 'spearman')
 		med.s$MeanTheta[-c(1:lg)], method = 'spearman')
	}
		
	cors = rbind(cors, c(ll, cc))
}
cors.all = cbind(cors.all, cors)
}
cors.all





# lagged correlation between treatments and 580Y


cors.all = NULL
for (c in 0:2) {
med.s = med.high[which(med.high$ClimaticZone == c), ]
mod = lm(log(med.s$X580yUnweighted + 0.001) ~ med.s$DaysElapsed)
y.f = fitted(mod); y.f = -1e6
cors = NULL
for (ll in 0:12) {
	ln = nrow(med.s); lg = ll
	if (lg == 0) {
		cc = cor(med.s$Treatments, (med.s$X580yUnweighted - exp(y.f)), method = 'spearman')
	} else {
	cc = cor((med.s$X580yUnweighted-exp(y.f))[-c((ln - lg + 1):ln)], 
#		(med.s$X580yUnweighted)[-c(1:lg)], method = 'spearman')
 		med.s$Treatments[-c(1:lg)], method = 'spearman')
	}
		
	cors = rbind(cors, c(ll, cc))
}
cors.all = cbind(cors.all, cors)
}
cors.all





# lagged correlation between treatments and 580Y proportion


cors.all = NULL
for (c in 0:2) {
med.s = med.high[which(med.high$ClimaticZone == c), ]
med.s$X580yMprop = med.s$X580yMulticlonal / med.s$Multiclonal
mod = lm(log(med.s$X580yMprop + 0.001) ~ med.s$DaysElapsed)
y.f = fitted(mod); y.f = -1e6
cors = NULL
for (ll in 0:12) {
	ln = nrow(med.s); lg = ll
	if (lg == 0) {
		cc = cor(med.s$Treatments, (med.s$X580yMprop - exp(y.f)), method = 'spearman')
	} else {
	cc = cor((med.s$X580yMprop-exp(y.f))[-c((ln - lg + 1):ln)], 
#		(med.s$X580yUnweighted)[-c(1:lg)], method = 'spearman')
 		med.s$Treatments[-c(1:lg)], method = 'spearman')
	}
		
	cors = rbind(cors, c(ll, cc))
}
cors.all = cbind(cors.all, cors)
}
cors.all








# lagged correlation between treatments and 580Y proportion


cors.all = NULL
for (c in 0:2) {
med.s = med.high[which(med.high$ClimaticZone == c), ]
med.s$X580yMprop = med.s$X580yMulticlonal / med.s$Multiclonal
med.s$X580yCprop = med.s$X580yUnweighted / med.s$ParasiteClones
mod = lm(log(med.s$X580yMprop + 0.001) ~ med.s$DaysElapsed)
y.f = fitted(mod); y.f = -1e6
cors = NULL
for (ll in 0:12) {
	ln = nrow(med.s); lg = ll
	if (lg == 0) {
		cc = cor(med.s$X580yCprop, (med.s$X580yMprop - exp(y.f)), method = 'spearman')
	} else {
	cc = cor((med.s$X580yMprop-exp(y.f))[-c((ln - lg + 1):ln)], 
#		(med.s$X580yUnweighted)[-c(1:lg)], method = 'spearman')
 		med.s$X580yCprop[-c(1:lg)], method = 'spearman')
	}
		
	cors = rbind(cors, c(ll, cc))
}
cors.all = cbind(cors.all, cors)
}
cors.all


