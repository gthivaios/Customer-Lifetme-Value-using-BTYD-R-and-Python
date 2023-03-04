
results$last_purch <- results$Tot_Obs - results$recency
# Use last_purchase and Pr_Alive as feature selection for the kmeans clustering
input_k <- subset(results, select = c(1,7,9))
clusters <- kmeans(input_k[,2:3], 3)

results_cluster <- cbind(results, cluster = clusters$cluster)

if (pp>0) {

results_cluster_Descr <- results_cluster %>% group_by(cluster) %>% summarize(avg_freq=mean(freq),
                                                             avg_recency=mean(recency),
                                                             avg_Tot_Obs=mean(Tot_Obs),
                                                             avg_last_purch=mean(last_purch),
                                                             avg_spend=mean(spend),
                                                             sum_spend=sum(spend),
                                                             avg_exp_trips_inf=mean(Exp_trans),
                                                             avg_clv_inf=mean(PFCS),
                                                             sum_exp_trips_inf=sum(Exp_trans),
                                                             sum_clv_inf=sum(PFCS),
                                                             min_rr=min(Pr_Alive),
                                                             max_rr=max(Pr_Alive),
                                                             avg_rr=mean(Pr_Alive),
                                                             count_HH=n_distinct(cust))
} else {
results_cluster_Descr <- results_cluster %>% group_by(cluster) %>% summarize(avg_freq=mean(freq),
                                                             avg_recency=mean(recency),
                                                             avg_Tot_Obs=mean(Tot_Obs),
                                                             avg_last_purch=mean(last_purch),
                                                             avg_spend=mean(spend),
                                                             sum_spend=sum(spend),
                                                             avg_exp_trips_inf=mean(exp_trips),
                                                             avg_clv_inf=mean(CLV_Inf),
                                                             sum_exp_trips_inf=sum(exp_trips),
                                                             sum_clv_inf=sum(CLV_Inf),
                                                             min_rr=min(p_alive),
                                                             max_rr=max(p_alive),
                                                             avg_rr=mean(p_alive),
                                                             count_HH=n_distinct(cust))}

results_cluster_Descr <- results_cluster_Descr %>% arrange(avg_rr)

fwrite(results_cluster_Descr,paste0(thisPath,"/Final_CLV_Segments_Descr.csv"),col.names=T)
fwrite(results_cluster,paste0(thisPath,"/Final_CLV_Segments.csv"),col.names=T)
