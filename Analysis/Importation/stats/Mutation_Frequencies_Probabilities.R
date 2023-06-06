
library(stats)


setwd('')

# Pull in data, retain necessary observations for analysis

dat0 = read.csv('BFA_Data/bfa-merged 1.csv')

dat = NULL
ids = unique(dat0$replicateid)
for (i in 1:length(ids)) {
	
	temp = dat0[which(dat0$replicateid == ids[i]), ]
	temp = temp[which(temp$dayselapsed == max(temp$dayselapsed)), ]
	dat = rbind(dat, temp)
	
}
dat = dat[which(dat$mutations == 0), ]

####
# 1. Differences in 580Y Frequency across months of importation
####

compare.months.within = function(dat.subset) {
	
	# calculate frequencies of 580Y, identify high-transmission months
	dat.subset$freq580y = dat.subset$weightedoccurrences / dat.subset$infectedindividuals
	dat.subset$freq580y[which(dat.subset$freq580y == 0)] = 1e-8
	dat.subset$freq580y = log(dat.subset$freq580y, base = 10)
	dat.subset$ht.month = 1 * (dat.subset$month %in% c(6:10))
	
	# Perform kruskal wallis test for differences among all months
	k.w = kruskal.test(freq580y ~ as.factor(month), data = dat.subset)
	
	# Wilcoxon rank-sum tests for pairs of months
	# Differences in frequencies across pairs of months
	
	wilcoxon.table.W = matrix(NA, nrow = 12, ncol = 12)
	rownames(wilcoxon.table.W) = colnames(wilcoxon.table.W) = c(1:12)
	wilcoxon.table.p = wilcoxon.table.W
	freq.diff = wilcoxon.table.W
	freqs = rep(NA, 12)
	
	for (i in 1:11) {
		for (j in (i+1):12) {
			wilcoxon.table.W[i, j] = wilcoxon.table.W[j, i] = 
				wilcox.test(freq580y ~ as.factor(month), 
				data = dat.subset[which(dat.subset$month %in% c(i, j)), ])$statistic
				
			wilcoxon.table.p[i, j] = wilcoxon.table.p[j, i] = 
				wilcox.test(freq580y ~ as.factor(month), 
				data = dat.subset[which(dat.subset$month %in% c(i, j)), ])$p.value
			freq.diff[i, j] = freq.diff[j, i] = 
				max(mean(10^(dat.subset$freq580y[which(dat.subset$month == i)])) - 
				mean(10^(dat.subset$freq580y[which(dat.subset$month == j)])), 
				mean(10^(dat.subset$freq580y[which(dat.subset$month == j)])) - 
				mean(10^(dat.subset$freq580y[which(dat.subset$month == i)])))
		}
		
	}
	
	for (i in 1:12) {
		freqs[i] = mean(10^(dat.subset$freq580y[which(dat.subset$month == i)]))
	}
	
		
	out = list('k.w' = k.w, 'wilcoxon_stat' = wilcoxon.table.W, 'wilcoxon_p' = wilcoxon.table.p, 
		'wilcoxon_seas' = wilcox.test(freq580y ~ ht.month, data = dat.subset), 
		'freq.diff' = freq.diff, 'freqs' = freqs)
	
	return(out)
	
}


# 1 per month, asymptomatic
dat.1.a = dat[which(dat$imports == 1 & dat$symptomatic == 0), ]
kw1a = compare.months.within(dat.1.a)

# 3 per month, asymptomatic
dat.3.a = dat[which(dat$imports == 3 & dat$symptomatic == 0), ]
kw3a = compare.months.within(dat.3.a)

# 6 per month, asymptomatic
dat.6.a = dat[which(dat$imports == 6 & dat$symptomatic == 0), ]
kw6a = compare.months.within(dat.6.a)

# 9 per month, asymptomatic
dat.9.a = dat[which(dat$imports == 9 & dat$symptomatic == 0), ]
kw9a = compare.months.within(dat.9.a)


# 1 per month, symptomatic
dat.1.s = dat[which(dat$imports == 1 & dat$symptomatic == 1), ]
kw1s = compare.months.within(dat.1.s)

# 3 per month, symptomatic
dat.3.s = dat[which(dat$imports == 3 & dat$symptomatic == 1), ]
kw3s = compare.months.within(dat.3.s)

# 6 per month, symptomatic
dat.6.s = dat[which(dat$imports == 6 & dat$symptomatic == 1), ]
kw6s = compare.months.within(dat.6.s)

# 9 per month, symptomatic
dat.9.s = dat[which(dat$imports == 9 & dat$symptomatic == 1), ]
kw9s = compare.months.within(dat.9.s)









