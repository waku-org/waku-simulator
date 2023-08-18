package simulate

import (
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"path"

	compose "github.com/compose-spec/compose-go/types"
	"github.com/otiai10/copy"
	"gopkg.in/yaml.v3"
)

const (
	BOOSTRAP_SERVICE_NAME  = "bootstrap"
	PUBLISHER_SERVICE_NAME = "waku-publisher"
	CONTAINER_ENTRYPOINT   = "/opt/run.sh"
)

type Simulation struct {
	Name      string
	TargetDir string
	Manifest  Manifest
}

func NewSimulation(name string, targetDir string) *Simulation {
	if targetDir == "" {
		targetDir = name
	}
	return &Simulation{
		Name:      name,
		TargetDir: targetDir,
	}
}

func (s *Simulation) Load(path string) error {
	bytes, err := ioutil.ReadFile(path)
	if err != nil {
		return err
	}

	var m = Manifest{}
	err = yaml.Unmarshal(bytes, &m)
	if err != nil {
		return err
	}

	if m.Bootstrap == nil {
		b := true
		m.Bootstrap = &b
	}

	if m.Monitoring == nil {
		b := true
		m.Monitoring = &b
	}

	for i, g := range m.Groups {
		if g.Name == "" {
			return fmt.Errorf("Missing name for group %d", i)
		}
	}

	s.Manifest = m
	return nil
}

func (s *Simulation) Generate() error {
	c := compose.Project{}
	bootstrap := false

	if *s.Manifest.Bootstrap {
		service, err := s.prepBootstrapNode()
		if err != nil {
			return err
		}

		c.Services = append(c.Services, service)
		bootstrap = true
	}

	for _, g := range s.Manifest.Groups {
		for j := 0; j < g.Count; j++ {
			service := compose.ServiceConfig{}

			service.Image = g.Image
			service.Name = fmt.Sprintf("%s-%d", g.Name, j)
			service.Environment = g.Env

			if bootstrap {
				service.DependsOn = compose.DependsOnConfig{
					BOOSTRAP_SERVICE_NAME: compose.ServiceDependency{
						Condition: compose.ServiceConditionStarted,
						Required:  true,
					},
				}
			}

			s.ensureRunScript(g, &service)

			service.Command = append(service.Command, g.Args...)

			s.ensureVolumes(g, &service)

			c.Services = append(c.Services, service)
		}
	}

	if *s.Manifest.Monitoring {
		services := c.ServiceNames()

		monitoringServices, err := s.prepMonitoring(s.TargetDir, services)
		if err != nil {
			return err
		}

		c.Services = append(c.Services, monitoringServices...)
	}

	if s.Manifest.Publisher != nil {
		service, err := s.prepPublisher()
		if err != nil {
			return err
		}

		c.Services = append(c.Services, service)
	}

	log.Printf("Generating Docker Compose environment into the folder ./%s", s.TargetDir)

	bytes, err := c.MarshalYAML()
	if err != nil {
		return err
	}

	err = os.MkdirAll(s.TargetDir, 0755)
	if err != nil {
		return err
	}
	ioutil.WriteFile(path.Join(s.TargetDir, "compose.yaml"), bytes, 0644)
	return nil

}

func (s *Simulation) ensureRunScript(g Group, service *compose.ServiceConfig) error {

	command := ""

	switch g.Typ {
	case "nwaku":
		command = "run_nwaku.sh"
	case "gowaku":
		command = "run_gowaku.sh"
	case "wakupublisher":
		command = "run_wakupublisher.sh"
	default:
		return fmt.Errorf("Unknown service type: %s", g.Typ)
	}

	if service.Command == nil || len(service.Command) == 0 {
		service.Command = compose.ShellCommand{CONTAINER_ENTRYPOINT}
	} else {
		service.Command = append(compose.ShellCommand{CONTAINER_ENTRYPOINT}, service.Command...)
	}

	if service.Volumes == nil {
		service.Volumes = make([]compose.ServiceVolumeConfig, 0)
	}

	service.Volumes = append(service.Volumes, compose.ServiceVolumeConfig{
		Type:     compose.VolumeTypeBind,
		Source:   fmt.Sprintf("../%s", command),
		Target:   CONTAINER_ENTRYPOINT,
		ReadOnly: true,
	})

	service.Entrypoint = compose.ShellCommand{"sh"}

	return nil
}

