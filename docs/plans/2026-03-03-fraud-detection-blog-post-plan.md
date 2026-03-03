---
date: 2026-03-03
topic: fraud-detection-analysis-blog-post
---

# Credit Card Fraud Detection Analysis - Blog Post

## Overview

Convert the Jupyter notebook `Untitled0.ipynb` (credit card fraud detection EDA and rules engine) into a blog post published on the personal portfolio site.

## Context

- **Source**: `/Users/phu/repos/lequangphu.github.io/Untitled0.ipynb`
- **Target**: New blog post in `src/content/projects/fraud-detection-analysis/`
- **Audience**: Data professionals (technical)
- **Style**: Code + output + text with collapsible code blocks

## Content Structure

### Frontmatter (YAML)
```yaml
---
title: "Credit Card Fraud Detection: EDA & Rules Engine"
description: "Analyzing 1.3M transactions to understand fraud patterns and build detection rules using Polars"
date: "Mar 3 2026"
---
```

### Sections

1. **Introduction/Overview**
   - Brief intro to the dataset (1.3M transactions, 2019-2020)
   - Fraud rate context (0.58%)
   - What the analysis covers

2. **Data Loading**
   - Polars code for loading dataset
   - Schema overview (columns)

3. **Exploratory Data Analysis**
   - Basic stats (total, fraud count, legit count)
   - Amount statistics (fraud avg: $531 vs legit avg: $67)
   - Category breakdown table
   - Time analysis (hour of day, day of week)
   - Key findings summary

4. **Fraud Rules Engine**
   - Three rules tested:
     - High Amount Rule (>$500)
     - High-Risk Category Rule
     - Outlier Rule (top 1%)
   - Performance metrics for each (precision, recall, false positives)

5. **Conclusion**
   - Key takeaways
   - Best performing rule (Outlier: 27.8% precision, 48% recall)

## Implementation Steps

### Step 1: Create Project Directory
- Create `src/content/projects/fraud-detection-analysis/`
- Create `index.md` inside

### Step 2: Write Frontmatter
- Set title, description, date

### Step 3: Write Content Sections
- Translate each notebook section to markdown
- Keep code blocks with Polars
- Include actual output tables/data from notebook
- Use HTML details/summary for collapsible code blocks:
  ```html
  <details>
  <summary>Show code</summary>
  
  ```python
  # code here
  ```
  
  </details>
  ```

### Step 4: Format Output Tables
- Use markdown tables for fraud by category, hour, day of week
- Include the actual numbers from notebook outputs

### Step 5: Review & Finalize
- Check all metrics match notebook output
- Ensure code is readable
- Verify frontmatter format matches existing projects

## Open Questions

- Should code be collapsible by default (hidden) or visible?
  - Recommendation: Collapsed with "Show code" toggle to match "code + output + text" style

## Next Steps

→ Implement the blog post creation
