# ca.tjo.cloud

Certificate Authority for `.internal` (and other?) TLD.

## Setting up new node

Rotatiion of Intermediate certificates is done  by replacing nodes themselfs.
We do not issue new certificates for existing nodes.

### Steps

1. Add new node in `terraform.tfvars`
2. Run `just ca apply`
3. Run `just ca configure-all`
4. Run `just ca backup-db $OLD_NODE`
5. Run `just ca restore-db $NEW_NODE`
   - We have to restore db otherwise ACME client's account "do not exist" and renewal fails.
6. Run `just ca sign-issuing-intermediate-ca $NODE`
7. Remove old node from `terraform.tfvars` and `just ca apply`.


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
