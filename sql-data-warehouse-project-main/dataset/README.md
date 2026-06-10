# datasets/

This folder contains the raw CSV source files for the Home Credit Default Risk project.

## Required Files

Download from [Kaggle](https://www.kaggle.com/c/home-credit-default-risk/data) and place here:

| File | Size | Rows |
|------|------|------|
| application_train.csv | ~166 MB | 307,511 |
| application_test.csv | ~26 MB | 48,744 |
| bureau.csv | ~220 MB | 1,716,428 |
| bureau_balance.csv | ~484 MB | 27,299,925 |
| previous_application.csv | ~311 MB | 1,670,214 |
| installments_payments.csv | ~420 MB | 13,605,401 |
| POS_CASH_balance.csv | ~323 MB | 10,001,358 |
| credit_card_balance.csv | ~127 MB | 3,840,312 |
| HomeCredit_columns_description.csv | ~14 KB | 219 rows |
| sample_submission.csv | ~1 MB | 48,744 |

> **Note:** CSV files are excluded from Git via `.gitignore` due to size.
> The BULK INSERT path in `proc_load_bronze.sql` expects files at `C:\home-credit-default-risk\`
