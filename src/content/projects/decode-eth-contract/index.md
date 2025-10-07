---
title: "Decode Ethereum Logs and Traces from BigQuery"
description: "A Python toolkit for fetching and decoding Ethereum smart contract events from Google BigQuery's public blockchain datasets. This project specifically focuses on decoding logs from the Ethena Mint and Redeem Contract V2 on Ethereum."
date: "Oct 7 2025"
repoURL: "https://github.com/lequangphu/decode-ethereum-logs-and-traces"
---

## 🎯 Overview

This repository provides tools to:
- Query Ethereum logs and traces from BigQuery's public datasets
- Decode smart contract events using Web3.py
- Analyze transaction data with proper event ABI definitions
- Export decoded data to CSV for further analysis

## 📊 Target Contract

**Ethena Mint and Redeem Contract V2**
- **Address**: `0xe3490297a08d6fc8da46edb7b6142e4f461b62d3`
- **Explorer**: [Etherscan](https://etherscan.io/address/0xe3490297a08d6fc8da46edb7b6142e4f461b62d3#code)
- **Events**: Mint and Redeem operations

## 🚀 Features

- **BigQuery Integration**: Direct access to Google's public Ethereum datasets
- **Event Decoding**: Automatic decoding of Mint and Redeem events
- **Data Validation**: Comprehensive validation of hex strings and event formats
- **Cost Estimation**: Dry-run queries to estimate BigQuery costs before execution
- **Export Capabilities**: Save raw and decoded data to CSV files

## 📋 Prerequisites

- Python 3.11+
- Google Cloud BigQuery access (free tier: 5TB/month)
- Required Python packages (see installation below)

## 🛠️ Installation

### Using uv (Recommended)

```bash
# Clone the repository
git clone https://github.com/lequangphu/decode-ethereum-logs-and-traces.git
cd decode-ethereum-logs-and-traces

# Install dependencies with uv
uv add google-cloud-bigquery web3 pandas
```

### Using pip

```bash
pip install google-cloud-bigquery web3 pandas
```

## � Setup

1. **Google Cloud Authentication**:
   ```bash
   # Authenticate with Google Cloud
   gcloud auth application-default login
   ```

2. **BigQuery Access**: Ensure you have access to the public Ethereum datasets:
   - `bigquery-public-data.crypto_ethereum.logs`
   - `bigquery-public-data.crypto_ethereum.traces`

## 📖 Usage

### 1. Query Ethereum Logs

```python
from google.cloud import bigquery

# Initialize the BigQuery client
client = bigquery.Client()

# Run a dry-run to estimate costs
run_bigquery_query(
    table_name="logs",
    address="0xe3490297a08d6fc8da46edb7b6142e4f461b62d3",
    date="2025-09-17",
    dry_run=True
)

# Execute the actual query
logs_df = run_bigquery_query(dry_run=False)
```

### 2. Decode Contract Events

```python
from web3 import Web3
import pandas as pd

# Load your data
df = pd.read_csv('ena_mint_redeem_v2_logs_20250917.csv')

# Decode events
w3 = Web3()
contract_abi = [mint_abi, redeem_abi]
contract = w3.eth.contract(abi=contract_abi)

# Apply decoding
df['decoded'] = df.apply(lambda row: decode_log(row, contract), axis=1)
```

### 3. Export Results

```python
# Save decoded data
df.to_csv('ena_mint_redeem_v2_decoded_logs_20250917.csv', index=False)
```

## � Event Schemas

### Mint Event
```json
{
  "order_id": "string (indexed)",
  "benefactor": "address (indexed)",
  "beneficiary": "address (indexed)",
  "minter": "address",
  "collateral_asset": "address",
  "collateral_amount": "uint256",
  "usde_amount": "uint256"
}
```

### Redeem Event
```json
{
  "order_id": "string (indexed)",
  "benefactor": "address (indexed)",
  "beneficiary": "address (indexed)",
  "redeemer": "address",
  "collateral_asset": "address",
  "collateral_amount": "uint256",
  "usde_amount": "uint256"
}
```

## 💰 Cost Management

- **Free Tier**: 5TB/month on BigQuery
- **Daily Replenishment**: Quota resets daily
- **Dry Run**: Always use `dry_run=True` first to estimate costs
- **Date Filtering**: Query specific dates to control data volume

## 📁 File Structure

```
decode-ethereum-logs-and-traces/
├── README.md
├── decode-ethereum-logs-and-traces-from-bigquery.ipynb
├── ena_mint_redeem_v2_logs_20250917.csv          # Raw logs data
└── ena_mint_redeem_v2_decoded_logs_20250917.csv  # Decoded events
```

## 🔍 Example Output

```python
Transaction Hash: 0x755ce81ef307b21ec9657dd30223d49238baaed333760d41ec50c57f391da712
Timestamp: 2025-09-17 22:11:35+00:00
Decoded Event: {
  'event': 'Mint', 
  'args': {
    'order_id': '0x58e76b680aed194cbb42a3e50d584bd79617ece37b4640d3a43fb4ae8ff53f68',
    'benefactor': '0x8d3b74ca8Bf34d4FAB9DE1228F0e577044ee340C',
    'beneficiary': '0x9374A55a7D9c1C9116eE8AD3689d2B5ff1bDeF0D',
    'minter': '0xb229D6dB056750E22499191156Bf4c3654DF3826',
    'collateral_asset': '0xdAC17F958D2ee523a2206206994597C13D831ec7',
    'collateral_amount': '869306263000',
    'usde_amount': '868870901000000000000000'
  }
}
```

## 🛡️ Error Handling

The toolkit includes comprehensive error handling for:
- Invalid hex strings
- Malformed event data
- Missing or incorrect topics
- BigQuery authentication issues
- Event decoding failures

## 🔗 Resources

- **BigQuery Public Datasets**: [Ethereum Mainnet](https://console.cloud.google.com/bigquery?p=bigquery-public-data&d=goog_blockchain_ethereum_mainnet_us&page=dataset)
- **Ethena Contract**: [Etherscan](https://etherscan.io/address/0xe3490297a08d6fc8da46edb7b6142e4f461b62d3#code)
- **Web3.py Documentation**: [Web3.py Docs](https://web3py.readthedocs.io/)
- **BigQuery Python Client**: [Google Cloud BigQuery](https://cloud.google.com/bigquery/docs/reference/libraries)

## 📝 License

This project is open source and available under the [MIT License](LICENSE).

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## ⚠️ Disclaimer

This tool is for educational and research purposes. Always verify decoded data and be mindful of BigQuery costs when working with large datasets.