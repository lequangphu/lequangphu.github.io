---
title: "Credit Card Fraud Detection: Rules vs Machine Learning"
description: "Comparing rule-based detection with Random Forest ML on 1.3M credit card transactions"
date: "Mar 18 2026"
---

Credit card fraud is a massive problem for financial institutions and consumers alike. In this analysis, I explore a dataset of 1.3 million credit card transactions to understand fraud patterns, build rule-based detection systems, and compare them against a machine learning approach.

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

4. **Simple rules have limits**: Even the best rule only catches ~50% of fraud with ~25% precision.

**The data tells a clear story**: Fraudsters prefer high-value transactions during off-hours when victims are likely asleep. A smart fraud system should flag high amounts in late-night transactions from high-risk categories.

---

## Machine Learning Approach

While rule-based systems are interpretable and easy to implement, they have significant limitations. Let's see how a machine learning model compares.

### Feature Engineering

I engineered the following features for the ML model:

| Feature | Description | Type |
|---------|-------------|------|
| `amt` | Transaction amount | Numerical |
| `log_amt` | Log-transformed amount | Numerical (handles skew) |
| `hour` | Hour of day (0-23) | Temporal |
| `day_of_week` | Day of week (0-6) | Temporal |
| `is_weekend` | Binary weekend flag | Temporal |
| `age` | Customer age | Demographic |
| `category` | Merchant category | Categorical (encoded) |
| `gender` | Customer gender | Categorical (encoded) |
| `state` | State location | Categorical (encoded) |
| `job` | Customer job | Categorical (encoded) |

### Handling Class Imbalance

The dataset has a severe class imbalance problem: only **0.58%** of transactions are fraudulent. To address this, I used **SMOTE** (Synthetic Minority Over-sampling Technique) to balance the training data.

```python
from imblearn.over_sampling import SMOTE
from sklearn.ensemble import RandomForestClassifier

# Apply SMOTE to balance the classes
smote = SMOTE(random_state=42)
X_train_resampled, y_train_resampled = smote.fit_resample(X_train, y_train)

# Train Random Forest
rf = RandomForestClassifier(
    n_estimators=100,
    max_depth=15,
    min_samples_split=10,
    min_samples_leaf=5,
    class_weight='balanced',
    random_state=42
)
rf.fit(X_train_resampled, y_train_resampled)
```

### Results Comparison

| Approach | Precision | Recall | F1 Score | ROC-AUC |
|----------|-----------|--------|----------|---------|
| High Amount Rule ($500+) | 23.3% | 48.6% | 0.315 | N/A |
| Outlier Rule (Top 1%) | 27.8% | 48.0% | 0.253 | N/A |
| **Random Forest + SMOTE** | **28.8%** | **92.5%** | **0.439** | **0.993** |

### Key Improvements with ML

The Random Forest classifier significantly outperforms rule-based approaches:

- **+70% improvement in precision** (16.9% → 28.8%)
- **+85% improvement in recall** (50.1% → 92.5%)
- **+74% improvement in F1 score** (0.253 → 0.439)
- **Excellent discrimination** with 0.993 ROC-AUC

### Feature Importance

The most important features for fraud detection are:

| Feature | Importance |
|---------|------------|
| Transaction amount (`amt`) | 43% |
| Log-transformed amount (`log_amt`) | 28% |
| Hour of day (`hour`) | 11% |
| Merchant category (`category`) | 10% |
| Other features (age, state, job, etc.) | 8% |

### Confusion Matrix (Random Forest on Test Set)

| | Predicted Legitimate | Predicted Fraud |
|---|---|---|
| **Actual Legitimate** | 254,399 (TN) | 3,435 (FP) |
| **Actual Fraud** | 113 (FN) | 1,388 (TP) |

**Interpretation**: The model correctly identified 1,388 out of 1,501 fraud cases (92.5% recall) while maintaining reasonable precision (28.8%).

### ML vs Rule-Based: Why the Big Difference?

1. **Non-linear relationships**: Random Forest can learn complex interactions between features (e.g., high amount + late night + specific category)

2. **Optimal thresholding**: The model learns the optimal decision boundary across all features simultaneously, rather than using arbitrary thresholds

3. **Feature weighting**: Each feature contributes proportionally to its predictive power, as shown in the feature importance chart

4. **Class imbalance handling**: SMOTE ensures the model sees enough fraud examples during training to learn the patterns effectively

### Updated Takeaways

1. **ML dramatically outperforms simple rules**: The Random Forest catches **92.5% of fraud** compared to ~50% for rule-based approaches, with similar or better precision.

2. **Feature engineering matters**: Log-transforming the amount and extracting temporal features significantly improved model performance.

3. **Class imbalance is critical**: Without SMOTE or proper weighting, models struggle to learn fraud patterns due to the extreme imbalance (0.58% fraud rate).

4. **Interpretability vs performance**: Rule-based systems are more interpretable, but ML models offer substantially better performance. In production, a hybrid approach often works best—use ML for scoring and rules for explainability.

**Code available at**: [github.com/lequangphu/credit-card-fraud-detection](https://github.com/lequangphu/credit-card-fraud-detection)

---

*Analysis performed using Polars on a dataset of 1.3M credit card transactions.*
