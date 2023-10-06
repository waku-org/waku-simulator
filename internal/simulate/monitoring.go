package simulate

import (
	"fmt"
	"io/ioutil"
	"os"
	"path"
	"time"

	compose "github.com/compose-spec/compose-go/types"
	"github.com/prometheus/common/model"
	prometheus "github.com/prometheus/prometheus/config"
	"github.com/prometheus/prometheus/discovery"
	"github.com/prometheus/prometheus/discovery/targetgroup"
	"github.com/prometheus/prometheus/model/labels"
	"gopkg.in/yaml.v3"
)

var PROMETHERUS_CONFIG_TMPLT = `
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    monitor: "Monitoring"

scrape_configs:
  - job_name: cadvisor
    scrape_interval: 5s
    static_configs:
    - targets:
      - cadvisor:8080
  - job_name: "nwaku"
    static_configs:
    - targets:
		%s
`

func (s *Simulation) prepMonitoring(folder string, services []string) ([]compose.ServiceConfig, error) {
	sc := make([]compose.ServiceConfig, 0)

	grafana, err := prepGrafana()
	if err != nil {
		return sc, err
	}
	prometheus, err := prepPrometheus(folder, services)
	if err != nil {
		return sc, err
	}

	cadvisor, err := prepCadvisor()
	if err != nil {
		return sc, err
	}
	redis, err := prepRedis()
	if err != nil {
		return sc, err
	}

	sc = append(sc, grafana, prometheus, redis, cadvisor)

	return sc, nil
}

func prepGrafana() (compose.ServiceConfig, error) {
	service := compose.ServiceConfig{
		Name:  "grafana",
		Image: "grafana/grafana:latest",
		EnvFile: compose.StringList{
			"../monitoring/configuration/grafana-plugins.env",
		},
		Ports: []compose.ServicePortConfig{
			{
				HostIP:    "0.0.0.0",
				Target:    3000,
				Published: "3000",
			},
		},
		DependsOn: compose.DependsOnConfig{
			"prometheus": compose.ServiceDependency{
				Condition: compose.ServiceConditionStarted,
			},
		},
		Volumes: []compose.ServiceVolumeConfig{
			{
				Type:     compose.VolumeTypeBind,
				Source:   "../monitoring/configuration/grafana.ini",
				Target:   "/etc/grafana/grafana.ini",
				ReadOnly: true,
			},
			{
				Type:     compose.VolumeTypeBind,
				Source:   "../monitoring/configuration/dashboards.yaml",
				Target:   "/etc/grafana/provisioning/dashboards/dashboards.yaml",
				ReadOnly: true,
			},
			{
				Type:     compose.VolumeTypeBind,
				Source:   "../monitoring/configuration/datasources.yaml",
				Target:   "//etc/grafana/provisioning/datasources/datasources.yaml",
				ReadOnly: true,
			},
			{
				Type:     compose.VolumeTypeBind,
				Source:   "../monitoring/configuration/dashboards",
				Target:   "/var/lib/grafana/dashboards/",
				ReadOnly: false,
			},
			{
				Type:     compose.VolumeTypeBind,
				Source:   "../monitoring/configuration/customizations/custom-logo.svg",
				Target:   "/usr/share/grafana/public/img/grafana_icon.svg",
				ReadOnly: true,
			},
			{
				Type:     compose.VolumeTypeBind,
				Source:   "../monitoring/configuration/customizations/custom-logo.svg",
				Target:   "/usr/share/grafana/public/img/grafana_typelogo.svg",
				ReadOnly: true,
			},
			{
				Type:     compose.VolumeTypeBind,
				Source:   "../monitoring/configuration/customizations/custom-logo.png",
				Target:   "/usr/share/grafana/public/img/fav32.png",
				ReadOnly: true,
			},
		},
	}
	return service, nil
}

