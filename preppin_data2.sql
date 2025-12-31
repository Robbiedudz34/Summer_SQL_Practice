/*
IBAN Code Order:
- Country Code
- Check Digits
- Bank Code
- Sort Code
- Account Number

REQUIREMENTS

- In the Transactions table, there is a Sort Code field which contains dashes. We need to remove these so just have a 6 digit string
- Use the SWIFT Bank Code lookup table to bring in additional information about the SWIFT code and Check Digits of the receiving bank account
- Add a field for the Country Code
  Hint: all these transactions take place in the UK so the Country Code should be GB
- Create the IBAN as above
  Hint: watch out for trying to combine sting fields with numeric fields - check data types
- Remove unnecessary fields
- Output the data

Challenge source: 
https://preppindata.blogspot.com/2023/01/2023-week-2-international-bank-account.html
*/

--  Sandbox Commands
SELECT *
FROM pd2023_wk02_swift_codes
LIMIT 100;
 -- bank, swift_code, check_digits
SELECT *
FROM pd2023_wk02_transactions
LIMIT 100;
 -- transaction_id, account_number, sort_code, bank
 
 
 -- 1. In the Transactions table, there is a Sort Code field which contains dashes. We need to remove these so just have a 6 digit string
SELECT
*,
REPLACE(sort_code, '-', '') AS sort_code_clean
FROM 
pd2023_wk02_transactions
LIMIT 10;

-- 2. Use the SWIFT Bank Code lookup table to bring in additional information about the SWIFT code and Check Digits of the receiving bank account
SELECT
t.transaction_id,
t.account_number,
REPLACE(t.sort_code, '-', '') AS sort_code_clean,
t.bank,
s.swift_code,
s.check_digits
FROM pd2023_wk02_transactions AS t
RIGHT JOIN pd2023_wk02_swift_codes AS s on t.bank = s.bank;

-- 3. Add a field for the Country Code -Hint: all these transactions take place in the UK so the Country Code should be GB
SELECT
t.transaction_id,
t.account_number,
REPLACE(t.sort_code, '-', '') AS sort_code_clean,
t.bank,
s.swift_code,
s.check_digits,
'GB' as country_code

FROM pd2023_wk02_transactions AS t
RIGHT JOIN pd2023_wk02_swift_codes AS s on t.bank = s.bank;

-- 4. - Create the IBAN as above  Hint: watch out for trying to combine sting fields with numeric fields - check data types
WITH ibanparts AS (
SELECT
'GB' as country_code,
s.check_digits,
s.swift_code,
REPLACE(t.sort_code, '-', '') AS sort_code_clean,
t.account_number
FROM pd2023_wk02_transactions AS t
RIGHT JOIN pd2023_wk02_swift_codes AS s on t.bank = s.bank
)
SELECT
CONCAT(
country_code,
check_digits,
swift_code,
sort_code_clean,
account_number
) AS IBAN
FROM ibanparts;

/*
IBAN Code Order:
- Country Code
- Check Digits
- Bank Code
- Sort Code
- Account Number
*/