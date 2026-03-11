---
title: "NYC Taxi Spatiotemporal Analysis"
description: "A comprehensive spatiotemporal data analysis project demonstrating EDA, zone grouping, and behavior-based anomaly detection on NYC Yellow Taxi trip data with interactive Streamlit dashboard."
date: "Mar 11 2026"
demoURL: "https://nyc-taxi-spatiotemporal-analysis.streamlit.app/"
repoURL: "https://github.com/lequangphu/nyc-taxi-spatiotemporal-analysis"
---

## ✨ Features

- **Spatiotemporal EDA**: Analyzing patterns across time and space with hourly, daily, and monthly views
- **Zone Grouping**: Intelligently groups 265 NYC taxi zones into 6 logical regions (Manhattan, Brooklyn, Queens, Bronx, Staten Island, Airports)
- **Behavior-based Anomaly Detection**: Identifies unusual trip patterns using heuristic methods
- **Interactive Dashboard**: Streamlit-powered visualization with multiple analysis views
- **High-Performance Processing**: Uses Polars for efficient data operations on large datasets

## 🏗️ Architecture

### Data Pipeline
- **Data Ingestion**: Automated download from NYC TLC API
- **Data Processing**: Polars for high-performance DataFrame operations
- **Zone Mapping**: 265 taxi zones grouped into 6 regions for spatial analysis

### Analysis Modules
- **Temporal Analysis**: Time-based pattern discovery (hourly/daily/monthly)
- **Spatial Analysis**: Zone-level pickup/dropoff patterns and regional flows
- **Anomaly Detection**: Multiple heuristic methods for outlier detection
- **Statistics**: Comprehensive summary statistics and aggregations

### Dashboard
- **Framework**: Streamlit for interactive web-based visualization
- **Visualization**: Plotly for interactive charts and graphs
- **Deployment**: Streamlit Cloud for zero-cost hosting

## ⚡ Tech Stack

### Core
- **Python 3.9+** - Core development
- **Polars** - High-performance DataFrame operations
- **Streamlit** - Interactive dashboard framework
- **Plotly** - Interactive visualizations

### Data Sources
- **NYC TLC API** - Taxi trip data (public domain)

## 🔍 Analysis Capabilities

### Temporal Patterns
- Peak hours identification (5-7 PM evening rush)
- Day-of-week analysis
- Monthly trend analysis
- Weekend vs weekday comparisons

### Spatial Patterns
- Top pickup/dropoff zones by volume
- Zone-to-zone flow analysis
- Regional inter-borough flow visualization
- Zone-hour heatmaps

### Anomaly Detection
- Speed violations (>60 mph)
- Fare outliers (IQR method)
- Distance-duration mismatches
- Late-night high fare anomalies

## 📊 Key Findings

### Temporal Insights
- Peak activity: 5-7 PM (evening rush hour)
- Lowest activity: 3-5 AM
- Weekdays show 15-20% higher activity than weekends

### Spatial Insights
- Manhattan dominates with ~70% of pickup/dropoff activity
- JFK and LaGuardia show distinct patterns (airport trips)
- Strong commuter patterns between boroughs

### Anomaly Rate
- ~2-5% of trips flagged as anomalous
- Late night (10PM-3AM) shows 3x higher anomaly rates

## 🚀 Live Demo

Visit the interactive dashboard at [nyc-taxi-spatiotemporal-analysis.streamlit.app](https://nyc-taxi-spatiotemporal-analysis.streamlit.app)

Select any year and month of available NYC taxi data to explore:
- Trip patterns by hour, day, and month
- Top pickup and dropoff zones
- Regional flow patterns
- Anomaly detection results

## 📋 Prerequisites

- Python 3.9 or higher
- UV package manager (recommended) or pip

## 🛠️ Quick Start

### 1. Clone the Repository
```bash
git clone https://github.com/lequangphu/nyc-taxi-spatiotemporal-analysis.git
cd nyc-taxi-spatiotemporal-analysis
```

### 2. Install Dependencies
```bash
# Using UV (recommended)
uv sync

# Or using pip
pip install -e .
```

### 3. Run the Dashboard
```bash
streamlit run src/dashboard/app.py
```

The dashboard will open at `http://localhost:8501`

## 📖 Project Structure

```
nyc-taxi-spatiotemporal-analysis/
├── src/
│   ├── data/
│   │   └── download.py     # Data download from NYC TLC
│   ├── eda/
│   │   ├── spatial.py      # Spatial analysis
│   │   ├── stats.py        # Statistical summaries
│   │   └── temporal.py     # Temporal analysis
│   ├── zones/
│   │   └── grouper.py      # Zone grouping logic
│   ├── anomaly/
│   │   └── detector.py     # Anomaly detection
│   └── dashboard/
│       └── app.py          # Streamlit dashboard
├── data/                   # Data storage
└── pyproject.toml
```

## 🎯 CV Keywords Demonstrated

- Spatiotemporal data analysis
- Exploratory data analysis (EDA)
- Time-series pattern analysis
- Zone/device grouping
- Behavior-based anomaly detection
- Python, Polars, SQL
- Dashboard development (Streamlit)
- Data visualization (Plotly)
