input <- elog
message("Succesfull load!")

message("\nCount of transactions before outliers:\n", nrow(input))
message("\nCount of distinct HHs before outliers:\n", length(unique(input$cust)))

# Function which transforms the week to specific date bases on specific date encoding
week_to_date <- function(week) {
  d <- week*7+29100
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
  
  df_input <- as.data.table(df_input)
  df_input <- df_input[, .(spend=mean(spend)), by=list(cust, iri_week)]
  
  
  # Tranform iri week to date -----------------------------------------------
  
  df_input$date <- week_to_date(df_input$iri_week)
  
  # Calculate average spend per customer ------------------------------------
  
  avg_input_spend <- aggregate(df_input$spend, by=list(df_input$cust), FUN=mean)
  colnames(avg_input_spend)[1] <- "cust"
  colnames(avg_input_spend)[2] <- "spend"
  
  
  df_input <- subset(df_input, select = c("cust","date"))
  
  # Set the last week -------------------------------------------------------
  
  df_input$T_cal <- max(df_input$date)
  
  # Create freq, recency and total observ period ----------------------------
  
  input_train <- sqldf("select cust, count(*)-1 as freq, (max(date) - min(date))/7 as recency, (T_cal - min(date))/7 as Tot_Obs from df_input group by cust", drv = 'SQLite')
  
  return(list(input_train,avg_input_spend))
}

input_train <- Data_prep(input)[[1]]
avg_input_spend <- Data_prep(input)[[2]]


rf.matrix <- data.table( x = input_train$freq, t.x = input_train$recency, n.cal = input_train$Tot_Obs )
message("\nSample of train dataset:\n")
print(head(rf.matrix))

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
  s=(1+d)^(1/52)-1
  Dert_Inf=bgbb.Dert(params,x,t.x,n.cal,disc)
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

results_full <- cbind(results_data, results_model)

message("\nThe average PAlive is:", mean(results_full$Pr_Alive))
message("\nThe average expected trips is:", mean(results_full$Exp_trans))
message("\nThe average CLV is:", mean(results_full$PFCS))

fwrite(results_full,paste0(outputPath,"/Final_CLV_Outcome_full.csv"),col.names=T)
##############################################################