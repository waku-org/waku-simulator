package wakusim

import (
	"log"

	"github.com/spf13/cobra"
)

var version = "v0.0.0"

var rootCmd = &cobra.Command{
	Use:     "waksim",
	Version: version,
}

func Execute() {
	var err error

	err = rootCmd.Execute()
	if err != nil {
		log.Fatalln(err)
	}
}

func init() {
	rootCmd.PersistentFlags().StringP("simulation", "s", "default", "name of the simulation")
}
