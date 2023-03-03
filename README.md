# Customer Lifetime Value Prediction & HML Segmentation

## Introduction

**What is Customer Lifetime Value?**

Customer lifetime value (CLV) is one of the key stats likely to be tracked as part of a customer experience program. CLV is a measurement of how valuable a customer is to your company with an unlimited time span as opposed to just the first purchase. This metric helps you understand a reasonable cost per acquisition. CLV is the total worth to a business of a customer over the whole period of their relationship. It’s an important metric as it costs less to keep existing customers than it does to acquire new ones, so increasing the value of your existing customers is a great way to drive growth.

**Why is it important to track customer lifetime value?**

* Measure in long term the financial impact of marketing campaigns
* Enhance customers' targeting
* Boost customers loyalty and retention
* Increase revenue over time

There are basically two types of business context which I am going to discuss below regards to the relationship and purchase opportunities.

a. **Contractual** - Contractual business refers to the business where there is a definite time when the customer is going to churn or we can say we know when the customer is going to be dropped. This type of customer relationship known as contractual and the customers called the subscription customers. For Ex - Hotstar, Netflix, Amazon Prime Subscription

b. **Non-Contractual** - In the non-contractual world, customers do go away, but they do so silently; they have no need to tell us they are leaving. This makes for a much trickier CLV calculation. For Ex- Retail/E-Commerce

The market store business setting is non-contractual

**Purchase Opportunities Types:**

a. **Continuous** - It refers the purchase opportunites when there is continuous purchases done by the customers.

b. **Discrete** - Under discrete, the purchase happened on a specific time period. For Ex- Subscription Plan

So for our business case we have the discrete transaction opportunity, in weekly basis.

Customer lifetime value definition:
“The present value of the future cash flows attributed to the customer during his/her entire relationship with the company”

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

## Case Stydy R/Python:

We use a sample dataset including 3 years transactions of customers.
The implementation takes part with R and Python accordingly using the corresponding lifetimes packages.

## Supported Models:

[Modeling Discrete-Time Transactions Using the BG/BB Model](https://repository.upenn.edu/cgi/viewcontent.cgi?article=1056&context=wharton_research_scholars)
[Customer Base Analysis with BTYDplus](https://cran.r-project.org/web/packages/BTYDplus/vignettes/BTYDplus-HowTo.pdf)
[Lifetimes Package in Python](https://lifetimes.readthedocs.io/en/latest/Quickstart.html)





