{# Simple Example #}
binddns:
  lookup:
    config:
      defaults_file:
        options:
          - '-4'
          - '-u bind'
      named_conf:
        file_prepend: "// my prepend\n// the end"
        controls:
          - 'inet 127.0.0.1 port 953 allow { 127.0.0.1; } keys { "rndc-key"; };'
        options:
          - '// my option here'
        includes:
          - /etc/bind/zones.rfc1918
        file_append: "// my append\n// the end"
  forwarders:
    - 8.8.8.8
    - 8.8.4.4

{# Example with user defined zones #}
binddns:
  lookup:
    config:
      options:
        ip4_listen:
          - 127.0.0.1
        ip6_listen:
          - ::1
      named_conf:
        controls:
          - 'inet 127.0.0.1 port 953 allow { 127.0.0.1; } keys { "rndc-key"; };'
    dnssec_validation: "no"
  forwarders:
    - 8.8.8.8
    - 8.8.4.4
  zones:
    - create_db_only: True
      name: prod.be1-net.local
      soa: foreman.prod.be1-net.local
      additional:
        - update-policy { grant rndc-key zonesub ANY; }
      records:
        - owner: foreman
          ttl: 86400
          class: A
          data: 172.16.34.10
        - owner: anyhost
          class: a
          data: 172.16.34.42
          comment: anyhost
    - create_db_only: True
      name: 34.16.172.in-addr.arpa
      soa: foreman.prod.be1-net.local
      additional:
        - update-policy { grant rndc-key zonesub ANY; }
      records:
        - owner: 10
          ttl: 86400
          class: PTR
          data: foreman.prod.be1-net.local.
