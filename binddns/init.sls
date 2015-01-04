#!jinja|yaml

{% from "binddns/defaults.yaml" import rawmap with context %}
{% set datamap = salt['grains.filter_by'](rawmap, merge=salt['pillar.get']('binddns:lookup')) %}

binddns:
  pkg:
    - installed
    - pkgs: {{ datamap.pkgs }}
  service:
    - running
    - name: {{ datamap.service.name }}
    - enable: {{ datamap.service.enable|default(True) }}
    - require:
      - pkg: binddns
      - file: zonedir

zonedir:
  file:
    - directory
    - name: {{ datamap.zonedir }}
    - mode: 750
    - user: {{ datamap.user.name }}
    - group: {{ datamap.group.name }}

{% if 'defaults_file' in datamap.config.manage %}
defaults_file:
  file:
    - managed
    - name: {{ datamap.config.defaults_file.path }}
    - makedirs: True
    - source: {{ datamap.config.defaults_file.template_path|default('salt://binddns/files/defaults_file.' ~ salt['grains.get']('os_family')) }}
    - template: {{ datamap.config.defaults_file.template_renderer|default('jinja') }}
    - mode: {{ datamap.config.defaults_file.mode|default('644') }}
    - user: {{ datamap.config.defaults_file.user|default('root') }}
    - group: {{ datamap.config.defaults_file.group|default('root') }}
    - watch_in:
      - service: binddns
{% endif %}

{% if 'named_conf' in datamap.config.manage %}
named_conf:
  file:
    - managed
    - name: {{ datamap.config.named_conf.path }}
    - source: {{ datamap.config.named_conf.template_path|default('salt://binddns/files/named.conf') }}
    - template: {{ datamap.config.named_conf.template_renderer|default('jinja') }}
    - mode: {{ datamap.config.named_conf.mode|default('640') }}
    - user: {{ datamap.config.named_conf.user|default(datamap.user.name) }}
    - group: {{ datamap.config.named_conf.group|default(datamap.group.name) }}
    - watch_in:
      - service: binddns
{% endif %}

{% if 'rndc_key' in datamap.config.manage %}
rndc_key:
  cmd:
    - run
    - name: {{ datamap.config.rndc_key.gen_cmd|default('/usr/sbin/rndc-confgen -r /dev/urandom -a -c ' ~ datamap.config.rndc_key.path ) }}
    - unless: test -f {{ datamap.config.rndc_key.path }}
  file:
    - managed
    - name: {{ datamap.config.rndc_key.path }}
    - mode: {{ datamap.config.rndc_key.mode|default('640') }}
    - user: {{ datamap.config.rndc_key.user|default('root') }}
    - group: {{ datamap.config.rndc_key.group|default(datamap.group.name) }}
    - require:
      - cmd: rndc_key
    - watch_in:
      - service: binddns
{% endif %}

{% if 'options' in datamap.config.manage %}
options:
  file:
    - managed
    - name: {{ datamap.config.options.path }}
    - source: {{ datamap.config.options.template_path|default('salt://binddns/files/named.conf.options') }}
    - template: {{ datamap.config.options.template_renderer|default('jinja') }}
    - mode: {{ datamap.config.options.mode|default('640') }}
    - user: {{ datamap.config.options.user|default(datamap.user.name) }}
    - group: {{ datamap.config.options.group|default(datamap.group.name) }}
    - watch_in:
      - service: binddns
{% endif %}


{# Zones #}

{%
set z_def = {
  'ttl': 10800,
  'serial': 1,
  'refresh': 86400,
  'retry': 3600,
  'expire': 604800,
  'minimum': 3600,
}
%}

{% if 'zoneconfigs' in datamap.config.manage|default([]) %}
zoneconfigs:
  file:
    - managed
    - name: {{ datamap.config.zoneconfigs.path }}
    - source: {{ datamap.config.zoneconfigs.template_path|default('salt://binddns/files/named.conf.zones') }}
    - template: {{ datamap.config.zoneconfigs.template_renderer|default('jinja') }}
    - mode: {{ datamap.config.zoneconfigs.mode|default('644') }}
    - user: {{ datamap.config.zoneconfigs.user|default('root') }}
    - group: {{ datamap.config.zoneconfigs.group|default('root') }}
    - watch_in:
      - service: binddns
{% endif %}

{% for z in salt['pillar.get']('binddns:zones', []) %}
  {% if not (z.create_db_only and salt['file.file_exists'](datamap.zonedir ~ '/db.' ~ z.name)) %}
zone_{{ z.name }}:
  file:
    - managed
    - name: {{ datamap.zonedir }}/db.{{ z.name }}
    - source: {{ datamap.config.zones.template_path|default('salt://binddns/files/zonefile') }}
    - template: {{ datamap.config.zones.template_renderer|default('jinja') }}
    - mode: {{ datamap.config.zones.mode|default('644') }}
    - user: {{ datamap.config.zones.user|default('root') }}
    - group: {{ datamap.config.zones.group|default('root') }}
    - watch_in:
      - service: binddns
    - context:
        name: {{ z.name }}
        soa: {{ z.soa }}
        ttl: {{ z.ttl|default(z_def.ttl) }}
        serial: {{ z.serial|default(z_def.serial) }}
        refresh: {{ z.refresh|default(z_def.refresh) }}
        retry: {{ z.retry|default(z_def.retry) }}
        expire: {{ z.expire|default(z_def.expire) }}
        minimum: {{ z.minimum|default(z_def.minimum) }}
        contact: {{ z.contact|default('root.' ~ z.name ~ '.') }}
        records: {{ z.records|default([]) }}
  {% endif %}
{% endfor %}
