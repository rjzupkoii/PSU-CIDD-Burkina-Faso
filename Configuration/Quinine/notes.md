# Quinine Calibration Notes
---
Calibration of quinine took place using a population of 20,000 individuals with the initial parasite prevalence set at 1.3 which resulted in about 9,500 individuals being infected upon model initialization. The configuration was further modified so that all clinical cases would receive treatment.

The following code was inserted in the `Model::daily_update` function following the `data_collector_->end_of_time_step()` function:

```C++
data_collector_->perform_population_statistic();
auto clinical = 0;
for (auto ac = 0; ac < CONFIG->number_of_age_classes(); ac++) {
  clinical += data_collector_->number_of_clinical_by_location_age_group()[0][ac];
}
auto total = data_collector_->cumulative_clinical_episodes_by_location()[0];
auto positive = data_collector_->number_of_positive_by_location()[0];
VLOG(1) << "Clinical: " << clinical << ", Positive: " << positive;
VLOG(1) << "Target Positive: " << total * 0.2;
```

In the model an individual is defined as positive if they are either clinical or asymptomatic. Since the literature suggests that the success rate for quinine is between 80% and 85%, calibration was made for the more pessimistic value of an 80% success rate. This allows for a nominal accounting for drug resistance to be present, although the EC50 is still quite low. The maximum number of clinical cases is typically reached by day six of the model. Thus, day 34 was used to evaluate the efficacy. Upon completion of the calibration the following parameters were found to approximate an 80% treatment success rate across all ages 28 days after treatment:

```YAML
drug_db:
  0:
    name: "QUIN"
    half_life: 18
    maximum_parasite_killing_rate: 0.9
    n: 3
    age_specific_drug_concentration_sd: [0.4,0.4,0.4,0.4,0.4,0.4,0.4,0.4,0.4,0.4,0.4,0.4,0.4,0.4,0.4]
    mutation_probability: 0.0
    affecting_loci: []
    selecting_alleles: []
    k: 4
    EC50:
      .....: 0.44
```

## References
Achan, J., Talisuna, A. O., Erhart, A., Yeka, A., Tibenderana, J. K., Baliraine, F. N., Rosenthal, P. J., & D’Alessandro, U. (2011). Quinine, an old anti-malarial drug in a modern world: Role in the treatment of malaria. Malaria Journal, 10(1), 144. https://doi.org/10.1186/1475-2875-10-144

Na-Bangchang, K., & Karbwang, J. (2019). Pharmacology of Antimalarial Drugs, Current Anti-malarials. In P. G. Kremsner & S. Krishna (Eds.), Encyclopedia of Malaria (pp. 1–82). Springer New York. https://doi.org/10.1007/978-1-4614-8757-9_149-1

Pukrittayakamee, S., Wanwimolruk, S., Stepniewska, K., Jantra, A., Huyakorn, S., Looareesuwan, S., & White, N. J. (2003). Quinine Pharmacokinetic-Pharmacodynamic Relationships in Uncomplicated Falciparum Malaria. Antimicrobial Agents and Chemotherapy, 47(11), 3458. https://doi.org/10.1128/AAC.47.11.3458-3463.2003
