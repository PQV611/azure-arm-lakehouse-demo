# Secure Lakehouse + Operational Analytics (Demo)

This repo shows a **shadowIT-can’t-mess-it-up** demo:
- One-command **IaC stamp** (Bicep) for ADLS Gen2 + Cosmos DB.
- A tiny ADF pipeline that **upserts incrementally** from the lake into Cosmos (idempotent).

## Files
- `main.bicep` — deploys ADLS, Key Vault, Cosmos (autoscale) for demo.
- `pipelines/pipeline.json` — ADF copy with watermark + upsert.
- `data/customers.csv` — sample input with `UpdatedAt` watermark.
- `.github/workflows/deploy.yml` — manual CI stub (safe to leave as is).

## Manual deploy (if you try it)
```bash
az group create -n rg-demo-lakehouse -l eastus
az deployment group create -g rg-demo-lakehouse -f main.bicep -p baseName=demo
