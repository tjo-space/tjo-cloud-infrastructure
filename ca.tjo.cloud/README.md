# ca.tjo.cloud

Certificate Authority for `.internal` (and other?) TLD.

## Setting up new node

Rotatiion of Intermediate certificates is done  by replacing nodes themselfs.
We do not issue new certificates for existing nodes.

### Steps

1. Add new node in `terraform.tfvars`
2. Run `just ca apply`
3. Run `just ca configure-all`
4. Run `just ca sign-issuing-intermediate-ca $NODE`

## Authorities

```
ca.tjo.cloud - Root (10 years)
  |
ca.tjo.cloud - [year] Intermediate (1 year)
  |
$HOST.ca.tjo.cloud - [year] Intermediate (6 months)
  |
example.com. (24 hours)
```
