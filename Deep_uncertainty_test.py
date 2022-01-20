import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from ema_workbench import (Model, RealParameter, TimeSeriesOutcome, 
                           Constant, CategoricalParameter, 
                           IntegerParameter, perform_experiments, 
                           MultiprocessingEvaluator, ema_logging,
                           save_results)

from ema_workbench.connectors.netlogo import NetLogoModel
from ema_workbench.connectors.excel import ExcelModel

from ema_workbench.em_framework.evaluators import LHS, SOBOL, MORRIS

from ema_workbench.analysis import plotting

if __name__ == '__main__':
    ema_logging.log_to_stderr(ema_logging.INFO)

    #We can define common uncertainties and outcomes for each model:
    uncertainties = [IntegerParameter('GDP', 3, 7),
                     IntegerParameter('rainfall', 3, 7),
                     IntegerParameter('water_demand', 8, 10),
                     IntegerParameter('regulations', 5, 8)
                    ] 
    
    outcomes = [TimeSeriesOutcome('TIME'),
                TimeSeriesOutcome('average_risk_consumers'),
                TimeSeriesOutcome('average_benefit_consumers'), 
                TimeSeriesOutcome('average_risk_farmers'),
                TimeSeriesOutcome('average_benefit_farmers'),
                TimeSeriesOutcome('optimistic_consumers'),
                TimeSeriesOutcome('conflicted_consumers'),
                TimeSeriesOutcome('neutral_consumers'),
                TimeSeriesOutcome('alarmed_consumers'),
                TimeSeriesOutcome('optimistic_farmers'),
                TimeSeriesOutcome('conflicted_farmers'),
                TimeSeriesOutcome('neutral_farmers'),
                TimeSeriesOutcome('alarmed_farmers')
               ]
    
    constants = [Constant('GDP_change', '"constant"'),
                 Constant('rainfall_change', '"constant"'),
                 Constant('w_demand_change', '"constant"'),
                 Constant('regulations_change', '"constant"'),
                 Constant('trust_agri_change', '"constant"'),
                 Constant('trust_gov_change', '"constant"'),
                 Constant('know_dev_change', '"constant"'),  
                 Constant('trust_agriculture', 5),
                 Constant('trust_government', 5),
                 Constant('knowledge_dev', 5),
                 Constant('No_consumers', 100),
                 Constant('No_farmers', 20),
                 Constant('consumer_leaders', 0.10),
                 Constant('farmer_leaders', 0.10),
                 Constant('leader_influence', 7)
                ]
    
    #Define the NetLogo model
    nl_model = NetLogoModel('NetLogo', wd='./Netlogo/', 
                            model_file="Risk_benefit_model_fullSetUp.nlogo")
    
    nl_model.run_length = 1565
    nl_model.replications = 1
    nl_model.uncertainties = uncertainties
    nl_model.outcomes = outcomes
    nl_model.constants = constants
    
    nr_experiments = 10

    #Using Latin Hypercube sampling
    #experiments, outcomes = perform_experiments(nl_model, nr_experiments, 
    #                                        uncertainty_sampling=LHS)
    
    with MultiprocessingEvaluator(nl_model, n_processes=2,
                                  maxtasksperchild=4) as evaluator:
        results = evaluator.perform_experiments(nr_experiments, 
                                                uncertainty_sampling=LHS)