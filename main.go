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

	staticFiles, err := server.PrepareStaticFiles(
		fsys,
		server.WithPrecompression(
			server.CompressionBrotli,
			server.CompressionGzip,
		),
	)
	if err != nil {
		slog.Error("unable to prepare static files", "error", err.Error())
		os.Exit(1)
	}

	// Instantiate a new Gosherve server
	s := server.NewServer(
		&fsys,
		redirectsURL,
		server.WithStaticFiles(staticFiles),
		server.WithCacheRules(
			// Do not retain negative responses for routes that may be added later.
			server.CacheRule{Pattern: "404.html", CacheControl: "no-store"},

			// Hugo includes a content fingerprint in these asset names.
			server.CacheRule{Pattern: "*.min.*.css", CacheControl: "public, max-age=31536000, immutable"},
			server.CacheRule{Pattern: "*.min.*.js", CacheControl: "public, max-age=31536000, immutable"},
			server.CacheRule{Pattern: "*_hu_*", CacheControl: "public, max-age=31536000, immutable"},

			// Site indexes and discovery documents should update promptly.
			server.CacheRule{Pattern: "sitemap.xml", CacheControl: "public, max-age=3600, must-revalidate"},
			server.CacheRule{Pattern: "robots.txt", CacheControl: "public, max-age=3600, must-revalidate"},
			server.CacheRule{Pattern: "site.webmanifest", CacheControl: "public, max-age=3600, must-revalidate"},
			server.CacheRule{Pattern: "llm*.txt", CacheControl: "no-cache"},
			server.CacheRule{Pattern: "*.xml", CacheControl: "no-cache"},
			server.CacheRule{Pattern: "*.json", CacheControl: "no-cache"},

			// Rendered pages and their Markdown alternatives are mutable.
			server.CacheRule{Pattern: "*.html", CacheControl: "public, max-age=300, must-revalidate"},
			server.CacheRule{Pattern: "*.md", CacheControl: "public, max-age=300, must-revalidate"},

			// Stable-name assets can be cached, but should periodically revalidate.
			server.CacheRule{Pattern: "*.css", CacheControl: "public, max-age=86400, must-revalidate"},
			server.CacheRule{Pattern: "*.js", CacheControl: "public, max-age=86400, must-revalidate"},
			server.CacheRule{Pattern: "*.png", CacheControl: "public, max-age=86400, must-revalidate"},
			server.CacheRule{Pattern: "*.jpg", CacheControl: "public, max-age=86400, must-revalidate"},
			server.CacheRule{Pattern: "*.jpeg", CacheControl: "public, max-age=86400, must-revalidate"},
			server.CacheRule{Pattern: "*.webp", CacheControl: "public, max-age=86400, must-revalidate"},
			server.CacheRule{Pattern: "*.svg", CacheControl: "public, max-age=86400, must-revalidate"},
			server.CacheRule{Pattern: "*.ico", CacheControl: "public, max-age=86400, must-revalidate"},
		),
	)
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
