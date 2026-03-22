# Kamino

This is a RBPI 4 that has USB connection to UPS.

This machine runs NUT server to tell other machines to shut down once UPS reaches low battery level (20%).

Other mahcines:
 - battu.system.tjo.cloud `00:1e:06:45:5e:d1`
 - jakku.system.tjo.cloud `00:1e:06:45:0c:34`
 - endor.system.tjo.cloud `00:1e:06:45:5d:c9`

## Observability:
 - [UPS Statistics](https://monitor.tjo.cloud/goto/efgs1m20ag3k0d?orgId=1)

## TODO:

Currently machines are only shutdown. They do not start up.

They are configured to "start when power is present again". But if UPS never runs out of battery and thus never
terminates the "power". The machines will never start back up.

Potential ideas:
 - Use Wake On Lan to wake up the machines.
   - Kamino could wake them up. But what wakes up kamino?
     - Kamino never shuts down?
 - ??
