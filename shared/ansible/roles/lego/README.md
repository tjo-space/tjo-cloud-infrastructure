# Lego Role

## Variables
```yaml
desec_token: ""
```

## Usage
```yaml
- name: Install Lego
  ansible.builtin.import_role:
    name: lego
  vars:
    desec_token: ""

```
