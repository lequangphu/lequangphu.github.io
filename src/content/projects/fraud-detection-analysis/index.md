---
title: "Credit Card Fraud Detection: EDA & Rules Engine"
description: "Analyzing 1.3M transactions to understand fraud patterns and build detection rules using Polars"
date: "Mar 3 2026"
---

Credit card fraud is a massive problem for financial institutions and consumers alike. In this analysis, I'll explore a dataset of 1.3 million credit card transactions to understand fraud patterns and build a simple rules-based detection system.

## Data Overview

The dataset contains 1,296,675 credit card transactions from January 2019 to June 2020. Each transaction includes details like merchant, category, amount, and whether it was flagged as fraud.

```python
from datasets import load_dataset
import polars as pl

dataset = load_dataset("pointe77/credit-card-transaction", split="train")
df = pl.from_arrow(dataset.data.table)

# Parse transaction time
df = df.with_columns(
    pl.col('trans_date_trans_time').str.strptime(pl.Datetime, format="%Y-%m-%d %H:%M:%S").alias('transaction_time')
)

print(f"Total transactions: {len(df):,}")
print(f"Columns: {df.columns}")
print(f"Fraud rate: {df['is_fraud'].mean() * 100:.2f}%")
```

**Key Dataset Stats:**
- **Total transactions**: 1,296,675
- **Time range**: 2019-01-01 to 2020-06-21
- **Overall fraud rate**: 0.58%

## Exploratory Data Analysis

### Amount Distribution

One of the most striking patterns: fraud transactions are significantly higher in value.

```python
fraud_df = df.filter(pl.col('is_fraud') == 1)
legit_df = df.filter(pl.col('is_fraud') == 0)

avg_fraud_amount = fraud_df['amt'].mean()
avg_legit_amount = legit_df['amt'].mean()

print(f"Average fraud transaction: ${avg_fraud_amount:.2f}")
print(f"Average legitimate transaction: ${avg_legit_amount:.2f}")
```

| Transaction Type | Average Amount |
|-----------------|----------------|
| Fraud | $531.32 |
| Legitimate | $67.67 |

**Finding**: Fraudulent transactions are nearly **8x higher** on average than legitimate ones.

### Category Analysis

```python
category_fraud = (
    df.group_by('category')
    .agg(
        pl.len().alias('total_transactions'),
        pl.col('is_fraud').sum().alias('fraud_count'),
    )
    .with_columns(
        (pl.col('fraud_count') / pl.col('total_transactions') * 100).alias('fraud_rate')
    )
    .sort('fraud_rate', descending=True)
)

print(category_fraud)
```

**Fraud Rate by Category:**

| Category | Total Transactions | Fraud Count | Fraud Rate |
|----------|-------------------|-------------|------------|
| shopping_net | 97,543 | 1,713 | 1.76% |
| misc_net | 63,287 | 915 | 1.45% |
| grocery_pos | 123,638 | 1,743 | 1.41% |
| shopping_pos | 116,672 | 843 | 0.72% |
| gas_transport | 131,659 | 618 | 0.47% |
| misc_pos | 79,655 | 250 | 0.31% |
| grocery_net | 45,452 | 134 | 0.29% |
| travel | 40,507 | 116 | 0.29% |
| entertainment | 94,014 | 233 | 0.25% |
| personal_care | 90,758 | 220 | 0.24% |
| kids_pets | 113,035 | 239 | 0.21% |
| food_dining | 91,461 | 151 | 0.17% |
| home | 123,115 | 198 | 0.16% |
| health_fitness | 85,879 | 133 | 0.15% |

**Finding**: Online shopping (`shopping_net`) has the highest fraud rate at 1.76%, nearly 12x higher than the lowest category (`health_fitness` at 0.15%).

### Time-Based Patterns

```python
# Fraud by Hour of Day
fraud_by_hour = (
    df.with_columns(
        pl.col('transaction_time').dt.hour().alias('hour_of_day')
    )
    .group_by('hour_of_day')
    .agg(
        pl.len().alias('total_transactions'),
        pl.col('is_fraud').sum().alias('fraud_count')
    )
    .with_columns(
        (pl.col('fraud_count') / pl.col('total_transactions') * 100).alias('fraud_rate')
    )
    .sort('hour_of_day')
)

print("Fraud by Hour of Day:")
print(fraud_by_hour)
```

**Key Insight - Late Night Fraud:**

| Time Period | Fraud Rate |
|-------------|------------|
| 10 PM - 11 PM | **2.88%** |
| 11 PM - Midnight | **2.84%** |
| Midnight - 1 AM | 1.53% |
| 1 AM - 2 AM | 1.49% |
| 2 AM - 3 AM | 1.47% |
| Daytime (6 AM - 9 PM) | < 0.15% |

**Finding**: Fraud peaks dramatically between **10 PM and 3 AM**, with rates 15-20x higher than daytime hours. This is when fraudsters operate, likely because:
- Victims are asleep and can't detect unauthorized charges
- Less monitoring during off-hours
- International transactions cross time zones

