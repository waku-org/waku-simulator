package simulate

type Manifest struct {
	Name       string     `yaml:"name"`
	Bootstrap  *bool      `yaml:"bootstrap"`
	Monitoring *bool      `yaml:"monitoring"`
	Groups     []Group    `yaml:"groups"`
	Publisher  *Publisher `yaml:"publisher"`
}

type Group struct {
	Name    string             `yaml:"name"`
	Typ     string             `yaml:"type"`
	Image   string             `yaml:"image"`
	Count   int                `yaml:"count"`
	Args    []string           `yaml:"args"`
	Env     map[string]*string `yaml:"env"`
	Volumes []Volume           `yaml:"volumes"`
}

type Volume struct {
	Src      string `yaml:"src"`
	Dst      string `yaml:"dst"`
	PerNode  bool   `yaml:"per_node"`
	ReadOnly bool   `yaml:"read_only"`
}

type Publisher struct {
	Image     string `yaml:"image"`
	MsgPerSec int    `yaml:"msq_per_sec"`
	MsgSizeKB int    `yaml:"msg_size_kb"`
}