# Combine differences in frequency 
# Separate by whether the pair of months was in the same or different transmission seasons (hi/low)
diff.pairs.seas = function(diff.tab) {
	
	diffs.within = NULL
	diffs.across = NULL
	
	for (i in 1:nrow(diff.tab)) {
		for (j in i:ncol(diff.tab)) {
			if (i %in% c(6:10) && j %in% c(6:10)) {
				diffs.within = c(diffs.within, diff.tab[i, j])
			} else if (i %in% c(1:5, 11:12) && j %in% c(1:5, 11:12)) {
				diffs.within = c(diffs.within, diff.tab[i, j])
			} else {
				diffs.across = c(diffs.across, diff.tab[i, j])
			}
		}
	}
	
	diffs.within = diffs.within[which(!is.na(diffs.within))]
	
	return(list('diffs.within' = diffs.within, 'diffs.across' = diffs.across))
	
}

d.1.a = diff.pairs.seas(kw1a$freq.diff)
d.3.a = diff.pairs.seas(kw3a$freq.diff)
d.6.a = diff.pairs.seas(kw6a$freq.diff)
d.9.a = diff.pairs.seas(kw9a$freq.diff)

d.1.s = diff.pairs.seas(kw1s$freq.diff)
d.3.s = diff.pairs.seas(kw3s$freq.diff)
d.6.s = diff.pairs.seas(kw6s$freq.diff)
d.9.s = diff.pairs.seas(kw9s$freq.diff)

mean(c(d.1.a[[1]], d.3.a[[1]], d.6.a[[1]], d.9.a[[1]], d.1.s[[1]], d.3.s[[1]], d.6.s[[1]], d.9.s[[1]]))
mean(c(d.1.a[[2]], d.3.a[[2]], d.6.a[[2]], d.9.a[[2]], d.1.s[[2]], d.3.s[[2]], d.6.s[[2]], d.9.s[[2]]))



####
# 2. Difference in (a)symptomatic within months
####

sympt.month.W = matrix(NA, nrow = 4, ncol = 12)
rownames(sympt.month.W) = c(1, 3 * c(1:3)); colnames(sympt.month.W) = c(1:12)
sympt.month.p = sympt.month.W

for (i in 1:nrow(sympt.month.W)) {
	for (j in 1:ncol(sympt.month.W)) {
		
#		temp = dat[which(dat$imports == (i*3) & dat$month == j), ]
		temp = dat[which(dat$imports == as.numeric(rownames(sympt.month.W)[i]) & dat$month == j), ]
		temp$freq580y = temp$weightedoccurrences / temp$infectedindividuals
		temp$freq580y[which(temp$freq580y == 0)] = 1e-8
		temp$freq580y = log(temp$freq580y, base = 10)
		
		test = wilcox.test(freq580y ~ symptomatic, data = temp)
		sympt.month.W[i, j] = test$statistic; sympt.month.p[i, j] = test$p.value
		
	}
}



####
# 3. Difference in Prob Establishment (freq > 10^-3) between months
#### 

compare.months.probest = function(dat.subset) {
	
	dat.subset$freq580y = dat.subset$weightedoccurrences / dat.subset$infectedindividuals
	dat.subset$freq580y[which(dat.subset$freq580y == 0)] = 1e-8
	dat.subset$freq580y = log(dat.subset$freq580y, base = 10)
	dat.subset$estab = 1 * (dat.subset$freq580y >= -3)
	dat.subset$ht.month = 1 * (dat.subset$month %in% c(6:10))
	
	est.vec = NULL; tot.vec = NULL
	for (i in 1:12) {
		est.vec = c(est.vec, sum(dat.subset$estab[dat.subset$month == i]))
		tot.vec = c(tot.vec, sum(dat.subset$month == i))
	}
	test = prop.test(est.vec, tot.vec)
	not.vec = tot.vec - est.vec
	
	
	prop.table.X2 = matrix(NA, nrow = 12, ncol = 12)
	rownames(prop.table.X2) = colnames(prop.table.X2) = c(1:12)
	prop.table.p = prop.table.X2
	
	for (i in 1:11) {
		for (j in (i+1):12) {
			
			# test.i = prop.test(est.vec[c(i, j)], tot.vec[c(i, j)])
			chsq = sum((est.vec[c(i, j)] - mean(est.vec[c(i, j)]))^2) / mean(est.vec[c(i, j)]) + 
				sum((not.vec[c(i, j)] - mean(not.vec[c(i, j)]))^2) / mean(not.vec[c(i, j)])
			
			prop.table.X2[i, j] = prop.table.X2[j, i] = chsq # test.i$statistic	
			prop.table.p[i, j] = prop.table.p[j, i] = 1 - pchisq(chsq, df = 1) # test.i$p.value

		}
	}
	
	prop.seas = prop.test(c(sum(est.vec[c(6:10)]), sum(est.vec[-c(6:10)])), 
		c(sum(tot.vec[c(6:10)]), sum(tot.vec[-c(6:10)])))
		
	out = list('proportion.global.test' = test, 'prop_stat' = prop.table.X2, 'prop_p' = prop.table.p, 
		'prop_seas' = prop.seas)
	
	return(out)
	
}


# 1 per month, asymptomatic
dat.1.a = dat[which(dat$imports == 1 & dat$symptomatic == 0), ]
p1a = compare.months.probest(dat.1.a)

