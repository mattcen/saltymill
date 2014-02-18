prereqs:
  pkg.installed:
    - names: [ unzip, wget ]

getfonts:
  cmd.run:
    - cwd: /usr/share/fonts/truetype
    - name: |
        {% for font in pillar.tm_fonts %}wget -nv --content-disposition '{{font}}' ;  {% endfor %}
    - unless: test "`find /usr/share/fonts/truetype -iname '*.zip'`"

unzip_fonts:
  cmd.wait:
    - cwd: /usr/share/fonts/truetype
    - name: "unzip -d . -o '*.zip'"
    - require: [ pkg: prereqs ]
    - watch: [ cmd: getfonts ]

fonts_logdone:
  cmd.wait_script:
    - source: salt://log.sh
    - args: "'Fonts downloaded and unzipped.'"
    - watch: [ { cmd: unzip_fonts } ]
