package main

//go:generate hugo --minify -s site -d ../public

import (
	"embed"
	"flag"
	"fmt"
	"io/fs"
	"log/slog"
	"os"

	"github.com/jnsgruk/gosherve/pkg/logging"
	"github.com/jnsgruk/gosherve/pkg/server"
)

var (
	commit string = "dev"

	logLevel = flag.String("log-level", "info", "log level of the application")

	redirectsURL = "https://gist.githubusercontent.com/jnsgruk/b590f114af1b041eeeab3e7f6e9851b7/raw"

	//go:embed public
	publicFS embed.FS
)

func main() {
	flag.Parse()
	logging.SetupLogger(*logLevel)

	// Create an fs.FS from the embedded filesystem
	fsys, err := fs.Sub(publicFS, "public")
	if err != nil {
		slog.Error(err.Error())
		os.Exit(1)
	}

	// Instantiate a new Gosherve server
	s := server.NewServer(&fsys, redirectsURL)
	slog.Info("jnsgruk", "commit", commit)

	// Hydrate the redirects map
	err = s.RefreshRedirects()
	if err != nil {
		// Since this is the first hydration, exit if unable to fetch redirects.
		// At this point, without the redirects to begin with the server is
		// quite useless.
		slog.Error("unable to fetch redirect map", "error", err.Error())
		os.Exit(1)
	}

	slog.Info(fmt.Sprintf("fetched %d redirects", s.NumRedirects()))
	s.Start()
}
