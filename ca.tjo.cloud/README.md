# ca.tjo.cloud

Certificate Authority for `.internal` (and other?) TLD.

## TODO
- [ ] Caddy does not support adding full chain to certificates?
  - Switch to `step ca` with caddy as proxy?
  - That would allow us to use more then just acme?
  - Keep existing CSR approach.

## Authorities

```
ca.tjo.cloud - Root (10 years)
  |
ca.tjo.cloud - [year] Intermediate (1 year)
  |
$HOST.ca.tjo.cloud - [year] Intermediate (6 months)
  |
$HOST.ca.tjo.cloud - [year] Signing (7 days)
  |
example.com. (12 hours)
```
