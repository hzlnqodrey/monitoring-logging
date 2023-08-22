# monitoring-logging

The monitoring stack consists of the following components:

 - **Prometheus** is the server that collects metrics from various sources and stores them such that they are available for querying. We will use three exporters: node_exporter, cadvisor and postgres_exporter.
 - **node_exporter** exposes system-level metrics, such as CPU and memory usage.
 - **cadvisor** provides container-level metrics
 - **postgres_exporter** exposes PostgreSQL metrics
 - **Grafana** is the dashboard that fetches data from the Prometheus server and displays it in a customizable UI.

The logging stack consists of the following components:
 - **Promtail** collects logs from various sources, and forwards them to the Loki server for storage.
 - **Loki** efficiently stores the logs, indexes them for fast retrieval, and provides APIs for querying them from the Grafana dashboard.

these are some of the key points of the setup:

 - **Prometheus** scrapes metrics from the exporters. It needs to know their address (localhost + port). The scraping happens every couple of seconds (configurable). Prometheus then exposes the data via an API at localhost:9090.
 - **The Prometheus exporters** Prometheus scrape the data from the log files stored in the system. Therefore the log files need to be mounted as their volumes (as read-only).
 - **Promtail** allows us to add various metadata to logs, such as labels (see the pipelinestages section of _promtail config file). This makes logs easy to query.
 - **Grafana** exposes the dashboard at localhost:3000. Requests to rides.jurajmajerik.com/grafana are reverse-proxied to localhost:3000, returning the dashboard to the user.

## Monitoring-and-Logging Infrastructure Architecture
![image](https://github.com/hzlnqodrey/monitoring-logging/assets/57006944/baf9f018-d5d7-42a8-a064-5af196237a85)

# Procedure [Documentation]

### 1. Setup prometheus.yml

```yaml
global:
  scrape_interval:     4s

scrape_configs:
  - job_name: 'prometheus'
    metrics_path: /prometheus/metrics
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node_exporter'
    static_configs:
     - targets: ['node_exporter:9100']

  - job_name: 'cadvisor'
    static_configs:
     - targets: ['cadvisor:8080']
```

### 2. Setup docker-compose.yaml for building the stacks

```yaml
services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus-prod.yml:/etc/prometheus/prometheus.yml
      - prometheus-data:/prometheus
    restart: unless-stopped
    command:
      - "--config.file=/etc/prometheus/prometheus.yml"
      - "--web.external-url=/prometheus/"
      - "--web.route-prefix=/prometheus/"

  node_exporter:
    image: quay.io/prometheus/node-exporter:latest
    container_name: node_exporter
    command:
      - '--path.rootfs=/host'
    pid: host
    restart: unless-stopped
    volumes:
      - '/:/host:ro,rslave'

  cadvisor:
    image: gcr.io/cadvisor/cadvisor:v0.45.0     
    container_name: cadvisor
    ports:
      - "9092:8080"
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
      - /dev/disk/:/dev/disk:ro
    devices:
      - /dev/kmsg
    restart: unless-stopped
    privileged: true

  grafana:
    image: grafana/grafana-oss:latest
    user: "0:0"
    container_name: grafana
    ports:
      - "3000:3000"
    volumes:
      - grafana-data:/var/lib/grafana
      - ./grafana.ini:/etc/grafana/grafana.ini
      - /etc/letsencrypt:/etc/letsencrypt
    restart: unless-stopped

volumes:
  prometheus-data:
    driver: local
  grafana-data:
    driver: local
```
### 3. Configure Volume Mounting for cAdvisor (because after reboot, WSL2 system deleted symlink mounting)

```bash
sudo mount -t drvfs '\\wsl$\docker-desktop-data\data\docker' /mnt/docker_data
```
### 4. Deploy

```bash
docker-compose up -d grafana prometheus node_exporter cadvisor
```

### 5. Check Prometheus Status

```bash
http://host.docker.internal:9090/prometheus/
http://host.docker.internal:9090/prometheus/metrics
http://localhost:9090/prometheus/
```

### 6. Check Loki Status

```bash
http://host.docker.internal:3100/metrics
http://host.docker.internal:3100/ready
```

### 7. Open Grafana

- Add Prometheus Data Source

```bash
Name: Prometheus
Prometheus server URL: http://host.docker.internal:9090/prometheus/ or http://host.docker.internal:9090/prometheus
```

- Everything else is default, click **Save & Test**
- Import Dashboard (check [Grafana Labs](https://grafana.com/grafana/dashboards/))

- Add Loki Data Source
```bash
Name: Loki
Prometheus server URL: http://loki:3100
```

- Loki Query
According to this [Link](https://grafana.com/blog/2022/03/02/new-in-grafana-8.4-how-to-use-full-range-log-volume-histograms-with-grafana-loki/?pg=getting-started-shipping-logs-to-grafana-loki), you must add "``` | logfmt ```" 
```bash
{jobs="varlogs"} | logfmt | level=`error` |= "docker"
```
### 8. On Docker Driver Plugin
- Install Plugin in each target machines that running a container
```bash
docker plugin install grafana/loki-docker-driver:2.8.2 --alias loki --grant-all-permissions
```
- check plugin staus
```bash
docker plugin ls
```

- Change the default logging driver

If you want the Loki logging driver to be the default for all containers, change Docker’s daemon.json file (located in /etc/docker on Linux) and set the value of log-driver to loki:
```txt
Note:
The Loki logging driver still uses the json-log driver in combination with sending logs to Loki, this is mainly useful to keep the docker logs command working. You can adjust file size and rotation using the respective log option max-size and max-file. Keep in mind that default values for these options are not taken from json-log configuration. You can deactivate this behavior by setting the log option no-file to true.
```
```json
{
    "log-driver": "loki",
    "log-opts": {
        // "loki-url": "https://<user_id>:<password>@logs-us-west1.grafana.net/loki/api/v1/push",
        "loki-url": "http://localhost:3100/loki/api/v1/push",
        "loki-batch-size": "400"
    }
}

```


## TODO:
 - [x] Monitoring Stack
   - [x] fix cadvisor mounting with WSL2 + Docker Desktop Enginer in /var/lib/docker
   - [x] choose between auto mounting docker_data or execute sudo mount -t drvfs
 - [ ] Logging Stack
   - [x] add logging level labels "``` error ```", "``` debug ```", "``` warn ```", and "``` info ```"
 - [ ] Mysql Exporter
 - [ ] Up to Cloud Infra
 - [ ] Config in Cloud Infra
   - [ ] Monitoring
     - [ ] add/install/deploy the EXPORTERS (node_exporter, cAdvisor, etc) in TARGET_SERVER
     - [ ] connect it to PROMETHEUS MASTER SERVER (add the target ip in the prometheus.yml)
   - [ ] Logging
     - [ ] add/install docker driver plugin in the TARGET_SERVER (REMOTE VMs) to push all logging containers - according to this [link](https://grafana.com/docs/loki/v2.8.x/clients/docker-driver/configuration/)
        ```bash
            docker plugin install grafana/loki-docker-driver:2.8.2 --alias loki --grant-all-permissions
        ```
     - [ ] 