func (s *Simulation) ensureVolumes(g Group, service *compose.ServiceConfig) error {
	if len(g.Volumes) > 0 && service.Volumes == nil {
		service.Volumes = make([]compose.ServiceVolumeConfig, 0)
	}
	for _, v := range g.Volumes {
		src := v.Src
		if v.PerNode && !v.ReadOnly {
			src = fmt.Sprintf("%s-%s", v.Src, service.Name)

			_, err := os.Stat(v.Src) //TODO: Is there a difference between dir and file?
			if err != nil && !os.IsNotExist(err) {
				return err
			}

			if os.IsNotExist(err) {
				err = os.MkdirAll(path.Join(s.TargetDir, src), 0755)
				if err != nil {
					return err
				}
			} else {
				err = copy.Copy(v.Src, path.Join(s.TargetDir, src))
				if err != nil {
					return err
				}
			}
		}

		volume := compose.ServiceVolumeConfig{
			Type:     compose.VolumeTypeBind,
			Source:   src,
			Target:   v.Dst,
			ReadOnly: v.ReadOnly,
		}
		service.Volumes = append(service.Volumes, volume)

	}

	return nil
}

func (s *Simulation) prepBootstrapNode() (compose.ServiceConfig, error) {
	service := compose.ServiceConfig{}

	service.Name = "bootstrap"
	service.Image = "statusteam/nim-waku:v0.19.0"
	service.Entrypoint = compose.ShellCommand{"sh"}
	service.Command = compose.ShellCommand{
		CONTAINER_ENTRYPOINT,
	}

	service.Volumes = make([]compose.ServiceVolumeConfig, 1)
	service.Volumes[0] = compose.ServiceVolumeConfig{
		Type:     compose.VolumeTypeBind,
		Source:   "../run_bootstrap.sh",
		Target:   CONTAINER_ENTRYPOINT,
		ReadOnly: true,
	}

	service.Ports = []compose.ServicePortConfig{
		{
			HostIP:    "127.0.0.1",
			Target:    60000,
			Published: "60000",
		},
		{
			HostIP:    "127.0.0.1",
			Target:    8008,
			Published: "8008",
		},
		{
			HostIP:    "127.0.0.1",
			Target:    9000,
			Published: "9000",
		},
		{
			HostIP:    "127.0.0.1",
			Target:    8545,
			Published: "8545",
		},
	}

	return service, nil
}

func (s *Simulation) prepPublisher() (compose.ServiceConfig, error) {
	service := compose.ServiceConfig{}

	service.Name = PUBLISHER_SERVICE_NAME
	service.Image = s.Manifest.Publisher.Image
	service.Entrypoint = compose.ShellCommand{"sh"}
	service.Command = compose.ShellCommand{
		CONTAINER_ENTRYPOINT,
	}

	service.Volumes = make([]compose.ServiceVolumeConfig, 1)
	service.Volumes[0] = compose.ServiceVolumeConfig{
		Type:     compose.VolumeTypeBind,
		Source:   "../run_wakupublisher.sh",
		Target:   CONTAINER_ENTRYPOINT,
		ReadOnly: true,
	}

	service.Environment = make(compose.MappingWithEquals)

	v := fmt.Sprintf("%d", s.Manifest.Publisher.MsgPerSec)
	service.Environment["MSG_PER_SECOND"] = &v

	v2 := fmt.Sprintf("%d", s.Manifest.Publisher.MsgSizeKB)
	service.Environment["MSG_SIZE_KBYTES"] = &v2

	return service, nil

}
