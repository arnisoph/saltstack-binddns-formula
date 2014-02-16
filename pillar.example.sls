binddns:
  lookup:
    config:
      named.conf:
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
