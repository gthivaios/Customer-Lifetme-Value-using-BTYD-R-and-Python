
def week_to_date(week):
    d = week*7+29100
    ndate = pd.to_datetime(d, unit='D', origin='1899-12-30').date()
    return(ndate)

def find_outliers_IQR(df):
   q1=df.quantile(0.25)
   q3=df.quantile(0.75)
   IQR=q3-q1
   outliers = df[((df<(q1-3.5*IQR)) | (df>(q3+3.5*IQR)))]
   outliers = outliers.to_frame().reset_index()
   return outliers

def trans_dataprep(folder_path):
    input_path = folder_path + "/" + "trans_input_clv.csv"
    df_input = pd.read_csv(input_path,engine='python')
    df2 = df_input[['cust','iri_week','spend']]
    df3 = df2.groupby(['cust','iri_week']).mean().reset_index()
    df3['date'] = df3['iri_week'].apply(iriweek_to_date)
    df3['T_cal']=max(df3['date'])
    T_cal = df3['date'].max()
    total_rev = df3.groupby('cust')['spend'].mean().rename('monetary')
    recency = ((df3.groupby('cust')['date'].max() - df3.groupby('cust')['date'].min())/7).apply(lambda x: x.days).rename('recency')
    frequency = (df3.groupby('cust')['cust'].count()-1).rename('frequency')
    t = ((T_cal- df3.groupby('cust')['date'].min())/7).apply(lambda x: x.days).rename('T')
    train_data = pd.DataFrame(index = frequency.index)
    train_data = train_data.join([frequency, recency, t, total_rev])
    return df3, train_data

def after_outliers(df3, train_data):
    outliers=[]
    for col in ['frequency','monetary']:
        df=train_data[col]
        outlier=find_outliers_IQR(df)
        outliers.append(outlier)
    outl_freq = outliers[0]['cust'].values
    outl_monet = outliers[1]['cust'].values
    outl_freq = set(outl_freq)
    outl_monet = set(outl_monet)
    outl_all = outl_freq.union(outl_monet)
    list_of_οutliers = list(outl_all)
    train_data = train_data.reset_index()
    train_data_wo_outliers = train_data[~train_data.cust.isin(list_of_οutliers)]
    df3_wo_outliers = df3[~df3.cust.isin(list_of_οutliers)]
    return train_data_wo_outliers, df3_wo_outliers

def create_train_test_df(raw_data_outl):
    raw_data_outl_train = raw_data_outl[raw_data_outl['iri_week'] <=  max(raw_data_outl['iri_week'])-52]
    raw_data_outl_test = raw_data_outl[raw_data_outl['iri_week'] >  max(raw_data_outl['iri_week'])-52]
    # rfm fro train dataset
    T_cal = raw_data_outl_train['date'].max()
    total_rev = raw_data_outl_train.groupby('cust')['spend'].mean().rename('monetary')
    recency = ((raw_data_outl_train.groupby('cust')['date'].max() - raw_data_outl.groupby('cust')['date'].min())/7).apply(lambda x: x.days).rename('recency')
    frequency = (raw_data_outl_train.groupby('cust')['cust'].count()-1).rename('frequency')
    t = ((T_cal- raw_data_outl_train.groupby('cust')['date'].min())/7).apply(lambda x: x.days).rename('T')
    df_train = pd.DataFrame(index = frequency.index)
    df_train = df_train.join([frequency, recency, t, total_rev])
    # rfm for the full dataset
    T_cal_full = raw_data_outl['date'].max()
    total_rev_full = raw_data_outl.groupby('cust')['spend'].mean().rename('monetary')
    recency_full = ((raw_data_outl.groupby('cust')['date'].max() - raw_data_outl_train.groupby('cust')['date'].min())/7).apply(lambda x: x.days).rename('recency')
    frequency_full = (raw_data_outl.groupby('cust')['cust'].count()-1).rename('frequency')
    t_full = ((T_cal_full- raw_data_outl.groupby('cust')['date'].min())/7).apply(lambda x: x.days).rename('T')
    df_full = pd.DataFrame(index = frequency_full.index)
    df_full = df_full.join([frequency_full, recency_full, t_full, total_rev_full])

    aggr_data_outl_test = raw_data_outl_test.groupby(['cust','iri_week']).mean().reset_index()
    df_test = aggr_data_outl_test.groupby('cust')['cust'].count().rename('actual_trips').reset_index()
    return df_train, df_test, df_full

