SaltyMill
---------

This is a rough salt configuration to deploy a tilemill stack. The major components are:

- TileMill: cartographic IDE for turning map data into web or static maps
- PostGIS: Postgresql database with GIS extensions, holds OpenStreetMap data
- Nginx: web server, provides password authentication and allows services to share one port (80).
- OSM (optional): extract of OpenStreetMap data downloaded and imported
- OSRM (optional): Open Source Routing Machine, adds a trip routing web interface to your data.

It's a conversion of http://github.com/stevage/tilemill-server

Building a machine with the three main components takes a few minutes. Adding OSM and OSRM can take
half an hour or more, possibly much more, depending on machine configuration and extract size.

There are two ways to build a server using Salt:
1. Using a separate SaltMaster which drives the "minion" - you need two servers for this.
2. Using a "masterless minion" which drives itself.

Typical usage:


### On a clean Ubuntu Quantal VM
```
wget -O - http://bootstrap.saltstack.org | sudo sh

sudo tee -a /etc/salt/minion <<EOF
grains:
  fqdn: `curl http://ifconfig.me` # Nginx needs to know the server's actual IP.
  roles:
    - tilemill
    - osm                         # Optional: local OSM data.
    - osrm                        # Optional: OSRM routing engine. (requires osm)
EOF

*Skip the next line if in masterless mode* 
sudo tee -a /etc/salt/minion "master: <<<INSERT YOUR SALTMASTER IP/FQDN HERE>>>"

sudo service salt-minion restart
```

### On the saltmaster (or the same VM if masterless):

* Skip this one step if masterless *
Install Salt, if needed:

`curl -L http://bootstrap.saltstack.org | sudo sh -s -- -M -N`

Install these scripts:
```
sudo git clone https://github.com/stevage/saltymill /srv/salt
```

Set up pillar properties:

```
sudo mkdir /srv/pillar
sudo tee /srv/pillar/top.sls <<EOF
base:
  '*':
    - tm
EOF
sudo tee /srv/pillar/tm.sls <<EOF
tm_username: tm                       # Username/password for basic htpasswd authentication
tm_password: pumpkin                   
tm_dbusername: ubuntu                 # Postgres username/password that will be created
tm_dbpassword: ubuntu                 # and used to load data with. It doesn't get external access.
tm_postgresdir: /mnt/var/lib          # Directory to move Postgres to (ie, big, non-ephemeral drive).
tm_timezone: 'Australia/Melbourne'    # We set the timezone because NeCTAR VMs don't have it set.
tm_dir: /mnt/saltymill                # Where to install scripts to.
                                      # Where to download OSM extracts from.
tm_osmsourceurl: http://download.geofabrik.de/australia-oceania/australia-latest.osm.pbf

# (Optional)
tm_projects:
  - http://gis.researchmaps.net/sample/melbourne.zip

# (If using OSRM)
tm_osrmdir: /mnt/saltymill/osrm
tm_osrmport: 5010
tm_osrmprofile: bicycle
# (optional)
#tm_osrmprofilesource: ...

EOF
```

*If running masterless:*

`salt --local state.highstate`

*If running saltmaster:*

```
sudo service salt-master start

yes | sudo salt-key -A

sudo salt '*' state.highstate
```