# 3 per month, asymptomatic
dat.3.a = dat[which(dat$imports == 3 & dat$symptomatic == 0), ]
p3a = compare.months.probest(dat.3.a)

# 6 per month, asymptomatic
dat.6.a = dat[which(dat$imports == 6 & dat$symptomatic == 0), ]
p6a = compare.months.probest(dat.6.a)

# 9 per month, asymptomatic
dat.9.a = dat[which(dat$imports == 9 & dat$symptomatic == 0), ]
p9a = compare.months.probest(dat.9.a)

# 1 per month, symptomatic
dat.1.s = dat[which(dat$imports == 1 & dat$symptomatic == 1), ]
p1s = compare.months.probest(dat.1.s)

# 3 per month, symptomatic
dat.3.s = dat[which(dat$imports == 3 & dat$symptomatic == 1), ]
p3s = compare.months.probest(dat.3.s)

# 6 per month, symptomatic
dat.6.s = dat[which(dat$imports == 6 & dat$symptomatic == 1), ]
p6s = compare.months.probest(dat.6.s)

# 9 per month, symptomatic
dat.9.s = dat[which(dat$imports == 9 & dat$symptomatic == 1), ]
p9s = compare.months.probest(dat.9.s)






####
# 4. Difference in P(est) by (a)symptomatic within months 
####


# Chi squared tests for proportions

est.sympt.month.X2 = matrix(NA, nrow = 4, ncol = 12)
rownames(est.sympt.month.X2) = c(1, 3 * c(1:3)); colnames(est.sympt.month.X2) = c(1:12)
est.sympt.month.p = est.sympt.month.X2

for (i in 1:nrow(est.sympt.month.X2)) {
	for (j in 1:ncol(est.sympt.month.X2)) {
		
		temp = dat[which(dat$imports == as.numeric(rownames(est.sympt.month.X2)[i]) & dat$month == j), ]
		temp$freq580y = temp$weightedoccurrences / temp$infectedindividuals
		temp$freq580y[which(temp$freq580y == 0)] = 1e-8
		temp$freq580y = log(temp$freq580y, base = 10)
		temp$estab = 1 * (temp$freq580y >= -3)
		
		est = c(sum(temp$estab[which(temp$symptomatic == 0)]), 
			sum(temp$estab[which(temp$symptomatic == 1)]))
		not = c(sum(temp$symptomatic == 0), sum(temp$symptomatic == 1)) - est
		est.sympt.month.X2[i, j] = sum((est - mean(est))^2 / mean(est)) + sum((not - mean(not))^2 / mean(not))
		est.sympt.month.p[i, j] = 1 - pchisq(est.sympt.month.X2[i, j], df = 1)
		
	}
}


###
# 5. P(est) by number of importations
###

compare.imports.probtest = function(dat.subset) {
	
	dat.subset$freq580y = dat.subset$weightedoccurrences / dat.subset$infectedindividuals
	dat.subset$freq580y[which(dat.subset$freq580y == 0)] = 1e-8
	dat.subset$freq580y = log(dat.subset$freq580y, base = 10)
	dat.subset$estab = 1 * (dat.subset$freq580y >= -3)
	dat.subset$ht.month = 1 * (dat.subset$month %in% c(6:10))
	
	est.vec = NULL; tot.vec = NULL
	for (i in c(1, 3, 6, 9)) {
		est.vec = c(est.vec, sum(dat.subset$estab[dat.subset$imports == i]))
		tot.vec = c(tot.vec, sum(dat.subset$imports == i))
	}
	test = prop.test(est.vec, tot.vec)
	not.vec = tot.vec - est.vec
	
	
	prop.table.X2 = matrix(NA, nrow = 4, ncol = 4)
	rownames(prop.table.X2) = colnames(prop.table.X2) = c(1, 3, 6, 9)
	prop.table.p = prop.table.X2
	
	for (i in 1:3) {
		for (j in (i+1):4) {
			
			# test.i = prop.test(est.vec[c(i, j)], tot.vec[c(i, j)])
			chsq = sum((est.vec[c(i, j)] - mean(est.vec[c(i, j)]))^2) / mean(est.vec[c(i, j)]) + 
				sum((not.vec[c(i, j)] - mean(not.vec[c(i, j)]))^2) / mean(not.vec[c(i, j)])
			
			prop.table.X2[i, j] = prop.table.X2[j, i] = chsq # test.i$statistic	
			prop.table.p[i, j] = prop.table.p[j, i] = 1 - pchisq(chsq, df = 1) # test.i$p.value

		}
	}
		
	out = list('proportion.global.test' = test, 'prop_stat' = prop.table.X2, 'prop_p' = prop.table.p)
	
	return(out)
	
}

compare.imports.probtest(dat)

compare.imports.probtest(dat[dat$symptomatic == 0, ])
compare.imports.probtest(dat[dat$symptomatic == 1, ])




