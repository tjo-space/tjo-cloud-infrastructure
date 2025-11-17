# Lego Role

## Variables
```yaml
desec_token: ""
domains:
 - example.com
```

## Usage
```yaml
- name: Install Lego
  ansible.builtin.import_role:
    name: lego
  vars:
    desec_token: ""
    domains:
      - example.com

```
