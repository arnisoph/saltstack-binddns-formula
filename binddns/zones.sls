{% from "binddns/defaults.yaml" import rawmap with context %}
{% set datamap = salt['grains.filter_by'](rawmap, merge=salt['pillar.get']('binddns:lookup')) %}

include:
    - binddns

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

{% if 'zoneconfigs' in datamap.config.manage %}
{{ datamap.config.zoneconfigs.path }}:
  file:
    - managed
    - source: {{ datamap.config.zoneconfigs.template_path|default('salt://binddns/files/named.conf.zones') }}
    - template: {{ datamap.config.zoneconfigs.template_renderer|default('jinja') }}
    - mode: {{ datamap.config.zoneconfigs.mode|default('644') }}
    - user: {{ datamap.config.zoneconfigs.user|default('root') }}
    - group: {{ datamap.config.zoneconfigs.group|default('root') }}
{% endif %}

{% for z in salt['pillar.get']('binddns:zones', []) %}
  {% if not (z.create_db_only and salt['file.file_exists'](datamap.zonedir ~ '/db.' ~ z.name)) %}
{{ datamap.zonedir }}/db.{{ z.name }}:
  file:
    - managed
    - source: {{ datamap.config.zones.template_path|default('salt://binddns/files/zonefile') }}
    - template: {{ datamap.config.zones.template_renderer|default('jinja') }}
    - mode: {{ datamap.config.zones.mode|default('644') }}
    - user: {{ datamap.config.zones.user|default('root') }}
    - group: {{ datamap.config.zones.group|default('root') }}
    - require:
      - pkg: binddns
    - require_in:
      - service: binddns
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
