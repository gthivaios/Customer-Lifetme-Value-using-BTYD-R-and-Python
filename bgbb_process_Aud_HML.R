# Change colnames
#colnames(input)[1] <- "cust"
#colnames(input)[2] <- "iri_week"
#colnames(input)[3] <- "spend"

#input <- elog[ which(elog$iri_week < start_week), ]

message("Succesfull load!")

message("\nCount of transactions before outliers:\n", nrow(input))
message("\nCount of distinct HHs before outliers:\n", length(unique(input$cust)))

# Function which transforms the iri_week to specific date bases on IRI date encoding
iriweek_to_date <- function(iri_week) {
  d <- iri_week*7+29100
  ndate <- as.Date(d, origin = "1899-12-30")
  return(ndate)
}

# Dataprep function

Data_prep <- function(input) {
  input <- data.table(input)
  input$cust <- as.numeric(input$cust)
  input$iri_week <- as.numeric(input$iri_week)
  input$spend <- as.numeric(input$spend)
  
  # Remove outliers ---------------------------------------------------------
  
  input_outl <- input[ , .N, by = c('cust' ) ]
  lower_bound <- quantile(input_outl$N, 0.025)
  upper_bound <- quantile(input_outl$N, 0.975)
  outlier_ind <- which(input_outl$N < lower_bound | input_outl$N > upper_bound)
  input_outl <- input_outl[-which(rownames(input_outl) %in% outlier_ind),]
  df_input= input %>% inner_join(input_outl,by="cust")
  df_input <- subset(df_input, select = c(1:3))
  
  
  # Aggregate Data weekly ---------------------------------------------------
  
  input <- as.data.table(df_input)
  input <- df_input[, .(spend=mean(spend)), by=list(cust, iri_week)]
  
  
  # Tranform iri week to date -----------------------------------------------
  
  input$date <- iriweek_to_date(input$iri_week)
  
  # Calculate average spend per customer ------------------------------------
  
  avg_input_spend <- aggregate(input$spend, by=list(input$cust), FUN=mean)
  colnames(avg_input_spend)[1] <- "cust"
  colnames(avg_input_spend)[2] <- "spend"
  
  
  input <- subset(input, select = c("cust","date"))
  
  # Set the last week -------------------------------------------------------
  
  input$T_cal <- max(input$date)
  
  # Create freq, recency and total observ period ----------------------------
  
  input_train <- sqldf("select cust, count(*)-1 as freq, (max(date) - min(date))/7 as recency, (T_cal - min(date))/7 as Tot_Obs from input group by cust", drv = 'SQLite')
  
  return(list(input_train,avg_input_spend))
}


input_train <- Data_prep(input)[[1]]
avg_input_spend <- Data_prep(input)[[2]]

#message("\nCount of transactions after outliers:\n", length(input_train$cust))
message("\nCount of distinct HHs after outliers:\n", length(input_train$cust))

rf.matrix <- data.table( x = input_train$freq, t.x = input_train$recency, n.cal = input_train$Tot_Obs )
message("\nSample of train dataset:\n")
print(head(rf.matrix))

message("\n The total number of weeks is:\n", max(rf.matrix$Tot_Obs))

my_rf_matrix <- rf.matrix[ , .N, by = c('x', 't.x', 'n.cal' ) ]
colnames( my_rf_matrix ) = c('x', 't.x', 'n.cal', 'custs' )
J = nrow( my_rf_matrix )
cal.rf.matrix <- as.matrix( my_rf_matrix )
input_train <- as.matrix(input_train)

message("\nEnd of dataprep: Success")

# Parameter estimation
params <- bgbb.EstimateParameters(cal.rf.matrix);
LL <- bgbb.rf.matrix.LL(params, cal.rf.matrix);
p.matrix <- c(params, LL);
#for (i in 1:2){
  #params <- bgbb.EstimateParameters(cal.rf.matrix);
  #LL <- bgbb.rf.matrix.LL(params, cal.rf.matrix);
  #p.matrix.row <- c(params, LL);
  #p.matrix <- rbind(p.matrix, p.matrix.row);
#}
#colnames(p.matrix) <- c("alpha", "beta", "gamma", "delta", "LL");
#rownames(p.matrix) <- 1:3;

message("\nParameter estimation: Success")
print(round(p.matrix,2))

#####################################
input_train <- as.data.frame(input_train)
results_data <- input_train %>% left_join(avg_input_spend, by="cust")
results_data[is.na(results_data)] <- 0
n.cal <- results_data$Tot_Obs
x <- results_data$freq
t.x <- results_data$recency

p.alive <- bgbb.PAlive(params,x,t.x,n.cal)

if (pp==1/12 || pp==1/4 || pp==1/2) {
  n.star=52*pp
  expected.frequency=bgbb.ConditionalExpectedTransactions(params, n.cal, n.star, x, t.x)
} else if (pp>=1) {
  expected.frequency_cum <- c()
  for (i in 1:pp) {
    n.star = 52*i
    expected.frequency=bgbb.ConditionalExpectedTransactions(params, n.cal, n.star, x, t.x)
    expected.frequency_cum[[i]] <- expected.frequency
  }
  CLV_y = expected.frequency_cum[[1]]*results_data$spend/(1+disc)
  i <- 2
  while ( i <= pp){
    CLV_y = CLV_y + (expected.frequency_cum[[i]] - expected.frequency_cum[[i-1]])*results_data$spend/(1+disc)^i
    i <- i+1
  }
} else {
  s=(1+disc)^(1/52)-1
  Dert_Inf=bgbb.DERT(params,x,t.x,n.cal,s)
}

if (pp==1/12 || pp==1/4 || pp==1/2) {
  CLV_m <- expected.frequency*results_data$spend*M/(1 + disc)^pp
  results_model <- data.frame(
    Exp_trans=expected.frequency,
    Pr_Alive=p.alive,
    PFCS=CLV_m)
} else if (pp>=1) {
  CLV_y = expected.frequency_cum[[1]]*results_data$spend/(1+disc)
  i <- 2
  while ( i <= pp){
    CLV_y = CLV_y + (expected.frequency_cum[[i]] - expected.frequency_cum[[i-1]])*results_data$spend/(1+disc)^i
    i <- i+1
  }
  results_model <- data.frame(
    Exp_trans=expected.frequency_cum[[pp]],
    Pr_Alive=p.alive,
    PFCS=CLV_y)
} else {
  CLV_Dert <- Dert_Inf*results_data$spend
  results_model <- data.frame(
    exp_trips=Dert_Inf,
    Pr_Alive=p.alive,
    CLV_Inf=CLV_Dert)
}

results <- cbind(results_data, results_model)

message("\nThe average PAlive is:", mean(results$Pr_Alive))
message("\nThe average expected trips is:", mean(results$Exp_trans))
message("\nThe average CLV is:", mean(results$PFCS))

fwrite(results,paste0(thisPath,"/Final_CLV_Outcome.csv"),col.names=T)
#############################################################

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
                                                             avg_exp_trips=mean(Exp_trans),
                                                             avg_clv=mean(PFCS),
                                                             sum_exp_trips=sum(Exp_trans),
                                                             sum_clv=sum(PFCS),
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