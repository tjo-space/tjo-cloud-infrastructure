# ca.tjo.cloud

Certificate Authority for `.internal` (and other?) TLD.

**Root fingerprint:** `8ca319801d29de1e24bf8ccc311a14b96b532e5238c0b442211a9802b25dcedb`

## How CA was created

```
STEPPATH="$PWD/rootca" step ca init --pki --name "ca.tjo.cloud" --deployment-type standalone
```
