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

## TODO:
 - [ ] fix cadvisor mounting with WSL2 + Docker Desktop Enginer in /var/lib/docker