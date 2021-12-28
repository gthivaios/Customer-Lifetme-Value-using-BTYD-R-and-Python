# Predict Customer Lifetime Value based on history transactions in Market stores
Customer lifetime value definition:
“The present value of the future cash flows attributed to the customer during his/her entire relationship with the company”
## Introduction - The goal
The goal is to identify opportunities for different customer segments based on CLV estimations and provide relevant recommendations
We have to face the challenge of non-contractual markets. How do we differentiate between those customers who have ended their relationship with the firm versus those who are simply in the midst of a long history between transactions?
We Calculate CLV metrics mainly for two reasons in order to expand our business: 
For custom segmentations based on long history purchase behavior and for media audiences and measurement
## BTYD package - Methodology
“Buy Till You Die” probabilistic models help us in quantifying the lifetime value of a customer by assessing the expected number of his future transactions and his probability of being “alive”. BTYD methodology contains models to capture non-contractual purchasing behavior of customers. We have applied BG/BB probability models to datasets that have the transaction history for a specific brand.

**Applications of probabilistic models**:
1. Summarize and interpret patterns of market-level behavior
2. Predict behavior in future periods, be it in the aggregate or at a more granular level (e.g., conditional on past behavior)
3. Create market segments based on customer’s future value (Low/Mid/High - Engagement)
4. Capture the campaign effect for the customers’ long term period.

**Building a probabilistic model:**
To fit the BG/BB model, the customer-level information has to be classified based on “recency” and “frequency” of each individual customer’s purchases

**Distributions:**
1. Frequency(x):  Number of repeated transactions
2. Recency(t.x): the age of the customer at the moment of his last purchase, which is equal to the duration between a customer’s first purchase and their last purchase.
3. Tot_Obs(n): the age of the customer at the end of the period under study, which is equal to the duration between a customer’s first purchase and the last day in the dataset.

Given these information about customer purchase behavior, we can fit the BG/BB model to describe their probability of still being active, as well as their expected number of purchases in the future conditioning on their (x, t.x, n) information.