### Day of Week

```python
# Fraud by Day of Week
fraud_by_day = (
    df.with_columns(
        pl.col('transaction_time').dt.weekday().alias('day_of_week')
    )
    .group_by('day_of_week')
    .agg(
        pl.len().alias('total_transactions'),
        pl.col('is_fraud').sum().alias('fraud_count')
    )
    .with_columns(
        (pl.col('fraud_count') / pl.col('total_transactions') * 100).alias('fraud_rate')
    )
    .sort('day_of_week')
)

day_names = {1: 'Monday', 2: 'Tuesday', 3: 'Wednesday', 4: 'Thursday', 5: 'Friday', 6: 'Saturday', 7: 'Sunday'}
fraud_by_day = fraud_by_day.with_columns(
    pl.col('day_of_week').map_elements(lambda x: day_names.get(x, str(x)), return_dtype=pl.String).alias('day_of_week')
)

print(fraud_by_day)
```

| Day | Fraud Rate |
|-----|------------|
| Friday | 0.71% (highest) |
| Thursday | 0.68% |
| Wednesday | 0.66% |
| Saturday | 0.61% |
| Tuesday | 0.58% |
| Sunday | 0.49% |
| Monday | 0.46% (lowest) |

**Finding**: **Friday** has the highest fraud rate, while **Monday** has the lowest. The latter half of the work week sees more fraud.

## Building a Fraud Rules Engine

Now let's build some detection rules and measure their effectiveness.

```python
# Create detection rules
def high_amount_rule(df, threshold=500):
    return df.filter(pl.col('amt') > threshold)

high_risk_categories = ['shopping_net', 'misc_net', 'grocery_pos']

def category_risk_rule(df, high_risk_categories=high_risk_categories):
    return df.filter(pl.col('category').is_in(high_risk_categories))

def outlier_rule(df, percentile=99):
    threshold = df['amt'].quantile(percentile / 100)
    return df.filter(pl.col('amt') > threshold)
```

### Rule 1: High Amount (>$500)

```python
high_amount_flagged = high_amount_rule(df, threshold=500)
fraud_caught = high_amount_flagged.filter(pl.col('is_fraud') == 1).height
false_positives = high_amount_flagged.height - fraud_caught

precision = fraud_caught / high_amount_flagged.height * 100
recall = fraud_caught / fraud_count * 100

print(f"High Amount Rule (>$500):")
print(f"  Precision: {precision:.1f}%")
print(f"  Recall: {recall:.1f}%")
print(f"  False positives: {false_positives:,}")
```

| Metric | Value |
|--------|-------|
| Precision | 23.3% |
| Recall | 48.6% |
| False Positives | 11,983 |

### Rule 2: High-Risk Categories

```python
high_risk_category_flagged = category_risk_rule(df, high_risk_categories=high_risk_categories)
fraud_caught = high_risk_category_flagged.filter(pl.col('is_fraud') == 1).height
false_positives = high_risk_category_flagged.height - fraud_caught

precision = fraud_caught / high_risk_category_flagged.height * 100
recall = fraud_caught / fraud_count * 100

print(f"High Risk Category Rule:")
print(f"  Precision: {precision:.1f}%")
print(f"  Recall: {recall:.1f}%")
print(f"  False positives: {false_positives:,}")
```

| Metric | Value |
|--------|-------|
| Precision | 1.5% |
| Recall | 58.2% |
| False Positives | 280,097 |

### Rule 3: Outlier Detection (Top 1%)

```python
outlier_flagged = outlier_rule(df, percentile=99)
fraud_caught = outlier_flagged.filter(pl.col('is_fraud') == 1).height
false_positives = outlier_flagged.height - fraud_caught

precision = fraud_caught / outlier_flagged.height * 100
recall = fraud_caught / fraud_count * 100

print(f"Outlier Rule (top 1% amount):")
print(f"  Precision: {precision:.1f}%")
print(f"  Recall: {recall:.1f}%")
print(f"  False positives: {false_positives:,}")
```

| Metric | Value |
|--------|-------|
| Precision | 27.8% |
| Recall | 48.0% |
| False Positives | 9,367 |

## Key Takeaways

1. **Amount is the strongest signal**: The outlier rule achieved the best precision (27.8%), confirming that fraudulent transactions are disproportionately high-value.

2. **Time matters**: Late night hours (10 PM - 3 AM) have 15-20x higher fraud rates than daytime. Any real fraud system should weight time heavily.

3. **Category helps but creates noise**: High-risk categories catch more fraud (58% recall) but with massive false positives (280K). Better as a feature weight than a standalone rule.

4. **Simple rules have limits**: Even the best rule only catches ~50% of fraud with ~25% precision. A production system would need ML models to improve these numbers.

**The data tells a clear story**: Fraudsters prefer high-value transactions during off-hours when victims are likely asleep. A smart fraud system should flag high amounts in late-night transactions from high-risk categories.

---

*Analysis performed using Polars on a dataset of 1.3M credit card transactions.*
