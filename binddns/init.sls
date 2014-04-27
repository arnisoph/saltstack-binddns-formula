{% from "binddns/defaults.yaml" import rawmap with context %}
{% set datamap = salt['grains.filter_by'](rawmap, merge=salt['pillar.get']('binddns:lookup')) %}

binddns:
  pkg:
    - installed
    - pkgs:
{% for p in datamap['pkgs'] %}
      - {{ p }}
{% endfor %}
  service:
    - running
    - name: {{ datamap['service']['name'] }}
    - enable: {{ datamap['service']['enable']|default(True) }}
    - watch:
{% for c in datamap['config']['manage']|default([]) %}
      - file: {{ datamap['config'][c]['path'] }}
{% endfor %}
    - require:
      - pkg: binddns

{{ datamap['zonedir'] }}:
  file:
    - directory
    - mode: '0750'
    - user: {{ datamap['user']['name'] }}
    - group: {{ datamap['group']['name'] }}
    - require:
      - pkg: binddns

{% if 'named.conf' in datamap['config']['manage'] %}
{{ datamap['config']['named.conf']['path'] }}:
  file:
    - managed
    #- name: {{ datamap['config']['named.conf']['path'] }}
    - source: {{ datamap['config']['named.conf']['template_path']|default('salt://binddns/files/named.conf') }}
    - template: {{ datamap['config']['named.conf']['template_renderer']|default('jinja') }}
    - mode: {{ datamap['config']['named.conf']['mode']|default('640') }}
    - user: {{ datamap['config']['named.conf']['user']|default(datamap['user']['name']) }}
    - group: {{ datamap['config']['named.conf']['group']|default(datamap['group']['name']) }}
    - require:
      - pkg: binddns
{% endif %}

{% if 'rndc.key' in datamap['config']['manage'] %}
{{ datamap['config']['rndc.key']['path'] }}:
  cmd:
    - run
    - name: {{ datamap['config']['rndc.key']['gen_cmd']|default('/usr/sbin/rndc-confgen -r /dev/urandom -a -c ' ~ datamap['config']['rndc.key']['path'] ) }}
    - unless: test -f {{ datamap['config']['rndc.key']['path'] }}
    - require:
      - pkg: binddns
  file:
    - managed
    - mode: {{ datamap['config']['rndc.key']['mode']|default('640') }}
    - user: {{ datamap['config']['rndc.key']['user']|default('root') }}
    - group: {{ datamap['config']['rndc.key']['group']|default(datamap['group']['name']) }}
    - require:
      - cmd: {{ datamap['config']['rndc.key']['path'] }}
{% endif %}

{% if 'options' in datamap['config']['manage'] %}
{{ datamap['config']['options']['path'] }}:
  file:
    - managed
    - source: {{ datamap['config']['options']['template_path']|default('salt://binddns/files/named.conf.options') }}
    - template: {{ datamap['config']['options']['template_renderer']|default('jinja') }}
    - mode: {{ datamap['config']['options']['mode']|default('640') }}
    - user: {{ datamap['config']['options']['user']|default(datamap['user']['name']) }}
    - group: {{ datamap['config']['options']['group']|default(datamap['group']['name']) }}
    - require:
      - pkg: binddns
{% endif %}
