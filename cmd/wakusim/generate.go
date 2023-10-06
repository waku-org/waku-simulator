package wakusim

import (
	"fmt"
	"log"

	"github.com/spf13/cobra"
	"github.com/waku-org/waku-simulator/internal/simulate"
)

var generateCmd = &cobra.Command{
	Use: "gen",
	Run: func(cmd *cobra.Command, args []string) {
		simulation, err := cmd.Flags().GetString("simulation")
		if err != nil {
			log.Fatal(err)
		}

		s := simulate.NewSimulation(simulation, "")

		err = s.Load(fmt.Sprintf("%s.yaml", simulation))
		if err != nil {
			log.Fatal(err)
		}

		err = s.Generate()
		if err != nil {
			log.Fatal(err)
		}
	},
}

func init() {
	rootCmd.AddCommand(generateCmd)
}
