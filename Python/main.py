import pandas as pd
import numpy as np
from datetime import datetime
import sys
import os
import math

#Statistical LTV
from statistics import mean
from lifetimes import BetaGeoFitter, GammaGammaFitter, BetaGeoBetaBinomFitter
from lifetimes.utils import calibration_and_holdout_data, summary_data_from_transaction_data
from lifetimes.plotting import plot_probability_alive_matrix


#Evaluation
from sklearn import metrics
from sklearn.metrics import r2_score,f1_score
from sklearn.metrics import mean_absolute_error
from sklearn.metrics import mean_squared_error
from sklearn.model_selection import GridSearchCV
from sklearn.cluster import KMeans


#Plotting
import matplotlib.pyplot as plt
import seaborn as sns

# set the input & output paths
inp_path = "/mapr/mapre04p/analytics0001/analytic_users/ProductDevelopment/Lift/ACE/uogss/CLV_DEV/Python/Hellmanns_2yrPre_1yrPos"
output_path = inp_path + "/" + "clv_output_python.csv"

# Run the dataprep functions
raw_data, aggr_data = trans_dataprep(input_path)
aggr_data_outl, raw_data_outl = after_outliers(raw_data, aggr_data)
df_train, df_test, df_full = create_train_test_df(raw_data_outl)

# Run the bgbb modelling prccess
bgf, final, max_value = bgbb_model(df_train=df_train,df_test=df_test,param_start=0.001,param_end=0.1,param_steps=10,p=0,f=52,metric="f1_score")

# Run the validation process(2 years of train period and 1 year holdout)
x1,x2,x3 = validations(final)

# Run the HML segmentation using KMeans clustering
final, cluster_centers = kmeans_clustering(final)

# export the final results
final.to_csv(output_path, index = False)
