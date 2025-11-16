# Grafana Alloy Role

## Variables
```yaml
alloy_systemd_exporter_version: "0.7.0"
alloy_username: ""
alloy_password: ""
alloy_custom_integrations: |
    prometheus.scrape "garage" {
      targets    = concat(
        [
          {"__address__" = "127.0.0.1:3903", "instance" = constants.hostname, "job" = "integrations/garage"},
        ],
      )
      forward_to = [
        otelcol.receiver.prometheus.default.receiver,
      ]
      bearer_token = "{{ garage_metrics_token }}"
    }
otel_resource_attributes: # optional
  service.name: "banana"
  service.version: "0.0.0"
  service.environment: "production"
  cloud.region: "foo"
```

## Usage
```yaml
- name: Install Alloy
  ansible.builtin.import_role:
    name: alloy
  vars:
    otel_resource_attributes: {}
    alloy_custom_integrations: ""
    alloy_username: ""
    alloy_password: ""
    alloy_systemd_exporter_version: "0.7.0"
    alloy_custom_integrations: |
      prometheus.scrape "garage" {
        targets    = concat(
          [
            {"__address__" = "127.0.0.1:3903", "instance" = constants.hostname, "job" = "integrations/garage"},
          ],
        )
        forward_to = [
          otelcol.receiver.prometheus.default.receiver,
        ]
        bearer_token = "{{ garage_metrics_token }}"
      }
```
