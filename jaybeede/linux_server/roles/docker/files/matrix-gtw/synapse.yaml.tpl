# Configuration file for Synapse.
#
# This is a YAML file: see [1] for a quick introduction. Note in particular
# that *indentation is important*: all the elements of a list or dictionary
# should have the same indentation.
#
# [1] https://docs.ansible.com/ansible/latest/reference_appendices/YAMLSyntax.html
#
# For more information on how to configure Synapse, including a complete accounting of
# each option, go to docs/usage/configuration/config_documentation.md or
# https://element-hq.github.io/synapse/latest/usage/configuration/config_documentation.html
server_name: "{{ matrix_domain }}"
pid_file: /data/homeserver.pid
listeners:
  - port: 8008
    tls: false
    type: http
    x_forwarded: true
    resources:
      - names: [client, federation]
        compress: false
database:
  name: psycopg2
  args:
    user: matrixdb
    password: "{{ matrixdb_password }}"
    database: matrixdb
    host: matrix-db
    cp_min: 5
    cp_max: 10
enable_registration: false
registration_shared_secret: "{{ matrixgtw_register_secret }}"
serve_server_wellknown: true
media_store_path: /data/media_store
signing_key_path: "/data/{{ server_domain }}.signing.key"
report_stats: true
trusted_key_servers:
  - server_name: matrix.org
app_service_config_files:
  - /data/mautrix-telegram-registration.yaml
  - /data/mautrix-whatsapp-registration.yaml