# GridSearch CV
def bgbb_model(df_train,df_test,param_start,param_end,param_steps,p,f,metric):
    train_data_wo_outliers_n = df_train.groupby(['frequency', 'recency', 'T']).size().rename('n_custs').reset_index()
    bgf = BetaGeoBetaBinomFitter(penalizer_coef=0.001)
    param_list = []
    index_list = []
    score_list = []
    param_range = np.linspace(param_start,param_end,param_steps)
    for idx,param in enumerate(param_range):
        bgf = BetaGeoBetaBinomFitter(penalizer_coef=param)
        #param_grid = {"penalizer_coef":param_list}
        #GridSearch_Model = GridSearchCV(bgf,param_list)
        bgf.fit(train_data_wo_outliers_n['frequency'], train_data_wo_outliers_n['recency'], train_data_wo_outliers_n['T'], train_data_wo_outliers_n['n_custs'])
        df_train['prob_alive'] = bgf.conditional_probability_alive(
        p,
        df_train['frequency'],
        df_train['recency'],
        df_train['T'])
        df_train['exp_trips'] = bgf.conditional_expected_number_of_purchases_up_to_time(
        f,
        df_train['frequency'],
        df_train['recency'],
        df_train['T'])
        final_train = df_train
        final = final_train.merge(df_test, on='cust', how='left')
        final['actual_trips'] = final['actual_trips'].fillna(0)
        final['CLV'] = final['monetary']*final['exp_trips']
        if metric=="f1_score":
            #pred_trips = final['exp_trips']
            #true_trips = final['actual_trips']
            true_trips = np.where(final['actual_trips']>0,1,0)
            pred_trips = np.where(final['exp_trips']>0.5,1,0)
            score = f1_score(true_trips,pred_trips)
            print(score,param)
            param_list.append(param)
            score_list.append(score)
        elif metric=="rmse":
            pred_trips = final['exp_trips']
            true_trips = final['actual_trips']
            MSE = mean_squared_error(final['actual_trips'], final['exp_trips'])
            RMSE = math.sqrt(MSE)
            nRMSE = -RMSE
            print(RMSE,param)
            param_list.append(param)
            score_list.append(nRMSE)
    max_value = max(score_list)
    max_index = score_list.index(max_value)
    best_coef = param_list[max_index]
    print("the best f1 score is:", max_value)
    print("the best param is:", best_coef)
    return bgf, final, max_value

def validations(final):
    results_freq = final.groupby('frequency').agg(
        {
            'exp_trips': mean,
            'actual_trips': mean,
            'cust': 'count'
        }).reset_index()
    results_rec = final.groupby('recency').agg(
        {
            'exp_trips': mean,
            'actual_trips': mean,
            'cust': 'count'
        }).reset_index()
    results_rec = final.groupby('recency').agg(
        {
            'exp_trips': mean,
            'actual_trips': mean,
            'cust': 'count'
        }).reset_index()
    freq_distr = results_freq.plot(x="frequency", y=["exp_trips", "actual_trips"], kind="line", figsize=(9, 4))
    plt.show()
    rec_distr = results_rec.plot(x="recency", y=["exp_trips", "actual_trips"], kind="line", figsize=(9, 4))
    plt.show()
    R = final['recency'].values
    PA = final['prob_alive'].values
    FR = final['frequency'].values
    palive_plot = plt.scatter(R,FR,marker='^',c=PA,s=20)
    plt.show()
    return freq_distr, rec_distr, palive_plot

def kmeans_clustering(final):
    # initialize object
    cluster_model = KMeans(n_clusters=3)
    Train_CLV = final['CLV'].values
    cluster_model.fit(Train_CLV)
    final['cluster'] = cluster_model.labels_
    return final, cluster_model.cluster_centers_
