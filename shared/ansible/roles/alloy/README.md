# Grafana Alloy Role

## Variables
```yaml
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

- name: Configure Alloy
  ansible.builtin.template:
    src: root/etc/alloy/config.alloy.j2
    dest: /etc/alloy/config.alloy
    mode: '0600'
    owner: "alloy"
    group: "alloy"
  notify: Restart alloy
```