func prepPrometheus(folder string, services []string) (compose.ServiceConfig, error) {

	bytes, err := ioutil.ReadFile("./monitoring/prometheus-config.yml")
	if err != nil {
		return compose.ServiceConfig{}, err
	}

	promConfig := prometheus.Config{
		GlobalConfig: prometheus.GlobalConfig{
			ScrapeInterval:     model.Duration(15 * time.Second),
			EvaluationInterval: model.Duration(15 * time.Second),
			ExternalLabels: labels.Labels{
				{
					Name:  "monitor",
					Value: "Monitoring",
				},
			},
		},
	}
	err = yaml.Unmarshal(bytes, &promConfig)
	if err != nil {
		return compose.ServiceConfig{}, err
	}

	cadvisorConfig := promConfig.ScrapeConfigs[0]
	promConfig.ScrapeConfigs = make([]*prometheus.ScrapeConfig, 0)

	nodesConfig := prometheus.ScrapeConfig{
		JobName: "nodes",
		ServiceDiscoveryConfigs: discovery.Configs{
			discovery.StaticConfig{},
		},
	}

	staticConfig := discovery.StaticConfig{
		&targetgroup.Group{
			Targets: make([]model.LabelSet, len(services)),
		},
	}
	for i, s := range services {
		staticConfig[0].Targets[i] = model.LabelSet{
			model.LabelName("__address__"): model.LabelValue(fmt.Sprintf("%s:8008", s)),
		}
	}

	nodesConfig.ServiceDiscoveryConfigs = discovery.Configs{staticConfig}

	promConfig.ScrapeConfigs = append(promConfig.ScrapeConfigs, cadvisorConfig, &nodesConfig)

	err = os.MkdirAll(path.Join(folder, "monitoring"), 0755)
	if err != nil {
		return compose.ServiceConfig{}, err
	}

	bytes, err = yaml.Marshal(promConfig)
	if err != nil {
		return compose.ServiceConfig{}, err
	}

	err = ioutil.WriteFile(path.Join(folder, "/monitoring/prometheus-config.yml"), bytes, 0644)
	if err != nil {
		return compose.ServiceConfig{}, err
	}

	service := compose.ServiceConfig{
		Name:  "prometheus",
		Image: "prom/prometheus:latest",
		Ports: []compose.ServicePortConfig{
			{
				HostIP:    "127.0.0.1",
				Target:    9090,
				Published: "9090",
			},
		},
		Command: compose.ShellCommand{
			"--config.file=/etc/prometheus/prometheus.yml",
			"--storage.tsdb.retention.time=7d",
		},
		Volumes: []compose.ServiceVolumeConfig{
			{
				Type:     compose.VolumeTypeBind,
				Source:   "./monitoring/prometheus-config.yml",
				Target:   "/etc/prometheus/prometheus.yml",
				ReadOnly: true,
			},
		},
	}

	return service, nil
}

func prepCadvisor() (compose.ServiceConfig, error) {
	service := compose.ServiceConfig{
		Name:          "cadvisor",
		Image:         "gcr.io/cadvisor/cadvisor:latest",
		ContainerName: "cadvisor",
		DependsOn: compose.DependsOnConfig{
			"redis": compose.ServiceDependency{
				Condition: compose.ServiceConditionStarted,
			},
		},
		Volumes: []compose.ServiceVolumeConfig{
			{
				Type:     compose.VolumeTypeBind,
				Source:   "/",
				Target:   "/rootfs",
				ReadOnly: true,
			},
			{
				Type:     compose.VolumeTypeBind,
				Source:   "/var/run",
				Target:   "/var/run",
				ReadOnly: false,
			},
			{
				Type:     compose.VolumeTypeBind,
				Source:   "/sys",
				Target:   "/sys",
				ReadOnly: true,
			},
			{
				Type:     compose.VolumeTypeBind,
				Source:   "/var/lib/docker/",
				Target:   "/var/lib/docker",
				ReadOnly: true,
			},
		},
	}

	return service, nil
}

func prepRedis() (compose.ServiceConfig, error) {
	service := compose.ServiceConfig{
		Name:          "redis",
		Image:         "redis:latest",
		ContainerName: "redis",
	}

	return service, nil
}
